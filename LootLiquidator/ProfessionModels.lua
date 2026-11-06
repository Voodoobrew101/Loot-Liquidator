-- Shared build/runtime arithmetic. Historical ItemDB replay belongs to the
-- builder; only personal observations need patch bridges in the client.
local _, LL = ...
local function copy(t)
    if type(t)~='table' then return t end
    local n={} for k,v in pairs(t) do n[k]=copy(v) end return n
end
local function finite(n) return type(n)=='number' and n==n and n>=0 and n<math.huge end
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
-- One evidence gate for all executable profession and personal patch rules.
local function approved(r)
    if type(r)~='table' or r.evidenceStatus~='VERIFIED_NUMERIC' or r.applyPolicy~='EXECUTE'
        or r.numericTransformValidated~=true or r.independentReview~='APPROVED'
        or not finite(r.confidence0to100) or r.confidence0to100<90 or r.confidence0to100>100
        or type(r.sourceClaimIDs)~='table' or #r.sourceClaimIDs<2 then return false end
    local seen={}
    for _,id in ipairs(r.sourceClaimIDs) do
        if type(id)~='string' or id=='' or seen[id] then return false end
        seen[id]=true
    end
    return true
end
function LL:IsApprovedNumericRule(rule) return approved(rule) end
-- C7 (owner decisions 1, 15, 16): a research scaling rule runs at any stated
-- confidence as long as it names at least one source; the numbers it scales
-- carry that confidence as a cap (transformConfidence). Only a rule with no
-- source, an invalid confidence, or one switched off is left out.
local function usable(r)
    if type(r)~='table' or r.applyPolicy=='DISABLED' or r.applyPolicy=='NO_NUMERIC_TRANSFORM' or r.evidenceStatus=='REJECTED'
        or not finite(r.confidence0to100) or r.confidence0to100>100
        or type(r.sourceClaimIDs)~='table' or #r.sourceClaimIDs<1 then return false end
    local seen={}
    for _,id in ipairs(r.sourceClaimIDs) do
        if type(id)~='string' or id=='' or seen[id] then return false end
        seen[id]=true
    end
    return true
end
function LL:IsUsableProfessionRule(rule) return usable(rule) end
local function matches(r,f,option,id)
    return r.method==option.name and r.recipeID==option.recipeID and r.inputItemID==f.id
        and r.outputItemID==id and r.expansionID==f.expansionID
        and (r.inputQualityRank==nil or r.inputQualityRank==f.reagentQuality)
end
function LL:ValidateProfessionRules(db)
    local ids={}
    local function identity(r)
        if not usable(r) or type(r.ruleID)~='string' or r.ruleID=='' or ids[r.ruleID]
            or type(r.method)~='string' or not finite(r.recipeID) or r.recipeID<1
            or not finite(r.inputItemID) or r.inputItemID<1
            or not finite(r.outputItemID) or r.outputItemID<1 or not finite(r.expansionID) then return false end
        ids[r.ruleID]=true;return true
    end
    for _,r in ipairs(db.professionRules or {}) do
        if not identity(r) or r.build==nil or type(r.referenceProfile)~='table'
            or type(r.skillFactors)~='table' or #r.skillFactors==0 then return false,'Invalid profession rule' end
        local previous
        for _,p in ipairs(r.skillFactors) do
            if type(p)~='table' or not finite(p.skill) or not finite(p.factor) or p.factor<=0
                or (previous and p.skill<=previous) then return false,'Invalid profession factors' end
            previous=p.skill
        end
    end
    for _,r in ipairs(db.personalPatchRules or {}) do
        if not identity(r) or r.fromBuild==nil or r.toBuild==nil or tostring(r.fromBuild)==tostring(r.toBuild)
            or not finite(r.expectedMultiplier) or r.expectedMultiplier<=0
            or (r.basis~='baseline' and type(r.profile)~='table') then return false,'Invalid personal patch rule' end
    end
    return true
