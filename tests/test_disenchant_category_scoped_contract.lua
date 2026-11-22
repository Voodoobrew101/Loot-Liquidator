-- Deterministic scope fixtures, not game-drop estimates. Exercise the real
-- selector/cache, category-only display completion, gold, and class19 boundary.
local checks=0
local function check(value,label)checks=checks+1;assert(value,label)end
local function near(a,b,label)check(type(a)=='number'and math.abs(a-b)<1e-9,label..': '..tostring(a))end
local function copy(t)local r={}for k,v in pairs(t)do r[k]=v end return r end
GetTime=function()return 1 end
GetBuildInfo=function()return '12.1.5','70961','',120105 end
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
SlashCmdList={}
local LL={db={source_itemdb_enabled=true,source_itemdb_weight=100,source_legacy_enabled=false,
    source_reference_enabled=false,source_personal_enabled=false,source_imported_enabled=false}}
for _,name in ipairs({'Database.lua','Core.lua','Badges.lua'})do
    assert(loadfile('LootLiquidator/'..name))('LL',LL)
end
LL.MarkupColor=function()return ''end
LL.Money=function(_,value)return tostring(value)..' actual-copper'end
LL.ProcessingMethodMode=function()return 1 end
C_Item={GetItemInfo=function()return 'Fixture Material'end,GetItemIconByID=function()return 123 end}
local function field(value)return{value=value,status='measured',confidence=80,samples=10}end
local function record(id,exp,quality,class,lo,hi,mean,p,min,max)
    return{recordID=id,studyID=id,source='Fixture source',sourceKey='itemdb',method='Disenchant',recipeID=13262,
        inputCount=1,expansionID=exp,inputRarity=quality,inputClassID=class,isDisenchantCategory=true,
        gearKey='gear:'..exp..':'..quality..':'..(class==19 and 'profession'or class==2 and 'weapon'or 'armor'),
        categoryItemLevelMin=lo,categoryItemLevelMax=hi,materials={{id=100,expectedQuantity=field(mean),
        dropChance=field(p),minQuantity=field(min),maxQuantity=field(max)}}}
end
local low=record('low-band',0,2,4,1,8,1,.5,1,3)
local high=record('high-band',0,2,4,9,12,3,1,3,3)
local robe=record('profession-gear',10,2,19,1,999,303/108,1,2,4)
local armor=record('ordinary-armor',10,2,4,1,999,9,1,9,9)
local function install(rows)
    LL.ItemDB={schemaVersion=1,version='category-scope-fixture',processing=rows,mechanicRules={},
        professionProfiles={items={}}}
    LL.LegacyDB=nil
    check(LL:InitializeItemDB(),LL.itemDBError)
end
local option={name='Disenchant',letter='D',recipeID=13262,inputCount=1}
local facts={id=999001,expansionID=0,quality=2,classID=4,itemLevel=5}
install({low,high})
near(assert(LL:ResolveEvidenceModel(facts,option,nil,1)).materials[1].expectedQuantity,1,'low band selected')
facts.itemLevel=10
near(assert(LL:ComputeEvidenceModel(facts,option,nil,1,{},true)).materials[1].expectedQuantity,3,'direct high band selected')
near(assert(LL:ResolveEvidenceModel(facts,option,nil,1)).materials[1].expectedQuantity,3,
    'same item ID changing level cannot reuse cached low-band mean')
facts.itemLevel=5
near(assert(LL:ResolveEvidenceModel(facts,option,nil,1)).materials[1].expectedQuantity,1,'return to lower band isolated')
facts.itemLevel=nil
check(LL:ResolveEvidenceModel(facts,option,nil,1)==nil,'unknown level cannot satisfy narrow legacy bands')
facts.itemLevel=10
near(assert(LL:ResolveEvidenceModel(facts,option,nil,1)).materials[1].expectedQuantity,3,'unknown-level miss does not poison known level')
for _,level in ipairs({1,8,9,12})do
    facts.itemLevel=level
    near(assert(LL:ComputeEvidenceModel(facts,option,nil,1,{},true)).materials[1].expectedQuantity,
        level<=8 and 1 or 3,'inclusive native band boundary')
end
for _,level in ipairs({0,13})do
    facts.itemLevel=level
    check(LL:ComputeEvidenceModel(facts,option,nil,1,{},true)==nil,'outside both native bands excluded')
