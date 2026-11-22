-- Numerical fixtures, not game-drop claims. Native metadata hydration must
-- invalidate cached output policy while prices remain request-local and fresh.
local checks=0
local function check(value,label)checks=checks+1;assert(value,label)end
local now=100
GetTime=function()return now end
GetBuildInfo=function()return '12.1.5','70961'end
local LL={db={source_itemdb_enabled=true,source_itemdb_weight=100,source_legacy_enabled=false,
    source_reference_enabled=false,source_personal_enabled=false,source_imported_enabled=false}}
for _,file in ipairs({'ProfessionCalculations.lua','Database.lua','ConversionEngine.lua'})do
    assert(loadfile('LootLiquidator/'..file))('LL',LL)
end
LL.ProfessionForMethod=function()return 'Enchanting'end
local context={profession='Enchanting',expansionID=9,character='Actual',skill=20,effectiveSkill=20,
    specializationPoints={[1]=1},_cacheKey='actual:unchanged',_cacheIdentity=1}
LL.ProcessingPlayerConditions=function()return context end
local function field(v)return{value=v,status='measured',confidence=100,samples=100}end
local source={recordID='binding-source',studyID='binding-source',source='Test measurement',sourceKey='itemdb',
    method='Disenchant',recipeID=13262,inputCount=1,expansionID=9,inputRarity=4,inputClassID=4,
    gearKey='gear:9:4:armor',isDisenchantCategory=true,categoryItemLevelMin=1,categoryItemLevelMax=999,
    baselineProfile={skill=0,specializationPoints={[1]=0}},materials={{id=100,
        expectedQuantity=field(1),dropChance=field(1),minQuantity=field(1),maxQuantity=field(1)}}}
local effect={metric='extraOutput',amount=1,unit='quantity',confidence=100,outputItemIDs={100},
    scope={profession='Enchanting',expansionID=9,method='Disenchant'}}
local data={items={[100]={}},recipes={},professionParameters={},
    profiles={['Enchanting:9']={nodes={[1]={maxRank=1,pointEffects={effect}}}}}}
LL.ItemDB={schemaVersion=1,version='binding-test',processing={source},professionProfiles=data,mechanicRules={}}
assert(LL:InitializeItemDB(),LL.itemDBError)
local computations=0
local compute=LL.ComputeEvidenceModel
LL.ComputeEvidenceModel=function(self,...)computations=computations+1;return compute(self,...)end
local price=100
LL.GetOutputPrice=function()return price end
LL.AHFeeRate=function()return 0 end
local facts={id=999001,quality=4,classID=4,expansionID=9,itemLevel=441}
local option={name='Disenchant',recipeID=13262,inputCount=1}
local first=assert(LL:ResolveEvidenceModel(facts,option,nil,1))
check(first.materials[1].expectedQuantity==2,'unknown binding keeps the original numerical transform')
check(LL:ResolveEvidenceModel(facts,option,nil,1)==first and computations==1,
    'unchanged native output metadata retains the final-model hit')
check(LL:ValueProcessingModel(first,0,true)==200,'initial valuation uses the actual mean and price')
price=250
check(LL:ValueProcessingModel(LL:ResolveEvidenceModel(facts,option,nil,1),0,true)==500 and computations==1,
    'price changes remain fresh without invalidating numerical models')
data.items[100]={bindType=1};price=50
local hydrated=assert(LL:ResolveEvidenceModel(facts,option,nil,1))
check(hydrated~=first and computations==2,'unknown-to-hydrated native pointer invalidates the model')
check(hydrated.materials[1].expectedQuantity==1 and LL:ValueProcessingModel(hydrated,0,true)==50,
    'hydrated nontradable policy matches fresh computation and fresh price')
local fresh=assert(LL:ComputeEvidenceModel(facts,option,nil,1,context,true))
check(fresh.materials[1].expectedQuantity==hydrated.materials[1].expectedQuantity,
    'cached resolution agrees with the uncached actual projection after hydration')
check(source.materials[1].expectedQuantity.value==1 and source.materials[1].economicPolicy==nil,
    'hydration never mutates original source quantities or economic policy')
