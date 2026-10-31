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

-- A5: optional price in the tooltip header, default on.
local evaluated=LL.Evaluate
assert(loadfile('LootLiquidator/Badges.lua'))('LootLiquidator',LL)
LL.Evaluate=evaluated
LL.MarkupColor=function() return '' end
LL.db.showTooltips=true;LL.db.tooltipDetail=1
assert(LL.db.tooltipHeaderPrice==nil or LL.db.tooltipHeaderPrice==true)
local function header(decision)
    local tip={lines={}}
    function tip:AddLine(t) self.lines[#self.lines+1]=t end
    function tip:AddDoubleLine(l,r) self.lines[#self.lines+1]=l..' '..r end
    decision.facts=decision.facts or {id=1,classID=7};decision.conversionOptions={};decision.count=1
    LL:AppendRecommendationTooltip(tip,decision)
    return tip.lines[1] or ''
end
local h=header({action='S',method='Smelt',converted=68700})
assert(h:find('Smelt',1,true) and h:find(LL:Money(68700),1,true),'header shows smelt value: '..h)
h=header({action='V',vendor=1500})
assert(h:find(LL:Money(1500),1,true),'header shows vendor value: '..h)
h=header({action='A',rawAuction=10000,netAuction=9500})
assert(h:find(LL:Money(9500),1,true),'header shows auction value after AH cut: '..h)
h=header({action='Q'})
assert(not h:find('%dg'),'no price for ?: '..h)
LL.db.tooltipHeaderPrice=false
h=header({action='S',method='Smelt',converted=68700})
assert(not h:find(LL:Money(68700),1,true),'header price can be switched off: '..h)
print('PASS: optional price in the tooltip header (A5)')

-- B1: dead settings are gone from defaults and quietly removed from old saved data.
local old={methodEnabledD=true,methodEnabledX=false,allowMilling=true,allowExchanges=true,
    allowEnchantingAlt=true,includeVerifiedAlts=false,tooltipDetail=3}
LL:RemoveRetiredSettings(old)
for _,key in ipairs(LL.RetiredSettings) do assert(old[key]==nil,'retired setting kept: '..key) end
assert(old.includeVerifiedAlts==false and old.tooltipDetail==3,'live settings untouched')
assert(LL.HasProfessionAccess==nil,'unused allow* reader removed')
local said={}
local realPrint=print;print=function(m) said[#said+1]=m end
SlashCmdList.LOOTLIQUIDATOR('help');print=realPrint
local help=table.concat(said,'\n')
assert(#said>0 and not help:find('milling on',1,true) and not help:find('exchanges on',1,true),'help no longer lists dead toggles')
print('PASS: retired settings removed with a saved-data migration (B1)')

-- B3: one tooltip level: 0 Off, 1 Recommendation, 2 Alternatives, 3 Breakdown.
LL.db.tooltipHeaderPrice=true
local function lines(level)
    LL.db.tooltipDetail=level
    local tip={lines={}}
    function tip:AddLine(t) self.lines[#self.lines+1]=t end
    function tip:AddDoubleLine(l,r) self.lines[#self.lines+1]=l..' '..r end
    local model={inputCount=5,valueConfidence=48,materials={{id=900,chance=.5,minQuantity=1,maxQuantity=2,
        expectedQuantity=.75,netExpectedValue=5000}}}
    LL:AppendRecommendationTooltip(tip,{action='P',method='Prospect',converted=27200,vendor=1500,
        rawAuction=66500,netAuction=63175,count=1,facts={id=1,classID=7},
        conversionOptions={{name='Prospect',letter='P',value=27200,available=true,yieldModel=model}}})
    return table.concat(tip.lines,'\n'),#tip.lines
end
local text,n=lines(0)
assert(n==0,'Off adds no tooltip lines')
text,n=lines(1)
assert(n==1 and text:find('Loot Liquidator:',1,true),'Recommendation is one line: '..text)
text=lines(2)
assert(text:find('Auction',1,true) and text:find('Vendor',1,true) and text:find('Prospecting (Confidence 48%)',1,true),
    'Alternatives shows every option: '..text)
assert(not text:find('[x1-2]',1,true),'Alternatives hides the material breakdown')
text=lines(3)
assert(text:find('[x1-2]',1,true),'Breakdown shows materials: '..text)
-- Old "Show Loot Liquidator tooltips" off becomes the Off level; folded boxes are dropped.
local saved={showTooltips=false,tooltipDetail=3,tooltipAuction=false,showMaterialBreakdown=false,showFallback=false}
LL:RemoveRetiredSettings(saved)
assert(saved.tooltipDetail==0 and saved.showTooltips==nil and saved.tooltipAuction==nil and saved.showMaterialBreakdown==nil,
    'tooltip settings migrate to the level')
saved={showTooltips=true,tooltipDetail=3};LL:RemoveRetiredSettings(saved)
assert(saved.tooltipDetail==3,'level kept when tooltips were on')
print('PASS: tooltip levels Off/Recommendation/Alternatives/Breakdown (B3)')
