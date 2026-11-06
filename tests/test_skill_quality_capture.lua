-- Primary API contract fixture: exact salvage input allocation determines the
-- quality boundary. Numbers are controlled examples, not measured game yields.
local count=0
local function check(v,msg) assert(v,msg);count=count+1 end
local function same(a,b,msg) check(a==b,(msg or '')..' '..tostring(a)..' ~= '..tostring(b)) end
local function clone(t) if type(t)~='table' then return t end local n={} for k,v in pairs(t)do n[k]=clone(v)end return n end
local now,currentBuild,linked=100,'70783',false
GetTime=function()return now end
time=function()return now end
GetBuildInfo=function()return 'test',currentBuild end
local hooks={}
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
hooksecurefunc=function(_,method,fn)hooks[method]=fn end
local stacks={
    ['0:1']={id=10,guid='Item-ten',rank=1},
    ['0:2']={id=11,guid='Item-eleven',rank=2},
}
ItemLocation={CreateFromBagAndSlot=function(_,bag,slot)return tostring(bag)..':'..tostring(slot)end}
C_Item={GetItemID=function(location)return stacks[location] and stacks[location].id end,
    GetItemGUID=function(location)return stacks[location] and stacks[location].guid end}
C_Container={GetContainerNumSlots=function(bag)return bag==0 and 2 or 0 end}
local calls={}
local recipe={supportsQualities=true,maxQuality=2,isSalvageRecipe=true}
local operations={
    ['Item-ten']={recipeID=1231127,isQualityCraft=true,baseSkill=100,bonusSkill=260,craftingQuality=1,
        baseDifficulty=365,bonusDifficulty=0,lowerSkillThreshold=0,upperSkillTreshold=365,bonusStats={}},
    ['Item-eleven']={recipeID=1231127,isQualityCraft=true,baseSkill=100,bonusSkill=270,craftingQuality=2,
        baseDifficulty=365,bonusDifficulty=0,lowerSkillThreshold=365,upperSkillTreshold=365,bonusStats={}},
}
C_TradeSkillUI={
    IsTradeSkillLinked=function()return linked end,
    GetRecipeInfo=function()return clone(recipe)end,
    GetItemReagentQualityByItemInfo=function(link)return tonumber(link:match('%d+'))==10 and 1 or 2 end,
    GetProfessionInfoByRecipeID=function()return {professionID=1,parentProfessionName='Jewelcrafting',skillLevel=100,skillModifier=0}end,
    GetCraftingOperationInfo=function(recipeID,allocation,guid,concentration)
        calls[#calls+1]={recipe=recipeID,allocation=allocation,guid=guid,concentration=concentration}
        return guid and clone(operations[guid]) or {baseSkill=100,bonusSkill=0}
    end,
    CraftSalvage=function()error('observer must not invoke crafting')end,
}
local LL={db={characters={Player={},Alt={}},rateProfile=1}}
for _,file in ipairs({'Professions.lua','ConversionEngine.lua'})do assert(loadfile('LootLiquidator/'..file))('LL',LL)end
LL.CharacterKey=function()return 'Player'end
LL.Invalidate=function(self)self._professionOperationCache=nil;self._processingContextCache=nil end
LL.GetResearchProfessionSnapshot=function()return 100,'none' end
local f={id=10,reagentQuality=1,expansionID=11,context={bagID=0,slotID=1}}
local second={id=11,reagentQuality=2,expansionID=11,context={bagID=0,slotID=2}}
local info=LL:GetCachedOperationInfo(1231127,f)
same(info.craftingQuality,1);same(calls[1].guid,'Item-ten');same(calls[1].concentration,false)
LL:GetCachedOperationInfo(1231127,f);same(#calls,1,'same exact allocation is cached')
LL:GetCachedOperationInfo(1231127,second);same(#calls,2,'input rank/GUID do not collide in recipe cache')
same(calls[2].guid,'Item-eleven')
local snapshot=assert(LL:GetSkillQualityOperation(f,1231127,'Player'))
same(snapshot.highQualitySkillThreshold,365);same(snapshot.inputItemID,10);same(snapshot.inputQualityRank,1)
check(snapshot.allocationVerified and snapshot.concentration==false)
same(snapshot.effectiveSkill,360);same(snapshot.craftingQuality,1);same(snapshot.build,'70783')
snapshot.highQualitySkillThreshold=1
same(LL:GetSkillQualityOperation(f,1231127,'Player').highQualitySkillThreshold,365,'returned contexts are clones')
local top=LL:GetSkillQualityOperation(second,1231127,'Player')
same(top.highQualitySkillThreshold,365,'top-rank operation supplies its lower boundary')
same(top.craftingQuality,2)
LL:GetCachedOperationInfo(1231127)
same(calls[#calls].guid,nil,'legacy recipe-only reads remain unqualified')
local bad={id=10,reagentQuality=2,expansionID=11,context={bagID=0,slotID=1}}
same(LL:GetCachedOperationInfo(1231127,bad),nil,'item rank mismatch cannot qualify')
local missing={id=99,reagentQuality=1,expansionID=11,context={allocationItemGUID='Item-ten'}}
local before=#calls
same(LL:GetCachedOperationInfo(1231127,missing),nil,'raw GUID cannot stand in for item validation')
same(#calls,before,'no target means no fabricated API allocation')
local moved=clone(f);moved.context={bagID=0,slotID=2}
same(LL:FindSkillQualityTarget(moved),'Item-ten','fallback finds an actually matching inventory stack')
linked=true
same(LL:GetSkillQualityOperation(f,1231127,'Player'),nil,'linked profession cannot refresh a live claim')
check(LL:GetSkillQualityOperation(f,1231127,'Player',true),'explicit simulated context may use its own stored boundary')
same(LL:GetSkillQualityOperation(f,1231127,'Alt',true),nil,'another character cannot borrow current snapshot')
LL.db.characters.Alt.skillQualityOperations=clone(LL.db.characters.Player.skillQualityOperations)
same(LL:GetSkillQualityOperation(f,1231127,'Alt',true),nil,'stored character identity is checked')
currentBuild='different'
same(LL:GetSkillQualityOperation(f,1231127,'Player',true),nil,'old-build snapshots are rejected')
currentBuild='70783';linked=false
local wrong=clone(f);wrong.expansionID=10
same(LL:GetSkillQualityOperation(wrong,1231127,'Player',true),nil,'expansion identity is checked')
-- Changed operation information must not leave an earlier qualifying boundary
-- available for a live quote, and baseDifficulty is never a fallback threshold.
recipe.maxQuality=3;LL:Invalidate()
same(LL:GetSkillQualityOperation(f,1231127,'Player'),nil,'three-rank operations need their own model')
check(not LL.db.characters.Player.skillQualityOperations['1231127:10'],'failed qualification clears older live snapshot')
recipe.maxQuality=2
local original=clone(operations['Item-ten'])
operations['Item-ten'].upperSkillTreshold=nil;LL:Invalidate()
same(LL:GetSkillQualityOperation(f,1231127,'Player'),nil,'difficulty cannot replace an absent threshold')
operations['Item-ten']=clone(original);operations['Item-ten'].baseSkill=105;LL:Invalidate()
same(LL:GetSkillQualityOperation(f,1231127,'Player'),nil,'quality and skill must agree with the threshold')
operations['Item-ten']=clone(original);LL:Invalidate()
check(LL:GetSkillQualityOperation(f,1231127,'Player'))
-- A manual target receives only its selected character's threshold metadata;
-- measured source skill/quality must not replace the requested simulated skill.
check(LL:SetManualProfessionProfile('Player','Jewelcrafting',11,{enabled=true,skill=400,specialization='none'}))
LL.db.rateProfile=3
local context=LL:ProcessingPlayerConditions(f,'Prospect',1231127)
same(context.effectiveSkill,400);same(context.craftingQuality,nil);check(context.simulated)
same(context.skillQualityOperation.effectiveSkill,360,'source snapshot remains measured context')
same(context.skillQualityOperation.highQualitySkillThreshold,365)
context.skillQualityOperation.highQualitySkillThreshold=1
same(LL.db.characters.Player.skillQualityOperations['1231127:10'].highQualitySkillThreshold,365)
-- The isolated hypothetical tooltip proxy deliberately hides real skill/gear,
-- but must retain the selected character's measured boundary for projection.
LL.db.rateProfile=1;LL.db.professionTooltipProfiles={Jewelcrafting='@hypothetical'}
LL.ConversionOptions=function(self,facts)
    return {{name='Prospect',recipeID=1231127,profession='Jewelcrafting',available=false,
        yieldModel={context=self:ProcessingPlayerConditions(facts,'Prospect',1231127)}}}
end
local displayed=LL:TooltipConversionOptions(f,{{name='Prospect',recipeID=1231127,profession='Jewelcrafting'}})
same(displayed[1].yieldModel.context.effectiveSkill,400)
same(displayed[1].yieldModel.context.skillQualityOperation.highQualitySkillThreshold,365)
same(LL.db.rateProfile,1,'display projection leaves normal rates unchanged')
-- Genuine salvage requests pass their item GUID into read-only research calls.
-- No crafting API is ever invoked by the observer.
assert(loadfile('LootLiquidator/CraftRecording.lua'))('LL',LL)
check(hooks.CraftSalvage,'salvage request hook is registered')
local raw=LL:CaptureCraftContext(1231127,f,'Prospect',{},false,'Item-ten')
same(calls[#calls].guid,'Item-ten');same(raw.lowerSkillThreshold,0);same(raw.upperSkillTreshold,365)
same(raw.baseDifficulty,365);check(raw.allocationVerified)
same(raw.operationInputItemID,10);same(raw.simulated,false)
stacks['0:3']={id=10,guid='Item-ten-second-stack',rank=1}
operations['Item-ten-second-stack']=clone(operations['Item-ten'])
C_Container.GetContainerNumSlots=function(bag)return bag==0 and 3 or 0 end
same(LL:FindSkillQualityTarget(f),'Item-ten','ordinary lookup can use the first matching stack')
same(LL:FindSkillQualityTarget(f,'Item-ten-second-stack'),'Item-ten-second-stack',
    'cast verification must find the exact selected stack among matching items')
local otherStack=LL:CaptureCraftContext(1231127,f,'Prospect',{},false,'Item-ten-second-stack')
check(otherStack.allocationVerified and otherStack.operationInputItemID==10,
    'another legitimate stack cannot lose its exact allocation context')
local concentrated=LL:CaptureCraftContext(1231127,f,'Prospect',{},true,'Item-ten')
same(concentrated.allocationVerified,nil,'concentrated operations do not qualify an unassisted boundary')
LL.db.recordConversions=true
LL.SnapshotCraftBags=function()return {counts={[10]=5},facts={[10]=f},variants={[10]={['item:10']=true}}}end
local measured=LL.CaptureCraftContext
local capturedGUID,capturedContext
LL.CaptureCraftContext=function(self,recipeID,facts,method,allocation,concentrating,guid)
    capturedGUID=guid
    capturedContext=measured(self,recipeID,facts,method,allocation,concentrating,guid)
    return capturedContext
end
hooks.CraftSalvage(1231127,1,'0:3',nil,false)
check(LL:BeginCraftCapture('salvage-test',1231127))
same(capturedGUID,'Item-ten-second-stack','observed salvage target reaches cast context capture')
check(capturedContext.allocationVerified,'actual cast keeps its exact target when bags contain several stacks')
print('PASS: '..count..' exact salvage skill-quality capture, scope, threshold, simulation and observer assertions')
