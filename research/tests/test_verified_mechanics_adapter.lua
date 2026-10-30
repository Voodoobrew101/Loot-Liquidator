-- Run from repository root: lua5.1 research/tests/test_verified_mechanics_adapter.lua
-- These tests run without WoW and do not require a character profile.
local LL={ItemDB={mechanicRules={}}}
assert(loadfile("LootLiquidator/ProfessionModels.lua"))("LootLiquidator",LL)
assert(loadfile("LootLiquidator/ConversionEngine.lua"))("LootLiquidator",LL)
GetBuildInfo=function() return "12.1.5","123456","",120105 end
LL.CharacterKey=function() return "Tester-Realm" end
LL.ProcessingPlayerConditions=function()
    return {skill=100,skillLineID=1234,expectedStat=20}
end
local input={id=10,quality=2,reagentQuality=2,expansionID=11}
local opt={name="Prospect",recipeID=444,character="Tester-Realm"}
local function base()
    return {patchBuild="123450",referenceContextID="cohort-a",
        source="sample",materials={
            {id=20,expectedQuantity=2,chance=.5,probabilityVerified=true,
                minQuantity=1,maxQuantity=4},
            {id=21,expectedQuantity=.2,chance=.1,
                probabilityBasis="estimated occurrence proxy",minQuantity=1,maxQuantity=3}
        }}
end
local function rule(target,id,formula,params)
    return {ruleID=target..id,method="Prospect",recipeID=444,
        inputItemID=10,outputItemID=id,inputQualityRank=2,
        expansionID=11,sourceBuild="123450",targetBuild="123456",
        sourceReferenceContextID="cohort-a",targetConditions={skill=100},
        evidenceStatus="VERIFIED_NUMERIC",applyPolicy="EXECUTE",
        applies="VERIFIED_APPLIES",confidence0to100=95,
        sourceClaimIDs={"research-claim-a","independent-claim-b"},
        numericTransformValidated=true,independentReview="APPROVED",
        effectTarget=target,formulaID=formula,parameters=params}
end
local function evaluate(model)
    return LL:ApplyVerifiedMechanics(input,opt,model or base())
end
local function eq(actual,expected,message)
    if actual~=expected then
        error((message or "unexpected value")..": expected "..
              tostring(expected).." got "..tostring(actual),2)
    end
end
local g=LL.ItemDB
local a=base()
eq(evaluate(a),a,"empty rules must preserve original reference")
local e=rule("OUTPUT_UNCONDITIONAL_EXPECTATION",20,"MULTIPLY",{multiplier=1.5})
LL.GameData={verifiedMechanicsRules={e}}
eq(evaluate(a),a,"old GameData rule path cannot execute")
g.mechanicRules={e}
local b=evaluate(a)
eq(b.materials[1].expectedQuantity,3,"scaled expectation")
eq(b.materials[1].chance,nil,"unknown new occurrence must not be invented")
eq(b.materials[1].minQuantity,nil,"unknown new minimum must not be invented")
eq(b.materials[1].maxQuantity,nil,"unknown new maximum must not be invented")
eq(b.materials[2].expectedQuantity,.2,"unrelated output unchanged")
eq(a.materials[1].expectedQuantity,2,"original cohort not mutated")
eq(a.materials[1].chance,.5,"original probability not mutated")
eq(b.mechanicsRuleCount,1,"count applied transforms")
local p=rule("OUTPUT_OCCURRENCE",20,"MULTIPLY",{multiplier=1.2})
local y=rule("OUTPUT_POSITIVE_QUANTITY",20,"SET_VERIFIED_RANGE",
    {minQuantity=2,maxQuantity=6})
g.mechanicRules={e,p,y}
local c=evaluate()
eq(c.materials[1].expectedQuantity,3,"EV is never multiplied by occurrence")
eq(c.materials[1].chance,.6,"verified occurrence transform")
eq(c.materials[1].minQuantity,2,"verified minimum")
eq(c.materials[1].maxQuantity,6,"verified maximum")
-- A probability may be updated independently, only from measured baseline.
g.mechanicRules={rule("OUTPUT_OCCURRENCE",21,"MULTIPLY",{multiplier=2})}
eq(evaluate().materials[2].chance,.1,"proxy chance must not be scaled")
local negative={
    function(r) r.evidenceStatus="VERIFIED_QUALITATIVE" end,
    function(r) r.confidence0to100=79 end,
    function(r) r.sourceClaimIDs={} end,
    function(r) r.sourceClaimIDs={"single-claim"} end,
    function(r) r.independentReview=nil end,
    function(r) r.numericTransformValidated=false end,
    function(r) r.confidence0to100=89 end,
    function(r) r.sourceBuild="wrong-era" end,
    function(r) r.targetBuild="wrong-build" end,
    function(r) r.sourceReferenceContextID="other-cohort" end,
    function(r) r.inputItemID=99 end,
    function(r) r.inputQualityRank=3 end,
    function(r) r.recipeID=999 end,
    function(r) r.applyPolicy="NO_NUMERIC_TRANSFORM" end,
    function(r) r.applies="UNKNOWN" end,
    function(r) r.targetConditions={skill=101} end,
    function(r) r.parameters.multiplier=math.huge end,
    function(r) r.parameters.multiplier=-1 end,
}
for i,change in ipairs(negative) do
    local r=rule("OUTPUT_UNCONDITIONAL_EXPECTATION",20,
                 "MULTIPLY",{multiplier=1.5})
    change(r)
    g.mechanicRules={r}
    eq(evaluate().materials[1].expectedQuantity,2,
        "unsafe rule "..i.." must not change baseline")
end
g.mechanicRules={e,e}
eq(evaluate().materials[1].expectedQuantity,2,
    "competing transformations must not silently stack")
g.mechanicRules={e}
opt.character="Offline-Realm"
eq(evaluate().materials[1].expectedQuantity,2,
    "current client stats must not apply to an offline alt")
opt.character="Tester-Realm"
local noBuild=base()
noBuild.patchBuild=nil
eq(evaluate(noBuild),noBuild,"missing source build must preserve baseline")
local noContext=base()
noContext.referenceContextID=nil
eq(evaluate(noContext),noContext,"missing reference context must preserve baseline")
print("PASS: verified mechanics adapter fail-closed and field-isolated checks")