check(first.materials[1].expectedQuantity==2,'recomputation never rewrites the previous public model')

-- Isolate the cache reader contract, including models without material arrays.
local cacheLL={db={},ItemDB={schemaVersion=1,version='cache-reader',processing={},
    professionProfiles={items={}}}}
assert(loadfile('LootLiquidator/Database.lua'))('LL',cacheLL)
cacheLL.ProcessingPlayerConditions=function()return context end
cacheLL.GetNativeProfessionItem=function()error('cache guards must not hydrate through native APIs')end
local rows,groups,returnNil,missingMaterials={},nil,false,false
local calls=0
cacheLL.ComputeEvidenceModel=function()
    calls=calls+1
    if returnNil then return nil,'no evidence' end
    return{materials=not missingMaterials and rows or nil,groupedSourceQuantities=groups},'fixture'
end
local function resolve()return cacheLL:ResolveEvidenceModel(facts,option,nil,1)end
local items=cacheLL.ItemDB.professionProfiles.items
local function reset(materials,grouped)
    cacheLL._processingModelCache=nil;rows=materials or {};groups=grouped
    returnNil=false;missingMaterials=false
end
local function invalidates(change,label)
    local before=assert(resolve());local count=calls
    change()
    check(resolve()~=before and calls==count+1,label)
    local current=resolve();count=calls
    check(resolve()==current and calls==count,label..' then hits with unchanged metadata')
end
reset({{id=100,expectedQuantity=1}})
items[100]={bindType=0,bonding=0,itemBinding=0,qualityFamilyID=1,qualityRank=1}
for _,name in ipairs({'bindType','bonding','itemBinding','qualityFamilyID','qualityRank'})do
    invalidates(function()items[100][name]=items[100][name]+1 end,
        'in-place '..name..' change invalidates final policy/family state')
end
invalidates(function()
    local old=items[100];items[100]={bindType=old.bindType,bonding=old.bonding,
        itemBinding=old.itemBinding,qualityFamilyID=old.qualityFamilyID,qualityRank=old.qualityRank}
end,'native item replacement invalidates even with identical scalar metadata')
reset({{id=100,rankIDs={},expectedQuantity=1}})
invalidates(function()items[100].bonding=99 end,'empty rank arrays still guard the exact output ID')
reset({{id=100,rankIDs={100,101},expectedQuantity=1}})
invalidates(function()items[101]={bindType=1,qualityFamilyID=1,qualityRank=2}end,
    'hydrating an alternate output rank invalidates the whole pooled material')
invalidates(function()items[101].qualityRank=3 end,'alternate rank identity changes invalidate')
reset({{id=100,expectedQuantity=1}},{{outputItemIDs={102,103}}})
invalidates(function()items[103]={qualityFamilyID=2,qualityRank=1}end,
    'group-only observed output family identity is guarded')
reset({{id=104,expectedQuantity=1}})
items['104']={bindType=0}
invalidates(function()items['104'].itemBinding=1 end,'string-keyed native output records are guarded')
reset({{id=105,expectedQuantity=1}})
invalidates(function()items[105]={bindType=0}end,'previously absent native output records are guarded')
reset();returnNil=true
local nilModel,reason=resolve();local count=calls
local cachedNil,cachedReason=resolve()
check(nilModel==nil and cachedNil==nil and reason=='no evidence' and cachedReason==reason and calls==count,
    'nil models and reasons remain safely cacheable')
reset();missingMaterials=true
local noMaterials=resolve();count=calls
check(resolve()==noMaterials and calls==count,'models without material arrays remain safely cacheable')
reset({{id=100,expectedQuantity=1}})
now=100;local timed=resolve();count=calls
now=129
check(resolve()==timed and calls==count,'metadata guard preserves the existing thirty-second TTL')
now=130
check(resolve()~=timed and calls==count+1,'the existing TTL expiry still recomputes')
check(rows[1].expectedQuantity==1 and rows[1].netExpectedValue==nil,
    'binding snapshots never add price or cache metadata to material inputs')
print('FINAL MODEL BINDING CACHE: '..checks..' checks passed')
