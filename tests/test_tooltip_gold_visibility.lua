-- Fixture quotes prove that presentation estimates cannot become valuation data.
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
local LL={db={tooltipDetail=3,tooltipOutputSort='database'}}
for _,name in ipairs({'Database.lua','Badges.lua'})do
 assert(loadfile('LootLiquidator/'..name))('LL',LL)
end
LL.MarkupColor=function()return ''end
LL.Money=function(_,value)return ('%.8g copper'):format(value)end
LL.CharacterKey=function()return 'Fixture - Realm'end
C_Item={GetItemInfo=function()return 'Fixture output'end,GetItemIconByID=function()return 123 end}
local calls=0
LL.GetMaterialPrice=function(_,m)
 calls=calls+1
 return m.id==2 and 95 or nil
end
local model={inputCount=5,confidence=80}
local option={name='Prospect',letter='P',inputCount=5}
local function same(a,b)return a==b or type(a)=='number'and type(b)=='number'and a~=a and b~=b end
local function check(material,expected)
 local original={};for key,value in pairs(material)do original[key]=value end
 local prepared=LL:TooltipMaterialDisplayFields(material,model,option)
 local left,price=LL:FormatTooltipMaterialRow(prepared,model,option)
 assert(left:find('%%')and left:find('%['),'Every case keeps the shared material format')
 assert(price==expected,'Expected '..expected..', got '..price)
 for key,value in pairs(original)do assert(same(material[key],value),'Rendering changed original '..key)end
 for key,value in pairs(material)do assert(same(original[key],value),'Rendering added original '..key)end
 return prepared
end
check({id=1,expectedQuantity=.104,netUnitPrice=100,netExpectedValue=145.6},'29.12 copper')
local display=check({id=1,expectedQuantity=.104,netUnitPrice=100},'2.08 copper')
assert(display.chance==.104 and display.minQuantity==1 and display.maxQuantity==1,
 'The displayed10.4%/[1] is separate from the actual.104 units used for gold')
check({id=2,expectedQuantity=2,unitPrice=999,expectedValue=999},'38 copper')
assert(calls==1,'Only an actual unvalued mean requests a missing net quote')
check({id=3,expectedQuantity=0},'0 copper')
assert(calls==1,'A real zero quantity needs no invented market quote')
local conditional=check({id=1,conditionalExpectedQuantity=.75,netUnitPrice=100},'')
assert(conditional.expectedQuantity==nil and conditional.netExpectedValue==nil,
 'A conditional display mean stays outside actual valuation')
check({id=1,chance=.5,minQuantity=1,maxQuantity=3,netUnitPrice=100},'')
check({id=3,expectedQuantity=2,unitPrice=999,expectedValue=999},'')
check({id=1,expectedQuantity=0/0,netUnitPrice=100},'')
check({id=1,expectedQuantity=-1,netUnitPrice=100},'')
check({id=1,expectedQuantity=math.huge,netUnitPrice=100},'')
assert(calls==2,'Unknown means and gross aliases cannot trigger fabricated values')
check({id=1,expectedQuantity=2,netUnitPrice=0},'0 copper')
local function vendorRows(facts,level,token)
 LL.db.tooltipDetail=level
 local tip={lines={},rows={}}
 function tip:AddLine(text)self.lines[#self.lines+1]=text end
 function tip:AddDoubleLine(left,price)self.rows[#self.rows+1]={left,price}end
 if token then LL.TokenClassSummary=function()return{}end end
 LL:AppendRecommendationTooltip(tip,{action='V',vendor=0,facts=facts,tokenInfo=token})
 return tip
end
for _,level in ipairs({0,1,2,3})do
 local tip=vendorRows({id=9,vendor=0,itemInfoPending=false},level)
 assert(#tip.rows==(level>=2 and 1 or 0),'Known zero honors existing detail settings')
 if level>=2 then assert(tip.rows[1][1]=='Vendor|r'and tip.rows[1][2]=='0 copper')end
end
assert(#vendorRows({id=9,vendor=0,itemInfoPending=true},3).rows==0,
 'Missing asynchronous item info cannot masquerade as a known zero price')
assert(#vendorRows({id=9,vendor=0,itemInfoPending=true,itemInfoFromSnapshot=true},3).rows==1,
 'A verified same-item snapshot preserves a known zero vendor quote')
assert(#vendorRows(nil,3).rows==1,'An explicit zero decision remains a valid quote')
local tokenTip=vendorRows({id=9,vendor=0,itemInfoPending=false},3,{})
assert(#tokenTip.rows==1 and tokenTip.rows[1][2]=='0 copper','Token vendor0 uses the same readiness guard')
print('PASS: actual means/net quotes recover missing row gold; display estimates and gross aliases never price rows; known vendor0 respects readiness and settings')
