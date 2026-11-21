-- Build-only modeled views. Source category records remain immutable evidence.
-- The canonical zero-skill profile below is a modeling assumption for sources
-- whose character is unknown; it is never written back as an observed profile.
local function copy(value)
    if type(value)~='table' then return value end
    local result={}
    for key,item in pairs(value) do result[key]=copy(item) end
    return result
end
local function finite(value)
    return type(value)=='number' and value==value and value>=0 and value<math.huge
end
local function confidence(value)
    return finite(value) and math.min(100,value) or 0
end
local classes={[2]='weapon',[4]='armor'}
local function category(records,rule,classID,referenceContextID)
    local expected=referenceContextID or ('de-category:gear:'..rule.expansionID..':'..rule.inputRarity
        ..':'..classes[classID]..':unknown-character')
    local found
    for _,record in ipairs(records) do
        if record.isDisenchantCategory==true and record.sourceKey=='itemdb'
            and record.method=='Disenchant' and record.recipeID==13262 and record.inputCount==1
            and record.expansionID==rule.expansionID and record.inputRarity==rule.inputRarity
            and record.inputClassID==classID
            and (record.referenceContextID==expected or record.recordID==expected) then
            assert(not found,'Ambiguous Disenchant category baseline: '..expected)
            found=record
        end
    end
    return found
