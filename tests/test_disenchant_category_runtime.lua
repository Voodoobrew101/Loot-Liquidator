-- Exercise the actual Database selector with controlled studies, then the
-- compiled research. Category estimates must work for gear never sampled.
local checks=0
local function check(value,label) assert(value,label);checks=checks+1 end
local function near(actual,expected,label)
    check(type(actual)=='number' and math.abs(actual-expected)<1e-9,
        (label or 'numeric result')..': '..tostring(actual)..' ~= '..tostring(expected))
end
local function clone(value)
    if type(value)~='table' then return value end
    local result={} for key,v in pairs(value) do result[key]=clone(v) end return result
end
local function contains(values,value)
    for _,v in ipairs(values or {}) do if v==value then return true end end
    return false
end
GetBuildInfo=function() return '12.1.5','70783' end
local LL={db={source_itemdb_enabled=true,source_itemdb_weight=100,
    source_personal_enabled=false,source_imported_enabled=false,
    source_legacy_enabled=false,source_reference_enabled=false}}
assert(loadfile('LootLiquidator/Database.lua'))('LL',LL)
local function field(value,samples)
    return {value=value,samples=samples or 100,confidence=100,
        status=value==nil and 'unknown' or 'measured'}
end
local function material(id,mean,chance,samples)
    return {id=id,expectedQuantity=field(mean,samples),dropChance=field(chance,samples),
        minQuantity=field(chance and 1 or nil,samples),maxQuantity=field(chance and 3 or nil,samples)}
end
local category={recordID='category:rare-armor',studyID='pooled:a+b',source='Two gear studies',
    sourceKey='itemdb',method='Disenchant',recipeID=13262,inputCount=1,
    expansionID=11,inputRarity=3,inputClassID=4,gearKey='gear:11:3:armor',
    isDisenchantCategory=true,categoryReferenceOnly=false,
    categorySourceStudyIDs={'study:a','study:b'},memberInputItemIDs={239671,239675},
    referenceContextID='rare-armor:ordinary',samples=100,
    materials={material(243599,1.2,.4)}}
-- Deliberately much stronger and marked fixedReference: an archived source
-- study already represented by the category must not get a second vote.
local exact={recordID='exact:239671',studyID='study:a',source='Preserved item study',
    sourceKey='itemdb',method='Disenchant',recipeID=13262,inputCount=1,
    inputItemID=239671,expansionID=11,inputRarity=3,inputClassID=4,
    referenceContextID='exact:item-context',fixedReference=true,samples=10000,
    materials={material(243599,2.7,.9,10000),material(243603,.3,.1,10000)}}
local option={name='Disenchant',recipeID=13262,inputCount=1}
local facts={id=999001,expansionID=11,quality=3,classID=4,count=1}
local function install(records)
    LL.ItemDB={schemaVersion=1,version='category-runtime-fixture',processing=records,mechanicRules={}}
    LL.LegacyDB=nil
    check(LL:InitializeItemDB(),LL.itemDBError)
end
local function resolve(input,context,personal,mode)
    return LL:ComputeEvidenceModel(input or facts,option,personal,mode or 1,context or {},true)
end
local function byID(model,id)
    for _,m in ipairs(model.materials) do if m.id==id then return m end end
end
install({exact,category})
local model=assert(resolve())
near(byID(model,243599).expectedQuantity,1.2,'unseen rare armor receives the pooled units/cast')
near(byID(model,243599).chance,.4,'unseen rare armor receives the pooled hit rate')
near(byID(model,243599).chanceCasts,100,'pooled denominator is counted once')
check(model.isDisenchantCategory and model.gearKey=='gear:11:3:armor','category identity reaches the result')
check(contains(model.categorySourceStudyIDs,'study:a') and contains(model.categorySourceStudyIDs,'study:b'),
    'result retains the source studies behind the pooled estimate')
check(contains(model.memberInputItemIDs,239671) and contains(model.memberInputItemIDs,239675),
    'result retains the sampled items without restricting lookup to them')
for _,id in ipairs({239671,239675,999002}) do
    local f=clone(facts);f.id=id
    local selected=assert(resolve(f))
    near(byID(selected,243599).expectedQuantity,1.2,'member and unseen items share the category mean')
    near(byID(selected,243599).chance,.4,'preserved exact-item rate does not replace the category rate')
    near(byID(selected,243599).chanceCasts,100,'preserved exact-item casts are not counted twice')
    check(byID(selected,243603)==nil,'an exact-only cooutput cannot be added on top of its category')
end
-- Physical dimensions are necessary even when the caller supplies the same ID.
for _,change in ipairs({{'expansionID',10},{'quality',2},{'quality',4},{'classID',2},{'classID',7}}) do
    local f=clone(facts);f[change[1]]=change[2]
    check(resolve(f)==nil,'category does not leak across '..change[1]..'='..change[2])