end
-- The formatter recovers only presentation fields from a category receipt.
facts.itemLevel=5
local material={id=100,expectedQuantity=1,netExpectedValue=125,netUnitPrice=100,confidence=95}
local model={inputCount=1,confidence=95,context={}}
local shown=LL:TooltipMaterialDisplayFields(material,model,option,facts)
near(shown.chance,.5,'category occurrence restored without exact item record')
check(shown.minQuantity==1 and shown.maxQuantity==3,'category positive range restored')
check(shown.tooltipFieldEvidence.chance.recordID=='low-band','restored occurrence cites actual category study')
check(shown.tooltipFieldEvidence.minQuantity.recordID=='low-band','range cites matching native band only')
local left,gold=LL:FormatTooltipMaterialRow(material,model,option,facts)
check(left:find('50%',1,true)and left:find('[1-3]',1,true),'category receipt rendered in required material format')
check(gold=='125 actual-copper','existing actual net quote wins over presentation fields')
local unquoted=copy(material);unquoted.netExpectedValue=nil
local _,fallbackGold=LL:FormatTooltipMaterialRow(unquoted,model,option,facts)
check(fallbackGold=='100 actual-copper','gold fallback uses original mean times actual net unit quote')
check(material.chance==nil and material.minQuantity==nil and material.maxQuantity==nil
    and material.expectedQuantity==1 and material.netExpectedValue==125 and model.confidence==95,
    'display completion mutates neither actual valuation nor source confidence')
facts.itemLevel=10
shown=LL:TooltipMaterialDisplayFields(material,model,option,facts)
check(shown.minQuantity==3 and shown.maxQuantity==3
    and shown.tooltipFieldEvidence.minQuantity.recordID=='high-band','formatter honors changed input band')
facts.itemLevel=nil
shown=LL:TooltipMaterialDisplayFields(material,model,option,facts)
check(shown.tooltipFieldEvidence.minQuantity.kind=='display-estimate','unknown legacy level cannot borrow category bounds')
facts.itemLevel=5
LL.db.source_itemdb_enabled=false
shown=LL:TooltipMaterialDisplayFields(material,model,option,facts)
check(shown.tooltipFieldEvidence.minQuantity.kind=='display-estimate','disabled source cannot supply recovered display range')
LL.db.source_itemdb_enabled=true
-- A context-gated receipt cannot be revived by the presentation helper.
local gated=record('gated',0,2,4,1,8,1,.5,1,3);gated.referenceConditions={buffed=true}
install({gated})
shown=LL:TooltipMaterialDisplayFields(material,model,option,facts)
check(shown.tooltipFieldEvidence.minQuantity.kind=='display-estimate','wrong buff context cannot supply range')
model.context={buffed=true}
shown=LL:TooltipMaterialDisplayFields(material,model,option,facts)
check(shown.tooltipFieldEvidence.minQuantity.recordID=='gated','matching recorded buff context enables source range')
local _,buffGold=LL:FormatTooltipMaterialRow(material,model,option,facts)
check(buffGold=='125 actual-copper','display buff context does not change original net gold')
-- Native profession equipment has its own category, never ordinary armor.
install({robe,armor})
local professionFacts={id=222845,expansionID=10,quality=2,classID=19,itemLevel=486,
    equipLoc='INVTYPE_PROFESSION_BODY',context={},bindType=2}
check(LL:DisenchantCategoryKey(professionFacts)=='gear:10:2:profession','native class19 has distinct category identity')
check(LL:EligibleDisenchant(professionFacts),'valid native class19 equipment is eligible')
near(assert(LL:ResolveEvidenceModel(professionFacts,option,nil,1)).materials[1].expectedQuantity,
    303/108,'profession category preserves actual pooled 303/108 source mean')
local armorFacts=copy(professionFacts);armorFacts.classID=4
near(assert(LL:ResolveEvidenceModel(armorFacts,option,nil,1)).materials[1].expectedQuantity,9,'armor does not receive profession-gear rate')
professionFacts.itemLevel=nil
near(assert(LL:ResolveEvidenceModel(professionFacts,option,nil,1)).materials[1].expectedQuantity,
    303/108,'universal 1-999 native category does not require known level')
check(not LL:EligibleDisenchant({id=999002,classID=7,quality=2,expansionID=10,
    equipLoc='INVTYPE_PROFESSION_BODY',context={}}),'class19 support never admits material items')
print('DISENCHANT CATEGORY SCOPED CONTRACT: '..checks..' checks passed')
