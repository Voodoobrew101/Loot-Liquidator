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
local function matches(r,f,option,id)
    return r.method==option.name and r.recipeID==option.recipeID and r.inputItemID==f.id
        and r.outputItemID==id and r.expansionID==f.expansionID
        and (r.inputQualityRank==nil or r.inputQualityRank==f.reagentQuality)
end
function LL:ValidateProfessionRules(db)
    local ids={}
    local function identity(r)
        if not approved(r) or type(r.ruleID)~='string' or r.ruleID=='' or ids[r.ruleID]
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
        if approved(r) and matches(r,f,option,id) and tostring(r.build)==tostring(build) then
            if found then return nil,'Conflicting profession rules' end
            found=r
        end
    end
    return found,found and nil or 'No numeric profession rule'
end
local function scale(m,factor,ruleID)
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
            if sourceFactor and targetFactor and scale(m,targetFactor/sourceFactor,rule.ruleID) then applied=true else complete=false end
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
        if normalized then
            local rule=ruleFor(self,f,option,m.id,sourceBuild)
            if not rule then return nil,'No source-profile conversion rule' end
            local sf=self:ProfessionFactor(rule,source)
            local bf=self:ProfessionFactor(rule,rule.referenceProfile)
            if not sf or not bf then return nil,'Unknown source-profile factor' end
            historicalFactor=bf/sf
            result.projectionRules[#result.projectionRules+1]=rule.ruleID..':inverse'
        end
        local current=sourceBuild
        local visited={}
        while current~=targetBuild do
            if visited[current] then return nil,'Patch rule cycle' end
            visited[current]=true
            local found
            for _,r in ipairs(self.ItemDB and self.ItemDB.personalPatchRules or {}) do
                if approved(r) and matches(r,f,option,m.id) and tostring(r.fromBuild)==current then
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
                historicalFactor=historicalFactor*bf/sf;normalized=true
                result.projectionRules[#result.projectionRules+1]=rule.ruleID..':inverse'
            elseif found.basis~='baseline' and not equal(found.profile,source) then
                return nil,'Patch bridge profile mismatch'
            end
            historicalFactor=historicalFactor*found.expectedMultiplier
            result.projectionRules[#result.projectionRules+1]=found.ruleID
            current=tostring(found.toBuild)
        end
        if normalized then
            local rule=ruleFor(self,f,option,m.id,targetBuild)
            local tf=rule and self:ProfessionFactor(rule,target)
            local bf=rule and self:ProfessionFactor(rule,rule.referenceProfile)
            if not tf or not bf then return nil,'No target-profile conversion rule' end
            historicalFactor=historicalFactor*tf/bf
            result.projectionRules[#result.projectionRules+1]=rule.ruleID..':forward'
        end
        if not scale(m,historicalFactor,table.concat(result.projectionRules,', ')) then return nil,'Invalid projection' end
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
