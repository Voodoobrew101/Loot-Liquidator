-- Loot Liquidator: rank ONLY conversions the current character or a verified alt can perform.
-- Prices are quoted in copper per original input. No automatic crafting or selling.
local ADDON, LL = ...
local floor=math.floor

-- Single authoritative processing evaluation path.
-- All skill/condition matching, reference selection, and valuation live here.
-- Skill-aware processing evidence selector. No universal invented skill/drop multiplier.
-- v0.9.52: conservative matching, safe fallback, reference data is never overwritten.

local function validNumber(n)
    return type(n)=="number" and n==n and n>=0 and n<math.huge
end
local function compatible(a,b)
    if a==nil or b==nil then return false end
    return tostring(a)==tostring(b)
end
local function listFor(gd,id)
    local models=gd.processingConditionModels or gd.conditionModels
    local found=models and models[id]
    if type(found)~="table" then return nil end
    if found[1] then return found end
    return {found}
end
-- Only use a documented minimum when present in compiled input/recipe data.
-- Recipe difficulty is NOT the same thing as the minimum learn/use skill.
function LL:MinimumProcessingSkill(f,method,recipeID)
    local gd=self.GameData
    local models=gd and (method=="Prospect" and gd.prospect or method=="Mill" and gd.mill)
    local entry=models and f and models[f.id]
    local minimum=entry and (entry.minimumSkill or entry.requiredSkill)
    if validNumber(minimum) then return minimum end
    local recipes=gd and gd.recipeRequirements
    local rec=recipes and recipeID and recipes[recipeID]
    minimum=rec and (rec.minimumSkill or rec.requiredSkill)
    if validNumber(minimum) then return minimum end
    return nil -- not documented, don't silently assert zero
end
-- Manual character entries without a scanned skill use only the minimum
-- recipe requirement, never assumed knowledge points or profession gear.
-- Missing requirements are left unknown instead of claiming skill zero.
function LL:ProcessingPlayerConditions(f,method,recipeID,character)
    local profession=self.ProfessionForMethod and self:ProfessionForMethod(method)
    local current=self.CharacterKey and self:CharacterKey()
    local key=(character and character~="Current character") and character or current
    local record=self.db and self.db.characters and self.db.characters[key]
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
        inputID=f and f.id,inputQuality=f and f.quality,recipeID=recipeID,
        character=key,assumedMinimum=false}
    -- Blizzard operation information is specific to the CURRENT character.
    -- Never use current gear/skill when pricing an offline alt.
    local api=C_TradeSkillUI and C_TradeSkillUI.GetCraftingOperationInfo
    if key==current and type(api)=="function" and type(recipeID)=="number" and recipeID>0 then
        local ok,info=pcall(api,recipeID,{},nil,false)
        if ok and type(info)=="table" then
            local base,bonus=info.baseSkill,info.bonusSkill
            if validNumber(base) and validNumber(bonus) then
                ctx.effectiveSkill=base+bonus
            end
            ctx.craftingQuality=info.craftingQuality
            ctx.qualityFromBlizzard=type(info.craftingQuality)=="number"
        end
    end
    local mode=({Mill="M",Prospect="P",Smelt="S",Disenchant="D"})[method]
    local manual=mode and self.ProcessingMethodMode and self:ProcessingMethodMode(mode)==4
        and self.AltMethodEnabled and self:AltMethodEnabled(key,mode)
        and record and record.altMethods and record.altMethods[mode]==true
    -- Actual verified skill wins even if this column is in Manual mode.
    if not validNumber(ctx.effectiveSkill) and validNumber(skill) then
        ctx.effectiveSkill=skill
    end
    -- A checked Manual row enables a hypothetical MINIMUM configuration.
    -- Unknown gear and knowledge grant no bonuses; never silently borrow
    -- this logged-in character's bonuses for a different character.
    if manual and not validNumber(ctx.effectiveSkill) then
        local required=self.MinimumProcessingSkill and self:MinimumProcessingSkill(f,method,recipeID)
        ctx.assumedMinimum=true
        ctx.specialization="none_assumed"
        ctx.equipmentAssumed=false
        ctx.skillAssumption="minimum"
        if validNumber(required) then
            ctx.effectiveSkill=required
            ctx.skill=required
        end
        -- If the recipe minimum is undocumented, skill remains UNKNOWN.
        -- Do not describe a guessed zero as a real profession skill.
    end
    ctx.skillKnown=validNumber(skill) and not ctx.assumedMinimum
    ctx.skillSource=ctx.assumedMinimum and "manual-minimum"
        or (ctx.qualityFromBlizzard and "blizzard-operation"
        or (ctx.skillKnown and "scanned-profession" or "unknown"))
    return ctx
