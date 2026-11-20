-- Offline startup allocation, using real Lua 5.1 and minimal game API stubs.
-- Run in a fresh process for each candidate; optional arg[1] replaces ItemDB.
assert(_VERSION=='Lua 5.1','Startup measurement requires Lua 5.1')
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
GetBuildInfo=function()return'12.1.5','70961','',120105 end
GetTime=function()return 100 end
SlashCmdList={}
wipe=function(t)for k in pairs(t)do t[k]=nil end return t end
local function memory()collectgarbage('collect');return collectgarbage('count')end
local LL={}
local initial=memory()
local previous=initial
for line in io.lines('LootLiquidator/LootLiquidator.toc')do
    if line:match('%.lua$')then
        local path=line=='ItemDBRuntime.lua' and arg and arg[1]or'LootLiquidator/'..line
        assert(loadfile(path))('LootLiquidator',LL)
        local current=memory()
        print(('%s: %.1f KiB (+%.1f)'):format(line,current-initial,current-previous))
        previous=current
    end
end
assert(LL:InitializeItemDB(),LL.itemDBError)
print(('Initialized: %.1f KiB'):format(memory()-initial))
