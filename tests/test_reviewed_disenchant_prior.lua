-- Published fixed-stack source-table means; no new casts, calibrated hit
-- probability or current-variant equivalence is asserted by these fixtures.
local checks=0
local function check(ok,label)checks=checks+1;assert(ok,label)end
local function near(a,b,label)check(type(a)=='number' and math.abs(a-b)<1e-8,(label or '')..': '..tostring(a)..' ~= '..tostring(b))end
local function copy(x)if type(x)~='table'then return x end local r={}for k,v in pairs(x)do r[k]=copy(v)end return r end
local function same(a,b)if type(a)~=type(b)then return false end if type(a)~='table'then return a==b end for k,v in pairs(a)do if not same(v,b[k])then return false end end for k in pairs(b)do if a[k]==nil then return false end end return true end
GetBuildInfo=function()return '12.1.5','70961','Nov 18 2026',120105 end
GetTime=function()return 100 end;time=GetTime
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
GetItemInfo=function(id)return 'Item '..id end
local LL={db={characters={Fixture={professions={Enchanting=true}}},rateProfile=3,rateProfileCharacter='Fixture',
    source_legacy_enabled=false,source_reference_enabled=true,source_personal_enabled=false,source_imported_enabled=false}}
for _,file in ipairs({'ItemDBRuntime.lua','ProfessionCatalog.lua','Professions.lua','ProfessionModels.lua',
    'Database.lua','ConversionEngine.lua','Observations.lua','Badges.lua'})do assert(loadfile('LootLiquidator/'..file))('LL',LL)end
LL.CharacterKey=function()return 'Fixture'end
LL.GetResearchProfessionSnapshot=function()return 0,'none',7946 end
LL.GetCachedOperationInfo=function()end
LL.GetOutputPrice=function(_,id)return id==243606 and 300 or 100 end
LL.MarkupColor=function()return ''end
LL.Money=function(_,n)return tostring(n)..' copper'end
LL.ProfessionProgression=function()return{}end
LL.Invalidate=function(self)self._processingModelCache=nil;self._processingContextCache=nil end
LL:MigrateEvidenceSettings()
local originalProcessing=LL.ItemDB.processing
LL.ItemDB.processing={}
local cases={{id=250055,class=4,low=33/73,high=37/73},{id=250058,class=4,low=40/87,high=46/87},
    {id=250060,class=4,low=62/133,high=69/133},{id=275218,class=2,low=78/166,high=85/166}}
