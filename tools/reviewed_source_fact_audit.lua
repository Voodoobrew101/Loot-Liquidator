-- Actual public query/renderer checks, isolated per fact to avoid a quadratic
-- full-catalogue scan. These checks grant no game actions or priced estimates.
return function(runtime)
    local data=runtime.ItemDB.reviewedSourceFacts or {schemaVersion=1,facts={}}
    local original=data.facts or {}
    local result={queriedFacts=0,renderedFacts=0,policyNegativeChecks=0,failures={}}
    local function verify(fact)
        local f={id=fact.inputItemID or (fact.inputFamilyIDs and fact.inputFamilyIDs[1]) or 900000001,
            expansionID=fact.expansionID,reagentQuality=fact.inputQualityRank,
            quality=fact.inputRarity,classID=fact.inputClassID or 7}
        if fact.gearKey then
            local era,quality,kind=fact.gearKey:match('^gear:(%d+):(%d+):(%a+)$')
            f.expansionID=tonumber(era);f.quality=tonumber(quality);f.classID=kind=='weapon' and 2 or 4
        elseif fact.gearScope then
            f.expansionID=fact.gearScope.expansionID;f.quality=fact.gearScope.rarity or 3
            f.classID=fact.gearScope.classID or 4
        end
        if type(f.quality)=='string' then
            f.quality=({poor=0,common=1,uncommon=2,rare=3,epic=4,legendary=5})[f.quality:lower()]
        end
        local option={name=fact.method,recipeID=fact.recipeID}
        data.facts={fact}
        local selected=runtime:ReviewedProcessingSourceFacts(f,option,{},1)
        assert(#selected==1 and selected[1].factID==fact.factID,
            'Reviewed fact is not reachable through its scoped public query: '..tostring(fact.factID))
        result.queriedFacts=result.queriedFacts+1
        local lines=runtime:ReviewedProcessingSourceFactLines(f,{option},{},10)
        assert(type(lines)=='table' and #lines>=2,
            'Reviewed fact cannot render: '..tostring(fact.factID))
        result.renderedFacts=result.renderedFacts+1
        assert(#runtime:ReviewedProcessingSourceFacts(f,option,{},2)==0,'Source fact leaked into personal-only mode')
        runtime.db.source_itemdb_enabled=false
        assert(#runtime:ReviewedProcessingSourceFacts(f,option,{},1)==0,'Disabled ItemDB source fact leaked')
        runtime.db.source_itemdb_enabled=true
        result.policyNegativeChecks=result.policyNegativeChecks+2
    end
    for _,fact in ipairs(original)do
        runtime.db.source_itemdb_enabled=true
        local ok,err=pcall(verify,fact)
        if not ok then result.failures[#result.failures+1]={factID=fact.factID,reason=tostring(err)} end
    end
    data.facts=original
    runtime.db.source_itemdb_enabled=true
    return result
end
