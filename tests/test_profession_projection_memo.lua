-- Deterministic projection boundaries, not game-drop claims. Exercise the real
-- inverse/forward model while controlling only its profile-parameter reader.
local checks=0
local function check(value,label)checks=checks+1;assert(value,label)end
local LL={ItemDB={professionProfiles={profiles={['Alchemy:11']={}},recipes={},items={}}}}
assert(loadfile('LootLiquidator/ProfessionCalculations.lua'))('LL',LL)

local targetContext={tag='target',contextFlags={actual=true}}
local lastTarget,targetCalls=nil,0
local function parameters(cap,factor)
    return{confidence=cap,skill=10,outputFactor=factor,inputFactor=1,sameOutputExtra=0,
        extraOutputs={},relativeExtraOutputs={},minimumOutputs={},nontradableExtraOutputs={},namedOutputs={},
        recipe={},stats={resourcefulness=0,multicraft=0},effectTotals={}}
end
LL.ProfessionProfileParameters=function(self,profession,expansion,context,option,facts)
    if context==targetContext then
        targetCalls=targetCalls+1
        lastTarget=parameters(99,option.reviewedEffectOverrides and option.reviewedEffectOverrides.factor or 2)
        return lastTarget
    end
    return parameters(context.cap or 80,1)
end
LL.ProcessingPlayerConditions=function()return targetContext end
local facts={id=1,expansionID=11,context={bound=true},
    conversionOptions={{yieldModel={source={actual=true}}}}}
local option={name='Craft',profession='Alchemy',expansionID=11,inputCount=1}
local function model(cap,override)
    return{baselineProfile={cap=cap},inputCount=1,confidence=100,
        reviewedEffectOverrides=override and {factor=override},
        materials={{id=2,expectedQuantity=2,confidence=100}}}
end

local memo={}
local sourceA,sourceB=model(7),model(73)
local a=assert(LL:ApplyGeneralProfessionModel(facts,option,sourceA,nil,memo))
local b=assert(LL:ApplyGeneralProfessionModel(facts,option,sourceB,nil,memo))
check(targetCalls==1,'same actual context/operation reuses its target parameters')
check(a.confidence==7,'first source retains its own confidence cap')
check(b.confidence==73,'first source cap cannot contaminate the second source')
check(lastTarget.confidence==99,'source confidence changes never mutate the shared target')
check(a.materials[1].expectedQuantity==4 and b.materials[1].expectedQuantity==4,
    'independent source caps leave actual projected means unchanged')
check(sourceA.materials[1].expectedQuantity==2 and sourceB.materials[1].expectedQuantity==2,
    'source normalization/projection never rewrites original material means')

local sourceC,sourceD=model(88,3),model(88,5)
local c=assert(LL:ApplyGeneralProfessionModel(facts,option,sourceC,nil,memo))
local d=assert(LL:ApplyGeneralProfessionModel(facts,option,sourceD,nil,memo))
check(targetCalls==3,'each source-specific effect override bypasses target reuse')
check(c.materials[1].expectedQuantity==6,'first source override uses its own actual factor')
check(d.materials[1].expectedQuantity==10,'second source override cannot reuse another source factor')
check(sourceC.reviewedEffectOverrides.factor==3 and sourceD.reviewedEffectOverrides.factor==5,
    'source-specific effect override tables remain unchanged')
check(facts.expansionID==11 and facts.context.bound==true,
    'scope calculations do not mutate actual item identity or nested context')
check(facts.conversionOptions[1].yieldModel.source.actual==true,
    'scope calculations preserve the previous quote graph')
check(targetContext.contextFlags.actual==true and targetContext.effectiveSkill==nil,
    'projected context changes never mutate the cached actual context')
check(option.reviewedEffectOverrides==nil,'source effect overrides never leak to the caller operation')
check(option.preserveMaterialIdentity==nil and option.deferRecipeQuality==nil,
    'projection-only settings never leak to the caller operation')
print('PROFESSION PROJECTION MEMO: '..checks..' checks passed')
