-- Deterministic build-time migration. Run from repository root with Lua 5.1.
-- Source snapshots are NOT runtime modules and are never fetched at runtime.
local LL={}
for _,file in ipairs({'ResearchDB.lua','GameData.lua','StatYieldProfiles.lua'}) do
    assert(loadfile('database/sources/'..file))('LootLiquidator',LL)
end
local gd=LL.GameData
local db={schemaVersion=1,version='1.1.1',processing={},mechanicRules={},
    provenance='main 051f582 / v0.9.70; schema-validated provisional migration',
    compat={Conversions=LL.Conversions,DisenchantTables=LL.DisenchantTables,
        ResearchTokenCandidates=LL.ResearchTokenCandidates,ResearchProcessingInputs=LL.ResearchProcessingInputs}}
local methods={Mill='Inscription',Prospect='Jewelcrafting',Disenchant='Enchanting',Smelt='Mining'}
local function clone(t) local n={} for k,v in pairs(t or {}) do n[k]=v end return n end
local function field(value,confidence,status)
    return {value=value,confidence=confidence or 0,status=status or 'unknown'}
end
local function add(method,input,batch,materials,meta,sourceKey,study)
    meta=meta or {}
    local r={recordID=method..':'..input..':'..sourceKey,method=method,profession=methods[method],
        inputItemID=input,inputCount=batch,sourceKey=sourceKey,studyID=study,
        expansionID=meta.expansion or meta.expansionID,inputQualityRank=meta.inputRank,
        recipeID=meta.recipeID,patchBuild=meta.patchBuild,referenceContextID=meta.referenceContextID,
        referenceConditions=meta.referenceConditions or {},samples=meta.samples,
        source=meta.source or meta.evidence or 'v0.9.70 snapshot',provisional=true,
        fieldConfidence=meta.confidenceCap or 35,materials={}}
    for _,m in ipairs(materials or {}) do
        if type(m.id)=='number' and m.id>0 then
            local e=m.expectedQuantity
            local measured=m.probabilityVerified==true
            local bounds=m.boundsVerified==true
            r.materials[#r.materials+1]={id=m.id,quality=m.targetQuality,rarity=m.rarity,
                expectedQuantity=field(e,r.fieldConfidence,e~=nil and 'provisional' or 'unknown'),
                dropChance=field(measured and m.chance or nil,measured and r.fieldConfidence or 0,measured and 'verified' or 'unknown'),
                minQuantity=field(bounds and m.minQuantity or nil,bounds and r.fieldConfidence or 0,bounds and 'verified' or 'unknown'),
                maxQuantity=field(bounds and m.maxQuantity or nil,bounds and r.fieldConfidence or 0,bounds and 'verified' or 'unknown')}
        end
    end
    if sourceKey=='itemtsm' then
        for i,m in ipairs(materials or {}) do
            local target=r.materials[i]
            if target then
                target.originalTSM=m.originalTSM
                target.dropChance=field(m.chance,40,m.chance~=nil and 'historical' or 'unknown')
                target.minQuantity=field(m.minQuantity,40,m.minQuantity~=nil and 'historical' or 'unknown')
                target.maxQuantity=field(m.maxQuantity,40,m.maxQuantity~=nil and 'historical' or 'unknown')
                local p,e,lo,hi=m.chance,m.expectedQuantity,m.minQuantity,m.maxQuantity
                target.sourceConflict=p and e and lo and hi and (e+1e-9<p*lo or e>p*hi+1e-9) or nil
            end
        end
    end
    if #r.materials>0 then db.processing[#db.processing+1]=r end
end
local inputs={}
for method,dict in pairs({Mill=gd.mill,Prospect=gd.prospect}) do
    for input,row in pairs(dict) do
        local metadata=LL.ResearchProcessingInputs[input]
        inputs[input]={method=method,batch=row.batch or (metadata and metadata.batch) or 5,
            expansion=metadata and metadata.expansion,evidence=row.evidence}
        local meta=clone(row);meta.expansion=metadata and metadata.expansion
        -- Remove duplicated historical TSM copies from the primary source.
        if not (method=='Prospect' and gd.midnightProspectingProfiles[input])
            and not tostring(row.source):lower():find('tsm',1,true)
            and not tostring(row.source):lower():find('tradeskillmaster',1,true)
            and not tostring(row.evidence):lower():find('tsm',1,true) then
            add(method,input,inputs[input].batch,row.materials,meta,'itemdb','compiled:'..method..':'..input)
        end
    end
