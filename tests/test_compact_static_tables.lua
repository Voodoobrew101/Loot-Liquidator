-- The compact serializer must change storage only, including sparse-map length.
local compact=assert(loadfile('tools/compact_static_tables.lua'))()
local function encode(v)
    if type(v)=='number'then return ('%.17g'):format(v)end
    if type(v)=='string'then return ('%q'):format(v)end
    if type(v)=='boolean'then return tostring(v)end
    error('Scalar expected')
end
local scalarCount=0
local function same(a,b,path)
    assert(type(a)==type(b),path..': type')
    if type(a)~='table'then assert(a==b,path..': value');scalarCount=scalarCount+1;return end
    assert(#a==#b,path..': length')
    for k,v in pairs(a)do same(v,b[k],path..'.'..tostring(k))end
    for k in pairs(b)do assert(a[k]~=nil,path..': added key')end
end
local source={a={1,2,3},b={1,2,3},sparse={[1]='a',[3]='c'},flags={x=false},empty={}}
local code=compact(source,encode)
local LL={ItemDB={}}
assert(loadstring('local LL=...;'..code))(LL)
same(source,LL.ItemDB.professionProfiles,'fixture')
assert(LL.ItemDB.professionProfiles.a==LL.ItemDB.professionProfiles.b,'Identical static values must share storage')
assert(code==compact(source,encode),'Serializer is nondeterministic')
local before={}
assert(loadfile('LootLiquidator/ItemDBRuntime.lua'))('LL',before)
assert(before.ItemDB.reviewedSourceFacts==nil,'Informational research archive leaked into live addon')
local native=assert(loadfile('database/profession-profile-rules.lua'))()
same(native,before.ItemDB.professionProfiles,'professionProfiles')
print(('PASS: compact static metadata preserves %d scalar values, types and lengths; research details remain offline'):format(scalarCount))
