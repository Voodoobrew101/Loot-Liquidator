-- Formatting fixtures, not game-drop claims. All rows must survive missing fields.
local LL={db={tooltipDetail=3,tooltipOutputSort='database',tooltipHeaderPrice=true},
 ItemDB={professionProfiles={items={[1]={name='Crystal',qualityRank=1},[2]={name='Dust',qualityRank=2}}}}}
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
assert(loadfile('LootLiquidator/Badges.lua'))('LL',LL)
LL.MarkupColor=function()return ''end
LL.Money=function(_,n)return tostring(n)..' copper'end
LL.CharacterKey=function()return 'Fixture - Realm'end
C_Item={GetItemInfo=function(id)return ({[1]='Crystal',[2]='Dust',[98]='Missing icon'})[id]end,
 GetItemIconByID=function(id)if id==1 or id==2 then return 100+id end end}
local a={id=1,chance=.4,expectedQuantity=.4,minQuantity=1,maxQuantity=1,netExpectedValue=100}
local b={id=2,chance=.6,expectedQuantity=1.5,minQuantity=2,maxQuantity=3,netExpectedValue=150}
local mean={id=1,expectedQuantity=13.095,netExpectedValue=1309.5}
local zero={id=1,chance=0,expectedQuantity=0,minQuantity=0,maxQuantity=0,netExpectedValue=0,structuralZero=true}
local locked={id=2,chance=0,expectedQuantity=0,structuralZero=true,
 probabilityBasis='specialization-eligibility-zero'}
local unknown={id=98};local namePending={id=99,chance=.25,minQuantity=1,maxQuantity=1,netExpectedValue=25}
local conditional={id=2,chance=0/0,expectedQuantity=-1,conditionalExpectedQuantity=.75,
 minQuantity=-1,maxQuantity=math.huge,netExpectedValue=0/0}
local labels={Disenchant='Disenchant',Mill='Milling',Prospect='Prospecting',Smelt='Smelting',Craft='Craft/refine',
 Recycle='Recycle',Research='Research',Combine='Combine',Split='Split',Exchange='Exchange'}
