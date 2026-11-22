local _,LL=...
-- Typed client effects feed one inverse/forward model. Observations, counts and
-- probability estimates are never rewritten by this module.
local function copy(v)
    if type(v)~='table' then return v end
    local r={} for k,x in pairs(v) do r[k]=copy(x) end return r
end
-- Scope probes only replace top-level identity/operation fields. Nested
-- facts may include whole quote graphs; they are read-only to these probes.
local function scopeCopy(value)
    local out={}for key,item in pairs(value or {})do out[key]=item end return out
end
local function number(v,default)
    return type(v)=='number' and v==v and math.abs(v)<math.huge and v or (default or 0)
end
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function lookup(t,k) return type(t)=='table' and (t[k] or t[tostring(k)]) or nil end
local function contains(t,x)
    for _,v in ipairs(t or {}) do if v==x then return true end end return false
end
local function intersect(a,b)
    for _,x in ipairs(a or {}) do if contains(b,x) then return true end end return false
end
function LL:ProfessionOutputGate(f,option,context)
    local gates=self.ItemDB and self.ItemDB.professionOutputGates
    local version,build
    if GetBuildInfo then version,build=GetBuildInfo() end
    if not gates or version~=gates.clientVersion or tostring(build)~=tostring(gates.build)
        or f.expansionID~=gates.expansionID or option.name~=gates.method or option.recipeID~=gates.recipeID then return end
    for _,rule in ipairs(gates.rules) do if contains(rule.inputItemIDs,f.id) then
        if not context or context.profession~=gates.profession or context.stale
            or context.expansionID and context.expansionID~=gates.expansionID
            or context.specializationKnown~=true or context.specializationEncoding~='invested-points'
            or type(context.specializationPoints)~='table' then return rule,nil,gates end
        local points=lookup(context.specializationPoints,rule.nodeID) or 0
        if type(points)~='number' or points<0 or points~=points or points%1~=0 then return rule,nil,gates end
        return rule,points>=rule.minimumPoints,gates
    end end
end

