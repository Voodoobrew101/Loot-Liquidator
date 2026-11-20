local _,LL=...
-- Typed client effects feed one inverse/forward model. Observations, counts and
-- probability estimates are never rewritten by this module.
local function copy(v)
    if type(v)~='table' then return v end
    local r={} for k,x in pairs(v) do r[k]=copy(x) end return r
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
local statKeys={'resourcefulness','multicraft','ingenuity','finesse','perception','deftness','craftingSpeed','inspiration'}
local nativeNames={resourcefulness='Resourcefulness',multicraft='Multicraft',ingenuity='Ingenuity',
    finesse='Finesse',perception='Perception',deftness='Deftness',craftingSpeed='Crafting Speed',inspiration='Inspiration'}
local function methodIsGather(method) return method=='Gather' or method=='Skin' or method=='Fish' end
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
    if s.method and s.method~=option.name and not alternate and not (s.method=='Gather' and methodIsGather(option.name)) then return false end
    if s.inputRarity and s.inputRarity~=facts.quality and not alternate then return false end
    if s.inputClassID and s.inputClassID~=facts.classID then return false end
    if s.scopeUnknown then return false end
    if #(s.labelIDs or {})>0 and s.labelContext~='disenchant-input'
        and not intersect(s.labelIDs,option.labels or context.recipeLabels or (recipe and recipe.labels)) then return false end
    if s.labelContext=='disenchant-input' and option.name~='Disenchant' and not alternate then return false end
    return conditionMatches(effect,context)
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