end
local function quantities(record,cap)
    local materials={}
    for _,material in ipairs(record.materials or {}) do
        local field=material.expectedQuantity
        if type(field)=='table' and finite(field.value) and field.status~='unknown'
            and field.status~='contradictory' and not material.conditionalReference then
            local value={id=material.id,expectedQuantity=field.value,
                confidence=math.min(cap,confidence(field.confidence))}
            -- A modeled mean is not a reason to erase independent source
            -- occurrence/range fields. Keep their values, never their cast
            -- counters, so the identity profile can reproduce the baseline.
            for _,pair in ipairs({{'dropChance','chance'},{'minQuantity','minQuantity'},
                {'maxQuantity','maxQuantity'}}) do
                local source=material[pair[1]]
                if type(source)=='table' and finite(source.value) and source.status~='unknown'
                    and source.status~='contradictory' and (pair[2]~='chance' or source.value<=1) then
                    value[pair[2]]=source.value
                    if pair[2]=='chance' then value.chanceConfidence=math.min(cap,confidence(source.confidence)) end
                end
            end
            if value.chance~=nil then value.probabilityBasis='source-category-occurrence' end
            materials[#materials+1]=value
        end
    end
    table.sort(materials,function(a,b) return a.id<b.id end)
    return materials
end
local function primary(materials,ids)
    local total,seen=0,{}
    for _,material in ipairs(materials) do
        if material.id==ids[1] or material.id==ids[2] then
            total=total+material.expectedQuantity;seen[material.id]=true
        end
    end
    if not seen[ids[1]] or not seen[ids[2]] then return nil end
    return total
end
local function endpointFromBaseline(materials,rule)
    local total=rule.preservePrimaryTotal and primary(materials,rule.primaryRankIDs) or rule.targetPooledMean
    assert(finite(total),'Missing modeled Disenchant endpoint total: '..rule.ruleID)
    assert(finite(rule.targetRank2Share) and rule.targetRank2Share<=1,
        'Invalid modeled Disenchant rank share: '..rule.ruleID)
    local result=copy(materials)
    for _,material in ipairs(result) do
        if material.id==rule.primaryRankIDs[1] then
            material.expectedQuantity=total*(1-rule.targetRank2Share)
        elseif material.id==rule.primaryRankIDs[2] then
            material.expectedQuantity=total*rule.targetRank2Share
        end
        -- An endpoint quantity is a separate model, not a copied observed
        -- occurrence or positive stack distribution.
        material.chance=nil;material.chanceConfidence=nil;material.probabilityBasis=nil
        material.minQuantity=nil;material.maxQuantity=nil
    end
    return result
end

return function(records,rules,LL)
    assert(type(records)=='table' and type(rules)=='table','Missing modeled Disenchant build inputs')
    local result={}
    for _,rule in ipairs(rules) do
        assert(rule.method=='Disenchant' and rule.profession=='Enchanting' and rule.expansionID==11
            and rule.applyPolicy=='EXECUTE' and type(rule.ruleID)=='string'
            and type(rule.primaryRankIDs)=='table' and #rule.primaryRankIDs==2
            and type(rule.inputClassIDs)=='table','Unsupported modeled Disenchant rule')
        for _,classID in ipairs(rule.inputClassIDs) do
            assert(classes[classID],'Unsupported modeled Disenchant equipment class')
            local sourceClassID=classID
            local source=category(records,rule,sourceClassID)
            if not source and rule.baselineFallbackClassID then
                sourceClassID=rule.baselineFallbackClassID
                assert(classes[sourceClassID],'Unsupported Disenchant fallback equipment class')
                source=category(records,rule,sourceClassID)
            end
            if source then
                local endpoint,endpointClassID
                if rule.endpointRecordID then
                    -- The published Supplier cohort is an armor reference, even
                    -- when its endpoint is used to model a weapon scenario.
                    endpointClassID=4
                    endpoint=category(records,rule,endpointClassID,rule.endpointRecordID)
                end
                if not rule.endpointRecordID or endpoint then
                    local cap=confidence(rule.confidence0to100)
                    if sourceClassID~=classID or endpointClassID and endpointClassID~=classID then
                        cap=math.min(cap,confidence(rule.crossClassConfidence))
                    end
                    local materials=quantities(source,cap)
                    if primary(materials,rule.primaryRankIDs) then
                        local baseline={rule=copy(rule),inputClassID=classID,sourceClassID=sourceClassID,
                            recordID='modeled-disenchant-baseline:'..rule.ruleID..':'..classID,
                            referenceContextID=source.referenceContextID,sourceRecordID=source.recordID,
                            sourceKey=source.sourceKey,source=source.source,
                            sourceBuild=source.patchBuild,modelBuild=rule.build,
                            sourceProfileAssumed=true,
                            sourceProfileAssumption='Unknown character source treated as the canonical zero-skill, zero-point model prior; not a measured minimum-skill cohort',
                            baselineProfile={effectiveSkill=0,childPoints=0},materials=materials,
                            confidence0to100=cap}
                        if endpoint then
                            baseline.endpointMaterials=quantities(endpoint,cap)
                            baseline.endpointSourceRecordID=endpoint.recordID
                            baseline.endpointReferenceContextID=endpoint.referenceContextID
                            baseline.endpointSourceClassID=endpointClassID
                        else
                            baseline.endpointMaterials=endpointFromBaseline(materials,rule)
                            baseline.endpointSourceClaimIDs=copy(rule.sourceClaimIDs)
                            baseline.endpointSourceKey=rule.sourceKey
                        end
                        assert(primary(baseline.endpointMaterials,rule.primaryRankIDs),
                            'Missing modeled Disenchant endpoint ranks: '..rule.ruleID)
                        for _,material in ipairs(baseline.materials) do
                            baseline.confidence0to100=math.min(baseline.confidence0to100,material.confidence)
                        end
                        for _,material in ipairs(baseline.endpointMaterials) do
                            baseline.confidence0to100=math.min(baseline.confidence0to100,material.confidence)
                        end
                        baseline.confidence=baseline.confidence0to100
                        for _,list in ipairs({baseline.materials,baseline.endpointMaterials}) do
                            for _,material in ipairs(list) do material.confidence=math.min(material.confidence,baseline.confidence) end
                        end
                        -- Unlock outputs have an additive zero-profile term.
                        -- Their weaker identity/rate prior does not overwrite
                        -- the confidence of the independently modeled crystals.
                        if rule.additionalOutputs then
                            assert(rule.additionalOutputBaselinePolicy=='ZERO_BEFORE_UNLOCK')
                            for _,extra in ipairs(rule.additionalOutputs) do
                                local extraCap=math.min(cap,confidence(extra.confidence0to100))
                                for index,list in ipairs({baseline.materials,baseline.endpointMaterials}) do
                                    local existing
                                    for _,material in ipairs(list) do if material.id==extra.id then existing=material end end
                                    local material=existing or {id=extra.id}
                                    material.expectedQuantity=index==1 and 0 or extra.expectedQuantity
                                    material.confidence=extraCap;material.additionalOutput=true
                                    if not existing then list[#list+1]=material end
                                    table.sort(list,function(a,b) return a.id<b.id end)
                                end
                            end
                        end
                        -- Use the same inverse as runtime; at the explicit zero
                        -- prior this is an identity, not recovered source skill.
                        if LL and LL.NormalizeDisenchantQuantities then
                            baseline.materials=assert(LL:NormalizeDisenchantQuantities(baseline,
                                copy(baseline.materials),copy(baseline.baselineProfile)))
                        end
                        result[#result+1]=baseline
                    end
                end
            end
        end
    end
    table.sort(result,function(a,b)
        if a.rule.ruleID~=b.rule.ruleID then return a.rule.ruleID<b.rule.ruleID end
        return a.inputClassID<b.inputClassID
    end)
    return result
end
