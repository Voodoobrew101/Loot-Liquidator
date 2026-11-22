local LL={db={tooltipDetail=3},ItemDB={professionProfiles={items={}}}}
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
assert(loadfile('LootLiquidator/Badges.lua'))('LL',LL)
LL.MarkupColor=function()return ''end
LL.Money=function(_,v)return tostring(v)..' copper'end
C_Item={GetItemInfo=function(id)return id==99 and 'Locked bonus' or 'Crystal'end,GetItemIconByID=function()return 123 end}
local materials={}
for id=1,14 do
    LL.ItemDB.professionProfiles.items[id]={qualityRank=(id-1)%2+1,qualityFamilyID=100}
    materials[id]={id=id,expectedQuantity=id==14 and 0 or id==2 and 1.25 or .2,
        chance=id==14 and 0 or id==2 and .625 or .2,
        minQuantity=1,maxQuantity=id==2 and 3 or 1,netExpectedValue=id}
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
    assert(count==14 and text:find('20% |T123:14:14:0:0|t |cffb4d8ff[R1]|r Crystal [1]',1,true)
        and text:find('62.5% |T123:14:14:0:0|t |cffb4d8ff[R2]|r Crystal [1-3]',1,true)
        and text:find('  0% ',1,true),text)
    assert(not text:find('%d%.%d+x Crystal'),'supported disenchant rows must use probabilities and bracketed yields')
    assert(not text:find('[avg',1,true) and text:find('Locked bonus',1,true),'every modeled row remains visible')
end
assert(materials[1].chance==.2 and materials[2].chance==.625 and materials[14].chance==0,
    'display preserves occurrence evidence')
assert(materials[1].expectedQuantity==.2 and materials[1].netExpectedValue==1,'baseline/valuation unchanged')
print('PASS: disenchant percentage/range format, every modeled grade including zero and unchanged evidence/value')
