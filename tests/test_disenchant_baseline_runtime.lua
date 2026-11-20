-- Real compiled baseline -> current/manual profile -> material means -> price.
local checks=0
local function check(value,label) assert(value,label);checks=checks+1 end
local function near(actual,expected,label)
    check(type(actual)=='number' and math.abs(actual-expected)<1e-8,
        (label or '')..': '..tostring(actual)..' ~= '..tostring(expected))
end
local function copy(value)
    if type(value)~='table' then return value end
    local result={} for key,item in pairs(value) do result[key]=copy(item) end return result
end
GetBuildInfo=function() return '12.1.5','70961','Nov 18 2026',120105 end
GetTime=function() return 100 end
time=function() return 100 end
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
GetItemInfo=function(id) return 'Item '..tostring(id) end
local LL={db={characters={Player={professions={Enchanting=true}}},
    rateProfile=3,rateProfileCharacter='Player',source_legacy_enabled=false,
    source_reference_enabled=true,source_personal_enabled=false,source_imported_enabled=false}}
for _,file in ipairs({'ItemDBRuntime.lua','ProfessionCatalog.lua','Professions.lua',
    'ProfessionModels.lua','Database.lua','ConversionEngine.lua','Observations.lua','Badges.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LL',LL)
end
LL.CharacterKey=function() return 'Player' end
LL.GetResearchProfessionSnapshot=function(self)
    local saved=self.db.characters.Player.researchProfiles
    saved=saved and saved['Enchanting:11']
    return saved and saved.skill or 0,saved and saved.specialization or 'none',7946
end
LL.GetCachedOperationInfo=function() end
LL.GetOutputPrice=function(_,id)
    return (id==243600 or id==243603 or id==243606) and 300 or 100
end
LL.MarkupColor=function() return '' end
LL.Money=function(_,value) return tostring(value)..' copper' end
LL.ProfessionProgression=function() return {} end
LL.Invalidate=function(self) self._processingModelCache=nil;self._processingContextCache=nil end
LL:MigrateEvidenceSettings()
check(LL:InitializeItemDB(),LL.itemDBError)
check(#(LL.ItemDB.modeledDisenchantBaselines or {})==6,'real compiler exports six physical category baselines')
local de={name='Disenchant',recipeID=13262,inputCount=1}
local cases={
    {rarity=2,child=107648,low=243599,high=243600,total=2.9,share=.65,armorConfidence=10,weaponConfidence=5},
    {rarity=3,child=107647,low=243602,high=243603,total=1.289,share=.660/1.289,armorConfidence=30,weaponConfidence=15},
    {rarity=4,child=107646,low=243605,high=243606,share=.66,armorConfidence=20,weaponConfidence=20},
}
local function facts(case,classID)
    return {id=999900+case.rarity*10+classID,expansionID=11,quality=case.rarity,classID=classID,count=1}
end
local function set(case,root,child,native,benchmark)
    LL.db.rateProfile=3
    check(LL:SetManualProfessionProfile('Player','Enchanting',11,{enabled=true,skill=native,
        specialization='107649='..root..','..case.child..'='..child,buffs={},benchmark=benchmark}),
        'manual profile accepted')
end
local function resolve(f,mode)
    LL:Invalidate()
    return LL:ResolveEvidenceModel(f,de,nil,mode or 1)
end
local function output(model,id)
    for _,material in ipairs(model and model.materials or {}) do if material.id==id then return material end end
end
local function mean(model,id) return assert(output(model,id),'missing material '..id).expectedQuantity end
local function pool(model,case) return mean(model,case.low)+mean(model,case.high) end
local essenceIDs={[236949]=true,[236950]=true,[236951]=true,[236952]=true}
local function valued(model,f)
    LL:ValueProcessingModel(model,0,true,f)
    return model.value or model.partialValue
end
local function rendered(f,model)
    LL.db.tooltipDetail=3;LL.db.showAverageQuantity=true;LL.db.showProfessionDetails=true
    local tip={lines={}}
    function tip:AddLine(text) self.lines[#self.lines+1]=text end
    function tip:AddDoubleLine(left,right) self.lines[#self.lines+1]=left..' | '..right end
    LL:AppendRecommendationTooltip(tip,{action='D',facts=f,disenchantEligible=true,
        conversionOptions={{name='Disenchant',letter='D',profession='Enchanting',recipeID=13262,
            inputCount=1,available=true,yieldModel=model,value=model.value or model.partialValue}}})
    return table.concat(tip.lines,'\n')
end
for _,case in ipairs(cases) do for _,classID in ipairs({2,4}) do
    local f=facts(case,classID)
    set(case,0,0,0)
    local zero=assert(resolve(f))
    check(zero.disenchantBaselineApplied,'actual resolver consumes the compiled baseline')
    local expectedConfidence=classID==4 and case.armorConfidence or case.weaponConfidence
    if case.rarity==4 then
        check(zero.confidence>0 and zero.confidence<=expectedConfidence,'Crystal confidence respects its category cap')
    else near(zero.confidence,expectedConfidence,'category uncertainty cap') end
    set(case,10,10,20)
    local lowSkill=assert(resolve(f));local lowValue=valued(lowSkill,f)
    set(case,10,10,100)
    local highSkill=assert(resolve(f));local highValue=valued(highSkill,f)
    check(mean(highSkill,case.high)>mean(lowSkill,case.high),'native skill changes top-rank units')
    check(highValue>lowValue,'native skill changes the priced tooltip output')
    near(pool(highSkill,case),pool(lowSkill,case),'quality redistribution conserves the selected primary pool')
    set(case,30,30,140)
    local full=assert(resolve(f));near(full.context.effectiveSkill,290,'native and specialization skill apply once')
    near(full.specializationSkillBonus,150,'full root and matching child add 150 skill')
    near(pool(full,case),case.total or pool(zero,case),'full primary endpoint')
    near(mean(full,case.high)/pool(full,case),case.share,'full endpoint rank mix')
    if case.rarity==4 then
        near(pool(full,case),pool(zero,case),'Crystal total is preserved')
        local extras=0
        for id in pairs(essenceIDs) do extras=extras+mean(full,id) end
        near(extras,.289,'full Crystal allocation includes its additive essence budget')
    end
    for _,material in ipairs(full.materials) do
        check(material.expectedQuantity>=0,'projected means remain nonnegative')
        check(material.chance==nil and material.samples==nil and material.quantityCounts==nil
            and material.minQuantity==nil and material.maxQuantity==nil,
            'projection invents neither hit probabilities, sample counts nor stack distributions')
        if essenceIDs[material.id] then near(material.confidence,5,'native essence uncertainty cap')
        else near(material.confidence,expectedConfidence,'per-material confidence respects the model cap') end
    end
    check(full.samples==nil and full.effectiveSamples==nil,'raw source sample counts are not model observations')
    local again=LL:ResolveEvidenceModel(f,de,nil,1)
    check(again==full,'same profile reuses its cached result')
    check(LL:ApplyDisenchantBaseline(f,de,full,full.context,1)==full,'an already projected model is idempotent')
    valued(full,f)
    local text=rendered(f,full):lower()
    for _,word in ipairs({'estimate','provisional','unquantified'}) do
        check(not text:find(word,1,true),'tooltip uses confidence without a '..word..' label')
    end
    local notes=table.concat(LL:ProfessionSimulationEffectNotes(f,de,full),'\n')
    check(notes:find('30 / 30 points.',1,true) and notes:find('Simulated skill: 290',1,true),
        'details contain the selected points and effective skill')

    -- Live expansion snapshots use normalized points and the profession/tool
    -- skill anchor, rather than a generic operation's already boosted skill.
    local manualMeans={}
    for _,material in ipairs(full.materials) do manualMeans[material.id]=material.expectedQuantity end
    LL.db.characters.Player.researchProfiles={['Enchanting:11']={skill=100,bonusSkill=40,
        specialization='captured-current-ranks',specializationVerified=true,observed=100,
        specializationSignatureEncoding='trait-node-current-rank',
        disenchantSpecializationEncoding='invested-points',disenchantSpecializationKnown=true,
        disenchantSpecializationPoints={['107649']=30,[tostring(case.child)]=30},
        disenchantLearnedSpecializations={['107649']=true,[tostring(case.child)]=true}}}
    LL.db.rateProfile=1
    LL.GetCachedOperationInfo=function() return {baseSkill=100,bonusSkill=999} end
    local live=assert(resolve(f))
    check(live.disenchantBaselineApplied and not live.context.simulated,'verified live snapshot reaches the same baseline')
    near(live.context.preSpecializationSkill,140,'live anchor includes profession skill and tool modifier')
    near(live.context.effectiveSkill,290,'generic operation bonus is not double-counted')
    for id,value in pairs(manualMeans) do near(mean(live,id),value,'live/manual material parity') end
    LL.GetCachedOperationInfo=function() end
    LL.db.rateProfile=3
end end

local supplier=cases[2];local rare=facts(supplier,4)
set(supplier,0,9,100)
local nine=assert(resolve(rare));local nineValue=valued(nine,rare)
set(supplier,0,10,100)
local ten=assert(resolve(rare))
near(ten.context.effectiveSkill-nine.context.effectiveSkill,6,'Supplier 9 to 10 adds one point and five milestone skill')
check(mean(ten,supplier.high)>mean(nine,supplier.high) and valued(ten,rare)>nineValue,
    'Supplier 9 to 10 changes material units and gold value')
for _,case in ipairs({cases[1],supplier}) do
    local f=facts(case,4)
    set(case,0,19,100);local nineteen=assert(resolve(f))
    set(case,0,20,100);local twenty=assert(resolve(f))
    set(case,0,29,100);local twentyNine=assert(resolve(f))
    set(case,0,30,100);local thirty=assert(resolve(f))
    check(pool(twenty,case)>pool(nineteen,case),'rank 20 advances pooled quantity')
    near(pool(twentyNine,case),pool(twenty,case),'quantity remains stable between quantity milestones')
    check(pool(thirty,case)>pool(twentyNine,case),'rank 30 advances pooled quantity')
end

for _,case in ipairs(cases) do
    local f=facts(case,4);set(case,30,30,140)
    LL.db.source_itemdb_enabled=false
    local disabled=resolve(f)
    check(not disabled or not disabled.disenchantBaselineApplied,'disabled ItemDB blocks modeled projection')
    LL.db.source_itemdb_enabled=true;LL.db.source_itemdb_weight=0
    disabled=resolve(f)
    check(not disabled or not disabled.disenchantBaselineApplied,'zero ItemDB weight blocks modeled projection')
    LL.db.source_itemdb_weight=nil;LL.db.source_reference_enabled=false
    disabled=resolve(f)
    check((not not (disabled and disabled.disenchantBaselineApplied))==(case.rarity==3),
        'reference endpoint policy is independent from Supplier itemdb evidence')
    LL.db.source_reference_enabled=true;LL.db.source_reference_weight=0
    disabled=resolve(f)
    check((not not (disabled and disabled.disenchantBaselineApplied))==(case.rarity==3),'zero reference weight is respected')
    LL.db.source_reference_weight=nil
    local personalOnly=resolve(f,2)
    check(not personalOnly or not personalOnly.disenchantBaselineApplied,'personal-only mode is protected')
end

set(supplier,30,30,140)
local unscaled=assert(resolve(rare))
set(supplier,30,30,140,{outputLevel=150,specializationBonus=20})
local benchmark=assert(resolve(rare))
check(benchmark.disenchantBaselineApplied and benchmark.syntheticBenchmark,'benchmark runs after profile projection')
for _,material in ipairs(unscaled.materials) do
    near(mean(benchmark,material.id),material.expectedQuantity*1.8,'benchmark scales projected output exactly once')
end
check(LL:ApplySyntheticBenchmark(rare,de,benchmark,benchmark.context)==benchmark,'benchmark replay is idempotent')
check(LL:ResolveEvidenceModel(rare,de,nil,1)==benchmark,'benchmark cache retains the once-scaled result')
print('DISENCHANT BASELINE RUNTIME: '..checks..' checks passed')
