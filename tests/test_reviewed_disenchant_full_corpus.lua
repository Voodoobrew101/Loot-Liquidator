-- Reviewed cohorts must contribute in the shipped corpus, including the raw
-- exact-personal path; aggregate overlap never implies a pooled union.
local data=assert(loadfile(arg and arg[1] or 'database/disenchant-category-baselines.lua'))()
local records={}
for _,r in ipairs(data.processing) do if r.retainedSourceProfileKey then records[#records+1]=r end end
assert(#records==4,'four reviewed cohorts required')
GetTime=function() return 100 end
time=function() return 1000 end
GetBuildInfo=function() return '12.1.5','70961' end
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
local checks=0
local function check(v,m) assert(v,m);checks=checks+1 end
local function copy(v) if type(v)~='table' then return v end local o={} for k,x in pairs(v) do o[k]=copy(x) end return o end
local function near(a,b,m) check(type(a)=='number' and type(b)=='number' and math.abs(a-b)<1e-8,m) end
local function equal(a,b) if type(a)~=type(b) then return false end if type(a)~='table' then return a==b end for k,v in pairs(a) do if not equal(v,b[k]) then return false end end for k in pairs(b) do if a[k]==nil then return false end end return true end
local frozenRecords=copy(records)
local shipped={};assert(loadfile('LootLiquidator/ItemDBRuntime.lua'))('LL',shipped)
local base={}
for _,r in ipairs(shipped.ItemDB.processing) do if not r.retainedSourceProfileKey then base[#base+1]=r end end
local function setup(include)
    local db={} for k,v in pairs(shipped.ItemDB) do db[k]=v end
    db.processing={} for _,r in ipairs(base) do db.processing[#db.processing+1]=r end
    if include then for _,r in ipairs(records) do db.processing[#db.processing+1]=r end end
    local ll={ItemDB=db,db={source_itemdb_enabled=true,source_legacy_enabled=false,
        source_reference_enabled=false,source_personal_enabled=true,source_imported_enabled=false}}
    for _,file in ipairs({'ProfessionModels.lua','ProfessionCalculations.lua','Database.lua','Professions.lua','ConversionEngine.lua'}) do assert(loadfile('LootLiquidator/'..file))('LL',ll) end
    ll.CharacterKey=function()return 'Another - Realm' end
    ll.GetOutputPrice=function(_,id)return 100+id%17,'deterministic net quote' end
    check(ll:InitializeItemDB(),ll.itemDBError or 'full database valid')
    return ll
end
local before,after=setup(false),setup(true)
for _,change in ipairs({
    function(r)r.retainedSourceProfileKey='effective:0;specialization:none;buffs:'end,
    function(r)r.sourceKind='ordinary-unreviewed-source'end,
    function(r)r.sourceRecordIDs[2]=r.sourceRecordIDs[1]end,
    function(r)r.observedOperations=r.observedOperations+1 end,
    function(r)r.fixedReference=false end,
    function(r)r.categoryReferenceOnly=true end}) do
    local row=copy(records[#records]);change(row)
    check(not after:ValidateItemDB({schemaVersion=1,processing={row}}),'malformed retained-source proof fails schema validation')
end
local option={name='Disenchant',profession='Enchanting',recipeID=13262,inputCount=1}
local function used(model,id)
    for _,m in ipairs(model.materials) do
        for _,estimate in pairs(m.sourceEstimates or {}) do
            for _,r in ipairs(estimate.records or {}) do if r.recordID==id then return true end end
        end
    end
    return false
end
local function signature(model)
    local out={} for _,m in ipairs(model.materials) do out[m.id]={m.expectedQuantity,m.chance,m.minQuantity,m.maxQuantity} end return out
end
local function evaluate(ll,facts,ctx,personal,mode)
    ll.ProcessingPlayerConditions=function()return ctx end
    return assert(ll:ComputeEvidenceModel(facts,option,personal,mode or 1,ctx,true))
end
local function personal(r,ctx,ids)
    local p={effectiveSamples=#ids,samples=#ids,operations=#ids,sourceRecordIDs=copy(ids),
        inputCount=1,patchBuild=r.patchBuild,studyID='actual-profile-test-ledger',
        observationContextID='actual-profile-test-context',observationContext=copy(ctx),
        referenceContextID='actual-profile-test-reference',isDisenchantCategory=true,gearKey=r.gearKey,
        coverageCensored=true,materials={}}
    for _,m in ipairs(r.materials) do p.materials[#p.materials+1]={id=m.id,
        expectedQuantity=m.expectedQuantity.value,chance=m.dropChance.value,
        minQuantity=m.minQuantity.value,maxQuantity=m.maxQuantity.value,samples=#ids} end
    return p
end
for index,r in ipairs(records) do
    local facts={id=990000+index,classID=r.inputClassID,quality=r.inputRarity,expansionID=r.expansionID,
        itemLevel=100,count=1,context={isBound=true}}
    local ctx=copy(r.baselineProfile);ctx.character='Another - Realm';ctx.profileKind='live'
    local old=evaluate(before,facts,ctx)
    local model=evaluate(after,facts,ctx)
    check(used(model,r.recordID),'reviewed source contributes in FULL corpus: '..r.gearKey)
    check(not equal(signature(old),signature(model)),'reviewed source affects actual quantities: '..r.gearKey)
    local gold=0 for _,m in ipairs(model.materials) do if m.expectedQuantity then gold=gold+m.expectedQuantity*after:GetOutputPrice(m.id) end end
    near(after:ValueProcessingModel(model,0,true,facts),gold,'gold uses fused E once, never P times E')
    for _,change in ipairs({
        function(c)c.effectiveSkill=c.effectiveSkill+1 end,
        function(c)c.effectiveSkill=0;c.preSpecializationSkill=0;c.skill=0 end,
        function(c)c.buffsKnown=false end,
        function(c)c.specializationKnown=false;c.disenchantSpecializationKnown=false end,
        function(c)c.effectiveSkill=nil;c.preSpecializationSkill=nil;c.skill=nil end,
        function(c)c.specializationPoints={['999999']=1};c.learnedSpecializations={['999999']=true} end}) do
        local changed=copy(ctx);change(changed)
        local actual=evaluate(after,facts,changed)
        check(not used(actual,r.recordID),'unknown or different relevant profile fails closed')
        check(equal(signature(actual),signature(evaluate(before,facts,changed))),'mismatch leaves ordinary corpus unchanged')
        local public=assert(after:ResolveEvidenceModel(facts,option,nil,1))
        local original=assert(before:ResolveEvidenceModel(facts,option,nil,1))
        check(equal(signature(public),signature(original)),'mismatch retains identical OLD public canonical behavior')
    end
    local unrelated=copy(ctx);unrelated.buffs['987654321']=true;unrelated.buffStacks['987654321']=7
    check(used(evaluate(after,facts,unrelated),r.recordID),'unrelated aura is ignored')
    -- A declared model dependency differs from unrelated aura noise. This
    -- fixture adds one declaration to the native profile, without adding any
    -- numeric multiplier or changing source/target skill.
    local originalData=after.ItemDB.professionProfiles
    local revised={} for k,v in pairs(originalData)do revised[k]=v end
    revised.profiles={} for k,v in pairs(originalData.profiles)do revised.profiles[k]=v end
    local profile={} for k,v in pairs(revised.profiles['Enchanting:'..r.expansionID])do profile[k]=v end
    profile.condition={spellIDs={987654320}}
    revised.profiles['Enchanting:'..r.expansionID]=profile
    after.ItemDB.professionProfiles=revised
    local relevant=copy(ctx);relevant.buffs['987654320']=true
    check(not used(evaluate(after,facts,relevant),r.recordID),'different declared material-model buff fails exact-profile gate')
    after.ItemDB.professionProfiles=originalData
    -- These are raw exact-personal estimates: deliberately NO professionProjected.
    local same=personal(r,ctx,r.sourceRecordIDs);local frozen=copy(same)
    local sameResult=evaluate(after,facts,ctx,same)
    check(not used(sameResult,r.recordID) and (sameResult.sources.personal or 0)>0,'same IDs: one eligible personal survivor, never neither')
    check(equal(same,frozen),'dedupe leaves raw personal estimate immutable')
    check(equal(signature(assert(after:ResolveEvidenceModel(facts,option,same,1))),signature(sameResult)),
        'public finalization preserves the actual overlap winner')
    local function overlapCase(label,ids,expectShared)
        local p=personal(r,ctx,ids)
        local actual=evaluate(after,facts,ctx,p)
        check(used(actual,r.recordID)==expectShared,label..': shared survivor')
        check(((actual.sources.personal or 0)>0)==not expectShared,label..': exactly one contributor')
        if expectShared then check(equal(signature(actual),signature(model)),label..': no duplicate sample weight') end
    end
    if #r.sourceRecordIDs>1 then
        local subset={} for i=1,math.max(1,math.floor(#r.sourceRecordIDs*.75)) do subset[#subset+1]=r.sourceRecordIDs[i] end
        overlapCase('subset uses actual N, not half support N',subset,true)
        local partial={} for i=1,math.floor(#r.sourceRecordIDs/2) do partial[#partial+1]=r.sourceRecordIDs[i] end
        for i=1,math.max(1,math.floor(#r.sourceRecordIDs/4)) do partial[#partial+1]='fixture-partial-'..i end
        overlapCase('partial overlap chooses whole larger cohort',partial,true)
    end
    local superset=copy(r.sourceRecordIDs);superset[#superset+1]='fixture-new-operation'
    overlapCase('superset keeps eligible larger personal aggregate',superset,false)
    local disjoint={} for i=1,#r.sourceRecordIDs do disjoint[i]='fixture-independent-'..i end
    local independent=evaluate(after,facts,ctx,personal(r,ctx,disjoint))
    check(used(independent,r.recordID),'nonoverlapping shared cohort remains eligible')
    -- A different raw personal reference remains subject to the unchanged
    -- reference-context contract; no unsupported cross-context pooling added.
    local overlapPersonal=personal(r,ctx,r.sourceRecordIDs)
    after.ProcessingPlayerConditions=function()return ctx end
    local cached=assert(after:ResolveEvidenceModel(facts,option,overlapPersonal,1))
    overlapPersonal.sourceRecordIDs=copy(disjoint)
    local recalc=assert(after:ResolveEvidenceModel(facts,option,overlapPersonal,1))
    check(cached~=recalc and used(recalc,r.recordID),'changing only operation-ID overlap invalidates the final model cache')
    after.db.source_personal_enabled=false
    check(used(evaluate(after,facts,ctx,same),r.recordID),'personal disabled preserves shared cohort')
    after.db.source_personal_enabled=true;after.db.source_itemdb_enabled=false
    check((evaluate(after,facts,ctx,same).sources.personal or 0)>0,'shared disabled preserves personal-only behavior')
    after.db.source_itemdb_enabled=true
    check((evaluate(after,facts,ctx,same,2).sources.personal or 0)>0,'personal-only mode preserved')
    after.db.source_itemdb_enabled=false;before.db.source_itemdb_enabled=false
    local disabled=after:ResolveEvidenceModel(facts,option,nil,1)
    local disabledOld=before:ResolveEvidenceModel(facts,option,nil,1)
    check((disabled==nil and disabledOld==nil) or disabled and disabledOld and equal(signature(disabled),signature(disabledOld)),
        'shared source OFF preserves the original public result')
    after.db.source_itemdb_enabled=true;before.db.source_itemdb_enabled=true
    -- Verify the real public context builder, not only a copied source context.
    local ll=setup(true)
    ll.db.characters={['Another - Realm']={professions={Enchanting=true},researchProfiles={}}}
    local saved=copy(r.baselineProfile)
    saved.skill=saved.baseSkill;saved.observed=1000;saved.lineID=saved.skillLineID
    saved.specializationVerified=true;saved.specializationSignatureEncoding='trait-node-current-rank'
    saved.specializationEncoding='invested-points';saved.disenchantSpecializationKnown=true
    saved.disenchantSpecializationEncoding='invested-points'
    saved.disenchantSpecializationPoints=copy(saved.specializationPoints)
    saved.disenchantLearnedSpecializations=copy(saved.learnedSpecializations)
    ll.db.characters['Another - Realm'].researchProfiles['Enchanting:'..r.expansionID]=saved
    ll.GetResearchProfessionSnapshot=function()return saved.skill,saved.specialization,saved.lineID end
    ll.ProfessionAuraState=function()return copy(saved.buffs),copy(saved.buffStacks),true end
    local current=ll:ProcessingPlayerConditions(facts,'Disenchant',13262,nil,'Enchanting')
    check(ll:DisenchantObservationProfileKey(current)==r.retainedSourceProfileKey,'public current scanned profile key matches')
    local direct=assert(ll:ComputeEvidenceModel(facts,option,nil,1,current,true))
    local resolved=assert(ll:ResolveEvidenceModel(facts,option,nil,1))
    check(used(resolved,r.recordID),'public Resolve uses matching scanned profile')
    check(equal(signature(resolved),signature(direct)),'public finalizers preserve the exact-profile measured quantities/chance/ranges')
    local resolvedGold=ll:ValueProcessingModel(resolved,0,true,facts)
    near(resolvedGold,ll:ValueProcessingModel(direct,0,true,facts),'public finalizers preserve the actual gold result')
    -- The actual shared renderer receives that resolved model; display fields
    -- cannot replace the selected E or calculate gold from P a second time.
    assert(loadfile('LootLiquidator/Badges.lua'))('LL',ll)
    ll.db.tooltipDetail=3;ll.db.tooltipOutputSort='database'
    ll.MarkupColor=function()return ''end
    ll.Money=function(_,n)return ('%.8fc'):format(n)end
    ll.ProcessingMethodMode=function()return 1 end
    ll.TooltipConversionOptions=nil
    C_Item={GetItemInfo=function(id)return 'Material '..id end,GetItemIconByID=function(id)return id+1000 end}
    local tip={lines={},rows={}}
    function tip:AddLine(s)self.lines[#self.lines+1]=s end
    function tip:AddDoubleLine(a,b)self.rows[#self.rows+1]={a,b}end
    ll:AppendRecommendationTooltip(tip,{action='D',facts=facts,disenchantEligible=true,
        conversionOptions={{name='Disenchant',profession='Enchanting',letter='D',available=true,
            inputCount=1,value=resolvedGold,yieldModel=resolved}}})
    check(#tip.rows==#resolved.materials+1,'renderer preserves every resolved output')
    check(tip.rows[1][2]==ll:Money(resolvedGold),'method header shows actual computed gold')
    for i,m in ipairs(resolved.materials)do
        local row=tip.rows[i+1]
        check(row[1]:find('%% ') and row[1]:find('|T'..(m.id+1000)..':14:14:0:0|t ',1,true)
            and row[1]:find('Material '..m.id,1,true) and row[1]:find('%[.-%]')
            and not row[1]:find('x ',1,true),'approved percentage/icon/name/range format')
        near(m.netExpectedValue,m.expectedQuantity*ll:GetOutputPrice(m.id),'material gold is E times quote once')
        check(row[2]==ll:Money(m.netExpectedValue),'renderer shows unchanged material gold')
    end
    ll._processingContextCache=nil;ll._processingModelCache=nil
    ll.db.characters['Scanned Alt - Realm']=copy(ll.db.characters['Another - Realm'])
    ll.db.rateProfile=2;ll.db.rateProfileCharacter='Scanned Alt - Realm'
    check(used(assert(ll:ResolveEvidenceModel(facts,option,nil,1)),r.recordID),'public Resolve uses matching offline alt profile')
    ll._processingContextCache=nil;ll._processingModelCache=nil
    ll.db.rateProfile=3;ll.db.rateProfileCharacter='Another - Realm'
    ll.GetManualProfessionProfile=function()return{enabled=true,skill=r.baselineProfile.effectiveSkill,
        specialization='none',buffs={},buffStacks={}}end
    check(used(assert(ll:ResolveEvidenceModel(facts,option,nil,1)),r.recordID),'public Resolve uses matching explicit simulation')
end
-- Optional audit harness supplies the ORIGINAL decoded transfer to exercise
-- the real private reader; no raw ledger copy is added to runtime/test data.
if rawReviewedCapture then
    local ll=setup(true)
    assert(loadfile('LootLiquidator/CraftRecording.lua'))('LL',ll)
    ll.db.craftResearch=copy(rawReviewedCapture)
    ll.db.craftResearch.activeStudy=nil
    ll.CharacterKey=function()return rawReviewedCapture.records[1].character end
    for index,r in ipairs(records) do
        local ctx=copy(r.baselineProfile);ctx.character=ll:CharacterKey();ctx.profileKind='live'
        ll.CaptureCraftContext=function()return copy(ctx)end
        local facts={id=995000+index,classID=r.inputClassID,quality=r.inputRarity,expansionID=r.expansionID,itemLevel=100,count=1}
        local p=assert(ll:GetRecordedDisenchantCategoryEstimate(facts,13262,ctx),'real private category available')
        check(p.professionProjected==nil,'actual exact private reader remains unprojected')
        check(#p.sourceRecordIDs==r.observedOperations,'actual private denominator/provenance match')
        local m=evaluate(ll,facts,ctx,p)
        check((m.sources.personal or 0)>0 and not used(m,r.recordID),'actual owner ledger contributes exactly once')
        local resolved=assert(ll:ResolveEvidenceModel(facts,option,p,1))
        check((resolved.sources.personal or 0)>0 and not used(resolved,r.recordID)
            and equal(signature(resolved),signature(m)),'public dispatch preserves the actual owner ledger survivor')
    end
end
check(equal(records,frozenRecords),'all reviewed source values and compact provenance remain immutable')
print('PASS: '..checks..' full-corpus/profile/overlap/public-dispatch checks')