end
for _,id in ipairs({210808,210809,210810,36721,87821}) do inputs[id]=nil end
for input,p in pairs(gd.midnightProspectingProfiles or {}) do
    local mats={}
    for _,m in ipairs(p.materials) do
        -- A missing diamond unlock formula is not proof of zero output.
        mats[#mats+1]={id=m.id,expectedQuantity=m.category~='diamond' and m.low or nil}
    end
    local meta=clone(p);meta.expansion=11
    add('Prospect',input,5,mats,meta,'itemdb','midnight-low:'..input)
end
for method,profiles in pairs(gd.statYieldProfiles or {}) do
    for input,p in pairs(profiles) do
        local mats={}
        for _,m in ipairs(p.rows) do mats[#mats+1]={id=m.id,expectedQuantity=m.low} end
        -- Historical/scenario rows remain opt-in legacy evidence.
        local historical=(tostring(p.source)..' '..tostring(p.evidence)):lower():find('tsm',1,true)
        add(method,input,p.batch,mats,p,'legacy',(historical and 'tsm:' or 'profile:')..method..':'..input)
    end
end
for method,dict in pairs({Mill=gd.tsmRetail.mill,Prospect=gd.tsmRetail.prospect}) do
    for input,mats in pairs(dict) do
        if inputs[input] then
            local rows={}
            for _,m in ipairs(mats) do
                -- Unknown reagent/output rank is never summed across rank variants.
                if (not m.sourceQuality or m.sourceQuality==1) and (not m.targetQuality or m.targetQuality==1) then
                    rows[#rows+1]={id=m.id,expectedQuantity=m.amountOfMats and m.amountOfMats*inputs[input].batch,
                        targetQuality=m.targetQuality,chance=m.matRate,minQuantity=m.minAmount,maxQuantity=m.maxAmount,originalTSM=clone(m)}
                end
            end
            add(method,input,inputs[input].batch,rows,{source='TradeSkillMaster historical conversion data',
                expansion=inputs[input].expansion,confidenceCap=40,inputRank=mats[1] and mats[1].sourceQuality},
                'itemtsm','tsm:'..method..':'..input)
            db.processing[#db.processing].fixedReference=true
        end
    end
end
for exp,tiers in pairs(gd.disenchant) do
    for quality,kinds in pairs(tiers) do
        for kind,row in pairs(kinds) do
            if type(row)=='table' and row.outputs then
                local key='gear:'..exp..':'..quality..':'..kind
                local before=#db.processing
                add('Disenchant',key,1,row.outputs,{expansion=exp,samples=row.samples,
                    source=row.evidence,confidenceCap=45},'itemdb',key)
                if #db.processing>before then
                    local r=db.processing[#db.processing];r.inputItemID=nil;r.gearKey=key
                end
            end
        end
    end
end
-- Deterministic recipes are primary records too; no runtime copy of yields.
for input,list in pairs(LL.Conversions or {}) do
    for _,recipe in ipairs(list) do
        if recipe.method=='Smelt' and recipe.outputID and recipe.outputCount and recipe.inputCount then
            local id=recipe.recipeID or recipe.requiredSpell
            if id then
                local before=#db.processing
                add('Smelt',input,recipe.inputCount,{{id=recipe.outputID,expectedQuantity=recipe.outputCount,
                    chance=1,minQuantity=recipe.outputCount,maxQuantity=recipe.outputCount,probabilityVerified=true,boundsVerified=true}},
                    {source=recipe.source or recipe.requirement or 'Documented recipe',recipeID=id,confidenceCap=100},
                    'itemdb','recipe:'..id)
                if #db.processing>before then
                    local r=db.processing[#db.processing]
                    r.recordID=r.recordID..':'..id;r.provisional=false
                    for _,m in ipairs(r.materials) do for _,field in pairs(m) do
                        if type(field)=='table' and field.status then field.status='verified' end
                    end end
                end
            end
        end
    end
end
-- Preserve old numeric references as fixed legacy fallback records.
for _,r in ipairs(db.processing) do
    if r.sourceKey=='itemdb' then r.sourceKey='legacy';r.recordID=r.recordID..':fallback' end
    if r.sourceKey=='legacy' then r.fixedReference=true end
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
for _,r in ipairs(research.processing) do
    validatePreview(r) -- retained only under researchRecord; NEVER an economic fallback
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
db.compat.GameData={tokens=gd.tokens,recipeRequirements=gd.recipeRequirements}
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
local validModels,modelError=LL:ValidateProfessionRules(db)
assert(validModels,modelError)
assert(loadfile('LootLiquidator/Database.lua'))('LootLiquidator',LL)
assert(not LL.itemDBError,LL.itemDBError)
local frozen={schemaVersion=1,version='tsm-v0.9.70-frozen/1',sourceRevision='1d47c4a961c5dc5af626e659f7d96d1490d3cf9e',
    source='Pinned main/GameData.lua TSM conversion tables; not live TSM prices',
    originalUnitBasis='amountOfMats per input; matRate and positive bounds per operation',
    rawTables=gd.tsmRetail,processing={}}
local legacy={schemaVersion=1,version='legacy-v0.9.70/1',processing={}}
local primary={}
for _,r in ipairs(db.processing) do
    if r.sourceKey=='itemtsm' then frozen.processing[#frozen.processing+1]=r
    elseif r.sourceKey=='legacy' then legacy.processing[#legacy.processing+1]=r
    else primary[#primary+1]=r end
end
local total=#db.processing
db.processing=primary
local output=arg[1] or 'LootLiquidator/ItemDBRuntime.lua'
-- Test builds can write all artifacts to a temporary directory.
local outdir=output:match('^(.*)/[^/]+$') or '.'
local function writeSource(name,key,data)
    local f=assert(io.open(outdir..'/'..name,'w'))
    f:write('-- Generated immutable reference; rebuild intentionally to update.\nlocal _, LL = ...\nLL.',key,'=',encode(data),'\n')
    f:close()
end
writeSource('itemTSM.lua','FrozenTSM',frozen)
writeSource('GameData.lua','LegacyDB',legacy)
local file=assert(io.open(output,'w'))
file:write('-- Generated by tools/compile_itemdb.lua. Unknown fields are absent, not zero.\nlocal _, LL = ...\nLL.ItemDB=',(encode(db):gsub('},%[','},\n[')),'\n')
file:close()
print('Compiled '..total..' source records (provisional and documented recipes) to '..output)

