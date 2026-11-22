-- Producer-shaped fixtures exercise the shared evidence/value/tooltip path.
-- These synthetic rows are not additional claims about game drop tables.
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
GetBuildInfo=function()return '12.1.5','123456','',120105 end
GetTime=function()return 100 end
local LL={}
for _,name in ipairs({'ItemDBRuntime.lua','ProfessionModels.lua','Database.lua','ConversionEngine.lua','Badges.lua'})do
    assert(loadfile('LootLiquidator/'..name))('LootLiquidator',LL)
end
LL.db={tooltipDetail=3,tooltipOutputSort='database',source_legacy_enabled=false,
    source_personal_enabled=false,source_imported_enabled=false}
LL.GetOutputPrice=function()return 100 end
LL.MarkupColor=function()return ''end
LL.Money=function(_,n)return ('%.4f copper'):format(n)end
LL.CharacterKey=function()return 'Fixture - Realm'end
LL.ProfessionProgression=function()return {}end
local function field(value)
    return {value=value,status=value==nil and 'unknown' or 'measured',confidence=value==nil and 0 or 80}
end
local function material(id,mean,chance,lo,hi)
    return {id=id,expectedQuantity=field(mean),dropChance=field(chance),
        minQuantity=field(lo),maxQuantity=field(hi)}
end
local inferred=material(22445,1.8,nil,3,3)
local varied=material(16203,.485436893,nil,1,2)
local measured=material(1003,1.8,.5,3,6)
local conflict=material(1004,1.8,nil,3,3)
conflict.dropChance.inferenceBlocked=true
conflict.heldDropChance=field(.95)
local zero=material(1005,0,0,1,1)
local unbounded=material(1006,.75,nil,nil,nil)
local record={recordID='synthetic-midpoint-recovery',sourceKey='itemdb',studyID='synthetic-midpoint-recovery',
    source='synthetic',method='Disenchant',inputItemID=21851,inputCount=1,fieldSpecificEvidence=true,
    materials={inferred,varied,measured,conflict,zero,unbounded}}
LL.ItemDB={schemaVersion=1,processing={record}}
assert(LL:InitializeItemDB(),LL.itemDBError)
local facts={id=21851,classID=4,quality=2,expansionID=1}
local operation={name='Disenchant',letter='D',inputCount=1,recipeID=13262}
local model=assert(LL:ComputeEvidenceModel(facts,operation,nil,1,{}))
local byID={};for _,m in ipairs(model.materials)do byID[m.id]=m end
local function near(a,b)assert(type(a)=='number'and math.abs(a-b)<1e-9,tostring(a)..' ~= '..tostring(b))end
near(byID[22445].chance,.6)
near(byID[16203].chance,.485436893/1.5)
for _,id in ipairs({22445,16203})do
    local m=byID[id]
    assert(m.filled=='chance'and model.filledFigures,'Midpoint-derived chance retains inferred provenance')
    assert(m.chanceConfidence==40 and m.confidence==80,'Only inferred occurrence receives half confidence')
end
near(byID[1003].chance,.5)
assert(not byID[1003].filled,'An actual source probability is never replaced by the midpoint estimate')
assert(byID[1004].chance==nil and not byID[1004].filled,
    'A rejected reported probability remains blocked instead of being recreated')
assert(byID[1004].sourceEstimates.itemdb.heldDropChance.value==.95,'Conflict evidence remains available')
assert(byID[1006].chance==nil and not byID[1006].filled,
    'A mean without a supported quantity range cannot establish occurrence')
assert(byID[1005].chance==0 and byID[1005].expectedQuantity==0,'A supported zero remains zero')
-- Independently exercise the formatter's known skill-locked projection shape.
-- This synthetic gate result does not establish that arbitrary observed zeros
-- are legitimate locked outputs or that an enabling skill exists for them.
byID[1005].structuralZero=true
byID[1005].probabilityBasis='specialization-eligibility-zero'
byID[1005].minQuantity=0;byID[1005].maxQuantity=0
local value=assert(LL:ValueProcessingModel(model,0,true))
near(value,(1.8+.485436893+1.8+1.8+.75)*100)
near(byID[22445].netExpectedValue,180)
near(byID[1005].netExpectedValue,0)

local names={[22445]='Midpoint Crystal',[16203]='Variable Essence',[1003]='Measured Dust',
    [1004]='Conflicting Shard',[1005]='Zero Crystal',[1006]='Mean Only Dust'}
C_Item={GetItemInfo=function(id)return names[id]end,GetItemIconByID=function(id)return id+100 end}
for level=0,3 do
    LL.db.tooltipDetail=level
    local tip={lines={},rows={}}
    function tip:AddLine(text)self.lines[#self.lines+1]=text end
    function tip:AddDoubleLine(left,right)self.rows[#self.rows+1]={left,right}end
    LL:AppendRecommendationTooltip(tip,{action='D',facts=facts,conversionOptions={{name='Disenchant',letter='D',
        inputCount=1,value=value,yieldModel=model}}})
    assert(#tip.lines==(level==0 and 0 or 1),'Existing tooltip detail setting remains effective')
    assert(#tip.rows==(level<2 and 0 or level==2 and 1 or 1+#record.materials),
        'Every material, including zero/blocked/mean-only outputs, survives at material detail')
    if level==3 then
        local rows={}
        for _,row in ipairs(tip.rows)do
            for id,name in pairs(names)do if row[1]:find(name,1,true)then rows[id]=row end end
        end
        assert(rows[22445][1]:find('60% |T22545:14:14:0:0|t Midpoint Crystal [3]',1,true))
        assert(rows[22445][2]=='180.0000 copper','Inferred occurrence does not multiply the mean a second time')
        assert(rows[16203][1]:find('32.4%',1,true)and rows[16203][1]:find('[1-2]',1,true))
        assert(rows[1003][1]:find('50%',1,true)and rows[1003][1]:find('[3-6]',1,true))
        assert(rows[1004][1]:find('60%',1,true)and rows[1004][1]:find('[3]',1,true),
            'Selected known bounds allow a display midpoint estimate while rejected raw source P stays held')
        assert(rows[1005][1]:find('0%',1,true)and rows[1005][1]:find('[0]',1,true)
            and rows[1005][2]=='0.0000 copper','Known skill-locked rows display 0% [0] and zero value')
        assert(rows[1006][1]:find('75%',1,true)and rows[1006][1]:find('[1]',1,true),
            'Missing presentation fields use a local best estimate without changing the unbounded source/model')
    end
end
assert(inferred.dropChance.value==nil and inferred.dropChance.status=='unknown'
    and inferred.dropChance.inferenceBlocked==nil and inferred.expectedQuantity.value==1.8,
    'Inference never writes back into source evidence')
assert(varied.dropChance.value==nil and measured.dropChance.value==.5
    and conflict.dropChance.inferenceBlocked and conflict.heldDropChance.value==.95,
    'Rendering preserves actual, missing and quarantined source fields')
print('PASS: midpoint recovery shares evidence, valuation and tooltip paths; inferred confidence, source conflicts, settings and zero rows preserved')
