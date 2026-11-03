-- C1a: counts-based (beta-binomial) confidence model, worked examples from
-- the owner's study notes.
local LL={ItemDB={schemaVersion=1,processing={},mechanicRules={}},db={}}
assert(loadfile('LootLiquidator/Database.lua'))('LootLiquidator',LL)
local n=0
local function near(a,b,tol,msg) n=n+1;assert(math.abs(a-b)<=tol,(msg or '')..': got '..tostring(a)..' want '..tostring(b)) end
-- Exact Beta CDF against known values.
near(LL:BetaCDF(.5,2,2),.5,1e-9,'symmetric beta')
near(LL:BetaCDF(.3,1,1),.3,1e-9,'uniform')
near(LL:BetaCDF(.2,2,5),1-(.8^6+6*.2*.8^5),1e-9,'Beta(2,5)')
-- Worked example: 18% guess worth 20 casts + 50 casts / 12 drops.
local e=LL:CountsEstimate({prior={chance=.18,casts=20,label='Rank 1 ore'},sources={{casts=50,drops=12,key='personal'}}})
near(e.chance,.2229,.0005,'worked example rate 22.3%')
near(e.confidence,69,1,'worked example ~69% confidence')
assert(not e.priorOnly and e.estimatedFrom==nil)
-- Confidence grows with casts (18% drop): 10 ~30, 50 ~64, 100 ~81, 200 ~94.
for _,row in ipairs({{10,33},{50,65},{100,81},{200,94}}) do
    near(LL:RateConfidence(.18*row[1],row[1]),row[2],2,row[1]..' casts')
end
-- A borrowed guess alone still answers, labelled, with low confidence.
local g=LL:CountsEstimate({prior={chance=.18,label='Rank 1 ore'}})
near(g.chance,.18,1e-9,'prior only');assert(g.priorOnly and g.estimatedFrom=='Estimated from Rank 1 ore')
assert(g.casts==LL.PRIOR_CASTS and g.confidence<50)
-- Weak sources count for less, never nothing (pre-hotfix x0.25).
local w=LL:CountsEstimate({sources={{casts=100,drops=50,weight=.25},{casts=100,drops=10}}})
near(w.chance,(12.5+10)/125,1e-9,'down-weighted source');assert(#w.sourcesUsed==2)
-- Sources may give a chance instead of drops; bad numbers are skipped.
local c=LL:CountsEstimate({sources={{casts=40,chance=.25},{casts=10,drops=12},{casts=-1,drops=0},{casts=0/0,drops=1}}})
near(c.chance,.25,1e-9,'chance source, impossible ones skipped');assert(#c.sourcesUsed==1)
assert(LL:CountsEstimate({})==nil,'nothing at all gives no answer')
-- 0% and 100% rates still produce a sane confidence.
assert(LL:RateConfidence(0,100)>90 and LL:RateConfidence(100,100)>90)
assert(LL:RateConfidence(0,2)<50,'0 drops in 2 casts is not certain')
-- Filling a missing figure from the range.
local ch,avg,filled=LL:FillChanceOrAverage(.4,nil,1,3)
near(avg,.8,1e-9,'average from chance');assert(filled=='average')
ch,avg,filled=LL:FillChanceOrAverage(nil,1.5,1,2)
near(ch,1,1e-9,'chance from average, capped at 100%');assert(filled=='chance')
ch,avg,filled=LL:FillChanceOrAverage(nil,.3,2,nil)
near(ch,.15,1e-9,'single bound');assert(filled=='chance')
assert(select(3,LL:FillChanceOrAverage(.4,.8,1,3))==nil,'nothing to fill')
print(('PASS: %d counts-model assertions (C1a: beta-binomial rates and confidence)'):format(n))
