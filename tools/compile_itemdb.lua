-- Deterministic build-time migration. Run from repository root with Lua 5.1.
-- Source snapshots are NOT runtime modules and are never fetched at runtime.
local LL={}
for _,file in ipairs({'ResearchDB.lua','ReferenceData.lua'}) do
    assert(loadfile('database/sources/'..file))('LootLiquidator',LL)
end
local references=assert(LL.ReferenceData,'Frozen references missing')
assert(references.schemaVersion==1,'Unsupported frozen reference schema')
local db={schemaVersion=1,version='1.1.1',processing={},mechanicRules={},
    provenance='main 051f582 / v0.9.70; schema-validated provisional migration',
    compat={Conversions=references.compatConversions,DisenchantTables=LL.DisenchantTables,
        ResearchTokenCandidates=LL.ResearchTokenCandidates,ResearchProcessingInputs=LL.ResearchProcessingInputs}}
local methods={Mill='Inscription',Prospect='Jewelcrafting',Disenchant='Enchanting',Smelt='Mining'}
local function clone(t) local n={} for k,v in pairs(t or {}) do n[k]=v end return n end
-- Historical/frozen references are data snapshots, not outputs of old skill,
-- upgrade, inspiration, resourcefulness or guessed-range calculations.
local inputs=clone(references.inputs)
-- B2: the frozen TSM conversion snapshot (references.frozen) stays in the source
-- data for the record but is no longer compiled into the addon. TSM is used
-- only for Auction House prices (owner decision 3).
for _,dataset in ipairs({references.legacy}) do
    for _,record in ipairs(dataset.processing) do db.processing[#db.processing+1]=record end
end
-- Translate the pinned research schema without interpreting a low scenario as
-- a normalized current baseline. Preserve the complete source record/lineage.
local research=assert(loadfile('database/research/itemdb.lua'))()
assert((research.schemaVersion=='0.1.0' or research.schemaVersion=='0.2.0')
    and type(research.processing)=='table','Unsupported research schema')
db.researchManifest=research.sourceManifest
db.buildReport={adapted=0,tsmDuplicates=0,rejected={},researchMappings=#research.processing,
    researchSchemaVersion=research.schemaVersion,previewEstimatesPreserved=0}
-- Identity is typed and deterministic. Output identity/source URLs are deliberately
-- absent: cooutputs with the same input, operation and observed conditions belong
-- to one reference profile, even though the research ledger stores them as rows.
local function contextIdentity(v)
    local kind=type(v)
    if kind=='nil' then return 'nil' end
    if kind=='number' then return 'number:'..string.format('%.17g',v) end
    if kind=='string' then return 'string:'..string.format('%q',v) end
    if kind=='boolean' then return 'boolean:'..tostring(v) end
    assert(kind=='table','Unsupported research context type')
    local keys={} for key in pairs(v) do keys[#keys+1]=key end
    table.sort(keys,function(a,b) return contextIdentity(a)<contextIdentity(b) end)
    local out={'table:{'}
    for _,key in ipairs(keys) do out[#out+1]=contextIdentity(key)..'='..contextIdentity(v[key])..';' end
    out[#out+1]='}';return table.concat(out)
end
local function known(v)
    if v==nil then return false end
    if type(v)=='string' then
        local text=v:upper()
        return text~='UNKNOWN' and text~='REFERENCE_UNKNOWN' and not text:find('UNVERIFIED',1,true)
            and not text:find('NOT_ESTABLISHED',1,true)
    end
    return true
end
local function referenceConditions(c)
    local out,unresolved={},{}
    for _,key in ipairs({'skillLineID','skill','baseSkill','effectiveSkill','bonusSkill',
        'operationStats','equipment','equipmentKey','specializationRanks'}) do
        if known(c[key]) then out[key]=c[key] end
    end
    if known(c.specialization) then
        -- Named tree/gem hints without ranks are source limitations, not exact
        -- runtime specialization snapshots. Never invent a rank from such a hint.
        if type(c.specialization)=='string' or (type(c.specialization)=='table' and c.specialization.requiredPoints~=nil) then
            out.specialization=c.specialization
        else unresolved[#unresolved+1]='specialization' end
    end
    return out,unresolved
end
local function validatePreview(r)
    local w=r.workingEstimate
    if w==nil then return end
    assert(research.schemaVersion=='0.2.0' and type(w)=='table'
        and w.economicUse=='PREVIEW_ONLY' and w.normalizedVerified==false
        and w.evidenceFieldsPreserved==true,'Unsupported working estimate contract: '..r.recordID)
    for _,key in ipairs({'dropChance','yieldMin','yieldMax','expectedQuantity'}) do
        local v=w[key]
        assert(type(v)=='number' and v==v and v>=0 and v<math.huge,
            'Invalid preview field: '..r.recordID..':'..key)
    end
    assert(w.dropChance<=1 and w.yieldMin%1==0 and w.yieldMax%1==0
        and w.yieldMin<=w.yieldMax,'Invalid preview probability/bounds: '..r.recordID)
    db.buildReport.previewEstimatesPreserved=db.buildReport.previewEstimatesPreserved+1
end
local function adaptField(f)
    assert(type(f)=='table' and type(f.confidence)=='number','Invalid research field')
    local n=clone(f)
    n.status=({proxy='historical',['community-reported']='provisional',modeled='modeled',
        measured='measured',verified='verified',unknown='unknown'})[f.status] or 'provisional'
    if n.value==nil then n.status='unknown' end
    return n
end
-- Owner decision (A1): a best guess beats nothing. A research working estimate
-- fills ONLY fields the evidence leaves unknown, as a low-confidence modeled
-- value flagged workingEstimate=true. Real evidence is never overwritten.
local WORKING_CONFIDENCE=10
local function fillFromWorkingEstimate(r,material)
    local w=r.workingEstimate
    if type(w)~='table' then return end
    local filled={}
    for field,key in pairs({expectedQuantity='expectedQuantity',dropChance='dropChance',
        minQuantity='yieldMin',maxQuantity='yieldMax'}) do
        local f=material[field]
        if f.value==nil and type(w[key])=='number' and not (key~='expectedQuantity' and key~='dropChance' and w[key]<1) then
            f.value=w[key];f.status='modeled';f.confidence=WORKING_CONFIDENCE;f.workingEstimate=true
            filled[field]=true
        end
    end
    local e,p,lo,hi=material.expectedQuantity,material.dropChance,material.minQuantity,material.maxQuantity
    local function contradictory()
        return e.value and p.value and lo.value and hi.value
            and (e.value+1e-9<p.value*lo.value or e.value>p.value*hi.value+1e-9)
            or (e.value==0 and p.value and p.value>0)
            or (lo.value and hi.value and lo.value>hi.value)
    end
    -- Never let a filled guess contradict real evidence: drop guesses, bounds first.
    for _,field in ipairs({'minQuantity','maxQuantity','dropChance','expectedQuantity'}) do
        if not contradictory() then break end
        if filled[field] then
            local f=material[field];f.value=nil;f.status='unknown';f.confidence=0;f.workingEstimate=nil
        end
    end
    if next(filled) then db.buildReport.workingEstimatesUsed=(db.buildReport.workingEstimatesUsed or 0)+1 end
end
for _,r in ipairs(research.processing) do
    validatePreview(r) -- full preview stays under researchRecord; unknown fields are filled below
    local provenance=table.concat(r.sources or {},' ')..' '..tostring(r.conditions and r.conditions.sourceContext)
    local isTSM=r.recordID:match('^tsm:') or provenance:lower():find('tsm',1,true)
    if isTSM then
        db.buildReport.tsmDuplicates=db.buildReport.tsmDuplicates+1
    elseif not methods[r.method] then
        db.buildReport.rejected[#db.buildReport.rejected+1]={recordID=r.recordID,reason='Unsupported method'}
    elseif r.reagents and #r.reagents>1 then
        db.buildReport.rejected[#db.buildReport.rejected+1]={recordID=r.recordID,reason='Multi-reagent costing not supported'}
    else
        local c=r.conditions or {}
        local patch=c.patchWindow
        local conditions,unresolved=referenceConditions(c)
        local contextID='research-context-v1:'..contextIdentity({method=r.method,inputItemID=r.inputItemID,
            inputCount=r.inputCountPerOperation,inputQualityRank=r.inputQualityRank,
            recipeID=r.recipeSpellID,expansionID=r.expansionID,conditions=c})
        local n={recordID='research:'..r.recordID,sourceKey='itemdb',studyID=r.recordID,
            method=r.method,profession=methods[r.method],inputItemID=r.inputItemID,inputCount=r.inputCountPerOperation,
            inputQualityRank=r.inputQualityRank,recipeID=r.recipeSpellID,expansionID=r.expansionID,
            minimumRecipeSkill=c.minimumRecipeSkill,
            source=table.concat(r.sources or {},'; '),samples=r.expectedQuantity.sampleOperations,
            referenceContextID=contextID,referenceConditions=conditions,researchConditions=c,
            unresolvedResearchConditions=unresolved,researchRecord=r,provisional=true,
            referenceApplicability=next(conditions) and 'condition-matched' or 'unverified-reference',
            baselineStatus=c.baselineStatus,materials={{id=r.outputItemID,quality=r.outputQualityRank,
                expectedQuantity=adaptField(r.expectedQuantity),dropChance=adaptField(r.dropChance),
                minQuantity=adaptField(r.yieldMin),maxQuantity=adaptField(r.yieldMax)}}}
        if type(patch)=='table' then
            n.patchStartBuild=patch.startBuild;n.patchEndBuild=patch.endBuild
            n.targetBuild=patch.targetBuild or patch.build
        end
        fillFromWorkingEstimate(r,n.materials[1])
        n.targetBuild=c.targetBuild or c.patchBuild or n.targetBuild
        n.hotfixBlocked=c.hotfixBlocked==true or c.normalizationBlocked==true or nil
        -- Only an explicit normalized export can opt into forward profession rules.
        if c.baselineProfile and c.targetBuild then n.baselineProfile=c.baselineProfile;n.patchBuild=c.targetBuild end
        db.processing[#db.processing+1]=n
        db.buildReport.adapted=db.buildReport.adapted+1
        inputs[r.inputItemID]=inputs[r.inputItemID] or {method=r.method,batch=r.inputCountPerOperation,expansion=r.expansionID}
    end
end
-- Reviewed registry rules arrive exclusively through the pinned ItemDB export.
local function contextMatches(actual, expected)
    for key,value in pairs(expected) do
        if key~='build' and contextIdentity(actual[key])~=contextIdentity(value) then return false end
    end
    return true
end
local function contains(list,value) for _,v in ipairs(list or {}) do if v==value then return true end end return false end
local approvedIDs={}
for _,rule in ipairs(research.mechanicRules or {}) do
    local label=tostring(rule.ruleID)
    assert(not approvedIDs[label],'Duplicate approved mechanic '..label);approvedIDs[label]=true
    assert(rule.applyPolicy=='VERIFIED_FOR_COMPILE' and rule.evidenceStatus=='VERIFIED_NUMERIC'
        and rule.numericTransformValidated==true and (rule.confidence0to100 or 0)>=90
        and type(rule.sources)=='table' and #rule.sources>=2
        and type(rule.independentReview)=='table' and rule.independentReview.reviewer
        and type(rule.independentReview.passedTestIDs)=='table' and #rule.independentReview.passedTestIDs>0,
        'Unapproved ItemDB mechanic '..label)
    local expectedFormula=({OUTPUT_UNCONDITIONAL_EXPECTATION='RATIO_ADJUSTMENT',OUTPUT_OCCURRENCE='RATIO_ADJUSTMENT_OCCURRENCE'})[rule.effectTarget]
    assert(expectedFormula and rule.formulaID==expectedFormula,'Unsupported approved mechanic '..label)
    local scope,reference,target=rule.scope,rule.referenceContext,rule.targetContext
    assert(scope and scope.gameMode=='RETAIL' and reference and reference.build and target and target.build,'Missing explicit build/context '..label)
    local factor=rule.parameters and rule.parameters.targetFactor/rule.parameters.referenceFactor
    assert(type(factor)=='number' and factor==factor and factor>=0 and factor<=10,'Invalid mechanic ratio '..label)
    local targetConditions=clone(target);targetConditions.build=nil
    for _,key in ipairs(rule.requiredLiveContext or {}) do assert(targetConditions[key]~=nil,'Missing target field '..label..':'..key) end
    assert(next(targetConditions),'Empty target conditions '..label)
    local matched=0
    for _,record in ipairs(db.processing) do
        local original=record.researchRecord
        if original and record.sourceKey=='itemdb' and record.method==rule.method
            and record.expansionID==rule.expansionID and contains(scope.recipeSpellIDs,record.recipeID)
            and contains(scope.inputItemIDs,record.inputItemID) and contains(scope.outputItemIDs,original.outputItemID)
            and record.inputCount==scope.nominalInputCount and contains(scope.inputQualityRanks,record.inputQualityRank)
            and (not scope.outputQualityRanks or #scope.outputQualityRanks==0 or contains(scope.outputQualityRanks,original.outputQualityRank))
            and contextMatches(original.conditions.baselineProfile or original.conditions,reference) then
            assert(not record.patchBuild or tostring(record.patchBuild)==tostring(reference.build),'Baseline build conflict '..label)
            record.patchBuild=reference.build;record.mechanicsSourceBuild=reference.build
            record.targetBuild=nil;record.patchStartBuild=nil;record.patchEndBuild=nil
            local translated={ruleID=label..':'..original.recordID,method=rule.method,recipeID=record.recipeID,
                inputItemID=record.inputItemID,outputItemID=original.outputItemID,expansionID=record.expansionID,
                inputQualityRank=record.inputQualityRank,sourceBuild=reference.build,targetBuild=target.build,
                sourceReferenceContextID=record.referenceContextID,targetConditions=targetConditions,
                effectTarget=rule.effectTarget,formulaID='MULTIPLY',parameters={multiplier=factor},
                evidenceStatus='VERIFIED_NUMERIC',applyPolicy='EXECUTE',applies='VERIFIED_APPLIES',
                confidence0to100=rule.confidence0to100,numericTransformValidated=true,independentReview='APPROVED',sourceClaimIDs={}}
            for _,source in ipairs(rule.sources) do translated.sourceClaimIDs[#translated.sourceClaimIDs+1]=assert(source.claimID) end
            db.mechanicRules[#db.mechanicRules+1]=translated;matched=matched+1
        end
    end
    assert(matched>0,'Approved mechanic has no compatible baseline mapping: '..label)
end
local models=assert(loadfile('database/profession-models.lua'))()
assert(models.schemaVersion==1,'Unsupported profession model schema')
db.professionRules=models.professionRules;db.personalPatchRules=models.personalPatchRules;db.modelRevision=models.revision
-- Reviewed additions use the same versioned interface, independent of engine code.
local additions=assert(loadfile('database/records.lua'))()
db.tokenRewards=additions.tokenRewards or {}
for _,r in ipairs(additions.processing or {}) do db.processing[#db.processing+1]=r end
for _,r in ipairs(additions.mechanicRules or {}) do
    assert(r.evidenceStatus=='VERIFIED_NUMERIC' and r.applyPolicy=='EXECUTE' and r.numericTransformValidated==true
        and type(r.sourceClaimIDs)=='table' and #r.sourceClaimIDs>0 and r.independentReview=='APPROVED',
        'Mechanics require numerical validation and independent approval')
    db.mechanicRules[#db.mechanicRules+1]=r
end
table.sort(db.processing,function(a,b) return a.recordID<b.recordID end)
-- Fixed conversions remain one copy; the valuation engine adapts these to a model.
db.inputs=inputs
db.compat.GameData=references.compatGameData
local function finite(n) return type(n)=='number' and n==n and n<math.huge and n>=0 end
local seen={}
for _,r in ipairs(db.processing) do
    for _,m in ipairs(r.materials) do for name,f in pairs(m) do
        if type(f)=='table' and f.status then f.sourceClaimIDs=f.sourceClaimIDs or {r.studyID..':'..m.id..':'..name} end
    end end
    assert(not seen[r.recordID],'duplicate record '..r.recordID);seen[r.recordID]=true
    assert(r.studyID and r.source and finite(r.inputCount) and r.inputCount>0)
    local ids={}
    for _,m in ipairs(r.materials) do
        assert(not ids[m.id],'duplicate output '..r.recordID);ids[m.id]=true
        for _,key in ipairs({'expectedQuantity','dropChance','minQuantity','maxQuantity'}) do
            local v=m[key].value
            assert(v==nil or finite(v),'invalid field '..r.recordID..':'..key)
        end
        local p,e=m.dropChance.value,m.expectedQuantity.value
        assert(p==nil or p<=1)
        assert(not (e==0 and p and p>0),'zero/chance contradiction')
    end
end
local function encode(v)
    if type(v)=='number' then return string.format('%.17g',v) end
    if type(v)=='string' then return string.format('%q',v) end
    if type(v)=='boolean' then return tostring(v) end
    assert(type(v)=='table','unsupported compiled value')
    local keys={} for k in pairs(v) do keys[#keys+1]=k end
    table.sort(keys,function(a,b) if type(a)==type(b) then return a<b end return type(a)<type(b) end)
    local out={'{'}
    for _,k in ipairs(keys) do out[#out+1]='['..encode(k)..']='..encode(v[k])..',' end
    out[#out+1]='}';return table.concat(out)
end
LL.ItemDB=db
assert(loadfile('LootLiquidator/ProfessionModels.lua'))('LootLiquidator',LL)
for _,rule in ipairs(db.mechanicRules) do
    assert(LL:IsApprovedNumericRule(rule),'Mechanic failed shared numeric evidence gate: '..tostring(rule.ruleID))
end
local validModels,modelError=LL:ValidateProfessionRules(db)
assert(validModels,modelError)
assert(loadfile('LootLiquidator/Database.lua'))('LootLiquidator',LL)
assert(not LL.itemDBError,LL.itemDBError)
local legacy={schemaVersion=1,version='legacy-v0.9.70/1',processing={}}
local primary={}
for _,r in ipairs(db.processing) do
    assert(r.sourceKey~='itemtsm','Frozen TSM records must not be compiled (B2)')
    if r.sourceKey=='legacy' then legacy.processing[#legacy.processing+1]=r
    else primary[#primary+1]=r end
end
local total=#db.processing
db.processing=primary
local output=arg[1] or 'LootLiquidator/ItemDBRuntime.lua'
-- C3: one database. The old disenchant estimates (formerly GameData.lua /
-- LL.LegacyDB) and the DB2 no-disenchant list + mill/prospect hints (formerly
-- DB2Restrictions.lua) now ship inside ItemDBRuntime.lua as ItemDB.legacy and
-- ItemDB.restrictions. Database.lua unpacks them at load.
local restrictionSource={}
assert(loadfile('database/sources/DB2Restrictions.lua'))('LootLiquidator',restrictionSource)
local restrictions={build=restrictionSource.ItemRestrictionsBuild,noDisenchant={},processable={}}
for id in pairs(restrictionSource.ItemRestrictions or {}) do restrictions.noDisenchant[#restrictions.noDisenchant+1]=id end
table.sort(restrictions.noDisenchant)
for id,method in pairs(restrictionSource.DB2Processable or {}) do restrictions.processable[id]=method end
local file=assert(io.open(output,'w'))
file:write('-- Generated by tools/compile_itemdb.lua. Unknown fields are absent, not zero.\nlocal _, LL = ...\nLL.ItemDB=',(encode(db):gsub('},%[','},\n[')),'\n')
file:write('-- Old disenchant estimates (weak "legacy" source).\nLL.ItemDB.legacy=',encode(legacy),'\n')
file:write('-- DB2 no-disenchant item IDs and mill/prospect input hints (build ',tostring(restrictions.build),').\nLL.ItemDB.restrictions=',encode(restrictions),'\n')
file:close()
print('Compiled '..total..' source records (provisional and documented recipes) to '..output)

