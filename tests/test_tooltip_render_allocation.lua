-- Repeated incomplete tooltip fields search real-shaped baseline rows. This
-- catches a return to per-source empty tables/helper closures, without a cache.
local checks=0
local function check(v,label)assert(v,label);checks=checks+1 end
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
GetBuildInfo=function()return '12.1.5','70961' end
C_Item={GetItemInfo=function(id)return 'Material '..id,nil,1 end,GetItemIconByID=function()return 123 end}
local LL={db={tooltipDetail=3,tooltipOutputSort='value'}}
assert(loadfile(BADGES_UNDER_TEST or 'LootLiquidator/Badges.lua'))('LL',LL)
LL.MarkupColor=function()return ''end
LL.Money=function(_,value)return tostring(value)..' copper'end
LL.CharacterKey=function()return 'Fixture' end
LL.EvidenceSourceWeight=function()return 1 end
LL.ProcessingMethodMode=function()return 1 end
local function field(value)return{value=value,status='measured',confidence=80}end
local records={}
for index=1,32 do
    local record={recordID='fixture:'..index,sourceKey='itemdb',method='Prospect',recipeID=500,
        inputItemID=100,expansionID=10,inputCount=5,materials={}}
    for id=1001,1008 do record.materials[#record.materials+1]={id=id,
        expectedQuantity=field(.4),dropChance=field(.25),minQuantity=field(1),maxQuantity=field(2)}end
    records[#records+1]=record
end
LL._evidenceIndex={['Prospect:100']=records}
local model={inputCount=5,confidence=80,materials={}}
for id=1001,1008 do model.materials[#model.materials+1]={id=id,expectedQuantity=.4,
    netExpectedValue=40,netUnitPrice=100,confidence=80}end
local option={name='Prospect',letter='P',recipeID=500,available=true,value=64,yieldModel=model}
local decision={action='V',vendor=1,facts={id=100,expansionID=10,quality=1,classID=7},conversionOptions={option}}
local tip={materials=0}
function tip:AddLine()end
function tip:AddDoubleLine(left,right)
    if left:find('Material ',1,true)then
        check(left:find('25%',1,true)and left:find('[1-2]',1,true)and right=='8 copper',
            'baseline percentage/range and actual quantity-derived gold reach every row')
        self.materials=self.materials+1
    end
end
LL:AppendRecommendationTooltip(tip,decision)
check(tip.materials==8,'all actual material rows remain visible')
-- Use a no-storage sink during allocation measurement, including all actual
-- formatting work. A fixed bound allows ordinary display copies and strings.
tip.AddDoubleLine=function()end
for i=1,5 do LL:AppendRecommendationTooltip(tip,decision)end
collectgarbage('collect')
local before=collectgarbage('count')
collectgarbage('stop')
for i=1,100 do LL:AppendRecommendationTooltip(tip,decision)end
local allocated=collectgarbage('count')-before
collectgarbage('restart');collectgarbage('collect')
local retained=collectgarbage('count')-before
check(allocated<4000,'100 baseline-render refreshes allocate excessive transient memory: '..allocated..' KiB')
check(retained<32,'repeated display-only renders retained new data: '..retained..' KiB')
for _,m in ipairs(model.materials)do
    check(m.expectedQuantity==.4 and m.netExpectedValue==40 and m.chance==nil
        and m.minQuantity==nil and m.maxQuantity==nil,'rendering preserves each actual model quantity/price/source field')
end
check(records[1].materials[1].dropChance.value==.25,'rendering preserves original baseline evidence')
print(('PASS: %d rendering/value/source checks; %.1f KiB temporary, %.1f KiB retained for100 refreshes'):format(checks,allocated,retained))