-- Resolve a typed native eligibility gate after source fusion and quantity
-- projection, before synthetic scaling and valuation. Source records stay raw.
function LL:ApplyProfessionOutputGates(f,option,model,context)
    if not model or model.professionOutputGateApplied then return model end
    local rule,eligible,gates=self:ProfessionOutputGate(f,option,context)
    if not rule or eligible==nil then return model end
    local result=copy(model)
    local function gated(m)
        if contains(gates.outputItemIDs,m.id) then return true end
        return intersect(gates.outputItemIDs,m.rankIDs)
    end
    local fallback,anchored,found
    for _,m in ipairs(result.materials or {}) do if gated(m) then
        found=true
        if m.conditionalRequirement=='Proficient Processor per-ore unlock'
            and type(m.conditionalExpectedQuantity)=='number' then fallback=m end
        if type(m.expectedQuantity)=='number' and m.expectedQuantity>0 and not m.additionalOutput then anchored=true end
    end end
    local materials={}
    for _,m in ipairs(result.materials or {}) do
        local omit=false
        if gated(m) then
            if not eligible then
                m.expectedQuantity=0;m.chance=0;m.chanceConfidence=gates.confidence
                m.structuralZero=true;m.probabilityBasis='specialization-eligibility-zero';m.probabilityVerified=false
                m.minQuantity=nil;m.maxQuantity=nil;m.unavailableReason=nil;m.conditionalExpectedQuantity=nil
                m.conditionalRequirement=nil;m.quantityCounts=nil;m.personalHistogram=nil;m.histogram=nil
                m.samples=nil;m.effectiveSamples=nil;m.personalSamples=nil;m.fieldEvidence=nil
            elseif fallback and not anchored then
                if m==fallback then
                    m.expectedQuantity=m.conditionalExpectedQuantity
                    m.confidence=m.conditionalConfidence or 0
                    m.rankIDs=copy(gates.outputItemIDs) -- the calculator did not identify an output quality
                    m.conditionalExpectedQuantity=nil;m.conditionalRequirement=nil;m.unavailableReason=nil
                    m.chance=nil;m.minQuantity=nil;m.maxQuantity=nil;m.probabilityVerified=false
                    m.gateReferenceActivated=true
                elseif m.additionalOutput then omit=true end -- do not add the weak native unlock prior twice
            end
        end
        if not omit then materials[#materials+1]=m end
    end
    if not eligible and not found then materials[#materials+1]={id=gates.outputItemIDs[1],
        rankIDs=copy(gates.outputItemIDs),expectedQuantity=0,chance=0,chanceConfidence=gates.confidence,
        structuralZero=true,probabilityBasis='specialization-eligibility-zero',probabilityVerified=false} end
    result.materials=materials;result.professionOutputGateApplied=true
    result.outputGate={nodeID=rule.nodeID,minimumPoints=rule.minimumPoints,eligible=eligible,confidence=gates.confidence}
    result.unknownOutputs=#(result.namedOutputs or {})>0
        or model.unknownOutputs and (not model.outputQuantityCompletenessTracked or model.unknownOutputIdentities) or nil
    result.hasConditionalReferences=nil
    for _,m in ipairs(materials) do
        if m.expectedQuantity==nil then result.unknownOutputs=true end
        if m.conditionalExpectedQuantity~=nil then result.hasConditionalReferences=true end
    end
    if not result.unknownOutputs and result.warning=='Partial: some output quantities unknown' then result.warning=nil end
    return result
end
-- A reviewed calibration changes one declared confidence-zero coefficient;
-- the native effect identity, node gate, scope, unit and operator still apply.
local function reviewedEffectAmount(effect,option)
    local overrides=option and option.reviewedEffectOverrides
    local value=type(overrides)=='table' and lookup(overrides,effect.effectID)
    if type(value)~='table' or effect.mechanism~='qualitative-extra-output-prior'
        or effect.confidence~=0 or effect.metric~='extraOutput'
        or value.confidence~=0 or value.entryID~=effect.entryID or value.metric~=effect.metric
        or value.mechanism~=effect.mechanism or value.unit~=effect.unit
        or value.operator~=(effect.operator or 'add')
        or type(value.inputCount)~='number' or value.inputCount<=0
        or value.inputCount~=option.inputCount
        or type(value.amount)~='number' or value.amount~=value.amount or value.amount<0 or value.amount==math.huge then
        return effect.amount,false
    end
    return value.amount,true
end
local function materialIDs(material)
    return type(material.rankIDs)=='table' and #material.rankIDs>0 and material.rankIDs or {material.id}
end
local function materialPolicy(self,material)
    if material.economicPolicy=='nontradable' then return 'nontradable' end
    local items=self.ItemDB and self.ItemDB.professionProfiles and self.ItemDB.professionProfiles.items
    local allBound=true
    for _,id in ipairs(materialIDs(material)) do
        local item=lookup(items,id)
        if not item or (item.bindType~=1 and item.bonding~=1 and item.itemBinding~=1) then allBound=false;break end
    end
    if allBound then material.economicPolicy='nontradable';return 'nontradable' end
    return material.economicPolicy
end
-- A pooled row is one quantity over alternatives. Additive units are summed
-- over its members once; a relative multiplier is identifiable only when all
-- alternatives have the same coefficient. Missing rank shares stay unknown.
local function materialUnits(self,material,params)
    local policy=materialPolicy(self,material)
    local extras=policy=='nontradable' and params.nontradableExtraOutputs or params.extraOutputs
    local relative,extra,minimum=nil,0,0
    for _,id in ipairs(materialIDs(material)) do
        local r=number(lookup(params.relativeExtraOutputs,id))
        if relative~=nil and math.abs(relative-r)>1e-12 then
            return nil,'Pooled output has unequal rank multipliers without a verified rank allocation'
        end
        relative=r;extra=extra+number(lookup(extras,id))
        local floor=number(lookup(params.minimumOutputs,id))
        if material.rankIDs and floor>0 then return nil,'Pooled output floors require exact rank quantities' end
        minimum=minimum+floor
    end
    local factor=1+(relative or 0)
    if factor<=0 then return nil,'Output multiplier must be positive for an identifiable inverse' end
    return {relativeFactor=factor,extra=extra,minimum=minimum,policy=policy}
end
local statKeys={'resourcefulness','multicraft'}
local nativeNames={resourcefulness='Resourcefulness',multicraft='Multicraft'}
local outputMetrics={skill=true,difficulty=true,resourcefulness=true,multicraft=true,
    extraOutput=true,dropChance=true,yieldMultiplier=true,resourcefulnessSaved=true,multicraftExtra=true}
local function metricApplies(metric,method)
    if not outputMetrics[metric] then return false end
    if metric=='multicraft' or metric=='multicraftExtra' then return method=='Craft' end
    if metric=='resourcefulness' or metric=='resourcefulnessSaved' then
        return method~='Disenchant' and method~='Use'
    end
    return true
end
local function nativeStat(context,key)
    for _,v in ipairs(context.operationStats or {}) do
        if v.key==key or v.bonusStatName==nativeNames[key] then
            return {rating=v.bonusStatValue or v.rating,percent=v.ratingPct or v.percent}
        end
    end
end
local function conditionMatches(effect,context)
    local c=effect.condition or {}
    local explicit=lookup(context.effectStates,effect.entryID)
    if type(explicit)=='table' and explicit.active==true then return true end
    if c.requiresActiveBuff then
        local selected=lookup(context.effectStates,effect.entryID)
        local found=type(selected)=='table' and selected.active==true
        for _,id in ipairs(c.spellIDs or {}) do
            if lookup(context.activeBuffs,id) or lookup(context.buffs,id) then found=true end
        end
        if not found then return false end
    end
    if c.event and not lookup(context.events,c.event) then return false end
    for flag,expected in pairs(c.contextFlags or {}) do
        if type(flag)=='number' then flag=expected;expected=true end
        if lookup(context.contextFlags,flag)~=expected then return false end
    end
    for flag,expected in pairs(effect.requiredContextFlags or {}) do
        if type(flag)=='number' then flag=expected;expected=true end
        if lookup(context.contextFlags,flag)~=expected then return false end
    end
    return true
end
local function scopeMatches(effect,profession,expansion,context,option,facts,recipe)
    local s=effect.scope or {}
    local alternate=contains(s.alternateRecipeIDs,option.recipeID) and option.name==s.alternateMethod
    if s.profession and s.profession~=profession then return false end
    if s.expansionID and s.expansionID~=expansion then return false end
    if s.method and s.method~=option.name and not alternate then return false end
    if s.inputRarity and s.inputRarity~=facts.quality and not alternate then return false end
    if s.inputClassID and s.inputClassID~=facts.classID then return false end
    if #(s.inputItemIDs or {})>0 and not contains(s.inputItemIDs,facts.id) then return false end
    if s.scopeUnknown then return false end
    if #(s.labelIDs or {})>0 and s.labelContext~='disenchant-input'
        and not intersect(s.labelIDs,option.labels or context.recipeLabels or (recipe and recipe.labels)) then return false end
    if s.labelContext=='disenchant-input' and option.name~='Disenchant' and not alternate then return false end
    return conditionMatches(effect,context)
end

-- Sharing a standard DE source must not erase an item-specific talent gate.
-- Character conditions remain part of the caller's full context key; explicit
-- input identities require the ordinary per-item path instead.
function LL:ProfessionCategoryProjectionIndependent(facts,option,context)
    if option.name~='Disenchant' or option.recipeID~=13262 or option.inputCount~=1
        or context.profession~='Enchanting' or context.expansionID~=facts.expansionID
        or option.profession and option.profession~='Enchanting'
        or option.expansionID and option.expansionID~=facts.expansionID
        or option.reviewedEffectOverrides then return false end
    local data=self.ItemDB and self.ItemDB.professionProfiles or {}
    local recipe=lookup(data.recipes,option.recipeID)
    if recipe and (recipe.profession and recipe.profession~='Enchanting'
        or recipe.expansionID and recipe.expansionID~=facts.expansionID) then return false end
    if lookup(data.recipeQualityModels,option.recipeID) then return false end
    local profile=data.profiles and data.profiles['Enchanting:'..tostring(facts.expansionID)]
    local function itemScoped(effects)
        for _,effect in ipairs(effects or {}) do
            local scope=effect.scope or {}
            local alternate=contains(scope.alternateRecipeIDs,option.recipeID) and scope.alternateMethod==option.name
            if (not scope.profession or scope.profession=='Enchanting')
                and (not scope.expansionID or scope.expansionID==facts.expansionID)
                and (not scope.method or scope.method==option.name or alternate)
                and (not scope.inputRarity or scope.inputRarity==facts.quality or alternate)
                and (not scope.inputClassID or scope.inputClassID==facts.classID)
                and (#(scope.inputItemIDs or {})>0 or scope.inputItemID~=nil or scope.inputID~=nil
                    or effect.inputItemID~=nil) then return true end
        end
        return false
    end
    if itemScoped(profile and profile.buffs) then return false end
    for _,node in pairs(profile and profile.nodes or {}) do
        if itemScoped(node.pointEffects) or itemScoped(node.learningEffects) then return false end
        for _,milestone in ipairs(node.milestones or {}) do
            if itemScoped(milestone.effects) then return false end
        end
    end
    return true
end

local function recipeQualityModel(self,params,option)
    local data=self.ItemDB and self.ItemDB.professionProfiles
    local rule=data and lookup(data.recipeQualityModels,params.recipeID)
    if not rule then return nil end
    if (option and option.name or params.method)~='Craft' or params.profession~=rule.profession
        or params.expansionID~=rule.expansionID
        or (self.ProfessionRuleMatchesBuild and not self:ProfessionRuleMatchesBuild(rule)) then return nil end
    local rank=params.inputQuality
    if type(rank)~='number' or rank%1~=0 or not lookup(rule.targetRankMeansByInputRank,rank) then
        return nil,'Recipe requires a verified input quality'
    end
    if params.inputItemID~=nil and lookup(rule.inputRankItemIDs,rank)~=params.inputItemID then
        return nil,'Input identity and native reagent quality disagree'
    end
    return rule,rank
end

-- The observed endpoints contain unit means, not output-hit probabilities.
-- This affine redistribution preserves the caller's primary material pool.
function LL:RecipeQualityQuantities(quantities,params,option,inverse)
    local rule,rank=recipeQualityModel(self,params,option)
    if not rule then return nil,rank end
    local endpoint=lookup(rule.targetRankMeansByInputRank,rank)
    local total=0
    for index in ipairs(rule.rankItemIDs) do
        local value=quantities[index] or 0
        if type(value)~='number' or value<0 or value~=value or value==math.huge then return nil,'Invalid quality units' end
        if index>rank and value>1e-8 then return nil,'Source exceeds the input quality cap' end
        total=total+value
    end
    if total<=0 then return nil,'Quality source has no measured primary units' end
    local progress=clamp(number(params.skill)/math.max(1,rule.skillMaximum),0,1)
    local scale=total/rule.outputCount
    local result={}
    if inverse and progress>=1-1e-12 then
        for index in ipairs(rule.rankItemIDs) do
            if math.abs((quantities[index] or 0)-endpoint[index]*scale)>1e-8 then
                return nil,'Saturated source differs from the declared endpoint'
            end
            result[index]=rule.baselineRankMeans[index]*scale
        end
    else
        for index in ipairs(rule.rankItemIDs) do
            local value=quantities[index] or 0
            if inverse then value=(value-progress*endpoint[index]*scale)/(1-progress)
            else value=(1-progress)*value+progress*endpoint[index]*scale end
            if value < -1e-8 then return nil,'Source cannot be inverted under the quality model' end
            result[index]=math.max(0,value)
        end
    end
    return result,rule
end

local function qualityMaterialChanged(material,confidence)
    material.chance=nil;material.minQuantity=nil;material.maxQuantity=nil;material.probabilityVerified=false
    material.histogram=nil;material.quantityCounts=nil;material.personalHistogram=nil;material.fieldEvidence=nil
    material.expectationTransformed=true;material.transformConfidence=confidence
    material.confidence=math.min(number(material.confidence,100),confidence)
end

-- Source rank distributions are retained until a dedicated, sourced recipe
-- model provides a numeric skill-to-quality relationship. Skill by itself is
-- not evidence for a universal highest-rank mix.
local function modelRecipeQuality(self,model,params,option,inverse)
    local rule,why=recipeQualityModel(self,params,option)
    if not rule then return nil,why end
    local quantities,byRank={},{}
    for index,id in ipairs(rule.rankItemIDs) do
        quantities[index]=0
        for _,material in ipairs(model.materials or {}) do if material.id==id and material.economicPolicy~='nontradable' then
            if material.rankIDs or type(material.expectedQuantity)~='number' or byRank[index] then
                return nil,'Recipe quality needs one exact mean for each present material'
            end
            quantities[index]=material.expectedQuantity;byRank[index]=material
        end end
    end
    local adjusted,error=self:RecipeQualityQuantities(quantities,params,option,inverse)
    if not adjusted then return nil,error end
    for index,id in ipairs(rule.rankItemIDs) do
        local material=byRank[index]
        if not material and adjusted[index]>0 then
            material={id=id,confidence=rule.confidence};model.materials[#model.materials+1]=material
        end
        if material then
            if material.expectedQuantity~=adjusted[index] then qualityMaterialChanged(material,rule.confidence) end
            material.expectedQuantity=adjusted[index]
        end
    end
    model.normalizationConfidence=math.min(number(model.normalizationConfidence,100),rule.confidence)
    return model
end

-- Re-evaluate the copied allocation for this exact recipe/input scope. Raw
-- grants must be subtracted before percentage conversion and chance clamping.
function LL:ProfessionStatGrants(profession,expansion,context,option,facts)
    local source=copy(context or {})
    source.statGrantReference=nil;source.statGrantsOnly=true
    source.statReferenceScope=true
    source.operationStatsIncludeSpecialization=false
    local result=self:ProfessionProfileParameters(profession,expansion,source,option,facts)
    return result.ratings,result.percents,result.scopeUnknown
end
function LL:ProfessionProfileParameters(profession,expansion,context,option,facts)
    context=context or {};option=option or {};facts=facts or {}
    local data=self.ItemDB and self.ItemDB.professionProfiles or {}
    local profile=data.profiles and data.profiles[profession..':'..tostring(expansion)]
    if GetBuildInfo and self.ProfessionRuleMatchesBuild and not self:ProfessionRuleMatchesBuild(data) then profile=nil end
    local recipe=lookup(data.recipes,option.recipeID) or {}
    local native=data.professionParameters and data.professionParameters[profession] or {}
    local live=context.operationStatsIncludeSpecialization==true
    local liveSkill=live and context.skillFromAllocation~=false
    local skillIncludes=liveSkill or context.skillIncludesSpecialization==true or
        (context.preSpecializationSkill==nil and context.effectiveSkill~=nil and not context.simulated)
    local params={profession=profession,expansionID=expansion,method=option.name,recipeID=option.recipeID,
        inputItemID=facts.id,inputQuality=facts.reagentQuality or context.inputQuality or option.inputRank,
        skill=number(liveSkill and context.effectiveSkill or context.preSpecializationSkill,
            number(context.effectiveSkill,number(context.skill))),skillBonus=0,
        difficulty=number(context.difficulty,context.baseDifficulty and
            (number(context.baseDifficulty)+number(context.bonusDifficulty)) or number(recipe.difficulty)),stats={},confidence=100,
        appliedEffects={},extraOutputs={},minimumOutputs={},nontradableExtraOutputs={},relativeExtraOutputs={},namedOutputs={},effectTotals={},
        outputFactor=1,inputFactor=1,recipe=recipe}
    local customQuality=lookup(data.recipeQualityModels,option.recipeID)
    if customQuality and params.inputQuality==nil then
        for rank,id in ipairs(customQuality.inputRankItemIDs) do if id==facts.id then params.inputQuality=rank end end
    end
    local ratings,percents={},{}
    local statScopeUnknown=false
    local pendingOutputs={}
    for _,key in ipairs(statKeys) do ratings[key]=0;percents[key]=0 end
    local function apply(effect,multiplier)
        -- Descriptions without a numeric coefficient never alter drops or
        -- prices. Keep the supported source baseline and native numeric rules.
        if effect.numericUnsupported or effect.requiresSemanticReview then return end
        if effect.dedicatedHandler then return end
        if not metricApplies(effect.metric,option.name) then return end
        if context.statReferenceScope and ratings[effect.metric]~=nil then
            local s=effect.scope or {}
            local probe,probeContext=scopeCopy(facts),copy(context)
            local missing=false
            local alternate=contains(s.alternateRecipeIDs,option.recipeID) and option.name==s.alternateMethod
            for _,pair in ipairs({{'inputRarity','quality'},{'inputClassID','classID'}}) do
                if (pair[1]~='inputRarity' or not alternate) and s[pair[1]]~=nil and facts[pair[2]]==nil then
                    probe[pair[2]]=s[pair[1]];missing=true
                end
            end
            if #(s.inputItemIDs or {})>0 and facts.id==nil then probe.id=s.inputItemIDs[1];missing=true end
            local c=effect.condition or {}
            if c.event and context.events==nil then probeContext.events={[c.event]=true};missing=true end
            if c.requiresActiveBuff and (context.buffsKnown~=true or #(c.spellIDs or {})==0)
                and not lookup(context.effectStates,effect.entryID) then
                probeContext.effectStates=copy(context.effectStates or {})
                probeContext.effectStates[effect.entryID]={active=true,stacks=1};missing=true
            end
            for flag,expected in pairs(c.contextFlags or {}) do
                if type(flag)=='number' then flag=expected;expected=true end
                if lookup(context.contextFlags,flag)==nil then
                    probeContext.contextFlags=probeContext.contextFlags or {};probeContext.contextFlags[flag]=expected;missing=true
                end
            end
            for flag,expected in pairs(effect.requiredContextFlags or {}) do
                if type(flag)=='number' then flag=expected;expected=true end
                if lookup(context.contextFlags,flag)==nil then
                    probeContext.contextFlags=probeContext.contextFlags or {};probeContext.contextFlags[flag]=expected;missing=true
                end
            end
            if missing and scopeMatches(effect,profession,expansion,probeContext,option,probe,recipe) then statScopeUnknown=true end
        end
        if not scopeMatches(effect,profession,expansion,context,option,facts,recipe) then return end
        local metric=effect.metric
        if skillIncludes and metric=='skill' then return end
        -- Native operations already contain skill and talent stat grants.
        if live and (metric=='difficulty' or ratings[metric]~=nil) then return end
        local declaredAmount,calibrated=reviewedEffectAmount(effect,option)
        local amount=number(declaredAmount)*multiplier*(effect.operator=='subtract' and -1 or 1)
        local selected=lookup(context.effectStates,effect.entryID)
        if effect.condition and effect.condition.maxStacks and type(selected)=='table' and selected.active then
            amount=amount*clamp(number(selected.stacks,1),1,effect.condition.maxStacks)
        elseif effect.condition and effect.condition.maxStacks then
            local stacks=1
            for _,id in ipairs(effect.condition.spellIDs or {}) do stacks=math.max(stacks,number(lookup(context.buffStacks,id),1)) end
            amount=amount*clamp(stacks,1,effect.condition.maxStacks)
        end
        params.appliedEffects[#params.appliedEffects+1]={entryID=effect.entryID,metric=metric,amount=amount,
            mechanism=effect.mechanism,confidence=effect.confidence,reviewedCalibration=calibrated or nil}
        params.confidence=math.min(params.confidence,number(effect.confidence))
        if metric=='skill' then params.skillBonus=params.skillBonus+amount
        elseif metric=='difficulty' then params.difficulty=params.difficulty+amount
        elseif ratings[metric]~=nil then
            if effect.unit=='rating' then ratings[metric]=ratings[metric]+amount
            else percents[metric]=percents[metric]+amount end
        elseif metric=='extraOutput' or metric=='dropChance' then
            if effect.unit=='percent' then amount=amount/100 end
            pendingOutputs[#pendingOutputs+1]={effect=effect,amount=amount}
        else params.effectTotals[metric]=(params.effectTotals[metric] or 0)+amount end
    end
    local maximumSpecializationSkill=0
    for id,node in pairs(profile and profile.nodes or {}) do
        local function maximum(effects,scale)
            for _,effect in ipairs(effects or {}) do
                if effect.metric=='skill' and scopeMatches(effect,profession,expansion,context,option,facts,recipe) then
                    maximumSpecializationSkill=maximumSpecializationSkill+number(effect.amount)*scale
                end
            end
        end
        maximum(node.pointEffects,node.maxRank);maximum(node.learningEffects,1)
        for _,milestone in ipairs(node.milestones or {}) do if milestone.rank>0 then maximum(milestone.effects,1) end end
        local points=clamp(number(lookup(context.specializationPoints,id)),0,number(node.maxRank))
        local learned=points>0 or lookup(context.learnedSpecializations,id)==true
        if learned then
            for _,effect in ipairs(node.pointEffects or {}) do apply(effect,points) end
            for _,effect in ipairs(node.learningEffects or {}) do apply(effect,1) end
            for _,milestone in ipairs(node.milestones or {}) do
                if milestone.rank>0 and points>=milestone.rank then
                    for _,effect in ipairs(milestone.effects or {}) do apply(effect,1) end
                end
            end
        end
    end
    if context.statGrantsOnly then return {ratings=ratings,percents=percents,scopeUnknown=statScopeUnknown} end
    if not live and type(context.statGrantReference)=='table' then
        local reference=context.statGrantReference
        local sourceRatings,sourcePercents,unknown
        if reference.policy=='ZERO_SOURCE' then
            sourceRatings,sourcePercents={},{}
        elseif reference.policy=='SOURCE_OPERATION' and type(reference.option)=='table' and type(reference.facts)=='table' then
            sourceRatings,sourcePercents,unknown=self:ProfessionStatGrants(profession,expansion,reference,reference.option,reference.facts)
        else unknown=true end
        if unknown then
            sourceRatings,sourcePercents=self:ProfessionStatGrants(profession,expansion,reference,option,facts)
            params.statReferenceAssumption='TARGET_SCOPED_TRANSFER_PRIOR'
        end
        for _,key in ipairs(statKeys) do
            ratings[key]=ratings[key]-number(sourceRatings[key])
            percents[key]=percents[key]-number(sourcePercents[key])
        end
    end
    params.skill=math.max(0,params.skill+params.skillBonus)
    params.skillMaximum=number(context.baseSkillMaximum,140)+maximumSpecializationSkill
    params.difficulty=math.max(0,params.difficulty)
    local quality=self:ProfessionQualityRank(params,recipe,context)
    for _,pending in ipairs(pendingOutputs) do
        local effect,amount=pending.effect,pending.amount
        local binding=effect.outputBinding or {}
        local ids=copy(effect.outputItemIDs or binding.itemIDs or {})
        if binding.kind=='recipe-primary' then
            local outputs=option.outputQualityItems or recipe.outputQualityItems
            local output=lookup(outputs,quality)
            ids=(output and {output.id}) or (option.outputID and {option.outputID}) or copy(recipe.outputIDs or {})
        end
        if binding.requiresTargetOutputFilter and not option.mixedTargetPrior then
            local legal={}
            for _,id in ipairs(ids) do if contains(option.legalExtraOutputIDs,id) then legal[#legal+1]=id end end
            ids=legal
        end
        if binding.requiresRenownedTarget and not option.renownedTarget then ids={} end
        -- Multiple verified quality alternatives form one product, not several
        -- independent extra drops. Resolve their native family at target rank.
        if #ids>1 and data.items and data.qualityFamilies then
            local item=lookup(data.items,ids[1]);local familyID=item and item.qualityFamilyID
            local family=lookup(data.qualityFamilies,familyID)
            local single=family~=nil
            for _,id in ipairs(ids) do
                local nextItem=lookup(data.items,id)
                if not nextItem or nextItem.qualityFamilyID~=familyID then single=false end
            end
            if single and family.rankItemIDs[quality] then ids={family.rankItemIDs[quality]} end
        end
        if #ids>0 then
            local quantities=effect.economicPolicy=='nontradable' and params.nontradableExtraOutputs or params.extraOutputs
            for _,id in ipairs(ids) do
                if effect.operator=='multiply' then params.relativeExtraOutputs[id]=(params.relativeExtraOutputs[id] or 0)+amount
                elseif effect.operator=='set' then params.minimumOutputs[id]=math.max(params.minimumOutputs[id] or 0,amount/#ids)
                else quantities[id]=(quantities[id] or 0)+amount/#ids end
            end
        elseif not effect.identityUnresolved and not binding.kind then params.sameOutputExtra=(params.sameOutputExtra or 0)+amount
        else
            local name=binding.name or effect.targetFamily
            if type(name)=='string' and name~='' then
                local named={name=name,entryID=effect.entryID,confidence=number(effect.confidence),economicPolicy='unpriced'}
                if effect.operator=='multiply' then named.discoveryFactor=1+amount
                elseif effect.metric=='dropChance' then named.chance=clamp(amount,0,1)
                else named.expectedQuantity=math.max(0,amount) end
                params.namedOutputs[#params.namedOutputs+1]=named
            end
        end
    end
    local explicitNativeStats=live and context.operationStats and #context.operationStats>0
    for _,key in ipairs(statKeys) do
        if metricApplies(key,option.name) then
            local current=lookup(context.stats,key) or nativeStat(context,key) or {}
            local anchor=lookup(context.statAnchors,key) or current
            local calibration=lookup(context.statCalibration,key) or anchor
            local slope
            if number(calibration.rating)>0 then slope=number(calibration.percent)/calibration.rating end
            -- A rating has no universal percent conversion across professions
            -- and levels. Native percentages remain valid; uncalibrated rating
            -- deltas do not create a guessed drop/quality bonus.
            if not slope or slope<=0 then slope=0 end
            local basePercent=number(current.percent)+(number(current.rating)-number(anchor.rating))*slope
            local percent=basePercent+ratings[key]*slope+percents[key]
            if (ratings[key]~=0 or (number(current.rating)-number(anchor.rating))~=0) and
                number(calibration.rating)<=0 then params.confidence=math.min(params.confidence,10) end
            params.stats[key]=clamp(percent/100,0,1)
            if profile and not contains(profile.statKeys,key) and ratings[key]==0 and percents[key]==0 then params.stats[key]=0 end
        else params.stats[key]=0 end
    end
    local function useReferenceStat(key)
        if params.statReferenceAssumption and (lookup(context.stats,key) or nativeStat(context,key)
            or ratings[key]~=0 or percents[key]~=0) then
            params.confidence=0;params.statReferenceUncertaintyApplied=true
        end
    end
    local method=option.name
    local itemUse=method=='Use'
    local de=method=='Disenchant'
    local supportsMC=option.supportsMulticraft
    if supportsMC==nil then supportsMC=recipe.supportsMulticraft end
    if explicitNativeStats then supportsMC=nativeStat(context,'multicraft')~=nil end
    if supportsMC==nil then supportsMC=number(recipe.outputCount,number(option.outputCount))>1 end
    local extraFraction=type(native.MinCraftExtraQtyPct)=='number' and type(native.MaxCraftExtraQtyPct)=='number'
        and (native.MinCraftExtraQtyPct+native.MaxCraftExtraQtyPct)/200
    if extraFraction and method=='Craft' and not customQuality and supportsMC then
        params.outputFactor=1+params.stats.multicraft*extraFraction*(1+number(params.effectTotals.multicraftExtra)/100)
        if params.outputFactor~=1 then useReferenceStat('multicraft') end
        if params.stats.multicraft>0 then params.confidence=math.min(params.confidence,15) end
        if not explicitNativeStats and recipe.capabilityConfidence then
            params.confidence=math.min(params.confidence,number(recipe.capabilityConfidence.multicraft,100))
        end
    end
    if type(native.ResourcefulEffectLow)=='number' and type(native.ResourcefulEffectHigh)=='number'
        and not de and not itemUse and option.supportsResourcefulness~=false and recipe.supportsResourcefulness~=false then
        local saved=(native.ResourcefulEffectLow+native.ResourcefulEffectHigh)/200
        params.inputFactor=clamp(1-params.stats.resourcefulness*saved*(1+number(params.effectTotals.resourcefulnessSaved)/100),.01,1)
        if params.inputFactor~=1 then useReferenceStat('resourcefulness') end
        if params.stats.resourcefulness>0 then params.confidence=math.min(params.confidence,15) end
    end
    params.outputFactor=params.outputFactor*(1+number(params.effectTotals.yieldMultiplier)/100)
    params.sameOutputExtra=math.max(0,number(params.sameOutputExtra))
    if customQuality then params.confidence=math.min(params.confidence,customQuality.confidence) end
    return params
end

function LL:ProfessionQualityRank(params,recipe,context)
    recipe=recipe or params.recipe or {};context=context or {}
    if context.operationStatsIncludeSpecialization and number(context.craftingQuality)>0 then return context.craftingQuality end
    local rank=1
    for _,threshold in ipairs(recipe.qualityThresholds or {}) do
        if params.skill+1e-8>=params.difficulty*number(threshold.fraction) then rank=math.max(rank,threshold.rank) end
    end
    return rank
end

function LL:NormalizeProfessionBaseline(model,params,option)
    if not model or not params or params.outputFactor<=0 or params.inputFactor<=0 then return nil end
    if model.rawProfessionBaseline then return copy(model.rawProfessionBaseline) end
    local raw=copy(model)
    raw.rawProfessionBaseline=nil
    -- A reported net-stock yield already includes reprocessing saved inputs.
    -- Convert its quantity to one gross input before inverse output/profile
    -- transforms. The target profile then receives its input savings once.
    if raw.sourceQuantityBasis=='net-input' then
        for _,material in ipairs(raw.materials or {}) do
            if type(material.expectedQuantity)=='number' then
                material.expectedQuantity=material.expectedQuantity*params.inputFactor
            end
        end
        raw.reportedNetInputFactor=params.inputFactor
        raw.expectedInputCount=number(raw.inputCount,number(option and option.inputCount,1))*params.inputFactor
        raw.sourceQuantityBasis='gross-input'
    end
    local data=self.ItemDB and self.ItemDB.professionProfiles
    if lookup(data and data.recipeQualityModels,params.recipeID) then
        local adjusted,why=modelRecipeQuality(self,raw,params,option,true)
        if not adjusted then return nil,why end
    end
    for _,m in ipairs(raw.materials or {}) do
        if type(m.expectedQuantity)=='number' then
            local units,why=materialUnits(self,m,params)
            if not units then return nil,why end
            if units.minimum>0 and m.expectedQuantity<=units.minimum then
                return nil,'Guaranteed floor does not identify an invertible source mean'
            end
            m.expectedQuantity=m.expectedQuantity-units.extra
            if params.sameOutputExtra>0 and #(raw.materials or {})==1 then m.expectedQuantity=m.expectedQuantity-params.sameOutputExtra end
            local factor=params.outputFactor
            m.expectedQuantity=m.expectedQuantity/(factor*units.relativeFactor)
            if m.expectedQuantity<0 then return nil,'Source cannot be inverted under declared profile' end
        end
    end
    if raw.expectedInputCount then raw.expectedInputCount=raw.expectedInputCount/params.inputFactor end
    raw.baselineNormalized=true
    return raw
end

function LL:ProjectProfessionBaseline(baseline,params,option)
    if not baseline or not params then return nil end
    local raw=baseline.rawProfessionBaseline or baseline
    local result=copy(raw);result.rawProfessionBaseline=copy(raw)
    local seen,nontradableSeen={},{}
    for _,m in ipairs(result.materials or {}) do
        local policy=materialPolicy(self,m)
        for _,id in ipairs(materialIDs(m)) do
            if policy=='nontradable' then nontradableSeen[id]=true else seen[id]=true end
        end
        if type(m.expectedQuantity)=='number' then
            local units,why=materialUnits(self,m,params)
            if not units then return nil,why end
            local factor=params.outputFactor
            local value=m.expectedQuantity*factor*units.relativeFactor+units.extra
            value=math.max(value,units.minimum)
            if params.sameOutputExtra>0 and #(result.materials or {})==1 then value=value+params.sameOutputExtra end
            if value~=m.expectedQuantity then
                m.chance=nil;m.minQuantity=nil;m.maxQuantity=nil;m.probabilityVerified=false
                m.histogram=nil;m.transformConfidence=params.confidence
                m.quantityCounts=nil;m.personalHistogram=nil;m.fieldEvidence=nil
                m.expectationTransformed=true
            end
            m.expectedQuantity=value
        end
        m.confidence=math.min(number(m.confidence,100),params.confidence)
    end
    if not (option and option.preserveMaterialIdentity) then
        for id,quantity in pairs(params.extraOutputs) do
            if not seen[id] and quantity>0 then result.materials[#result.materials+1]={id=id,expectedQuantity=quantity,confidence=params.confidence,additionalOutput=true} end
        end
        for id,quantity in pairs(params.nontradableExtraOutputs or {}) do
            if quantity>0 and not nontradableSeen[id] then result.materials[#result.materials+1]={id=id,expectedQuantity=quantity,
                confidence=params.confidence,additionalOutput=true,economicPolicy='nontradable'} end
        end
    end
    result.inputCount=number(raw.inputCount,number(option and option.inputCount,1))
    result.expectedInputCount=number(raw.expectedInputCount,result.inputCount)*params.inputFactor
    local data=self.ItemDB and self.ItemDB.professionProfiles
    if lookup(data and data.recipeQualityModels,params.recipeID) and not (option and option.deferRecipeQuality) then
        local adjusted,why=modelRecipeQuality(self,result,params,option,false)
        if not adjusted then return nil,why end
        result.recipeQualityApplied=true
    end
    result.qualityRank=params.recipe.supportsQuality and self:ProfessionQualityRank(params,params.recipe) or nil
    result.confidence=math.min(number(raw.confidence,100),params.confidence)
    result.ruleConfidence=math.min(number(raw.ruleConfidence,100),params.confidence)
    result.professionParameters=copy(params)
    result.namedOutputs=copy(raw.namedOutputs or {})
    for _,named in ipairs(params.namedOutputs or {}) do
        local found=false
        for _,old in ipairs(result.namedOutputs) do
            if old.name==named.name and old.entryID==named.entryID then found=true;break end
        end
        if not found then result.namedOutputs[#result.namedOutputs+1]=copy(named) end
    end
    if #result.namedOutputs>0 then result.unknownOutputs=true end
    result.generalProfessionApplied=true;result.professionProjected=true
    result.mechanicsApplied=true
    return result
end

function LL:ApplyGeneralProfessionModel(f,option,model,context,projectionMemo)
    if not model or (option.name=='Disenchant' and f.expansionID==11) or model.professionProjected then return model end
    local data=self.ItemDB and self.ItemDB.professionProfiles
    local recipe=data and lookup(data.recipes,option.recipeID)
    local profession=option.profession or (recipe and recipe.profession) or (self.ProfessionForMethod and self:ProfessionForMethod(option.name))
    local expansion=option.expansionID or (recipe and recipe.expansionID) or f.expansionID
    if not data or not data.profiles or not profession or not expansion or not data.profiles[profession..':'..expansion] then return model end
    -- Calibration belongs to this evidence model, never the caller's shared
    -- operation or character profile. Source and target use the same units.
    if model.reviewedEffectOverrides then
        option=scopeCopy(option);option.reviewedEffectOverrides=copy(model.reviewedEffectOverrides)
    end
    local contextFacts=scopeCopy(f);contextFacts.expansionID=expansion
    context=context or (self.ProcessingPlayerConditions and self:ProcessingPlayerConditions(contextFacts,option.name,option.recipeID,option.character,profession)) or {}
    local source=copy(model.baselineProfile or {})
    local assumed=not model.baselineProfile
    source.skill=source.skill or source.effectiveSkill or 0;source.preSpecializationSkill=source.preSpecializationSkill or source.skill
    source.specializationPoints=source.specializationPoints or {};source.stats=source.stats or {}
    local target
    if projectionMemo and not model.reviewedEffectOverrides then
        local byOperation=projectionMemo[context]
        if not byOperation then byOperation={};projectionMemo[context]=byOperation end
        target=byOperation[option]
        if not target then
            target=self:ProfessionProfileParameters(profession,expansion,context,option,f)
            byOperation[option]=target
        end
        -- Each source still has its own normalization/confidence caps.
        target=scopeCopy(target)
    else target=self:ProfessionProfileParameters(profession,expansion,context,option,f) end
    if assumed then target.confidence=math.min(target.confidence,5) end
    local baseline=self.ItemDB.modeledProfessionBaselines and self.ItemDB.modeledProfessionBaselines[model.recordID]
    if baseline then
        -- The compiled object supplies only normalized numerical fields. Keep
        -- runtime evidence metadata, source identity and material order intact.
        local merged=copy(model)
        for index,material in ipairs(merged.materials or {}) do
            local normalized=baseline.materials[index]
            if not normalized or normalized.id~=material.id then return model end
            -- Compilation cannot restore a field excluded by the runtime
            -- unlock/source policy (for example an unlearned diamond bonus).
            if material.expectedQuantity~=nil then material.expectedQuantity=normalized.expectedQuantity end
        end
        merged.expectedInputCount=baseline.expectedInputCount
        merged.reviewedQualityAnchors=copy(baseline.reviewedQualityAnchors)
        merged.reviewedQualityProjection=baseline.reviewedQualityProjection or merged.reviewedQualityProjection
        merged.reviewedQualityZeroShares=copy(baseline.reviewedQualityZeroShares or merged.reviewedQualityZeroShares)
        if baseline.reviewedBacklogModel~=nil then merged.reviewedBacklogModel=baseline.reviewedBacklogModel end
        target.confidence=math.min(target.confidence,number(baseline.baselineConfidence,100),number(baseline.normalizationConfidence,100))
        baseline=merged
    else
        local sourceParams=self:ProfessionProfileParameters(profession,expansion,source,option,f)
        baseline=self:NormalizeProfessionBaseline(model,sourceParams,option)
        target.confidence=math.min(target.confidence,sourceParams.confidence,number(baseline and baseline.normalizationConfidence,100))
    end
    if not baseline then
        if model.requiresSourceNormalization then
            local blocked=copy(model);blocked.projectionIncomplete=true
            blocked.normalizationFailure='Reviewed source profile cannot be inverted under the declared rules'
            return blocked
        end
        return model
    end
    local settings=scopeCopy(option);settings.preserveMaterialIdentity=true;settings.deferRecipeQuality=true
    local projected=self:ProjectProfessionBaseline(baseline,target,settings)
    if not projected then
        if model.requiresSourceNormalization then
            local blocked=copy(model);blocked.projectionIncomplete=true
            blocked.normalizationFailure='Reviewed source quality anchor cannot be projected under the declared rules'
            return blocked
        end
        return model
    end
    projected.projectedContext=copy(context)
    projected.projectedContext.effectiveSkill=target.skill
    for _,m in ipairs(projected.materials or {}) do m.appliedProfessionRule='profession-profile-rules/1' end
    projected.sourceProfileAssumed=assumed
    if model.reviewedPublishedPriorModel or model.reviewedPublishedPrior or model.reviewedBacklogModel
        or target.statReferenceUncertaintyApplied then
        for _,material in ipairs(projected.materials or {})do
            material.transformConfidence=math.min(number(material.transformConfidence,100),target.confidence)
        end
    end
    if target.outputFactor==1 and target.inputFactor==1
        and number(target.sameOutputExtra)==0 and not next(target.extraOutputs or {})
        and not next(target.relativeExtraOutputs or {}) and not next(target.minimumOutputs or {})
        and not next(target.nontradableExtraOutputs or {}) and #(target.namedOutputs or {})==0 then
        local identical=#(projected.materials or {})==#(model.materials or {})
            and projected.expectedInputCount==number(model.expectedInputCount,number(model.inputCount,1))
        for i,material in ipairs(projected.materials or {}) do
            local original=model.materials and model.materials[i]
            if not original or material.id~=original.id or material.expectedQuantity~=original.expectedQuantity then identical=false;break end
        end
        if identical and not model.reviewedPublishedPriorModel and not model.reviewedPublishedPrior
            and not target.statReferenceUncertaintyApplied then
            -- An identity operation introduces no new modeled uncertainty.
            -- Keep confidence in the original evidence, even when its source
            -- profile was unspecified. An explicit published-model cap remains
            -- authoritative even when its numerical projection is unchanged.
            projected.ruleConfidence=model.ruleConfidence
            projected.confidence=model.confidence
            for i,material in ipairs(projected.materials or {}) do
                material.confidence=model.materials[i].confidence
                material.transformConfidence=model.materials[i].transformConfidence
            end
        end
    end
    return projected
end

function LL:ProjectGeneralPersonalEstimate(f,option,raw,target,targetBuild)
    local data=self.ItemDB and self.ItemDB.professionProfiles
    if not data or not raw or not raw.observationContext or not target then return nil end
    if tostring(raw.patchBuild)~=tostring(targetBuild) then return nil end
    if option.name=='Disenchant' and f.expansionID==11 then return nil end
    local source=copy(raw.observationContext)
    local recipe=lookup(data.recipes,option.recipeID)
    local profession=target.profession or option.profession or recipe and recipe.profession
    local expansion=recipe and recipe.expansionID or f.expansionID
    if not profession or not data.profiles[profession..':'..tostring(expansion)] then return nil end
    -- A measured operation's typed ratings already contain its talents. Raw
    -- trait signatures alone never become an invented invested allocation.
    if source.operationStats and #source.operationStats>0 then
        source.operationStatsIncludeSpecialization=true
        source.statCalibration=source.statCalibration or (self.ProfessionStatCalibration and self:ProfessionStatCalibration(source.operationStats))
    end
    local sp=self:ProfessionProfileParameters(profession,expansion,source,option,f)
    local tp=self:ProfessionProfileParameters(profession,expansion,target,option,f)
    local canonical=self:NormalizeProfessionBaseline(raw.rawEstimate or raw,sp,option)
    if not canonical then return nil end
    tp.confidence=math.min(tp.confidence,sp.confidence,number(raw.confidence,85))
    local settings=scopeCopy(option);settings.deferRecipeQuality=true;settings.preserveMaterialIdentity=true
    local projected=self:ProjectProfessionBaseline(canonical,tp,settings)
    if not projected then return nil end
    projected.rawEstimate=copy(raw.rawEstimate or raw);projected.observationContext=copy(raw.observationContext)
    projected.projectedContext=copy(target);projected.projectedContext.effectiveSkill=tp.skill
    projected.patchBuild=targetBuild;projected.provisional=true
    projected.projectionRules={'profession-profile-rules/1:inverse','profession-profile-rules/1:forward'}
    projected.adjustment='Profession profile';projected.sourceKey='personal'
    return projected
end

function LL:ProfessionCraftModel(f,c,character)
    if not c.outputID or not c.outputCount then return nil end
    local data=self.ItemDB and self.ItemDB.professionProfiles
    local recipe=data and lookup(data.recipes,c.recipeID)
    local profession=c.profession or (recipe and recipe.profession)
    local expansion=(recipe and recipe.expansionID) or c.expansionID or f.expansionID
    if not profession or not expansion then return nil end
    local option=scopeCopy(c);option.name=c.method or c.name
    local contextFacts=scopeCopy(f);contextFacts.expansionID=expansion
    local ctx=self:ProcessingPlayerConditions(contextFacts,option.name,c.recipeID,character,profession) or {}
    local build=GetBuildInfo and select(2,GetBuildInfo())
    if not ctx.simulated and c.operationInfo and c.operationCharacter==ctx.character
        and tostring(c.operationBuild)==tostring(build) and self.CopyProfessionOperationContext then
        ctx=copy(ctx);self:CopyProfessionOperationContext(ctx,c.operationInfo)
        if c.operationInfo.baseSkill and c.operationInfo.bonusSkill then ctx.effectiveSkill=c.operationInfo.baseSkill+c.operationInfo.bonusSkill end
    elseif not ctx.simulated and c.allocation then
        ctx=copy(ctx);ctx.craftingQuality=nil;ctx.qualityFromBlizzard=false
        ctx.skillFromAllocation=false;ctx.effectiveSkill=nil;ctx.skillIncludesSpecialization=false
        ctx.baseDifficulty=nil;ctx.bonusDifficulty=nil;ctx.difficulty=nil
    end
    local params=self:ProfessionProfileParameters(profession,expansion,ctx,option,f)
    if c.allocationConfidence~=nil then params.confidence=math.min(params.confidence,c.allocationConfidence) end
    local rank=self:ProfessionQualityRank(params,recipe,ctx)
    local qualityItems=c.qualityOrderVerified and c.outputQualityItems or recipe and recipe.qualityOrderVerified and recipe.outputQualityItems
    local output=lookup(qualityItems,rank)
    local id=output and output.id or c.outputID
    local baseline={inputCount=c.inputCount or 1,expectedInputCount=c.inputCount or 1,
        materials={{id=id,itemLink=output and output.itemLink or c.outputItemLink,
            expectedQuantity=c.outputCount,confidence=100}},
        confidence=100,source='Profession recipe',sourceKey='recipe'}
    local model=self:ProjectProfessionBaseline(baseline,params,option)
    model.qualityRank=(qualityItems or recipe and recipe.supportsQuality or ctx.qualityFromBlizzard) and rank or nil
    model.projectedContext=copy(ctx)
    model.context=copy(ctx);model.context.effectiveSkill=params.skill
    model.simulated=ctx.simulated
    model.supplyCostFactor=params.inputFactor
    return model
end

function LL:ApplyGeneralProfessionAdditions(f,option,model,context)
    local params=model and model.generalProfessionParameters
    if not params or model.generalAdditionsApplied then return model end
    local result=copy(model)
    result.namedOutputs=copy(params.namedOutputs or {})
    if #result.namedOutputs>0 then result.unknownOutputs=true end
    local seen,nontradableSeen={},{}
    for _,m in ipairs(result.materials or {}) do
        if m.economicPolicy=='nontradable' then nontradableSeen[m.id]=true else seen[m.id]=true end
        for _,id in ipairs(m.rankIDs or {}) do seen[id]=true end
    end
    local weight=0
    for key in pairs(model.generalProjectedSources or {itemdb=true}) do weight=weight+(model.sources and model.sources[key] or 0) end
    for _,named in ipairs(result.namedOutputs) do
        if named.expectedQuantity then named.expectedQuantity=named.expectedQuantity*weight*result.inputCount/number(model.generalProjectionInputCount,1) end
    end
    for id,quantity in pairs(params.extraOutputs or {}) do
        if not seen[id] and quantity>0 and weight>0 then
            result.materials[#result.materials+1]={id=id,
                expectedQuantity=quantity*weight*result.inputCount/number(model.generalProjectionInputCount,1),
                confidence=math.min(number(model.confidence),params.confidence),
                additionalOutput=true,sourceContributions={itemdb=1}}
        end
    end
    for id,quantity in pairs(params.nontradableExtraOutputs or {}) do
        if quantity>0 and weight>0 and not nontradableSeen[id] then result.materials[#result.materials+1]={id=id,
            expectedQuantity=quantity*weight*result.inputCount/number(model.generalProjectionInputCount,1),
            confidence=math.min(number(model.confidence),params.confidence),economicPolicy='nontradable',additionalOutput=true} end
    end
    result.generalAdditionsApplied=true
    return result
end

-- Quality changes redistribute a verified sibling pool, conserving its units.
-- Only the ItemDB term is routed; personal/imported/legacy contributions keep
-- their original identities and weights. Family membership comes from Item's
-- CraftingQualityID/ModifiedCraftingReagentItemID, never numeric item-ID order.
function LL:ApplyGeneralProfessionQuality(f,option,model,context)
    if not model or not model.generalProfessionApplied or model.generalQualityApplied then return model end
    local data=self.ItemDB and self.ItemDB.professionProfiles
    local params=model.generalProfessionParameters
    if not data or not data.items or not data.qualityFamilies or not params then return model end
    if lookup(data.recipeQualityModels,option.recipeID) then
        return self:ApplyRecipeProfessionQuality(f,option,model,params)
    end
    -- A zero profile is the ordinary baseline itself. Dedicated, verified
    -- recipe models above retain their own source/target calibration.
    if params.skill==0 then return model end
    context=model.projectedContext or context or {}
    local recipe=lookup(data.recipes,option.recipeID)
    -- Random processing ranks need their own measured model. Crafting
    -- thresholds describe crafted outputs, not disenchant/mill/prospect rolls.
    if option.name=='Disenchant' or option.name=='Mill' or option.name=='Prospect' or option.name=='Crush' then return model end
    if not recipe or not recipe.supportsQuality then return model end
    local rank=self:ProfessionQualityRank(params,recipe,context)
    local groups={}
    for index,m in ipairs(model.materials or {}) do
        local item=lookup(data.items,m.id)
        local familyID=item and item.qualityFamilyID
        if not familyID and m.rankIDs and m.rankIDs[1] then
            item=lookup(data.items,m.rankIDs[1]);familyID=item and item.qualityFamilyID
        end
        local family=lookup(data.qualityFamilies,familyID)
        if family and #(family.rankItemIDs or {})>1 then
            local valid=m.economicPolicy~='nontradable'
            for _,id in ipairs(m.rankIDs or {m.id}) do if not contains(family.rankItemIDs,id) then valid=false end end
            if valid then
                groups[familyID]=groups[familyID] or {family=family,entries={},total=0,aggregate=false,exact=false}
                local group=groups[familyID]
                group.entries[#group.entries+1]={index=index,material=m}
                if m.rankIDs then group.aggregate=true else group.exact=true end
            end
        end
    end
    local result=copy(model);local additions={};local changed=false
    for familyID,group in pairs(groups) do
        if not (group.aggregate and group.exact) then
            local qualityConfidence=math.min(number(params.confidence),
                lookup(model.familyQualityConfidence,familyID) or 100)
            local quantities,valid={},true
            for _,entry in ipairs(group.entries) do
                local m=entry.material
                for key in pairs(model.generalProjectedSources or {itemdb=true}) do
                    local alpha=m.sourceContributions and m.sourceContributions[key] or 0
                    local source=m.sourceEstimates and m.sourceEstimates[key]
                    if alpha>0 then
                        if not source or type(source.expectedQuantity)~='number' or not source.inputCount or source.inputCount<=0
                            or type(m.expectedQuantity)~='number' then valid=false;break end
                        -- Reviewed source-anchored terms were already routed
                        -- before blending. Route only the remaining accepted
                        -- quantity, even when ItemDB also contributes ordinary
                        -- baselines for this same output/source key.
                        local unrouted=source.unprojectedQualityExpectedQuantity
                        if unrouted==nil then unrouted=source.expectedQuantity end
                        local quantity=alpha*unrouted*model.inputCount/source.inputCount
                        quantities[entry.index]=(quantities[entry.index] or 0)+quantity;group.total=group.total+quantity
                    end
                end
                if not valid or (quantities[entry.index] or 0)>number(m.expectedQuantity)+1e-8 then valid=false;break end
            end
            local targetID=rank and group.family.rankItemIDs[rank]
            if valid and targetID and group.total>0 then
                local targetIndex,upgraded= nil,0
                for _,entry in ipairs(group.entries) do
                    local material=entry.material
                    if material.id==targetID and not material.rankIDs then targetIndex=entry.index end
                    local sourceRank
                    for r,id in ipairs(group.family.rankItemIDs) do if material.id==id then sourceRank=r;break end end
                    -- The ordinary baseline already identifies these units.
                    -- A bonus may upgrade them, never downgrade a known higher
                    -- rank merely because a lower threshold was selected.
                    if not material.rankIDs and (not sourceRank or sourceRank>=rank) then
                        quantities[entry.index]=0
                    end
                    upgraded=upgraded+(quantities[entry.index] or 0)
                end
                for _,entry in ipairs(group.entries) do
                    local quantity=quantities[entry.index] or 0
                    if quantity>0 then
                        local m=result.materials[entry.index]
                        m.expectedQuantity=math.max(0,m.expectedQuantity-quantity)
                        if m.expectedQuantity<1e-12 then m.expectedQuantity=0 end
                        m.chance=nil;m.minQuantity=nil;m.maxQuantity=nil;m.probabilityVerified=false
                        m.quantityCounts=nil;m.personalHistogram=nil;m.fieldEvidence=nil
                        m.confidence=math.min(number(m.confidence),qualityConfidence)
                    end
                end
                if upgraded>0 and targetIndex then
                    local material=result.materials[targetIndex]
                    material.expectedQuantity=material.expectedQuantity+upgraded
                    qualityMaterialChanged(material,qualityConfidence)
                elseif upgraded>0 then additions[#additions+1]={id=targetID,expectedQuantity=upgraded,
                    confidence=math.min(number(model.confidence),qualityConfidence),projectedQualityRank=rank,
                    sourceContributions={itemdb=1}} end
                changed=changed or upgraded>0
            end
        end
    end
    if not changed then return model end
    for _,m in ipairs(additions) do result.materials[#result.materials+1]=m end
    -- Empty pooled placeholders would overlap the newly routed exact rank.
    local materials={}
    for _,m in ipairs(result.materials) do
        if not (m.rankIDs and m.expectedQuantity==0) then materials[#materials+1]=m end
    end
    result.materials=materials;result.generalQualityApplied=true;result.skillQualityApplied=true
    result.ruleConfidence=math.min(number(result.ruleConfidence,100),number(params.confidence,100))
    result.qualityRank=rank;result.skillQualityRank=rank
    return result
end

-- Apply only the already-normalized source contributions. Their original
-- provenance and fusion weights stay attached; unrelated sources stay intact.
function LL:ApplyRecipeProfessionQuality(f,option,model,params)
    if model.recipeQualityApplied then return model end
    local rule=recipeQualityModel(self,params,option)
    if not rule then return model end
    local selected,byRank={},{}
    for rank,id in ipairs(rule.rankItemIDs) do
        selected[rank]=0
        for index,material in ipairs(model.materials or {}) do
            if material.id==id and not material.rankIDs and material.economicPolicy~='nontradable' then
                if byRank[rank] or type(material.expectedQuantity)~='number' then return model end
                byRank[rank]={index=index,material=material}
                for key in pairs(model.generalProjectedSources or {}) do
                    local alpha=material.sourceContributions and material.sourceContributions[key] or 0
                    local source=material.sourceEstimates and material.sourceEstimates[key]
                    if alpha>0 then
                        if not source or type(source.expectedQuantity)~='number' or number(source.inputCount)<=0 then return model end
                        selected[rank]=selected[rank]+alpha*source.expectedQuantity*model.inputCount/source.inputCount
                    end
                end
                if selected[rank]>material.expectedQuantity+1e-8 then return model end
            end
        end
    end
    local quantities=self:RecipeQualityQuantities(selected,params,option,false)
    if not quantities then return model end
    local result=copy(model)
    for rank,id in ipairs(rule.rankItemIDs) do
        local entry=byRank[rank]
        local material=entry and result.materials[entry.index]
        if not material and quantities[rank]>0 then
            material={id=id,expectedQuantity=0,confidence=rule.confidence}
            result.materials[#result.materials+1]=material
        end
        if material then
            material.expectedQuantity=math.max(0,material.expectedQuantity-selected[rank])+quantities[rank]
            qualityMaterialChanged(material,rule.confidence)
        end
    end
    result.confidence=math.min(number(result.confidence,100),rule.confidence)
    result.ruleConfidence=math.min(number(result.ruleConfidence,100),rule.confidence)
    result.recipeQualityApplied=true;result.generalQualityApplied=true;result.skillQualityApplied=true
    result.recipeQualityRule=rule.ruleID
    return result
end
