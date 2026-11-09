-- Deterministic build-time migration. Run from repository root with Lua 5.1.
-- Source snapshots are NOT runtime modules and are never fetched at runtime.
local LL={}
for _,file in ipairs({'ResearchDB.lua','ReferenceData.lua'}) do
    assert(loadfile('database/sources/'..file))('LootLiquidator',LL)
end
local references=assert(LL.ReferenceData,'Frozen references missing')
assert(references.schemaVersion==1,'Unsupported frozen reference schema')
local db={schemaVersion=1,version='1.2.0',processing={},mechanicRules={},
    provenance='Pinned research plus versioned Retail reference fallbacks; see researchV3Manifest and referenceManifest',
    compat={Conversions=references.compatConversions,DisenchantTables=LL.DisenchantTables,
        ResearchTokenCandidates=LL.ResearchTokenCandidates,ResearchProcessingInputs=LL.ResearchProcessingInputs}}
local methods={Mill='Inscription',Prospect='Jewelcrafting',Disenchant='Enchanting',Smelt='Mining'}
local function clone(t) local n={} for k,v in pairs(t or {}) do n[k]=v end return n end
local function deepCopy(value)
    if type(value)~='table' then return value end
    local result={} for k,v in pairs(value) do result[k]=deepCopy(v) end return result
