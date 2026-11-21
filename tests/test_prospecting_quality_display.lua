-- Same material name, different native quality IDs: keep every row and value.
local LL={db={tooltipDetail=3,showAverageQuantity=false},ItemDB={professionProfiles={items={}}}}
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
assert(loadfile('LootLiquidator/Badges.lua'))('LL',LL)
LL.MarkupColor=function()return ''end
LL.Money=function(_,n)return tostring(n)..' copper'end
LL.ProfessionProgression=function()return {}end
C_Item={GetItemInfo=function()return 'Flawless Amani Lapis'end}
local materials={}
for id=1,14 do
    LL.ItemDB.professionProfiles.items[id]={qualityRank=(id-1)%2+1,qualityFamilyID=100}
    materials[id]={id=id,expectedQuantity=id==14 and 0 or .2,netExpectedValue=id,confidence=30}
end
local model={inputCount=5,materials=materials,confidence=30,generalQualityApplied=true}
local tip={rows={}}
function tip:AddLine()end
function tip:AddDoubleLine(left,right)self.rows[#self.rows+1]={left,right}end
LL:AppendRecommendationTooltip(tip,{action='A',facts={id=999,classID=7},conversionOptions={{name='Prospect',
    inputCount=5,profession='Jewelcrafting',value=42,yieldModel=model}}})
local count,zero=0,false
for _,row in ipairs(tip.rows)do if row[1]:find('Flawless Amani Lapis',1,true)then
    count=count+1
    assert(not row[1]:find('[avg',1,true) and not row[1]:find('per prospect',1,true),row[1])
    assert(row[1]:find('20%%') or row[1]:find('0%%'),row[1])
    if row[1]:find('0%% Flawless',1,false)then zero=true end
end end
assert(count==14,'all separate quality rows remain visible beyond the old twelve-row cutoff')
assert(zero,'a numerical zero for a distinct quality remains visible')
for _,m in ipairs(materials)do assert(m.chance==nil,'presentation must not invent probability evidence')end
assert(materials[1].expectedQuantity==.2 and materials[1].netExpectedValue==1,'yield and valuation unchanged')
-- A measured grade does not erase a separate exact-grade reference merely
-- because their native family/name matches. Pooled family fallbacks stay separate.
GetBuildInfo=function()return '12.1.5','70961'end
assert(loadfile('LootLiquidator/Database.lua'))('LL',LL)
local function field(v,known)return {value=v,status=v and (known and 'measured' or 'provisional') or 'unknown',
    confidence=known and 80 or 10,sampleOperations=known and 100 or nil}end
local function source(id,grade,mean,known)
    return {recordID=id,studyID=id,sourceKey=known and 'itemdb' or 'reference',source=id,method='Prospect',
        inputItemID=999,inputCount=5,expansionID=11,patchBuild='70961',referenceContextID='fixture',referenceConditions={},
        samples=known and 100 or 0,sampleSizeKnown=known,fixedReference=not known,fallbackOnly=not known,
        materials={{id=grade,expectedQuantity=field(mean,known),dropChance=field(nil,known),
            minQuantity=field(nil,known),maxQuantity=field(nil,known)}}}
end
LL.ItemDB.schemaVersion=1;LL.ItemDB.processing={source('measured-rank1',1,.2,true),source('reference-rank2',2,.3,false)}
LL.ItemDB.legacy=nil;LL.LegacyDB=nil
LL:MigrateEvidenceSettings();assert(LL:InitializeItemDB(),LL.itemDBError)
local quote=assert(LL:ComputeEvidenceModel({id=999,expansionID=11},{name='Prospect',inputCount=5},nil,1,{}))
local byID={}for _,m in ipairs(quote.materials)do byID[m.id]=m.expectedQuantity end
assert(byID[1]==.2 and math.abs(byID[2]-.3)<1e-12,'both exact quality rows retain their own numerical baseline')
print('PASS: leading 20% without average suffix, fourteen separate quality rows, zero quality, immutable evidence/value')
