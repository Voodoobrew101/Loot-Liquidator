local LL={db={tooltipDetail=3},ItemDB={professionProfiles={items={}}}}
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
assert(loadfile('LootLiquidator/Badges.lua'))('LL',LL)
LL.MarkupColor=function()return ''end
LL.Money=function(_,v)return tostring(v)..' copper'end
LL.ProfessionProgression=function()return {}end
C_Item={GetItemInfo=function()return 'Pigment'end}
local materials={}
for id=1,14 do
    LL.ItemDB.professionProfiles.items[id]={qualityRank=(id-1)%2+1,qualityFamilyID=100}
    materials[id]={id=id,expectedQuantity=id==14 and 0 or id==2 and 13.095 or .2,netExpectedValue=id}
end
local model={inputCount=10,materials=materials,confidence=30,generalQualityApplied=true}
local function render(show)
    LL.db.showAverageQuantity=show
    local tip={rows={}}
    function tip:AddLine()end
    function tip:AddDoubleLine(a,b)self.rows[#self.rows+1]=a..' | '..b end
    LL:AppendRecommendationTooltip(tip,{action='A',facts={id=999,classID=7},conversionOptions={{name='Mill',
        inputCount=model.inputCount,profession='Inscription',yieldModel=model,value=42}}})
    return table.concat(tip.rows,'\n')
end
for _,show in ipairs({false,true})do
    local text=render(show)
    local _,count=text:gsub('Pigment','')
    assert(count==14 and text:find('20%% Pigment') and text:find('13.095x Pigment',1,true) and text:find('0%% Pigment'),text)
    assert(not text:find('[avg',1,true) and not text:find('per 10',1,true),'no trailing milling average text')
end
for _,m in ipairs(materials)do assert(m.chance==nil,'display does not invent probability observations')end
assert(materials[1].expectedQuantity==.2 and materials[2].expectedQuantity==13.095 and materials[1].netExpectedValue==1)
model.operationUnverified=true;model.inputCount=1
assert(render(false):find('[avg 0.200 per 1 input]',1,true),'unverified per-input source keeps its original denominator')
print('PASS: milling leading rates/counts, fourteen separate quality rows, zeros, unchanged evidence/value and per-input references')