end
-- Historical/frozen references are data snapshots, not outputs of old skill,
-- upgrade, inspiration, resourcefulness or guessed-range calculations.
local inputs=clone(references.inputs)
-- Latest owner clarification: usable conversion tables/calculators fill gaps
-- from every source, with provenance and uncertainty. They are one fallback
-- source inside ItemDB, not a second database or live TSM price feed.
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
db.buildReport.referenceCorrections={}
local calculators=assert(loadfile('database/reference-calculator-baselines.lua'))()
assert(calculators.schemaVersion==1,'Unsupported reference calculator schema')
local admitted={}
for _,original in ipairs(references.frozen.processing) do
    local r=deepCopy(original)
    r.recordID='reference:'..r.recordID;r.sourceKey='reference';r.fallbackOnly=true
    r.sourceKind='historical-conversion-table';r.sourceRevision=references.frozen.sourceRevision
    r.referenceApplicability='unverified-reference'
    r.baselineStatus='Historical Retail conversion reference; current skill/patch unverified'
    for _,m in ipairs(r.materials) do
        admitted[r.method..':'..r.inputItemID..':'..m.id]=true
        local e,p,lo,hi=m.expectedQuantity.value,m.dropChance.value,m.minQuantity.value,m.maxQuantity.value
        if e and p and lo and hi and (e+1e-9<p*lo or e>p*hi+1e-9) then
            -- Source fields disagree. Preserve every original number, and use
            -- the source's lowest positive conditional yield as an explicitly
            -- conservative provisional alternative, never as a measured mean.
            m.referenceOriginal={expectedQuantity=e,dropChance=p,minQuantity=lo,maxQuantity=hi}
            m.expectedQuantity.value=p*lo;m.expectedQuantity.status='modeled'
            m.expectedQuantity.confidence=math.floor(math.min(m.expectedQuantity.confidence,m.dropChance.confidence)*.5)
            m.expectedQuantity.assumption='Source mean contradicts probability/bounds; provisional probability times minimum yield'
            m.referenceCorrection=true
            db.buildReport.referenceCorrections[#db.buildReport.referenceCorrections+1]={
                recordID=r.recordID,outputItemID=m.id,originalExpectedQuantity=e,
                expectedQuantity=p*lo,reason=m.expectedQuantity.assumption}
        end
    end
    db.processing[#db.processing+1]=r
end
-- The old adapter omitted quality alternatives. Preserve one conservative
-- unknown-rank estimate per explicitly mapped family, never the sum of ranks.
-- A three-row milling pool with explicit targetQuality 1/2/3 is also a stated
-- quality-alternative contract; equal numbers alone never identify a family.
db.buildReport.referenceRankPools=0
for tableName,method in pairs({mill='Mill',prospect='Prospect'}) do
    for input,raw in pairs(references.frozen.rawTables[tableName]) do
        local hint=inputs[input]
        local unitOnly=hint==nil
        if unitOnly then
            -- The raw snapshot explicitly stores amountOfMats per input.
            -- It can be valued without inventing this item's recipe/batch.
            -- A discovered live recipe may later supply those requirements;
            -- this hint on its own is display-only.
            hint={method=method,batch=1,operationUnverified=true,quantityBasis='per-input'}
            inputs[input]={method=method,operationUnverified=true,quantityBasis='per-input'}
        end
        if hint and hint.method==method then
            local pools={}
            for _,family in ipairs(calculators.rankFamilies or {}) do
                if #family.ids>1 then
                    local members={}
                    for _,m in ipairs(raw) do
                        for _,id in ipairs(family.ids) do if m.id==id then members[#members+1]=m end end
                    end
                    if #members>1 then pools[#pools+1]={name=family.name,ids=family.ids,rows=members} end
                end
            end
            if method=='Mill' and #pools==0 and #raw==3 then
                local ranks,ids={},{}
                for _,m in ipairs(raw) do ranks[m.targetQuality or 0]=true;ids[#ids+1]=m.id end
                if ranks[1] and ranks[2] and ranks[3] then
                    table.sort(ids);pools[1]={name='Explicit milling quality alternatives',ids=ids,rows=raw}
                end
            end
            local materials={}
            if unitOnly then
                for _,m in ipairs(raw) do
                    if not m.targetQuality then
                        materials[#materials+1]={id=m.id,referenceVariants={deepCopy(m)},
                            expectedQuantity={value=m.amountOfMats,status='historical',confidence=20,
                                assumption='Source mean per input; actual processing recipe/batch not established'},
                            dropChance={status='unknown',confidence=0},minQuantity={status='unknown',confidence=0},maxQuantity={status='unknown',confidence=0}}
                    end
                end
            end
            for _,pool in ipairs(pools) do
                local present=false
                for _,id in ipairs(pool.ids) do if admitted[method..':'..input..':'..id] then present=true end end
                if not present then
                    local minimum
                    for _,m in ipairs(pool.rows) do
                        local mean=m.amountOfMats*hint.batch
                        minimum=minimum and math.min(minimum,mean) or mean
                    end
                    local function unknown()return {status='unknown',confidence=0}end
                    materials[#materials+1]={id=pool.ids[1],rankIDs=deepCopy(pool.ids),
                        referenceVariants=deepCopy(pool.rows),outputName=pool.name,
                        expectedQuantity={value=minimum,status='modeled',confidence=20,
                            assumption='Unknown rank distribution; minimum of source quality projections, not their sum'},
                        dropChance=unknown(),minQuantity=unknown(),maxQuantity=unknown()}
                end
            end
            if #materials>0 then
                table.sort(materials,function(a,b)return a.id<b.id end)
                db.processing[#db.processing+1]={recordID='reference:rank-pool:'..method..':'..input,
                    studyID='tsm:'..method..':'..input,sourceKey='reference',method=method,
                    profession=methods[method],inputItemID=input,inputCount=hint.batch,
                    source='Historical Retail TSM quality alternatives; conservative rank-unknown reference',
                    sourceRevision=references.frozen.sourceRevision,sourceKind='historical-rank-pool',
                    fixedReference=true,fallbackOnly=true,provisional=true,
                    operationUnverified=unitOnly or nil,quantityBasis=unitOnly and 'per-input' or nil,
                    referenceApplicability='unverified-reference',
                    baselineStatus='Unknown rank distribution; source quality alternatives are not additive',materials=materials}
                db.buildReport.referenceRankPools=db.buildReport.referenceRankPools+#materials
            end
        end
    end
end
for _,r in ipairs(calculators.processing) do db.processing[#db.processing+1]=r end
db.referenceManifest={historicalVersion=references.frozen.version,
    historicalSourceRevision=references.frozen.sourceRevision,calculatorSourceSHA256=calculators.sourceSHA256,
    calculatorHeld=calculators.held}
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
        -- These Midnight milling rows are explicitly unmeasured legacy
        -- estimates. Keep them as references rather than letting a guessed
        -- exact-rank quantity hide a sourced, whole-family calculator total.
        if r.method=='Mill' and (r.expansionID==nil or r.expansionID==11) and r.recordID:match('^midnight:mill:')
            and r.recordID:match(':legacy%-reference$') and r.expectedQuantity.sampleOperations==nil
            and r.expectedQuantity.status~='measured' and r.expectedQuantity.status~='verified' then
            n.sourceKey='reference';n.sourceKind='legacy-model'
            n.fallbackOnly=true;n.fixedReference=true
            n.sourceAssumption='Unmeasured legacy milling estimate; source rank/skill unverified'
            db.buildReport.legacyMillingReferences=(db.buildReport.legacyMillingReferences or 0)+1
        end
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
db.buildReport.mechanicRulesSkipped={}
-- C7b (owner decisions 1, 15, 16): a research mechanic is compiled at its stated
-- confidence when it names at least one source, like professionRules (C7). It is
-- marked APPROVED only when the research export itself carries a full review;
-- this builder never writes an approval of its own. A rule that is switched off
-- or has no usable source is skipped with a reason (buildReport) instead of
-- failing the build; a malformed formula or context still fails it.
local function mechanicEvidence(rule)
    local c=rule.confidence0to100
    if rule.applyPolicy=='DISABLED' or rule.applyPolicy=='NO_NUMERIC_TRANSFORM' then return nil,'switched off ('..tostring(rule.applyPolicy)..')' end
    if rule.evidenceStatus=='REJECTED' then return nil,'rejected by research' end
    if type(c)~='number' or c~=c or c<0 or c>100 then return nil,'invalid confidence' end
    if type(rule.sources)~='table' or #rule.sources<1 then return nil,'no source' end
    local seen={}
    for _,source in ipairs(rule.sources) do
        local id=type(source)=='table' and source.claimID
        if type(id)~='string' or id=='' then return nil,'source without claimID' end
        if seen[id] then return nil,'same source listed twice: '..id end
        seen[id]=true
    end
    local review=rule.independentReview
    return rule.applyPolicy=='VERIFIED_FOR_COMPILE' and rule.evidenceStatus=='VERIFIED_NUMERIC'
        and rule.numericTransformValidated==true and c>=90 and #rule.sources>=2
        and type(review)=='table' and review.reviewer
        and type(review.passedTestIDs)=='table' and #review.passedTestIDs>0
end
for _,rule in ipairs(research.mechanicRules or {}) do
    local label=tostring(rule.ruleID)
    assert(not approvedIDs[label],'Duplicate research mechanic '..label);approvedIDs[label]=true
    local reviewed,why=mechanicEvidence(rule)
    if reviewed==nil then
        local skipped=db.buildReport.mechanicRulesSkipped
        skipped[#skipped+1]={ruleID=label,reason=why}
        print('Mechanic rule skipped: '..label..': '..why)
    else
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
                evidenceStatus=reviewed and 'VERIFIED_NUMERIC' or tostring(rule.evidenceStatus or 'UNREVIEWED'),
                applyPolicy='EXECUTE',applies='VERIFIED_APPLIES',
                confidence0to100=rule.confidence0to100,numericTransformValidated=rule.numericTransformValidated==true,
                independentReview=reviewed and 'APPROVED' or 'NOT_REVIEWED',sourceClaimIDs={}}
            for _,source in ipairs(rule.sources) do translated.sourceClaimIDs[#translated.sourceClaimIDs+1]=assert(source.claimID) end
            db.mechanicRules[#db.mechanicRules+1]=translated;matched=matched+1
        end
    end
    assert(matched>0,'Research mechanic has no compatible baseline mapping: '..label)
    end
end
local models=assert(loadfile('database/profession-models.lua'))()
assert(models.schemaVersion==1,'Unsupported profession model schema')
db.professionRules=models.professionRules;db.personalPatchRules=models.personalPatchRules;db.modelRevision=models.revision
-- Sourced skill-to-quality models are generated independently of quantity
-- baselines. They require an exact-input operation context at runtime.
local skillQuality=assert(loadfile('database/skill-quality-rules.lua'))()
assert(skillQuality.schemaVersion==1 and type(skillQuality.skillQualityRules)=='table',
    'Unsupported generated skill-quality schema')
db.skillQualityRules=skillQuality.skillQualityRules
db.skillQualityRevision=skillQuality.revision..':'..skillQuality.sourceSHA256
db.skillQualitySources=skillQuality.sourceClaims
db.skillQualityHeld=skillQuality.held
db.skillQualityHeldNumericCandidates=skillQuality.heldNumericCandidates
local skillQualityFamilies=0
for _,rule in ipairs(db.skillQualityRules) do skillQualityFamilies=skillQualityFamilies+#rule.outputFamilies end
db.buildReport.skillQuality={rules=#db.skillQualityRules,families=skillQualityFamilies,
    held=#skillQuality.held,heldNumeric=#(skillQuality.heldNumericCandidates or {})}
-- Named specialization point sliders use sourced operation effects. Keep
-- these separate from empirical baselines and legacy aggregate assumptions.
local specialization=assert(loadfile('database/specialization-effects.lua'))()
assert(specialization.schemaVersion==1 and type(specialization.specializationRules)=='table',
    'Unsupported generated specialization-effect schema')
db.specializationRules=specialization.specializationRules
db.specializationRevision=specialization.revision..':'..specialization.sourceSHA256
db.specializationSources=specialization.sourceClaims
db.specializationHeld=specialization.held
db.buildReport.specializationEffects={rules=#specialization.specializationRules,held=#specialization.held}
-- Reviewed additions use the same versioned interface, independent of engine code.
local additions=assert(loadfile('database/records.lua'))()
-- C4b1 (owner, session 12): checked token lists come ONLY from the research
-- team's ItemDB export (research.tokenRewards in database/research/itemdb.lua,
-- a snapshot of research/proposed/itemdb.lua on their branch). This branch
-- never writes an approval itself, so records.lua must not carry tokens.
-- Format and checking steps: research/evidence/v3/TOKEN-CHECK.md.
assert(additions.tokenRewards==nil or next(additions.tokenRewards)==nil,
    'Token lists belong in the research export (database/research/itemdb.lua tokenRewards), not database/records.lua')
local tokenValidator={}
assert(loadfile('LootLiquidator/Database.lua'))('LootLiquidator',tokenValidator)
db.tokenRewards={}
db.buildReport.tokenRewardsSkipped={}
-- C4b3 (owner, session 15): "the rewards should be part of the compiler system for
-- updating the itemdb". Token lists built from the research team's v3 notes by
-- tools/research_v3_to_baselines.py (tokenRewards in database/research-v3-baselines.lua,
-- confidence shown, never marked APPROVED) follow any reviewed ones from the research
-- export, so a reviewed record for the same token wins and the v3 one is skipped.
local tokenCandidates={}
-- Owner's pass-2 clarification: ATT Retail data is an authorized research
-- source. Static costs are pinned/attributed; no installed-ATT dependency.
local att=assert(loadfile('database/att-token-baselines.lua'))()
assert(att.schemaVersion==1,'Unsupported pinned ATT reference schema')
db.attSourceManifest=att.sourceManifest
for _,r in ipairs(type(research.tokenRewards)=='table' and research.tokenRewards or {}) do tokenCandidates[#tokenCandidates+1]=r end
do
    local v3tokens=assert(loadfile(arg[3] or 'database/research-v3-baselines.lua'))().tokenRewards
    for _,r in ipairs(type(v3tokens)=='table' and v3tokens or {}) do
        assert(type(r)=='table' and tostring(r.recordID):match('^v3token:') and r.independentReview~='APPROVED',
            'Research v3 token lists must use v3token: IDs and are never pre-approved')
        for _,proof in ipairs(att.curioEvidence or {}) do
            if proof.tokenID==r.tokenID then
                r=deepCopy(r)
                r.sourceURLs[#r.sourceURLs+1]=proof.sourceURL
                r.sourceOrigin='ATT';r.licenseSPDX='MIT';r.licenseText=att.licenseText
                r.additionalSourceRevision=proof.sourceRevision
                if r.candidateRewards and contextIdentity(r.rewards)==contextIdentity(proof.rewards) then
                    r.candidateRewards=nil;r.confidence0to100=math.max(r.confidence0to100,60)
                    r.sourceAssumption='Reward membership corroborated by pinned ATT Retail tier data; complete exchange costs unverified'
                end
            end
        end
        tokenCandidates[#tokenCandidates+1]=r
    end
end
for _,r in ipairs(att.tokenRewards or {}) do tokenCandidates[#tokenCandidates+1]=r end
db.buildReport.tokenRewardsFromResearchV3=0
for index,r in ipairs(tokenCandidates) do
    -- Each record is checked alone, then against everything kept so far
    -- (duplicate IDs, overlapping patch windows). A bad record is skipped with
    -- its reason instead of failing the build; it stays in the research file.
    local ok,why=tokenValidator:ValidateTokenCatalog({r})
    if ok then
        local trial={}
        for i,kept in ipairs(db.tokenRewards) do trial[i]=kept end
        trial[#trial+1]=r
        ok,why=tokenValidator:ValidateTokenCatalog(trial)
    end
    if ok then
        db.tokenRewards[#db.tokenRewards+1]=r
        if tostring(r.recordID):match('^v3token:') then db.buildReport.tokenRewardsFromResearchV3=db.buildReport.tokenRewardsFromResearchV3+1 end
    else
        local skipped=db.buildReport.tokenRewardsSkipped
        skipped[#skipped+1]={index=index,recordID=type(r)=='table' and tostring(r.recordID) or '?',reason=tostring(why)}
        print('Token record skipped: #'..index..' '..skipped[#skipped].recordID..': '..tostring(why))
    end
end
table.sort(db.tokenRewards,function(a,b) return a.recordID<b.recordID end)
for _,r in ipairs(additions.processing or {}) do db.processing[#db.processing+1]=r end
-- Direct captured output identities survive study-level denominator gaps.
-- This adapter carries no numerical rates, bounds, confidence or mechanics.
local captures=assert(loadfile('database/capture-observations.lua'))()
local recycling=assert(loadfile('database/recycling-capture-baselines.lua'))()
assert(recycling.schemaVersion==1,'Unsupported reviewed Recycling captures')
db.captureCoverageReviews=recycling.coverageReviews
for _,r in ipairs(recycling.processing) do db.processing[#db.processing+1]=r end
assert(captures.schemaVersion==1 and type(captures.processing)=='table','Unsupported capture observations')
for _,r in ipairs(captures.processing) do
    assert(r.observationOnly==true and r.sourceKey=='itemdb' and r.sourceKind=='direct-player-cast-observation')
    for _,m in ipairs(r.materials) do
        for _,key in ipairs({'expectedQuantity','dropChance','minQuantity','maxQuantity'}) do
            assert(m[key].value==nil and m[key].status=='unknown','Capture identity must not imply a yield rate')
        end
    end
    db.processing[#db.processing+1]=r
end
for _,r in ipairs(additions.mechanicRules or {}) do
    assert(r.applyPolicy=='EXECUTE' and type(r.sourceClaimIDs)=='table' and #r.sourceClaimIDs>0,
        'Mechanics need applyPolicy EXECUTE and at least one source')
    db.mechanicRules[#db.mechanicRules+1]=r
end
-- D1b step 2: baseline counts generated from research/evidence/v3 by
-- tools/evidence_to_baselines.py. Ordinary "itemdb" records whose fields carry
-- weighted cast counts, so the addon's counting math sets their confidence.
-- arg[2] lets tests compile a fixture file instead.
-- D1c: the research team's v3 results (tools/research_v3_to_baselines.py, real
-- studies only) arrive the same way. v3 already contains the studies behind the
-- older "research:" rows (it imported them), so a v3 record with
-- supersedesResearch replaces those rows for the same method, input and
-- material instead of counting the same studies twice. A row whose material v3
-- does not carry (e.g. an unlock-only gem) is kept. The replaced rows stay in
-- database/research/itemdb.lua and are listed in buildReport.researchSuperseded.
-- arg[3] lets tests compile a fixture file instead.
local v3=assert(loadfile(arg[3] or 'database/research-v3-baselines.lua'))()
assert(v3.schemaVersion==1 and type(v3.processing)=='table','Unsupported research v3 baseline schema')
db.researchV3Manifest={revision=v3.sourceRevision,branch=v3.sourceBranch}
local superseding={}
for _,r in ipairs(v3.processing) do
    assert(r.recordID:match('^evidence:v3:'),'Research v3 baselines must use evidence:v3: record IDs')
    if r.supersedesResearch then
        for _,m in ipairs(r.materials) do
            superseding[r.method..':'..tostring(r.inputItemID or r.gearKey)..':'..m.id]=r.recordID
        end
    end
end
local function supersededBy(r)
    if not r.recordID:match('^research:') then return nil end
    local by
    for _,m in ipairs(r.materials) do
        local found=superseding[r.method..':'..tostring(r.inputItemID or r.gearKey)..':'..m.id]
        if not found then return nil end -- keep any row carrying a material v3 lacks
        by=found
    end
    return by
end
db.buildReport.researchSuperseded={}
local kept={}
for _,r in ipairs(db.processing) do
    local by=supersededBy(r)
    if by then
        db.buildReport.researchSuperseded[#db.buildReport.researchSuperseded+1]=r.recordID..' -> '..by
    else
        kept[#kept+1]=r
    end
end
db.processing=kept
table.sort(db.buildReport.researchSuperseded)
local baselines=assert(loadfile(arg[2] or 'database/evidence-baselines.lua'))()
assert(baselines.schemaVersion==1 and type(baselines.processing)=='table','Unsupported evidence baseline schema')
for _,file in ipairs({baselines,v3}) do
    for _,r in ipairs(file.processing) do
        assert(r.sourceKey=='itemdb' and r.recordID:match('^evidence:'),'Evidence baselines must be itemdb evidence records')
        db.processing[#db.processing+1]=r
        if r.inputItemID then
            if not inputs[r.inputItemID] or (inputs[r.inputItemID].operationUnverified and r.sourceKey=='itemdb') then
                inputs[r.inputItemID]={method=r.method,batch=r.inputCount,expansion=r.expansionID}
            end
        end
    end
end
-- Reviewed item observations also inform their expansion + rarity + item-type
-- category. The scope adapter reuses the native evidence counting compiler;
-- exact records remain provenance, and runtime chooses one applicable context.
-- Existing evidence/v3 fixture compiles stay isolated unless arg[4] supplies a
-- category fixture explicitly.
local categories={schemaVersion=1,processing={}}
if arg[4] or (not arg[2] and not arg[3]) then
    categories=assert(loadfile(arg[4] or 'database/disenchant-category-baselines.lua'))()
end
assert(categories.schemaVersion==1 and type(categories.processing)=='table','Unsupported disenchant category baseline schema')
db.buildReport.disenchantCategoryRecords=#categories.processing
for _,r in ipairs(categories.processing) do
    assert(r.sourceKey=='itemdb' and r.isDisenchantCategory and r.recordID:match('^evidence:category:'),
        'Disenchant category baselines must be scoped itemdb evidence records')
    db.processing[#db.processing+1]=r
end
if #db.buildReport.researchSuperseded>0 then
    print(('Research v3 replaced %d older research row(s) for the same input'):format(#db.buildReport.researchSuperseded))
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
    assert(LL:IsUsableProfessionRule(rule),'Mechanic failed shared evidence gate (source, confidence): '..tostring(rule.ruleID))
end
local validModels,modelError=LL:ValidateProfessionRules(db)
assert(validModels,modelError)
assert(loadfile('LootLiquidator/Database.lua'))('LootLiquidator',LL)
assert(not LL.itemDBError,LL.itemDBError)
local legacy={schemaVersion=1,version='legacy-v0.9.70/1',processing={}}
local primary={}
for _,r in ipairs(db.processing) do
    assert(r.sourceKey~='itemtsm','Historical conversion data uses the unified reference source')
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
-- D1c4: items the research team's v3 notes say can't be disenchanted
-- (tools/research_v3_no_disenchant.py). Only ADDED, as researchNoDisenchant, for
-- items the game-file list lacks; a game-file entry is never removed or changed.
local gameNoDE={} for _,id in ipairs(restrictions.noDisenchant) do gameNoDE[id]=true end
restrictions.researchNoDisenchant={}
local researchNoDESeen={}
for _,r in ipairs(type(v3.noDisenchant)=='table' and v3.noDisenchant or {}) do
    local id=r.itemID
    assert(type(id)=='number' and id>0 and id%1==0,'research no-disenchant record needs an item ID')
    local sourced=false
    for _,url in ipairs(r.sourceURLs or {}) do if type(url)=='string' and url:match('^https://%S+$') then sourced=true end end
    assert(sourced,'research no-disenchant record '..id..' needs an https source')
    if not gameNoDE[id] and not researchNoDESeen[id] then
        researchNoDESeen[id]=true
        restrictions.researchNoDisenchant[#restrictions.researchNoDisenchant+1]=id
    end
end
table.sort(restrictions.researchNoDisenchant)
if #restrictions.researchNoDisenchant>0 then
    print(('Research v3 added %d no-disenchant item(s) the game-file list lacks'):format(#restrictions.researchNoDisenchant))
end
local file=assert(io.open(output,'w'))
file:write('-- Generated by tools/compile_itemdb.lua. Unknown fields are absent, not zero.\nlocal _, LL = ...\nLL.ItemDB=',(encode(db):gsub('},%[','},\n[')),'\n')
file:write('-- Old disenchant estimates (weak "legacy" source).\nLL.ItemDB.legacy=',encode(legacy),'\n')
file:write('-- DB2 no-disenchant item IDs (+ research v3 additions) and mill/prospect input hints (build ',tostring(restrictions.build),').\nLL.ItemDB.restrictions=',encode(restrictions),'\n')
file:close()
print('Compiled '..total..' source records (provisional and documented recipes) to '..output)

