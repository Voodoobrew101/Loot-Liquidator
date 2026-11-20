-- Derived copies only: input source rows and their empirical counts are retained.
local function copy(v)
    if type(v)~='table' then return v end
    local result={} for k,x in pairs(v) do result[k]=copy(x) end return result
end
return function(db,LL)
    local result={}
    for _,record in ipairs(db.processing) do
        local recipe=db.professionProfiles.recipes[record.recipeID]
        local profession=record.profession or (recipe and recipe.profession) or
            ({Disenchant='Enchanting',Mill='Inscription',Prospect='Jewelcrafting',Crush='Jewelcrafting',Smelt='Mining'})[record.method]
        local expansion=record.expansionID or (recipe and recipe.expansionID)
        if record.sourceKey~='personal' and record.sourceKey~='imported' and not (record.method=='Disenchant' and expansion==11) and profession and expansion
            and db.professionProfiles.profiles[profession..':'..expansion] then
            local materials={}
            for _,material in ipairs(record.materials) do
                materials[#materials+1]={id=material.id,expectedQuantity=material.expectedQuantity.value,
                    confidence=material.expectedQuantity.confidence}
            end
            local source=record.baselineProfile or {skill=0,preSpecializationSkill=0,stats={},specializationPoints={}}
            local option={name=record.method,recipeID=record.recipeID,inputCount=record.inputCount,profession=profession}
            local facts={id=record.inputItemID,reagentQuality=record.inputQualityRank,
                expansionID=expansion,quality=record.inputRarity,classID=record.inputClassID}
            local params=LL:ProfessionProfileParameters(profession,expansion,source,option,facts)
            local normalized=LL:NormalizeProfessionBaseline({inputCount=record.inputCount,
                expectedInputCount=record.expectedInputCount,duration=record.duration,materials=materials},params,option)
            if normalized then
                normalized.sourceRecordID=record.recordID
                normalized.sourceProfileAssumed=record.baselineProfile==nil or record.baselineProfileAssumed==true
                normalized.sourceProfile=copy(source)
                normalized.baselineConfidence=math.min(record.baselineProfile and params.confidence or 5,
                    record.baselineProfileConfidence or 100,
                    normalized.normalizationConfidence or 100)
                result[record.recordID]=normalized
            end
        end
    end
    return result
end
