-- A4: the "?" badge appears only when no option has any estimate.
-- Synthetic items; every external lookup is stubbed.
GetTime=function()return 100 end
time=function()return 1000 end
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
SlashCmdList={};max,min=math.max,math.min
wipe=wipe or function(t) for k in pairs(t) do t[k]=nil end return t end
local LL={ItemDB={schemaVersion=1,processing={},tokenRewards={}},db={}}
assert(loadfile('LootLiquidator/Core.lua'))('LootLiquidator',LL)
LL.db.enabled=true
LL.db.minConversionExtraGold=5
LL.db.minGearProfitGold=100
LL.db.minReagentProfitGold=2

local G=10000
local item, prices, conversion
LL.GetItemFacts=function() return item end
LL.ATTTokenInfo=function() return nil end
LL.AppearanceCollectionState=nil
LL.BestConversion=function() return conversion end
LL.AHFeeRate=function() return 0.05 end
LL.AuctionEligible=function() return true end
LL.IsNonAuctionableByBinding=function() return false end
LL.DisenchantEligibility=function() return false end
LL.EligibleDisenchant=function() return false end
LL.ChosenTSMAuctionOperation=nil
LL.ReportMissing=function() end
LL.Price=function(_,source) return prices[source] end

local n=0
local function decide(f,p,c)
    n=n+1
    item=f;prices=p or {};conversion=c
    f.id=f.id or (1000+n);f.link='item:'..f.id;f.count=f.count or 1;f.context=f.context or {}
    f.tsmString='i:'..f.id..':'..n -- unique per case so the decision cache never repeats
    return LL:Evaluate(f.link,f.context)
end

-- 1. Tradeable reagent with a small TSM price and no vendor price: was "?"
-- (auction below the profit threshold, nothing else). Now: A.
local r=decide({classID=7,vendor=0},{dbminbuyout=1*G})
assert(r.action=='A',('only priced option is the AH, got %s (%s)'):format(tostring(r.action),tostring(r.why)))

-- 2. No TSM price at all, but a vendor price: was "?", now V.
r=decide({classID=7,vendor=50},{})
assert(r.action=='V','vendor price is an estimate, got '..tostring(r.action))

-- 3. Only a small conversion value: pick the conversion letter.
r=decide({classID=7,vendor=0,conversionOptions={}},{},{name='Prospect',value=3000})
assert(r.action=='P','small prospecting value should win over nothing, got '..tostring(r.action))

-- 4. TSM operation blocks posting, nothing else priced, but TSM has a market price.
local realAuctionUnit=LL.AuctionUnit
LL.AuctionUnit=function() return nil,'Below TSM operation minimum' end
r=decide({classID=7,vendor=0},{dbmarket=2*G})
assert(r.action=='A' and r.why:find('Below TSM operation minimum',1,true),'blocked AH still has an estimate')
LL.AuctionUnit=realAuctionUnit

-- 5. Truly nothing: still "?".
r=decide({classID=7,vendor=0},{})
assert(r.action=='Q' and r.why:find('no option has any estimate',1,true),'nothing known stays ?')

-- 6. Clear profit cases are unchanged.
r=decide({classID=7,vendor=10},{dbminbuyout=50*G})
assert(r.action=='A','profitable auction stays A')
r=decide({classID=7,vendor=10,conversionOptions={}},{},{name='Smelt',value=10*G})
assert(r.action=='S','profitable smelt stays S')

print('PASS: ? badge only when no option has any estimate (A4)')
