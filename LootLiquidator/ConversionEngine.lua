-- Loot Liquidator: rank ONLY conversions the current character or a verified alt can perform.
-- Prices are quoted in copper per original input. No automatic crafting or selling.
local _, LL = ...
local processingMethodLetters={Disenchant="D",Mill="M",Prospect="P",Smelt="S"}
local conversionMethodLetters={Disenchant="D",Mill="M",Prospect="P",Smelt="S",
    Recycle="R",Research="R",Combine="X",Split="X",Exchange="X",Craft="C"}

-- Single authoritative processing evaluation path.
-- All skill/condition matching, reference selection, and valuation live here.
-- Skill-aware processing evidence selector. No universal invented skill/drop multiplier.
-- v0.9.52: conservative matching, safe fallback, reference data is never overwritten.

local function validNumber(n)
    return type(n)=="number" and n==n and n>=0 and n<math.huge
end
local function sameCondition(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~="table" then return a==b end
    for key,value in pairs(a) do if not sameCondition(value,b[key]) then return false end end
    for key in pairs(b) do if a[key]==nil then return false end end
    return true
end
function LL:ProcessingPlayerConditions(f,method,recipeID,character)
    local profession=self.ProfessionForMethod and self:ProfessionForMethod(method)
    local current=self.CharacterKey and self:CharacterKey()
    local key=(character and character~="Current character") and character or current
    local record=self.db and self.db.characters and self.db.characters[key]
    local modeKey=processingMethodLetters[method]
    local modeValue=modeKey and self.ProcessingMethodMode and self:ProcessingMethodMode(modeKey)
    local contextKey=table.concat({tostring(key),tostring(profession),tostring(f and f.id),
        tostring(f and f.expansionID),tostring(f and f.reagentQuality),tostring(recipeID),tostring(modeValue)},":")
    local now=GetTime and GetTime() or 0
    self._processingContextCache=self._processingContextCache or {}
    local cached=self._processingContextCache[contextKey]
    if cached and now-cached.at<5 then return cached.context end
    local skill,spec,lineID
    if key==current and profession and self.GetResearchProfessionSnapshot then
        skill,spec,lineID=self:GetResearchProfessionSnapshot(f,profession)
    elseif record and type(record.researchProfiles)=="table" then
        local saved=record.researchProfiles[tostring(profession)..":"..tostring(f and f.expansionID)]
        if saved then skill,spec,lineID=saved.skill,saved.specialization,saved.lineID end
    end
    -- Some offline characters have their expansion skill in the original
    -- roster detail scan but no researchProfiles cache yet.
    if not validNumber(skill) and record and type(record.details)=="table" then
        local exp=f and f.expansionID
        local family=self.DisenchantTables and self.DisenchantTables[exp]
        local expName=family and family.name
        for id,detail in pairs(record.details) do
            if type(detail)=="table" and detail.parentName==profession
               and type(detail.name)=="string" and expName
               and (detail.name:find(expName,1,true)
                   or (exp==10 and detail.name:find("Khaz Algar",1,true)))
               and validNumber(detail.skill) then
                skill=detail.skill
                lineID=id
                break
            end
        end
    end
    local ctx={skill=skill,specialization=spec,skillLineID=lineID,
        inputID=f and f.id,inputQuality=f and f.reagentQuality,recipeID=recipeID,
        character=key,profession=profession,expansionID=f and f.expansionID,assumedMinimum=false}
    -- Blizzard operation information is specific to the CURRENT character.
    -- Never use current gear/skill when pricing an offline alt.
    if key==current and self.GetCachedOperationInfo then
        local info=self:GetCachedOperationInfo(recipeID)
        if info then
            ctx.baseSkill=info.baseSkill;ctx.bonusSkill=info.bonusSkill
            if validNumber(info.baseSkill) and validNumber(info.bonusSkill) then
                ctx.effectiveSkill=info.baseSkill+info.bonusSkill
            end
            ctx.operationStats=info.bonusStats -- Preserve typed API data; no rating-to-% guesses.
            ctx.craftingQuality=info.craftingQuality
            ctx.qualityFromBlizzard=type(info.craftingQuality)=="number"
        end
    end
    local manual=modeKey and self.ProcessingMethodMode and self:ProcessingMethodMode(modeKey)==4
        and self.AltMethodEnabled and self:AltMethodEnabled(key,modeKey)
        and record and record.altMethods and record.altMethods[modeKey]==true
    if not validNumber(ctx.effectiveSkill) and validNumber(skill) then ctx.effectiveSkill=skill end
    local saved=record and record.researchProfiles and record.researchProfiles[tostring(profession)..":"..tostring(f and f.expansionID)]
    ctx.equipment=key==current and record and record.professionEquipment or (saved and saved.equipment)
    if saved and validNumber(saved.bonusSkill) and not ctx.qualityFromBlizzard then
        ctx.baseSkill=skill;ctx.bonusSkill=saved.bonusSkill
        if validNumber(skill) then ctx.effectiveSkill=skill+saved.bonusSkill end
    end
    ctx.profileKind=key==current and "live" or "offline-snapshot"
    ctx.observed=saved and saved.observed or (record and record.observed)
    local snapshotNow=time and time()
    ctx.stale=ctx.profileKind=="offline-snapshot" and (not ctx.observed or (snapshotNow and snapshotNow-ctx.observed>7*86400)) or false
    ctx.incomplete=not validNumber(ctx.effectiveSkill) or not ctx.specialization
    local simulated=manual and self.GetManualProfessionProfile and
        self:GetManualProfessionProfile(key,profession,f and f.expansionID)
    if simulated and simulated.enabled then
        ctx.skill=simulated.skill;ctx.effectiveSkill=simulated.skill
        ctx.buffs=simulated.buffs
        ctx.specialization=simulated.specialization
        ctx.baseSkill=nil;ctx.bonusSkill=nil;ctx.operationStats=nil;ctx.craftingQuality=nil;ctx.equipment=nil
        ctx.qualityFromBlizzard=false;ctx.simulated=true;ctx.stale=false;ctx.profileKind="manual-simulation"
        ctx.incomplete=not validNumber(ctx.skill) or not ctx.specialization
    end
    ctx.skillKnown=validNumber(ctx.skill) and not ctx.simulated
    ctx.skillSource=ctx.simulated and "manual-simulation"
        or (ctx.qualityFromBlizzard and "blizzard-operation"
        or (ctx.skillKnown and "scanned-profession" or "unknown"))
    self._processingContextGeneration=(self._processingContextGeneration or 0)+1
    ctx._cacheIdentity=self._processingContextGeneration
    if (self._processingContextCache.count or 0)>=256 then self._processingContextCache={} end
    self._processingContextCache[contextKey]={at=now,context=ctx}
    self._processingContextCache.count=(self._processingContextCache.count or 0)+1
    return ctx
end
-- Compiled mechanics v0.2 adapter. Research JSON is NEVER loaded directly in WoW.
-- A build step may populate ItemDB.mechanicRules only after a rule
-- has passed recipe-specific numerical validation. Unknown means no transform.
-- This lives in the existing conversion engine to avoid another runtime module.
function LL:ApplyVerifiedMechanics(f,option,baseline)
    if baseline and (baseline.sourceKey=='itemtsm' or baseline.sourceKey=='tsm' or baseline.sourceKey=='legacy' or baseline.sourceKey=='personal') then return baseline end
    if baseline and baseline.mechanicsApplied then return baseline end
    local rules=self.ItemDB and self.ItemDB.mechanicRules
    if type(rules)~="table" or #rules==0 or type(f)~="table"
        or type(option)~="table" or type(baseline)~="table"
        or type(baseline.materials)~="table" then return baseline end
    -- The active client's gear and skill cannot be imputed to an offline alt.
    local current=self.CharacterKey and self:CharacterKey()
    local ctx
    if option.character and option.character~="Current character"
        and option.character~=current then
        ctx=self.ProcessingPlayerConditions and self:ProcessingPlayerConditions(f,option.name,option.recipeID,option.character)
        if not ctx or ctx.stale or ctx.incomplete or
            (ctx.profileKind~="offline-snapshot" and ctx.profileKind~="manual-simulation") then return baseline end
    end
    local build=GetBuildInfo and select(2,GetBuildInfo())
    if not build or not baseline.patchBuild or not baseline.referenceContextID then
        return baseline
    end
    local eligible={}
    local duplicates={}
    for _,rule in ipairs(rules) do
        if self.IsApprovedNumericRule and self:IsApprovedNumericRule(rule)
            and rule.applies=="VERIFIED_APPLIES"
            and rule.method==option.name and rule.recipeID==option.recipeID
            and rule.recipeID~=nil and rule.inputItemID==f.id
            and rule.expansionID==f.expansionID
            and ((option.name=="Disenchant" and rule.inputRarity==f.quality and rule.inputClassID==f.classID)
                or (option.name~="Disenchant" and rule.inputQualityRank==f.reagentQuality and rule.inputQualityRank~=nil))
            and tostring(rule.sourceBuild)==tostring(baseline.patchBuild)
            and tostring(rule.targetBuild)==tostring(build)
            and rule.sourceReferenceContextID==baseline.referenceContextID
            and type(rule.targetConditions)=="table" then
            local conditionsOK=true
            for name,expected in pairs(rule.targetConditions) do
                if not ctx then
                    ctx=self.ProcessingPlayerConditions and
                        self:ProcessingPlayerConditions(f,option.name,option.recipeID,option.character)
                end
                -- Never coerce an absent stat, skill, or specialization to zero.
                if not ctx or ctx[name]==nil or not sameCondition(ctx[name],expected) then
                    conditionsOK=false;break
                end
            end
            local params=rule.parameters
            local target=rule.effectTarget
            local formulaOK=type(params)=="table" and (
                (rule.formulaID=="MULTIPLY" and type(params.multiplier)=="number"
                    and params.multiplier==params.multiplier
                    and params.multiplier>=0 and params.multiplier<=10)
                or (rule.formulaID=="SET_VERIFIED_RANGE"
                    and target=="OUTPUT_POSITIVE_QUANTITY"
                    and type(params.minQuantity)=="number"
                    and type(params.maxQuantity)=="number"
                    and params.minQuantity>=1 and params.minQuantity%1==0
                    and params.maxQuantity>=params.minQuantity
                    and params.maxQuantity%1==0))
            if conditionsOK and formulaOK and
                (target=="OUTPUT_UNCONDITIONAL_EXPECTATION"
                 or target=="OUTPUT_OCCURRENCE"
                 or target=="OUTPUT_POSITIVE_QUANTITY"
                 or target=="EXPECTED_INPUT_CONSUMPTION" or target=="OPERATION_DURATION") then
                if target=="EXPECTED_INPUT_CONSUMPTION" or target=="OPERATION_DURATION" then
                    if rule.formulaID=="MULTIPLY" and (target~="EXPECTED_INPUT_CONSUMPTION" or params.multiplier<=1) then
                        if eligible[target] then duplicates[target]=true else eligible[target]=rule end
                    end
                end
                for _,material in ipairs(baseline.materials) do
                    if rule.outputItemID==material.id then
                        local key=tostring(material.id)..":"..target
                        if eligible[key] then duplicates[key]=true
                        else eligible[key]=rule end
                    end
                end
            end
        end
    end
    local changed,materials=0,{}
    for _,original in ipairs(baseline.materials) do
        local material={}
        for k,v in pairs(original) do material[k]=v end
        local prefix=tostring(original.id)..":"
        local expectation=eligible[prefix.."OUTPUT_UNCONDITIONAL_EXPECTATION"]
        local probability=eligible[prefix.."OUTPUT_OCCURRENCE"]
        local bounds=eligible[prefix.."OUTPUT_POSITIVE_QUANTITY"]
        if duplicates[prefix.."OUTPUT_UNCONDITIONAL_EXPECTATION"] then expectation=nil end
        if duplicates[prefix.."OUTPUT_OCCURRENCE"] then probability=nil end
        if duplicates[prefix.."OUTPUT_POSITIVE_QUANTITY"] then bounds=nil end
        -- No inferred probability from expected units, nor inferred range
        -- from a scaled mean. These are independent measurements.
        if expectation and expectation.formulaID=="MULTIPLY"
            and validNumber(original.expectedQuantity) then
            material.expectedQuantity=original.expectedQuantity*expectation.parameters.multiplier
            material.quantityBasis="verified build/context-specific numeric transform"
            material.transformConfidence=expectation.confidence0to100
            material.appliedExpectationRule=expectation.ruleID
            -- Old occurrence/ranges may not hold under a yield-changing rule.
            material.chance=nil;material.minQuantity=nil;material.maxQuantity=nil
            material.probabilityBasis="unknown after yield adjustment"
            changed=changed+1
        end
        if probability and probability.formulaID=="MULTIPLY"
            and original.probabilityVerified==true and validNumber(original.chance)
            and original.chance<=1 then
            local p=original.chance*probability.parameters.multiplier
            if p<=1 then
                material.chance=p;material.probabilityVerified=true
                if not material.appliedExpectationRule and p~=original.chance then
                    material.expectedQuantity=nil -- new mean needs independent supporting evidence
                end
                material.probabilityBasis="verified numeric occurrence transform"
                material.appliedProbabilityRule=probability.ruleID
                changed=changed+1
            end
        end
        if bounds and bounds.formulaID=="SET_VERIFIED_RANGE" then
            material.minQuantity=bounds.parameters.minQuantity
            material.maxQuantity=bounds.parameters.maxQuantity
            material.yieldBasis="verified conditional bounds at current build"
            material.appliedRangeRule=bounds.ruleID
            changed=changed+1
        end
        local e,p,lo,hi=material.expectedQuantity,material.chance,material.minQuantity,material.maxQuantity
        if e and p and ((p==0 and e>0) or (lo and e+1e-9<p*lo) or (hi and e>p*hi+1e-9)) then return baseline end
        materials[#materials+1]=material
    end
    local inputRule=not duplicates.EXPECTED_INPUT_CONSUMPTION and eligible.EXPECTED_INPUT_CONSUMPTION
    local timeRule=not duplicates.OPERATION_DURATION and eligible.OPERATION_DURATION
    local inputCount=inputRule and baseline.inputCount and baseline.inputCount*inputRule.parameters.multiplier
    local duration=timeRule and baseline.duration and baseline.duration*timeRule.parameters.multiplier
    if inputCount then changed=changed+1 end
    if duration then changed=changed+1 end
    if changed==0 then return baseline end
    local result={}
    for k,v in pairs(baseline) do result[k]=v end
    result.materials=materials
    result.expectedInputCount=inputCount or baseline.expectedInputCount
    result.duration=duration or baseline.duration
    result.mechanicsRuleCount=changed
    result.mechanicsApplied=true
    result.source=(baseline.source or "compiled reference").." + verified mechanics"
    return result
end

-- All display callers must use the already evaluated model; this compatibility
-- entry point resolves evidence without constructing a separate scenario.
function LL:ProcessingYieldDisplayModel(f,option)
    return self:ResolveEvidenceModel(f,option,nil,3)
end
function LL:ValueProcessingModel(model,suppliesCost,suppliesKnown,f)
    if not model or suppliesKnown==false then return nil,'Insufficient Data' end
    local total,missing,known=0,0,0
    for _,m in ipairs(model.materials or {}) do
        local quote=self:GetOutputPrice(m.id)
        m.netUnitPrice=quote
        m.netExpectedValue=nil
        if m.expectedQuantity==0 then
            m.netExpectedValue=0;known=known+1
        elseif quote and validNumber(m.expectedQuantity) then
            m.netExpectedValue=quote*m.expectedQuantity
            total=total+m.netExpectedValue;known=known+1
        else missing=missing+1 end
    end
    local savings=0
    if model.expectedInputCount and model.expectedInputCount<model.inputCount then
        local quote=f and self:GetOutputPrice(f.id)
        if f and self.AuctionEligible and not self:AuctionEligible(f) then
            quote=validNumber(f.vendor) and f.vendor or nil
        end
        if quote then savings=(model.inputCount-model.expectedInputCount)*quote else missing=missing+1 end
    end
    model.partialPrice=(missing>0 or model.unknownOutputs or model.insufficientSamples) and true or false
    model.partialValue=(total+savings-(suppliesCost or 0))/model.inputCount
    -- A2 (owner decision 1): when some outputs are unknown, the known outputs
    -- still give a value (a lower bound), marked partial, with confidence scaled
    -- by the share of outputs that could be valued. "Insufficient Data" only
    -- when nothing of value is known. The model is cached and shared, so the
    -- scaled figure goes in valueConfidence; model.confidence stays untouched.
    local base=type(model.confidence)=='number' and model.confidence or 0
    -- A3: one confidence per option, weighted by each material's share of the
    -- value, so a cheap uncertain by-product barely moves it. Model-wide
    -- discounts (e.g. sources disagreeing) are kept by scaling to the base.
    local weighted,valueSum,plain,count=0,0,0,0
    for _,m in ipairs(model.materials or {}) do
        if type(m.confidence)=='number' then
            plain=plain+m.confidence;count=count+1
            local v=m.netExpectedValue
            if validNumber(v) and v>0 then weighted=weighted+m.confidence*v;valueSum=valueSum+v end
        end
    end
    if valueSum>0 and count>0 and plain>0 then
        local factor=base/(plain/count) -- 1 unless the model applied a discount
        base=math.max(0,math.min(100,math.floor(weighted/valueSum*factor+.5)))
    end
    if not model.partialPrice then
        model.value=model.partialValue;model.partial=nil;model.valueConfidence=base
    elseif total>0 and known>0 then
        model.value=model.partialValue;model.partial=true
        model.valueConfidence=math.floor(base*known/(known+missing)+.5)
    else
        model.value=nil;model.partial=nil;model.valueConfidence=nil
    end
    return model.value,model.source
end
function LL:EvaluateDisenchant(f,character)
    if not self:EligibleDisenchant(f) then return nil,'Disenchanting not eligible' end
    local exp,issue=self:DisenchantExpansion(f)
    if exp==nil then return nil,issue end
    local family=self.DisenchantTables and self.DisenchantTables[exp]
    local mode=self.ProcessingDataMode and self:ProcessingDataMode('Disenchant') or 1
    local current=self.CharacterKey and self:CharacterKey()
    local personal
    if (not character or character=='Current character' or character==current) and self.GetLearnedDisenchantEstimate then
        personal=self:GetLearnedDisenchantEstimate(f,family)
    end
    local model,reason=self:ResolveEvidenceModel(f,{name='Disenchant',inputCount=1,
        recipeID=13262,character=character},personal,mode)
    if not model then
        -- Possible output identities are useful to non-enchanters too. They
        -- provide no quantities, probabilities or economic fallback.
        local tier=family and family.quality and family.quality[f.quality]
        local candidates=tier and tier.candidates
        if candidates and #candidates>0 then
            model={inputCount=1,materials={},unknownOutputs=true,confidence=0,
                source='Possible disenchant materials (unverified)',
                adjustment='Possible outputs only; quantities unknown',warning=reason}
            for _,id in ipairs(candidates) do model.materials[#model.materials+1]={id=id} end
        end
    end
    local value=self:ValueProcessingModel(model,0,true)
    return {name='Disenchant',value=value,materials=model and model.materials,
        yieldModel=model,expansion=exp,expansionName=family and family.name,
        samples=model and model.personalStats and model.personalStats.total,
        confidence=model and (model.valueConfidence or model.confidence) or 'unknown',partial=model and model.partial or nil,
        source=model and model.source,method=model and model.source,
        note=reason or (model and model.warning),incompletePrices=model and model.partialPrice},reason
end
local function number(n) return type(n)=="number" and n>0 and n<math.huge and n or nil end
local function Allowed(db,method)
    local letter=conversionMethodLetters[method] or "C"
    local modes=db and db.processingModes
    if type(modes)=="table" and modes[letter]==3 then return false end
    -- Modes replace all prior redundant method gates; Auto is the default.
    return true
end
local function MethodLetter(name)
    return processingMethodLetters[name] or "C"
end
function LL:GetOutputPrice(itemID)
    local key=self:TSMString(nil,itemID)
    local ask=self:Price("dbminbuyout",key) or self:Price("dbmarket",key)
        or self:Price("dbregionmarketavg",key)
    if ask then return ask*(1-self:AHFeeRate()),
        self:AHFeeRate()>0 and "TSM auction estimate (net)" or "TSM auction estimate (gross)" end
    local fn=C_Item and C_Item.GetItemInfo or GetItemInfo
    if fn then
        local ok,_,_,_,_,_,_,_,_,_,_,vendor=pcall(fn,itemID)
        if ok then return number(vendor),"Vendor output" end
    end
end
function LL:ConversionOptions(f)
    local out,knownOperations={},{}
    local function add(c,kind)
        if not c or not c.method or not Allowed(self.db,c.method) then return end
        if self.IsIgnoredAction and self:IsIgnoredAction(f.id,c.method) then return end
        -- Do not hide an expected-value quote just because this particular
        -- bag stack is smaller than one processing batch.  The displayed
        -- price is per original input, and the player may hold more in bank.
        -- Insufficient counted inputs must, however, NEVER make a processing
        -- action actionable or a winning liquidation recommendation.
        local available,why,character=self:CanUseConversion(f,c)
        local price,source
        local defaultBatch=(c.method=="Mill" and (f.expansionID==10 or f.expansionID==11)) and 10 or 5
        local inputCount=c.inputCount or ((c.method=="Mill" or c.method=="Prospect") and defaultBatch or 1)
        local processingRecipe=c.recipeID or c.requiredSpell
        if not processingRecipe then
            if c.method=="Mill" then processingRecipe=({[9]=382981,[10]=444181,[11]=1269575})[f.expansionID] or 51005
            elseif c.method=="Prospect" then processingRecipe=({[9]=374627,[10]=434018,[11]=1231127})[f.expansionID] or 31252 end
        end
        local identity=table.concat({c.method,tostring(processingRecipe),tostring(inputCount)},':')
        if kind=='research-operation' and knownOperations[identity] then return true end
        knownOperations[identity]=true
        local insufficientCount=type(f.count)=="number" and f.count<inputCount
        if insufficientCount then
            available=false
            why=("Need %d inputs for one %s operation"):format(inputCount,c.method)
        end
        local dataMode=self.ProcessingDataMode and self:ProcessingDataMode(c.method) or 1
        -- Direct item-use and vendor exchanges are fixed-ratio, not
        -- sampled random professions; they retain their documented returns.
        if c.method=="Exchange" or c.method=="Combine" or c.method=="Split" then
            dataMode=3
        end
        local research=(self.GetLearnedProcessingEstimate and
            self:GetLearnedProcessingEstimate(f,c.method,inputCount,processingRecipe)) or nil
        if c.outputID and c.outputCount and c.inputCount then
            price,source=self:GetOutputPrice(c.outputID)
        end
        local suppliesCost=0
        local suppliesKnown=true
        local missingExtra=false
        for _,extra in ipairs(c.extraReagents or {}) do
            local extraValue=self:GetOutputPrice(extra.id)
            if not extraValue then suppliesKnown=false else
                suppliesCost=suppliesCost+extraValue*extra.amount
            end
            -- Multi-reagent crafts aren't actionable unless extra inputs
            -- are in the current character's inventory. Do not promise
            -- another character has the same materials without verification.
            local availableCount=GetItemCount and GetItemCount(extra.id,true) or 0
            if availableCount<extra.amount then missingExtra=true end
        end
        for _,supply in ipairs(c.vendorSupplies or {}) do
            -- No TSM vendor-buy source. A verified fixed vendor price must
            -- be recorded in Game Data before this supply can be costed.
            if type(supply.fixedBuyPrice)~="number" then
                suppliesKnown=false;break
            end
            suppliesCost=suppliesCost+supply.fixedBuyPrice*supply.amount
        end
        local value
        if price and c.outputCount and c.inputCount and suppliesKnown then
            value=(price*c.outputCount-suppliesCost)/c.inputCount
        elseif suppliesKnown then value=price end
        -- Price stochastic processing only from the resolved ItemDB/personal
        -- evidence model. EV already includes zero-result operations and chance.
        local yieldModel,modelIssue
        if c.method=="Mill" or c.method=="Prospect" or c.method=="Smelt" or (research and dataMode~=3) then
            local displayOption={name=c.method,inputCount=inputCount,
                recipeID=processingRecipe,character=character}
            local current=self.CharacterKey and self:CharacterKey()
            if character and character~="Current character" and character~=current then research=nil end
            yieldModel,modelIssue=self:ResolveEvidenceModel(f,displayOption,research,dataMode)
            value,source=self:ValueProcessingModel(yieldModel,suppliesCost,suppliesKnown,f)
        end
        if value and value<0 then value=nil end
        if missingExtra then
            available=false
            why="Additional recipe reagents required"
        end
        local isFixed = c.outputID and c.outputCount and c.inputCount
            and (c.confidence=="documented" or c.confidence=="verified" or
                 c.method=="Exchange" or c.method=="Combine" or c.method=="Split")
        if not yieldModel and dataMode==2 and not isFixed then
            value=nil;source="Personal results only"
        end
        local v={name=c.method,letter=MethodLetter(c.method),available=available,
            why=why or modelIssue,character=character,profession=c.profession,
            value=value,source=source,inputShort=insufficientCount,
            confidence=yieldModel and (yieldModel.valueConfidence or yieldModel.confidence) or c.confidence or "verified-recipe",
            partial=yieldModel and yieldModel.partial or nil,
            -- Only per-input observations, never shared expansion-wide candidates.
            estimate=yieldModel and yieldModel.personalStats and research or nil,
            samples=yieldModel and yieldModel.personalStats and yieldModel.personalStats.total or 0,
            dataMode=dataMode,
            note=modelIssue or (dataMode==2 and (research and research.note or
                "Personal results only: no matching observations yet")) or c.requirement,
            outputID=c.outputID,outputCount=c.outputCount,inputCount=inputCount,
            recipeID=processingRecipe,expansion=c.expansion,
            dataSource=c.source,category=kind,
            vendorSupplyCost=suppliesKnown and suppliesCost or nil,
            yieldModel=yieldModel}
        out[#out+1]=v
        return true
    end
    for _,c in ipairs((self.Conversions and self.Conversions[f.id]) or {}) do
        -- Explicit verified conversion recipes / vendor exchanges.
        add(c,"curated")
    end
    for _,c in pairs((self.db.recipeCandidates and self.db.recipeCandidates[f.id]) or {}) do
        -- A discovered craft is eligible only if the produced reagent is consumed
        -- by a DIFFERENT profession (not merely used by the producer).
        local others=self.db.reagentConsumers and self.db.reagentConsumers[c.outputID]
        local usedElsewhere=false
        if others then for profession in pairs(others) do
            if profession~=c.profession then usedElsewhere=true;break end
        end end
        if usedElsewhere then
            local infoID
            if C_Item and C_Item.GetItemInfoInstant then
                local ok,_,_,_,_,_,cl=pcall(C_Item.GetItemInfoInstant,c.outputID)
                if ok then infoID=cl end
            end
            if infoID==7 then add(c,"discovered") end
        end
    end
    local researchMethods={}
    for _,operation in ipairs(self.ResearchProcessingOperations and self:ResearchProcessingOperations(f) or {}) do
        if add(operation,'research-operation') then researchMethods[operation.method]=true end
    end
    local modern=self.ResearchProcessingInput and self:ResearchProcessingInput(f.id)
    local destroy=(modern and modern.method) or
        (self.DB2Processable and self.DB2Processable[f.id]) or
        (self.db.processingLearning and self.db.processingLearning.inputs and
         self.db.processingLearning.inputs[f.id])
    local dataRecord=self.ResearchProcessingOutputs and self.ResearchProcessingOutputs[f.id]
    if not destroy and dataRecord then destroy=dataRecord.method end
    if destroy and destroy~='Disenchant' and not researchMethods[destroy] and Allowed(self.db,destroy) and not (self.IsIgnoredAction and self:IsIgnoredAction(f.id,destroy)) then add({method=destroy,profession=self:ProfessionForMethod(destroy),
        inputCount=(modern and modern.method==destroy and modern.batch)
            or (dataRecord and dataRecord.batch)
            or (destroy=="Mill" and (f.expansionID==10 or f.expansionID==11) and 10 or 5),
        requiredSpell=modern and (({Mill={[10]=444181,[11]=1269575},
            Prospect={[10]=434018,[11]=1231127}})[destroy] or {})[modern.expansion],
        confidence=(dataRecord and dataRecord.evidence) or "source-candidate",source=modern and "Research input candidate (client metadata)"
            or "Blizzard processing flag (possible input; yields unknown)"},"destroy") end
    if dataRecord and dataRecord.method~='Disenchant' and not researchMethods[dataRecord.method] and dataRecord.method~=destroy and Allowed(self.db,dataRecord.method)
        and not (self.IsIgnoredAction and self:IsIgnoredAction(f.id,dataRecord.method)) then
        add({method=dataRecord.method,profession=self:ProfessionForMethod(dataRecord.method),
             inputCount=dataRecord.batch,confidence=dataRecord.evidence,
             source="Compiled research processing data"},"research")
    end
    local eligible=self:EligibleDisenchant(f)
    if eligible and Allowed(self.db,"Disenchant") then
        local c={method="Disenchant",profession="Enchanting"}
        local available,why,character=self:CanUseConversion(f,c)
        local estimate,issue=self:DisenchantEstimate(f,character)
        f.currentCanDisenchant=self:CurrentHasEnchanting()
        f.disenchantIssue=issue
        f.disenchantEstimate=estimate
        if not available then f.unavailableDisenchant=estimate end
        out[#out+1]={name="Disenchant",letter="D",available=available,
            why=why or issue,character=character,profession="Enchanting",
            value=estimate and estimate.value or nil,
            source=(estimate and estimate.method) or (estimate and estimate.source) or "Game Data materials",
            confidence=estimate and estimate.confidence or "unknown",
            materialID=estimate and estimate.materialID,
            higherQualityID=estimate and estimate.higherQualityID,
            higherValue=estimate and estimate.higherValue,
            amount=estimate and estimate.amount,note=estimate and estimate.note or issue,
            expansion=estimate and estimate.expansion or nil,
            expansionName=estimate and estimate.expansionName or nil,
            category="disenchant",estimate=estimate,yieldModel=estimate and estimate.yieldModel}
    end
    table.sort(out,function(a,b)
        if a.available~=b.available then return a.available end
        return (a.value or -1)>(b.value or -1)
    end)
    return out
end
function LL:BestConversion(f)
    local options=self:ConversionOptions(f)
    f.conversionOptions=options
    for _,option in ipairs(options) do
        if option.available and number(option.value) then
            return option
        end
    end
    return nil
end
