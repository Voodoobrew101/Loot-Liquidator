-- Test-only native recipe snapshots. Production keeps unused recipe scope
-- tuples and restores output metadata only for actual learned recipes.
local native=assert(loadfile('database/profession-profile-rules.lua'))()
local function copy(value)
    if type(value)~='table'then return value end
    local out={}for key,item in pairs(value)do out[key]=copy(item)end return out
end
return function(LL,id)
    local source=assert(native.recipes[id],'native fixture recipe '..tostring(id))
    local saved={learned=true,profession=source.profession,outputID=assert(source.outputIDs[1]),
        outputCount=source.outputCount or 1,outputQualityItems=copy(source.outputQualityItems),
        qualityOrderVerified=source.qualityOrderVerified,reagentSlots={}}
    return saved,assert(LL:RestoreProfessionRecipeMetadata(id,saved))
end
