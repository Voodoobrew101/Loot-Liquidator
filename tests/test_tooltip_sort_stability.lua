-- Sorting is presentation only: source order/fields stay intact, including
-- same-ID ties, unknown values and repeated references to the same row.
local checks=0
local function check(v,label)assert(v,label);checks=checks+1 end
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
local LL={db={}}
assert(loadfile('LootLiquidator/Badges.lua'))('LL',LL)
C_Item={GetItemInfo=function(id)return id==100 and 'Same item' or id==99 and 'Alpha' or nil end}
local a={id=100,netExpectedValue=10,chance=.5,expectedQuantity=2}
local b={id=100,netExpectedValue=10,chance=.5,expectedQuantity=5}
local input={a,b,a}
for _,mode in ipairs({'database','value','chance','name','quantity','invalid-setting'})do
    LL.db.tooltipOutputSort=mode
    local sorted=LL:SortedTooltipMaterials(input)
    check(sorted~=input,'sorting returns a display copy: '..mode)
    if mode=='quantity'then
        check(sorted[1]==b and sorted[2]==a and sorted[3]==a,'quantity sort uses actual units')
    else check(sorted[1]==a and sorted[2]==b and sorted[3]==a,'equal sort fields keep per-occurrence order: '..mode)end
    check(input[1]==a and input[2]==b and input[3]==a,'source array order is unchanged: '..mode)
    check(a.expectedQuantity==2 and b.expectedQuantity==5,'material quantities never change: '..mode)
end
local missing={id=99,chance=0/0}
local highID={id=101,netExpectedValue=10,chance=.5}
LL.db.tooltipOutputSort='value'
local sorted=LL:SortedTooltipMaterials({highID,missing,b,a})
check(sorted[1]==b and sorted[2]==a and sorted[3]==highID and sorted[4]==missing,
    'numeric ties use item ID then original row position, with unknown quotes last')
LL.db.tooltipOutputSort='chance'
sorted=LL:SortedTooltipMaterials({missing,highID,a,b})
check(sorted[1]==a and sorted[2]==b and sorted[3]==highID and sorted[4]==missing,
    'NaN chance remains unknown and sorts after real chances')
LL.db.tooltipOutputSort='name'
sorted=LL:SortedTooltipMaterials({highID,a,missing,b})
check(sorted[1]==missing and sorted[2]==a and sorted[3]==b and sorted[4]==highID,
    'name order retains stable same-name rows and pending item names last')
for _,mode in ipairs({'database','value','name'})do
    LL.db.tooltipOutputSort=mode
    check(#LL:SortedTooltipMaterials(nil)==0,'empty display sort remains safe: '..mode)
end
print('PASS: '..checks..' stable immutable tooltip sorting checks')
