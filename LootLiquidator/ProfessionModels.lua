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
-- A research build identifies the evidence, not necessarily an expiry at the
-- next client hotfix. Static rules may explicitly cover one client version.
-- Keep exact-build behavior for rules without that scope, and keep operation
-- snapshots/patch bridges exact: those describe an actual captured state.
function LL:ProfessionRuleMatchesBuild(rule)
    if type(rule)~='table' then return false end
    local version,build
    if GetBuildInfo then version,build=GetBuildInfo() end
    if rule.clientVersion~=nil then
        local sourceBuild,currentBuild=tonumber(rule.build),tonumber(build)
        return type(rule.clientVersion)=='string'
            and rule.clientVersion:match('^%d+%.%d+%.%d+$')~=nil
            and version==rule.clientVersion
            and finite(sourceBuild) and sourceBuild>0 and sourceBuild%1==0
            and finite(currentBuild) and currentBuild%1==0 and currentBuild>=sourceBuild
    end
    return rule.build==nil or build~=nil and tostring(rule.build)==tostring(build)
end
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
-- Disenchant quantity/quality does not depend on an equipment GUID, armor
-- subclass, UI allocation-table format, or a Crafting Speed rating. At known
-- zero specialization, the measured effective skill already includes actual
-- gear/enchant skill once. Other talent states still need their normal model.
-- Material baselines depend on skill, specialization and modeled outcome
-- modifiers. Full aura maps remain observation metadata; an unrelated or
-- unmodeled aura must not replace a measured baseline with a category prior.
function LL:DisenchantModelAuraSet(context)
    local database=self.ItemDB
    local db=database or {}
    local profiles=db.professionProfiles and db.professionProfiles.profiles
    local expansion=context and (context.expansionID or context.inputExpansionID)
    local revision=db.modelRevision or db.revision
    local cached=self._disenchantAuraScopeCache
    if not cached or cached.database~=database or cached.revision~=revision
        or cached.profiles~=db.professionProfiles or cached.professionRules~=db.professionRules
        or cached.personalPatchRules~=db.personalPatchRules or cached.mechanicRules~=db.mechanicRules then
        cached={database=database,revision=revision,profiles=db.professionProfiles,
            professionRules=db.professionRules,personalPatchRules=db.personalPatchRules,
            mechanicRules=db.mechanicRules,scopes={}}
        self._disenchantAuraScopeCache=cached
    end
    local scope=expansion==nil and '*' or tostring(expansion)
    if cached.scopes[scope] then return cached.scopes[scope] end
    local ids,visited={},{}
    local function visit(value,materialEffect)
        if type(value)~='table' or visited[value] then return end
        visited[value]=true
        if value.metric~=nil then
            materialEffect=value.metric=='skill' or value.metric=='yieldMultiplier'
                or value.metric=='extraOutput' or value.metric=='dropChance'
        end
        local scope=value.scope or {}
        if scope.method and scope.method~='Disenchant' then materialEffect=false end
        if scope.recipeID and scope.recipeID~=13262 then materialEffect=false end
        if materialEffect==false then return end
        for _,id in ipairs(type(value.condition)=='table' and value.condition.spellIDs or {}) do ids[tostring(id)]=true end
        for id,active in pairs(type(value.buffs)=='table' and value.buffs or {}) do
            if active then ids[tostring(type(active)=='number' and active or id)]=true end
        end
        for _,entry in pairs(value) do if type(entry)=='table' then visit(entry,materialEffect) end end
    end
    if expansion~=nil then visit(profiles and profiles['Enchanting:'..tostring(expansion)])
    else
        -- Old source contexts may omit expansion. Absence of that field must
        -- not hide a known condition from another Enchanting profile.
        for key,profile in pairs(profiles or {}) do
            if type(key)=='string' and key:match('^Enchanting:') then visit(profile) end
        end
    end
    for _,name in ipairs({'professionRules','personalPatchRules','mechanicRules'}) do
        for _,rule in ipairs(db[name] or {}) do
            if (rule.profession=='Enchanting' or rule.method=='Disenchant')
                and (rule.method==nil or rule.method=='Disenchant')
                and (rule.recipeID==nil or rule.recipeID==13262)
                and (expansion==nil or rule.expansionID==nil or rule.expansionID==expansion) then visit(rule) end
        end
    end
    cached.scopes[scope]=ids
    return ids
