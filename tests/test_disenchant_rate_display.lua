local LL={db={tooltipDetail=3},ItemDB={professionProfiles={items={}}}}
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
assert(loadfile('LootLiquidator/Badges.lua'))('LL',LL)
LL.MarkupColor=function()return ''end
LL.Money=function(_,v)return tostring(v)..' copper'end
LL.ProfessionProgression=function()return {}end
C_Item={GetItemInfo=function(id)return id==99 and 'Locked bonus' or 'Crystal'end}
local materials={}
for id=1,14 do
    LL.ItemDB.professionProfiles.items[id]={qualityRank=(id-1)%2+1,qualityFamilyID=100}
    materials[id]={id=id,expectedQuantity=id==14 and 0 or id==2 and 1.25 or .2,netExpectedValue=id}
end
LL.ItemDB.professionProfiles.items[99]={qualityRank=1,qualityFamilyID=200}
materials[#materials+1]={id=99,expectedQuantity=0,additionalOutput=true}
local model={inputCount=1,materials=materials,confidence=30,disenchantBaselineApplied=true}
for _,show in ipairs({false,true})do
    LL.db.showAverageQuantity=show
    local tip={rows={}}
    function tip:AddLine()end
    function tip:AddDoubleLine(a,b)self.rows[#self.rows+1]=a..' | '..b end
    LL:AppendRecommendationTooltip(tip,{action='D',facts={id=999,classID=4},disenchantEligible=true,
        conversionOptions={{name='Disenchant',letter='D',inputCount=1,profession='Enchanting',yieldModel=model,value=42}}})
    local text=table.concat(tip.rows,'\n');local _,count=text:gsub('Crystal','')
    assert(count==14 and text:find('20%% Crystal') and text:find('1.250x Crystal',1,true) and text:find('0%% Crystal'),text)
    assert(not text:find('[avg',1,true) and not text:find('Locked bonus',1,true),'no average suffix or locked unrelated bonus')
end
for _,m in ipairs(materials)do assert(m.chance==nil,'display does not fabricate occurrence evidence')end
assert(materials[1].expectedQuantity==.2 and materials[1].netExpectedValue==1,'baseline/valuation unchanged')
print('PASS: disenchant leading rates/counts, fourteen separate quality rows, zero sibling, hidden locked bonus and unchanged evidence/value')