local renders=0
for method,label in pairs(labels)do for _,stale in ipairs({false,true})do
 LL.db.tooltipHeaderPrice=stale
 local batch=method=='Disenchant'and 1 or 5
 local model={inputCount=batch,confidence=30,materials={a,b,mean,zero,unknown,namePending,conditional,locked},
  namedOutputs={{name='Named byproduct',expectedQuantity=.5},{name='Named discovery',discoveryFactor=2},{name='Named chance',chance=.5}}}
 local tip={lines={},rows={}}
 function tip:AddLine(t)self.lines[#self.lines+1]=t end
 function tip:AddDoubleLine(l,r)self.rows[#self.rows+1]={l,r}end
 LL:AppendRecommendationTooltip(tip,{action='D',fallback='V',converted=250/batch,facts={id=999,classID=7},
  deStats={total=999},conversionOptions={{name=method,letter='D',value=250/batch,available=true,yieldModel=model}}})
 assert(#tip.lines==1 and tip.lines[1]=='|cff66ccffLoot Liquidator:|r Disenchant|r')
 assert(#tip.rows==1+#model.materials,'Every actual material survives '..method)
 assert(tip.rows[1][1]==label..' — Fixture - Realm (Confidence 0%)|r')
 for _,row in ipairs(tip.rows)do
  assert(not row[1]:find('Named ',1,true)and not row[2]:find('Discovery',1,true),
   'Unidentified non-item extras must not use a separate tooltip layout')
 end
 assert(tip.rows[2][1]=='  40% |T101:14:14:0:0|t |cffb4d8ff[R1]|r Crystal [1]|r')
 assert(tip.rows[3][1]=='  60% |T102:14:14:0:0|t |cffb4d8ff[R2]|r Dust [2-3]|r')
 assert(tip.rows[2][2]==tostring(100/batch)..' copper'and tip.rows[3][2]==tostring(150/batch)..' copper')
 assert(tip.rows[4][1]:find('100% ',1,true)and tip.rows[4][1]:find('Crystal [13-14]',1,true),
  'A missing distribution gets only a local plausible display estimate')
 assert(tip.rows[5][1]:find('0% ',1,true)and tip.rows[5][1]:find('[0]',1,true)and tip.rows[5][2]=='0 copper')
 assert(tip.rows[6][1]:find('?% |T134400:',1,true)and tip.rows[6][1]:find('Missing icon [?]',1,true)and tip.rows[6][2]=='')
 assert(tip.rows[7][1]:find('Material 99',1,true))
 assert(tip.rows[8][1]:find('75% ',1,true)and tip.rows[8][1]:find('Dust [1]',1,true)and tip.rows[8][2]=='')
 assert(tip.rows[9][1]=='  0% |T102:14:14:0:0|t |cffb4d8ff[R2]|r Dust [0]|r'
  and tip.rows[9][2]=='0 copper','A proven specialization lock displays its zero range and value')
 assert(mean.chance==nil and mean.expectedQuantity==13.095 and a.chance==.4 and b.netExpectedValue==150)
 assert(locked.chance==0 and locked.expectedQuantity==0 and locked.minQuantity==nil
  and locked.maxQuantity==nil and locked.netExpectedValue==nil,'Eligibility-zero display never writes to the model')
 renders=renders+1
end end
local function copy(t)local o={}for k,v in pairs(t)do o[k]=v end return o end
local model={inputCount=1}
for level=0,3 do
 LL.db.tooltipDetail=level
 local tip={lines={},rows={}}
 function tip:AddLine(text)self.lines[#self.lines+1]=text end
 function tip:AddDoubleLine(left,price)self.rows[#self.rows+1]={left,price}end
 LL:AppendRecommendationTooltip(tip,{action='D',rawAuction=20,netAuction=19,vendor=5,facts={id=999,classID=7},
  conversionOptions={{name='Disenchant',letter='D',available=true,value=100,
   yieldModel={inputCount=1,confidence=30,materials={a,locked}}}}})
 assert(#tip.lines==(level==0 and 0 or 1),'Off and Recommendation contain only their intended action header')
 if level<=1 then assert(#tip.rows==0,'Recommendation must not append alternatives, materials or prices')
 else
  assert(#tip.rows==(level==2 and 3 or 5),'Alternatives show method prices; Full also shows every output')
  assert(tip.rows[1][1]=='Auction|r'and tip.rows[1][2]=='19 copper')
  assert(tip.rows[2][1]=='Disenchant — Fixture - Realm (Confidence 30%)|r'and tip.rows[2][2]=='100 copper')
  assert(tip.rows[#tip.rows][1]=='Vendor|r'and tip.rows[#tip.rows][2]=='5 copper')
  if level==3 then assert(tip.rows[4][1]:find('Dust [0]',1,true)and tip.rows[4][2]=='0 copper')end
 end
end
LL.db.tooltipDetail=3
local lockedLeft,lockedPrice=LL:FormatTooltipMaterialRow(locked,model)
assert(lockedLeft:find('0% ',1,true)and lockedLeft:find('Dust [0]',1,true)and lockedPrice=='0 copper')
local noChance=copy(locked);noChance.chance=nil
local noChanceLeft,noChancePrice=LL:FormatTooltipMaterialRow(noChance,model)
assert(noChanceLeft==lockedLeft and noChancePrice==lockedPrice and noChance.chance==nil,
 'The explicit eligibility proof supplies the display zero without changing absent source fields')
for _,changes in ipairs({{structuralZero=false},{probabilityBasis='sampled-zero'},{structuralZero='true'}})do
 local unproven=copy(locked)
 for key,value in pairs(changes)do unproven[key]=value end
 local left,price=LL:FormatTooltipMaterialRow(unproven,model)
 assert(left:find('0% ',1,true)and left:find('[0]',1,true)and price=='0 copper',
  'An actual zero expected quantity contributes zero gold without needing a quote or eligibility marker')
end
for _,missing in ipairs({'structuralZero','probabilityBasis'})do
 local unproven=copy(locked);unproven[missing]=nil
 local left,price=LL:FormatTooltipMaterialRow(unproven,model)
 assert(left:find('0% ',1,true)and left:find('[0]',1,true)and price=='0 copper',
  'Missing eligibility markers do not change the arithmetic value of an actual zero mean')
end
local unpriced=copy(a);unpriced.netExpectedValue=0
local unpricedLeft,unpricedPrice=LL:FormatTooltipMaterialRow(unpriced,model)
assert(unpricedLeft:find('40% ',1,true)and unpricedLeft:find('Crystal [1]',1,true)
 and unpricedPrice=='0 copper'and unpriced.chance==.4,'Zero market value does not mean zero drop chance')
local sampledZero=copy(a);sampledZero.chance=0;sampledZero.expectedQuantity=0;sampledZero.netExpectedValue=0
local sampledLeft,sampledPrice=LL:FormatTooltipMaterialRow(sampledZero,model)
assert(sampledLeft:find('0% ',1,true)and sampledLeft:find('Crystal [1]',1,true)and sampledPrice=='0 copper',
 'A sampled zero preserves its recorded conditional range')
local meanZero={id=1,expectedQuantity=0,netExpectedValue=0}
local meanLeft,meanPrice=LL:FormatTooltipMaterialRow(meanZero,model)
assert(meanLeft:find('0% ',1,true)and meanLeft:find('[0]',1,true)and meanPrice=='0 copper'
 and meanZero.chance==nil and meanZero.minQuantity==nil,'A local zero display never writes an eligibility proof into the model')
for _,changes in ipairs({{chance=0/0},{chance=math.huge},{chance=-.1},{chance=1.1},{chance=0},
 {minQuantity=-1},{minQuantity=.5},{minQuantity=2,maxQuantity=1},{maxQuantity=math.huge},{maxQuantity=1e20},
 {netExpectedValue=-1},{netExpectedValue=0/0},{id=0},{id=math.huge},{inconsistentFields=true}})do
 local m=copy(a);for k,v in pairs(changes)do m[k]=v end
 local l,r=LL:FormatTooltipMaterialRow(m,model)
 assert(type(l)=='string'and type(r)=='string','Invalid fields must not hide the material')
end
local conflict=copy(a);conflict.inconsistentFields=true
local l,r=LL:FormatTooltipMaterialRow(conflict,model)
assert(l:find('40%',1,true)and l:find('[1]',1,true)and r=='100 copper',
 'A disagreement with the selected mean must not erase a retained source range')
for _,original in ipairs({a,b,zero})do
 local flagged=copy(original);flagged.inconsistentFields=true
 local baselineLeft,baselinePrice=LL:FormatTooltipMaterialRow(original,model)
 local flaggedLeft,flaggedPrice=LL:FormatTooltipMaterialRow(flagged,model)
 assert(flaggedLeft==baselineLeft and flaggedPrice==baselinePrice,
  'Retained ranges, zero rows, percentages, icons, names and prices must survive the conflict flag')
end
conflict=copy(b);conflict.expectedQuantity=2;conflict.netExpectedValue=200;conflict.inconsistentFields=true
l,r=LL:FormatTooltipMaterialRow(conflict,model)
assert(l:find('60%',1,true)and l:find('Dust [2-3]',1,true)and r=='200 copper')
assert(conflict.chance==.6 and conflict.expectedQuantity==2 and conflict.minQuantity==2
 and conflict.maxQuantity==3 and conflict.netExpectedValue==200 and conflict.inconsistentFields==true,
 'Displaying an inconsistent source range must not alter the selected model or price')
for _,changes in ipairs({{minQuantity=-1},{minQuantity=.5},{minQuantity=2,maxQuantity=1},
 {minQuantity=0/0},{maxQuantity=math.huge},{maxQuantity=1e20}})do
 local invalid=copy(a);invalid.inconsistentFields=true
 for key,value in pairs(changes)do invalid[key]=value end
 l,r=LL:FormatTooltipMaterialRow(invalid,model)
 assert(l:find('40%',1,true)and l:find('Crystal',1,true)and l:match(' %[[%d%-]+%]')
  and r=='100 copper','Invalid display bounds are repaired locally without changing the known probability or price')
end
LL.MarkupColor=function(_,letter)assert(letter=='M');return '|cffc0ffee'end
l=assert(LL:FormatTooltipMaterialRow(a,model,{letter='M'}));assert(l:find('Crystal|cffc0ffee [1]',1,true))
LL.MarkupColor=function()return ''end
model.inputCount=0;l,r=LL:FormatTooltipMaterialRow(a,model);assert(l and r=='');model.inputCount=1
local pooled=copy(a);pooled.rankIDs={1,2};l=assert(LL:FormatTooltipMaterialRow(pooled,model));assert(not l:find('[R1]',1,true))
C_Item.GetItemIconByID=function()end;C_Item.GetItemInfoInstant=function(id)return id,'Fixture','Fixture','',456 end
l=assert(LL:FormatTooltipMaterialRow(a,model));assert(l:find('|T456:',1,true))
LL.Money=function()error('price loading')end;l,r=LL:FormatTooltipMaterialRow(a,model);assert(l and r=='')
assert(LL:FormatTooltipMaterialRow(nil,model)==nil)
print(('PASS: %d all-method tooltips retain every actual material, zero and known field; non-item extras have no alternate layout'):format(renders))