end
-- Explicit piecewise factors supplied by research; no universal skill curve.
-- The same function evaluates source and target, so inverse/forward agree.
function LL:ProfessionFactor(rule,context)
    if type(rule)~='table' or type(context)~='table' then return nil,'Missing profile' end
    local skill=context.effectiveSkill or context.skill
    if not finite(skill) then return nil,'Unknown skill' end
    local points=rule.skillFactors
    if type(points)~='table' or #points<1 then return nil,'No numeric profession rule' end
    local factor
    for i,p in ipairs(points) do
        if not finite(p.skill) or not finite(p.factor) or p.factor<=0
            or (i>1 and p.skill<=points[i-1].skill) then return nil,'Invalid skill factors' end
    end
    if skill<points[1].skill or skill>points[#points].skill then return nil,'Skill outside model' end
    for i,p in ipairs(points) do
        if skill==p.skill then factor=p.factor;break end
        local q=points[i+1]
        if q and skill>p.skill and skill<q.skill then
            factor=p.factor+(q.factor-p.factor)*(skill-p.skill)/(q.skill-p.skill);break
        end
    end
    for _,entry in ipairs({{'specialization',rule.specializationFactors},{'equipmentKey',rule.equipmentFactors}}) do
        local field,values=entry[1],entry[2]
        if values then
            local v=values[context[field]]
            if not finite(v) or v<=0 then return nil,'Unknown '..field..' factor' end
            factor=factor*v
        elseif context[field]~=nil and not equal(context[field],rule.referenceProfile and rule.referenceProfile[field]) then
            return nil,'Unmodeled '..field
        end
    end
    -- Other stats are usable only at the explicitly modeled reference value.
    if not equal(context.operationStats,rule.referenceProfile and rule.referenceProfile.operationStats)
        or not equal(context.equipment,rule.referenceProfile and rule.referenceProfile.equipment)
        or not equal(context.buffs,rule.referenceProfile and rule.referenceProfile.buffs) then
        return nil,'Unmodeled gear, buffs or operation stats'
    end
    return finite(factor) and factor>0 and factor or nil
end
local function ruleFor(self,f,option,id,build)
    local found
    for _,r in ipairs(self.ItemDB and self.ItemDB.professionRules or {}) do
        if usable(r) and matches(r,f,option,id) and tostring(r.build)==tostring(build) then
            if found then return nil end
            found=r
        end
    end
    return found
end
local function scale(m,factor,ruleID,confidence)
    if finite(confidence) then
        m.transformConfidence=math.min(m.transformConfidence or 100,confidence)
    end
    if m.expectedQuantity~=nil then
        if not finite(m.expectedQuantity) or not finite(m.expectedQuantity*factor) then return false end
        m.expectedQuantity=m.expectedQuantity*factor
        if factor~=1 then
            -- E does not determine probability or conditional ranges.
            m.chance=nil;m.minQuantity=nil;m.maxQuantity=nil;m.probabilityVerified=false
        end
    end
    m.appliedProfessionRule=ruleID
    return true
end
function LL:ApplyProfessionModel(f,option,baseline,target)
    if not baseline or (baseline.sourceKey~='itemdb' and baseline.sourceKey~='personal') then return baseline end
    if baseline.professionProjected then return baseline end
    local result=copy(baseline)
    result.adjustment='unadjusted — no numeric profession rule'
    if not baseline.baselineProfile or not baseline.patchBuild then return result end
    local currentBuild=GetBuildInfo and select(2,GetBuildInfo())
    if currentBuild and tostring(currentBuild)~=tostring(baseline.patchBuild) then
        result.adjustment='baseline needs a research update for this game build';return result
    end
    target=target or self:ProcessingPlayerConditions(f,option.name,option.recipeID,option.character)
    local applied,complete=false,true
    for _,m in ipairs(result.materials) do
        local rule=ruleFor(self,f,option,m.id,baseline.patchBuild)
        if rule then
            local sourceFactor=self:ProfessionFactor(rule,baseline.baselineProfile)
            local targetFactor=self:ProfessionFactor(rule,target)
            if sourceFactor and targetFactor and scale(m,targetFactor/sourceFactor,rule.ruleID,rule.confidence0to100) then
                applied=true
                result.ruleConfidence=math.min(result.ruleConfidence or 100,rule.confidence0to100)
                if not approved(rule) then result.unreviewedRule=true end
            else complete=false end
        elseif m.expectedQuantity~=nil then complete=false end
    end
    if applied and not complete then
        result=copy(baseline);result.projectionIncomplete=true
        result.adjustment="incomplete profession rules; character valuation unavailable"
        return result
    end
    if applied then
        result.professionProjected=true;result.mechanicsApplied=true
        result.adjustment='profession model / '..(target.simulated and 'SIMULATED' or 'selected profile')
            ..(result.unreviewedRule and ' / research rule, not yet reviewed' or '')
        result.projectedContext=copy(target)
    end
    return result
end
-- Derive afresh from raw samples. Never persist a rewritten empirical mean.
-- Explicit patch edges also represent reviewed "no change" (factor=1).
function LL:ProjectPersonalEstimate(f,option,raw,target,targetBuild)
    if not raw or not raw.observationContext then return nil,'Missing recorded profile' end
    raw=raw.rawEstimate or raw
    if not raw.patchBuild or type(target)~='table' then return nil,'Missing sample build or target profile' end
    targetBuild=tostring(targetBuild or (GetBuildInfo and select(2,GetBuildInfo())))
    local sourceBuild=tostring(raw.patchBuild)
    local source=raw.observationContext
    local profileFields={'effectiveSkill','specialization','operationStats','equipment','equipmentKey','craftingQuality','buffs'}
    local sameProfile=true
    for _,k in ipairs(profileFields) do if not equal(source[k],target[k]) then sameProfile=false end end
    if sourceBuild==targetBuild and sameProfile then return copy(raw) end
    local result=copy(raw);result.materials={};result.rawEstimate=copy(raw)
    result.patchBuild=targetBuild;result.projectionRules={};result.provisional=true
    for _,original in ipairs(raw.materials or {}) do
        local m=copy(original)
        local normalized=not sameProfile
        local historicalFactor=1
        local ruleConfidence
        local function used(r)
            ruleConfidence=math.min(ruleConfidence or 100,r.confidence0to100)
            if not approved(r) then result.unreviewedRule=true end
        end
        if normalized then
            local rule=ruleFor(self,f,option,m.id,sourceBuild)
            if not rule then return nil,'No source-profile conversion rule' end
            local sf=self:ProfessionFactor(rule,source)
            local bf=self:ProfessionFactor(rule,rule.referenceProfile)
            if not sf or not bf then return nil,'Unknown source-profile factor' end
            historicalFactor=bf/sf;used(rule)
            result.projectionRules[#result.projectionRules+1]=rule.ruleID..':inverse'
        end
        local current=sourceBuild
        local visited={}
        while current~=targetBuild do
            if visited[current] then return nil,'Patch rule cycle' end
            visited[current]=true
            local found
            for _,r in ipairs(self.ItemDB and self.ItemDB.personalPatchRules or {}) do
                if usable(r) and matches(r,f,option,m.id) and tostring(r.fromBuild)==current then
                    if found then return nil,'Ambiguous patch bridge' end
                    found=r
                end
            end
            if not found or not finite(found.expectedMultiplier) or found.expectedMultiplier<=0 then
                return nil,'Pre-patch samples — adjustment unknown'
            end
            -- Profile-specific bridges must explicitly match the observed profile;
            -- baseline bridges require inverse normalization first.
            if found.basis=='baseline' and not normalized then
                local rule=ruleFor(self,f,option,m.id,sourceBuild)
                local sf=rule and self:ProfessionFactor(rule,source)
                local bf=rule and self:ProfessionFactor(rule,rule.referenceProfile)
                if not sf or not bf then return nil,'Missing baseline patch normalization' end
                historicalFactor=historicalFactor*bf/sf;normalized=true;used(rule)
                result.projectionRules[#result.projectionRules+1]=rule.ruleID..':inverse'
            elseif found.basis~='baseline' and not equal(found.profile,source) then
                return nil,'Patch bridge profile mismatch'
            end
            historicalFactor=historicalFactor*found.expectedMultiplier;used(found)
            result.projectionRules[#result.projectionRules+1]=found.ruleID
            current=tostring(found.toBuild)
        end
        if normalized then
            local rule=ruleFor(self,f,option,m.id,targetBuild)
            local tf=rule and self:ProfessionFactor(rule,target)
            local bf=rule and self:ProfessionFactor(rule,rule.referenceProfile)
            if not tf or not bf then return nil,'No target-profile conversion rule' end
            historicalFactor=historicalFactor*tf/bf;used(rule)
            result.projectionRules[#result.projectionRules+1]=rule.ruleID..':forward'
        end
        if not scale(m,historicalFactor,table.concat(result.projectionRules,', '),ruleConfidence) then return nil,'Invalid projection' end
        -- Histograms and sample extrema remain properties of the raw source.
        m.quantityCounts=nil;m.fieldEvidence=nil;m.boundsBasis=nil
        result.materials[#result.materials+1]=m
    end
    result.observationContext=copy(target);result.mechanicsApplied=true
    result.adjustment='derived personal estimate / versioned patch and profession model'
    result.professionProjected=true
    result.projectionRevision=self.ItemDB and self.ItemDB.modelRevision
    return result
end

-- Research-backed quality selection is a separate dimension from quantity.
-- Only an aggregate of explicitly identified quality siblings may be assigned
-- to a rank. Exact-rank studies and missing/conditional means stay untouched.
function LL:ApplySkillQualityModel(f,option,model,context)
    if type(model)~='table' or model.skillQualityApplied or type(f)~='table'
        or type(option)~='table' or type(context)~='table' or context.stale then return model end
    local operation=context.skillQualityOperation
    local build=GetBuildInfo and select(2,GetBuildInfo())
    if type(operation)~='table' or operation.allocationVerified~=true or operation.concentration~=false
        or operation.maxQuality~=2 or type(context.character)~='string' or operation.character~=context.character
        or not build or tostring(operation.build)~=tostring(build)
        or operation.recipeID~=option.recipeID or operation.inputItemID~=f.id
        or operation.expansionID~=f.expansionID or operation.inputQualityRank~=f.reagentQuality
        or not finite(operation.observed) then return model end
    local now=time and time()
    if now and (operation.observed>now or now-operation.observed>7*86400) then return model end
    local quality
    if context.simulated then
        if context.profileKind~='manual-simulation' or not finite(context.effectiveSkill)
            or not finite(operation.highQualitySkillThreshold) or operation.highQualitySkillThreshold<=0 then return model end
        quality=context.effectiveSkill>=operation.highQualitySkillThreshold and 2 or 1
    elseif operation.craftingQuality==1 or operation.craftingQuality==2 then
        quality=operation.craftingQuality
    end
    if not quality then return model end
    local rule
    for _,candidate in ipairs(self.ItemDB and self.ItemDB.skillQualityRules or {}) do
        if usable(candidate) and candidate.applyPolicy=='EXECUTE'
            and candidate.formulaID=='EXACT_INPUT_QUALITY_THRESHOLD' and candidate.maxQuality==2
            and candidate.requireExactOperationContext==true
            and candidate.quantityPolicy=='PRESERVE_SELECTED_FAMILY_EXPECTATION'
            and candidate.method==option.name and candidate.recipeID==option.recipeID
            and candidate.expansionID==f.expansionID then
            local rankOK=false
            for _,rank in ipairs(candidate.inputQualityRanks or {}) do if rank==f.reagentQuality then rankOK=true end end
            local itemOK=candidate.inputItemIDs==nil
            for _,id in ipairs(candidate.inputItemIDs or {}) do if id==f.id then itemOK=true end end
            if rankOK and itemOK then
                if rule then return model end -- Ambiguous exports cannot pick a rule by file order.
                rule=candidate
            end
        end
    end
    if not rule then return model end
    local result=copy(model)
    local changed=false
    for index,material in ipairs(result.materials or {}) do
        local ids=material.rankIDs
        if type(ids)=='table' and #ids==2 and finite(material.expectedQuantity)
            and material.conditionalExpectedQuantity==nil and material.conditionalRequirement==nil then
            local family
            for _,candidate in ipairs(rule.outputFamilies or {}) do
                local ranks=candidate.rankItemIDs
                if type(ranks)=='table' and #ranks==2 and ranks[1]~=ranks[2]
                    and ((ids[1]==ranks[1] and ids[2]==ranks[2]) or (ids[1]==ranks[2] and ids[2]==ranks[1])) then
                    if family then return model end
                    family=candidate
                end
            end
            if family then
                local overlap=false
                for otherIndex,other in ipairs(model.materials or {}) do
                    if otherIndex~=index and (other.id==ids[1] or other.id==ids[2]) then overlap=true end
                end
                if not overlap then
                    material.sourceRankIDs=copy(ids);material.rankIDs=nil
                    material.id=family.rankItemIDs[quality];material.projectedQualityRank=quality
                    material.appliedSkillQualityRule=rule.ruleID
                    material.baselineConfidence=material.confidence
                    material.confidence=math.min(material.confidence or 0,rule.confidence0to100)
                    material.transformConfidence=math.min(material.transformConfidence or 100,rule.confidence0to100)
                    material.chance=nil;material.probabilityVerified=false
                    material.minQuantity=nil;material.maxQuantity=nil
                    material.quantityCounts=nil;material.personalHistogram=nil;material.fieldEvidence=nil
                    material.boundsSource=nil;material.boundsBasis=nil;material.probabilityBasis=nil
                    material.chanceConfidence=nil;material.chanceCasts=nil
                    material.netUnitPrice=nil;material.netExpectedValue=nil
                    changed=true
                end
            end
        end
    end
    if not changed then return model end
    result.skillQualityApplied=true;result.skillQualityRank=quality
    result.skillQualityThreshold=operation.highQualitySkillThreshold
    result.skillQualityRuleID=rule.ruleID;result.skillQualitySources=copy(rule.sourceClaimIDs)
    result.baselineConfidence=model.baselineConfidence or model.confidence
    result.confidence=math.min(model.confidence or 0,rule.confidence0to100)
    result.ruleConfidence=math.min(model.ruleConfidence or 100,rule.confidence0to100)
    result.provisional=true;result.baselineAdjustment=model.adjustment
    result.adjustment='Skill-based output quality; reference quantities unchanged'
    result.value=nil;result.partialValue=nil;result.valueConfidence=nil
    return result
end

-- A what-if scenario on the selected evidence estimate. These percentages are
-- supplied by the player; they are not learned skill/specialization curves.
-- Apply after source selection/blending, never to stored empirical records.
function LL:ApplySyntheticBenchmark(f,option,model,context)
    if not model or model.syntheticBenchmark or not context or not context.simulated
        or context.profileKind~='manual-simulation' or not self.NormalizeSyntheticBenchmark then return model end
    local benchmark=self:NormalizeSyntheticBenchmark(context.benchmark)
    if not benchmark or (benchmark.outputLevel==100 and benchmark.specializationBonus==0
        and benchmark.resourcefulnessChance==0 and benchmark.resourcefulnessSaved==0) then return model end
    local factor=benchmark.outputLevel/100*(1+benchmark.specializationBonus/100)
    -- A scenario never creates an expectation for an unknown/conditional drop.
    for _,material in ipairs(model.materials or {}) do
        if finite(material.expectedQuantity) and not finite(material.expectedQuantity*factor) then return model end
    end
    local result=copy(model)
    result.syntheticBenchmark=true;result.simulated=true;result.provisional=true
    result.benchmarkParameters=benchmark;result.benchmarkOutputFactor=factor
    result.baselineConfidence=model.confidence
    result.confidence=0;result.confidenceUnscored=true
    result.baselineAdjustment=model.adjustment
    result.adjustment=('Synthetic benchmark — assumed bonuses; baseline confidence %s%%'):format(
        finite(model.confidence) and tostring(model.confidence) or 'unknown')
    -- A previously valued model may be passed by a display caller. Revaluation
    -- must use scenario quantities rather than retained baseline price totals.
    result.value=nil;result.partialValue=nil;result.valueConfidence=nil
    for _,material in ipairs(result.materials or {}) do
        material.baselineConfidence=material.confidence;material.confidence=0
        if finite(material.expectedQuantity) then
            local original=material.expectedQuantity
            material.expectedQuantity=original*factor
            material.netExpectedValue=nil
            if factor~=1 and original>0 then
                -- A new mean establishes neither P(hit), bounds nor a histogram.
                material.chance=nil;material.chanceConfidence=nil;material.chanceCasts=nil
                material.probabilityVerified=false;material.minQuantity=nil;material.maxQuantity=nil
                material.quantityCounts=nil;material.personalHistogram=nil;material.fieldEvidence=nil
                material.boundsSource=nil;material.boundsBasis=nil;material.probabilityBasis=nil
                material.conditionalExpectedQuantity=nil;material.conditionalExpectedValue=nil
                material.conditionalRequirement=nil;material.filled=nil;material.derivedMean=nil
                material.inconsistentFields=nil
            end
        end
    end
    local requested=benchmark.resourcefulnessChance>0 or benchmark.resourcefulnessSaved>0
    if requested then
        local method=option and option.name
        if (method=='Mill' or method=='Prospect') and f and finite(f.expansionID) and f.expansionID>=9
            and finite(result.inputCount) and result.inputCount>0 then
            result.baselineExpectedInputCount=model.expectedInputCount
            result.expectedInputCount=result.inputCount*(1-benchmark.resourcefulnessChance/100*benchmark.resourcefulnessSaved/100)
            result.syntheticResourcefulnessNote='Assumed Resourcefulness replaces any baseline input savings; output quantities remain per completed operation'
        else
            result.syntheticResourcefulnessNote='Assumed Resourcefulness skipped: only Dragonflight and later milling/prospecting are supported'
        end
        result.warning=result.warning and (result.warning..'; '..result.syntheticResourcefulnessNote) or result.syntheticResourcefulnessNote
    end
    return result
end

-- Specialization point effects use the selected node's sourced formula. The
-- editor stores points, never a universal percentage-to-yield assumption.
local function specializationPoints(self,context)
    if type(context.specializationPoints)=='table' then return context.specializationPoints end
    if self.ProfessionSpecializationPoints then return self:ProfessionSpecializationPoints(context.specialization) end
    local out={}
    for id,rank in tostring(context.specialization or ''):gmatch('(%d+)=(%d+)') do out[id]=tonumber(rank) end
    return out
end
local function specializationScope(rule,f,option,context)
    if not usable(rule) or rule.applyPolicy~='EXECUTE' or type(rule.ruleID)~='string'
        or rule.method~=option.name or rule.expansionID~=f.expansionID
        or (rule.profession and context.profession and rule.profession~=context.profession)
        or (rule.recipeID and rule.recipeID~=option.recipeID)
        or (rule.inputRarity and rule.inputRarity~=f.quality)
        or (rule.inputClassID and rule.inputClassID~=f.classID) then return false end
    local build=GetBuildInfo and select(2,GetBuildInfo())
    if rule.build and tostring(rule.build)~=tostring(build) then return false end
    if rule.inputItemIDs then
        local matched=false
        for _,id in ipairs(rule.inputItemIDs) do if id==f.id then matched=true end end
        if not matched then return false end
    end
    if rule.inputQualityRanks then
        local matched=false
        for _,rank in ipairs(rule.inputQualityRanks) do if rank==f.reagentQuality then matched=true end end
        if not matched then return false end
    end
    return true
end
local function selectedRank(rule,points)
    if not finite(rule.nodeID) or rule.nodeID%1~=0 or not finite(rule.maxRank) or rule.maxRank%1~=0 then return nil end
    local rank=points[tostring(rule.nodeID)] or points[rule.nodeID] or 0
    if not finite(rank) or rank%1~=0 or rank>rule.maxRank then return nil end
    return rank
end
local function specializationRules(self,f,option,context)
    local rules,seen,duplicates={},{},{}
    for _,rule in ipairs(self.ItemDB and self.ItemDB.specializationRules or {}) do
        if specializationScope(rule,f,option,context) then
            if seen[rule.ruleID] then duplicates[rule.ruleID]=true else seen[rule.ruleID]=true;rules[#rules+1]=rule end
        end
    end
    local unique={}
    for _,rule in ipairs(rules) do if not duplicates[rule.ruleID] then unique[#unique+1]=rule end end
    return unique
end
local function manualSpecializationContext(context)
    return type(context)=='table' and context.simulated==true and context.profileKind=='manual-simulation' and not context.stale
end
function LL:ApplySpecializationSkill(f,option,context)
    if not manualSpecializationContext(context) or type(f)~='table' or type(option)~='table' then return context end
    local points=specializationPoints(self,context)
    if type(points)~='table' then return context end
    local bonus,confidence,rules,sources=0,100,{},{}
    local reference,referenceRule,ambiguous
    for _,rule in ipairs(specializationRules(self,f,option,context)) do
        if rule.kind=='skill-per-point' and finite(rule.perPoint) then
            local rank=selectedRank(rule,points)
            if rank and rank>0 then
                bonus=bonus+rank*rule.perPoint
                confidence=math.min(confidence,rule.confidence0to100)
                rules[#rules+1]=rule.ruleID
                for _,id in ipairs(rule.sourceClaimIDs) do sources[id]=true end
            end
        elseif rule.kind=='reference-context' and type(rule.requiredNodes)=='table'
            and type(rule.referenceContextID)=='string' then
            local complete,count=true,0
            for id,required in pairs(rule.requiredNodes) do
                count=count+1
                local rank=points[tostring(id)] or points[tonumber(id)] or 0
                local cap=rule.requiredNodeCaps and rule.requiredNodeCaps[tostring(id)] or required
                if not finite(required) or required<=0 or not finite(rank) or rank%1~=0 or rank<required or rank>cap then complete=false end
            end
            if complete and count>0 then
                if reference and reference~=rule.referenceContextID then ambiguous=true end
                reference=rule.referenceContextID;referenceRule=rule
            end
        end
    end
    if ambiguous then reference=nil;referenceRule=nil end
    if bonus==0 and not reference and not context.specializationSkillApplied and not context.specializationReferenceRule then return context end
    local result=copy(context)
    if result.specializationReferenceRule and result.referenceContextID==result.specializationReferenceContextID then
        result.referenceContextID=nil
    end
    result.specializationReferenceRule=nil;result.specializationReferenceContextID=nil
    local base=context.simulatedBaseSkill or context.skill or context.effectiveSkill
    if finite(base) and finite(base+bonus) then
        result.simulatedBaseSkill=base;result.effectiveSkill=base+bonus
        result.specializationSkillApplied=bonus>0 or nil
        result.specializationSkillBonus=bonus
        result.specializationSkillRules=rules
        result.specializationSkillConfidence=bonus>0 and confidence or nil
        result.specializationSkillSources={}
        for id in pairs(sources) do result.specializationSkillSources[#result.specializationSkillSources+1]=id end
        table.sort(result.specializationSkillSources)
    end
    if reference then
        result.referenceContextID=reference
        result.specializationReferenceContextID=reference
        result.specializationReferenceRule=referenceRule.ruleID
        result.specializationReferenceConfidence=referenceRule.confidence0to100
    end
    return result
end
local function invalidateSpecializationDistribution(material)
    material.chance=nil;material.chanceConfidence=nil;material.chanceCasts=nil
    material.probabilityVerified=false;material.minQuantity=nil;material.maxQuantity=nil
    material.quantityCounts=nil;material.personalHistogram=nil;material.fieldEvidence=nil
    material.boundsSource=nil;material.boundsBasis=nil;material.probabilityBasis=nil
    material.filled=nil;material.derivedMean=nil;material.inconsistentFields=nil
    material.netUnitPrice=nil;material.netExpectedValue=nil
end
local function familyIdentity(family)
    if type(family)~='table' or not finite(family.id) or family.id<=0 then return nil end
    local ids=copy(family.rankIDs or {family.id})
    if #ids==0 then return nil end
    local sorted=copy(ids);table.sort(sorted)
    return table.concat(sorted,':'),ids
end
local function materialFamily(material,family)
    local key,ids=familyIdentity(family)
    if not key then return nil end
    if material.rankIDs then
        local sorted=copy(material.rankIDs);table.sort(sorted)
        if table.concat(sorted,':')==key then return 'family' end
    else
        for rank,id in ipairs(ids) do if material.id==id then return rank end end
    end
end
local function multiplierAt(rule,rank)
    local factor=1+(rule.perPoint or 0)*rank
    if not finite(factor) or factor<=0 then return nil end
    for _,milestone in ipairs(rule.milestones or {}) do
        if not finite(milestone.rank) or not finite(milestone.multiplier) or milestone.multiplier<=0 then return nil end
        if rank>=milestone.rank then factor=factor*milestone.multiplier end
    end
    return finite(factor) and factor>0 and factor or nil
end
function LL:ApplySpecializationEffects(f,option,model,context)
    if type(model)~='table' or model.specializationEffectsApplied or not manualSpecializationContext(context)
        or type(f)~='table' or type(option)~='table' then return model end
    local points=specializationPoints(self,context)
    if type(points)~='table' then return model end
    local selected=specializationRules(self,f,option,context)
    local result=copy(model)
    local changed,applied,confidence=false,{},100
    local function note(rule)
        applied[rule.ruleID]=rule
        confidence=math.min(confidence,rule.confidence0to100)
    end
    -- Replacements are evaluated against one original donor reservoir. Applying
    -- four colors in sequence would incorrectly shrink each later color's base.
    local groups={}
    for _,rule in ipairs(selected) do
        local rank=selectedRank(rule,points)
        if rule.kind=='replace-family' and rank and rank>0 and finite(rule.perPoint) then
            local key=familyIdentity(rule.sourceFamily)
            if key and familyIdentity(rule.targetFamily) then
                groups[key]=groups[key] or {family=rule.sourceFamily,rules={},sum=0}
                local group=groups[key]
                group.rules[#group.rules+1]={rule=rule,chance=rank*rule.perPoint}
                group.sum=group.sum+rank*rule.perPoint
            end
        elseif rule.kind=='quantity-multiplier' and rank and rank>0 then
            local factor=multiplierAt(rule,rank)
            local profile=model.specializationBaselineProfile
            if factor and profile then
                local sourceRank=selectedRank(rule,specializationPoints(self,profile))
                local sourceFactor=sourceRank and multiplierAt(rule,sourceRank)
                factor=sourceFactor and factor/sourceFactor or nil
            end
            if factor and factor~=1 then
                for _,material in ipairs(result.materials or {}) do
                    if finite(material.expectedQuantity) and material.conditionalExpectedQuantity==nil
                        and material.conditionalRequirement==nil
                        and (not rule.outputFamily or materialFamily(material,rule.outputFamily))
                        and finite(material.expectedQuantity*factor) then
                        material.specializationBaselineQuantity=material.specializationBaselineQuantity or material.expectedQuantity
                        material.expectedQuantity=material.expectedQuantity*factor
                        invalidateSpecializationDistribution(material)
                        material.confidence=math.min(material.confidence or model.confidence or 0,rule.confidence0to100)
                        note(rule);changed=true
                    end
                end
            end
        end
    end
    for _,group in pairs(groups) do
        if group.sum>0 and group.sum<=1 then
            local donors,aggregate,exact={},false,false
            for _,material in ipairs(result.materials or {}) do
                local rank=materialFamily(material,group.family)
                if rank and finite(material.expectedQuantity) and material.conditionalExpectedQuantity==nil
                    and material.conditionalRequirement==nil then
                    donors[#donors+1]={material=material,rank=rank,quantity=material.expectedQuantity}
                    if rank=='family' then aggregate=true else exact=true end
                end
            end
            -- An aggregate and its measured quality alternatives overlap; such
            -- a distribution cannot be safely allocated to colors a second time.
            if not (aggregate and exact) then
                for _,donor in ipairs(donors) do
                    local compatible=true
                    for _,entry in ipairs(group.rules) do
                        local _,ids=familyIdentity(entry.rule.targetFamily)
                        if donor.rank~='family' and not ids[donor.rank] then compatible=false end
                        for _,material in ipairs(result.materials) do
                            if materialFamily(material,entry.rule.targetFamily)==donor.rank
                                and (material.conditionalRequirement~=nil or material.conditionalExpectedQuantity~=nil) then compatible=false end
                        end
                    end
                    local moved=donor.quantity*group.sum
                    if compatible and moved>0 then
                        donor.material.specializationBaselineQuantity=donor.quantity
                        donor.material.expectedQuantity=donor.quantity-moved
                        invalidateSpecializationDistribution(donor.material)
                        for _,entry in ipairs(group.rules) do
                            local rule=entry.rule
                            local _,targetIDs=familyIdentity(rule.targetFamily)
                            local targetID=donor.rank=='family' and rule.targetFamily.id or targetIDs[donor.rank]
                            if targetID then
                                local target
                                for _,material in ipairs(result.materials) do
                                    if materialFamily(material,rule.targetFamily)==donor.rank then target=material;break end
                                end
                                local additional=donor.quantity*entry.chance
                                if not target then
                                    target={id=targetID,rankIDs=donor.rank=='family' and copy(rule.targetFamily.rankIDs) or nil,
                                        expectedQuantity=0,confidence=math.min(model.confidence or 0,rule.confidence0to100),
                                        sourceEstimates={},specializationDerivedOutput=true}
                                    result.materials[#result.materials+1]=target
                                elseif not finite(target.expectedQuantity) then
                                    target.specializationUnknownBaseline=true
                                    target.expectedQuantity=0;result.unknownOutputs=true
                                end
                                target.specializationBaselineQuantity=target.specializationBaselineQuantity or target.expectedQuantity
                                target.expectedQuantity=target.expectedQuantity+additional
                                invalidateSpecializationDistribution(target)
                                target.confidence=math.min(target.confidence or model.confidence or 0,rule.confidence0to100)
                                donor.material.confidence=math.min(donor.material.confidence or model.confidence or 0,rule.confidence0to100)
                                note(rule);changed=true
                            end
                        end
                    end
                end
            end
        end
    end
    local matchedReference=context.specializationReferenceRule
        and model.referenceContextID==context.specializationReferenceContextID
    if not changed then
        if context.specializationSkillApplied or matchedReference then
            result.specializationSkillBonus=context.specializationSkillBonus
            result.specializationReferenceRule=matchedReference and context.specializationReferenceRule or nil
            if matchedReference then
                result.specializationEffectsApplied=true
                result.specializationAppliedRules={context.specializationReferenceRule}
                result.baselineConfidence=model.baselineConfidence or model.confidence
                result.ruleConfidence=math.min(result.ruleConfidence or 100,context.specializationReferenceConfidence or 100)
                result.confidence=math.min(result.confidence or 0,result.ruleConfidence)
                for _,material in ipairs(result.materials or {}) do
                    material.confidence=math.min(material.confidence or 0,result.ruleConfidence)
                    material.transformConfidence=math.min(material.transformConfidence or 100,result.ruleConfidence)
                end
                result.provisional=true;result.simulated=true
                result.adjustment='Specialization point simulation; matched researched specialization reference'
            end
            if context.specializationSkillApplied and model.skillQualityApplied then
                result.specializationAppliedRules=result.specializationAppliedRules or copy(context.specializationSkillRules)
                result.specializationSources=copy(context.specializationSkillSources)
                result.ruleConfidence=math.min(result.ruleConfidence or 100,context.specializationSkillConfidence or 100)
                result.confidence=math.min(result.confidence or 0,result.ruleConfidence)
                for _,material in ipairs(result.materials or {}) do
                    if material.appliedSkillQualityRule then
                        material.confidence=math.min(material.confidence or 0,result.ruleConfidence)
                        material.transformConfidence=math.min(material.transformConfidence or 100,result.ruleConfidence)
                    end
                end
            end
            return result
        end
        return model
    end
    result.specializationEffectsApplied=true;result.simulated=true;result.provisional=true
    result.specializationAppliedRules={};result.specializationSources={}
    local sourceIDs={}
    for id,rule in pairs(applied) do
        result.specializationAppliedRules[#result.specializationAppliedRules+1]=id
        for _,source in ipairs(rule.sourceClaimIDs) do sourceIDs[source]=true end
    end
    for id in pairs(sourceIDs) do result.specializationSources[#result.specializationSources+1]=id end
    table.sort(result.specializationAppliedRules);table.sort(result.specializationSources)
    result.specializationSkillBonus=context.specializationSkillBonus
    result.baselineConfidence=model.baselineConfidence or model.confidence
    result.ruleConfidence=math.min(model.ruleConfidence or 100,confidence)
    if model.skillQualityApplied and context.specializationSkillApplied then
        result.ruleConfidence=math.min(result.ruleConfidence,context.specializationSkillConfidence or 100)
        for _,id in ipairs(context.specializationSkillSources or {}) do
            if not sourceIDs[id] then result.specializationSources[#result.specializationSources+1]=id;sourceIDs[id]=true end
        end
        table.sort(result.specializationSources)
    end
    result.confidence=math.min(model.confidence or 0,result.ruleConfidence)
    result.baselineAdjustment=model.adjustment
    result.adjustment='Specialization point simulation; sourced effects applied to selected reference'
    result.specializationReferenceAssumption=model.specializationBaselineProfile==nil and 'Selected reference; original specialization allocation is unknown' or nil
    if result.specializationReferenceAssumption then
        result.warning=result.warning and (result.warning..'; '..result.specializationReferenceAssumption) or result.specializationReferenceAssumption
    end
    result.value=nil;result.partialValue=nil;result.valueConfidence=nil
    return result
end
