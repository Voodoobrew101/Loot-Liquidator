-- Exercise the real compiler and runtime accessor, not a hand-built runtime row.
-- All numeric values/conditions below are synthetic contract fixtures.
local count=0
local function check(v,msg) assert(v,msg);count=count+1 end
local function near(a,b) check(type(a)=='number' and math.abs(a-b)<1e-9,tostring(a)..' ~= '..tostring(b)) end
local function clone(t) if type(t)~='table' then return t end local out={} for k,v in pairs(t) do out[k]=clone(v) end return out end
local fixtureDir=assert(arg[1],'Pass a temporary output directory')
local originalLoadfile=loadfile
local originalArg=arg
local function field(v) return {value=v,status=v~=nil and 'measured' or 'unknown',confidence=v~=nil and 90 or 0,sampleOperations=100} end
local conditions={sourceContext='synthetic controlled study',effectiveSkill=50,skillLineID=171,
    specialization='none',minimumRecipeSkill=25,patchWindow={startBuild=200,endBuild=200}}
local function record(name,output)
    return {recordID=name,method='Prospect',inputItemID=10,inputCountPerOperation=5,inputQualityRank=2,
        outputItemID=output,recipeSpellID=444,expansionID=11,sources={'synthetic evidence'},conditions=clone(conditions),
        expectedQuantity=field(1),dropChance=field(.5),yieldMin=field(1),yieldMax=field(3)}
end
local function preview()
    return {dropChance=1,yieldMin=999,yieldMax=999,expectedQuantity=999,fieldConfidence={},confidence=0,
        status='PROVISIONAL',economicUse='PREVIEW_ONLY',modelID='synthetic-test',assumptions={},targetContext={},
        normalizedVerified=false,evidenceFieldsPreserved=true}
end
local research={schemaVersion='0.1.0',sourceManifest={compilerVersion='fixture'},
    processing={record('fixture:a',20),record('fixture:b',21)}}
local function compile()
    loadfile=function(path)
        if path=='database/research/itemdb.lua' then return function() return research end end
        return originalLoadfile(path)
    end
    arg={fixtureDir..'/FixtureItemDB.lua'}
    local ok,err=pcall(assert(originalLoadfile('tools/compile_itemdb.lua')))
    loadfile=originalLoadfile;arg=originalArg
    return ok,err
end
check(compile(),'schema 0.1.0 compiler fixture')
local function runtime()
    local LL={db={}}
    assert(originalLoadfile(fixtureDir..'/FixtureItemDB.lua'))('LootLiquidator',LL)
    assert(originalLoadfile('LootLiquidator/ProfessionModels.lua'))('LootLiquidator',LL)
    assert(originalLoadfile('LootLiquidator/Database.lua'))('LootLiquidator',LL)
    check(LL:InitializeItemDB(),LL.itemDBError);LL:MigrateEvidenceSettings()
    return LL
end
GetBuildInfo=function() return 'synthetic','200' end
local f={id=10,reagentQuality=2,expansionID=11}
local option={name='Prospect',inputCount=5,recipeID=444}
local ctx={inputQuality=2,effectiveSkill=50,skillLineID=171,specialization='none'}
local function model(LL,context,op,facts)
    return LL:ComputeEvidenceModel(facts or f,op or option,nil,1,context or ctx)
