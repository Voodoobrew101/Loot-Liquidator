local checks=0
local function check(v,label) assert(v,label);checks=checks+1 end
local function near(a,b,label) check(type(a)=='number' and math.abs(a-b)<1e-10,label..': '..tostring(a)..' ~= '..tostring(b)) end
local LL={ItemDB={professionProfiles={recipeQualityModels={},items={},qualityFamilies={}}}}
assert(loadfile('LootLiquidator/ProfessionCalculations.lua'))('LL',LL)
local function params(inputFactor,outputFactor)
    return {inputFactor=inputFactor,outputFactor=outputFactor,method='Mill',expansionID=9,
        profession='Inscription',recipe={},skill=0,skillMaximum=100,confidence=0,
        extraOutputs={},nontradableExtraOutputs={},minimumOutputs={},relativeExtraOutputs={},
        sameOutputExtra=0,namedOutputs={},speedFactor=1}
end
local original={inputCount=5,sourceQuantityBasis='net-input',materials={{id=100,expectedQuantity=10,
    confidence=0,sourceObservedCounts={quantity=100,netInputs=50}}}}
local option={name='Mill',inputCount=5}
local source=params(.8,1.2)
local canonical=assert(LL:NormalizeProfessionBaseline(original,source,option))
near(canonical.materials[1].expectedQuantity,10*.8/1.2,'net output converts to gross before inverse output effects')
near(canonical.expectedInputCount,5,'canonical input remains one gross five-input batch')
near(canonical.reportedNetInputFactor,.8,'source refund normalization retained')
check(canonical.sourceQuantityBasis=='gross-input','canonical units explicitly gross')
near(original.materials[1].expectedQuantity,10,'source quantities immutable')
check(original.expectedInputCount==nil and original.sourceQuantityBasis=='net-input','source units immutable')
local atSource=LL:ProjectProfessionBaseline(canonical,source,option)
near(atSource.materials[1].expectedQuantity,8,'source gross-operation output')
near(atSource.expectedInputCount,4,'source net input cost exactly once')
near(atSource.materials[1].expectedQuantity/atSource.expectedInputCount,2,'reported per-net-input yield round trips')
near(original.materials[1].sourceObservedCounts.quantity,100,'original output counters unchanged')
local noRefund=LL:ProjectProfessionBaseline(canonical,params(1,1.2),option)
near(noRefund.materials[1].expectedQuantity,8,'changing input savings does not manufacture gross output')
near(noRefund.expectedInputCount,5,'zero resourcefulness restores gross consumption')
local strongerRefund=LL:ProjectProfessionBaseline(canonical,params(.6,1.2),option)
near(strongerRefund.materials[1].expectedQuantity,8,'target resourcefulness stays an input effect')
near(strongerRefund.expectedInputCount,3,'stronger target resourcefulness applies once')
near(strongerRefund.materials[1].expectedQuantity/strongerRefund.expectedInputCount,8/3,'target net ratio uses normalized gross quantity')
local normalizedAgain=LL:NormalizeProfessionBaseline(atSource,source,option)
near(normalizedAgain.materials[1].expectedQuantity,canonical.materials[1].expectedQuantity,'projected baseline inverse is idempotent')
local gross={inputCount=5,sourceQuantityBasis='gross-input',materials={{id=100,expectedQuantity=10,confidence=0}}}
local grossBase=LL:NormalizeProfessionBaseline(gross,source,option)
near(grossBase.materials[1].expectedQuantity,10/1.2,'gross observations do not receive net-input correction')
local grossRoundtrip=LL:ProjectProfessionBaseline(grossBase,source,option)
near(grossRoundtrip.materials[1].expectedQuantity,10,'gross-operation source quantities round trip')
near(grossRoundtrip.expectedInputCount,4,'gross source still has ordinary modeled input savings')
print(('REVIEWED NET INPUT BASIS: %d checks passed'):format(checks))