end
function LL:DisenchantObservationProfileKey(context)
    if type(context)~='table' or context.profession~='Enchanting' then return nil end
    local skill=context.effectiveSkill or context.preSpecializationSkill or context.skill
    if not finite(skill) then return nil end
    if context.maxSkill~=nil and (not finite(context.maxSkill) or context.maxSkill<=0) then return nil end
    local zero=context.specialization=='none'
    for _,points in ipairs({context.specializationPoints or {},context.disenchantSpecializationPoints or {}}) do
        for _,value in pairs(points) do
            if not finite(value) or value~=0 then return nil end
        end
    end
    for _,learned in ipairs({context.learnedSpecializations or {},context.disenchantLearnedSpecializations or {}}) do
        for _,value in pairs(learned) do if value then return nil end end
    end
    if (context.specializationKnown==true or context.disenchantSpecializationKnown==true
        or context.simulated and context.profileKind=='manual-simulation')
        and type(context.specializationPoints or context.disenchantSpecializationPoints)=='table' then zero=true end
    if not zero then return nil end
    if context.fieldStatus and context.fieldStatus.effectiveSkill=='unknown' then return nil end
    -- Keep only declared material-model dependencies in the matching key.
    -- Unknown aura differences remain in both complete contexts, but supply
    -- no invented multiplier and do not invalidate measured quantities.
    local relevant=self:DisenchantModelAuraSet(context)
    local buffs,values={},{}
    for _,auraMap in ipairs({context.buffs or {},context.activeBuffs or {}}) do
        for id,active in pairs(auraMap) do
            local key=tostring(id)
            if active and relevant[key] then
                local stacks=context.buffStacks or {}
                local value=tostring(stacks[id] or stacks[key] or stacks[tonumber(key)] or active)
                if values[key] and values[key]~=value then return nil end
                values[key]=value
            end
        end
    end
    for id,value in pairs(values) do buffs[#buffs+1]=id..'='..value end
    table.sort(buffs)
    return ('effective:%g;specialization:none;buffs:%s'):format(skill,table.concat(buffs,','))
end

function LL:ReuseDisenchantSourceProfile(f,option,raw,target,targetBuild)
    if type(option)~='table' or option.name~='Disenchant' or option.recipeID~=13262 or type(f)~='table'
        or (f.classID~=2 and f.classID~=4) or not raw or not raw.observationContext
        or type(target)~='table' or target.character~=raw.observationContext.character then return nil end
    local source=raw.observationContext
    -- A manual target may match a recorded profile; a manual source is never
    -- evidence. Legacy measured contexts have no profileKind marker.
    if source.simulated==true or (source.profileKind~=nil and source.profileKind~='measured') then return nil end
    if source.fieldStatus and source.fieldStatus.specialization=='unknown' then return nil end
    local sourceKey=self:DisenchantObservationProfileKey(source)
    if not sourceKey or sourceKey~=self:DisenchantObservationProfileKey(target) then return nil end
    local category=('gear:%s:%s:%s'):format(tostring(f.expansionID),tostring(f.quality),f.classID==2 and 'weapon' or 'armor')
    if raw.gearKey~=category then return nil end
    local sourceBuild=tostring(raw.sourcePatchBuild or raw.patchBuild)
    targetBuild=tostring(targetBuild or (GetBuildInfo and select(2,GetBuildInfo())))
    local version=GetBuildInfo and GetBuildInfo()
    local historical=sourceBuild~=targetBuild
    if historical then
        local before,after=tonumber(sourceBuild),tonumber(targetBuild)
        if not before or not after or before>=after or type(version)~='string'
            or not version:match('^%d+%.%d+%.%d+$') then return nil end
        if raw.clientVersion and raw.clientVersion~=version then return nil end
    end
    local result=copy(raw)
    result.rawEstimate=copy(raw.rawEstimate or raw)
    result.projectedContext=copy(target)
    result.targetPatchBuild=targetBuild;result.sourcePatchBuild=sourceBuild
    -- This is an unscaled historical source reference, not a factor-one patch
    -- bridge or a newly observed current-build study. Histograms/counts retain
    -- their original source build/profile and are never relabeled as new casts.
    result.patchBuild=sourceBuild
    result.professionProjected=true
    result.numericTransformApplied=false
    result.personalSourceProfileMatched=true
    result.profileEquivalencePolicy='disenchant-material-dependencies/2'
    result.sourceReferenceOnly=historical or raw.coverageCensored==true
    result.sourceApplicabilityConfidence=historical and 0 or nil
    result.currentPatchApplicabilityConfidence=historical and 0 or nil
    result.observationBuildPolicy={policyID='personal-de-source-context/1',sourceBuild=sourceBuild,targetBuild=targetBuild,
        currentClientVersion=version,sourceClientVersion=raw.clientVersion,sourceClientVersionKnown=raw.clientVersion~=nil,
        unchangedRatesVerified=false,numericTransformApplied=false,retainedSourceSamples=raw.samples or raw.operations}
    result.adjustment='Recorded disenchant source profile'
    return result
end

function LL:ProjectPersonalEstimate(f,option,raw,target,targetBuild)
    if not raw or not raw.observationContext then return nil,'Missing recorded profile' end
    local retained=self:ReuseDisenchantSourceProfile(f,option,raw.rawEstimate or raw,target,targetBuild)
    if retained then return retained end
    if self.ProjectGeneralPersonalEstimate then
        local general=self:ProjectGeneralPersonalEstimate(f,option,raw,target,targetBuild)
        if general then return general end
    end
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
            and self:ProfessionRuleMatchesBuild(candidate)
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
    for _,outcome in ipairs(result.namedOutputs or {}) do
        if finite(outcome.expectedQuantity) then outcome.expectedQuantity=outcome.expectedQuantity*factor;outcome.confidence=0 end
    end
    local requested=benchmark.resourcefulnessChance>0 or benchmark.resourcefulnessSaved>0
    if requested then
        local method=option and option.name
        local params=model.professionParameters or model.generalProfessionParameters
        local craft=params and params.method~='Disenchant' and params.method~='Gather'
            and params.method~='Loot' and params.method~='Use'
            and params.method~='Skin' and params.method~='Fish' and params.recipe
            and params.recipe.supportsResourcefulness~=false
        local expansion=params and params.expansionID or f and f.expansionID
        if (method=='Mill' or method=='Prospect' or craft) and finite(expansion) and expansion>=9
            and finite(result.inputCount) and result.inputCount>0 then
            result.baselineExpectedInputCount=model.expectedInputCount
            result.expectedInputCount=result.inputCount*(1-benchmark.resourcefulnessChance/100*benchmark.resourcefulnessSaved/100)
            result.supplyCostFactor=1-benchmark.resourcefulnessChance/100*benchmark.resourcefulnessSaved/100
            result.syntheticResourcefulnessNote='Assumed Resourcefulness replaces any baseline input savings; output quantities remain per completed operation'
        else
            result.syntheticResourcefulnessNote='Resourcefulness scenario skipped for this operation'
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
    if not LL:ProfessionRuleMatchesBuild(rule) then return false end
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
local function describedEffectValid(self,effect)
    if type(effect)~='table' or type(effect.effectID)~='string' or effect.effectID==''
        or type(effect.description)~='string' or effect.description==''
        or type(effect.nodeName)~='string' or effect.nodeName==''
        or not finite(effect.nodeID) or effect.nodeID<=0 or effect.nodeID%1~=0
        or not finite(effect.maxRank) or effect.maxRank<=0 or effect.maxRank%1~=0
        or type(effect.sourceClaimIDs)~='table' or #effect.sourceClaimIDs==0
        or not self:ProfessionRuleMatchesBuild(effect) then return false end
    for _,id in ipairs(effect.sourceClaimIDs) do
        if type(id)~='string' or id=='' then return false end
    end
    return true
end
-- These historical endpoint reports are display-only. Maximal selected points
-- choose which report is relevant; they do not establish matching source skill,
-- equipment, inputs or patch. Never inject them into the selected distribution.
function LL:ProfessionSimulationPublishedReferences(f,option,model)
    local context=model and model.context
    local notes={}
    -- Ordinary Disenchant tooltip options omit recipeID; that method denotes
    -- spell 13262. An explicitly different operation must still be rejected.
    if not manualSpecializationContext(context) or type(f)~='table' or type(option)~='table'
        or option.name~='Disenchant' or (option.recipeID~=nil and option.recipeID~=13262) or context.profession~='Enchanting'
        or f.expansionID~=11 or (f.classID~=2 and f.classID~=4) then return notes end
    local mode=(self.ProcessingDataMode and self:ProcessingDataMode(option.name)) or 1
    if not self.EvidenceSourceWeight or self:EvidenceSourceWeight('reference',mode)<=0 then return notes end
    local points=specializationPoints(self,context)
    if type(points)~='table' then return notes end
    local seen={}
    for _,reference in ipairs(self.ItemDB and self.ItemDB.specializationPublishedReferences or {}) do
        if type(reference)=='table' and type(reference.referenceID)=='string' and not seen[reference.referenceID]
            and reference.applyPolicy=='DISPLAY_ONLY' and reference.displayPolicy=='MAX_INVESTMENT_SCENARIO_ONLY'
            and reference.method==option.name and reference.profession==context.profession
            and reference.expansionID==f.expansionID and reference.inputRarity==f.quality
            and self:ProfessionRuleMatchesBuild(reference) and type(reference.displayText)=='string'
            and type(reference.sourceClaimIDs)=='table' and #reference.sourceClaimIDs>0
            and type(reference.requiredNodes)=='table' and type(reference.notes)=='table' then
            local complete,count=true,0
            for id,required in pairs(reference.requiredNodes) do
                count=count+1
                local node=tonumber(id)
                if not finite(node) or node<=0 or node%1~=0 or not finite(required) or required<=0 or required%1~=0
                    or selectedRank({nodeID=node,maxRank=required},points)~=required then complete=false end
            end
            local text=reference.displayText
            for _,note in ipairs(reference.notes) do
                if type(note)~='string' then complete=false else text=text..' '..note end
            end
            if complete and count>0 then
                notes[#notes+1]=text;seen[reference.referenceID]=true
            end
        end
    end
    return notes
end
-- Confidence is the uncertainty signal. Profession details contain only the
-- selected inputs, not research caveats or a second estimate label.
function LL:ProfessionSimulationEffectNotes(f,option,model)
    local context=model and model.context
    local notes,unquantified={},false
    if not manualSpecializationContext(context) or type(f)~='table' or type(option)~='table' then return notes,false end
    local points=specializationPoints(self,context)
    local knownSkill=false
    for _,rule in ipairs(self.ItemDB and self.ItemDB.specializationRules or {}) do
        if rule.kind=='skill-per-point' and specializationScope(rule,f,option,context) then knownSkill=true end
    end
    for _,effect in ipairs(self.ItemDB and self.ItemDB.specializationDescriptions or {}) do
        if describedEffectValid(self,effect) and effect.method==option.name and effect.expansionID==f.expansionID
            and effect.profession==context.profession
            and (effect.inputRarity==nil or effect.inputRarity==f.quality)
            and (effect.inputClassID==nil or effect.inputClassID==f.classID)
            and (effect.recipeID==nil or effect.recipeID==option.recipeID) then
            local rank=selectedRank(effect,points)
            if rank and rank>0 then
                notes[#notes+1]=effect.nodeName..': '..rank..' / '..effect.maxRank..' points.'
            end
        end
    end
    if (knownSkill or model.skillQualityApplied) and finite(context.effectiveSkill) then
        table.insert(notes,1,('Simulated skill: %g (specialization bonus: +%g).')
            :format(context.effectiveSkill,context.specializationSkillBonus or 0))
    end
    return notes,unquantified
end
local function specializationSkillContribution(rule,rank,context)
    local contribution=rank*(rule.perPoint or 0)
    if not finite(contribution) then return nil end
    -- New milestone evidence does not retroactively change older builds.
    local build=GetBuildInfo and tonumber((select(2,GetBuildInfo())))
    if rule.skillMilestoneBuild~=nil then
        if not finite(rule.skillMilestoneBuild) or rule.skillMilestoneBuild<=0 or rule.skillMilestoneBuild%1~=0 then return nil end
        if not finite(build) or build<rule.skillMilestoneBuild then return contribution end
    end
    local learned=rank>0 or type(context.learnedSpecializations)=='table'
        and (context.learnedSpecializations[tostring(rule.nodeID)]==true or context.learnedSpecializations[rule.nodeID]==true)
    if not learned then return contribution end
    if rule.learningSkill~=nil then
        if not finite(rule.learningSkill) then return nil end
        contribution=contribution+rule.learningSkill
    end
    if rule.skillMilestones~=nil and type(rule.skillMilestones)~='table' then return nil end
    local previous=0
    for _,milestone in ipairs(rule.skillMilestones or {}) do
        if type(milestone)~='table' or not finite(milestone.rank) or milestone.rank%1~=0
            or milestone.rank<=previous or milestone.rank>rule.maxRank or not finite(milestone.skill) then return nil end
        previous=milestone.rank
        if rank>=milestone.rank then contribution=contribution+milestone.skill end
    end
    return finite(contribution) and contribution or nil
end
function LL:ApplySpecializationSkill(f,option,context)
    if not manualSpecializationContext(context) or type(f)~='table' or type(option)~='table' then return context end
    local points=specializationPoints(self,context)
    if type(points)~='table' then return context end
    local bonus,confidence,rules,sources=0,100,{},{}
    local reference,referenceRule,ambiguous
    for _,rule in ipairs(specializationRules(self,f,option,context)) do
        if (rule.kind=='skill-per-point' and finite(rule.perPoint)) or rule.kind=='skill-milestones' then
            local rank=selectedRank(rule,points)
            local contribution=rank and specializationSkillContribution(rule,rank,context)
            if contribution and contribution>0 then
                bonus=bonus+contribution
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
                local chance=rank*rule.perPoint
                local currentBuild=GetBuildInfo and tonumber((select(2,GetBuildInfo())))
                if currentBuild and currentBuild>=(rule.replacementMilestoneBuild or math.huge) then
                    for _,milestone in ipairs(rule.replacementMilestones or {}) do
                        if rank>=milestone.rank then chance=chance+milestone.fraction end
                    end
                end
                group.rules[#group.rules+1]={rule=rule,chance=chance}
                group.sum=group.sum+chance
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

-- Shared build/runtime curve. Observations stay in db.processing; the compiler
-- supplies an independent baseline and endpoint, with explicit model confidence.
local function deAmounts(materials)
    local result={}
    for _,material in ipairs(materials or {}) do
        if type(material)~='table' or not finite(material.id) or material.id<=0 or material.id%1~=0
            or result[material.id]~=nil or not finite(material.expectedQuantity) then return nil end
        result[material.id]=material.expectedQuantity
    end
    return result
end
-- Retain an unchanged distribution. A changed mean alone does not determine
-- occurrence. The one supported exception is quality-only redistribution of
-- a source primary that always has the same positive stack size: E=P*stack.
-- This remains a confidence-capped model and adds no observed casts/hits.
local function deDistribution(source,result,fixedPrimaryStack)
    if type(source)~='table' then return result end
    if finite(source.expectedQuantity) and math.abs(result.expectedQuantity-source.expectedQuantity)<1e-10 then
        result.minQuantity=source.minQuantity;result.maxQuantity=source.maxQuantity
        if not finite(source.chance) or source.chance>1 then return result end
        result.chance=source.chance
        result.chanceConfidence=math.min(result.confidence or 100,source.chanceConfidence or source.confidence or 0)
        result.probabilityBasis=source.probabilityBasis or 'unchanged-source-occurrence'
        result.probabilityVerified=source.probabilityVerified
    elseif fixedPrimaryStack and finite(source.chance) and source.chance<=1
        and finite(source.minQuantity) and source.minQuantity>0
        and source.minQuantity==source.maxQuantity and source.minQuantity%1==0
        and finite(source.expectedQuantity)
        and math.abs(source.expectedQuantity-source.chance*source.minQuantity)<1e-6
        and result.expectedQuantity<=source.minQuantity then
        result.chance=result.expectedQuantity/source.minQuantity
        result.minQuantity=source.minQuantity;result.maxQuantity=source.maxQuantity
        result.chanceConfidence=math.min(result.confidence or 100,source.chanceConfidence or source.confidence or 0)
        result.probabilityBasis='modeled-fixed-stack-primary-quality'
        result.probabilityAssumption='Primary quality redistribution preserves the source fixed positive stack; no target observations added'
        result.probabilityVerified=false
    end
    return result
end
local function deFixedStackContributors(material)
    local stack=material.minQuantity
    if not finite(stack) or stack<=0 or stack~=material.maxQuantity or stack%1~=0 then return false end
    local any=false
    for key,weight in pairs(material.sourceContributions or {}) do
        if finite(weight) and weight>0 then
            local source=material.sourceEstimates and material.sourceEstimates[key]
            if not source or not source.records or #source.records==0 then return false end
            for _,record in ipairs(source.records) do
                if record.inputCount~=1 or record.minQuantity~=stack or record.maxQuantity~=stack
                    or not finite(record.expectedQuantity) or not finite(record.dropChance) or record.dropChance>1
                    or math.abs(record.expectedQuantity-record.dropChance*stack)>1e-6 then return false end
            end
            any=true
        end
    end
    return any
end
local function deCurveState(baseline,profile)
    local rule=type(baseline)=='table' and baseline.rule
    if type(rule)~='table' or type(profile)~='table' or not finite(profile.effectiveSkill)
        or not finite(profile.childPoints) or profile.childPoints%1~=0 or profile.childPoints>30
        or not finite(rule.skillMaximum) or rule.skillMaximum<=0 or type(rule.primaryRankIDs)~='table'
        or #rule.primaryRankIDs~=2 or rule.primaryRankIDs[1]==rule.primaryRankIDs[2] then return nil end
    local base,target=deAmounts(baseline.materials),deAmounts(baseline.endpointMaterials)
    if not base or not target then return nil end
    local low,high=rule.primaryRankIDs[1],rule.primaryRankIDs[2]
    if not finite(base[low]) or not finite(base[high]) or not finite(target[low]) or not finite(target[high]) then return nil end
    local q0,q1=base[low]+base[high],target[low]+target[high]
    if q0<=0 or q1<=0 then return nil end
    local tq,previous=0,0
    if type(rule.quantityMilestones)~='table' then return nil end
    for _,milestone in ipairs(rule.quantityMilestones) do
        if type(milestone)~='table' or not finite(milestone.rank) or milestone.rank%1~=0
            or milestone.rank<=previous or milestone.rank>30 or not finite(milestone.progress) then return nil end
        previous=milestone.rank
        if profile.childPoints>=milestone.rank then tq=tq+milestone.progress end
    end
    if tq>1 then return nil end
    local extraIDs,extraConfidence,extraProgress={},{},0
    if rule.additionalOutputs then
        if rule.additionalOutputBaselinePolicy~='ZERO_BEFORE_UNLOCK' or type(rule.additionalOutputMilestones)~='table' then return nil end
        local previousRank=0
        for _,milestone in ipairs(rule.additionalOutputMilestones) do
            if not finite(milestone.rank) or milestone.rank%1~=0 or milestone.rank<=previousRank or milestone.rank>30
                or not finite(milestone.progress) then return nil end
            previousRank=milestone.rank
            if profile.childPoints>=milestone.rank then extraProgress=extraProgress+milestone.progress end
        end
        if extraProgress>1 then return nil end
        for _,extra in ipairs(rule.additionalOutputs) do
            if type(extra)~='table' or not finite(extra.id) or extra.id<=0 or extra.id%1~=0 or extraIDs[extra.id]
                or extra.id==low or extra.id==high or not finite(extra.expectedQuantity)
                or not finite(extra.confidence0to100) or extra.confidence0to100>100
                or not finite(base[extra.id]) or not finite(target[extra.id]) then return nil end
            extraIDs[extra.id]=true;extraConfidence[extra.id]=extra.confidence0to100
        end
    end
    return {base=base,target=target,low=low,high=high,q0=q0,q1=q1,r0=base[high]/q0,r1=target[high]/q1,
        skill=math.min(1,profile.effectiveSkill/rule.skillMaximum),quantity=tq,rule=rule,
        extraIDs=extraIDs,extraConfidence=extraConfidence,extraProgress=extraProgress}
end
function LL:DisenchantCurveQuantities(baseline,profile)
    local state=deCurveState(baseline,profile)
    if not state then return nil end
    local q=state.rule.preservePrimaryTotal and state.q0 or state.q0+(state.q1-state.q0)*state.quantity
    local share=state.r0+(state.r1-state.r0)*state.skill
    local means=copy(state.base)
    if state.rule.endpointRecordID then
        for id in pairs(state.target) do if means[id]==nil then means[id]=0 end end
        for id,value in pairs(means) do
            if id~=state.low and id~=state.high then means[id]=value+((state.target[id] or 0)-value)*state.quantity end
        end
    end
    for id in pairs(state.extraIDs) do means[id]=state.base[id]+(state.target[id]-state.base[id])*state.extraProgress end
    means[state.low]=q*(1-share);means[state.high]=q*share
    local sourceByID={}
    for _,material in ipairs(baseline.materials or {}) do sourceByID[material.id]=material end
    local result={}
    for id,value in pairs(means) do
        if not finite(value) then return nil end
        result[#result+1]=deDistribution(sourceByID[id],{id=id,expectedQuantity=value,
            confidence=math.min(baseline.confidence or state.rule.confidence0to100,state.extraConfidence[id] or 100),
            additionalOutput=state.extraIDs[id] or nil},
            (state.rule.preservePrimaryTotal or state.quantity==0) and (id==state.low or id==state.high))
    end
    table.sort(result,function(a,b) return a.id<b.id end)
    return result,{skill=state.skill,quantity=state.quantity,additional=state.extraProgress}
end
-- Invert the same affine pool/share model, never a separate guessed multiplier.
-- At a saturated endpoint the prior baseline is not identifiable from that
-- observation; retain its declared prior only when the endpoint agrees.
function LL:NormalizeDisenchantQuantities(baseline,observed,sourceProfile)
    local state=deCurveState(baseline,sourceProfile)
    local actual=deAmounts(observed)
    if not state or not actual or not finite(actual[state.low]) or not finite(actual[state.high]) then return nil end
    local q=actual[state.low]+actual[state.high]
    if q<=0 then return nil end
    local share=actual[state.high]/q
    local function inverse(value,target,progress,prior)
        if progress==1 then return math.abs(value-target)<1e-8 and prior or nil end
        local result=(value-target*progress)/(1-progress)
        return result>=-1e-10 and math.max(0,result) or nil
    end
    local q0=state.rule.preservePrimaryTotal and q or inverse(q,state.q1,state.quantity,state.q0)
    local r0=inverse(share,state.r1,state.skill,state.r0)
    if not finite(q0) or not finite(r0) or r0>1+1e-10 then return nil end
    r0=math.min(1,r0)
    local means=copy(actual)
    if state.rule.endpointRecordID then
        for id in pairs(state.base) do if means[id]==nil then return nil end end
        for id,value in pairs(means) do
            if id~=state.low and id~=state.high and not state.extraIDs[id] then
                means[id]=inverse(value,state.target[id] or 0,state.quantity,state.base[id] or 0)
                if not finite(means[id]) then return nil end
            end
        end
    end
    for id in pairs(state.extraIDs) do
        if not finite(actual[id]) then return nil end
        -- Additive unlock term: this inverse can reject negative baselines,
        -- rather than attempting to divide a zero expectation by a factor.
        local value=actual[id]-(state.target[id]-state.base[id])*state.extraProgress
        if value < -1e-10 then return nil end
        means[id]=math.max(0,value)
    end
    means[state.low]=q0*(1-r0);means[state.high]=q0*r0
    local observedByID={}
    for _,material in ipairs(observed) do observedByID[material.id]=material end
    local result={}
    for id,value in pairs(means) do result[#result+1]=deDistribution(observedByID[id],{id=id,expectedQuantity=value,
        confidence=math.min(baseline.confidence or state.rule.confidence0to100,state.extraConfidence[id] or 100),
        additionalOutput=state.extraIDs[id] or nil},
        (state.rule.preservePrimaryTotal or state.quantity==0) and (id==state.low or id==state.high)) end
    table.sort(result,function(a,b) return a.id<b.id end)
    return result
end

function LL:DisenchantForwardProfile(f,option,context,rule)
    if type(context)~='table' or context.stale or type(rule)~='table' then return nil end
    local manual=manualSpecializationContext(context)
    local points=manual and specializationPoints(self,context) or context.disenchantSpecializationPoints
    local learned=manual and context.learnedSpecializations or context.disenchantLearnedSpecializations
    local pre=manual and (context.preSpecializationSkill or context.simulatedBaseSkill or context.skill)
        or context.preSpecializationSkill
    if not finite(pre) or type(points)~='table' or (not manual and context.disenchantSpecializationKnown~=true) then return nil end
    local skillContext={learnedSpecializations=learned}
    local bonus,child,seen=0,nil,{}
    for _,skillRule in ipairs(specializationRules(self,f,option,context)) do
        if skillRule.kind=='skill-per-point' and (skillRule.nodeID==rule.rootNodeID or skillRule.nodeID==rule.childNodeID) then
            if seen[skillRule.nodeID] then return nil end
            seen[skillRule.nodeID]=true
            local rank=selectedRank(skillRule,points)
            local value=rank and specializationSkillContribution(skillRule,rank,skillContext)
            if not finite(value) then return nil end
            bonus=bonus+value
            if skillRule.nodeID==rule.childNodeID then child=rank end
        end
    end
    if not seen[rule.rootNodeID] or not seen[rule.childNodeID] or not finite(pre+bonus) then return nil end
    return {effectiveSkill=pre+bonus,preSpecializationSkill=pre,specializationSkillBonus=bonus,childPoints=child}
end
local function selectedDisenchantBaseline(self,f,option,context,mode)
    local selected
    for _,baseline in ipairs(self.ItemDB and self.ItemDB.modeledDisenchantBaselines or {}) do
        local rule=baseline.rule
        if usable(rule) and rule.applyPolicy=='EXECUTE' and rule.method==option.name
            and rule.profession==context.profession and rule.expansionID==f.expansionID
            and rule.inputRarity==f.quality and baseline.inputClassID==f.classID
            and self:ProfessionRuleMatchesBuild(rule) and self:EvidenceSourceWeight(rule.sourceKey,mode)>0 then
            if selected then return nil end
            selected=baseline
        end
    end
    return selected
end

-- An opt-in, exact-input source-table vector may supply the declared unknown-
-- profile zero reference. It is not an observed minimum-skill cohort. Project
-- only its own term before evidence fusion; the post-fusion adapter retains
-- these weighted primary terms and adds native unlock outcomes once.
function LL:ProjectReviewedDisenchantPrior(f,option,model,context,mode)
    if type(model)~='table' or model.reviewedBacklogModel~=true
        or model.reviewedDisenchantProjection~='source-anchored' or model.reviewedDisenchantProjected then return model end
    local function blocked(reason)
        if model.requiresSourceNormalization~=true then return model end
        local result=copy(model)
        result.projectionIncomplete=true;result.normalizationFailure=reason
        result.reviewedDisenchantProjectionFailed=true
        return result
    end
    context=context or (type(option)=='table' and self.ProcessingPlayerConditions
        and self:ProcessingPlayerConditions(f,option.name,option.recipeID,option.character))
    if type(f)~='table' or f.expansionID~=11 or type(option)~='table' or option.name~='Disenchant'
        or option.recipeID~=13262 or type(model)~='table' or type(context)~='table'
        or context.profession~='Enchanting'
        or model.baselineProfileAssumed~=true or model.inputItemID~=f.id or model.inputCount~=1
        or mode==2 or not self.EvidenceSourceWeight or self:EvidenceSourceWeight('itemdb',mode)<=0 then
        return blocked('Reviewed disenchant prior requires its exact input, enabled source policy and a current profession profile')
    end
    local source=model.baselineProfile
    if type(source)~='table' or source.skill~=0 or source.preSpecializationSkill~=0 then
        return blocked('Reviewed disenchant prior has no declared unknown-profile zero reference')
    end
    for _,values in ipairs({source.stats or {},source.specializationPoints or {},source.learnedSpecializations or {}}) do
        if type(values)~='table' or next(values) then return blocked('Known source stats or specialization need their own identified inverse') end
    end
    local reported=source.sourceReportedProfile
    if type(reported)=='table' and (reported.skill~=nil or reported.specialization~=nil or reported.stats~=nil) then
        return blocked('Known reported source profile cannot be substituted by an unknown zero reference')
    end
    local selected=selectedDisenchantBaseline(self,f,option,context,mode)
    if not selected then return blocked('No unique enabled native disenchant rule matches this input category and build') end
    local profile=self:DisenchantForwardProfile(f,option,context,selected.rule)
    if not profile then return blocked('Target skill or normalized specialization points are unknown or stale') end
    local actual=deAmounts(model.materials)
    local low,high=selected.rule.primaryRankIDs[1],selected.rule.primaryRankIDs[2]
    if not actual or not finite(actual[low]) or not finite(actual[high]) or actual[low]+actual[high]<=0 then
        return blocked('Reviewed source must explicitly identify the complete native primary rank family with positive total units')
    end
    local baseline=copy(selected)
    local base=deAmounts(baseline.materials)
    if not base then return blocked('Native model baseline quantities are invalid') end
    for id,quantity in pairs(actual) do
        if id~=low and id~=high and (quantity~=0 or base[id]==nil) then
            return blocked('Source extra outputs conflict with the declared before-unlock zero reference')
        end
    end
    for _,material in ipairs(baseline.materials) do
        if material.id==low or material.id==high then material.expectedQuantity=actual[material.id] end
    end
    if baseline.rule.preservePrimaryTotal then
        local endpoint=deAmounts(baseline.endpointMaterials)
        if not endpoint or not finite(endpoint[low]) or not finite(endpoint[high]) or endpoint[low]+endpoint[high]<=0 then
            return blocked('Native primary quality endpoint is incomplete')
        end
        local total=actual[low]+actual[high]
        local share=endpoint[high]/(endpoint[low]+endpoint[high])
        for _,material in ipairs(baseline.endpointMaterials) do
            if material.id==low then material.expectedQuantity=total*(1-share)
            elseif material.id==high then material.expectedQuantity=total*share end
        end
    end
    baseline.confidence=0
    local projected,progress=self:DisenchantCurveQuantities(baseline,profile)
    if not projected then return blocked('Native disenchant curve cannot project this declared source reference') end
    local byID={} for _,material in ipairs(projected) do byID[material.id]=material end
    local result=copy(model)
    for _,material in ipairs(result.materials) do
        local adjusted=byID[material.id]
        if not adjusted then return blocked('Source output has no matching native model outcome') end
        local distribution=deDistribution(material,{expectedQuantity=adjusted.expectedQuantity,confidence=0},
            (baseline.rule.preservePrimaryTotal or progress.quantity==0) and (material.id==low or material.id==high))
        material.expectedQuantity=adjusted.expectedQuantity
        material.confidence=0
        material.chance=distribution.chance;material.probabilityVerified=distribution.probabilityVerified
        material.minQuantity=distribution.minQuantity;material.maxQuantity=distribution.maxQuantity
        material.quantityCounts=nil;material.histogram=nil;material.personalHistogram=nil
        material.fieldEvidence=nil;material.samples=nil;material.castsWithDrop=nil;material.totalQuantity=nil
        material.boundsBasis=nil;material.boundsSource=nil;material.chanceConfidence=distribution.chanceConfidence;material.chanceCasts=nil
        material.probabilityBasis=distribution.probabilityBasis
        material.probabilityAssumption=distribution.probabilityAssumption
        material.netUnitPrice=nil;material.netExpectedValue=nil
        material.reviewedDisenchantProjected=true
    end
    result.reviewedDisenchantProjected=true
    result.projectionIncomplete=nil;result.normalizationFailure=nil;result.reviewedDisenchantProjectionFailed=nil
    result.professionProjected=true;result.specializationEffectsApplied=true
    result.projectedContext=copy(context)
    result.projectedContext.effectiveSkill=profile.effectiveSkill
    result.projectedContext.preSpecializationSkill=profile.preSpecializationSkill
    result.projectedContext.specializationSkillBonus=profile.specializationSkillBonus
    result.disenchantProgress=progress
    result.reviewedDisenchantSourceReference={recordID=model.recordID,
        sourceProfileAssumed=true,referenceKind='declared-unknown-profile-zero-reference',
        observedZeroProfileClaim=false,observedSamplesAdded=0,
        currentVariantEqualityVerified=false,
        sourcePrimaryMaterials=copy(model.materials),ruleID=selected.rule.ruleID}
    result.confidence=0;result.ruleConfidence=0;result.numericTransformApplied=true
    result.value=nil;result.partialValue=nil;result.valueConfidence=nil
    return result
end
-- Consume only the compiler's model baseline, not an arbitrary selected source
-- mean. Source observations/counts remain immutable and are never projected twice.
function LL:ApplyDisenchantBaseline(f,option,model,context,mode)
    if type(f)~='table' or type(option)~='table' or option.name~='Disenchant'
        or (option.recipeID~=nil and option.recipeID~=13262) or type(context)~='table'
        or context.profession~='Enchanting' or mode==2 or model and model.disenchantBaselineApplied then return model end
    if not self.EvidenceSourceWeight or self:EvidenceSourceWeight('itemdb',mode)<=0 then return model end
    if model and model.sources and ((model.sources.personal or 0)>0 or (model.sources.imported or 0)>0) then return model end
    local selected=selectedDisenchantBaseline(self,f,option,context,mode)
    if not selected then return model end
    local profile=self:DisenchantForwardProfile(f,option,context,selected.rule)
    local materials,progress
    if profile then materials,progress=self:DisenchantCurveQuantities(selected,profile) end
    if not materials then return model end
    local projectedContext=copy(context)
    projectedContext.effectiveSkill=profile.effectiveSkill
    projectedContext.preSpecializationSkill=profile.preSpecializationSkill
    projectedContext.specializationSkillBonus=profile.specializationSkillBonus
    local confidence=selected.confidence or selected.rule.confidence0to100
    -- Keep the evidence pipeline's per-material source weights. Replace only
    -- the ItemDB term when compatible legacy/reference means also contributed.
    local mixed=false
    for key,weight in pairs(model and model.sources or {}) do if key~='itemdb' and weight>0 then mixed=true end end
    local reviewedPrimary,sourcePrimaryTotal,unprojectedPrimaryTotal=false,0,0
    local primary={}
    for _,id in ipairs(selected.rule.primaryRankIDs or {}) do primary[id]=true end
    for _,original in ipairs(model and model.materials or {}) do
        local source=original.sourceEstimates and original.sourceEstimates.itemdb
        if primary[original.id] and source and finite(source.expectedQuantity)
            and finite(source.inputCount) and source.inputCount>0 then
            local unprojected=source.unprojectedDisenchantExpectedQuantity
            if unprojected~=nil then
                if not finite(unprojected) or unprojected>source.expectedQuantity+1e-9 then return model end
                reviewedPrimary=true
            else unprojected=source.expectedQuantity end
            sourcePrimaryTotal=sourcePrimaryTotal+source.expectedQuantity/source.inputCount
            unprojectedPrimaryTotal=unprojectedPrimaryTotal+unprojected/source.inputCount
        end
    end
    -- Scale the ordinary quantity term against the canonical ZERO pool, not
    -- against a mixed pool that includes differently sized reviewed priors.
    -- The latter would change an otherwise identical zero-profile fusion.
    local canonicalBase=deAmounts(selected.materials)
    local canonicalPrimaryTotal=canonicalBase and ((canonicalBase[selected.rule.primaryRankIDs[1]] or 0)
        +(canonicalBase[selected.rule.primaryRankIDs[2]] or 0)) or 0
    local ordinaryShare=canonicalPrimaryTotal>0 and unprojectedPrimaryTotal/canonicalPrimaryTotal or 0
    if mixed or reviewedPrimary then
        local byID={}
        for _,material in ipairs(materials) do byID[material.id]=material end
        -- A newly introduced rank or bonus has no per-material contribution
        -- row yet. Give it only the selected ItemDB primary family's share,
        -- rather than a full-strength bonus beside mostly legacy evidence.
        local originalIDs,primarySum,weightedPrimary={},0,0
        for _,original in ipairs(model.materials or {}) do
            originalIDs[original.id]=true
            local weight=original.sourceContributions and original.sourceContributions.itemdb
            local source=original.sourceEstimates and original.sourceEstimates.itemdb
            if primary[original.id] and finite(weight) and weight>=0 and weight<=1
                and source and finite(source.expectedQuantity) and source.expectedQuantity>=0
                and finite(source.inputCount) and source.inputCount>0 then
                local quantity=source.expectedQuantity/source.inputCount
                primarySum=primarySum+quantity;weightedPrimary=weightedPrimary+quantity*weight
            end
        end
        local familyWeight=primarySum>0 and weightedPrimary/primarySum or 0
        for id,projected in pairs(byID) do
            if not originalIDs[id] then projected.expectedQuantity=projected.expectedQuantity*familyWeight end
        end
        for _,original in ipairs(model.materials or {}) do
            if type(original.rankIDs)=='table' then
                for _,id in ipairs(original.rankIDs) do if byID[id] then return model end end
            end
            local projected=byID[original.id]
            if projected then
                local weight=original.sourceContributions and original.sourceContributions.itemdb or 0
                local source=original.sourceEstimates and original.sourceEstimates.itemdb
                if finite(original.expectedQuantity) and finite(weight) and weight>0 and weight<=1
                    and source and finite(source.expectedQuantity) and finite(source.inputCount) and source.inputCount>0 then
                    local replacement=projected.expectedQuantity
                    if reviewedPrimary and primary[original.id] then
                        local unprojected=source.unprojectedDisenchantExpectedQuantity
                        if unprojected==nil then unprojected=source.expectedQuantity end
                        replacement=(source.expectedQuantity-unprojected)/source.inputCount+replacement*ordinaryShare
                    end
                    projected.expectedQuantity=original.expectedQuantity+weight*(replacement-source.expectedQuantity/source.inputCount)
                    if projected.expectedQuantity<0 and projected.expectedQuantity>-1e-9 then projected.expectedQuantity=0 end
                    if not finite(projected.expectedQuantity) then return model end
                    projected.confidence=math.min(projected.confidence or confidence,original.confidence or confidence)
                    projected.chance=nil;projected.minQuantity=nil;projected.maxQuantity=nil
                    projected.chanceConfidence=nil;projected.probabilityBasis=nil;projected.probabilityVerified=nil
                    projected.probabilityAssumption=nil
                    deDistribution(original,projected,(selected.rule.preservePrimaryTotal or progress.quantity==0)
                        and primary[original.id] and deFixedStackContributors(original))
                    projected.sourceEstimates=copy(original.sourceEstimates)
                    projected.sourceContributions=copy(original.sourceContributions)
                else
                    byID[original.id]=copy(original)
                end
            else byID[original.id]=copy(original) end
        end
        materials={}
        for _,material in pairs(byID) do materials[#materials+1]=material end
        table.sort(materials,function(a,b) return a.id<b.id end)
        confidence=math.min(confidence,model.confidence or confidence)
    end
    local result={kind='profession-baseline',inputCount=1,materials=materials,context=projectedContext,
        source='ItemDB',sources={itemdb=1},confidence=confidence,ruleConfidence=confidence,
        provisional=true,simulated=context.simulated,professionProjected=true,specializationEffectsApplied=true,
        disenchantBaselineApplied=true,disenchantBaselineID=selected.recordID,
        baselineProfile=copy(selected.baselineProfile),projectedContext=copy(profile),
        disenchantProgress=progress,specializationSkillBonus=profile.specializationSkillBonus,
        specializationAppliedRules={selected.rule.ruleID},specializationSources=copy(selected.rule.sourceClaimIDs),
        adjustment='Profession profile',unknownOutputs=selected.unknownOutputs or false}
    if mixed then
        result.sources=copy(model.sources);result.source=model.source
        result.unknownOutputs=result.unknownOutputs or model.unknownOutputs
    end
    if reviewedPrimary then result.reviewedDisenchantProjected=true end
    return result
end

-- Describe controls that can reach an executable outcome calculation. The
-- complete catalog and saved profile remain intact; this is presentation
-- capability, independent of the selected points or source preferences.
function LL:GetProfessionSimulationControlSupport(profession,expansion,nodes)
    local support={skill=false,nodes={},stats={},buffs={},dependencyNodes={},skillDependency=false,nodeEffects={},
        unquantifiedNodes={},nodeDescriptions={}}
    local db=self.ItemDB
    local build=GetBuildInfo and select(2,GetBuildInfo())
    if type(db)~='table' or build==nil then return support end
    local methodProfessions={Disenchant='Enchanting',Mill='Inscription',Prospect='Jewelcrafting',Smelt='Mining'}
    local function positive(value) return finite(value) and value>0 end
    local function identity(value) return positive(value) and value%1==0 end
    if nodes==nil then
        local bundled=self.ProfessionCatalog and self.ProfessionCatalog[profession..':'..tostring(expansion)]
        nodes=bundled and bundled.nodes
    end
    local catalog={}
    for _,node in ipairs(type(nodes)=='table' and nodes or {}) do
        if type(node)=='table' and identity(node.id) and identity(node.maxRank) then catalog[node.id]=node end
    end
    local function ruleScope(rule,strict)
        return usable(rule) and type(rule.ruleID)=='string' and rule.ruleID~=''
            and (not strict or rule.applyPolicy=='EXECUTE')
            and (rule.profession or methodProfessions[rule.method])==profession
            and rule.expansionID==expansion
            and self:ProfessionRuleMatchesBuild(rule)
            and (rule.inputItemIDs==nil or type(rule.inputItemIDs)=='table')
            and (rule.inputQualityRanks==nil or type(rule.inputQualityRanks)=='table')
    end
    local function listHas(list,value)
        for _,entry in ipairs(list or {}) do if entry==value then return true end end
        return false
    end
    local function fieldValue(field)
        if type(field)~='table' or field.status=='unknown' or field.status=='contradictory' then return nil end
        return finite(field.value) and field.value or nil
    end
    local function overlaps(a,b)
        for _,key in ipairs({'recipeID','inputRarity','inputClassID','inputQualityRank','inputItemID'}) do
            if a[key]~=nil and b[key]~=nil and a[key]~=b[key] then return false end
        end
        for _,pair in ipairs({{'inputItemID','inputItemIDs'},{'inputQualityRank','inputQualityRanks'}}) do
            local one,many=pair[1],pair[2]
            if a[one]~=nil and b[many] and not listHas(b[many],a[one]) then return false end
            if b[one]~=nil and a[many] and not listHas(a[many],b[one]) then return false end
            if a[many] and b[many] then
                local shared=false
                for _,value in ipairs(a[many]) do if listHas(b[many],value) then shared=true end end
                if not shared then return false end
            end
        end
        return true
    end
    local records={}
    for _,dataset in ipairs({db,db.legacy or {}}) do
        for _,record in ipairs(dataset.processing or {}) do
            local consistent=type(record)=='table'
            if consistent and record.gearKey~=nil then
                local era,rarity,kind
                if type(record.gearKey)=='string' then era,rarity,kind=record.gearKey:match('^gear:(%d+):(%d+):(%a+)$') end
                era=tonumber(era);rarity=tonumber(rarity)
                local class=kind=='weapon' and 2 or kind=='armor' and 4 or nil
                consistent=era~=nil and rarity~=nil and class~=nil
                    and (record.expansionID==nil or record.expansionID==era)
                    and (record.inputRarity==nil or record.inputRarity==rarity)
                    and (record.inputClassID==nil or record.inputClassID==class)
                if consistent then
                    local original=record;record={}
                    for key,value in pairs(original) do record[key]=value end
                    record.expansionID=era;record.inputRarity=rarity;record.inputClassID=class
                end
            end
            if consistent and methodProfessions[record.method]==profession
                and (record.expansionID==nil or record.expansionID==expansion)
                and (record.targetBuild==nil or tostring(record.targetBuild)==tostring(build))
                and (record.patchStartBuild==nil or tonumber(build) and tonumber(build)>=record.patchStartBuild) then
                local hint=record.inputItemID and db.inputs and db.inputs[record.inputItemID]
                if record.expansionID~=nil or not hint or hint.expansion==nil or hint.expansion==expansion then
                    records[#records+1]=record
                end
            end
        end
    end
    local function baselineFor(rule,predicate)
        for _,record in ipairs(records) do
            if record.method==rule.method and overlaps(rule,record) and predicate(record) then return record end
        end
    end
    local function mean(material)
        if material.conditionalReference or material.conditionalRequirement then return false end
        if positive(fieldValue(material.expectedQuantity)) then return true end
        -- The resolver also admits its existing P(hit) times stated midpoint
        -- estimate when a measured expected quantity is absent.
        local p,lo,hi=fieldValue(material.dropChance),fieldValue(material.minQuantity),fieldValue(material.maxQuantity)
        return positive(p) and p<=1 and positive(lo) and positive(hi) and hi>=lo
    end
    local function familyMatches(material,family)
        if type(family)~='table' or not identity(family.id)
            or family.rankIDs~=nil and type(family.rankIDs)~='table' then return false end
        if material.rankIDs then
            if type(family.rankIDs)~='table' or #material.rankIDs~=#family.rankIDs then return false end
            for _,id in ipairs(material.rankIDs) do if not listHas(family.rankIDs,id) then return false end end
            return true
        end
        return material.id==family.id or listHas(family.rankIDs,material.id)
    end
    local function anyMean(record,family)
        for _,material in ipairs(record.materials or {}) do
            if mean(material) and (not family or familyMatches(material,family)) then return true end
        end
        return false
    end
    local function showNode(id,ruleID,dependency)
        if not identity(tonumber(id)) then return end
        id=tostring(id)
        support.nodes[id]=true
        if dependency then support.dependencyNodes[id]=true end
        support.nodeEffects[id]=support.nodeEffects[id] or {}
        if ruleID and not listHas(support.nodeEffects[id],ruleID) then
            support.nodeEffects[id][#support.nodeEffects[id]+1]=ruleID
        end
    end
    local skillModels={}
    local quality={}
    for _,rule in ipairs(db.skillQualityRules or {}) do
        if ruleScope(rule,true) and rule.formulaID=='EXACT_INPUT_QUALITY_THRESHOLD'
            and rule.maxQuality==2 and rule.requireExactOperationContext==true
            and rule.quantityPolicy=='PRESERVE_SELECTED_FAMILY_EXPECTATION'
            and identity(rule.recipeID) and type(rule.inputQualityRanks)=='table' and #rule.inputQualityRanks>0 then
            quality[#quality+1]=rule
        end
    end
    for _,rule in ipairs(quality) do
        local ambiguous=false
        for _,other in ipairs(quality) do
            if other~=rule and other.method==rule.method and overlaps(rule,other) then ambiguous=true end
        end
        local record=not ambiguous and baselineFor(rule,function(candidate)
            for _,material in ipairs(candidate.materials or {}) do
                if mean(material) and type(material.rankIDs)=='table' and #material.rankIDs==2 then
                    for _,family in ipairs(rule.outputFamilies or {}) do
                        local ids=family.rankItemIDs
                        if type(ids)=='table' and #ids==2 and identity(ids[1]) and identity(ids[2]) and ids[1]~=ids[2]
                            and listHas(ids,material.rankIDs[1]) and listHas(ids,material.rankIDs[2]) then return true end
                    end
                end
            end
            return false
        end)
        if record then support.skill=true;skillModels[#skillModels+1]={rule=rule,record=record} end
    end
    for _,rule in ipairs(db.professionRules or {}) do
        if ruleScope(rule,false) and tostring(rule.build)==tostring(build)
            and identity(rule.recipeID) and identity(rule.inputItemID) and identity(rule.outputItemID)
            and type(rule.referenceProfile)=='table' and type(rule.skillFactors)=='table' and #rule.skillFactors>0 then
            local valid,varies,previous,first=true,false,nil,nil
            for _,point in ipairs(rule.skillFactors) do
                if type(point)~='table' or not finite(point.skill) or not positive(point.factor)
                    or previous and point.skill<=previous then valid=false;break end
                if first and first~=point.factor then varies=true end
                first=first or point.factor;previous=point.skill
            end
            local record=valid and baselineFor(rule,function(candidate)
                if candidate.sourceKey~='itemdb' or tostring(candidate.patchBuild)~=tostring(build)
                    or type(candidate.baselineProfile)~='table' then return false end
                for _,material in ipairs(candidate.materials or {}) do
                    if material.id==rule.outputItemID and mean(material) then return true end
                end
                return false
            end)
            if record and self:ProfessionFactor(rule,record.baselineProfile) then
                if varies then support.skill=true;skillModels[#skillModels+1]={rule=rule,record=record} end
                local factors=rule.specializationFactors
                if type(factors)=='table' then
                    local allocations={}
                    for signature,factor in pairs(factors) do
                        local points=self.ProfessionSpecializationPoints and self:ProfessionSpecializationPoints(signature)
                        if positive(factor) and type(points)=='table' then allocations[#allocations+1]={points=points,factor=factor} end
                    end
                    for _,a in ipairs(allocations) do for _,b in ipairs(allocations) do
                        if a.factor~=b.factor then
                            for id,rank in pairs(a.points) do if rank~=(b.points[id] or 0) then showNode(id,rule.ruleID) end end
                            for id,rank in pairs(b.points) do if rank~=(a.points[id] or 0) then showNode(id,rule.ruleID) end end
                        end
                    end end
                end
            end
        end
    end
    local special,counts={},{ }
    for _,rule in ipairs(db.specializationRules or {}) do
        if ruleScope(rule,true) then
            special[#special+1]=rule;counts[rule.ruleID]=(counts[rule.ruleID] or 0)+1
        end
    end
    for _,rule in ipairs(special) do
        local node=catalog[rule.nodeID]
        local validNode=identity(rule.nodeID) and identity(rule.maxRank)
            and (nodes==nil or node~=nil) and (not node or node.maxRank==rule.maxRank)
        if counts[rule.ruleID]==1 then
            if rule.kind=='reference-context' and type(rule.requiredNodes)=='table' and type(rule.referenceContextID)=='string' then
                local valid,required=rule.requiredNodeCaps==nil or type(rule.requiredNodeCaps)=='table',0
                for id,rank in pairs(rule.requiredNodes) do
                    required=required+1
                    local n=catalog[tonumber(id)]
                    local cap=type(rule.requiredNodeCaps)=='table' and rule.requiredNodeCaps[tostring(id)] or rank
                    if not identity(tonumber(id)) or not identity(rank) or nodes~=nil and not n or n and rank>n.maxRank
                        or not identity(cap) or cap<rank then valid=false end
                end
                local record=valid and required>0 and baselineFor(rule,function(candidate)
                    return candidate.referenceContextID==rule.referenceContextID and anyMean(candidate)
                end)
                if record then for id in pairs(rule.requiredNodes) do showNode(id,rule.ruleID) end end
            elseif validNode and rule.kind=='skill-per-point' and positive(rule.perPoint) then
                local calculated=false
                for _,model in ipairs(skillModels) do
                    local acceptsPoints=model.rule.formulaID=='EXACT_INPUT_QUALITY_THRESHOLD'
                    -- ProfessionFactor requires an explicit specialization
                    -- mapping before it can accept a changed allocation. A
                    -- skill curve alone cannot consume arbitrary node points.
                    if not acceptsPoints and type(model.rule.specializationFactors)=='table' then
                        local prior
                        for signature,factor in pairs(model.rule.specializationFactors) do
                            local allocation=self.ProfessionSpecializationPoints and self:ProfessionSpecializationPoints(signature)
                            if positive(factor) and allocation then
                                local rank=allocation[tostring(rule.nodeID)] or 0
                                if prior~=nil and prior~=rank then acceptsPoints=true end
                                prior=rank
                            end
                        end
                    end
                    if acceptsPoints and model.rule.method==rule.method and overlaps(rule,model.rule) and overlaps(rule,model.record) then
                        showNode(rule.nodeID,rule.ruleID)
                        calculated=true
                    end
                end
                if not calculated and baselineFor(rule,function(record) return anyMean(record) end) then
                    showNode(rule.nodeID,rule.ruleID)
                    support.unquantifiedNodes[tostring(rule.nodeID)]=true
                    support.skill=true
                end
            elseif validNode and rule.kind=='replace-family' and positive(rule.perPoint)
                and rule.perPoint*rule.maxRank<=1 and type(rule.targetFamily)=='table'
                and identity(rule.targetFamily.id) and type(rule.sourceFamily)=='table'
                and rule.sourceFamily.id~=rule.targetFamily.id
                and baselineFor(rule,function(record) return anyMean(record,rule.sourceFamily) end) then
                showNode(rule.nodeID,rule.ruleID)
            elseif validNode and rule.kind=='quantity-multiplier' then
                local valid=(rule.perPoint==nil or finite(rule.perPoint))
                    and (rule.milestones==nil or type(rule.milestones)=='table')
                local ranks={1,rule.maxRank}
                for _,milestone in ipairs(valid and rule.milestones or {}) do
                    if type(milestone)~='table' or not identity(milestone.rank)
                        or milestone.rank>rule.maxRank or not positive(milestone.multiplier) then valid=false
                    else
                        ranks[#ranks+1]=milestone.rank;ranks[#ranks+1]=math.max(0,milestone.rank-1)
                    end
                end
                local changes=false
                if valid then for _,rank in ipairs(ranks) do
                    local factor=multiplierAt(rule,rank)
                    if not factor then valid=false elseif factor~=1 then changes=true end
                end end
                if valid and changes and baselineFor(rule,function(record) return anyMean(record,rule.outputFamily) end) then
                    showNode(rule.nodeID,rule.ruleID)
                end
            end
        end
    end
    for _,effect in ipairs(db.specializationDescriptions or {}) do
        local node=catalog[effect.nodeID]
        if describedEffectValid(self,effect) and effect.profession==profession and effect.expansionID==expansion
            and node and node.maxRank==effect.maxRank
            and baselineFor(effect,function(record) return anyMean(record) end) then
            showNode(effect.nodeID)
            local id=tostring(effect.nodeID)
            support.unquantifiedNodes[id]=true
            support.nodeDescriptions[id]=support.nodeDescriptions[id] or {}
            support.nodeDescriptions[id][#support.nodeDescriptions[id]+1]=effect.description
        end
    end
    for _,baseline in ipairs(db.modeledDisenchantBaselines or {}) do
        local rule=baseline.rule
        if ruleScope(rule,true) and type(baseline.materials)=='table' and type(baseline.endpointMaterials)=='table' then
            support.skill=true
            for _,nodeID in ipairs({rule.rootNodeID,rule.childNodeID}) do
                local node=catalog[nodeID]
                if node then
                    showNode(nodeID,rule.ruleID)
                    support.unquantifiedNodes[tostring(nodeID)]=nil
                    support.nodeDescriptions[tostring(nodeID)]={'Adjusts disenchant material quality and applicable quantity milestones.'}
                end
            end
        end
    end
    -- Existing context-specific mechanic rules can consume typed stat/buff
    -- values. Mere captured stats or a fixed profession reference profile do
    -- not establish an effect and never reveal a control by themselves.
    local statKeys,statNames={},{ }
    for _,stat in ipairs(self.ProfessionSimulationStats or {}) do statKeys[stat.key]=true;statNames[stat.name]=stat.key end
    local function showStat(key,field,value)
        if statKeys[key] and (field=='rating' or field=='percent') and finite(value) then
            support.stats[key]=support.stats[key] or {};support.stats[key][field]=true
        end
    end
    local function manualConditionsReachable(rule,conditions)
        local constants={simulated=true,profileKind='manual-simulation',stale=false,qualityFromBlizzard=false,
            assumedMinimum=false,skillKnown=false,skillSource='manual-simulation',incomplete=false,
            profession=profession,expansionID=expansion,recipeID=rule.recipeID,inputID=rule.inputItemID,
            inputQuality=rule.inputQualityRank,inputRarity=rule.inputRarity,inputClassID=rule.inputClassID,
            character=self.CharacterKey and self:CharacterKey()}
        local editable={stats=true,operationStats=true,buffs=true,specialization=true,skill=true,effectiveSkill=true}
        for key,value in pairs(conditions) do
            if not editable[key] and not equal(constants[key],value) then return false end
        end
        if conditions.skill~=nil and not finite(conditions.skill)
            or conditions.effectiveSkill~=nil and not finite(conditions.effectiveSkill) then return false end
        local stats={}
        for key,values in pairs(type(conditions.stats)=='table' and conditions.stats or {}) do
            if not statKeys[key] or type(values)~='table' then return false end
            for field,value in pairs(values) do
                if (field~='rating' and field~='percent') or not finite(value)
                    or field=='percent' and self.IsProfessionChanceStat and self:IsProfessionChanceStat(key) and value>100 then return false end
            end
            stats[key]=copy(values)
        end
        if conditions.stats~=nil and type(conditions.stats)~='table' then return false end
        if conditions.operationStats~=nil then
            if type(conditions.operationStats)~='table' or not self.SimulatedProfessionOperationStats then return false end
            for _,stat in ipairs(conditions.operationStats) do
                if type(stat)~='table' or not statKeys[stat.statKey] then return false end
                stats[stat.statKey]=stats[stat.statKey] or {}
                for field,value in pairs({rating=stat.bonusStatValue,percent=stat.ratingPct}) do
                    if not finite(value) or stats[stat.statKey][field]~=nil and stats[stat.statKey][field]~=value then return false end
                    stats[stat.statKey][field]=value
                end
            end
            if conditions.stats~=nil and not equal(stats,conditions.stats)
                or not equal(self:SimulatedProfessionOperationStats({stats=stats}),conditions.operationStats) then return false end
        end
        if conditions.buffs~=nil then
            if type(conditions.buffs)~='table' or not next(conditions.buffs) then return false end
            for id,on in pairs(conditions.buffs) do
                if type(id)~='string' or not identity(tonumber(id)) or tostring(tonumber(id))~=id or on~=true then return false end
            end
        end
        if conditions.specialization~=nil and (not self.ProfessionSpecializationPoints
            or not self:ProfessionSpecializationPoints(conditions.specialization)) then return false end
        return true
    end
    for _,rule in ipairs(db.mechanicRules or {}) do
        if ruleScope(rule,false) and rule.applies=='VERIFIED_APPLIES'
            and tostring(rule.targetBuild)==tostring(build) and identity(rule.recipeID)
            and identity(rule.inputItemID) and type(rule.sourceReferenceContextID)=='string' and rule.sourceReferenceContextID~=''
            and ((rule.method=='Disenchant' and identity(rule.inputRarity) and (rule.inputClassID==2 or rule.inputClassID==4))
                or rule.method~='Disenchant' and identity(rule.inputQualityRank))
            and type(rule.targetConditions)=='table' and type(rule.parameters)=='table'
            and manualConditionsReachable(rule,rule.targetConditions) then
            local target,params=rule.effectTarget,rule.parameters
            local multiply=rule.formulaID=='MULTIPLY' and finite(params.multiplier) and params.multiplier<=10 and params.multiplier~=1
            local record=baselineFor(rule,function(candidate)
                if candidate.sourceKey~='itemdb' or tostring(candidate.patchBuild)~=tostring(rule.sourceBuild)
                    or candidate.referenceContextID~=rule.sourceReferenceContextID then return false end
                if target=='EXPECTED_INPUT_CONSUMPTION' then
                    return (rule.method=='Mill' or rule.method=='Prospect') and multiply
                        and params.multiplier<1 and positive(candidate.inputCount)
                end
                for _,material in ipairs(candidate.materials or {}) do
                    if material.id==rule.outputItemID then
                        if target=='OUTPUT_UNCONDITIONAL_EXPECTATION' then return multiply and mean(material) end
                        local probability=fieldValue(material.dropChance)
                        if target=='OUTPUT_OCCURRENCE' then
                            return multiply and positive(probability) and probability<=1 and probability*params.multiplier<=1
                                and (material.dropChance.status=='measured' or material.dropChance.status=='verified')
                        end
                        if target=='OUTPUT_POSITIVE_QUANTITY' and rule.formulaID=='SET_VERIFIED_RANGE' then
                            return identity(params.minQuantity) and identity(params.maxQuantity) and params.maxQuantity>=params.minQuantity
                                and (fieldValue(material.minQuantity)~=params.minQuantity or fieldValue(material.maxQuantity)~=params.maxQuantity)
                        end
                    end
                end
                return false
            end)
            if record then
                local conditions=rule.targetConditions
                if finite(conditions.skill) or finite(conditions.effectiveSkill) then support.skill=true end
                if type(conditions.specialization)=='string' then
                    local points=self.ProfessionSpecializationPoints and self:ProfessionSpecializationPoints(conditions.specialization)
                    for id,rank in pairs(points or {}) do if rank>0 then showNode(id,rule.ruleID) end end
                end
                for key,values in pairs(type(conditions.stats)=='table' and conditions.stats or {}) do
                    if type(values)=='table' then showStat(key,'rating',values.rating);showStat(key,'percent',values.percent) end
                end
                for _,stat in ipairs(type(conditions.operationStats)=='table' and conditions.operationStats or {}) do
                    if type(stat)=='table' then
                        local key=stat.statKey or statNames[stat.bonusStatName]
                        showStat(key,'rating',stat.bonusStatValue);showStat(key,'percent',stat.ratingPct)
                    end
                end
                for id,on in pairs(type(conditions.buffs)=='table' and conditions.buffs or {}) do
                    if on==true and identity(tonumber(id)) then support.buffs[tostring(id)]=true end
                end
            end
        end
    end
    -- A prerequisite is useful only when it unlocks an actual calculated
    -- control. Catalog parent edges alone never reveal otherwise inert sliders.
    local changed=true
    while changed do
        changed=false
        for id in pairs(support.nodes) do
            local node=catalog[tonumber(id)]
            for _,requirement in ipairs(node and node.requirements or {}) do
                if type(requirement)=='table' and requirement.kind=='node' and identity(requirement.nodeID) and positive(requirement.rank)
                    and catalog[requirement.nodeID] and not support.nodes[tostring(requirement.nodeID)] then
                    showNode(requirement.nodeID,nil,true);changed=true
                elseif type(requirement)=='table' and requirement.kind=='skill' and positive(requirement.skill) then
                    if not support.skill then support.skillDependency=true end
                    support.skill=true
                end
            end
        end
    end
    local generic=db.professionProfiles
    local genericProfile=generic and generic.profiles and generic.profiles[profession..':'..tostring(expansion)]
    if genericProfile and self:ProfessionRuleMatchesBuild(generic) then
        support.skill=true
        for id in pairs(genericProfile.nodes or {}) do
            support.nodes[tostring(id)]=true
            support.unquantifiedNodes[tostring(id)]=nil
        end
        for _,key in ipairs(genericProfile.statKeys or {}) do
            if key~='skill' then support.stats[key]={rating=true,percent=true} end
        end
        local function includeBuffs(effects)
            for _,effect in ipairs(effects or {}) do
                for _,id in ipairs(effect.condition and effect.condition.spellIDs or {}) do support.buffs[tostring(id)]=true end
            end
        end
        for _,node in pairs(genericProfile.nodes or {}) do
            includeBuffs(node.pointEffects);includeBuffs(node.learningEffects)
            for _,milestone in ipairs(node.milestones or {}) do includeBuffs(milestone.effects) end
        end
    end
    return support
end
