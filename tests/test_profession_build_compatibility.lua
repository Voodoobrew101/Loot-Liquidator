-- Client build updates within a researched patch must preserve both the editor
-- capability and the calculation it exposes. Operation captures stay build exact.
local checks=0
local function check(value,label) assert(value,label);checks=checks+1 end
local function near(actual,expected,label)
    check(type(actual)=='number' and math.abs(actual-expected)<1e-8,
        (label or '')..': '..tostring(actual)..' ~= '..tostring(expected))
end
local version,build='12.1.5','70961'
GetBuildInfo=function() return version,build,'Nov 18 2026',120105 end
GetTime=function() return 100 end
time=function() return 100 end
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
local LL={db={characters={Player={professions={Enchanting=true,Jewelcrafting=true,Inscription=true}}},
    rateProfile=3,rateProfileCharacter='Player',source_legacy_enabled=false,
    source_reference_enabled=false,source_personal_enabled=false,source_imported_enabled=false}}
for _,file in ipairs({'ItemDBRuntime.lua','ProfessionCatalog.lua','Professions.lua',
    'ProfessionModels.lua','Database.lua','ConversionEngine.lua','Badges.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LL',LL)
end
LL.CharacterKey=function() return 'Player' end
LL.GetResearchProfessionSnapshot=function() return 0,'none' end
LL.GetCachedOperationInfo=function() end
LL.GetOutputPrice=function(_,id) return id%2==0 and 100 or 300 end
LL.MarkupColor=function() return '' end
LL.Money=function(_,value) return tostring(value)..' copper' end
LL.ProfessionProgression=function() return {} end
LL.Invalidate=function(self) self._processingModelCache=nil;self._processingContextCache=nil end
LL:MigrateEvidenceSettings()
check(LL:InitializeItemDB(),LL.itemDBError)

check(LL:ProfessionRuleMatchesBuild({build=70961}),'legacy exact-build rule still works')
check(not LL:ProfessionRuleMatchesBuild({build=70783}),'legacy rules do not gain implicit compatibility')
local compatible={build=70783,clientVersion='12.1.5'}
check(LL:ProfessionRuleMatchesBuild(compatible),'explicit patch scope survives the installed build update')
version='12.1.6'
check(not LL:ProfessionRuleMatchesBuild(compatible),'another patch needs its own compatibility review')
version='12.1.5';build='70782'
check(not LL:ProfessionRuleMatchesBuild(compatible),'compatibility does not run evidence backwards')
build='70961'
local function support(profession,expansion) return LL:GetProfessionSimulationControlSupport(profession,expansion) end
local expected={
    {'Enchanting',11,true,{'107646','107647','107648','107649'}},
    {'Enchanting',10,true,{'99887','99888','99889','99890'}},
    {'Inscription',9,true,{'34832','34835'}},
    {'Inscription',10,true,{'101625','101627'}},
    {'Inscription',11,true,{'109653','109655','109660'}},
    {'Jewelcrafting',11,true,{'106982','106983'}},
    {'Jewelcrafting',10,false,{'98659','98660','98661','98662'}},
}
for _,clientBuild in ipairs({'70783','70961'}) do
    build=clientBuild
    for _,row in ipairs(expected) do
        local capability=support(row[1],row[2])
        check(capability.skill==row[3],row[1]..' base skill capability on '..build)
        local count=0 for _ in pairs(capability.nodes) do count=count+1 end
        check(count==#row[4],row[1]..' exact known-effect node coverage on '..build)
        for _,id in ipairs(row[4]) do check(capability.nodes[id],row[1]..' node '..id..' on '..build) end
        check(not next(capability.stats) and not next(capability.buffs),
            'captured stats and buffs without output formulas are not advertised')
    end
end
build='70961';version='12.1.6'
for _,row in ipairs(expected) do
    check(not next(support(row[1],row[2]).nodes),'unreviewed patch hides specialization rules')
end
version='12.1.5'
local function set(profession,expansion,points,skill)
    check(LL:SetManualProfessionProfile('Player',profession,expansion,
        {enabled=true,skill=skill or 0,specialization=points,buffs={}}),'manual profile saves')
end
local function resolve(facts,option)
    LL:Invalidate()
    return assert(LL:ResolveEvidenceModel(facts,option,nil,1))
end
local function output(model,id)
    for _,material in ipairs(model.materials) do if material.id==id then return material end end
end
local rare={id=999992,expansionID=11,quality=3,classID=4,count=1}
local disenchant={name='Disenchant',recipeID=13262,inputCount=1}
set('Enchanting',11,'none')
local ordinary=resolve(rare,disenchant)
set('Enchanting',11,'107649=30,107647=30')
local specialized=resolve(rare,disenchant)
check(specialized.specializationEffectsApplied,'both point sliders reach the actual category resolver on 70961')
near(output(specialized,243602).expectedQuantity,.629,'measured low-rank shard mean')
near(output(specialized,243603).expectedQuantity,.660,'measured high-rank shard mean')
check(specialized.referenceContextID~=ordinary.referenceContextID,'the full allocation selects its measured cohort')
set('Enchanting',11,'107649=30,107647=29')
local below=resolve(rare,disenchant)
check(not below.specializationEffectsApplied,'a below-cap allocation cannot claim the full-investment cohort')

-- Dust and Crystal are known output modifiers even without a measured numerical
-- curve. Editing them must retain context/notes, never invent a quantity bonus.
LL.db.tooltipDetail=3;LL.db.showAverageQuantity=true
local function render(facts,model,details)
    LL.db.showProfessionDetails=details
    local tip={lines={}}
    function tip:AddLine(text) self.lines[#self.lines+1]=text end
    function tip:AddDoubleLine(left,right) self.lines[#self.lines+1]=left..' | '..right end
    LL:AppendRecommendationTooltip(tip,{action='D',facts=facts,disenchantEligible=true,
        conversionOptions={{name='Disenchant',letter='D',profession='Enchanting',recipeID=13262,
            inputCount=1,available=true,yieldModel=model,value=model.value or model.partialValue}}})
    return table.concat(tip.lines,'\n')
end
for _,case in ipairs({
    {name='Dust Deliverer',node=107648,rarity=2,skill=125},
    {name='Crystal Collector',node=107646,rarity=4,skill=125},
}) do
    local facts={id=999990+case.rarity,expansionID=11,quality=case.rarity,classID=4,count=1}
    set('Enchanting',11,'none',100)
    local baseline=resolve(facts,disenchant)
    LL:ValueProcessingModel(baseline,0,true,facts)
    set('Enchanting',11,case.node..'=10',100)
    local selected=resolve(facts,disenchant)
    near(selected.context.effectiveSkill,case.skill,case.name..' applies its sourced point, learning and milestone skill')
    check(selected.context.specialization==case.node..'=10',case.name..' selected points reach resolver context')
    check(not selected.specializationEffectsApplied and not selected.skillQualityApplied,
        case.name..' has no invented numerical output transform')
    check(#selected.materials==#baseline.materials,case.name..' invents no extra outputs')
    for _,material in ipairs(baseline.materials) do
        check(output(selected,material.id).expectedQuantity==material.expectedQuantity,
            case.name..' retains each selected reference mean')
    end
    LL:ValueProcessingModel(selected,0,true,facts)
    check(selected.value==baseline.value and selected.partialValue==baseline.partialValue,
        case.name..' does not invent an output value change')
    local notes,unquantified=LL:ProfessionSimulationEffectNotes(facts,disenchant,selected)
    local text=table.concat(notes,'\n')
    check(unquantified and text:find(case.name..': 10 / 30 points.',1,true),case.name..' allocation reaches description notes')
    check(text:find('unquantified',1,true),case.name..' numerical limitation stays explicit')
    local compact=render(facts,selected,false)
    check(compact:find('some specialization effects unquantified',1,true),
        case.name..' compact limitation remains visible with profession details off')
    check(not compact:find(case.name..': 10 / 30 points.',1,true),'detailed point notes respect the profession-details option')
    local detailed=render(facts,selected,true)
    check(detailed:find(case.name..': 10 / 30 points.',1,true) and detailed:find('Simulated skill:',1,true),
        case.name..' point and researched skill notes reach the actual tooltip')
    local wrongRarity={id=999992,expansionID=11,quality=3,classID=4}
    check(not table.concat(LL:ProfessionSimulationEffectNotes(wrongRarity,disenchant,selected),'\n'):find(case.name,1,true),
        case.name..' description does not cross rarity scope')
end

-- Optional descriptor scopes must agree in editor discovery and tooltip notes.
-- These temporary restrictions exercise the schema contract, not new research.
local descriptions=LL.ItemDB.specializationDescriptions
local scoped={}
for _,description in ipairs(descriptions) do
    if description.nodeID==107646 then for key,value in pairs(description) do scoped[key]=value end end
end
scoped.recipeID=13262;scoped.inputClassID=4
LL.ItemDB.specializationDescriptions={scoped}
local describedFacts={id=999994,expansionID=11,quality=4,classID=4}
local describedModel={context={simulated=true,profileKind='manual-simulation',profession='Enchanting',
    skill=100,effectiveSkill=100,specialization='107646=10'}}
local function hasCrystal(facts,option)
    return table.concat(LL:ProfessionSimulationEffectNotes(facts,option,describedModel),'\n'):find('Crystal Collector',1,true)~=nil
end
check(hasCrystal(describedFacts,disenchant),'matching optional recipe and class permit the descriptor note')
describedFacts.classID=2
check(not hasCrystal(describedFacts,disenchant),'a descriptor for armor cannot leak onto a weapon')
describedFacts.classID=4
check(not hasCrystal(describedFacts,{name='Disenchant',recipeID=999}),
    'a recipe-restricted descriptor cannot leak onto another recipe')
scoped.inputClassID=nil;describedFacts.classID=2
check(hasCrystal(describedFacts,disenchant),'omitted descriptor class permits either equipment class')
scoped.recipeID=nil
check(hasCrystal(describedFacts,{name='Disenchant',recipeID=999}),'omitted descriptor recipe remains unrestricted')
scoped.inputRarity=nil;describedFacts.quality=2
check(hasCrystal(describedFacts,disenchant),'omitted descriptor rarity remains unrestricted')
LL.ItemDB.specializationDescriptions=descriptions

local ore={id=210931,expansionID=10,reagentQuality=2,classID=7,count=5}
local prospect={name='Prospect',recipeID=434018,inputCount=5}
LL.db.source_legacy_enabled=true
set('Jewelcrafting',10,'none')
local neutral=resolve(ore,prospect)
local amber=assert(output(neutral,212498)).expectedQuantity
set('Jewelcrafting',10,'98660=20')
local replacement=resolve(ore,prospect)
check(replacement.specializationEffectsApplied,'TWW replacement points reach the shipped resolver on 70961')
near(output(replacement,212498).expectedQuantity,amber*.8,'sourced point conversion uses original amber reservoir')

-- Real compiled quality-family baselines and real node rules, with an explicit
-- exact-operation fixture. Prices/thresholds here are fixtures, not game claims.
LL.db.source_legacy_enabled=false
LL.db.source_itemdb_enabled=false
LL.db.source_reference_enabled=true
for _,case in ipairs({
    {profession='Jewelcrafting',method='Prospect',recipe=1231127,input=237359,node=106982,low=242554,high=242722},
    {profession='Inscription',method='Mill',recipe=1269575,input=236761,node=109653,low=245807,high=245808},
}) do
    local facts={id=case.input,expansionID=11,reagentQuality=1,classID=7,count=5}
    local option={name=case.method,recipeID=case.recipe,inputCount=5}
    local snapshot={recipeID=case.recipe,inputItemID=case.input,inputQualityRank=1,expansionID=11,
        build='70961',observed=100,craftingQuality=2,highQualitySkillThreshold=365,
        character='Player',maxQuality=2,allocationVerified=true,concentration=false}
    LL.GetSkillQualityOperation=function() return snapshot end
    set(case.profession,11,'none',364)
    local low=resolve(facts,option)
    check(low.skillQualityApplied and output(low,case.low),case.method..' low skill routes actual family to rank 1')
    set(case.profession,11,case.node..'=1',364)
    local high=resolve(facts,option)
    check(high.skillQualityApplied and output(high,case.high),case.method..' specialization point crosses quality threshold')
    near(high.context.effectiveSkill,365,case.method..' node skill bonus is calculated')
    near(output(high,case.high).expectedQuantity,output(low,case.low).expectedQuantity,
        case.method..' quality selection preserves the researched total')
    set(case.profession,11,'none',365)
    check(resolve(facts,option).skillQualityApplied,case.method..' base skill slider reaches the same calculation')
    snapshot.build='70783'
    check(not resolve(facts,option).skillQualityApplied,case.method..' operation captures remain client-build exact')
end
print('PASS: '..checks..' client-patch compatibility, actual capability, category/reference, point and quality assertions')
