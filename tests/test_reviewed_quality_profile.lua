-- Mathematical source-anchor tests. Native rank identities are fixed here;
-- era9 dispatch is an engine fixture, not a claim that DF drops TWW/Midnight
-- reagents. The publisher still has to admit the exact input/output cohort.
local LL={}
assert(loadfile('LootLiquidator/ProfessionCalculations.lua'))('LootLiquidator',LL)
local checks=0
local function check(ok,why)checks=checks+1;assert(ok,why)end
local function near(a,b,why)check(type(a)=='number' and math.abs(a-b)<1e-8,(why or '')..': '..tostring(a)..' ~= '..tostring(b))end
local function copy(x)if type(x)~='table'then return x end local y={}for k,v in pairs(x)do y[k]=copy(v)end return y end
local function same(a,b)
    if type(a)~=type(b)then return false end
    if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end
    return true
end
local dust={219946,219947,219948}
local crystal={243605,243606}
LL.ItemDB={professionProfiles={items={},qualityFamilies={},profiles={
    ['Enchanting:9']={nodes={},statKeys={}},['Enchanting:10']={nodes={},statKeys={}}}},modeledProfessionBaselines={}}
for _,ids in ipairs({dust,crystal})do
    LL.ItemDB.professionProfiles.qualityFamilies[ids[1]]={rankItemIDs=ids}
    for rank,id in ipairs(ids)do LL.ItemDB.professionProfiles.items[id]={subclassID=12,qualityFamilyID=ids[1],qualityRank=rank}end
end
local function params(era,p,factor,extras)
    return {method='Disenchant',profession='Enchanting',expansionID=era,skill=p*200,skillMaximum=200,
        outputFactor=factor or 1,inputFactor=1,relativeExtraOutputs={},minimumOutputs={},extraOutputs=extras or {},
        nontradableExtraOutputs={},sameOutputExtra=0,speedFactor=1,confidence=100,recipe={}}
end
local function model(ids,means)
    local out={recordID='reviewed-quality-fixture',inputCount=1,expectedInputCount=1,confidence=100,
        reviewedBacklogModel=true,reviewedQualityProjection='source-anchored',requiresSourceNormalization=true,materials={}}
    for rank,id in ipairs(ids)do out.materials[rank]={id=id,expectedQuantity=means[rank],confidence=100,
        chance=.5,minQuantity=1,maxQuantity=3,probabilityVerified=true,histogram={[1]=10},
        quantityCounts={total=10},personalHistogram={[1]=10},fieldEvidence={quantity=true},samples=10,
        castsWithDrop=10,totalQuantity=20,personalSamples=10}end
    return out
end
local function total(m,ids)
    local n=0 for _,material in ipairs(m.materials)do for _,id in ipairs(ids)do if material.id==id then n=n+material.expectedQuantity end end end return n
