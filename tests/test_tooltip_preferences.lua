local LL={db={tooltipDetail=3}}
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
assert(loadfile('LootLiquidator/Database.lua'))('LootLiquidator',LL)
assert(loadfile('LootLiquidator/Badges.lua'))('LootLiquidator',LL)
LL.MarkupColor=function()return ''end
LL.Money=function(_,n)return tostring(n)..' copper'end
LL.ProfessionProgression=function()return {}end
local a={id=10,chance=.2,expectedQuantity=.375,minQuantity=1,maxQuantity=2,netExpectedValue=3}
local b={id=20,chance=.8,expectedQuantity=2,minQuantity=2,maxQuantity=2,netExpectedValue=9}
local zero={id=30,chance=0,expectedQuantity=0,netExpectedValue=0}
local unknown={id=40}
local original={unknown,a,zero,b}
local function order(mode,expected)
    LL.db.tooltipOutputSort=mode
    local sorted=LL:SortedTooltipMaterials(original)
    for i,id in ipairs(expected) do assert(sorted[i].id==id,mode..' row '..i) end
    assert(original[1]==unknown and original[2]==a and original[3]==zero and original[4]==b,'cached model unchanged')
end
order('value',{20,10,30,40})
a.chance=.9
order('chance',{10,20,30,40})
a.chance=.2
a.expectedQuantity=3
order('quantity',{10,20,30,40})
a.expectedQuantity=.375
order('database',{40,10,30,20})
order('invalid-saved-value',{20,10,30,40})
C_Item={GetItemInfo=function(id)return ({[10]='Zinc',[20]='amber',[30]='Copper'})[id]end,
    GetItemIconByID=function(id)return 100+id end}
order('name',{20,30,10,40})
local model={inputCount=5,materials={a,b},confidence=50,value=12}
local function render(show,method)
    LL.db.showAverageQuantity=show
    local tip={lines={}}
    function tip:AddLine(s)self.lines[#self.lines+1]=s end
    function tip:AddDoubleLine(l,r)self.lines[#self.lines+1]=l..' | '..r end
    LL:AppendRecommendationTooltip(tip,{action='P',facts={id=1,classID=7,count=5},count=5,
        conversionOptions={{name=method or 'Smelt',letter='P',available=true,value=12,yieldModel=model}}})
    return table.concat(tip.lines,'\n')
end
for _,method in ipairs({'Disenchant','Mill','Prospect','Smelt','Craft'})do
    for _,show in ipairs({false,true})do
        LL.db.showAverageQuantity=show
        LL.db.showResearchDetails=true;LL.db.showTooltipExplanations=true;LL.db.showProfessionDetails=true
        local text=render(show,method)
        assert(text:find('[1-2]',1,true) and text:find('[2]',1,true),'conditional ranges stay visible')
        assert(text:find('20% |T110:14:14:0:0|t Zinc',1,true)
            and text:find('80% |T120:14:14:0:0|t amber',1,true),'leading probabilities remain exact')
        assert(text:find('copper',1,true),'prices stay visible')
        for _,word in ipairs({'[avg','Per 5 input','Unadjusted reference','effective contribution','skill 104'})do
            assert(not text:find(word,1,true),'compact tooltip omits '..word)
        end
        assert(a.expectedQuantity==.375 and a.netExpectedValue==3,'display does not modify yield/value')
    end
end
a.chance=nil
local meanOnly=render(false,'Prospect')
assert(meanOnly:find('25% ',1,true) and meanOnly:find('Zinc [1-2]',1,true) and not meanOnly:find('x ',1,true),
    'The existing mean/range rule supplies a local display estimate in the shared format')
assert(a.expectedQuantity==.375 and a.chance==nil and a.netExpectedValue==3,'Rendering preserves valuation and evidence')
model.confidenceUnscored=true
assert(not render(false):find('Confidence 50%',1,true),'unscored output cannot acquire a numeric confidence')
print('PASS: compact processing rows, sorting and display estimates preserve source figures and prices')