local function unknown()return{status='unknown',confidence=0,samples=0,sampleSizeKnown=false,inferenceBlocked=true}end
for _,case in ipairs(cases)do
    local r={recordID='evidence:reviewed-backlog:test-'..case.id,method='Disenchant',profession='Enchanting',recipeID=13262,
        inputCount=1,inputItemID=case.id,inputClassID=case.class,inputRarity=4,expansionID=11,sourceKey='itemdb',
        source='Published source-table fixture',sourceURL='https://www.wowhead.com/item='..case.id,
        studyID='exact-source-table-'..case.id,referenceContextID='reviewed-source-table-'..case.id,
        reviewedBacklogModel=true,reviewedDisenchantProjection='source-anchored',requiresSourceNormalization=true,
        reviewedPublishedPrior={kind='REVIEWED_BACKLOG_FIELDS',observedSamplesAdded=0},
        baselineProfileAssumed=true,baselineProfileConfidence=0,fixedReference=true,fieldSpecificEvidence=true,
        samples=0,sampleSizeKnown=false,baselineProfile={skill=0,preSpecializationSkill=0,stats={},
            specializationPoints={},learnedSpecializations={},sourceReportedProfile={}},materials={}}
    for index,id in ipairs({243605,243606})do r.materials[index]={id=id,
        expectedQuantity={value=index==1 and case.low or case.high,status='historical',confidence=20,
            modelConfidenceCap=0,independentConfidence=true,samples=0,sampleSizeKnown=false},
        dropChance=unknown(),minQuantity=unknown(),maxQuantity=unknown()}end
    case.record=r;LL.ItemDB.processing[#LL.ItemDB.processing+1]=r
    LL.ItemDB.inputs[case.id]={method='Disenchant',batch=1,expansion=11}
end
check(LL:InitializeItemDB(),LL.itemDBError or 'initialization')
local de={name='Disenchant',recipeID=13262,inputCount=1,profession='Enchanting'}
local function set(root,child,skill)
    check(LL:SetManualProfessionProfile('Fixture','Enchanting',11,{enabled=true,skill=skill,
        specialization='107649='..root..',107646='..child,buffs={}}),'manual profile')
    LL:Invalidate()
end
local function facts(case)return{id=case.id,expansionID=11,quality=4,classID=case.class,count=1}end
local function map(m)local out={}for _,v in ipairs(m.materials or{})do out[v.id]=v end return out end
local function quantity(m,id)return map(m)[id]and map(m)[id].expectedQuantity or 0 end
local function resolve(case)return assert(LL:ResolveEvidenceModel(facts(case),de,nil,1))end
local function sourceModel(case)
    local out=copy(case.record)
    for _,m in ipairs(out.materials)do m.expectedQuantity=m.expectedQuantity.value;m.chance=nil;m.minQuantity=nil;m.maxQuantity=nil end
    return out
end
local immutable=copy(LL.ItemDB.processing)
local function blocked(result,original,label)
    check(result~=original and result.projectionIncomplete and type(result.normalizationFailure)=='string'
        and same(result.materials,original.materials),label)
end
for _,case in ipairs(cases)do
    set(0,0,0)
    local f=facts(case);local zero=resolve(case)
    check(zero.disenchantBaselineApplied and zero.reviewedDisenchantProjected,'actual resolver reaches reviewed DE consumer')
    near(quantity(zero,243605),case.low,'source zero reference R1 roundtrip')
    near(quantity(zero,243606),case.high,'source zero reference R2 roundtrip')
    check(zero.confidence==0,'unknown source normalization confidence remains0')
    LL:ValueProcessingModel(zero,0,true,f)
    near(zero.value,case.low*100+case.high*300,'source reference reaches an actual full-DB priced quote')
    check(zero.valueConfidence==0,'source applicability stays0 after pricing')
    local raw=sourceModel(case)
    local projected=LL:ProjectReviewedDisenchantPrior(f,de,raw,LL:ProcessingPlayerConditions(f,de.name,de.recipeID,de.character),1)
    check(projected~=raw and #projected.materials==#raw.materials,'prefusion material IDs/order are stable')
    check(projected.reviewedDisenchantSourceReference.observedSamplesAdded==0
        and projected.reviewedDisenchantSourceReference.observedZeroProfileClaim==false,'declared reference never becomes an observed minimum cohort')
    for i,m in ipairs(projected.materials)do check(m.id==raw.materials[i].id,'no appended prefusion outputs')end
    for _,rank in ipairs({0,19,20,29,30})do
        set(30,rank,140)
        local result=resolve(case)
        near(quantity(result,243605)+quantity(result,243606),case.low+case.high,'Collector preserves this exact source primary pool')
        for _,id in ipairs({236949,236950,236951,236952})do
            check(map(result)[id]==nil,'native Collector milestone does not add an unmeasured essence outcome')
        end
        LL:ValueProcessingModel(result,0,true,f)
        check(type(result.value)=='number' and result.valueConfidence==0,'all four actual quotes price every Collector milestone with confidence0')
        if rank==30 then near(quantity(result,243606)/(case.low+case.high),.66,'full skill reaches existing declared quality endpoint')end
        for _,m in ipairs(result.materials)do
            check(m.quantityCounts==nil and m.samples==nil,'projected source adds no observed counts or samples')
            if m.chance~=nil then
                check((m.id==243605 or m.id==243606) and m.minQuantity==1 and m.maxQuantity==1
                    and m.probabilityVerified==false and m.chanceConfidence==0,
                    'a projected source may expose only the explicit confidence-zero one-unit category model')
                near(m.chance,m.expectedQuantity,'one-unit modeled occurrence agrees with its unchanged source expectation')
            end
        end
    end
    local disabled=copy(raw);disabled.reviewedDisenchantProjection=nil
    check(LL:ProjectReviewedDisenchantPrior(f,de,disabled,LL:ProcessingPlayerConditions(f,de.name,de.recipeID,de.character),1)==disabled,'no opt-in keeps legacy behavior')
    disabled=copy(raw);disabled.baselineProfile.skill=100
    blocked(LL:ProjectReviewedDisenchantPrior(f,de,disabled,LL:ProcessingPlayerConditions(f,de.name,de.recipeID,de.character),1),disabled,'known high source never minimum')
    disabled=copy(raw);disabled.baselineProfile.sourceReportedProfile.specialization='maxed'
    blocked(LL:ProjectReviewedDisenchantPrior(f,de,disabled,LL:ProcessingPlayerConditions(f,de.name,de.recipeID,de.character),1),disabled,'known max source cannot masquerade unknown')
    disabled=copy(raw);disabled.materials[2]=nil
    blocked(LL:ProjectReviewedDisenchantPrior(f,de,disabled,LL:ProcessingPlayerConditions(f,de.name,de.recipeID,de.character),1),disabled,'missing rank is unknown, not fabricated zero')
    blocked(LL:ProjectReviewedDisenchantPrior(f,de,raw,LL:ProcessingPlayerConditions(f,de.name,de.recipeID,de.character),2),raw,'personal-only policy excludes source prior')
    local other=copy(f);other.id=f.id+1
    blocked(LL:ProjectReviewedDisenchantPrior(other,de,raw,LL:ProcessingPlayerConditions(f,de.name,de.recipeID,de.character),1),raw,'exact source prior never widens into another item')
    local stale=copy(LL:ProcessingPlayerConditions(f,de.name,de.recipeID,de.character));stale.stale=true
    blocked(LL:ProjectReviewedDisenchantPrior(f,de,raw,stale,1),raw,'stale target fails closed without altering source fields')
    -- Preserve reviewed and other-source terms without an invented bonus.
    local current=LL:ProcessingPlayerConditions(f,de.name,de.recipeID,de.character)
    local primary=LL:ProjectReviewedDisenchantPrior(f,de,raw,current,1)
    local mixture={sources={itemdb=.3,legacy=.7},source='Mixed source fixture',confidence=0,inputCount=1,materials={}}
    for i,m in ipairs(primary.materials)do mixture.materials[i]={id=m.id,
        expectedQuantity=.3*m.expectedQuantity+.7*(i+4),confidence=0,
        sourceContributions={itemdb=.3,legacy=.7},sourceEstimates={itemdb={expectedQuantity=m.expectedQuantity,
            inputCount=1,unprojectedDisenchantExpectedQuantity=0}}}end
    local mixed=LL:ApplyDisenchantBaseline(f,de,mixture,current,1)
    for i,m in ipairs(mixture.materials)do near(quantity(mixed,m.id),m.expectedQuantity,'independent source primary term retained')end
    for _,id in ipairs({236949,236950,236951,236952})do check(map(mixed)[id]==nil,'source blending creates no unmeasured Collector outcome')end
    check(LL:ApplyDisenchantBaseline(f,de,mixed,current,1)==mixed,'post-fusion projection is not applied twice')
    -- Different source pool sizes must round-trip at zero; U/all-pool would
    -- inflate this ordinary portion because the reviewed pool is below1.
    set(0,0,0);current=LL:ProcessingPlayerConditions(f,de.name,de.recipeID,de.character)
    local canonical
    for _,b in ipairs(LL.ItemDB.modeledDisenchantBaselines)do if b.rule.inputRarity==4 and b.inputClassID==case.class then canonical=b end end
    local baseline=map({materials=canonical.materials})
    local fused={sources={itemdb=1},confidence=0,inputCount=1,materials={}}
    for i,id in ipairs({243605,243606})do
        local observed=i==1 and case.low or case.high
        local ordinary=.6*baseline[id].expectedQuantity
        local all=.4*observed+ordinary
        fused.materials[i]={id=id,expectedQuantity=all,confidence=0,sourceContributions={itemdb=1},
            sourceEstimates={itemdb={expectedQuantity=all,inputCount=1,unprojectedDisenchantExpectedQuantity=ordinary}}}
    end
    local routed=LL:ApplyDisenchantBaseline(f,de,fused,current,1)
    for _,m in ipairs(fused.materials)do near(quantity(routed,m.id),m.expectedQuantity,'zero-profile mixed ItemDB source means preserved')end
    set(30,30,140);current=LL:ProcessingPlayerConditions(f,de.name,de.recipeID,de.character)
    local targetPrimary=LL:ProjectReviewedDisenchantPrior(f,de,raw,current,1)
    local canonicalTarget=map({materials=assert(LL:DisenchantCurveQuantities(canonical,
        assert(LL:DisenchantForwardProfile(f,de,current,canonical.rule))))})
    for _,m in ipairs(fused.materials)do
        m.expectedQuantity=.4*quantity(targetPrimary,m.id)+m.sourceEstimates.itemdb.unprojectedDisenchantExpectedQuantity
        m.sourceEstimates.itemdb.expectedQuantity=m.expectedQuantity
    end
    routed=LL:ApplyDisenchantBaseline(f,de,fused,current,1)
    for _,m in ipairs(fused.materials)do near(quantity(routed,m.id),.4*quantity(targetPrimary,m.id)
        +.6*canonicalTarget[m.id].expectedQuantity,'only ordinary ItemDB portion is projected after fusion')end
    for _,id in ipairs({236949,236950,236951,236952})do check(map(routed)[id]==nil,'mixed ItemDB terms do not gain a borrowed essence budget')end
end
check(same(LL.ItemDB.processing,immutable),'published source records and counts remain immutable')
-- Render the actual final model, with source0 means and current skill effects
-- reaching the same recommendation tooltip caller used in game.
local case=cases[1];set(30,30,140);local result=resolve(case);local f=facts(case)
LL:ValueProcessingModel(result,0,true,f)
check(type(result.value or result.partialValue)=='number','actual priced output is produced')
local tip={lines={}}
function tip:AddLine(text)self.lines[#self.lines+1]=text end
function tip:AddDoubleLine(a,b)self.lines[#self.lines+1]=a..' | '..b end
LL.db.tooltipDetail=3;LL.db.showAverageQuantity=true;LL.db.showProfessionDetails=true
LL:AppendRecommendationTooltip(tip,{action='D',facts=f,disenchantEligible=true,conversionOptions={{name='Disenchant',letter='D',
    profession='Enchanting',recipeID=13262,inputCount=1,available=true,yieldModel=result,value=result.value or result.partialValue}}})
local text=table.concat(tip.lines,'\n')
check(text:find('243606',1,true),'actual tooltip contains the sourced projected crystal')
for _,id in ipairs({236949,236950,236951,236952})do
    check(not text:find(tostring(id),1,true),'actual tooltip omits the removed unmeasured essence pool')
end
check(not text:find('provisional',1,true) and not text:find('estimated',1,true),'no new tooltip estimate labels')
LL.ItemDB.processing=originalProcessing
print('PASS: '..checks..' reviewed DE prior source roundtrip, weighted fusion, milestone, price and tooltip checks')
