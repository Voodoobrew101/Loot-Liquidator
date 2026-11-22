-- Repeated native tooltip repolls must reuse isolated display calculations.
-- Skills/yields/prices below are deterministic fixtures, not game drop claims.
local now,frames=100,{}
GetTime=function()return now end;time=GetTime
CreateFrame=function()
    local frame={events={}}
    function frame:RegisterEvent(event)self.events[event]=true end
    function frame:SetScript(name,fn)self[name]=fn end
    frames[#frames+1]=frame;return frame
end
SlashCmdList={};hooksecurefunc=function()end
wipe=function(t)for key in pairs(t)do t[key]=nil end end
local LL={}
for _,name in ipairs({'Core.lua','Professions.lua','ConversionEngine.lua'})do
    assert(loadfile('LootLiquidator/'..name))('LootLiquidator',LL)
end
local function character(skill)
    return {professions={Inscription=true},recipes={[100]={learned=true}},
        researchProfiles={['Inscription:9']={skill=skill,specialization='none',observed=now}}}
end
LL.db={enabled=true,characters={Player=character(10),Alt=character(40)},
    professionTooltipProfiles={Inscription='Player'},manualProfessionProfiles={
        Player={['Inscription:9']={enabled=true,skill=90,specialization='none'}}}}
LL.ItemDB={version='projection-cache-fixture'}
LL.CharacterKey=function()return 'Player'end
LL.GetResearchProfessionSnapshot=function()return 10,'none'end
LL.GetCachedOperationInfo=function()end
LL.EligibleDisenchant=function()return false end
LL.Conversions={[1]={{method='Mill',profession='Inscription',recipeID=100,inputCount=5}}}
local activeBuff,pricesKnown,state,calls=false,true,'valid',0
LL.ProfessionAuraState=function()
    return activeBuff and {['123']=true} or {},{},true
end
LL.GetOutputPrice=function(_,id)return id==10 and 100 or pricesKnown and 50 or nil end
LL.ResolveEvidenceModel=function(self,f,option)
    calls=calls+1
    if state=='missing' then return nil,'Sibling item name is loading' end
    local ctx=self:ProcessingPlayerConditions(f,option.name,option.recipeID,option.character)
    local amount=state=='zero' and 0 or (ctx.effectiveSkill or 0)/10+(ctx.buffs and ctx.buffs['123'] and 1 or 0)
    local materials={{id=10,expectedQuantity=amount,confidence=80}}
    if state=='partial' then materials[#materials+1]={id=11,expectedQuantity=1,confidence=80} end
    return {inputCount=5,confidence=80,context=ctx,materials=materials}
end
local f={id=1,classID=7,quality=1,reagentQuality=1,count=5,expansionID=9,
    link='item:1',context={verifiedUnbound=true}}
local original=LL:ConversionOptions(f)
local originalModel=original[1].yieldModel
local function project(selection,facts,candidates)
    LL.db.professionTooltipProfiles.Inscription=selection or 'Player'
    return LL:TooltipConversionOptions(facts or f,candidates or original)
end
local first=project('Player')[1]
local computed=calls
for _=1,75 do assert(project('Player')[1].yieldModel==first.yieldModel) end
assert(calls==computed,'Native repolls must reuse the selected-profile calculation')
assert(first.value==20 and first.yieldModel.context.character=='Player')
assert(project('Alt')[1].value==80,'Selected alt has its own scanned profile')
assert(project('@hypothetical')[1].value==180,'Hypothetical keeps manual rates isolated')
assert(project('@auto')[1]==original[1] and #project('@hide')==0)
assert(original[1].yieldModel==originalModel and original[1].value==20,
    'Display caches must preserve the recommendation model and value')
LL.ProcessingMethodMode=function()return 4 end
LL.AltMethodEnabled=function()return true end
LL.db.characters.Player.altMethods={M=true}
assert(project('Player')[1].value==20 and not project('Player')[1].yieldModel.context.simulated,
    'Named current character must use scanned skill rather than manual skill')
assert(project('@hypothetical')[1].value==180)
LL.db.characters.Player.altMethods=nil
LL.ProcessingMethodMode=function()return 2 end
LL:Invalidate()
first=project('Player')[1];computed=calls
now=now+5
assert(project('Player')[1].yieldModel~=first.yieldModel and calls==computed+1,'Expired quotes must refresh')
LL:RefreshProfessionAuraFingerprint()
first=project('Player')[1]
activeBuff=true
for _,frame in ipairs(frames)do
    if frame.events.UNIT_AURA then frame.OnEvent(frame,'UNIT_AURA','player') end
end
assert(LL._tooltipProjectionCache==nil,'Real player buff event must clear display projections immediately')
assert(project('Player')[1].value==40 and first.value==20,'The next tooltip uses the changed live buff')
local before=calls
local altered={} for key,value in pairs(f)do altered[key]=value end
altered.count=6;project('Player',altered)
altered.count=5;altered.reagentQuality=2;project('Player',altered)
altered.reagentQuality=1;altered.link='item:1:changed';project('Player',altered)
altered.link=f.link;altered.context={isBound=true,isSoulbound=true};project('Player',altered)
local otherCandidates={{name='Mill',profession='Inscription',recipeID=101,inputCount=5}}
project('Player',f,otherCandidates)
assert(calls==before+5,'Stack, reagent rank, item link, instance binding and candidate changes have separate scopes')
LL:Invalidate();state='missing'
assert(project('Player')[1].yieldModel==nil)
state='valid';assert(project('Player')[1].value==40,'A pending sibling name must retry before the cache TTL')
LL:Invalidate();state='partial';pricesKnown=false
assert(project('Player')[1].yieldModel.partialPrice)
computed=calls;pricesKnown=true
assert(not project('Player')[1].yieldModel.partialPrice and calls==computed+1,'Missing prices must retry immediately')
LL:Invalidate();state='zero'
assert(project('Player')[1].value==0);computed=calls
assert(project('Player')[1].value==0 and calls==computed,'A complete zero-value quote is reusable')
LL:Invalidate();state='valid'
local conversionOptions=LL.ConversionOptions
LL.ConversionOptions=function()return {}end
assert(#project('Player')==0)
LL.ConversionOptions=conversionOptions
assert(project('Player')[1].value==40,'An empty transient projection must retry immediately')
first=project('Player')[1];computed=calls
LL.ItemDB.version='projection-cache-fixture-2'
assert(project('Player')[1].yieldModel~=first.yieldModel and calls==computed+1,'A native database revision invalidates cached projections')
LL:Invalidate()
for i=1,150 do
    now=now+.001
    local facts={} for key,value in pairs(f)do facts[key]=value end
    facts.id=1000+i;LL.Conversions[facts.id]=LL.Conversions[1]
    project('Player',facts)
end
assert(LL._tooltipProjectionCache.count==128,'Rapid distinct inputs must remain bounded')
local entries=0 for _ in pairs(LL._tooltipProjectionCache.entries)do entries=entries+1 end
assert(entries==128,'Cache count must match retained quote entries')
now=now+5;project('Player')
assert(LL._tooltipProjectionCache.count==1,'Expired item projections must release on later tooltip reads')
print('PASS: projection reuse, scanned/manual/alt isolation, live buff invalidation, fact scopes, async retries, zero values, expiry and cap')
