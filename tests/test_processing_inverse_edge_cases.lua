-- Actual sparse-rank and bound-output source vectors that previously failed
-- inverse/forward. Source counters/fields are immutable and samples remain0.
local rules=PROFILE_RULES_OVERRIDE or assert(loadfile('database/profession-profile-rules.lua'))()
local LL={ItemDB={professionProfiles=rules}}
assert(loadfile('LootLiquidator/ProfessionCalculations.lua'))('LL',LL)
local fixtures=assert(loadfile('tests/fixtures/processing-inverse-edge-cases.lua'))()
local checks=0
local function check(ok,why) checks=checks+1;assert(ok,why) end
local function close(a,b,why)check(math.abs(a-b)<1e-8*math.max(1,math.abs(a),math.abs(b)),why)end
local function copy(v)if type(v)~='table'then return v end local r={}for k,x in pairs(v)do r[k]=copy(x)end return r end
local function equal(a,b)if type(a)~=type(b)then return false end if type(a)~='table'then return a==b end for k,v in pairs(a)do if not equal(v,b[k])then return false end end for k in pairs(b)do if a[k]==nil then return false end end return true end
local function option(s)return {name=s.method,recipeID=s.recipeID,inputCount=s.inputCount,profession=s.profession,reviewedEffectOverrides=s.reviewedEffectOverrides}end
local rawGemEffect
for _,milestone in ipairs(rules.profiles['Jewelcrafting:9'].nodes[28609].milestones)do
 for _,effect in ipairs(milestone.effects or{})do if effect.entryID==36393 and effect.metric=='extraOutput'then rawGemEffect=effect end end