end
for _,missing in ipairs({'expansionID','quality','classID'}) do
    local f=clone(facts);f[missing]=nil
    check(resolve(f)==nil,'missing '..missing..' cannot satisfy the gear category')
end
-- The native evidence contract must reject contradictory category identities.
for _,change in ipairs({{'gearKey','gear:10:3:armor'},{'inputRarity',4},{'inputClassID',2},
    {'expansionID',10},{'inputItemID',239671},{'isDisenchantCategory','true'}}) do
    local bad=clone(category);bad[change[1]]=change[2]
    check(not LL:ValidateItemDB({schemaVersion=1,processing={bad}}),
        'invalid category identity rejected: '..change[1])
end
-- Only a documented exception may make an exact item diverge from its class.
local sampled=clone(facts);sampled.id=239671
for _,documentation in ipairs({
    {reason='A reason alone is insufficient'},
    {sources={'https://example.test/item-study'}},
    {reason='   ',sources={'https://example.test/item-study'}},
    {reason='Measured item-specific behavior',sources={'http://example.test/item-study'}}}) do
    local candidate=clone(exact)
    candidate.categoryExceptionReason=documentation.reason
    candidate.categoryExceptionSources=documentation.sources
    install({category,candidate})
    near(byID(assert(resolve(sampled)),243599).expectedQuantity,1.2,
        'an undocumented or unsupported item exception cannot override the category')
end
local exception=clone(exact)
exception.categoryExceptionReason='Independent measurements establish different behavior for this item'
exception.categoryExceptionSources={'https://example.test/item-study'}
install({category,exception})
local exceptional=assert(resolve(sampled))
near(byID(exceptional,243599).expectedQuantity,2.7,'documented item exception supplies its own mean')
near(byID(exceptional,243599).chance,.9,'documented item exception supplies its own probability')
near(byID(exceptional,243599).chanceCasts,10000,'exception does not add the category denominator')
near(byID(assert(resolve()),243599).expectedQuantity,1.2,'item exception does not affect unseen gear')
-- The known max-specialization study is a separate context, selectable without
-- letting its higher mean silently replace the ordinary category baseline.
local specialized=clone(category)
specialized.recordID='category:rare-armor:max-spec';specialized.studyID='study:max-spec'
specialized.categoryReferenceOnly=true;specialized.referenceContextID='rare-armor:max-spec'
specialized.categorySourceStudyIDs={'study:max-spec'};specialized.memberInputItemIDs={239671}
specialized.samples=1000;specialized.materials={material(243599,1.8,.6,1000)}
install({exact,specialized,category})
near(byID(assert(resolve(sampled)),243599).expectedQuantity,1.2,'ordinary context outranks max-spec reference by default')
local maxSpec=assert(resolve(sampled,{referenceContextID='rare-armor:max-spec'}))
near(byID(maxSpec,243599).expectedQuantity,1.8,'explicit reference context selects max-specialization mean')
near(byID(maxSpec,243599).chance,.6,'max-specialization probability stays with that study')
near(byID(maxSpec,243599).chanceCasts,1000,'max-specialization denominator stays separate')
check(#maxSpec.categorySourceStudyIDs==1 and maxSpec.categorySourceStudyIDs[1]=='study:max-spec',
    'selected context retains only its own study provenance')
-- Source and observation policy remain authoritative over category lookup.
LL.db.source_itemdb_enabled=false
local disabled,reason=resolve()
check(disabled==nil and reason:find('disabled',1,true),'disabling itemdb disables the category')
LL.db.source_itemdb_enabled=true;LL.db.source_itemdb_weight=0
check(resolve()==nil,'zero itemdb weight disables the category')
LL.db.source_itemdb_weight=100
check(resolve(nil,nil,nil,2)==nil,'personal-only mode does not admit researched categories')
local personal={effectiveSamples=50,samples=50,inputCount=1,
    materials={{id=243599,expectedQuantity=.5,chance=.25,minQuantity=1,maxQuantity=3}}}
LL.db.source_personal_enabled=true;LL.db.source_personal_weight=100
local observed=assert(resolve(nil,nil,personal,2))
near(byID(observed,243599).expectedQuantity,.5,'personal-only mode keeps the player mean')
near(byID(observed,243599).chance,.25,'personal-only mode keeps the player hit rate')
near(byID(observed,243599).chanceCasts,50,'personal-only mode keeps the player sample count')
near(byID(assert(resolve(nil,nil,personal,3)),243599).expectedQuantity,1.2,
    'research-only mode excludes personal data')
