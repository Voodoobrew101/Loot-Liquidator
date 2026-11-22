-- Exact native operation quality maps one entire family to one output grade.
-- The controlled family distribution is a fixture, not an asserted game rate.
local now,buffed,linked=100,true,false
GetTime=function()return now end;time=GetTime
GetBuildInfo=function()return '12.1.5','70783'end
SlashCmdList={};hooksecurefunc=function()end
wipe=function(t)for key in pairs(t)do t[key]=nil end end
local frames={}
CreateFrame=function()
    local frame={events={}}
    function frame:RegisterEvent(event)self.events[event]=true end
    function frame:SetScript(name,fn)self[name]=fn end
    frames[#frames+1]=frame;return frame
end
local input,recipeID=237362,1231127
ItemLocation={CreateFromBagAndSlot=function(_,bag,slot)return bag==0 and slot==1 and 'input' end}
C_Item={GetItemID=function(location)return location=='input' and input end,
    GetItemGUID=function(location)return location=='input' and 'Item-UmbralTin' end}
C_TradeSkillUI={
    IsTradeSkillLinked=function()return linked end,
    GetRecipeInfo=function()return {supportsQualities=true,maxQuality=2,isSalvageRecipe=true}end,
    GetItemReagentQualityByItemInfo=function()return 1 end,
    GetCraftingOperationInfo=function(id,allocation,guid,concentration)
        assert(id==recipeID and guid=='Item-UmbralTin' and concentration==false)
        return {recipeID=id,isQualityCraft=true,baseSkill=100,bonusSkill=buffed and 265 or 264,
            craftingQuality=buffed and 2 or 1,baseDifficulty=365,bonusDifficulty=0,
            lowerSkillThreshold=buffed and 365 or 0,upperSkillTreshold=365,bonusStats={}}
    end,
}
local LL={db={enabled=true,characters={Player={professions={Jewelcrafting=true}}}}}
for _,name in ipairs({'Core.lua','ProfessionModels.lua','Database.lua','Professions.lua','ConversionEngine.lua'})do
    assert(loadfile('LootLiquidator/'..name))('LootLiquidator',LL)
end
local rules=assert(loadfile('database/skill-quality-rules.lua'))().skillQualityRules
local rule
for _,candidate in ipairs(rules)do if candidate.recipeID==recipeID then rule=candidate end end
local low,high=rule.outputFamilies[1].rankItemIDs[1],rule.outputFamilies[1].rankItemIDs[2]
local function field(value)return {value=value,status='measured',confidence=90,samples=100}end
local source={recordID='native-family-distribution-fixture',studyID='fixture',source='controlled family fixture',
    sourceKey='itemdb',fixedReference=true,referenceConditions={},method='Prospect',recipeID=recipeID,
    inputItemID=input,inputCount=5,expansionID=11,materials={{id=low,rankIDs={low,high},
        expectedQuantity=field(2),dropChance=field(.5),minQuantity=field(2),maxQuantity=field(6)}}}
LL.ItemDB={schemaVersion=1,version='native-family-distribution-fixture',processing={source},
    mechanicRules={},skillQualityRules=rules}
LL.CharacterKey=function()return 'Player'end
LL.GetResearchProfessionSnapshot=function()return 100,'none'end
LL.ProfessionAuraState=function()return buffed and {['123']=true} or {},{},true end
LL.GetOutputPrice=function(_,id)return id==high and 300 or 100 end
LL:MigrateEvidenceSettings();assert(LL:InitializeItemDB(),LL.itemDBError)
local facts={id=input,classID=7,quality=1,reagentQuality=1,expansionID=11,count=5,context={bagID=0,slotID=1}}
local option={name='Prospect',recipeID=recipeID,inputCount=5}
local function resolve()return assert(LL:ResolveEvidenceModel(facts,option,nil,1))end
local function distribution(model,id,pooled)
    assert(#model.materials==1,'One family event must not become independent rank rows')
    local material=model.materials[1]
    assert(material.id==id and (material.rankIDs~=nil)==pooled)
    assert(material.expectedQuantity==2 and material.chance==.5)
    assert(material.minQuantity==2 and material.maxQuantity==6,
        'One-to-one native quality assignment must retain family occurrence and positive stack bounds')
    return material
end
LL:RefreshProfessionAuraFingerprint()
local gold=resolve()
distribution(gold,high,false)
assert(gold.skillQualityApplied and gold.skillQualityRank==2,'Native quality2 is reached at the exact boundary')
assert(LL:ValueProcessingModel(gold,0,true,facts)==120,'Native routing retains its ordinary yield-based valuation')
assert(LL:ApplySkillQualityModel(facts,option,gold,LL:ProcessingPlayerConditions(facts,'Prospect',recipeID))==gold)
buffed=false
for _,frame in ipairs(frames)do if frame.events.UNIT_AURA then frame.OnEvent(frame,'UNIT_AURA','player') end end
local silver=resolve()
distribution(silver,low,false)
assert(silver.skillQualityRank==1,'Buff loss refreshes the exact native quality below its boundary')
assert(LL:ValueProcessingModel(silver,0,true,facts)==40)
linked=true;LL:Invalidate()
local unqualified=resolve()
distribution(unqualified,low,true)
assert(not unqualified.skillQualityApplied,'Unavailable native allocation must preserve the family fallback')
local manual={simulated=true,profileKind='manual-simulation',character='Player',effectiveSkill=365,
    skillQualityOperation=LL.db.characters.Player.skillQualityOperations[tostring(recipeID)..':'..tostring(input)]}
local simulated=LL:ApplySkillQualityModel(facts,option,unqualified,manual)
assert(simulated.materials[1].id==high and simulated.materials[1].expectedQuantity==2)
assert(simulated.materials[1].chance==nil and simulated.materials[1].minQuantity==nil,
    'A simulated boundary must not claim an observed rank distribution')
local overlap={inputCount=5,materials={
    {id=low,rankIDs={low,high},expectedQuantity=2,chance=.5,minQuantity=2,maxQuantity=6},
    {id=high,expectedQuantity=1},
}}
manual.simulated=false;manual.profileKind='live'
assert(LL:ApplySkillQualityModel(facts,option,overlap,manual)==overlap,
    'An overlapping family and exact grade cannot be redistributed as one event')
assert(source.materials[1].dropChance.value==.5 and source.materials[1].minQuantity.value==2
    and source.materials[1].maxQuantity.value==6 and source.materials[1].rankIDs[1]==low,
    'Native projection, buff changes and fallback never mutate source evidence')
print('PASS: actual native quality preserves one family distribution, buff boundary, fallback, simulation isolation and source evidence')
