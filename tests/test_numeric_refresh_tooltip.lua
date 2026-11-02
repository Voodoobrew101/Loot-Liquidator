-- New real evidence must reach the actual engine and tooltip. Prices here are
-- deterministic test prices (100 copper per material), never live quotations.
local LL={}
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
GetBuildInfo=function()return '12.1.5','123456','Oct 29 2026',120105 end
GetTime=function()return 100 end
for _,file in ipairs({'ItemDBRuntime.lua','ProfessionModels.lua','Database.lua','ConversionEngine.lua','Badges.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LootLiquidator',LL)
end
LL.db={source_itemdb_enabled=true,source_personal_enabled=false,source_legacy_enabled=false,
    tooltipDetail=3,processingModes={D=1}}
LL:MigrateEvidenceSettings()
assert(LL:InitializeItemDB() and not LL.itemDBError)
LL.EligibleDisenchant=function()return true end
LL.DisenchantExpansion=function(_,f)return f.expansionID end
LL.ProcessingPlayerConditions=function()return {skill=0,effectiveSkill=0}end
LL.GetOutputPrice=function()return 100 end
LL.MarkupColor=function()return '|cffffffff'end
LL.Money=function(_,value)return ('%.6f copper (fixture)'):format(value)end
LL.ProfessionProgression=function()return {}end
local output={}
local function render(id,expansion,quality)
    local facts={id=id,expansionID=expansion,quality=quality,classID=4,count=1}
    local option=assert(LL:EvaluateDisenchant(facts))
    option.letter='D';option.available=true
    assert(type(option.value)=='number' and option.value>0,'new exact-item estimate has a value')
    local tip={lines={}}
    function tip:AddLine(s)self.lines[#self.lines+1]=s end
    function tip:AddDoubleLine(a,b)self.lines[#self.lines+1]=a..' | '..b end
    LL:AppendRecommendationTooltip(tip,{action='D',facts=facts,conversionOptions={option},count=1})
    local text=table.concat(tip.lines,'\n')
    assert(not text:find('Insufficient Data',1,true),'numeric item must not render missing data')
    assert(text:find('provisional',1,true),'uncertain historical contexts stay labelled')
    assert(not text:find('  EV ',1,true),'owner-requested EV prefix cleanup')
    output[#output+1]='ITEM '..id..' — synthetic prices, offline rendering\n'..text
    return option,text
end
local warmaul,text=render(24995,1,2)
assert(text:find('75.4%',1,true) and text:find('[x2-6]',1,true) and text:find('3.015',1,true))
assert(warmaul.value>345 and warmaul.value<346,'derived TBC baseline prices expected units once')
assert(warmaul.confidence<=50,'a derived mean cannot inherit 100% occurrence confidence')
local dust
for _,m in ipairs(warmaul.materials) do if m.id==22445 then dust=m end end
assert(dust and math.abs(dust.chance-1559/2068)<1e-10,'original occurrence counts survive import')
-- Average is the existing midpoint estimate, not a newly claimed measured mean.
assert(math.abs(dust.expectedQuantity-3.0155)<1e-4)
local midnight,midText=render(258931,11,3)
assert(midText:find('60.3%',1,true) and midText:find('[x1-3]',1,true) and midText:find('1.238',1,true))
assert(midnight.value>186 and midnight.value<187,'Midnight measured units reach valuation')
local midnightDust
for _,m in ipairs(midnight.materials) do if m.id==243599 then midnightDust=m end end
assert(math.abs(midnightDust.chance-896/1485)<1e-10)
assert(math.abs(midnightDust.expectedQuantity-1838/1485)<1e-4)
-- Disabling both sources still respects the player's evidence choice.
LL.db.source_itemdb_enabled=false;LL._processingModelCache=nil
local disabled=LL:EvaluateDisenchant({id=24995,expansionID=1,quality=2,classID=4,count=1})
assert(disabled.value==nil,'numeric import must not bypass disabled sources')
if arg and arg[1] then
    local file=assert(io.open(arg[1]..'/numeric-tooltip-proof.txt','w'))
    file:write(table.concat(output,'\n\n'));file:close()
end
print('PASS: imported Warmaul and Midnight chances/ranges/means reach priced tooltips; source gates preserved')