end
local function value(m,id)for _,material in ipairs(m.materials)do if material.id==id then return material.expectedQuantity,material end end end
local option={name='Disenchant',inputCount=1,profession='Enchanting'}
for _,era in ipairs({9,10})do for _,ids in ipairs({dust,crystal})do
    local means=#ids==3 and {.9,.5,.6} or {.8,1.2}
    for _,sourceProgress in ipairs({0,.4,1})do
        local source=model(ids,means);local original=copy(source)
        local sp=params(era,sourceProgress,2,{[ids[1]]=.1,[ids[#ids]]=.2})
        local baseline,why=LL:NormalizeProfessionBaseline(source,sp,option)
        check(baseline~=nil,why or 'source anchor normalizes even where old affine inverse is negative/saturated')
        local anchor=baseline.reviewedQualityAnchors.families[ids[1]]
        near(anchor.sourceProgress,sourceProgress,'source profile retained')
        near(total(baseline,ids),.85,'source quantity effects stripped first')
        check(baseline.normalizationConfidence==0,'declared quality prior confidence is zero')
        local roundtrip=assert(LL:ProjectProfessionBaseline(baseline,sp,option))
        for rank,id in ipairs(ids)do near(value(roundtrip,id),means[rank],'source rank mean round trip')end
        check(roundtrip.confidence==0 and roundtrip.ruleConfidence==0 and roundtrip.reviewedQualityProjected,'source anchor projection flagged/capped')
        for _,targetProgress in ipairs({0,.2,.4,.7,1})do
            local tp=params(era,targetProgress,3,{[ids[1]]=.2,[ids[#ids]]=.1})
            local projected=assert(LL:ProjectProfessionBaseline(baseline,tp,option))
            near(total(projected,ids),2.85,'target quantity effects precede quality and family units conserved')
            if targetProgress==sourceProgress then
                for rank,id in ipairs(ids)do near(value(projected,id),2.85*means[rank]/2,'target quantity and anchor shares remain separate')end
            end
            if targetProgress==0 and sourceProgress>0 then
                near(value(projected,ids[1]),2.85,'independent zero prior is lowest native rank')
                for rank=2,#ids do near(value(projected,ids[rank]),0,'higher zero-profile ranks explicitly zero in declared model')end
            end
            if targetProgress==1 and sourceProgress<1 then
                near(value(projected,ids[#ids]),2.85*.66,'existing high-quality prior beyond source anchor')
                near(value(projected,ids[#ids-1]),2.85*.34,'existing next-quality prior beyond source anchor')
            end
            check(#projected.materials==#ids,'quality projection creates no missing material IDs')
            for _,material in ipairs(projected.materials)do
                if material.reviewedQualityProjected then
                    check(material.chance==nil and material.minQuantity==nil and material.maxQuantity==nil and material.probabilityVerified==false,'changed quality clears unsupported chance/range')
                    check(material.histogram==nil and material.quantityCounts==nil and material.personalHistogram==nil
                        and material.fieldEvidence==nil and material.samples==nil and material.castsWithDrop==nil,'changed quality clears unsupported count/histogram fields')
                end
            end
        end
        check(same(source,original),'normalization and forward projection preserve immutable source model')
        local saved=copy(baseline)
        LL:ProjectProfessionBaseline(baseline,params(era,.25),option)
        check(same(baseline,saved),'forward projection does not mutate compiled baseline/anchors')
    end
end end
-- Nonlinear midpoint curve is anchored, not an inverse of a universal .66 mix.
local source=model(dust,{1.6,.3,.1})
local b=assert(LL:NormalizeProfessionBaseline(source,params(10,.5),option))
local low=assert(LL:ProjectProfessionBaseline(b,params(10,.25),option))
near(value(low,dust[1]),1.8,'halfway zero to source anchor')
near(value(low,dust[2]),.15,'halfway zero to source anchor')
near(value(low,dust[3]),.05,'halfway zero to source anchor')
local high=assert(LL:ProjectProfessionBaseline(b,params(10,.75),option))
near(value(high,dust[1]),.8,'halfway source to high prior')
near(value(high,dust[2]),.49,'halfway source to high prior')
near(value(high,dust[3]),.71,'halfway source to high prior')
-- Complete families are required: an absent rank is not a measured zero.
local incomplete=model(dust,{1,1,0});incomplete.materials[3]=nil
local before=copy(incomplete)
local rejected,why=LL:NormalizeProfessionBaseline(incomplete,params(10,1),option)
check(rejected==nil and why:find('missing an explicit',1,true),'incomplete family fails closed')
check(same(before,incomplete),'incomplete source unchanged')
local pooled=model(dust,{1,1,0});pooled.materials[1].rankIDs={dust[1],dust[2]}
check(LL:NormalizeProfessionBaseline(pooled,params(10,.5),option)==nil,'rankIDs pooling never treated as exact ranks')
local duplicate=model(crystal,{1,1});duplicate.materials[3]=copy(duplicate.materials[1])
check(LL:NormalizeProfessionBaseline(duplicate,params(9,.4),option)==nil,'duplicate exact rank rejected')
local negative=model(crystal,{1,-.1})
check(LL:NormalizeProfessionBaseline(negative,params(10,.4),option)==nil,'invalid quantity rejected')
local override=model(dust,{1,.4,.6});override.reviewedQualityZeroShares={[dust[1]]={.2,.3,.5}}
local ob=assert(LL:NormalizeProfessionBaseline(override,params(10,.5),option))
local op=assert(LL:ProjectProfessionBaseline(ob,params(10,0),option))
for rank,id in ipairs(dust)do near(value(op,id),2*({.2,.3,.5})[rank],'explicit complete zero-quality override')end
local bad=copy(override);bad.reviewedQualityZeroShares[dust[1]]={.5,.5}
check(LL:NormalizeProfessionBaseline(bad,params(10,.5),option)==nil,'incomplete zero override rejected without renormalizing')
check(LL:NormalizeProfessionBaseline(override,params(10,0),option)==nil,'conflicting zero-source/zero-prior is unidentified')
local mismatch=params(10,.5);mismatch.relativeExtraOutputs[crystal[1]]=1
check(LL:NormalizeProfessionBaseline(model(crystal,{1,1}),mismatch,option)==nil,'rank-dependent source quantity mismatch fails closed')
-- Old records retain their old inverse/forward behavior without both opt-ins.
local legacy=model(crystal,{.8,1.2});legacy.reviewedBacklogModel=nil
check(LL:NormalizeProfessionBaseline(legacy,params(10,1),option)==nil,'old saturated-quality source is not silently reinterpreted')
legacy.reviewedBacklogModel=true;legacy.reviewedQualityProjection=nil
check(LL:NormalizeProfessionBaseline(legacy,params(10,1),option)==nil,'quality policy needs explicit opt-in flag')
local old=assert(LL:NormalizeProfessionBaseline(legacy,params(10,0),option))
local oldTarget=assert(LL:ProjectProfessionBaseline(old,params(10,1),option))
near(value(oldTarget,crystal[1]),.8,'old direct forward path unchanged')
check(old.reviewedQualityAnchors==nil and oldTarget.reviewedQualityProjected==nil,'old record gains no new quality flags')

-- Runtime compiler merge must carry quality anchors, and failure must reach the
-- existing requiresSourceNormalization guard rather than use max source as zero.
local nativeParameters=LL.ProfessionProfileParameters
LL.ProfessionProfileParameters=function(_,_,era,context)return params(era,context.progress or 0,context.factor or 1)end
local runtime=model(dust,{1.6,.3,.1});runtime.baselineProfile={progress=1,skill=200}
local compiled=assert(LL:NormalizeProfessionBaseline(runtime,params(10,1),option))
LL.ItemDB.modeledProfessionBaselines[runtime.recordID]=compiled
local target=LL:ApplyGeneralProfessionModel({id=222845,expansionID=10,quality=2,classID=4},option,runtime,{progress=.5})
near(value(target,dust[1]),1.8,'compiled quality metadata survives runtime merge')
near(value(target,dust[3]),.05,'compiled source anchor uses target progress')
check(target.reviewedQualityProjected and target.projectedContext and target.confidence==0,'runtime projection confidence/flag/context retained')
LL.ItemDB.modeledProfessionBaselines[runtime.recordID]=nil
local broken=model(dust,{1.6,.3,.1});broken.materials[3]=nil;broken.baselineProfile={progress=1,skill=200}
local blocked=LL:ApplyGeneralProfessionModel({id=222845,expansionID=10,quality=2,classID=4},option,broken,{progress=.1})
check(blocked.projectionIncomplete and not blocked.professionProjected,'unidentified reviewed source stays blocked')
check(same(blocked.materials,broken.materials),'blocked source quantities never converted to minimum baseline')
LL.ProfessionProfileParameters=nativeParameters
-- A qualitative 66/34 endpoint cannot downgrade a better reported source.
local highSource=model(dust,{.1,.1,1.8})
local highBase=assert(LL:NormalizeProfessionBaseline(highSource,params(10,.4),option))
local previousQuality=-1
for _,progress in ipairs({0,.2,.4,.6,.8,1})do
    local projected=assert(LL:ProjectProfessionBaseline(highBase,params(10,progress),option))
    local score=0 for rank,id in ipairs(dust)do score=score+rank*value(projected,id)end
    check(score>=previousQuality-1e-8,'increasing skill cannot downgrade a reviewed source quality mix')
    previousQuality=score
    near(total(projected,dust),2,'monotone quality prior conserves family quantity')
end
-- A source key can contain an already projected reviewed cohort and an
-- ordinary baseline. Only the ordinary contribution may move a second time.
local mixed={inputCount=1,generalProfessionApplied=true,
    generalProfessionParameters={skill=100,skillMaximum=200},
    generalProjectedSources={itemdb=true},materials={
        {id=dust[1],expectedQuantity=1.1,sourceContributions={itemdb=1},
            sourceEstimates={itemdb={inputCount=1,expectedQuantity=1.1,unprojectedQualityExpectedQuantity=.6}}},
        {id=dust[2],expectedQuantity=.4,sourceContributions={itemdb=1},
            sourceEstimates={itemdb={inputCount=1,expectedQuantity=.4,unprojectedQualityExpectedQuantity=.2}}},
        {id=dust[3],expectedQuantity=.5,sourceContributions={itemdb=1},
            sourceEstimates={itemdb={inputCount=1,expectedQuantity=.5,unprojectedQualityExpectedQuantity=.2}}}}}
local mixedBefore=copy(mixed)
local mixedProjected=LL:ApplyGeneralProfessionQuality({expansionID=10},option,mixed,{})
near(total(mixedProjected,dust),2,'mixed calibrated and ordinary cohorts conserve all units')
near(value(mixedProjected,dust[1]),.8,'reviewed low-rank term is not projected twice')
near(value(mixedProjected,dust[2]),.47,'only ordinary pool supplies middle-rank interpolation')
near(value(mixedProjected,dust[3]),.73,'only ordinary pool supplies high-rank interpolation')
check(same(mixed,mixedBefore),'mixed-source quality pass leaves cached source unchanged')
local neutral=copy(mixed);neutral.generalProfessionParameters.skill=0
check(same(LL:ApplyGeneralProfessionQuality({expansionID=10},option,neutral,{}),neutral),
    'zero bonus quality projection preserves every baseline field')
-- Processing uses native quality order (the higher ID is not necessarily the
-- higher rank), and its endpoint does not inherit the DE 66/34 prior.
local pigment={245865,245864}
LL.ItemDB.professionProfiles.qualityFamilies[pigment[1]]={rankItemIDs=pigment}
for rank,id in ipairs(pigment)do
    LL.ItemDB.professionProfiles.items[id]={subclassID=16,qualityFamilyID=pigment[1],qualityRank=rank}
end
for _,method in ipairs({'Mill','Prospect'})do
    local processingOption={name=method,inputCount=10}
    local function processingParams(progress,factor)
        local result=params(11,progress,factor);result.method=method
        result.profession=method=='Mill' and 'Inscription' or 'Jewelcrafting'
        return result
    end
    local reported=model(pigment,{0,13})
    local unchanged=assert(LL:NormalizeProfessionBaseline(reported,processingParams(0,1),processingOption))
    local projected=assert(LL:ProjectProfessionBaseline(unchanged,processingParams(0,1),processingOption))
    near(value(projected,pigment[2]),13,'zero bonuses preserve reported native R2 processing baseline')
    near(total(projected,pigment),13,'zero bonuses preserve processing family total')
    near(value(assert(LL:ProjectProfessionBaseline(unchanged,processingParams(1,1),processingOption)),pigment[2]),13,
        'processing high-quality prior cannot degrade an all-highest source')
    local mixedRanks=model(pigment,{3,7})
    local base=assert(LL:NormalizeProfessionBaseline(mixedRanks,processingParams(.4,1.2),processingOption))
    local roundTrip=assert(LL:ProjectProfessionBaseline(base,processingParams(.4,1.2),processingOption))
    near(value(roundTrip,pigment[1]),3,'processing source rank1 round trip')
    near(value(roundTrip,pigment[2]),7,'processing source rank2 round trip')
    local increased=assert(LL:ProjectProfessionBaseline(base,processingParams(1,1.5),processingOption))
    near(total(increased,pigment),10/1.2*1.5,'processing bonus applied once after source inverse')
    near(value(increased,pigment[2]),12.5,'processing endpoint routes all family units to highest rank')
    check(same(reported.materials,model(pigment,{0,13}).materials),'processing source remains immutable')
end
-- The real typed-profile reader crosses knowledge milestones before quality
-- redistribution. This deliberately small rule fixture verifies control
-- plumbing; it is not published coefficient or game-mechanics evidence.
local skillEffect={metric='skill',amount=1,unit='skill',confidence=0}
local milestone20={rank=20,effects={{metric='yieldMultiplier',amount=20,unit='percent',confidence=0}}}
local milestone30={rank=30,effects={{metric='yieldMultiplier',amount=30,unit='percent',confidence=0}}}
LL.ItemDB.professionProfiles.profiles['Enchanting:10']={nodes={[1]={maxRank=30,pointEffects={skillEffect},milestones={milestone20,milestone30}}},statKeys={}}
local function context(points)return {skill=100,preSpecializationSkill=100,baseSkillMaximum=100,specializationPoints={[1]=points}}end
local facts={id=222845,expansionID=10,quality=2,classID=4}
local sp=LL:ProfessionProfileParameters('Enchanting',10,context(30),option,facts)
near(sp.skill,130,'typed full source skill')
near(sp.skillMaximum,130,'scoped source maximum')
near(sp.outputFactor,1.5,'source quantity milestones combined once')
local sourceMilestone=model(dust,{1,.4,.6})
local canonical=assert(LL:NormalizeProfessionBaseline(sourceMilestone,sp,option))
local totals={}
for _,points in ipairs({19,20,30})do
    local tp=LL:ProfessionProfileParameters('Enchanting',10,context(points),option,facts)
    local output=assert(LL:ProjectProfessionBaseline(canonical,tp,option))
    totals[points]=total(output,dust)
    near(totals[points],2/1.5*tp.outputFactor,'actual typed milestone quantity preserved')
    near(value(output,dust[3]),totals[points]*(tp.skill/tp.skillMaximum)*.3,'actual skill control changes source-anchored quality')
end
check(totals[20]>totals[19] and totals[30]>totals[20],'milestones affect actual quantities alongside quality')
-- The actual item-tooltip renderer sees these projected quantities and fixture
-- prices. Its presentation does not create profession/recipe availability.
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
assert(loadfile('LootLiquidator/Badges.lua'))('LootLiquidator',LL)
LL.db={tooltipDetail=3,showAverageQuantity=true,showMaterialConfidence=true}
LL.MarkupColor=function()return ''end
LL.Money=function(_,amount)return ('%.3f copper'):format(amount)end
LL.ProfessionProgression=function()return {}end
local function rendered(points)
    local tp=LL:ProfessionProfileParameters('Enchanting',10,context(points),option,facts)
    local output=assert(LL:ProjectProfessionBaseline(canonical,tp,option))
    local worth=0
    for rank,material in ipairs(output.materials)do
        material.netExpectedValue=material.expectedQuantity*({100,200,500})[rank]
        worth=worth+material.netExpectedValue
    end
    local tip={lines={}}
    function tip:AddLine(line)self.lines[#self.lines+1]=line end
    function tip:AddDoubleLine(left,right)self.lines[#self.lines+1]=left..' | '..right end
    local shown={name='Disenchant',letter='D',profession='Enchanting',available=false,eligibleInput=true,value=worth,yieldModel=output}
    LL:AppendRecommendationTooltip(tip,{action='D',facts=facts,disenchantEligible=true,conversionOptions={shown},converted=worth})
    check(shown.available==false,'rendered quality does not grant profession/recipe access')
    return table.concat(tip.lines,'\n'),worth,output
end
local lowText,lowValue,lowModel=rendered(0)
local maxText,maxValue,maxModel=rendered(30)
check(lowText~=maxText and maxValue>lowValue,'skill/milestones change actual displayed quantities and fixture value')
check(maxText:find('Confidence 0%',1,true),'rendered source-anchor model uses confidence zero')
for _,material in ipairs(maxModel.materials)do
    local rate=material.chance or material.expectedQuantity
    local prefix=rate>1 and ('%.3fx'):format(rate) or rate==0 and '0%' or rate==1 and '100%'
        or rate<.001 and '<0.1%' or rate>.999 and '>99.9%'
        or ('%.1f'):format(rate*100):gsub('%.0$','')..'%'
    check(maxText:find(prefix..' ',1,true),'actual rank rate/count visible at the start of the tooltip row')
end
check(not maxText:find('estimate',1,true) and not maxText:find('provisional',1,true),'no extra tooltip uncertainty labels for source-anchor model')
print('PASS: '..checks..' source-anchored reviewed quality inverse/forward, conservation and runtime-merge checks')
