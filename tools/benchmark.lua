-- Optional offline CPU probe: lua5.1 tools/benchmark.lua /path/to/baseline
-- The baseline folder must contain 0.9.70 ResearchDB/GameData/StatYieldProfiles
-- and PR #4 ConversionEngine. This measures distribution lookup, not live UI FPS.
local baselinePath=assert(arg[1],'baseline directory required')
local iterations=tonumber(arg[2]) or 10000
GetTime=function() return 100 end
GetBuildInfo=function() return '12.1.5','123456','',120105 end
local before={db={characters={}}}
for _,name in ipairs({'ResearchDB.lua','GameData.lua','StatYieldProfiles.lua','ConversionEngine.lua'}) do
    assert(loadfile(baselinePath..'/'..name))('LootLiquidator',before)
end
local after={db={characters={}}}
for _,name in ipairs({'itemdb.lua','Database.lua','ConversionEngine.lua'}) do
    assert(loadfile('LootLiquidator/'..name))('LootLiquidator',after)
end
after:MigrateEvidenceSettings()
for _,namespace in ipairs({before,after}) do namespace.CharacterKey=function() return 'Benchmark - Realm' end end
local input={id=765,quality=1,expansionID=0,classID=7}
local option={name='Mill',inputCount=5,recipeID=51005,character='Benchmark - Realm'}
local function run(name,fn)
    collectgarbage('collect')
    local memory=collectgarbage('count')
    local at=os.clock()
    local result
    for i=1,iterations do result=assert(fn()) end
    local elapsed=os.clock()-at
    collectgarbage('collect')
    print(('%s: %d calls, %.4f CPU seconds, %.1f KiB retained delta'):format(name,iterations,elapsed,collectgarbage('count')-memory))
    return result
end
local a=run('0.9.70 / PR4',function() return before:ProcessingYieldDisplayModel(input,option) end)
local b=run('modernized (warm distribution cache)',function() return after:ResolveEvidenceModel(input,option,nil,1) end)
local function quantities(model)
    local out={} for _,m in ipairs(model.materials) do out[m.id]=m.expectedQuantity/model.inputCount end return out
end
local original=quantities(a)
for id,expected in pairs(quantities(b)) do assert(original[id] and math.abs(original[id]-expected)<1e-9,'per-input baseline changed') end
print('PASS: same per-input historical yield in this fixture. No live-game performance claim.')
