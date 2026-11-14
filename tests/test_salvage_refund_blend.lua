-- Synthetic cohorts exercise the valuation reducer after import eligibility.
GetBuildInfo=function() return '12.1.5','70783','',120105 end
local LL={db={},ItemDB={schemaVersion=1,processing={}}}
assert(loadfile(arg[1] or 'LootLiquidator/Database.lua'))('LL',LL)
assert(loadfile('LootLiquidator/ConversionEngine.lua'))('LL',LL)

local f={id=243602}
local option={name='Craft',recipeID=1280394,inputCount=1}
LL.GetOutputPrice=function(_,id) return id==f.id and 20 or 100 end

local function near(actual,expected,description)
    assert(type(actual)=='number' and math.abs(actual-expected)<1e-9,
        description..': expected '..expected..', got '..tostring(actual))
end

local function material(id,quantity)
    return {id=id,expectedQuantity={value=quantity,confidence=60,status='observed'},
        dropChance={},minQuantity={},maxQuantity={}}
end

local function record(id,samples,consumed,quantity)
    return {recordID=id,studyID=id,sourceKey='imported',method='Craft',source='Imported results',
        salvage=true,patchBuild='70783',referenceConditions={},referenceContextID='shatter-profile',
        inputItemID=f.id,recipeID=option.recipeID,inputCount=1,samples=samples,expectedInputCount=consumed,
        materials={material(219946,quantity)}}
end

local function quote(imported,other)
    LL._evidenceIndex={['Craft:'..f.id]=other}
    local model=assert(LL:ComputeEvidenceModel(f,option,nil,1,{},true,imported))
    return model,LL:ValueProcessingModel(model,0,true,f)
end

local noRefund=record('a',4,1,3)
local fullRefund=record('b',4,0,3)
local model,value=quote({noRefund,fullRefund})
near(model.expectedInputCount,.5,'equal-size cohorts blend zero and full consumption')
near(value,310,'price both cohorts’ refund savings once')
noRefund.recordID,fullRefund.recordID='b','a'
model,value=quote({fullRefund,noRefund})
near(model.expectedInputCount,.5,'renaming the anchor leaves input consumption unchanged')
near(value,310,'renaming the anchor leaves valuation unchanged')

fullRefund.samples=12
fullRefund.materials[1].expectedQuantity.value=7
model,value=quote({noRefund,fullRefund})
local noRefundWeight=4/(4+30)
local fullRefundWeight=12/(12+30)
local expectedInput=noRefundWeight/(noRefundWeight+fullRefundWeight)
local expectedOutput=(3*noRefundWeight+7*fullRefundWeight)/(noRefundWeight+fullRefundWeight)
near(model.expectedInputCount,expectedInput,'different cast counts use output mean weights')
near(model.materials[1].expectedQuantity,expectedOutput,'existing output blend is preserved')
near(value,100*expectedOutput+20*(1-expectedInput),'weighted refund is priced per nominal shard')
fullRefund.materials[2]=material(219947,2)
model=quote({noRefund,fullRefund})
near(model.expectedInputCount,expectedInput,'an extra cooutput does not add refund weight')
fullRefund.materials[2]=nil

local duplicate=record('z',4,0,15)
duplicate.studyID=noRefund.studyID
local mismatch=record('other',1,0,19)
mismatch.referenceContextID='unrelated-profile'
model,value=quote({noRefund,duplicate,mismatch})
near(model.expectedInputCount,1,'skipped duplicate and incompatible studies add no refund weight')
near(value,300,'ineligible studies do not affect valuation')
local droppedMean=record('invalid mean',500,0,nil)
model=quote({noRefund,droppedMean})
near(model.expectedInputCount,1,'a cohort without an accepted mean adds no refund weight')

for _,invalidConsumption in ipairs({false,-.1,1.1,math.huge,0/0}) do
    local incomplete=record('missing',4,invalidConsumption or nil,3)
    model,value=quote({fullRefund,incomplete})
    assert(model.expectedInputCount==nil,'unusable consumption must not inherit one cohort’s refund rate')
    near(model.materials[1].expectedQuantity,expectedOutput,'known outputs remain priced at nominal input')
    near(value,100*expectedOutput,'no refund savings without complete contributing evidence')
end

local other=record('fixed reference',4,1,3)
other.sourceKey,other.salvage,other.fixedReference='itemdb',nil,true
model,value=quote({fullRefund},{other})
local referenceWeight,importWeight=noRefundWeight,.25*fullRefundWeight
expectedInput=referenceWeight/(referenceWeight+importWeight)
near(model.expectedInputCount,expectedInput,'an exact-context salvage cohort contributes behind a non-salvage anchor')
expectedOutput=(3*referenceWeight+7*importWeight)/(referenceWeight+importWeight)
near(value,100*expectedOutput+20*(1-expectedInput),'higher-priority anchor does not monopolize the refunds')
other.referenceContextID='unrelated fixed reference'
other.expectedInputCount=.8
model,value=quote({fullRefund},{other})
near(model.expectedInputCount,.8,'excluded salvage leaves ordinary anchor consumption intact')
near(value,304,'ordinary anchor valuation is preserved')

other.sourceKey='reference'
model,value=quote({fullRefund},{other})
assert(model.expectedInputCount==nil,'a contributing fixed reference from another context cannot supply a measured refund')
near(value,100*model.materials[1].expectedQuantity,'known outputs survive without a mixed-context refund')

print('PASS: salvage refunds follow accepted weighted output cohorts and price once per nominal batch')