end
local LL=runtime()
local a,b=LL.ItemDB.processing[1],LL.ItemDB.processing[2]
check(a.referenceContextID==b.referenceContextID,'cooutputs share a typed reference profile')
check(a.referenceContextID:find('research%-context%-v1:')==1)
local m=assert(model(LL));check(#m.materials==2,'compiler-to-lookup retains both outputs')
near(m.materials[1].expectedQuantity,1);near(m.materials[2].expectedQuantity,1)
assert(originalLoadfile('LootLiquidator/ConversionEngine.lua'))('LootLiquidator',LL)
LL.GetOutputPrice=function() return 100 end
near(LL:ValueProcessingModel(m,0,true),40) -- (1+1)*100 / five ore
check(#m.materials==2,'valuation and tooltip consume the same complete material model')
-- The lexically first mapping may have no usable mean. It still belongs to
-- the profile, but cannot anchor or silently complete an economic estimate.
research.processing[1].expectedQuantity=field(nil)
check(compile(),'known and unknown cooutput compiler fixture')
local partial=runtime();local incomplete=assert(model(partial))
check(#incomplete.materials==2 and incomplete.unknownOutputs,'unknown cooutput remains in output universe')
check(incomplete.materials[1].expectedQuantity==nil and incomplete.warning~=nil)
assert(originalLoadfile('LootLiquidator/ConversionEngine.lua'))('LootLiquidator',partial)
partial.GetOutputPrice=function() return 100 end
check(partial:ValueProcessingModel(incomplete,0,true)==nil,'partial model cannot recommend processing')
near(incomplete.partialValue,20);check(incomplete.partialPrice,'known cooutput is a diagnostic lower bound')
research.processing[1].expectedQuantity=field(1)
local wrong=clone(ctx);wrong.inputQuality=1;check(model(LL,wrong)==nil,'input-rank mismatch')
wrong=clone(ctx);wrong.effectiveSkill=100;check(model(LL,wrong)==nil,'known skill mismatch')
wrong=clone(ctx);wrong.specialization='other';check(model(LL,wrong)==nil,'known specialization mismatch')
wrong=clone(ctx);wrong.skillLineID=nil;check(model(LL,wrong)==nil,'missing known skill-line context')
wrong=clone(ctx);wrong.skill=10;check(model(LL,wrong)==nil,'minimum base recipe skill requirement')
local op=clone(option);op.recipeID=445;check(model(LL,nil,op)==nil,'recipe mismatch')
GetBuildInfo=function() return 'synthetic','201' end
do -- A1: past the end of its patch window = stale, weighted down, not rejected
    local stale=model(LL);check(stale and stale.staleEvidence and stale.provisional,'patch-window mismatch is flagged stale')
end
GetBuildInfo=function() return 'synthetic','200' end
research.schemaVersion='0.2.0'
research.processing[1].workingEstimate=preview()
local unknown=record('fixture:preview-only',22);unknown.inputItemID=11
unknown.expectedQuantity=field(nil);unknown.dropChance=field(nil);unknown.yieldMin=field(nil);unknown.yieldMax=field(nil)
unknown.workingEstimate=preview();research.processing[3]=unknown
check(compile(),'schema 0.2.0 preview compiler fixture')
LL=runtime();m=assert(model(LL));near(m.materials[1].expectedQuantity,1)
check(#m.materials==2 and LL.ItemDB.buildReport.previewEstimatesPreserved==2)
near(LL.ItemDB.processing[1].researchRecord.workingEstimate.expectedQuantity,999)
local facts=clone(f);facts.id=11
-- A1 (owner decision 1): a working estimate fills a fully unknown record as a
-- low-confidence, flagged guess instead of hiding the answer.
local guessed=model(LL,nil,nil,facts)
check(guessed and guessed.workingEstimate and guessed.provisional,'working estimate gives a flagged answer')
near(guessed.materials[1].expectedQuantity,999);check(guessed.confidence<=10,'working estimate has low confidence')
-- ...but never overrides a real measured field (record a keeps its measured mean).
near(m.materials[1].expectedQuantity,1);check(not m.materials[1].workingEstimate)
research.processing[1].workingEstimate.economicUse='LIVE'
check(not compile(),'unsupported preview contract rejected')
research.processing[1].workingEstimate.economicUse='PREVIEW_ONLY';research.schemaVersion='99.0.0'
check(not compile(),'unknown research schema rejected')
-- An explicitly unknown historical reference remains visibly provisional.
research.schemaVersion='0.1.0';research.processing={record('fixture:unknown',20)}
research.processing[1].conditions={characterContext='REFERENCE_UNKNOWN',sourceContext='historical reference'}
check(compile());LL=runtime();m=assert(model(LL,{inputQuality=2}))
check(m.provisional and m.unverifiedReference,'unknown context is not relabeled as normalized')
-- Distinct observed contexts are never turned into one pool by the compiler.
research.processing={record('fixture:a',20),record('fixture:b',21)}
research.processing[2].conditions.effectiveSkill=100
check(compile());LL=runtime()
check(LL.ItemDB.processing[1].referenceContextID~=LL.ItemDB.processing[2].referenceContextID)
m=assert(model(LL));check(#m.materials==1 and m.materials[1].id==20)
-- Reviewed registry-format rules must reach the actual runtime adjustment path.
research.schemaVersion='0.2.0';research.processing={record('fixture:a',20),record('fixture:b',21)}
local approved={ruleID='synthetic-registry',profession='Jewelcrafting',method='Prospect',expansionID=11,
 effectTarget='OUTPUT_UNCONDITIONAL_EXPECTATION',formulaID='RATIO_ADJUSTMENT',parameters={referenceFactor=1,targetFactor=2},
 scope={gameMode='RETAIL',recipeSpellIDs={444},inputItemIDs={10},outputItemIDs={20,21},inputQualityRanks={2},nominalInputCount=5},
 referenceContext={build='200',effectiveSkill=50},targetContext={build='200',effectiveSkill=100},requiredLiveContext={'effectiveSkill'},
 evidenceStatus='VERIFIED_NUMERIC',applyPolicy='VERIFIED_FOR_COMPILE',numericTransformValidated=true,confidence0to100=94,
 sources={{claimID='synthetic-independent-a'},{claimID='synthetic-independent-b'}},
 independentReview={reviewer='synthetic-reviewer',passedTestIDs={'synthetic-only'}}}
research.mechanicRules={approved};check(compile(),'reviewed registry contract compiles')
LL=runtime();assert(originalLoadfile('LootLiquidator/ConversionEngine.lua'))('LootLiquidator',LL)
local adjusted=clone(ctx);adjusted.effectiveSkill=100
LL.ProcessingPlayerConditions=function()return adjusted end
m=assert(model(LL,adjusted));check(m.mechanicsApplied,'registry rule executes at runtime')
near(m.materials[1].expectedQuantity,2);near(m.materials[2].expectedQuantity,2)
near(research.processing[1].expectedQuantity.value,1)
check(#LL.ItemDB.mechanicRules==2,'scoped rule expands to both concrete output profiles')
approved.sources[2].claimID='synthetic-independent-a'
check(not compile(),'duplicate claims fail shared compiler evidence gate')
approved.sources[2].claimID='synthetic-independent-b'
approved.formulaID='UNSUPPORTED';check(not compile(),'unsupported approved rule fails build')
approved.formulaID='RATIO_ADJUSTMENT';approved.referenceContext.effectiveSkill=999
check(not compile(),'unmatched source baseline fails build')
approved.referenceContext.effectiveSkill=50;approved.applyPolicy='NO_NUMERIC_TRANSFORM'
check(not compile(),'unapproved exported rule rejected')
research.mechanicRules={}
-- Also check a genuine accepted multi-output profile from the shipped research
-- snapshot after compilation. This guards the production artifact, not just fixtures.
local actual={db={}}
assert(originalLoadfile(fixtureDir..'/ItemDBRuntime.lua'))('LootLiquidator',actual)
assert(originalLoadfile('LootLiquidator/Database.lua'))('LootLiquidator',actual)
check(actual:InitializeItemDB(),actual.itemDBError);actual:MigrateEvidenceSettings()
local groups={}
for _,r in ipairs(actual.ItemDB.processing) do
    if r.referenceContextID and r.materials[1].expectedQuantity.value~=nil then
        local g=groups[r.referenceContextID] or {};groups[r.referenceContextID]=g;g[#g+1]=r
    end
end
local verifiedActual=false
for _,rows in pairs(groups) do
    if #rows>=2 then
        local r=rows[1];local c=clone(r.referenceConditions);c.inputQuality=r.inputQualityRank
        local build=r.targetBuild or r.patchStartBuild or 200
        GetBuildInfo=function() return 'fixture',tostring(build) end
        local result=actual:ComputeEvidenceModel({id=r.inputItemID,reagentQuality=r.inputQualityRank,expansionID=r.expansionID},
            {name=r.method,inputCount=r.inputCount,recipeID=r.recipeID},nil,1,c)
        if result then
            local outputs={} for _,out in ipairs(result.materials) do outputs[out.id]=true end
            for _,row in ipairs(rows) do check(outputs[row.materials[1].id],'actual compiled cooutput lost') end
            verifiedActual=true;break
        end
    end
end
check(verifiedActual,'genuine compiled multi-output research profile was exercised')
print('PASS: '..count..' research compiler/profile/applicability/preview assertions')