LL.db.source_personal_enabled=false
-- Native compilation: all five researched physical categories must support new
-- IDs, and sampled item IDs must produce the same category answer exactly once.
local shipped={}
assert(loadfile('LootLiquidator/ItemDBRuntime.lua'))('LL',shipped)
LL.ItemDB=shipped.ItemDB;LL.LegacyDB=nil
check(LL:InitializeItemDB(),LL.itemDBError)
local native,ordinary,maxReference,retained={},{},nil,{}
local migrated=0
for _,r in ipairs(LL.ItemDB.processing) do
    if r.categorySourceInputItemID then
        check(r.method=='Disenchant' and r.isDisenchantCategory and r.inputItemID==nil,
            'ordinary source item identity is provenance, never an exact eligibility override')
        migrated=migrated+1
    end
    -- Keep the six original receipts separate from the four newly admitted
    -- measured-profile cohorts; table order must not replace the old receipt.
    if r.retainedSourceProfileKey then
        retained[#retained+1]=r
    elseif r.isDisenchantCategory and r.expansionID==11 and r.recordID:match('^evidence:category:') then
        native[#native+1]=r
        if r.categoryReferenceOnly then maxReference=r else ordinary[r.gearKey]=r end
    end
end
check(#native==6,'native ItemDB preserves five original category receipts plus a separate max-specialization receipt')
check(migrated>0,'native ItemDB also contains independent studies migrated to shared categories')
-- All four additions have exact source/profile/category identities and the
-- actual denominators. Half-weighted support must never become P/E's divisor.
local expectedRetained={
    ['gear:9:4:armor']={suffix='0fe2a5e798ae',n=66,skill=51,expansion=9,class=4,band=310,
        outputs={[194124]={38,59,1,2},[200113]={28,28,1,1}}},
    ['gear:9:4:weapon']={suffix='5f7d0f4f13dd',n=17,skill=51,expansion=9,class=2,band=313,
        outputs={[194124]={10,23,2,3},[200113]={7,7,1,1}}},
    ['gear:11:4:armor']={suffix='8ac87db87c7a',n=9,skill=104,expansion=11,class=4,band=331,
        outputs={[243605]={9,9,1,1}}},
    ['gear:11:4:weapon']={suffix='73d6cb967bbd',n=1,skill=104,expansion=11,class=2,band=328,
        outputs={[243606]={1,1,1,1}}}}
check(#retained==4,'exactly four new reviewed cohorts accompany the six original receipts')
local seenCategories,seenOperations,operations,midnight,outputCount={},{},0,0,0
for _,r in ipairs(retained)do
    local expected=assert(expectedRetained[r.gearKey],'unexpected retained category')
    check(not seenCategories[r.gearKey],'each retained physical category appears once')
    seenCategories[r.gearKey]=true
    check(r.recordID=='evidence:category:Disenchant:'..r.gearKey..':x1:scope:'..expected.suffix,
        'retained category keeps its exact reviewed record identity')
    check(r.method=='Disenchant' and r.recipeID==13262 and r.sourceKey=='itemdb'
        and r.sourceKind=='reviewed-player-retained-subset' and r.inputCount==1 and r.inputItemID==nil,
        'new shared evidence is a one-input category, not an exact-item exception')
    check(r.expansionID==expected.expansion and r.inputClassID==expected.class and r.inputRarity==4,
        'retained cohort keeps its actual era, epic rarity and equipment class')
    check(r.categoryReferenceOnly==false and r.fixedReference==true
        and r.retainedSourceProfileKey=='effective:'..expected.skill..';specialization:none;buffs:',
        'shared cohort retains the explicit exact-profile gate')
    check(r.baselineProfile.effectiveSkill==expected.skill and r.baselineProfile.buffsKnown==true
        and r.baselineProfile.specializationKnown==true,'recorded source skill and known states remain measured')
    check(r.observedOperations==expected.n and #r.sourceRecordIDs==expected.n,
        'actual retained operation count is preserved')
    near(r.samples,expected.n/2,'only evidence support uses the existing half weight')
    check(r.categoryItemLevelMin==1 and r.categoryItemLevelMax==999
        and #r.categoryNativeBandIDs==1 and r.categoryNativeBandIDs[1]==expected.band,
        'retained source keeps its verified native category band')
    check(tostring(r.patchBuild)=='70961' and r.targetBuild==70961 and r.clientVersion=='12.1.5',
        'retained source stays scoped to its captured build and client')
    for _,id in ipairs(r.sourceRecordIDs)do
        check(not seenOperations[id],'one operation cannot appear in multiple shared cohorts')
        seenOperations[id]=true;operations=operations+1
    end
    if r.expansionID==11 then midnight=midnight+1 end
    local expectedOutputs=0 for _ in pairs(expected.outputs)do expectedOutputs=expectedOutputs+1 end
    check(#r.materials==expectedOutputs,'only the actual admitted material rows are present')
    for _,m in ipairs(r.materials)do
        local count=assert(expected.outputs[m.id],'unexpected shared output, including held knowledge')
        near(m.dropChance.value,tonumber(('%.6f'):format(count[1]/expected.n)),
            'shared occurrence remains original hits divided by actual N')
        near(m.expectedQuantity.value,tonumber(('%.6f'):format(count[2]/expected.n)),
            'shared mean remains original units divided by actual N')
        near(m.minQuantity.value,count[3],'observed positive minimum preserved')
        near(m.maxQuantity.value,count[4],'observed positive maximum preserved')
        local n,hits,units=0,0,0
        for quantity,casts in pairs(m.quantityCounts)do
            local q=assert(tonumber(quantity));n=n+casts;units=units+q*casts
            if q>0 then hits=hits+casts end
        end
        check(n==expected.n and hits==count[1] and units==count[2],
            'integer histogram retains actual operations, hits and units, including observed zeros')
        outputCount=outputCount+1
    end
end
check(operations==93 and midnight==2 and outputCount==6,
    'new shared data is exactly93 operations, two Midnight cohorts and six material rows')
local probes={
    {'gear:11:2:armor',2,4,278884,243599,.837915,.406635,527.5},
    {'gear:11:3:armor',3,4,239671,243602,.465373,.465373,4252.5},
    {'gear:11:3:weapon',3,2,244178,243602,.781290,.781290,791},
    {'gear:11:4:armor',4,4,250456,243605,.597484,.597484,159,.5812970837510016},
    {'gear:11:4:weapon',4,2,250451,243605,.631148,.631148,61}}
for index,probe in ipairs(probes) do
    local key,rarity,classID,member,output,mean,chance,casts,fusedMean=unpack(probe)
    check(ordinary[key] and #ordinary[key].categorySourceStudyIDs>0,'native category has source studies: '..key)
    check(contains(ordinary[key].memberInputItemIDs,member),'native category names its sampled member: '..key)
    local receipt=assert(byID(ordinary[key],output),'canonical material receipt missing')
    near(receipt.expectedQuantity.value,mean,'migration preserves the original category mean verbatim')
    near(receipt.dropChance.value,chance,'migration preserves the original measured occurrence verbatim')
    near(receipt.dropChance.samples,casts,'migration preserves original occurrence samples verbatim')
    for _,id in ipairs({999100+index,member}) do
        local f={id=id,expansionID=11,quality=rarity,classID=classID,count=1}
        local resolved=assert(resolve(f))
        check(resolved.isDisenchantCategory and resolved.gearKey==key,'native dimensions select '..key)
        local m=assert(byID(resolved,output),'native material missing: '..output)
        -- Epic armor now admits additional independent mean providers from
        -- ordinary items; occurrence still has its own measured denominator.
        near(m.expectedQuantity,fusedMean or mean,'all independent category means are fused once')
        near(m.chance,chance,'native category probability survives preserved exact studies')
        near(m.chanceCasts,casts,'native category denominator is counted once')
        local seen={}
        for _,source in ipairs(m.sourceEstimates.itemdb.records or {})do
            check(not seen[source.recordID],'one independent source receipt cannot contribute twice')
            seen[source.recordID]=true
        end
        check(seen[ordinary[key].recordID],'original category receipt still contributes to shared estimate')
    end
end
check(maxReference and maxReference.categoryReferenceOnly and maxReference.referenceContextID,
    'native max-specialization reference retains a separate context identity')
local nativeMax=assert(resolve(facts,{referenceContextID=maxReference.referenceContextID}))
near(byID(nativeMax,243602).expectedQuantity,.629,'native explicit max-specialization shard rank 1 mean')
near(byID(nativeMax,243603).expectedQuantity,.660,'native explicit max-specialization shard rank 2 mean')
check(byID(nativeMax,243602).chance==nil and byID(nativeMax,243603).chance==nil,
    'native max-specialization unit totals do not borrow ordinary category probabilities')
check(contains(nativeMax.categorySourceStudyIDs,'wowhead-mikimm-courtly-wrists-1000'),
    'native explicit max-specialization selection preserves its exact source')
LL.db.source_itemdb_enabled=false
check(resolve()==nil,'native compiled categories respect the disabled source preference')
LL.db.source_itemdb_enabled=true
check(resolve(nil,nil,nil,2)==nil,'native compiled categories respect personal-only mode')
print('PASS: '..checks..' disenchant category identity, priority, policy and native compilation assertions')
