-- Quotes may repeat within one evaluation; later evaluations and incomplete
-- native item information must still read current prices and binding metadata.
local checks=0
local function check(v,why)assert(v,why);checks=checks+1 end
local function eq(a,b,why)check(a==b,(why or '')..': '..tostring(a)..' ~= '..tostring(b))end
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
SlashCmdList={};GetTime=function()return 100 end
local LL={db={enabled=true},ItemDB={professionProfiles={items={}}}}
assert(loadfile('LootLiquidator/Core.lua'))('LootLiquidator',LL)
assert(loadfile('LootLiquidator/ConversionEngine.lua'))('LootLiquidator',LL)
local items=LL.ItemDB.professionProfiles.items
for _,id in ipairs({101,102})do items[id]={bindType=2}end
for _,id in ipairs({103,105,106,107})do items[id]={bindType=1}end
items[104]={}
local fee=.05
LL.AHFeeRate=function()return fee end
LL.TSMString=function(_,link,id)return link or 'item:'..id end
LL.GetNativeProfessionItem=function(_,id)return items[id]end
local asks={['item:101']=100,['item:102']=200,['item:101:bonus-A']=80,['item:101:bonus-B']=60,['item:104']=100}
local priceReads,nativeReads=0,0
LL.Price=function(_,source,item)
 priceReads=priceReads+1
 if source=='dbminbuyout'then return asks[item]end
end
local native={}
for _,id in ipairs({101,102,103,104,105,106,107})do native[id]={name='Known item',vendor=0}end
C_Item={GetItemInfo=function(id)
 nativeReads=nativeReads+1;local x=native[id]or{}
 return x.name,nil,nil,nil,nil,nil,nil,nil,nil,nil,x.vendor
end}
local function request()
 LL._outputPriceRequest={db=LL.db,database=LL.ItemDB,fee=fee,quotes={}}
 priceReads=0;nativeReads=0
end
request()
local price,source=LL:GetOutputPrice(101)
eq(price,95,'AH cut is unchanged');eq(source,'TSM auction estimate (net)')
eq(LL:GetOutputPrice(101),95);eq(priceReads,1,'ready repeated output quote is reused')
eq(select('#',LL:GetOutputPrice(101)),2,'public quote still returns exactly price/source')
eq(LL:GetOutputPrice(101,'item:101:bonus-A'),76)
eq(LL:GetOutputPrice(101,'item:101:bonus-B'),57)
eq(LL:GetOutputPrice(101,'item:101:bonus-A'),76)
eq(priceReads,3,'distinct full item links never share a variant quote')
eq(LL:GetOutputPrice(102,'item:101'),95)
eq(priceReads,4,'item ID remains part of the key even with an identical link')
request()
price,source=LL:GetOutputPrice(103)
eq(price,0,'known zero vendor value is retained');eq(source,'Vendor output')
eq(LL:GetOutputPrice(103),0);eq(nativeReads,1,'ready zero value can be reused')
request();native[104].vendor=2
eq(LL:GetOutputPrice(104),2,'unknown binding preserves the current vendor fallback')
eq(LL:GetOutputPrice(104),2);eq(nativeReads,2,'unknown binding fallback remains retryable')
items[104].bindType=2
eq(LL:GetOutputPrice(104),95,'resolved binding can expose its AH quote in the same request')
eq(LL:GetOutputPrice(104),95);eq(priceReads,1)
request();native[105]={}
eq(LL:GetOutputPrice(105),nil,'pending vendor data stays unknown')
native[105]={name='Known item',vendor=7}
eq(LL:GetOutputPrice(105),7);eq(LL:GetOutputPrice(105),7)
eq(nativeReads,2,'a nil result is retried, then the ready result is reused')
request();native[107]={vendor=0}
eq(LL:GetOutputPrice(107),0,'the existing unnamed native zero remains its current return value')
native[107]={name='Known item',vendor=12}
eq(LL:GetOutputPrice(107),12,'unnamed pending zero cannot freeze a later known value')
request();local oldAPI=C_Item;C_Item=nil
eq(LL:GetOutputPrice(106),0,'bound output fallback remains zero')
C_Item=oldAPI;native[106]={name='Known item',vendor=9}
eq(LL:GetOutputPrice(106),9,'bound fallback without native data is not memoized')
request();eq(LL:GetOutputPrice(101),95)
fee=.1;eq(LL:GetOutputPrice(101),90,'changed AH fee bypasses the prior request quote')
fee=.05;local oldDB=LL.db;LL.db={enabled=true}
eq(LL:GetOutputPrice(101),95);eq(priceReads,3,'a different settings database bypasses the request memo')
LL.db=oldDB;local oldData=LL.ItemDB;LL.ItemDB={professionProfiles={items=items}}
eq(LL:GetOutputPrice(101),95);eq(priceReads,4,'native database replacement bypasses the request memo')
LL.ItemDB=oldData
asks['item:101']=300;request();eq(LL:GetOutputPrice(101),285,'a later request reads the current price')
LL._outputPriceRequest=nil;priceReads=0
LL:GetOutputPrice(101);LL:GetOutputPrice(101)
eq(priceReads,2,'direct calls outside a request never create a persistent price cache')
request()
check(pcall(LL.GetOutputPrice,LL,0/0),'nonfinite item identity bypasses memo indexing')
check(pcall(LL.GetOutputPrice,LL,math.huge),'infinite item identity bypasses memo indexing')
check(pcall(LL.GetOutputPrice,LL,101,{}),'unsupported item-link identity bypasses memo indexing')
eq(next(LL._outputPriceRequest.quotes),nil,'unsupported identities do not populate request quotes')
issecretvalue=function(value)return value=='secret-link-fixture'end
LL:GetOutputPrice(101,'secret-link-fixture');LL:GetOutputPrice(101,'secret-link-fixture')
eq(next(LL._outputPriceRequest.quotes),nil,'secret identities do not become memo keys')
issecretvalue=nil;LL._outputPriceRequest=nil
-- Exercise the real Core wrapper without running unrelated recommendation
-- policy: item facts deliberately return nil after these quote reads.
local active,inside=0,nil
LL.GetItemFacts=function(self,link)
 local scope=rawget(self,'_outputPriceRequest');check(scope~=nil,'Evaluate opens a price request')
 if link=='outer'then
  inside=scope;self:GetOutputPrice(101);self:Evaluate('nested');self:GetOutputPrice(101)
 elseif link=='nested'then eq(scope,inside,'nested evaluation shares the active request');self:GetOutputPrice(101)
 elseif link=='error'then self:GetOutputPrice(101);error('intentional quote-scope failure')
 end
 return nil
end
priceReads=0;eq(LL:Evaluate('outer'),nil);eq(priceReads,1,'nested quotes are reused for one evaluation')
eq(rawget(LL,'_outputPriceRequest'),nil,'successful evaluation discards all request quotes')
asks['item:101']=400;priceReads=0;LL:Evaluate('outer');eq(priceReads,1)
local ok,reason=pcall(LL.Evaluate,LL,'error')
check(not ok and tostring(reason):find('intentional quote%-scope failure'),'original evaluation error is preserved')
eq(rawget(LL,'_outputPriceRequest'),nil,'failed evaluation also discards all request quotes')
print('OUTPUT PRICE REQUEST MEMO: '..checks..' checks passed')