end
check(rawGemEffect and rawGemEffect.operator=='multiply' and rawGemEffect.unit=='fraction' and rawGemEffect.confidence==0,'native raw-gem opportunity uses a relative zero-confidence coefficient')
close(rawGemEffect.amount,.05,'raw-gem coefficient is .05 relative, not units per rank')
local function facts(s)return {id=s.inputItemID,expansionID=s.expansionID,reagentQuality=s.inputQualityRank}end
local function flat(s)
 local m={inputCount=s.inputCount,sourceQuantityBasis=s.sourceQuantityBasis,materials={},reviewedBacklogModel=true,
  reviewedQualityProjection=s.reviewedQualityProjection,reviewedQualityZeroShares=s.reviewedQualityZeroShares}
 for _,v in ipairs(s.materials)do m.materials[#m.materials+1]={id=v.id,rankIDs=copy(v.rankIDs),economicPolicy=v.economicPolicy,expectedQuantity=v.expectedQuantity.value,confidence=0}end
 return m
end
local function means(m)
 local q={}for _,v in ipairs(m.materials or{})do q[v.id]=(q[v.id]or 0)+v.expectedQuantity end return q
end
for _,s in ipairs(fixtures)do
 local saved=copy(s);local o=option(s);local source=LL:ProfessionProfileParameters(s.profession,s.expansionID,s.baselineProfile,o,facts(s))
 local original=flat(s);local raw,why=LL:NormalizeProfessionBaseline(original,source,o)
 check(raw~=nil,s.recordID..' inverse: '..tostring(why))
 local forward,error=LL:ProjectProfessionBaseline(raw,source,o);check(forward~=nil,tostring(error))
 local q=means(forward)
 for _,m in ipairs(original.materials)do close(q[m.id]or 0,m.expectedQuantity,'source mean preserved '..s.recordID..' '..m.id)end
 check(equal(s,saved),'source spec remains unchanged')
 for _,root in ipairs({0,15,30})do for _,points in ipairs({0,5,10,15,20,25})do
  local c=copy(s.baselineProfile);c.specializationPoints={[28610]=root,[28609]=points}
  c.learnedSpecializations={[28610]=root>0,[28609]=points>0}
  local p=LL:ProfessionProfileParameters(s.profession,s.expansionID,c,o,facts(s))
  local projected,issue=LL:ProjectProfessionBaseline(raw,p,o);check(projected~=nil,'target profile forward exists: '..tostring(issue))
  for _,m in ipairs(projected.materials)do check(m.expectedQuantity>=0 and m.expectedQuantity<math.huge,'all target quantities finite and nonnegative')end
  local again=LL:ProjectProfessionBaseline(projected,p,o);check(again~=nil,'replay exists')
  check(equal(means(projected),means(again)),'bonuses apply once on every target profile')
 end end
 if s.reviewedEffectOverrides then
  local zero=copy(s.baselineProfile);zero.specializationPoints={};zero.learnedSpecializations={}
  local off=LL:ProfessionProfileParameters(s.profession,s.expansionID,zero,o,facts(s))
  local z=LL:ProjectProfessionBaseline(raw,off,o);close(means(z)[194545]or 0,0,'Prismatic locked baseline is zero')
  zero.learnedSpecializations[28609]=true
  local learned=LL:ProfessionProfileParameters(s.profession,s.expansionID,zero,o,facts(s))
  local p=LL:ProjectProfessionBaseline(raw,learned,o)
  local count=0 for _,m in ipairs(p.materials)do if m.id==194545 then count=count+1;check(m.economicPolicy=='nontradable','Prismatic stays bound')end end
  check(count==1,'calibrated Prismatic not duplicated as normal+bound')
  close(means(p)[194545],s.reviewedEffectOverrides['entry:36397:extraOutput:1'].amount,'learning applies source-calibrated units')
  for _,bad in ipairs({{confidence=1},{entryID=123},{metric='skill'},{mechanism='client-effect-0'},{unit='percent'},{operator='multiply'},{inputCount=1},{amount=-1},{amount=0/0}})do
   local wrong=copy(o);local override=wrong.reviewedEffectOverrides['entry:36397:extraOutput:1'];for k,v in pairs(bad)do override[k]=v end
   local w=LL:ProfessionProfileParameters(s.profession,s.expansionID,zero,wrong,facts(s))
   close(w.nontradableExtraOutputs[194545],.05,'invalid override cannot replace native scoped prior')
  end
 end
end
-- Khaz'gorite chance wording is scoped to Prismatic input; the adjacent
-- native15% speed bonus stays available on all valid prospect operations.
local ctx={skill=0,specializationPoints={[28609]=25},learnedSpecializations={[28609]=true},stats={}}
local op={name='Prospect',profession='Jewelcrafting',recipeID=374627,inputCount=5}
for _,input in ipairs({190394,190396,194545})do
 local p=LL:ProfessionProfileParameters('Jewelcrafting',9,ctx,op,{id=input,expansionID=9})
 local quantity,speed=false,false
 for _,effect in ipairs(p.appliedEffects)do if effect.entryID==36392 then
  if effect.metric=='extraOutput'then quantity=true;close(effect.amount,.05,'Khaz magnitude is an uncalibrated qualitative prior')end
  if effect.metric=='craftingSpeed'then speed=true;close(effect.amount,15,'native15% is crafting speed')end
 end end
 check(quantity==(input==194545),'Khaz output perk cannot leak onto Serevite')
 check(speed,'native speed perk remains active')
end
-- Pure pooled alternatives: one quantity and one additive term across ranks.
local minimal={skill=0,skillMaximum=100,outputFactor=1.1,inputFactor=.9,speedFactor=1,confidence=0,recipe={},method='Prospect',
 extraOutputs={[192870]=.003},nontradableExtraOutputs={},relativeExtraOutputs={[192869]=.05,[192870]=.05,[192871]=.05},minimumOutputs={},
 sameOutputExtra=0,namedOutputs={},effectTotals={}}
local pool={inputCount=5,materials={{id=192869,rankIDs={192869,192870,192871},expectedQuantity=.2,confidence=0}}}
local before=copy(pool);local canonical=assert(LL:NormalizeProfessionBaseline(pool,minimal,{inputCount=5}));local projected=assert(LL:ProjectProfessionBaseline(canonical,minimal,{inputCount=5}))
check(#projected.materials==1,'pool member extra not appended as duplicate exact-rank row')
close(projected.materials[1].expectedQuantity,.2,'pooled additive and relative terms roundtrip exactly')
check(equal(pool,before),'pooled source stays immutable')
local inconsistent=copy(minimal);inconsistent.relativeExtraOutputs[192871]=.15
local rejected,why=LL:NormalizeProfessionBaseline(pool,inconsistent,{inputCount=5})
check(not rejected and why:find('unequal rank multipliers',1,true),'unknown pool shares cannot identify unequal rank coefficients')
-- The correction of native BoP metadata does not merge conjured copies of a
-- normally tradable primary into its priced quantity.
local mixed=copy(minimal);mixed.outputFactor=1;mixed.relativeExtraOutputs={};mixed.extraOutputs={};mixed.nontradableExtraOutputs={[192870]=.01}
local tradable={inputCount=5,materials={{id=192870,expectedQuantity=.2}}}
local both=assert(LL:ProjectProfessionBaseline(tradable,mixed,{inputCount=5}))
check(#both.materials==2,'tradable primary and separate bound extra remain separate')
close(both.materials[1].expectedQuantity,.2,'normal primary quantity unchanged')
check(both.materials[2].economicPolicy=='nontradable','bound extra keeps policy')
print('PROCESSING INVERSE EDGE CASES: '..checks..' checks passed')
