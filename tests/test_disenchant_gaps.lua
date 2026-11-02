-- C2b: the disenchant research-target list matches the real gaps in ItemDB.
local LL={}
assert(loadfile('LootLiquidator/ItemDBRuntime.lua'))('LootLiquidator',LL)
local gaps=assert(loadfile('database/research/disenchant-gaps.lua'))()
local passed=0
local function check(name,fn) fn(); passed=passed+1; print('PASS: '..name) end

local covered={}
local function scan(list)
    for _,r in ipairs(list or {}) do
        if r.method=='Disenchant' and type(r.gearKey)=='string' then covered[r.gearKey]=true end
    end
end
scan(LL.ItemDB.processing)
scan(LL.ItemDB.legacy and LL.ItemDB.legacy.processing)

local missing={}
for e=0,11 do for q=2,4 do for _,kind in ipairs({'armor','weapon'}) do
    local key=('gear:%d:%d:%s'):format(e,q,kind)
    if not covered[key] then missing[key]=true end
end end end

check('Every listed target really has no disenchant data',function()
    for _,t in ipairs(gaps.targets) do
        assert(not covered[t.key],t.key..' now has data: remove it from database/research/disenchant-gaps.lua')
    end
end)

check('Every real gap is listed as a research target',function()
    local listed={}
    for _,t in ipairs(gaps.targets) do
        assert(not listed[t.key],'duplicate target '..t.key); listed[t.key]=true
    end
    for key in pairs(missing) do assert(listed[key],key..' has no data and is not listed as a research target') end
end)

check('Targets carry no invented numbers',function()
    for _,t in ipairs(gaps.targets) do
        assert(t.status=='needs-data' and t.materials==nil and t.dropChance==nil and t.expectedQuantity==nil,t.key)
        assert(t.expansion and t.qualityName and (t.gearKind=='armor' or t.gearKind=='weapon'),t.key)
    end
end)

check('"Other gear kind has data" flags are correct',function()
    for _,t in ipairs(gaps.targets) do
        local other=t.key:gsub(t.gearKind..'$',t.gearKind=='armor' and 'weapon' or 'armor')
        assert((t.otherKindHasData==true)==(covered[other]==true),t.key)
    end
end)

print(('DISENCHANT GAPS: %d passed, 0 failed; %d research targets'):format(passed,#gaps.targets))
