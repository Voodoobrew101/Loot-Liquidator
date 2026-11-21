-- Measure real Lua 5.1 table allocation while preserving every database value.
-- An optional pre-change runtime file also proves the current-main migration.
assert(_VERSION=='Lua 5.1','Memory regression requires the actual Lua 5.1 engine')
local LL={}
assert(loadfile('LootLiquidator/ItemDBRuntime.lua'))('LootLiquidator',LL)
local values,tables=0,0
local function equal(left,right)
    assert(type(left)==type(right),'Database value type changed')
    if type(left)~='table' then assert(left==right,'Database value changed');values=values+1;return end
    tables=tables+1
    assert(not getmetatable(left) and not getmetatable(right),'Unexpected database metatable')
    assert(#left==#right,'Database table length changed')
    for key,value in pairs(left) do equal(value,right[key]) end
    for key in pairs(right) do assert(left[key]~=nil,'Database gained a key') end
end
if arg and arg[1] then
    local before={}
    assert(loadfile(arg[1]))('LootLiquidator',before)
    equal(before.ItemDB,LL.ItemDB)
    print(('PASS: pre-change ItemDB preserved: %d tables, %d scalar values, all types and lengths'):format(tables,values))
end
local oldConstructor=assert(loadfile('tests/keyed_database_constructor.lua'))()(LL.ItemDB)
collectgarbage('collect')
local before=collectgarbage('count')
local old=oldConstructor()
collectgarbage('collect')
local keyedSize=collectgarbage('count')-before
equal(LL.ItemDB,old)
old=nil
collectgarbage('collect')
before=collectgarbage('count')
local fresh={}
assert(loadfile('LootLiquidator/ItemDBRuntime.lua'))('LootLiquidator',fresh)
collectgarbage('collect')
local compiledSize=collectgarbage('count')-before
assert(compiledSize<keyedSize,'Native lists must allocate less than keyed lists')
print(('PASS: all ItemDB values/types/lengths preserved; keyed %.1f KiB, native lists %.1f KiB (%.1f%% less)')
    :format(keyedSize,compiledSize,(1-compiledSize/keyedSize)*100))