function LL:ProfessionProfileParameters(profession,expansion,context,option,facts)
    context=context or {};option=option or {};facts=facts or {}
    local data=self.ItemDB and self.ItemDB.professionProfiles or {}
    local profile=data.profiles and data.profiles[profession..':'..tostring(expansion)]
    if GetBuildInfo and self.ProfessionRuleMatchesBuild and not self:ProfessionRuleMatchesBuild(data) then profile=nil end
    local recipe=lookup(data.recipes,option.recipeID) or {}
    if methodIsGather(option.name) and option.qualityThresholds then
        recipe=copy(recipe);recipe.qualityThresholds=option.qualityThresholds
        recipe.difficulty=option.difficulty or recipe.difficulty;recipe.supportsQuality=true
    end
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
        appliedEffects={},unlocks={},extraOutputs={},minimumOutputs={},nontradableExtraOutputs={},relativeExtraOutputs={},namedOutputs={},opportunityEffects={},effectTotals={},duration=number(recipe.baseDuration,number(context.duration,number(context.craftTime))),
        concentrationCost=number(context.concentrationCost),concentrationRefund=number(context.concentrationRefund),
        outputFactor=1,inputFactor=1,recipe=recipe,eligible=number(context.skill)>=number(recipe.minimumSkill)}
    local customQuality=lookup(data.recipeQualityModels,option.recipeID)
    if customQuality and params.inputQuality==nil then
        for rank,id in ipairs(customQuality.inputRankItemIDs) do if id==facts.id then params.inputQuality=rank end end
    end
    local ratings,percents={},{}
    local pendingOutputs={}
    for _,key in ipairs(statKeys) do ratings[key]=0;percents[key]=0 end
    local function apply(effect,multiplier)
        if effect.dedicatedHandler then return end
        if not scopeMatches(effect,profession,expansion,context,option,facts,recipe) then return end
        local metric=effect.metric
        if skillIncludes and metric=='skill' then return end
        -- Native operations already contain skill and talent stat grants.
        if live and (metric=='difficulty' or metric=='concentrationCost'
            or metric=='concentrationRefund' or ratings[metric]~=nil) then return end
        local amount=number(effect.amount)*multiplier*(effect.operator=='subtract' and -1 or 1)
        local selected=lookup(context.effectStates,effect.entryID)
        if effect.condition and effect.condition.maxStacks and type(selected)=='table' and selected.active then
            amount=amount*clamp(number(selected.stacks,1),1,effect.condition.maxStacks)
        elseif effect.condition and effect.condition.maxStacks then
            local stacks=1
            for _,id in ipairs(effect.condition.spellIDs or {}) do stacks=math.max(stacks,number(lookup(context.buffStacks,id),1)) end
            amount=amount*clamp(stacks,1,effect.condition.maxStacks)
        end
        params.appliedEffects[#params.appliedEffects+1]={entryID=effect.entryID,metric=metric,amount=amount,
            mechanism=effect.mechanism,confidence=effect.confidence}
        if metric~='nonOutput' then params.confidence=math.min(params.confidence,number(effect.confidence)) end
        if metric=='skill' then params.skillBonus=params.skillBonus+amount
        elseif metric=='difficulty' then params.difficulty=params.difficulty+amount
        elseif ratings[metric]~=nil then
            if effect.unit=='rating' then ratings[metric]=ratings[metric]+amount
            else percents[metric]=percents[metric]+amount end
        elseif metric=='recipeUnlock' or metric=='eligibility' then
            for _,id in ipairs(effect.recipeIDs or {}) do params.unlocks[id]=true end
            if metric=='eligibility' then params.simulatedEligibility=true end
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
        elseif binding.kind=='gather-target-primary' then
            ids=copy(option.primaryOutputIDs or (option.baseline and option.baseline.primaryOutputIDs) or {})
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
            params.opportunityEffects[#params.opportunityEffects+1]=copy(effect)
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
        local current=lookup(context.stats,key) or nativeStat(context,key) or {}
        local anchor=lookup(context.statAnchors,key) or current
        local calibration=lookup(context.statCalibration,key) or anchor
        local slope
        if number(calibration.rating)>0 then slope=number(calibration.percent)/calibration.rating end
        if not slope or slope<=0 then slope=.1 end -- declared low-confidence rating prior
        local basePercent=number(current.percent)+(number(current.rating)-number(anchor.rating))*slope
        local percent=basePercent+ratings[key]*slope+percents[key]
        if (ratings[key]~=0 or (number(current.rating)-number(anchor.rating))~=0) and
            number(calibration.rating)<=0 then params.confidence=math.min(params.confidence,10) end
        params.stats[key]=key=='craftingSpeed' and math.max(0,percent)
            or key=='deftness' and math.max(0,percent/100) or clamp(percent/100,0,1)
        if profile and not contains(profile.statKeys,key) and ratings[key]==0 and percents[key]==0 then params.stats[key]=0 end
    end
    local method=option.name
    local gather=methodIsGather(method)
    local opportunity=method=='Loot' or method=='Use'
    local de=method=='Disenchant'
    local stochastic=de or method=='Mill' or method=='Prospect' or method=='Crush'
    local supportsMC=option.supportsMulticraft
    if supportsMC==nil then supportsMC=recipe.supportsMulticraft end
    if explicitNativeStats then supportsMC=nativeStat(context,'multicraft')~=nil end
    if supportsMC==nil then supportsMC=number(recipe.outputCount,number(option.outputCount))>1 end
    local extraFraction=(number(native.MinCraftExtraQtyPct,1)+number(native.MaxCraftExtraQtyPct,250))/200
    if not stochastic and not gather and not opportunity and not customQuality and supportsMC then
        params.outputFactor=1+params.stats.multicraft*extraFraction*(1+number(params.effectTotals.multicraftExtra)/100)
        if params.stats.multicraft>0 then params.confidence=math.min(params.confidence,15) end
        if not explicitNativeStats and recipe.capabilityConfidence then
            params.confidence=math.min(params.confidence,number(recipe.capabilityConfidence.multicraft,100))
        end
    end
    if not de and not gather and not opportunity and option.supportsResourcefulness~=false and recipe.supportsResourcefulness~=false then
        local saved=(number(native.ResourcefulEffectLow,20)+number(native.ResourcefulEffectHigh,40))/200
        params.inputFactor=clamp(1-params.stats.resourcefulness*saved*(1+number(params.effectTotals.resourcefulnessSaved)/100),.01,1)
        if params.stats.resourcefulness>0 then params.confidence=math.min(params.confidence,15) end
    end
    if gather then
        params.outputFactor=1+params.stats.finesse*(1+number(params.effectTotals.finesseExtra)/100)
        params.rareDiscoveryFactor=1+params.stats.perception
        if params.stats.finesse>0 or params.stats.perception>0 then params.confidence=math.min(params.confidence,5) end
    end
    params.outputFactor=params.outputFactor*(1+number(params.effectTotals.yieldMultiplier)/100)
    params.sameOutputExtra=math.max(0,number(params.sameOutputExtra))
    local speed=gather and params.stats.deftness*100 or params.stats.craftingSpeed
    params.speedFactor=1+speed/100
    if not recipe.baseDuration and context.durationIncludesSpeed then
        local key=gather and 'deftness' or 'craftingSpeed'
        local calibration=lookup(context.statCalibration,key) or nativeStat(context,key) or {}
        params.duration=params.duration*(1+number(calibration.percent)/100)
        if not calibration.percent then params.confidence=math.min(params.confidence,0) end
    end
    params.baseDuration=params.duration
    params.duration=params.duration/params.speedFactor
    params.concentrationCost=params.concentrationCost*math.max(0,1+number(params.effectTotals.concentrationCost)/100)
    local refund=number(context.ingenuityRefundFraction,.5)
    if type(context.ingenuityRefund)=='number' and params.concentrationCost>0 then refund=context.ingenuityRefund/params.concentrationCost end
    params.concentrationRefund=clamp(refund+number(params.effectTotals.concentrationRefund)/100,0,1)*params.stats.ingenuity
    params.expectedConcentrationCost=params.concentrationCost*(1-params.concentrationRefund)
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
    local data=self.ItemDB and self.ItemDB.professionProfiles
    if lookup(data and data.recipeQualityModels,params.recipeID) then
        local adjusted,why=modelRecipeQuality(self,raw,params,option,true)
        if not adjusted then return nil,why end
    end
    for _,m in ipairs(raw.materials or {}) do
        if type(m.expectedQuantity)=='number' then
            local extras=m.economicPolicy=='nontradable' and params.nontradableExtraOutputs or params.extraOutputs
            if (params.minimumOutputs[m.id] or 0)>0 and m.expectedQuantity<=params.minimumOutputs[m.id] then
                return nil,'Guaranteed floor does not identify an invertible source mean'
            end
            m.expectedQuantity=m.expectedQuantity-(extras and extras[m.id] or 0)
            if params.sameOutputExtra>0 and #(raw.materials or {})==1 then m.expectedQuantity=m.expectedQuantity-params.sameOutputExtra end
            local factor=params.outputFactor
            if methodIsGather(params.method) and option then
                if m.rareDiscovery or contains(option.rareOutputIDs,m.id) then factor=params.rareDiscoveryFactor or 1
                elseif option.primaryOutputIDs and not contains(option.primaryOutputIDs,m.id) then factor=1 end
            end
            m.expectedQuantity=m.expectedQuantity/(factor*(1+number(lookup(params.relativeExtraOutputs,m.id))))
            if m.expectedQuantity<0 then return nil,'Source cannot be inverted under declared profile' end
        end
    end
    if params.method=='Disenchant' and params.expansionID~=11 and params.skill>0 then
        local data=self.ItemDB and self.ItemDB.professionProfiles or {}
        local groups={}
        for _,m in ipairs(raw.materials or {}) do
            local item=lookup(data.items,m.id)
            local family=item and item.subclassID==12 and lookup(data.qualityFamilies,item.qualityFamilyID)
            if family and #family.rankItemIDs>1 and not m.rankIDs and type(m.expectedQuantity)=='number' then
                local key=item.qualityFamilyID
                groups[key]=groups[key] or {family=family,items={}}
                groups[key].items[m.id]=m
            end
        end
        local progress=clamp(params.skill/math.max(1,params.skillMaximum),0,1)
        for _,group in pairs(groups) do
            local complete,total=true,0
            local ids=group.family.rankItemIDs
            for _,id in ipairs(ids) do
                if not group.items[id] then complete=false else total=total+group.items[id].expectedQuantity end
            end
            if complete and progress>0 then
                if progress>=1 then return nil,'Saturated quality profile requires a declared independent prior' end
                for rank,id in ipairs(ids) do
                    local share=rank==#ids and .66 or rank==#ids-1 and .34 or 0
                    local value=(group.items[id].expectedQuantity-progress*total*share)/(1-progress)
                    if value < -1e-8 then return nil,'Source quality mix cannot be inverted under this prior' end
                    group.items[id].expectedQuantity=math.max(0,value)
                end
                raw.normalizationConfidence=0
            end
        end
    end
    if raw.expectedInputCount then raw.expectedInputCount=raw.expectedInputCount/params.inputFactor end
    if raw.duration then raw.duration=raw.duration*params.speedFactor end
    raw.baselineNormalized=true
    return raw
end

function LL:ProjectProfessionBaseline(baseline,params,option)
    if not baseline or not params then return nil end
    local raw=baseline.rawProfessionBaseline or baseline
    local result=copy(raw);result.rawProfessionBaseline=copy(raw)
    local seen,nontradableSeen={},{}
    for _,m in ipairs(result.materials or {}) do
        if m.economicPolicy=='nontradable' then nontradableSeen[m.id]=true else seen[m.id]=true end
        if type(m.expectedQuantity)=='number' then
            local extras=m.economicPolicy=='nontradable' and params.nontradableExtraOutputs or params.extraOutputs
            local factor=params.outputFactor
            if methodIsGather(params.method) and option then
                if m.rareDiscovery or contains(option.rareOutputIDs,m.id) then factor=params.rareDiscoveryFactor or 1
                elseif option.primaryOutputIDs and not contains(option.primaryOutputIDs,m.id) then factor=1 end
            end
            local value=m.expectedQuantity*factor*(1+number(lookup(params.relativeExtraOutputs,m.id)))+(extras and extras[m.id] or 0)
            value=math.max(value,params.minimumOutputs[m.id] or 0)
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
    result.duration=number(raw.duration)*params.speedFactor^(-1)
    result.concentrationCost=params.expectedConcentrationCost
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
    result.namedOutputs=copy(params.namedOutputs or {})
    if #result.namedOutputs>0 then result.unknownOutputs=true end
    result.generalProfessionApplied=true;result.professionProjected=true
    result.mechanicsApplied=true
    return result
end

function LL:ApplyGeneralProfessionModel(f,option,model,context)
    if not model or (option.name=='Disenchant' and f.expansionID==11) or model.professionProjected then return model end
    local data=self.ItemDB and self.ItemDB.professionProfiles
    local recipe=data and lookup(data.recipes,option.recipeID)
    local profession=option.profession or (recipe and recipe.profession) or (self.ProfessionForMethod and self:ProfessionForMethod(option.name))
    local expansion=option.expansionID or (recipe and recipe.expansionID) or f.expansionID
    if not data or not data.profiles or not profession or not expansion or not data.profiles[profession..':'..expansion] then return model end
    local contextFacts=copy(f);contextFacts.expansionID=expansion
    context=context or (self.ProcessingPlayerConditions and self:ProcessingPlayerConditions(contextFacts,option.name,option.recipeID,option.character,profession)) or {}
    local source=copy(model.baselineProfile or {})
    local assumed=not model.baselineProfile
    source.skill=source.skill or source.effectiveSkill or 0;source.preSpecializationSkill=source.preSpecializationSkill or source.skill
    source.specializationPoints=source.specializationPoints or {};source.stats=source.stats or {}
    local target=self:ProfessionProfileParameters(profession,expansion,context,option,f)
    if assumed then target.confidence=math.min(target.confidence,5) end
    local baseline=self.ItemDB.modeledProfessionBaselines and self.ItemDB.modeledProfessionBaselines[model.recordID]
    if baseline then
        -- The compiled object supplies only normalized numerical fields. Keep
        -- runtime evidence metadata, source identity and material order intact.
        local merged=copy(model)
        for index,material in ipairs(merged.materials or {}) do
            local normalized=baseline.materials[index]
            if not normalized or normalized.id~=material.id then return model end
            material.expectedQuantity=normalized.expectedQuantity
        end
        merged.expectedInputCount=baseline.expectedInputCount;merged.duration=baseline.duration
        target.confidence=math.min(target.confidence,number(baseline.baselineConfidence,100),number(baseline.normalizationConfidence,100))
        baseline=merged
    else
        local sourceParams=self:ProfessionProfileParameters(profession,expansion,source,option,f)
        baseline=self:NormalizeProfessionBaseline(model,sourceParams,option)
        target.confidence=math.min(target.confidence,sourceParams.confidence,number(baseline and baseline.normalizationConfidence,100))
    end
    if not baseline then return model end
    local settings=copy(option);settings.preserveMaterialIdentity=true;settings.deferRecipeQuality=true
    local projected=self:ProjectProfessionBaseline(baseline,target,settings)
    projected.projectedContext=copy(context)
    projected.projectedContext.effectiveSkill=target.skill
    for _,m in ipairs(projected.materials or {}) do m.appliedProfessionRule='profession-profile-rules/1' end
    projected.sourceProfileAssumed=assumed
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
    local settings=copy(option);settings.deferRecipeQuality=true;settings.preserveMaterialIdentity=true
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
    local option=copy(c);option.name=c.method or c.name
    local contextFacts=copy(f);contextFacts.expansionID=expansion
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
            expectedQuantity=c.outputCount,confidence=100}},duration=params.baseDuration,
        confidence=100,source='Profession recipe',sourceKey='recipe'}
    local model=self:ProjectProfessionBaseline(baseline,params,option)
    model.qualityRank=(qualityItems or recipe and recipe.supportsQuality or ctx.qualityFromBlizzard) and rank or nil
    model.projectedContext=copy(ctx)
    model.context=copy(ctx);model.context.effectiveSkill=params.skill
    model.simulated=ctx.simulated
    model.supplyCostFactor=params.inputFactor
    if self.ApplySyntheticBenchmark then model=self:ApplySyntheticBenchmark(f,option,model,ctx) end
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
    context=model.projectedContext or context or {}
    local recipe=lookup(data.recipes,option.recipeID)
    local disenchant=option.name=='Disenchant' and f.expansionID~=11
    if not disenchant and (not recipe or not recipe.supportsQuality) then return model end
    local rank=not disenchant and self:ProfessionQualityRank(params,recipe,context) or nil
    local groups={}
    for index,m in ipairs(model.materials or {}) do
        local item=lookup(data.items,m.id)
        local familyID=item and item.qualityFamilyID
        if not familyID and m.rankIDs and m.rankIDs[1] then
            item=lookup(data.items,m.rankIDs[1]);familyID=item and item.qualityFamilyID
        end
        local family=lookup(data.qualityFamilies,familyID)
        if disenchant and (not item or item.subclassID~=12) then family=nil end
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
    for _,group in pairs(groups) do
        if not (group.aggregate and group.exact) then
            local quantities,valid={},true
            for _,entry in ipairs(group.entries) do
                local m=entry.material
                for key in pairs(model.generalProjectedSources or {itemdb=true}) do
                    local alpha=m.sourceContributions and m.sourceContributions[key] or 0
                    local source=m.sourceEstimates and m.sourceEstimates[key]
                    if alpha>0 then
                        if not source or type(source.expectedQuantity)~='number' or not source.inputCount or source.inputCount<=0
                            or type(m.expectedQuantity)~='number' then valid=false;break end
                        local quantity=alpha*source.expectedQuantity*model.inputCount/source.inputCount
                        quantities[entry.index]=(quantities[entry.index] or 0)+quantity;group.total=group.total+quantity
                    end
                end
                if not valid or (quantities[entry.index] or 0)>number(m.expectedQuantity)+1e-8 then valid=false;break end
            end
            local targetID=rank and group.family.rankItemIDs[rank]
            if disenchant then
                -- Cross-era quality prior: retain the zero-profile source mix,
                -- then interpolate to 66% highest rank, remainder next rank.
                -- No empirical endpoint/count is asserted for this fallback.
                local progress=clamp(params.skill/math.max(1,params.skillMaximum),0,1)
                local n=#group.family.rankItemIDs
                if valid and group.total>0 and progress>0 then
                    local byID={}
                    for _,entry in ipairs(group.entries) do
                        local m=result.materials[entry.index]
                        local amount=quantities[entry.index] or 0
                        if amount>0 then
                            m.expectedQuantity=math.max(0,m.expectedQuantity-amount*progress)
                            m.chance=nil;m.minQuantity=nil;m.maxQuantity=nil;m.probabilityVerified=false
                            m.quantityCounts=nil;m.personalHistogram=nil;m.fieldEvidence=nil;m.confidence=0
                        end
                        if not m.rankIDs then byID[m.id]=m end
                    end
                    for _,allocation in ipairs({{n,.66},{n-1,.34}}) do
                        local id=group.family.rankItemIDs[allocation[1]]
                        local amount=group.total*progress*allocation[2]
                        if byID[id] then byID[id].expectedQuantity=byID[id].expectedQuantity+amount
                        else additions[#additions+1]={id=id,expectedQuantity=amount,confidence=0,sourceContributions={itemdb=1}} end
                    end
                    result.ruleConfidence=0;result.confidence=0;changed=true
                end
            elseif valid and targetID and group.total>0 then
                local targetIndex
                for _,entry in ipairs(group.entries) do if entry.material.id==targetID and not entry.material.rankIDs then targetIndex=entry.index end end
                for _,entry in ipairs(group.entries) do
                    local quantity=quantities[entry.index] or 0
                    if quantity>0 then
                        local m=result.materials[entry.index]
                        m.expectedQuantity=math.max(0,m.expectedQuantity-quantity)
                        m.chance=nil;m.minQuantity=nil;m.maxQuantity=nil;m.probabilityVerified=false
                        m.quantityCounts=nil;m.personalHistogram=nil;m.fieldEvidence=nil
                        m.confidence=math.min(number(m.confidence),params.confidence)
                    end
                end
                if targetIndex then result.materials[targetIndex].expectedQuantity=result.materials[targetIndex].expectedQuantity+group.total
                else additions[#additions+1]={id=targetID,expectedQuantity=group.total,
                    confidence=math.min(number(model.confidence),params.confidence),projectedQualityRank=rank,
                    sourceContributions={itemdb=1}} end
                changed=true
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

function LL:GatheringSimulationModel(target,context)
    if type(target)~='table' or not methodIsGather(target.method or target.name) then return nil end
    local option=copy(target);option.name=target.method or target.name;option.inputCount=1
    local profession=target.profession
    local expansion=target.expansionID
    if not profession or not expansion then return nil end
    context=context or self:ProcessingPlayerConditions({expansionID=expansion},option.name,target.recipeID,nil,profession)
    if not context.simulated and self.CharacterKey and context.character==self:CharacterKey()
        and C_TradeSkillUI and type(C_TradeSkillUI.GetGatheringOperationInfo)=='function' then
        local ok,info=pcall(C_TradeSkillUI.GetGatheringOperationInfo,target.recipeID)
        if ok and type(info)=='table' then
            context=copy(context)
            if self.CopyProfessionOperationContext then self:CopyProfessionOperationContext(context,info,target.recipeID) end
            if info.baseSkill and info.bonusSkill then context.effectiveSkill=info.baseSkill+info.bonusSkill end
            if info.maxDifficulty then option.difficulty=info.maxDifficulty end
        end
    end
    local params=self:ProfessionProfileParameters(profession,expansion,context,option,target)
    local baseline=target.baseline
    local result
    if baseline and type(baseline.materials)=='table' then
        local source=target.sourceProfile or {skill=0,preSpecializationSkill=0,stats={},specializationPoints={}}
        local sourceParams=self:ProfessionProfileParameters(profession,expansion,source,option,target)
        params.confidence=math.min(params.confidence,sourceParams.confidence,number(baseline.confidence,100))
        local normalized=self:NormalizeProfessionBaseline(baseline,sourceParams,option)
        if normalized then result=self:ProjectProfessionBaseline(normalized,params,option) end
    end
    result=result or {materials={},confidence=params.confidence}
    result.professionParameters=params;result.skill=params.skill;result.yieldFactor=params.outputFactor
    result.rareDiscoveryFactor=params.rareDiscoveryFactor;result.speedFactor=params.speedFactor
    result.qualityRank=(target.qualityThresholds or params.recipe.supportsQuality)
        and self:ProfessionQualityRank(params,params.recipe,context) or nil
    if baseline and target.primaryOutputIDs and self.ItemDB and self.ItemDB.professionProfiles then
        local data=self.ItemDB.professionProfiles
        local first=lookup(data.items,target.primaryOutputIDs[1])
        local family=first and lookup(data.qualityFamilies,first.qualityFamilyID)
        if family and #family.rankItemIDs>1 then
            local rank=result.qualityRank
            if target.qualityThresholds then rank=self:ProfessionQualityRank(params,{qualityThresholds=target.qualityThresholds},context) end
            local id=family.rankItemIDs[rank]
            if id then
                local kept,total={},0
                for _,m in ipairs(result.materials) do
                    if contains(target.primaryOutputIDs,m.id) then total=total+number(m.expectedQuantity)
                    else kept[#kept+1]=m end
                end
                kept[#kept+1]={id=id,expectedQuantity=total,confidence=math.min(result.confidence,number(target.qualityConfidence))}
                result.materials=kept;result.qualityRank=rank
            end
        end
    end
    result.targetID=target.targetID;result.actionable=false;result.generalProfessionApplied=true
    result.inputCount=result.inputCount or 1
    if self.ApplySyntheticBenchmark then
        result=self:ApplySyntheticBenchmark(target,option,result,context)
        if result.benchmarkOutputFactor then result.yieldFactor=result.yieldFactor*result.benchmarkOutputFactor end
    end
    return result
end

-- These are normalized scenario indexes, not item quantities per kill/use and
-- not liquidation EV. Real item identities remain separate from named pools.
function LL:OpportunitySimulationModel(target,context)
    if type(target)~='table' or (target.method~='Loot' and target.method~='Use')
        or type(target.profession)~='string' or type(target.expansionID)~='number' then return nil end
    context=context or {}
    local option={name=target.method,labels=copy(target.labels or {}),inputCount=1}
    local params=self:ProfessionProfileParameters(target.profession,target.expansionID,context,option,
        {expansionID=target.expansionID})
    local data=self.ItemDB and self.ItemDB.professionProfiles or {}
    local relativeOutputs={}
    local total=0
    local function itemName(id)
        local item=lookup(data.items,id)
        return item and item.name or 'Item '..id
    end
    local function add(name,value,metric,unit,id,policy)
        if type(value)=='number' and value~=0 then
            relativeOutputs[#relativeOutputs+1]={name=name,value=value,metric=metric,unit=unit,id=id,
                economicPolicy=policy,confidence=0}
            if metric=='additional-output' then total=total+value end
        end
    end
    for id,quantity in pairs(params.extraOutputs) do add(itemName(id),quantity,'additional-output','normalized-additional-units',id) end
    for id,quantity in pairs(params.nontradableExtraOutputs) do add(itemName(id),quantity,'additional-output','normalized-additional-units',id,'nontradable') end
    for id,fraction in pairs(params.relativeExtraOutputs) do add(itemName(id),1+fraction,'discovery','relative-factor',id) end
    for id,minimum in pairs(params.minimumOutputs) do add(itemName(id),minimum,'guaranteed-output-floor','normalized-output-floor',id) end
    for _,named in ipairs(params.namedOutputs) do
        if type(named.expectedQuantity)=='number' then add(named.name,named.expectedQuantity,'additional-output','normalized-additional-units')
        elseif type(named.discoveryFactor)=='number' then add(named.name,named.discoveryFactor,'discovery','relative-factor')
        elseif type(named.chance)=='number' then
            -- A typed chance term is displayed on a reference index rather
            -- than asserted as an absolute probability for an unknown kill.
            add(named.name,1+named.chance,'discovery','relative-factor')
        end
    end
    table.sort(relativeOutputs,function(a,b)
        return a.name==b.name and a.metric<b.metric or a.name<b.name
    end)
    local result={kind='profession-opportunity-preview',targetID=target.targetID,method=target.method,
        profession=target.profession,expansionID=target.expansionID,actionable=false,
        confidence=0,baselineIndex=1,outputIndex=1+total,quantityBasis=target.quantityBasis,
        relativeOutputs=relativeOutputs,params=params,professionParameters=params,
        unlocks=copy(params.unlocks),effectTotals=copy(params.effectTotals),appliedEffects=copy(params.appliedEffects),
        materials={},namedOutputs={},inputCount=1,context=copy(context)}
    if self.ApplySyntheticBenchmark then
        result=self:ApplySyntheticBenchmark({expansionID=target.expansionID},option,result,context)
        local factor=result.benchmarkOutputFactor
        if factor then
            result.outputIndex=result.outputIndex*factor
            for _,output in ipairs(result.relativeOutputs) do
                if output.unit=='normalized-additional-units' or output.unit=='normalized-output-floor' then output.value=output.value*factor end
            end
        end
    end
    return result
end
