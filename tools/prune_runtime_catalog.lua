-- Build-time only. Keep numerical source/rule references and exact native rank
-- families; unrelated crafting catalog rows do not become item exceptions.
local function count(t)local n=0 for _ in pairs(t or {})do n=n+1 end return n end
local function copy(t)local out={} for k,v in pairs(t or {})do out[k]=v end return out end
local recipeFields={recipeID=true,recipeSpellID=true,requiredSpell=true}
local recipeLists={recipeIDs=true,alternateRecipeIDs=true}
local itemFields={id=true,itemID=true,inputItemID=true,outputItemID=true,outputID=true,
    sourceItemID=true,targetItemID=true,tokenID=true,rewardID=true}
local itemLists={rankIDs=true,rankItemIDs=true,inputRankItemIDs=true,primaryRankIDs=true,
    inputItemIDs=true,outputItemIDs=true,outputIDs=true,itemIDs=true,memberInputItemIDs=true,
    modeledMissingRankZeroItemIDs=true,candidates=true,rewards=true}
local itemMaps={inputs=true,Conversions=true,ResearchTokenCandidates=true,ResearchProcessingInputs=true,
    processable=true,costs=true,rewardClassMasks=true,rewardRequirements=true}
local flagOnly={noDisenchant=true,researchNoDisenchant=true,researchNoDisenchantObservations=true,
    researchNoDisenchantGlobalProofs=true}
local function scopeTuple(recipe)
    local thresholds={}
    for _,threshold in ipairs(recipe.qualityThresholds or {})do
        thresholds[#thresholds+1]={threshold.rank,threshold.fraction}
    end
    local flags=(recipe.supportsQuality and 1 or 0)
        +(recipe.supportsMulticraft==true and 2 or recipe.supportsMulticraft==false and 4 or 0)
        +(recipe.supportsResourcefulness==true and 8 or recipe.supportsResourcefulness==false and 16 or 0)
    return {recipe.profession,recipe.expansionID,recipe.labels or {},recipe.difficulty or false,
        thresholds,flags,recipe.capabilityConfidence and recipe.capabilityConfidence.multicraft or false}
end
return function(profiles,db,additionalRoots)
    assert(type(profiles)=='table' and type(profiles.items)=='table' and type(profiles.recipes)=='table',
        'Native profession catalog required')
    local items,recipes,seen={},{},{}
    local function id(value)
        if type(value)=='string'and value:match('^%d+$')then value=tonumber(value)end
        return type(value)=='number'and value>0 and value%1==0 and value or nil
    end
    local function item(value)
        value=id(value);if value and profiles.items[value]then items[value]=true end
    end
    local function recipe(value)
        value=id(value);if value and profiles.recipes[value]then recipes[value]=true end
    end
    local function values(value,add)
        if type(value)=='table'then for _,child in pairs(value)do
            if type(child)~='table'then add(child)end
        end else add(value)end
    end
    local function keys(value,add)
        if type(value)=='table'then for key in pairs(value)do add(key)end end
    end
    local function walk(value)
        if type(value)~='table'then return end
        if seen[value] or value==profiles.items or value==profiles.recipes or value==profiles.qualityFamilies then return end
        seen[value]=true
        for key,child in pairs(value)do if not flagOnly[key]then
            if recipeFields[key]then recipe(child)
            elseif recipeLists[key]then values(child,recipe)
            elseif key=='recipeQualityModels'then keys(child,recipe)
            elseif itemFields[key]and not (key=='id'and value.kind=='currency')then item(child)
            elseif itemLists[key]then values(child,item)
            elseif itemMaps[key]then keys(child,item)
            elseif key=='outputs'and type(child)=='table'then
                for itemID,output in pairs(child)do item(itemID);if type(output)~='table'then item(output)end end
            elseif type(key)=='string'and key:match('[Ff]amilyID$')then
                local family=profiles.qualityFamilies and profiles.qualityFamilies[id(child)]
                if family then values(family.rankItemIDs,item)end
            end
            walk(child)
        end end
    end
    -- Only item/recipe identities are roots. Counts, labels and trait IDs do
    -- not become crafting records; native no-DE lists remain flag sets only.
    walk(db);walk(profiles);walk(additionalRoots)
    for id in pairs(recipes)do walk(profiles.recipes[id])end
    local changed=true
    while changed do
        changed=false
        for id in pairs(items)do
            local native=profiles.items[id]
            local family=native and profiles.qualityFamilies and profiles.qualityFamilies[native.qualityFamilyID]
            for _,rankID in ipairs(family and family.rankItemIDs or {})do
                if profiles.items[rankID] and not items[rankID]then items[rankID]=true;changed=true end
            end
        end
    end
    local result=copy(profiles)
    result.items={};result.recipes={};result.recipeScopes={}
    for id in pairs(items)do result.items[id]=profiles.items[id]end
    for id,recipe in pairs(profiles.recipes)do
        if recipes[id]then result.recipes[id]=recipe
        else result.recipeScopes[id]=scopeTuple(recipe)end
    end
    -- Small rank-identity definitions support a future real learned recipe;
    -- no unused item descriptions or output/reagent catalogs accompany them.
    return result,{itemsBefore=count(profiles.items),itemsAfter=count(result.items),
        recipesBefore=count(profiles.recipes),recipesAfter=count(result.recipes),
        scopeTuples=count(result.recipeScopes),qualityFamilies=count(profiles.qualityFamilies)}
end
