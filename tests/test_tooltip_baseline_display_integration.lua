-- Deterministic presentation fixtures, not claims about any game's drop rates.
-- Complete baseline receipts must use the same layout as already complete rows.
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
GetBuildInfo=function()return '12.1.5','70961','',120105 end
local LL={db={tooltipDetail=3,tooltipOutputSort='database',source_reference_enabled=true,
 source_reference_weight=10,source_itemdb_enabled=true,source_itemdb_weight=81}}
for _,name in ipairs({'Database.lua','Badges.lua'})do
 assert(loadfile('LootLiquidator/'..name))('LL',LL)
end
LL.MarkupColor=function()return ''end
LL.CharacterKey=function()return 'Fixture - Realm'end
LL.Money=function(_,value)return value==0 and '0g' or ('%.4f fixture-copper'):format(value)end
LL.ProcessingMethodMode=function()return 1 end
local names={[101]='Alpha known',[102]='Beta estimated',[103]='Gamma locked',
 [104]='Delta no value',[105]='Epsilon tracked',[106]='Zeta source'}
C_Item={GetItemInfo=function(id)return names[id]end,GetItemIconByID=function(id)return id+1000 end}
local function signature(value)
 if type(value)~='table'then return type(value)..':'..tostring(value)end
 local keys={};for key in pairs(value)do keys[#keys+1]=key end
 table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
 local text={'{'}
 for _,key in ipairs(keys)do text[#text+1]=signature(key)..'='..signature(value[key])end
 text[#text+1]='}';return table.concat(text,';')
end
local function field(value)
 return {value=value,status=value==nil and 'unknown' or 'measured',confidence=value==nil and 0 or 80}
end
local function sourceMaterial(id,mean,chance,lo,hi)
 return {id=id,expectedQuantity=field(mean),dropChance=field(chance),minQuantity=field(lo),maxQuantity=field(hi)}
end
local expectedOrder={database={105,104,103,102,101,106},value={106,102,101,105,103,104},
 chance={101,104,103,102,105,106},quantity={106,102,101,105,104,103},name={101,102,104,105,103,106}}
local rendered,tracked=0,{}
for _,method in ipairs({'Disenchant','Mill','Prospect'})do
 local batch=method=='Disenchant'and 1 or 5
 local materials={
  {id=105,expectedQuantity=.75,netExpectedValue=75},
  {id=104,chance=.25,expectedQuantity=.25,minQuantity=1,maxQuantity=1,netExpectedValue=0},
  {id=103,chance=0,expectedQuantity=0,netExpectedValue=0,structuralZero=true,
   probabilityBasis='specialization-eligibility-zero'},
  {id=102,expectedQuantity=1,netExpectedValue=100},
  {id=101,chance=.4,expectedQuantity=.8,minQuantity=1,maxQuantity=3,netExpectedValue=80},
  {id=106,expectedQuantity=1.125,netExpectedValue=112.5},
 }
 for _,m in ipairs(materials)do m.confidence=80 end
 local record={recordID='tooltip-display-fixture:'..method,sourceKey='reference',method=method,
  inputItemID=900,inputCount=batch,fieldSpecificEvidence=true,materials={
   sourceMaterial(101,.8,.8,1,1),sourceMaterial(102,1,nil,1,3),sourceMaterial(106,1.125,.75,1,2)}}
 local wrongBatch={recordID='wrong-batch-display-fixture:'..method,sourceKey='reference',method=method,
  inputItemID=900,inputCount=batch+1,materials={sourceMaterial(105,.75,.5,1,2)}}
 LL._evidenceIndex={[method..':900']={record,wrongBatch}}
 local model={inputItemID=900,inputCount=batch,confidence=80,materials=materials}
 local letter=({Disenchant='D',Mill='M',Prospect='P'})[method]
 local option={name=method,letter=letter,available=true,value=367.5/batch,yieldModel=model,inputCount=batch}
 local facts={id=900,classID=7}
 local original=signature({model=model,record=record,wrongBatch=wrongBatch,option=option})
 for _,mode in ipairs({'database','value','chance','quantity','name'})do
  LL.db.tooltipOutputSort=mode
  local sorted=LL:SortedTooltipMaterials(materials)
  for i,id in ipairs(expectedOrder[mode])do assert(sorted[i].id==id,'Saved sorting order must be retained: '..mode)end
  for _,afterCut in ipairs({false,true})do for level=0,3 do
   LL.db.tooltipDetail=level;LL.db.tooltipShowAfterAHCut=afterCut
   local tip={lines={},rows={}}
   function tip:AddLine(text)self.lines[#self.lines+1]=text end
   function tip:AddDoubleLine(left,price)self.rows[#self.rows+1]={left,price}end
   LL:AppendRecommendationTooltip(tip,{action='V',facts=facts,rawAuction=200,netAuction=190,
    vendor=5,conversionOptions={option}})
   assert(#tip.lines==(level==0 and 0 or 1),'Off/Recommendation header contract')
   if level<2 then assert(#tip.rows==0,'Recommendation cannot append prices or materials')
   else
    assert(#tip.rows==(level==2 and 3 or 3+#materials),'Every actual output remains present at Breakdown')
    assert(tip.rows[1][1]=='Auction|r'and tip.rows[1][2]==LL:Money(afterCut and 190 or 200),
     'The AH-cut preference controls the existing auction row')
    assert(tip.rows[2][1]:find('(Confidence 0%)',1,true),
     'An unsupported display estimate has lowest header confidence while model confidence stays unchanged')
    assert(tip.rows[2][2]==LL:Money(option.value),'Restoring display fields cannot change method value')
    assert(tip.rows[#tip.rows][1]=='Vendor|r'and tip.rows[#tip.rows][2]==LL:Money(5))
    if level==3 then
     local byID={}
     local displayedOrder=mode=='chance'and{105,106,102,101,104,103}or expectedOrder[mode]
     for i,id in ipairs(displayedOrder)do
      local row=tip.rows[i+2];assert(row[1]:find(names[id],1,true),'Rendered sorting order: '..mode)
      byID[id]=row
      assert(row[1]:find('|T'..(id+1000)..':14:14:0:0|t ',1,true),'Every item keeps its icon')
     end
     for id,expected in pairs({[101]='40% ',[102]='50% ',[103]='0% ',[104]='25% ',[106]='75% '})do
      local left=byID[id][1]
      assert(left:find(expected,1,true)and not left:find('x ',1,true),
       'A known or baseline-completable receipt must use a percentage: '..id)
      local range=({[101]='[1-3]',[102]='[1-3]',[103]='[0]',[104]='[1]',[106]='[1-2]'})[id]
      assert(left:find(names[id]..' '..range,1,true),'The original complete-row range contract: '..id)
     end
     assert(byID[103][2]=='0g'and not byID[103][1]:find('(locked)',1,true),
      'Known-zero output displays its value without an extra lock label')
     assert(byID[104][2]=='0g'and byID[104][1]:find('25%',1,true),
      'A zero auction value does not establish a zero output')
     for _,m in ipairs(materials)do assert(byID[m.id][2]==LL:Money(m.netExpectedValue/batch),
      'No display completion, sorting or AH header preference may recalculate a material price')end
     assert(byID[105][1]:find('75% ',1,true)and byID[105][1]:find('Epsilon tracked [1]',1,true),
      'A missing baseline uses a lowest-confidence display copy rather than another row format')
    end
   end
   assert(signature({model=model,record=record,wrongBatch=wrongBatch,option=option})==original,
    'Rendering must leave every source field, selected mean, confidence and price unchanged')
   rendered=rendered+1
  end end
 end
 -- Neither another item's receipt nor a disabled source can complete this row.
 local wrongInput=LL:FormatTooltipMaterialRow(materials[4],model,option,{id=901,classID=7})
 assert(wrongInput:find('100% ',1,true)and not wrongInput:find('[1-3]',1,true))
 LL.db.source_reference_enabled=false
 local disabled=LL:FormatTooltipMaterialRow(materials[4],model,option,facts)
 assert(disabled:find('100% ',1,true)and not disabled:find('[1-3]',1,true),'Disabled sources stay disabled')
 LL.db.source_reference_enabled=true
 local estimated=LL:TooltipMaterialDisplayFields(materials[4],model,option,facts)
 assert(estimated~=materials[4]and estimated.chance==.5 and estimated.minQuantity==1 and estimated.maxQuantity==3,
  'Missing display fields are completed on a separate presentation copy')
 assert(estimated.tooltipFieldEvidence.chance.kind=='midpoint'
  and estimated.tooltipFieldEvidence.chance.confidence==40,
  'Existing midpoint inference retains its reduced confidence from the original 80 support')
 assert(estimated.tooltipFieldEvidence.minQuantity.confidence==80
  and estimated.tooltipFieldEvidence.maxQuantity.confidence==80,
  'Original baseline range confidence must survive display completion')
 local sourced=LL:TooltipMaterialDisplayFields(materials[6],model,option,facts)
 assert(sourced.chance==.75 and sourced.tooltipFieldEvidence.chance.confidence==80,
  'A retained source occurrence keeps its original confidence and beats inference')
 assert(signature({model=model,record=record,wrongBatch=wrongBatch,option=option})==original,
  'Public completion helper cannot mutate source, recommendation or price fields')
 tracked[#tracked+1]={method=method,id=105,reason='No enabled same-item same-batch baseline for this material'}
end
LL_TOOLTIP_BASELINE_DISPLAY_TRACKED=tracked
assert(#tracked==3,'Every deliberately incomplete case is explicitly tracked')
local scopeChecks=0
local function checkScope(changes,allowed,label,mechanicsApplied)
 local m={id=701,expectedQuantity=1,confidence=80,netExpectedValue=100}
 local model={inputCount=5,confidence=80,materials={m},mechanicsApplied=mechanicsApplied,
  context={skill=50,stats={craftingSpeed={percent=10}}}}
 local option={name='Mill',letter='M',recipeID=700,inputCount=5,yieldModel=model}
 local facts={id=901,classID=7,quality=1,reagentQuality=1,expansionID=9}
 local record={recordID='display-scope-fixture',sourceKey='reference',method='Mill',
  inputItemID=901,inputCount=5,expansionID=9,materials={sourceMaterial(701,1,nil,1,3)}}
 for key,value in pairs(changes)do record[key]=value end
 LL._evidenceIndex={['Mill:901']={record}}
 local original=signature({model=model,record=record,option=option,facts=facts})
 local display=LL:TooltipMaterialDisplayFields(m,model,option,facts)
 if allowed then assert(display.chance==.5 and display.minQuantity==1 and display.maxQuantity==3,label)
 else assert(display.chance==1 and display.minQuantity==1 and display.maxQuantity==1
  and display.tooltipFieldEvidence.chance.kind=='display-estimate'and display.chanceConfidence==0,label)end
 assert(signature({model=model,record=record,option=option,facts=facts})==original,
  'Source-scope checks must not mutate source/model/context fields')
 scopeChecks=scopeChecks+1
end
checkScope({},true,'An exact same-expansion receipt remains usable')
checkScope({expansionID=0},false,'Actual Classic expansion0 cannot supply a modern item baseline')
checkScope({expansionID=0,researchConditions={expansionIDKnown=false}},true,
 'The explicitly marked unknown-expansion sentinel may use its exact input mapping')
checkScope({expansionID=0,researchConditions={expansionIDKnown=true}},false,
 'A known expansion0 never acquires sentinel semantics')
checkScope({clientVersion='12.1.4'},false,'Different client versions stay isolated')
checkScope({clientVersion='12.1.5'},true,'Matching client version remains usable')
checkScope({targetBuild=70962},false,'Future target builds are excluded')
checkScope({targetBuild='70961'},true,'String build metadata matches the current build')
checkScope({patchStartBuild=70962},false,'Future patch start is excluded')
checkScope({patchStartBuild=70960},true,'A patch already active remains usable')
checkScope({minimumRecipeSkill=51},false,'A higher skill requirement cannot supply fields')
checkScope({minimumRecipeSkill=50},true,'The current skill can satisfy a baseline requirement')
checkScope({referenceConditions={skill=40}},false,'A mismatched source character context is excluded')
checkScope({referenceConditions={skill=50,stats={craftingSpeed={percent=10}}}},true,
 'Exact nested reference context remains usable')
checkScope({referenceConditions={stats={craftingSpeed={percent=20}}}},false,
 'Nested stat mismatches cannot supply display fields')
checkScope({mechanicsSourceBuild=70960},false,'Old unadjusted mechanics are excluded')
checkScope({mechanicsSourceBuild=70960},true,'An explicitly applied mechanics translation is recognized',true)
checkScope({unresolvedResearchConditions={'unresolved'}},false,'Unresolved source conditions remain excluded')
checkScope({researchConditions={eligibilityStatus='REQUIRES_SPECIALIZATION'}},false,
 'An unmet source unlock is not a current output distribution')
checkScope({recipeID=701},false,'A different operation receipt cannot supply display fields')
-- Owner's original missing-field rule applies to the selected bounds even
-- when no range needs restoring and the rejected raw probability stays held.
local current={id=101,expectedQuantity=.7,minQuantity=1,maxQuantity=1,confidence=80,netExpectedValue=70}
local currentModel={inputCount=1,confidence=80,materials={current}}
local currentOption={name='Disenchant',letter='D',inputCount=1,yieldModel=currentModel}
local currentFacts={id=902,classID=4,expansionID=9}
local rejected=sourceMaterial(101,.7,nil,1,1)
rejected.dropChance.inferenceBlocked=true;rejected.heldDropChance=field(.95)
local heldRecord={recordID='held-source-p-current-bounds',sourceKey='reference',method='Disenchant',
 inputItemID=902,inputCount=1,materials={rejected}}
LL._evidenceIndex={['Disenchant:902']={heldRecord}}
local original=signature({material=current,model=currentModel,source=heldRecord})
local display=LL:TooltipMaterialDisplayFields(current,currentModel,currentOption,currentFacts)
assert(display.chance==.7 and display.chanceConfidence==40 and display.tooltipFieldEvidence.chance.kind=='midpoint',
 'Known selected [1] and mean0.7 display the existing70% midpoint estimate at reduced confidence')
local left,price=LL:FormatTooltipMaterialRow(current,currentModel,currentOption,currentFacts)
assert(left:find('70% ',1,true)and left:find('Alpha known [1]',1,true)and price==LL:Money(70))
assert(current.chance==nil and rejected.dropChance.value==nil and rejected.dropChance.inferenceBlocked
 and rejected.heldDropChance.value==.95 and signature({material=current,model=currentModel,source=heldRecord})==original,
 'A display estimate never revives the held raw probability or writes to means/ranges/confidence/prices')
LL._evidenceIndex=nil
display=LL:TooltipMaterialDisplayFields(current,currentModel,currentOption,currentFacts)
assert(display.chance==.7 and display.chanceConfidence==40,'Known selected bounds do not require a second source-index entry')
for _,changes in ipairs({{expectedQuantity=2},{expectedQuantity=0},{minQuantity=2,maxQuantity=1},
 {minQuantity=0},{maxQuantity=math.huge}})do
 local invalid={};for key,value in pairs(current)do invalid[key]=value end
 for key,value in pairs(changes)do invalid[key]=value end
 local untouched=LL:TooltipMaterialDisplayFields(invalid,currentModel,currentOption,currentFacts)
 assert(untouched.chance>=0 and untouched.chance<=1 and untouched.chanceConfidence==0 and invalid.chance==nil,
  'Contradictory or zero-only presentation estimates stay lowest-confidence copies')
end
current.chance=.25
display=LL:TooltipMaterialDisplayFields(current,currentModel,currentOption,currentFacts)
assert(display==current and display.chance==.25,'An existing probability is never replaced by the midpoint rule')
local conditionalOnly={id=101,conditionalExpectedQuantity=.75,netUnitPrice=100,confidence=80}
local conditionalModel={inputCount=1,confidence=80,materials={conditionalOnly}}
local conditionalOption={name='Disenchant',letter='D',inputCount=1,yieldModel=conditionalModel}
local beforeConditional=signature({material=conditionalOnly,model=conditionalModel})
local pretty=LL:TooltipMaterialDisplayFields(conditionalOnly,conditionalModel,conditionalOption,currentFacts)
local conditionalLeft,conditionalPrice=LL:FormatTooltipMaterialRow(pretty,conditionalModel,conditionalOption,currentFacts)
assert(pretty.chance==.75 and pretty.minQuantity==1 and pretty.maxQuantity==1
 and conditionalLeft:find('75% ',1,true),'Conditional units may supply only a local presentation estimate')
assert(pretty.expectedQuantity==nil and pretty.netExpectedValue==nil and conditionalPrice=='',
 'A conditional display estimate cannot become an actual expected quantity or fabricated gold value, even with a real unit quote')
assert(signature({material=conditionalOnly,model=conditionalModel})==beforeConditional,
 'Preparing and formatting conditional estimates preserves every actual source/model/price field')
print(('PASS: %d baseline display renders and %d source-scope checks; approved rows, levels 0-3, sorting and AH cut; %d baseline-missing fixtures tracked; source/model/prices unchanged'):format(rendered,scopeChecks,#tracked))
