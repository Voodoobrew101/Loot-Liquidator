-- Fixed learned recipes derive quantities from their recipe model; unused
-- personal-record scans must not alter quotes or personal-only explanatory notes.
local checks=0
local function check(v,why)assert(v,why);checks=checks+1 end
local function eq(a,b,why)check(a==b,(why or '')..': '..tostring(a)..' ~= '..tostring(b))end
local LL={db={}}
assert(loadfile('LootLiquidator/ConversionEngine.lua'))('LootLiquidator',LL)
local mode=1
LL.ProcessingDataMode=function()return mode end
LL.CharacterKey=function()return'Player'end
LL.CanUseConversion=function()return true,nil,'Current character'end
LL.EligibleDisenchant=function()return false end
LL.LearnedRecipeConversionOptions=function()return{}end
LL.SalvageConversionOptions=function()return{}end
LL.ResearchProcessingOperations=function()return{}end
GetItemCount=function()return 100 end
local prices={[1]=20,[10]=100,[11]=40,[20]=10}
LL.GetOutputPrice=function(_,id)return prices[id],'Current price fixture'end
LL.Conversions={[1]={
 {method='Craft',profession='Engineering',recipeID=1001,inputCount=2,outputID=10,outputCount=3,
  extraReagents={{id=20,amount=1}},confidence='verified',requirement='Learned recipe'},
 {method='Craft',profession='Engineering',recipeID=1002,inputCount=2,outputID=10},
 {method='Prospect',profession='Jewelcrafting',recipeID=1003,inputCount=5},
 {method='Exchange',recipeID=1004,inputCount=2,outputID=10,outputCount=1}}}
local lookups,personal={},{}
for _,id in ipairs({1001,1002,1003,1004})do personal[id]={note='Original personal note '..id,sourceMarker='immutable '..id}end
LL.GetLearnedProcessingEstimate=function(_,facts,method,batch,id)
 lookups[id]=(lookups[id]or 0)+1;return personal[id]
end
local craftCalls=0
local nativeCraft=function(_,facts,c)
 craftCalls=craftCalls+1
 return{inputCount=c.inputCount,expectedInputCount=c.inputCount,
  materials={{id=c.outputID,expectedQuantity=c.outputCount,confidence=80}},confidence=80,source='Profession recipe'}
end
LL.ProfessionCraftModel=nativeCraft
LL.ResolveEvidenceModel=function(_,facts,option,research)
 eq(research,personal[option.recipeID],'nonfixed processing retains its original personal evidence')
 return{inputCount=option.inputCount,materials={{id=option.recipeID==1003 and 11 or 10,
  expectedQuantity=option.recipeID==1003 and 1.5 or 4,chance=.5,minQuantity=1,maxQuantity=4,confidence=70}},
  confidence=70,personalStats={total=8},source='Personal results fixture'}
end
local function options(count)
 local by={}
 for _,q in ipairs(LL:ConversionOptions({id=1,classID=7,quality=1,expansionID=11,count=count or 100}))do by[q.recipeID]=q end
 return by
end
for _,selectedMode in ipairs({1,2,3})do
 mode=selectedMode;lookups={};craftCalls=0
 local rows=options()
 eq(rows[1001].value,145,'fixed output less the complete extra-reagent cost, per input')
 eq(rows[1001].source,'Profession recipe');eq(rows[1001].yieldModel.materials[1].expectedQuantity,3)
 eq(rows[1001].yieldModel.materials[1].netExpectedValue,300)
 eq(rows[1001].note,mode==2 and personal[1001].note or'Learned recipe','original explanatory note remains intact')
 eq(lookups[1001]or 0,mode==2 and 1 or 0,'only personal-only mode needs the unused fixed-craft note')
 eq(craftCalls,1,'the native fixed recipe model is still projected exactly once')
 eq(rows[1002].value,200);eq(rows[1002].estimate,personal[1002]);eq(rows[1002].samples,8)
 eq(rows[1002].yieldModel.materials[1].chance,.5);eq(rows[1002].yieldModel.materials[1].maxQuantity,4)
 eq(rows[1003].value,12);eq(rows[1003].estimate,personal[1003])
 eq(lookups[1002],1,'variable-output Craft still queries personal data in every mode')
 eq(lookups[1003],1,'stochastic processing still queries personal data in every mode')
 eq(lookups[1004],1,'fixed-ratio exchanges retain their existing separate path')
 eq(rows[1004].value,50)
 for id,r in pairs(personal)do eq(r.sourceMarker,'immutable '..id,'source evidence is never modified')end
end
mode=1;lookups={}
local short=options(1)
eq(short[1001].available,false,'short stacks stay nonactionable')
eq(short[1001].value,145,'short stacks retain their per-input tooltip quote')
eq(lookups[1001],nil,'short stacks do not restore unused record scans')
LL.ProfessionCraftModel=nil;lookups={}
local fallback=options()
eq(lookups[1001],1,'absence of the native recipe-model capability keeps the original fallback query')
eq(fallback[1001].estimate,personal[1001],'fallback evidence is not suppressed')
print('FIXED CRAFT PERSONAL LOOKUP: '..checks..' checks passed')
