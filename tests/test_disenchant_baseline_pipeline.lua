-- Build-only normalization views never become additional observed evidence.
-- The curve is a declared model; these tests check its reversible arithmetic.
local checks=0
local function check(value,label) assert(value,label);checks=checks+1 end
local function near(a,b,label)
    check(type(a)=='number' and type(b)=='number' and math.abs(a-b)<1e-8,
        (label or '')..': '..tostring(a)..' ~= '..tostring(b))
end
local function copy(value)
    if type(value)~='table' then return value end
    local result={} for key,item in pairs(value) do result[key]=copy(item) end return result
end
local function same(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for key,value in pairs(a) do if not same(value,b[key]) then return false end end
    for key in pairs(b) do if a[key]==nil then return false end end
    return true
end
local function amounts(materials)
    local result={} for _,material in ipairs(materials) do result[material.id]=material.expectedQuantity end return result
end
local function sameAmounts(a,b,label)
    a,b=amounts(a),amounts(b)
    for id,value in pairs(a) do near(value,b[id] or 0,label..' '..id) end
    for id,value in pairs(b) do if a[id]==nil then near(value,0,label..' extra '..id) end end
end
local LL={}
assert(loadfile('LootLiquidator/ProfessionModels.lua'))('LL',LL)
local build=assert(loadfile('tools/disenchant_simulation_baselines.lua'))()
local records=assert(loadfile('database/disenchant-category-baselines.lua'))().processing
local original=copy(records)
-- The fixture follows the generated rule contract; no arbitrary observed
-- denominator, source skill, source patch or per-cast distribution is added.
local common={method='Disenchant',profession='Enchanting',expansionID=11,build=70961,clientVersion='12.1.5',
    applyPolicy='EXECUTE',evidenceStatus='MODELED',inputClassIDs={2,4},confidence0to100=25,
    crossClassConfidence=15,skillMaximum=290,quantityMilestones={{rank=20,progress=.5},{rank=30,progress=.5}},
    rootNodeID=107649,sourceClaimIDs={'fixture-model-source'},assumptions={'Declared zero-profile prior'}}
local rules={}
for _,entry in ipairs({
    {ruleID='dust-fixture',inputRarity=2,childNodeID=107648,primaryRankIDs={243599,243600},
        sourceKey='reference',targetPooledMean=2.9,targetRank2Share=.65,baselineFallbackClassID=4},
    {ruleID='supplier-fixture',inputRarity=3,childNodeID=107647,primaryRankIDs={243602,243603},
        sourceKey='itemdb',targetPooledMean=1.289,targetRank2Share=.660/1.289,
        endpointRecordID='de-category:gear:11:3:armor:max-specialization:a194c8a33fcf'},
    {ruleID='crystal-fixture',inputRarity=4,childNodeID=107646,primaryRankIDs={243605,243606},
        sourceKey='reference',preservePrimaryTotal=true,targetRank2Share=.66},
}) do
    local rule=copy(common) for key,value in pairs(entry) do rule[key]=value end rules[#rules+1]=rule
end
local originalRules=copy(rules)
local baselines=build(records,rules,LL)
check(#baselines==6,'three rarity models cover both equipment classes, with a Dust armor fallback')
check(same(records,original),'the builder never modifies source records or their counts')
check(same(rules,originalRules),'the builder never modifies generated rules')
check(same(baselines,build(records,rules,LL)),'repeated builds are deterministic and do not compound normalization')
check(#build({},rules,LL)==0,'fixture compiles without category evidence produce no modeled baselines')
local exactOnly=copy(records)
for _,record in ipairs(exactOnly) do record.isDisenchantCategory=false end
check(#build(exactOnly,rules,LL)==0,'exact source studies are not silently widened into categories')
local selected={}
for _,baseline in ipairs(baselines) do
    local rule=baseline.rule
    selected[rule.inputRarity..':'..baseline.inputClassID]=baseline
    check(baseline.sourceProfileAssumed and baseline.baselineProfile.effectiveSkill==0
        and baseline.baselineProfile.childPoints==0,'zero profile is an explicit modeling prior')
    check(baseline.sourceRecordID and baseline.referenceContextID:find(':unknown-character',1,true),
        'modeled view retains its ordinary category source lineage')
    check(baseline.sourceBuild==nil and baseline.modelBuild==70961,'model build never backdates an unknown source build')
    check(baseline.samples==nil and baseline.effectiveSamples==nil and baseline.castCount==nil,
        'modeled views invent no observed cast denominator')
    check(baseline.confidence<=rule.confidence0to100,'model confidence is capped by the rule')
    if baseline.inputClassID==2 and rule.inputRarity~=4 then
        check(baseline.confidence<=rule.crossClassConfidence,'cross-class baseline or endpoint carries the lower cap')
    end
    for _,material in ipairs(baseline.materials) do
        check(material.confidence<=baseline.confidence,'normalized means carry the full confidence cap')
        check(material.samples==nil and material.quantityCounts==nil and material.fieldEvidence==nil,
            'plain modeled means carry no fake measured fields')
    end
    for _,profile in ipairs({{effectiveSkill=0,childPoints=0},{effectiveSkill=145,childPoints=20},
        {effectiveSkill=217.5,childPoints=25},{effectiveSkill=290,childPoints=30}}) do
        local forward=assert(LL:DisenchantCurveQuantities(baseline,profile))
        local normalized=assert(LL:NormalizeDisenchantQuantities(baseline,forward,profile))
        sameAmounts(normalized,baseline.materials,'forward/inverse returns the declared prior')
        for _,material in ipairs(forward) do
            check(material.confidence<=baseline.confidence,'forward calculations retain confidence caps')
        end
    end
    local full=assert(LL:DisenchantCurveQuantities(baseline,{effectiveSkill=290,childPoints=30}))
    local fullMeans=amounts(full)
    local ids=rule.primaryRankIDs
    local pool=fullMeans[ids[1]]+fullMeans[ids[2]]
    near(fullMeans[ids[2]]/pool,rule.targetRank2Share,'full skill reaches the declared rank share')
    local before=amounts(baseline.materials)
    if rule.preservePrimaryTotal then
        near(pool,before[ids[1]]+before[ids[2]],'Crystal skill preserves primary total units')
    else near(pool,rule.targetPooledMean,'full child points reach the declared primary total') end
    local inconsistent=copy(full)
    for _,material in ipairs(inconsistent) do if material.id==ids[1] then material.expectedQuantity=material.expectedQuantity+.1 end end
    check(LL:NormalizeDisenchantQuantities(baseline,inconsistent,{effectiveSkill=290,childPoints=30})==nil,
        'a saturated endpoint cannot conceal an inconsistent observation')
    local invalid=copy(baseline.materials)
    for _,material in ipairs(invalid) do
        if material.id==ids[1] then material.expectedQuantity=.1
        elseif material.id==ids[2] then material.expectedQuantity=0 end
    end
    check(LL:NormalizeDisenchantQuantities(baseline,invalid,{effectiveSkill=145,childPoints=20})==nil,
        'negative or impossible inverse baselines are rejected')
end
check(selected['2:2'].sourceClassID==4 and selected['2:4'].sourceClassID==4,'only absent Dust weapons use the armor prior')
check(selected['3:2'].sourceClassID==2,'Supplier weapons keep their own ordinary baseline')
for _,classID in ipairs({2,4}) do
    local supplier=selected['3:'..classID]
    check(supplier.endpointSourceClassID==4 and supplier.endpointSourceRecordID
        and supplier.endpointReferenceContextID==rules[2].endpointRecordID,'Supplier endpoint retains exact armor cohort lineage')
    local endpoint=amounts(supplier.endpointMaterials)
    near(endpoint[243602],.629,'Supplier R1 endpoint remains the source mean')
    near(endpoint[243603],.660,'Supplier R2 endpoint remains the source mean')
    near(endpoint[236963],.071,'Supplier additional outputs remain the source means')
end
check(same(records,original),'all normalization and forward tests leave the raw category data intact')
-- The shipped artifact uses the same independent views. Exercise the actual
-- resolver order: selected profile, modeled outputs, then one benchmark pass.
GetBuildInfo=function() return '12.1.5','70961','',120105 end
GetTime=function() return 100 end
time=function() return 100 end
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
for _,file in ipairs({'ItemDBRuntime.lua','Professions.lua','Database.lua','ConversionEngine.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LL',LL)
end
check(#LL.ItemDB.modeledDisenchantBaselines==6 and LL.ItemDB.buildReport.modeledDisenchantBaselines==6,
    'compiled model views have their own count outside raw processing evidence')
for _,baseline in ipairs(LL.ItemDB.modeledDisenchantBaselines) do
    check(baseline.samples==nil and baseline.effectiveSamples==nil,'compiled model artifact invents no observed samples')
end
LL.db={characters={Player={professions={Enchanting=true}}},rateProfile=3,rateProfileCharacter='Player',
    source_legacy_enabled=false,source_personal_enabled=false,source_imported_enabled=false}
LL.CharacterKey=function() return 'Player' end
LL.GetResearchProfessionSnapshot=function() return 0,'none' end
LL.GetCachedOperationInfo=function() end
LL:MigrateEvidenceSettings()
check(LL:InitializeItemDB(),LL.itemDBError)
local option={name='Disenchant',recipeID=13262,inputCount=1}
local function resolve(facts,node,benchmark)
    check(LL:SetManualProfessionProfile('Player','Enchanting',11,{enabled=true,skill=140,
        specialization='107649=30,'..node..'=30',benchmark=benchmark}),'runtime simulation profile saves')
    LL._processingContextCache=nil;LL._processingModelCache=nil
    return assert(LL:ResolveEvidenceModel(facts,option,nil,1))
end
for _,case in ipairs({{rarity=2,node=107648,low=243599,high=243600,total=2.9},
    {rarity=3,node=107647,low=243602,high=243603,total=1.289},
    {rarity=4,node=107646,low=243605,high=243606}}) do
    local facts={id=999990+case.rarity,expansionID=11,quality=case.rarity,classID=4,count=1}
    local model=resolve(facts,case.node)
    check(model.disenchantBaselineApplied and model.professionProjected,'real resolver consumes the compiled baseline once')
    check(model.samples==nil and model.effectiveSamples==nil,'runtime model reports no fabricated sample denominator')
    near(model.context.effectiveSkill,290,'runtime profile includes specialization skill once')
    local means=amounts(model.materials)
    local canonical
    for _,baseline in ipairs(LL.ItemDB.modeledDisenchantBaselines) do
        if baseline.recordID==model.disenchantBaselineID then canonical=amounts(baseline.materials) end
    end
    check(canonical,'selected baseline retains its quantity reference')
    local quantityFactor=(means[case.low]+means[case.high])/(canonical[case.low]+canonical[case.high])
    if case.total then near(means[case.low]+means[case.high],case.total,'older full-reference path adds no second yield bonus') end
    check(LL:ApplyDisenchantBaseline(facts,option,model,model.context,1)==model,'an already projected baseline is not reapplied')
    for _,source in ipairs({'personal','imported'}) do
        local observed={sources={[source]=.01,itemdb=.99},materials={{id=case.low,expectedQuantity=123}}}
        check(LL:ApplyDisenchantBaseline(facts,option,observed,model.context,1)==observed,
            source..' evidence retains precedence over the modeled prior')
    end
    for _,alpha in ipairs({.1,.8}) do
        local combined={confidence=80,source='Weighted evidence',sources={itemdb=alpha,legacy=1-alpha},materials={
            {id=case.low,expectedQuantity=alpha*2+(1-alpha)*10,confidence=80,
                sourceContributions={itemdb=alpha,legacy=1-alpha},
                sourceEstimates={itemdb={expectedQuantity=2,inputCount=1}}},
            {id=case.high,expectedQuantity=alpha*3+(1-alpha)*12,confidence=80,
                sourceContributions={itemdb=alpha,legacy=1-alpha},
                sourceEstimates={itemdb={expectedQuantity=3,inputCount=1}}},
            {id=999999,expectedQuantity=7,confidence=80,sourceContributions={legacy=1}}}}
        local beforeCombined=copy(combined)
        local zeroContext=copy(model.context)
        zeroContext.skill=0;zeroContext.effectiveSkill=0;zeroContext.preSpecializationSkill=0
        zeroContext.specialization='none';zeroContext.specializationPoints={};zeroContext.learnedSpecializations={}
        zeroContext.disenchantSpecializationPoints={};zeroContext.disenchantLearnedSpecializations={}
        local neutral=LL:ApplyDisenchantBaseline(facts,option,combined,zeroContext,1)
        local neutralMeans=amounts(neutral.materials)
        near(neutralMeans[case.low],combined.materials[1].expectedQuantity,'mixed zero-bonus low-rank identity')
        near(neutralMeans[case.high],combined.materials[2].expectedQuantity,'mixed zero-bonus high-rank identity')
        local invalidPool=copy(combined);invalidPool.materials[1].expectedQuantity=0
        check(LL:ApplyDisenchantBaseline(facts,option,invalidPool,model.context,1)==invalidPool,
            'a declared source term larger than the fused pool cannot be projected')
        local mixed=LL:ApplyDisenchantBaseline(facts,option,combined,model.context,1)
        check(mixed.disenchantBaselineApplied,'mixed source model receives only an ItemDB-term projection')
        local mixedMeans=amounts(mixed.materials)
        near(mixedMeans[case.low]+mixedMeans[case.high],alpha*5*quantityFactor+(1-alpha)*22,
            'only the contributing ordinary pool receives the canonical quantity multiplier')
        check(mixedMeans[case.low]>=(1-alpha)*10-1e-9 and mixedMeans[case.high]>=(1-alpha)*12-1e-9,
            'quality redistribution never spends the other source primary units')
        check(mixedMeans[case.high]>=alpha*3*quantityFactor+(1-alpha)*12-1e-9,
            'positive quality progress cannot downgrade the ordinary high-rank pool')
        near(mixedMeans[999999],7,'a non-ItemDB-only material stays unchanged')
        if case.rarity==4 then
            local bonus=0
            for _,id in ipairs({236949,236950,236951,236952}) do
                near(mixedMeans[id],means[id]*alpha,'new Crystal extras retain the selected ItemDB share')
                bonus=bonus+mixedMeans[id]
            end
            near(bonus,.289*alpha,'Crystal bonus pool scales with the 10/90 or 80/20 source mixture')
            local missingHigh=copy(combined);table.remove(missingHigh.materials,2)
            local withNewRank=LL:ApplyDisenchantBaseline(facts,option,missingHigh,model.context,1)
            local missingMeans=amounts(withNewRank.materials)
            near(missingMeans[case.low]+missingMeans[case.high],alpha*2*quantityFactor+(1-alpha)*10,
                'a newly introduced primary rank conserves the actual accepted pool')
            check(missingMeans[case.high]>=0 and missingMeans[case.high]<=alpha*2*quantityFactor+1e-9,
                'new high-rank units never exceed the accepted ItemDB donor pool')
            local missingBonus=0
            for _,id in ipairs({236949,236950,236951,236952}) do missingBonus=missingBonus+(missingMeans[id] or 0) end
            near(missingBonus,.289*alpha,'a missing original high-rank row does not amplify Crystal extras')
        end
        check(same(mixed.sources,combined.sources),'combined source contributions retain their original weights')
        check(same(combined,beforeCombined),'mixed projection never rewrites the original weighted model')
        local pooled=copy(combined)
        pooled.materials[1].rankIDs={case.low,case.high}
        check(LL:ApplyDisenchantBaseline(facts,option,pooled,model.context,1)==pooled,
            'overlapping pooled and exact rank distributions are not projected twice')
    end
    if case.rarity==4 then
        local uneven={confidence=80,sources={itemdb=.5,legacy=.5},materials={
            {id=case.low,expectedQuantity=2,sourceContributions={itemdb=1},sourceEstimates={itemdb={expectedQuantity=2,inputCount=1}}},
            {id=case.high,expectedQuantity=12,sourceContributions={itemdb=0,legacy=1},sourceEstimates={itemdb={expectedQuantity=3,inputCount=1}}}}}
        local unevenBefore=copy(uneven)
        local unevenProjection=LL:ApplyDisenchantBaseline(facts,option,uneven,model.context,1)
        local unevenMeans=amounts(unevenProjection.materials)
        local bonus=0
        for _,id in ipairs({236949,236950,236951,236952}) do bonus=bonus+(unevenMeans[id] or 0) end
        near(bonus,.289*2/5,'uneven primary weights use quantity-weighted ItemDB family share')
        near(unevenMeans[case.low]+unevenMeans[case.high],2*quantityFactor+12,
            'unequal rank weights conserve the ordinary pool and the legacy-only term')
        check(unevenMeans[case.high]>=12,'quality progress may add a modeled rank without spending the legacy-only term')
        check(same(uneven,unevenBefore),'family-share projection preserves its weighted source inputs')
        local noItemDB=copy(uneven);noItemDB.sources={legacy=1}
        for _,material in ipairs(noItemDB.materials) do material.sourceContributions={legacy=1} end
        local absent=LL:ApplyDisenchantBaseline(facts,option,noItemDB,model.context,1)
        local absentMeans=amounts(absent.materials)
        for _,id in ipairs({236949,236950,236951,236952}) do near(absentMeans[id] or 0,0,'no accepted ItemDB primary contribution creates no extra Mote units') end
        LL.db.source_itemdb_enabled=false
        check(LL:ApplyDisenchantBaseline(facts,option,uneven,model.context,1)==uneven,'disabled ItemDB source cannot add mixed-source Crystal extras')
        LL.db.source_itemdb_enabled=true
    end
    local ordinary={sources={itemdb=1},materials={{id=case.low,expectedQuantity=123}}}
    check(LL:ApplyDisenchantBaseline(facts,option,ordinary,model.context,2)==ordinary,
        'personal-only mode cannot consume the compiler model')
    LL.db.source_itemdb_weight=0
    check(LL:ApplyDisenchantBaseline(facts,option,ordinary,model.context,1)==ordinary,
        'zero ItemDB source weight disables the model prior')
    LL.db.source_itemdb_weight=nil
    if case.rarity~=3 then
        LL.db.source_reference_enabled=false
        check(LL:ApplyDisenchantBaseline(facts,option,ordinary,model.context,1)==ordinary,
            'a disabled reference source disables its Dust or Crystal endpoint')
        LL.db.source_reference_enabled=true;LL.db.source_reference_weight=0
        check(LL:ApplyDisenchantBaseline(facts,option,ordinary,model.context,1)==ordinary,
            'zero reference weight disables its Dust or Crystal endpoint')
        LL.db.source_reference_weight=nil
    end
    local benchmark=resolve(facts,case.node,{outputLevel=200,specializationBonus=0,
        resourcefulnessChance=0,resourcefulnessSaved=0})
    check(benchmark.disenchantBaselineApplied and benchmark.syntheticBenchmark,'benchmark follows the compiled baseline model')
    local doubled=amounts(benchmark.materials)
    for id,value in pairs(means) do near(doubled[id],2*value,'benchmark is applied exactly once') end
    check(LL:ApplySyntheticBenchmark(facts,option,benchmark,benchmark.context)==benchmark,
        'a benchmark result cannot be compounded on reevaluation')
end
print('PASS: '..checks..' immutable Disenchant baseline build, forward/inverse, endpoint and confidence assertions')
