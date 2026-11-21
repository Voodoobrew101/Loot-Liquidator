-- Reconstruct the former explicit-key layout without compiling the entire DB
-- into one Lua 5.1 prototype (which has a fixed constant-table limit). Compile
-- every root section separately; oversized sections are split at table entries.
-- Parents still use explicit keyed constructors, including numeric list keys.
-- Compile factories before measuring allocation so code/constants are excluded.
local function orderedKeys(value)
    local keys={} for key in pairs(value)do keys[#keys+1]=key end
    table.sort(keys,function(a,b)
        if type(a)==type(b)then
            if type(a)=='boolean'then return not a and b end
            return a<b
        end
        return type(a)<type(b)
    end)
    return keys
end
local function keyed(value)
    local kind=type(value)
    if kind=='number'then return string.format('%.17g',value)end
    if kind=='string'then return string.format('%q',value)end
    if kind=='boolean'then return tostring(value)end
    assert(kind=='table','Unsupported database constructor type: '..kind)
    local entries={'{'}
    for _,key in ipairs(orderedKeys(value))do
        entries[#entries+1]='['..keyed(key)..']='..keyed(value[key])..','
    end
    entries[#entries+1]='}'
    return table.concat(entries)
end
return function(database)
    local compile,partition
    partition=function(value)
        local parts,entries={}, {'local parts=...;return {'}
        for _,key in ipairs(orderedKeys(value))do
            parts[#parts+1]=compile(value[key])
            entries[#entries+1]='['..keyed(key)..']=parts['..#parts..'](),'
        end
        entries[#entries+1]='}'
        local factory,why=loadstring(table.concat(entries))
        assert(factory,'Keyed database parent constructor failed: '..tostring(why))
        return function()return factory(parts)end
    end
    compile=function(value)
        local factory,why=loadstring('return '..keyed(value))
        if factory then return factory end
        assert(type(value)=='table' and (why:find('constant',1,true) or why:find('items in a constructor',1,true)),
            'Keyed database constructor failed: '..tostring(why))
        return partition(value)
    end
    return partition(database)
end