end
-- Return a single research-adjusted model. Partial observations update only
-- their measured materials; unknown outputs preserve the compiled estimate.
-- An absent yield does NOT imply 1, 0, or a measured occurrence chance.
function LL:SelectProcessingConditionModel(f,method,recipeID,character,baseline)
    local db=self.db or {}
    if db.skillAwareProcessing==false then return nil end
    local gd=self.GameData
    local list=gd and f and listFor(gd,f.id)
    if not list or not baseline or type(baseline.materials)~="table" then
        local d=self.processingDebug
        if d and d.armed and not d.done and not d.target then
            d.target=f and f.id;d.done=true;d.armed=false
            d.lines={"LIVE processing diagnostic: no condition cohorts for item="..tostring(f and f.id),
              "Method="..tostring(method).." recipe="..tostring(recipeID),
              "Compiled reference fallback (conditionModels entry absent or invalid)"}
        end
        return nil
    end
    local ctx=self:ProcessingPlayerConditions(f,method,recipeID,character)
    local best,score
    local debug=self.processingDebug
    local capturing=debug and debug.armed and not debug.done and not debug.target
    if capturing then
        debug.target=f.id
        debug.lines={"Loot Liquidator LIVE processing diagnostic",
          "Input item="..tostring(f.id).." method="..tostring(method).." recipe="..tostring(recipeID),
          "Character="..tostring(ctx.character).." skill="..tostring(ctx.skill).." effective="..tostring(ctx.effectiveSkill),
          "Skill source="..tostring(ctx.skillSource).." assumed minimum="..tostring(ctx.assumedMinimum),
          "Input quality="..tostring(ctx.inputQuality).." specialization="..tostring(ctx.specialization),
          "Reference batch="..tostring(baseline.inputCount).." reference materials="..tostring(#baseline.materials),
          "Condition cohorts="..tostring(#list)}
    end
    local function log(line)
        if capturing and #debug.lines<80 then debug.lines[#debug.lines+1]=line end
    end
    for index,model in ipairs(list) do
        -- Unknown input quality must NOT be interpreted as a match to rank 2.
        -- Unknown experimental specialization also cannot be assumed learned.
        local valid=(model.method==nil or model.method==method)
          and (model.recipeID==nil or recipeID==nil or compatible(model.recipeID,recipeID))
          and (model.inputQuality==nil or (ctx.inputQuality~=nil and compatible(model.inputQuality,ctx.inputQuality)))
          and (model.specialization==nil or compatible(model.specialization,ctx.specialization))
          and (not validNumber(model.effectiveSkill) or (validNumber(ctx.effectiveSkill)
               and math.abs(model.effectiveSkill-ctx.effectiveSkill)<= (db.skillMatchingTolerance or 40)))
          and type(model.outputs)=="table" and #model.outputs>0
          and validNumber(model.operations) and model.operations>0
          and validNumber(model.batch) and model.batch>0
          and model.batch==baseline.inputCount
        if capturing then
            local reasons={}
            local function need(ok,reason) if not ok then reasons[#reasons+1]=reason end end
            need(model.method==nil or model.method==method,"method mismatch")
            need(model.recipeID==nil or recipeID==nil or compatible(model.recipeID,recipeID),"recipe mismatch")
            need(model.inputQuality==nil or (ctx.inputQuality~=nil and compatible(model.inputQuality,ctx.inputQuality)),"input quality mismatch or unknown")
            need(model.specialization==nil or compatible(model.specialization,ctx.specialization),"specialization mismatch or unknown")
            need(not validNumber(model.effectiveSkill) or (validNumber(ctx.effectiveSkill) and math.abs(model.effectiveSkill-ctx.effectiveSkill)<=(db.skillMatchingTolerance or 40)),"skill outside tolerance or unknown")
            need(type(model.outputs)=="table" and #model.outputs>0,"no outputs")
            need(validNumber(model.operations) and model.operations>0,"operation count missing")
            need(validNumber(model.batch) and model.batch>0 and model.batch==baseline.inputCount,"batch missing or mismatch")
            log("Cohort #"..index.." study="..tostring(model.study).." batch="..tostring(model.batch).." samples="..tostring(model.operations).." => "..(#reasons==0 and "CONDITIONS PASS" or table.concat(reasons,"; ")))
        end
        if valid then
            local outputFound=false
            local original={}
            for _,m in ipairs(baseline.materials) do original[m.id]=true end
            for _,m in ipairs(model.outputs) do
                if original[m.id] and validNumber(m.expectedQuantity) then outputFound=true end
            end
            if capturing then log("Cohort #"..index.." matching measured outputs="..tostring(outputFound)) end
            if outputFound then
                -- Source era is unverified: permit LOW-WEIGHT partial evidence,
                -- not an unconditional full replacement.
                local s=model.operations
                if model.patchVerifiedCurrent==true then s=s+100000 end
                if validNumber(model.effectiveSkill) and validNumber(ctx.effectiveSkill) then
                    s=s-math.abs(model.effectiveSkill-ctx.effectiveSkill)
                end
                if not score or s>score then best=model;score=s end
            end
        end
    end
    if not best then
        log("SELECTED: no eligible cohort; compiled reference fallback")
        if capturing then debug.done=true;debug.armed=false end
        return nil
    end
    log("SELECTED cohort: "..tostring(best.study).." operations="..tostring(best.operations))
    -- Experimental samples with unknown patch applicability are discounted.
    -- Full verified cohort: n/(n+50); unresolved patch: n/(n+200).
    local prior=best.patchVerifiedCurrent==true and 50 or 200
    local weight=best.operations/(best.operations+prior)
    local measured={}
    for _,m in ipairs(best.outputs) do
        if validNumber(m.id) and validNumber(m.expectedQuantity) then measured[m.id]=m end
    end
    local materials={}
    local improvements=0
    for _,original in ipairs(baseline.materials) do
        local updated={}
        for k,v in pairs(original) do updated[k]=v end
        local m=measured[original.id]
        if m then
            updated.expectedQuantity=original.expectedQuantity*(1-weight)+m.expectedQuantity*weight
            updated.quantityBasis="partial observed mean + provisional reference"
            updated.provisional=true
            -- No per-operation hit histogram; retain chance as a PROXY.
            updated.probabilityBasis="reference probability proxy; occurrence unmeasured in cohort"
            updated.observationWeight=weight
            improvements=improvements+1
        end
        materials[#materials+1]=updated
    end
    if improvements==0 then
        log("FALLBACK: selected cohort has no matching output IDs with expected quantities")
        if capturing then debug.done=true;debug.armed=false end
        return nil
    end
    log("ACTIVE research: improved output IDs="..tostring(improvements).." observation weight="..string.format("%.4f",weight))
    if capturing then debug.done=true;debug.armed=false end
    return {kind="partially-observed",materials=materials,inputCount=best.batch,
        samples=best.operations,source=best.source,evidence="partial observed cohort; unresolved patch discounted",
        conditionStudy=best.study,confidenceCap=baseline.confidenceCap,
        measuredOutputs=improvements,observationWeight=weight}
end
function LL:ReferenceProcessingModel(f,method,recipeID,baseline,character)
    local matched=self.SelectProcessingConditionModel and
        self:SelectProcessingConditionModel(f,method,recipeID,character,baseline)
    return matched or baseline
end
-- Automatic combines independent, compatible observations at the MATERIAL
-- level. A published reference counts as a conservative prior of 100 effective
-- samples; increasing personal evidence progressively takes precedence.
-- Never borrow material counts for a different recipe, input or batch.
function LL:BlendProcessingYields(reference,personal,batch)
    if not reference or type(reference.materials)~="table" then return reference end
    if not personal or type(personal.materials)~="table" or #personal.materials==0 then return reference end
    if personal.inputCount~=batch or reference.inputCount~=batch then return reference end
    local n=tonumber(personal.effectiveSamples) or 0
    if n<=0 then return reference end
    local prior=100
    local w=n/(n+prior)
    local byID,out,seen={}, {}, {}
    for _,m in ipairs(personal.materials) do byID[m.id]=m end
    local function add(base,id)
        local pm=byID[id]
        local old=base and tonumber(base.expectedQuantity) or nil
        local observed=pm and tonumber(pm.expectedQuantity) or 0
        local result={}
        for k,v in pairs(base or pm or {}) do result[k]=v end
        result.id=id
        if old then
            result.expectedQuantity=(1-w)*old+w*observed
        elseif pm then
            -- Previously unknown output: conservative prior of zero units.
            result.expectedQuantity=w*observed
        end
        if base and type(base.chance)=="number" and pm and type(pm.chance)=="number" then
            result.chance=(1-w)*base.chance+w*pm.chance
        elseif base and type(base.chance)=="number" then
            result.chance=(1-w)*base.chance+w*(pm and pm.chance or 0)
        elseif pm and type(pm.chance)=="number" then
            result.chance=w*pm.chance
        end
        result.quantityBasis="weighted reference + personal observations"
        result.probabilityBasis="weighted estimate (not independently verified)"
        result.provisional=true
        out[#out+1]=result
        seen[id]=true
    end
    for _,m in ipairs(reference.materials) do add(m,m.id) end
    for _,m in ipairs(personal.materials) do
        if not seen[m.id] then add(nil,m.id) end
    end
    return {kind="blended",materials=out,inputCount=batch,
        source="Built-in + compatible personal observations",personalWeight=w,
        samples=n,evidence="Weighted per-output expectations; reference prior 100 effective samples",
        confidenceCap=reference.confidenceCap}
end

-- Midnight basic yields are the FALLBACK, not the output of a universal
-- skill multiplier. Optional upgrade slider interpolates ore/material-specific
-- research anchors. A diamond is controlled by a separate ore-specific unlock.
-- No false claims of exact specialization skill or item-quality thresholds.
function LL:MidnightProspectingModel(f,option)
    local profile=self.GameData and self.GameData.midnightProspectingProfiles
        and f and self.GameData.midnightProspectingProfiles[f.id]
    if not profile or not option or option.name~="Prospect" then return nil end
    local db=self.db or {}
    local pct=tonumber(db.midnightProspectingUpgradePct) or 0
    pct=math.max(0,math.min(100,pct))/100
    local diamondUnlocked=db[profile.diamondFlag]==true
    local outputs={}
    for _,m in ipairs(profile.materials) do
        local lo=tonumber(m.low) or 0
        local hi=tonumber(m.high) or lo
        local expected
        if m.category=="diamond" then
            -- Unlocked diamond expected yield is ore-specific. This research
            -- does not establish a separate bonus curve after the unlock.
            expected=diamondUnlocked and math.max(0,hi) or 0
        else
            -- Separate incompatible high/low studies sometimes have high<low.
            -- Never interpret sampling noise as a negative upgrade benefit.
            expected=lo+pct*(math.max(lo,hi)-lo)
        end
        if expected>0 then
            outputs[#outputs+1]={id=m.id,expectedQuantity=expected,
                quantityBasis="midnight estimated units per five ore",
                probabilityBasis="expected-count not measured drop chance",
                provisional=true,source=(pct>0 and m.highBasis or m.lowBasis)}
        end
    end
    local result={kind="midnight-estimate",materials=outputs,inputCount=5,
        evidence=profile.evidence,confidenceCap=profile.confidenceCap,
        source="Midnight prospecting: low fallback + ore-specific upgrade estimates",
        upgradePct=pct*100,diamondUnlocked=diamondUnlocked,
        qualityAssumption="quality-1 output prices; thresholds unverified",
        inputRank=profile.inputRank}
    -- Assign changing, tooltip-only occurrence/range estimates from the SAME
    -- low/high anchors used in pricing; never multiply them into EV twice.
    for _,m in ipairs(result.materials) do
        for _,r in ipairs(profile.materials) do
            if r.id==m.id and self.CompleteYieldAnnotations then
                local lo=tonumber(r.low) or 0; local hi=tonumber(r.high) or lo
                local x=max(0,lo+pct*(max(lo,hi)-lo))
                local prob=math.min(1,math.max(.025,x/(x>=1 and math.ceil(x) or 1)))
                m.chance=prob;m.minQuantity=1;m.maxQuantity=math.max(1,math.ceil(x/math.max(.025,prob)))
                m.probabilityBasis="estimated from research output mean; not measured occurrence"
                break
            end
        end
    end
    return self.CompleteYieldAnnotations and self:CompleteYieldAnnotations(result) or result
end

-- Dragonflight is a separate, evidence-limited processing estimator.
-- Default low comes from unmodified historical TSM amountOfMats per ore.
-- Individual material upgrade effects are applied to expected quantities;
-- probabilities (TSM matRate) are NOT multiplied a second time.
-- Output rank and Inspiration model quality separately from quantity.
local function DFClamp(x,lo,hi)
    x=tonumber(x) or lo
    return math.max(lo,math.min(hi,x))
end
function LL:DragonflightProspectingModel(f,option)
    local profiles=self.GameData and self.GameData.dragonflightProspectingProfiles
    local p=profiles and f and profiles[f.id]
    if not p or not option or option.name~="Prospect" then return nil end
    local db=self.db or {}
    local upgrade=DFClamp(db.dragonflightProspectingUpgradePct,0,100)/100
    local quality=DFClamp(db.dragonflightProspectingOutputRank,0,3)
    local ctx
    if quality==0 then
        ctx=self.ProcessingPlayerConditions and
            self:ProcessingPlayerConditions(f,"Prospect",option.recipeID,option.character)
        -- Only Blizzard's actual operation quality qualifies for an automatic
        -- quality determination. Scanned base skill alone cannot prove rank.
        if ctx and ctx.qualityFromBlizzard and tonumber(ctx.craftingQuality) then
            quality=DFClamp(ctx.craftingQuality,1,3)
        else
            quality=1 -- conservative fallback: NEVER assume rank 3 from ore rank
        end
    end
    quality=math.floor(quality)
    local inspiration=DFClamp(db.dragonflightProspectingInspirationPct,0,60)/100
    local inspiredRank=quality
    if db.dragonflightProspectingInspirationCrossesThreshold==true and quality<3 then
        inspiredRank=quality+1
    else
        inspiration=0 -- chance alone cannot prove a rank threshold is crossed
    end
    local materialOrder,byID={},{}
    local function emit(id,expected,basis)
        if not id or expected<=0 then return end
        local m=byID[id]
        if m then m.expectedQuantity=m.expectedQuantity+expected
        else
            m={id=id,expectedQuantity=expected,
                provisional=true,quantityBasis="estimated Dragonflight units per five inputs",
                probabilityBasis="expected count, NOT item drop chance",
                source=basis}
            byID[id]=m
            materialOrder[#materialOrder+1]=m
        end
    end
    local function appendProfile(target,multiplier)
        for _,m in ipairs(target.materials or {}) do
            if m.category~="special" then
                local lo=tonumber(m.low) or 0
                local high=tonumber(m.high) or lo
                -- Heterogeneous samples can conflict; the compiled high
                -- endpoint is monotone only as a pragmatic scenario guard.
                local units=math.max(0,lo+upgrade*(math.max(lo,high)-lo))*multiplier
                if units>0 then
                    if type(m.rankIDs)=="table" then
                        local baseID=m.rankIDs[quality] or m.id
                        emit(baseID,units*(1-inspiration),m.lowBasis)
                        if inspiration>0 then
                            emit(m.rankIDs[inspiredRank] or baseID,units*inspiration,m.highBasis)
                        end
                    else
                        emit(m.id,units,m.lowBasis)
                    end
                end
            end
        end
    end
    appendProfile(p,1)
    local prismaticRate=0
    -- Prismatic Ore is soulbound; never value it as auctionable loot.
    -- Optionally prospect it virtually using TSM's downstream gem table.
    if f.id~=194545 and f.id~=192880 and db.dragonflightProspectingPrismaticUnlocked==true then
        for _,m in ipairs(p.materials) do
            if m.category=="special" and m.id==194545 then
                prismaticRate=(tonumber(m.low) or 0)+upgrade*((tonumber(m.high) or 0)-(tonumber(m.low) or 0))
                break
            end
        end
        if prismaticRate>0 and profiles[194545] then
            -- prismaticRate units gained from five normal ore, divided by
            -- five for the Prismatic processing yield's five-item batch.
            appendProfile(profiles[194545],prismaticRate/5)
        end
    end
    local resourceChance=DFClamp(db.dragonflightProspectingResourcefulnessPct,0,50)/100
    -- Approximation from player saved-ore reports: 30% of a 5-ore batch
    -- returned on proc. No direct per-craft distribution was recovered.
    local oreSavedFraction=resourceChance*0.30
    if self.CompleteYieldAnnotations then
        -- Use the researched per-gem occurrence proxies when available.
        for _,m in ipairs(materialOrder) do
            for _,r in ipairs(p.materials) do
                if r.id==m.id or (r.rankIDs and (r.rankIDs[1]==m.id or r.rankIDs[2]==m.id or r.rankIDs[3]==m.id)) then
                    local a=tonumber(r.lowOccurrenceProxy)
                    local b=tonumber(r.highOccurrenceProxy) or a
                    if a and b then
                        m.chance=math.max(0,math.min(1,a+upgrade*(b-a)))
                        m.probabilityBasis="TSM/research occurrence proxy, not EV multiplier"
                    end
                    break
                end
            end
        end
    end
    return {kind="dragonflight-estimate",materials=materialOrder,
        inputCount=5*(1-oreSavedFraction),nominalInputCount=5,
        source="Dragonflight: TSM historical low + research-derived high",
        evidence=p.evidence,confidenceCap=p.confidenceCap,
        upgradePct=upgrade*100,outputQuality=quality,
        inspirationQualitySplitPct=inspiration*100,
        resourcefulnessChancePct=resourceChance*100,
        expectedOreSavedPct=oreSavedFraction*100,
        prismaticYieldPerBatch=prismaticRate,
        inputRank=p.inputRank}
end

function LL:ProcessingYieldDisplayModel(f,option)
 local gd=self.GameData
 if type(f)~="table" or type(option)~="table" or option.name=="Disenchant" then return nil end
 if type(option.outputID)=="number" and type(option.outputCount)=="number" and option.outputCount>0 and type(option.inputCount)=="number" and option.inputCount>0 then
  return {kind="fixed",materials={{id=option.outputID,chance=1,expectedQuantity=option.outputCount,minQuantity=option.outputCount,maxQuantity=option.outputCount}},inputCount=option.inputCount,source=option.dataSource or "Verified fixed recipe"}
 end
 -- Midnight fallback takes precedence over unrelated legacy candidate/TSM
 -- entries; the other expansion processing paths remain unchanged.
 local midnight=self.MidnightProspectingModel and self:MidnightProspectingModel(f,option)
 if midnight then return midnight end
 -- Independent Dragonflight estimate, before legacy TSM and candidate paths.
 local dragonflight=self.DragonflightProspectingModel and self:DragonflightProspectingModel(f,option)
 if dragonflight then return self:CompleteYieldAnnotations(dragonflight) end
 -- TWW prospect and modern milling: one source drives EV and tooltip.
 local stat=self.StatProfiledYieldModel and self:StatProfiledYieldModel(f,option)
 if stat then return self:CompleteYieldAnnotations(stat) end
 -- TSM first: preserve original rate per input item. No midpoint or extra matRate multiplier.
 local methodKey=option.name=="Prospect" and "prospect" or option.name=="Mill" and "mill" or nil
 local tsm=methodKey and gd.tsmRetail and gd.tsmRetail[methodKey] and gd.tsmRetail[methodKey][f.id]
 if tsm and #tsm>0 then
  local ctx=self.ProcessingPlayerConditions and self:ProcessingPlayerConditions(f,option.name,option.recipeID,option.character)
  local inputQuality=(ctx and tonumber(ctx.inputQuality)) or nil
  local outputQuality=(ctx and ctx.qualityFromBlizzard and tonumber(ctx.craftingQuality)) or nil
  -- With unknown output-quality skill, choose the lowest available quality per gem family.
  -- Never sum rank-1, rank-2, and rank-3 copies of the same material as simultaneous drops.
  local groupMap={}; local result={}
  -- The TSM table has separate item IDs for each pigment/gem quality.
  -- Select the output rank before summing, not one entry per quality ID.
  local rank=outputQuality or 1
  for _,m in ipairs(tsm) do
   if (not m.sourceQuality or not inputQuality or m.sourceQuality==inputQuality)
       and (not m.targetQuality or m.targetQuality==rank) then
    groupMap[m.id]=m
   end
  end
  for _,m in pairs(groupMap) do
   result[#result+1]={id=m.id,matRate=m.matRate,amountOfMats=m.amountOfMats,
     chance=m.matRate,expectedQuantity=m.amountOfMats,
     minQuantity=m.minAmount,maxQuantity=m.maxAmount,
     sourceQuality=m.sourceQuality,targetQuality=m.targetQuality,
     requiredSkill=m.requiredSkill,quantityBasis="TSM amountOfMats per input",source="TSM Retail"}
  end
  table.sort(result,function(a,b) return a.id<b.id end)
  if #result>0 then
   return {kind="tsm-retail",materials=result,inputCount=1,
     processingBatchSize=(option.inputCount and option.inputCount>1) and option.inputCount or 5,
     source="TradeSkillMaster Retail: original per-input conversion rates",confidenceCap=80,
     tsmNativeRate=true}
  end
 end
 local r=gd.prospect[f.id] or gd.mill[f.id]
 if not r or r.method~=option.name or not r.materials or #r.materials==0 then
  if self.processingDebug and self.processingDebug.armed and not self.processingDebug.done then
   local d=self.processingDebug;d.target=f.id;d.armed=false;d.done=true
   d.lines={"LIVE processing diagnostic: No compiled processing model for item "..tostring(f.id).." method="..tostring(option.name)}
  end
  return nil
 end
 local baseline={kind=r.kind,materials=r.materials,inputCount=r.batch or option.inputCount or 1,evidence=r.evidence,confidenceCap=r.confidenceCap,samples=r.samples,referenceURL=r.source,source=r.source}
 if LL.ReferenceProcessingModel then
  return LL:ReferenceProcessingModel(f,option.name,option.recipeID,baseline,option.character)
 end
 return baseline
end
local function number(n) return type(n)=="number" and n>0 and n<math.huge and n or nil end
local function Allowed(db,method)
    local letter=({Disenchant="D",Mill="M",Prospect="P",Smelt="S",
        Recycle="R",Research="R",Combine="X",Split="X",Exchange="X",Craft="C"})[method] or "C"
    local modes=db and db.processingModes
    if type(modes)=="table" and modes[letter]==3 then return false end
    -- Modes replace all prior redundant method gates; Auto is the default.
    return true
end
local function MethodLetter(name)
    return ({Disenchant="D",Mill="M",Prospect="P",Smelt="S"})[name] or "C"
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
    local out={}
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
        local insufficientCount=type(f.count)=="number" and f.count<inputCount
        if insufficientCount then
            available=false
            why=("Need %d inputs for one %s operation"):format(inputCount,c.method)
        end
        local dataMode=self.ProcessingDataMode and self:ProcessingDataMode(c.method) or 1
        -- Global research preference applies only when per-method choice is Automatic.
        local globalMode=self.db and self.db.processingFallbackMode or 1
        if dataMode==1 and globalMode==2 then dataMode=3 end
        if dataMode==1 and globalMode==3 then dataMode=2 end
        -- Direct item-use and vendor exchanges are fixed-ratio, not
        -- sampled random professions; they retain their documented returns.
        if c.method=="Exchange" or c.method=="Combine" or c.method=="Split" then
            dataMode=3
        end
        local research=(self.GetLearnedProcessingEstimate and
            self:GetLearnedProcessingEstimate(f,c.method,inputCount,c.recipeID or c.requiredSpell)) or nil
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
        -- All compiled GameData processing models can be priced when their
        -- expected units are supplied and every output has a price.  A model
        -- marked 'candidates' remains PROVISIONAL and low confidence; its
        -- expectedQuantity is a scenario per processing batch, not a measured
        -- drop rate. Do not multiply by chance again (already included).
        -- GetOutputPrice includes the AH fee once.
        local yieldModel
        if c.method=="Mill" or c.method=="Prospect" then
            yieldModel=self:ProcessingYieldDisplayModel(f,
                {name=c.method,inputCount=inputCount,recipeID=c.recipeID or c.requiredSpell,character=character})
            if yieldModel and self.CompleteYieldAnnotations then
                yieldModel=self:CompleteYieldAnnotations(yieldModel)
            end
        end
        local minSamples=self.ProcessingMinimum and self:ProcessingMinimum() or 1
        if (c.method=="Mill" or c.method=="Prospect") and dataMode==1
            and research and (research.effectiveSamples or 0)>0 then
            yieldModel=self:BlendProcessingYields(yieldModel,research,inputCount)
        elseif (c.method=="Mill" or c.method=="Prospect") and dataMode==2 then
            yieldModel=(research and (research.effectiveSamples or 0)>=minSamples
                and research.materials and #research.materials>0)
                and {kind="observed",materials=research.materials,
                    inputCount=inputCount,source="Personal recorded results"} or nil
        end
        if yieldModel and (c.method=="Mill" or c.method=="Prospect") then
            local total,priced,unpriced=0,0,0
            for _,material in ipairs(yieldModel.materials) do
                local quote=self:GetOutputPrice(material.id)
                local expected=tonumber(material.expectedQuantity)
                if quote and expected and expected>=0 then
                    total=total+quote*expected
                    priced=priced+1
                else
                    unpriced=unpriced+1
                end
            end
            -- Missing material prices must not suppress ALL useful gold data.
            -- An incomplete sum is a conservative lower bound; never assign a
            -- made-up market price or treat it as a fully-priced estimate.
            yieldModel.partialPrice=unpriced>0
            yieldModel.pricedOutputs=priced
            yieldModel.missingPrices=unpriced
            value=priced>0 and total>0 and total/(yieldModel.inputCount or inputCount) or nil
            source=(yieldModel.source or "Compiled processing research")..
                (unpriced>0 and " (partial priced outputs)" or "")
        end
        if value and value<=0 then value=nil end
        if missingExtra then
            available=false
            why="Additional recipe reagents required"
        end
        local isFixed = c.outputID and c.outputCount and c.inputCount
            and (c.confidence=="documented" or c.confidence=="verified" or
                 c.method=="Exchange" or c.method=="Combine" or c.method=="Split")
        if c.method~="Mill" and c.method~="Prospect" then
            if dataMode==2 and not isFixed then
                value=research and research.value or nil
                source="Personal results only"
            elseif dataMode==1 and research and research.value then
                value=research.value
                source="Personal recorded results"
            end
        end
        local v={name=c.method,letter=MethodLetter(c.method),available=available,
            why=why,character=character,profession=c.profession,
            value=value,source=source,inputShort=insufficientCount,
            confidence=(research and research.value and dataMode~=3)
                and research.confidence or c.confidence or "verified-recipe",
            -- Only per-input observations, never shared expansion-wide candidates.
            estimate=(dataMode~=3 and research) or nil,
            samples=research and research.samples or 0,
            dataMode=dataMode,
            note=(dataMode==2 and (research and research.note or
                "Personal results only: no matching observations yet")) or c.requirement,
            outputID=c.outputID,outputCount=c.outputCount,inputCount=c.inputCount,
            recipeID=c.recipeID,expansion=c.expansion,
            dataSource=c.source,category=kind,
            vendorSupplyCost=suppliesKnown and suppliesCost or nil,
            yieldModel=yieldModel}
        out[#out+1]=v
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
    local modern=self.ResearchProcessingInput and self:ResearchProcessingInput(f.id)
    local destroy=(modern and modern.method) or
        (self.DB2Processable and self.DB2Processable[f.id]) or
        (self.db.processingLearning and self.db.processingLearning.inputs and
         self.db.processingLearning.inputs[f.id])
    local dataRecord=self.ResearchProcessingOutputs and self.ResearchProcessingOutputs[f.id]
    if not destroy and dataRecord then destroy=dataRecord.method end
    if destroy and Allowed(self.db,destroy) and not (self.IsIgnoredAction and self:IsIgnoredAction(f.id,destroy)) then add({method=destroy,profession=self:ProfessionForMethod(destroy),
        inputCount=(modern and modern.method==destroy and modern.batch)
            or (dataRecord and dataRecord.batch)
            or (destroy=="Mill" and (f.expansionID==10 or f.expansionID==11) and 10 or 5),
        requiredSpell=modern and ({Mill={[10]=444181,[11]=1269575},
            Prospect={[10]=434018,[11]=1231127}})[destroy][modern.expansion],
        confidence=(dataRecord and dataRecord.evidence) or "source-candidate",source=modern and "Research input candidate (client metadata)"
            or "Blizzard processing flag (possible input; yields unknown)"},"destroy") end
    if dataRecord and dataRecord.method~=destroy and Allowed(self.db,dataRecord.method)
        and not (self.IsIgnoredAction and self:IsIgnoredAction(f.id,dataRecord.method)) then
        add({method=dataRecord.method,profession=self:ProfessionForMethod(dataRecord.method),
             inputCount=dataRecord.batch,confidence=dataRecord.evidence,
             source="Compiled research processing data"},"research")
    end
    local eligible=self:EligibleDisenchant(f)
    if eligible and Allowed(self.db,"Disenchant") then
        local c={method="Disenchant",profession="Enchanting"}
        local available,why,character=self:CanUseConversion(f,c)
        local estimate,issue=self:DisenchantEstimate(f)
        f.currentCanDisenchant=self:CurrentHasEnchanting()
        f.disenchantIssue=issue
        f.disenchantEstimate=estimate
        if not available then f.unavailableDisenchant=estimate end
        local research=(self.GetLearnedDisenchantEstimate and self.DisenchantTables
            and self:GetLearnedDisenchantEstimate(f,self.DisenchantTables[f.expansionID])) or nil
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
            category="disenchant",estimate=estimate,
            personalResearch=(research and research~=estimate) and research or nil}
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
