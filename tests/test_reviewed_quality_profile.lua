-- A source quality mix is data. Skill alone cannot establish new rank odds.
-- Fixture quantities/bonuses exercise algebra, not claimed game coefficients.
local LL={}
assert(loadfile('LootLiquidator/ProfessionCalculations.lua'))('LL',LL)
local checks=0
local function check(ok,why)checks=checks+1;assert(ok,why)end
local function near(a,b,why)check(type(a)=='number' and math.abs(a-b)<1e-8,why..': '..tostring(a)..' ~= '..tostring(b))end
local function copy(x)if type(x)~='table'then return x end local y={}for k,v in pairs(x)do y[k]=copy(v)end return y end
local function same(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not same(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
local dust={219946,219947,219948}
LL.ItemDB={professionProfiles={items={},qualityFamilies={},profiles={['Enchanting:10']={nodes={},statKeys={}}}},modeledProfessionBaselines={}}
LL.ItemDB.professionProfiles.qualityFamilies[1]={rankItemIDs=dust}
for rank,id in ipairs(dust)do LL.ItemDB.professionProfiles.items[id]={subclassID=12,qualityFamilyID=1,qualityRank=rank}end
local function params(method,skill,factor)return{method=method,profession='Enchanting',expansionID=10,skill=skill,skillMaximum=200,outputFactor=factor or 1,inputFactor=1,relativeExtraOutputs={},minimumOutputs={},extraOutputs={},nontradableExtraOutputs={},sameOutputExtra=0,speedFactor=1,confidence=100,recipe={}}end
local function model()
 local out={recordID='source-quality-fixture',inputCount=1,expectedInputCount=1,confidence=90,reviewedBacklogModel=true,reviewedQualityProjection='source-anchored',materials={}}
 for rank,id in ipairs(dust)do out.materials[rank]={id=id,expectedQuantity=({1,.4,.6})[rank],chance=({.5,.2,.3})[rank],confidence=90,minQuantity=1,maxQuantity=3}end
 return out
end
local option={name='Disenchant',inputCount=1}
for _,method in ipairs({'Disenchant','Mill','Prospect'})do
 for _,sourceSkill in ipairs({0,80,200})do
  local source=model();local original=copy(source)
  local normalized=assert(LL:NormalizeProfessionBaseline(source,params(method,sourceSkill),option))
  check(not normalized.reviewedQualityAnchors,'normalization invents no endpoints')
  for _,targetSkill in ipairs({0,40,140,200})do
   local result=assert(LL:ProjectProfessionBaseline(normalized,params(method,targetSkill),option))
   for rank,m in ipairs(result.materials)do near(m.expectedQuantity,source.materials[rank].expectedQuantity,'source rank quantity retained without calibration');near(m.chance,source.materials[rank].chance,'original probability retained when quantity unchanged')end
   check(result.confidence==90,'no fabricated projection confidence replaces source confidence')
  end
  check(same(source,original),'immutable source quantities and rank probabilities')
 end
end
local source=model();local normalized=assert(LL:NormalizeProfessionBaseline(source,params('Disenchant',200,1.5),option))
local boosted=assert(LL:ProjectProfessionBaseline(normalized,params('Disenchant',50,2),option))
for rank,m in ipairs(boosted.materials)do
 near(m.expectedQuantity,source.materials[rank].expectedQuantity/1.5*2,'explicit supported yield factor applies once without rank guess')
 check(m.chance==nil,'changed expectation does not invent probability')
end
-- The post-blend quality hook must not reintroduce the removed rank prior.
source.generalProfessionApplied=true;source.generalProfessionParameters=params('Disenchant',200)
check(LL:ApplyGeneralProfessionQuality({expansionID=10},option,source,{})==source,'ordinary DE blend retains source ranks')
source.generalProfessionParameters=params('Prospect',200)
check(LL:ApplyGeneralProfessionQuality({expansionID=10},{name='Prospect'},source,{})==source,'ordinary processing blend retains source ranks')
print('PASS: '..checks..' retained source quality, conservation and supported coefficient checks')
