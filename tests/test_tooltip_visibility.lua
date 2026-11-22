local LL={db={}}
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
assert(loadfile('LootLiquidator/Badges.lua'))('LootLiquidator',LL)
LL.MarkupColor=function()return ''end
LL.Money=function(_,v)return tostring(v)..' copper'end
LL.SourceOrder={'fixture'}
LL.ReviewedProcessingSourceFactLines=function()error('the normal tooltip must not query research detail')end
LL.ProfessionSimulationEffectNotes=function()error('the normal tooltip must not query diagnostic notes')end
LL.ProfessionProgression=function()error('the normal tooltip must not query progression notes')end
C_Item={GetItemInfo=function(id)return ({[1]='Dawn Crystal',[2]='Eversinging Dust',[3]='Radiant Shard',[4]='Eversinging Dust'})[id],nil,id==1 and 4 or id==3 and 3 or 2 end,
    GetItemIconByID=function(id)return 100+id end}
ITEM_QUALITY_COLORS={[2]={hex='|cff1eff00'},[3]={hex='|cff0070dd'},[4]={hex='|cffa335ee'}}
local probabilities={.029,.663,.402,.175}
local materials={}
for id,chance in ipairs(probabilities)do materials[id]={id=id,chance=chance,expectedQuantity=chance,minQuantity=1,maxQuantity=id%2==0 and 3 or 1,netExpectedValue=id*100}end
local model={inputCount=1,materials=materials,confidence=30,provisional=true,partial=true,
    skillQualityApplied=true,warning='diagnostic warning',adjustment='diagnostic adjustment',sources={fixture=1},samples=2}
local renders=0
for _,method in ipairs({'Disenchant','Mill','Prospect','Smelt','Craft','Recycle','Research','Combine','Split','Exchange'})do
    for detail=0,3 do
        for mask=0,7 do
            LL.db={tooltipDetail=detail,tooltipHeaderPrice=false,tooltipOutputSort='database',
                showResearchDetails=mask>=4,showProfessionDetails=math.floor(mask/2)%2==1,showTooltipExplanations=mask%2==1}
            local option={name=method,profession='Enchanting',letter='D',available=true,value=1234,
                tooltipProfileLabel='Voodoobrew - Grizzly Hills',yieldModel=model}
            local tip={lines={},rows={}}
            function tip:AddLine(s)self.lines[#self.lines+1]=s end
            function tip:AddDoubleLine(l,r)self.lines[#self.lines+1]=l..' | '..r;self.rows[#self.rows+1]={l,r}end
            LL:AppendRecommendationTooltip(tip,{action='V',facts={id=276033,classID=7},conversionOptions={option}})
            local text=table.concat(tip.lines,'\n')
            if detail==0 then assert(text=='')else
                assert(tip.lines[1]=='|cff66ccffLoot Liquidator:|r Vendor|r','required recommendation header')
                if detail>=2 then
                    assert(tip.rows[1][1]:find(' — Voodoobrew - Grizzly Hills (Confidence 30%)',1,true),'required character/confidence header')
                    assert(tip.rows[1][2]=='1234 copper','method value remains numerical')
                end
                if detail==3 then
                    assert(#tip.rows==5,'one method and all four material rows, no extra panels')
                    assert(tip.rows[2][1]=='  2.9% |T101:14:14:0:0|t |cffa335eeDawn Crystal|r [1]|r')
                    assert(tip.rows[3][1]=='  66.3% |T102:14:14:0:0|t |cff1eff00Eversinging Dust|r [1-3]|r')
                    assert(tip.rows[4][1]=='  40.2% |T103:14:14:0:0|t |cff0070ddRadiant Shard|r [1]|r')
                    assert(tip.rows[5][1]=='  17.5% |T104:14:14:0:0|t |cff1eff00Eversinging Dust|r [1-3]|r')
                    for i=2,5 do assert(tip.rows[i][2]==tostring((i-1)*100)..' copper')end
                end
                for _,word in ipairs({'diagnostic','partial','estimate','unavailable','unscored','Processing source facts','skill-based quality'})do
                    assert(not text:find(word,1,true),'no '..word..' appendage')
                end
            end
            assert(materials[1].chance==.029 and materials[1].netExpectedValue==100 and option.available==true,'no numerical/access mutation')
            renders=renders+1
        end
    end
end
-- Incomplete rows remain visible in the owner's shared percentage/range format.
LL.db={tooltipDetail=3};model.materials={{id=1,expectedQuantity=.375}};model.confidenceUnscored=true
local tip={rows={}};function tip:AddLine()end;function tip:AddDoubleLine(l,r)self.rows[#self.rows+1]={l,r}end
LL:AppendRecommendationTooltip(tip,{action='V',facts={id=1},conversionOptions={{name='Disenchant',available=true,letter='D',yieldModel=model}}})
assert(tip.rows[1][2]=='' and not tip.rows[1][1]:find('Confidence',1,true))
assert(#tip.rows==2 and tip.rows[2][1]:find('37.5% ',1,true)and tip.rows[2][1]:find('[1]',1,true)and tip.rows[2][2]=='',
    'Missing probability/range gets a local display estimate; a missing gold value stays missing')
assert(model.materials[1].expectedQuantity==.375 and model.materials[1].chance==nil)
-- Auto profile rows retain the same character header, including at detail 2
-- when a recommendation action is absent.
LL.db={tooltipDetail=2};model.materials=materials;model.confidenceUnscored=nil
model.context={character='Voodoobrew - Grizzly Hills'}
local autoOption={name='Disenchant',available=true,letter='D',yieldModel=model,value=42}
tip.rows={}
LL:AppendRecommendationTooltip(tip,{facts={id=1},conversionOptions={autoOption}})
assert(#tip.rows==1 and tip.rows[1][1]:find('Disenchant — Voodoobrew - Grizzly Hills (Confidence 30%)',1,true))
LL.CharacterKey=function()return 'Live - Realm'end
model.context.character='Current character';tip.rows={}
LL:AppendRecommendationTooltip(tip,{facts={id=1},conversionOptions={autoOption}})
assert(tip.rows[1][1]:find('Disenchant — Live - Realm',1,true))
-- A pooled rank family must not acquire the representative item's quality pip.
LL.db.tooltipDetail=3;LL.MaterialReagentRanks={[1]=1};model.materials={{id=1,rankIDs={1,2},expectedQuantity=.2,
    chance=.2,minQuantity=1,maxQuantity=1,netExpectedValue=20}}
tip.rows={};LL:AppendRecommendationTooltip(tip,{facts={id=1},conversionOptions={autoOption}})
assert(not tip.rows[2][1]:find('[R1]',1,true),'pooled rank family has no invented quality rank')
model.materials[1].rankIDs=nil;tip.rows={}
LL:AppendRecommendationTooltip(tip,{facts={id=1},conversionOptions={autoOption}})
assert(tip.rows[2][1]:find('[R1]',1,true),'exact native quality retains its rank pip')
print('PASS: '..renders..' compact tooltip renders, shared icon/color/range/value contract and unchanged source/value fields')
