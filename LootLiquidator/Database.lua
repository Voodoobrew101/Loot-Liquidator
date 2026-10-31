-- Versioned evidence interface. No prices or live scans are cached here.
local _, LL = ...
-- Legacy (old disenchant tables) is on by default since A1: weak evidence counts
-- for less, it is not thrown away. Its low weight keeps it from outvoting ItemDB.
-- B2: the frozen TSM conversion source was removed; TSM gives AH prices only.
-- B7: results imported from other players are their own source (default weight 25).
local defaults={itemdb={true,100},personal={true,60},imported={true,25},legacy={true,10}}
-- Weak-evidence multipliers (owner decision 15: weight down, never reject).
local STALE_FACTOR=.25          -- pre-hotfix, obsolete or past its patch window
local UNKNOWN_CONFIDENCE=10     -- a value whose source gave no confidence figure
LL.SourceDefaults=defaults
local order={'itemdb','personal','imported','legacy'}
local sourcePriority={itemdb=1,personal=2,imported=3,legacy=4}
local methods={Mill=true,Prospect=true,Disenchant=true,Smelt=true}
local statuses={unknown=true,contradictory=true,verified=true,measured=true,observed=true,provisional=true,historical=true,modeled=true}
LL.SourceOrder=order
local function finite(n) return type(n)=='number' and n==n and n>=0 and n<math.huge end
local function copy(t) local out={} for k,v in pairs(t or {}) do out[k]=v end return out end
local function same(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in pairs(a) do if not same(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
-- C1a: counts-based (beta-binomial / empirical-Bayes) estimate. Every source is
-- expressed as casts and drops; a borrowed guess counts as PRIOR_CASTS casts;
-- weak sources are scaled down by their weight (never dropped); then
-- chance = drops / casts. Confidence = chance the true rate is within
-- +/- CONFIDENCE_BAND of the shown number (exact Beta probability).
LL.PRIOR_CASTS=20
LL.CONFIDENCE_BAND=.05
local function logGamma(x) -- Lanczos approximation, x>0
    local g={76.18009172947146,-86.50532032941677,24.01409824083091,
        -1.231739572450155,.1208650973866179e-2,-.5395239384953e-5}
    local y,tmp=x,x+5.5
    tmp=tmp-(x+.5)*math.log(tmp)
    local ser=1.000000000190015
    for i=1,6 do y=y+1;ser=ser+g[i]/y end
    return -tmp+math.log(2.5066282746310005*ser/x)
end
local function betaContinuedFraction(x,a,b)
    local qab,qap,qam=a+b,a+1,a-1
    local c,d=1,1-qab*x/qap
    if math.abs(d)<1e-30 then d=1e-30 end
    d=1/d
    local h=d
    for m=1,200 do
        local m2=2*m
        local aa=m*(b-m)*x/((qam+m2)*(a+m2))
        d=1+aa*d;if math.abs(d)<1e-30 then d=1e-30 end
        c=1+aa/c;if math.abs(c)<1e-30 then c=1e-30 end
        d=1/d;h=h*d*c
        aa=-(a+m)*(qab+m)*x/((a+m2)*(qap+m2))
        d=1+aa*d;if math.abs(d)<1e-30 then d=1e-30 end
        c=1+aa/c;if math.abs(c)<1e-30 then c=1e-30 end
        d=1/d
        local del=d*c;h=h*del
        if math.abs(del-1)<3e-12 then break end
    end
    return h
end
-- Regularized incomplete beta I_x(a,b): P(p<=x) for p ~ Beta(a,b).
function LL:BetaCDF(x,a,b)
    if not (finite(a) and finite(b)) or a<=0 or b<=0 then return nil end
    if x<=0 then return 0 elseif x>=1 then return 1 end
    local front=math.exp(logGamma(a+b)-logGamma(a)-logGamma(b)+a*math.log(x)+b*math.log(1-x))
    if x<(a+1)/(a+b+2) then return front*betaContinuedFraction(x,a,b)/a end
    return 1-front*betaContinuedFraction(1-x,b,a)/b
end
-- Confidence (0-100) that the true rate is within +/-band of drops/casts.
function LL:RateConfidence(drops,casts,band)
    band=band or LL.CONFIDENCE_BAND
    if not finite(drops) or not finite(casts) or casts<=0 then return 0 end
    drops=math.min(drops,casts)
    -- Half a count on each side (Jeffreys prior) so 0 drops in 2 casts is not
    -- "certain"; the shown rate stays drops/casts.
    local a,b=drops+.5,casts-drops+.5
    local mean=drops/casts
    local p=self:BetaCDF(math.min(1,mean+band),a,b)-self:BetaCDF(math.max(0,mean-band),a,b)
    return math.max(0,math.min(100,math.floor(p*100+.5)))
end
-- spec = {prior={chance=0.18, casts=20, label="Rank 1 ore"},
--         sources={{casts=50, drops=12, weight=1, key="personal"}, ...}}
-- A source may give {casts, chance} instead of drops. weight (0-1) scales its
-- casts and drops: weak or old evidence counts for less, never nothing.
function LL:CountsEstimate(spec)
    spec=spec or {}
    local casts,drops,real=0,0,0
    local prior=spec.prior
    if prior and finite(prior.chance) and prior.chance<=1 then
        local n=finite(prior.casts) and prior.casts or LL.PRIOR_CASTS
        casts,drops=n,prior.chance*n
    else prior=nil end
    local used={}
    for _,src in ipairs(spec.sources or {}) do
        local n,w=src.casts,src.weight
        if w==nil then w=1 end
        local d=src.drops
        if d==nil and finite(src.chance) and src.chance<=1 and finite(n) then d=src.chance*n end
        if finite(n) and n>0 and finite(d) and d<=n and finite(w) and w>0 then
            casts=casts+n*w;drops=drops+d*w;real=real+n*w
            used[#used+1]=src.key or src.source or #used+1
        end
    end
    if casts<=0 then return nil end
    return {chance=drops/casts,casts=casts,drops=drops,realCasts=real,
        confidence=self:RateConfidence(drops,casts),sourcesUsed=used,
        estimatedFrom=(real==0 and prior and prior.label) and ("Estimated from "..prior.label) or nil,
        priorOnly=real==0}
end
-- Fill one missing figure from the other (owner study notes): average ~= chance x
-- middle of the range, chance ~= average / middle of the range. Returns
-- chance, average, filled ("chance" / "average" / nil). Filled figures should be
-- shown with lower confidence (see FILLED_CONFIDENCE_FACTOR).
LL.FILLED_CONFIDENCE_FACTOR=.5
function LL:FillChanceOrAverage(chance,average,minQuantity,maxQuantity)
    local lo,hi=minQuantity,maxQuantity
    if not finite(lo) and finite(hi) then lo=hi end
    if not finite(hi) and finite(lo) then hi=lo end
    local middle=(finite(lo) and finite(hi)) and (lo+hi)/2 or nil
    if finite(chance) and not finite(average) and middle then return chance,chance*middle,'average' end
    if finite(average) and not finite(chance) and middle and middle>0 then
        return math.min(1,average/middle),average,'chance'
    end
    return chance,average,nil
end
function LL:MigrateEvidenceSettings()
    if not self.db then return end
    -- B2: the frozen TSM source is gone; drop its saved switches quietly.
    for _,k in ipairs({'source_itemtsm_enabled','source_itemtsm_weight','source_tsm_enabled','source_tsm_weight','frozenTSMMigrated'}) do
        self.db[k]=nil
    end
    -- Materialize the old global policy once, so later per-method changes work
    -- without a hidden legacy selector overriding the visible weighted choice.
    if not self.db.evidenceSchemaVersion then
        local old=self.db.processingFallbackMode
        for _,name in ipairs({'disenchantDataMode','millingDataMode','prospectingDataMode','otherConversionDataMode'}) do
            if self.db[name]==nil or self.db[name]==1 then
                if old==2 then self.db[name]=3 elseif old==3 then self.db[name]=2 end
            end
        end
    end
    -- Additive migration: retain old preferences and all observations.
    for key,d in pairs(defaults) do
        local enabled,weight='source_'..key..'_enabled','source_'..key..'_weight'
        if self.db[enabled]==nil then self.db[enabled]=d[1] end
        if self.db[weight]==nil then self.db[weight]=d[2] end
    end
    -- Schema 2 (A1): legacy disenchant tables were off by default and hid most
    -- disenchant answers. Turn them on once; a later manual choice is respected.
    if self.db.evidenceSchemaVersion==1 and self.db.source_legacy_enabled==false then
        self.db.source_legacy_enabled=true
    end
    self.db.evidenceSchemaVersion=2
end
function LL:SetEvidenceSource(key,enabled,weight)
    if not defaults[key] or not self.db then return false end
    if enabled~=nil then self.db['source_'..key..'_enabled']=enabled==true end
    if weight~=nil then
        if not finite(weight) then return false end
        self.db['source_'..key..'_weight']=math.max(0,math.min(100,weight))
    end
    if self.Invalidate then self:Invalidate("evidence") end
    return true
end
function LL:ResetEvidenceSources()
    for key,d in pairs(defaults) do self:SetEvidenceSource(key,d[1],d[2]) end
end
function LL:ValidateItemDB(db)
    if type(db)~='table' or db.schemaVersion~=1 or type(db.processing)~='table' then
        return false,'Unsupported itemdb schema'
    end
    local ids={}
    for _,r in ipairs(db.processing) do
        if type(r)~='table' or type(r.recordID)~='string' or r.recordID=='' or ids[r.recordID] or not methods[r.method]
            or not (defaults[r.sourceKey] or r.sourceKey=='tsm') or not finite(r.inputCount) or r.inputCount<=0 or r.inputCount%1~=0
            or (not (finite(r.inputItemID) and r.inputItemID>0 and r.inputItemID%1==0)
                and not (r.method=='Disenchant' and type(r.gearKey)=='string' and
                    (r.gearKey:match('^gear:%d+:%d+:armor$') or r.gearKey:match('^gear:%d+:%d+:weapon$'))))
            or (r.recipeID~=nil and (not finite(r.recipeID) or r.recipeID<1 or r.recipeID%1~=0))
            or (r.referenceConditions~=nil and type(r.referenceConditions)~='table')
            or (r.referenceContextID~=nil and type(r.referenceContextID)~='string')
            or (r.patchStartBuild~=nil and not finite(r.patchStartBuild))
            or (r.patchEndBuild~=nil and not finite(r.patchEndBuild))
            or (r.minimumRecipeSkill~=nil and not finite(r.minimumRecipeSkill))
            or (r.samples~=nil and not finite(r.samples))
            or type(r.studyID)~='string' or type(r.source)~='string'
            or type(r.materials)~='table' then return false,'Invalid or duplicate record identity' end
        ids[r.recordID]=true
        local outputs={}
        for _,m in ipairs(r.materials) do
            if not finite(m.id) or m.id<=0 or m.id%1~=0 or outputs[m.id] then return false,'Invalid output identity' end
            outputs[m.id]=true
            for _,name in ipairs({'expectedQuantity','dropChance','minQuantity','maxQuantity'}) do
                local f=m[name]
                if type(f)~='table' or not statuses[f.status] or not finite(f.confidence) or f.confidence>100
                    or (f.value~=nil and not finite(f.value)) then return false,'Invalid field '..name end
            end
            local p,e,lo,hi=m.dropChance.value,m.expectedQuantity.value,m.minQuantity.value,m.maxQuantity.value
            if (p and p>1) or (lo and (lo<1 or lo%1~=0)) or (hi and (hi<1 or hi%1~=0))
                or (lo and hi and lo>hi) or (e==0 and p and p>0)
                or (e and p and lo and hi and (e+1e-9<p*lo or e>p*hi+1e-9)) then
                return false,'Contradictory probability/quantity fields'
            end
        end
    end
    return true
end
-- Token relationships have their own evidence contract. They describe possible
-- rewards, never drop probabilities or crafting/profession yield coefficients.
function LL:ValidateTokenCatalog(records)
    if records==nil then return true end
    if type(records)~='table' then return false,'Invalid token catalog' end
    local seen,windows={},{}
    local function positive(n) return finite(n) and n>0 and n%1==0 end
    local function array(t)
        if type(t)~='table' then return false end
        for key in pairs(t) do if not positive(key) or key>#t then return false end end
        return true
    end
    if not array(records) then return false,'Token catalog must be an array' end
    for _,r in ipairs(records) do
        if type(r)~='table' or type(r.recordID)~='string' or r.recordID=='' or seen[r.recordID]
            or not positive(r.tokenID) or (r.kind~='open' and r.kind~='exchange') or r.gameMode~='Retail'
            or not finite(r.inputClassID) or r.inputClassID>20 or r.inputClassID%1~=0 or r.inputClassID==7
            or r.evidenceStatus~='VERIFIED_RELATIONSHIP' or r.independentReview~='APPROVED'
            or type(r.reviewedBy)~='string' or r.reviewedBy=='' or r.listComplete~=true
            or r.requirementsReviewed~=true or type(r.requirements)~='table' or next(r.requirements)
            or not finite(r.confidence0to100) or r.confidence0to100<90 or r.confidence0to100>100
            or not positive(r.patchStartBuild) or not positive(r.patchEndBuild) or r.patchStartBuild>r.patchEndBuild
            or type(r.sourceRevision)~='string' or r.sourceRevision==''
            or not array(r.sourceURLs) or #r.sourceURLs<2 or not array(r.rewards) or #r.rewards==0 or #r.rewards>500
            or r.expectedQuantity~=nil or r.dropChance~=nil or r.probability~=nil then
            return false,'Token catalog requires complete reviewed relationships, explicit scope and provenance'
        end
        seen[r.recordID]=true
        local urls={}
        for _,url in ipairs(r.sourceURLs) do
            if type(url)~='string' or not url:match('^https://%S+$') or urls[url] then return false,'Invalid token evidence sources' end
            urls[url]=true
        end
        if r.sourceOrigin=='ATT' and (r.licenseSPDX~='MIT' or type(r.licenseText)~='string'
            or not r.licenseText:find('Permission is hereby granted',1,true)
            or not r.licenseText:find('AllTheThings',1,true)) then return false,'ATT-derived catalog requires its license attribution' end
        local prior=windows[r.tokenID] or {}
        for _,window in ipairs(prior) do
            if r.patchStartBuild<=window[2] and r.patchEndBuild>=window[1] then return false,'Overlapping token catalog scope' end
        end
        prior[#prior+1]={r.patchStartBuild,r.patchEndBuild};windows[r.tokenID]=prior
        local rewards={}
        for _,id in ipairs(r.rewards) do
            if not positive(id) or id==r.tokenID or rewards[id] then return false,'Invalid token reward identity' end
            rewards[id]=true
            if r.kind=='exchange' then
                local costs=type(r.costs)=='table' and r.costs[tostring(id)]
                if not array(costs) or #costs==0 then return false,'Exchange reward requires complete costs' end
                local hasToken=false
                for _,cost in ipairs(costs) do
                    if type(cost)~='table' or not positive(cost.quantity)
                        or (cost.kind~='money' and ((cost.kind~='item' and cost.kind~='currency') or not positive(cost.id))) then
                        return false,'Unsupported token exchange cost'
                    end
                    if cost.kind=='item' and cost.id==r.tokenID then hasToken=true end
                end
                if not hasToken then return false,'Exchange cost does not contain its token' end
            end
        end
    end
    return true
end
function LL:InitializeItemDB()
    self._processingModelCache=nil
    self._tokenRewardIndex={}
    local ok,reason=self:ValidateItemDB(self.ItemDB)
    if ok and self.ValidateProfessionRules then ok,reason=self:ValidateProfessionRules(self.ItemDB) end
    if ok then ok,reason=self:ValidateTokenCatalog(self.ItemDB.tokenRewards) end
    self.itemDBError=not ok and reason or nil
    self._evidenceIndex={}
    self._researchRecipeOperations={}
    if not ok then return false end
    for _,r in ipairs(self.ItemDB.tokenRewards or {}) do
        local list=self._tokenRewardIndex[r.tokenID] or {}
        list[#list+1]=r;self._tokenRewardIndex[r.tokenID]=list
    end
    local all={}
    for _,dataset in ipairs({self.ItemDB,self.LegacyDB or {}}) do
        if dataset~=self.ItemDB and dataset.processing then
            local valid,why=self:ValidateItemDB(dataset)
            if not valid then self.itemDBError=why;return false end
        end
        for _,r in ipairs(dataset.processing or {}) do all[#all+1]=r end
    end
    for _,r in ipairs(all) do
        local key=r.method..':'..tostring(r.inputItemID or r.gearKey)
        local list=self._evidenceIndex[key] or {};self._evidenceIndex[key]=list
        list[#list+1]=r
        if r.sourceKey=='itemdb' and r.inputItemID and r.recipeID
            and (r.method=='Mill' or r.method=='Prospect' or r.method=='Smelt') then
            local recipes=self._researchRecipeOperations[r.recipeID] or {}
            recipes[#recipes+1]=r;self._researchRecipeOperations[r.recipeID]=recipes
        end
    end
    local compat=self.ItemDB.compat or {}
    for k,v in pairs(compat) do self[k]=v end -- aliases, never copied data
    self.GameData=self.GameData or {}
    self.GameDataVersion=self.ItemDB.version
    self.ResearchProcessingOutputs=self.ItemDB.inputs
    return true
end
function LL:ResearchProcessingInput(id)
    return self.ItemDB and self.ItemDB.inputs and self.ItemDB.inputs[id]
end
-- Recorder lookup shares the same admitted primary operation records as
-- valuation discovery. Disabled yield sources do not disable raw capture.
function LL:ResearchProcessingRecipeOperations(recipeID)
    return self._researchRecipeOperations and self._researchRecipeOperations[recipeID]
end
-- Operation identities are metadata, independent of source weights. A single
-- herb/ore can have several recipes with different batch sizes; do not replace
-- a recorded mass-processing recipe with a generic five-input spell.
function LL:ResearchProcessingOperations(f)
    local operations,seen={},{}
    for _,method in ipairs({'Mill','Prospect','Smelt'}) do
        for _,r in ipairs(self._evidenceIndex and self._evidenceIndex[method..':'..tostring(f.id)] or {}) do
            if r.sourceKey=='itemdb' and r.recipeID and (not r.expansionID or r.expansionID==f.expansionID)
                and (not r.inputQualityRank or r.inputQualityRank==f.reagentQuality) then
                local key=method..':'..r.recipeID..':'..r.inputCount
                if not seen[key] then
                    seen[key]=true
                    operations[#operations+1]={method=method,recipeID=r.recipeID,requiredSpell=r.recipeID,
                        inputCount=r.inputCount,profession=r.profession,source=r.source}
                end
            end
        end
    end
    table.sort(operations,function(a,b)
        if a.method~=b.method then return a.method<b.method end
        if a.recipeID~=b.recipeID then return a.recipeID<b.recipeID end
        return a.inputCount<b.inputCount
    end)
    return operations
end
-- A confidence score is an ordinal evidence-quality score, not a posterior.
-- Sample saturation and provenance class are independent conservative discounts.
function LL:EvidenceReliability(field,record)
    if not field or field.value==nil or field.status=='unknown' or field.status=='contradictory' then return 0 end
    -- A value with no stated confidence is weak, not worthless (owner decision 1).
    local stated=finite(field.confidence) and field.confidence>0 and field.confidence or UNKNOWN_CONFIDENCE
    local score=math.min(1,stated/100)
    local n=field.samples or record.samples
    local sampleFactor=finite(n) and n/(n+30) or 0.35
    local class=({verified=1,measured=1,observed=1,provisional=.6,modeled=.25,historical=.4})[field.status] or 0
    return score*sampleFactor*class
end
-- C1b: how many casts a drop-chance figure is worth in the counts model.
-- A real count (field.samples, else record.samples) is used as is. A figure with
-- no count is a guess worth at most PRIOR_CASTS casts, scaled by its stated
-- confidence and evidence class (the "no samples" discount in
-- EvidenceReliability is not applied again: the small count already says it).
function LL:EvidenceCasts(field,record)
    if not field or field.value==nil or field.status=='unknown' or field.status=='contradictory' then return 0,false end
    local n=field.samples or (record and record.samples)
    if finite(n) and n>0 then return n,true end
    local stated=finite(field.confidence) and field.confidence>0 and field.confidence or UNKNOWN_CONFIDENCE
    local class=({verified=1,measured=1,observed=1,provisional=.6,modeled=.25,historical=.4})[field.status] or 0
    return LL.PRIOR_CASTS*math.min(1,stated/100)*class,false
end
local function gearKey(f)
    return 'gear:'..tostring(f.expansionID)..':'..tostring(f.quality)..':'..
        (f.classID==2 and 'weapon' or 'armor')
end
-- Returns eligible, stale. Stale evidence (pre-hotfix, obsolete, or past the end
-- of its patch window) still counts, at STALE_FACTOR weight and lower confidence.
local function contextEligible(record,ctx,build,model,rules)
    if model and model.projectionIncomplete then return false end
    if record.mechanicsSourceBuild and tostring(record.mechanicsSourceBuild)~=tostring(build) and not (model and model.mechanicsApplied) then return false end
    if record.targetBuild and tostring(record.targetBuild)~=tostring(build) then return false end
    if record.patchStartBuild and (not tonumber(build) or tonumber(build)<record.patchStartBuild) then return false end
    local stale=record.obsolete or record.hotfixBlocked
        or (record.patchEndBuild and (not tonumber(build) or tonumber(build)>record.patchEndBuild)) or false
    if record.minimumRecipeSkill~=nil then
        local skill=ctx.skill or ctx.baseSkill or ctx.effectiveSkill
        if not finite(skill) or skill<record.minimumRecipeSkill then return false end
    end
    for key,v in pairs(record.referenceConditions or {}) do
        if not same(ctx[key],v) then
            if not model or not model.mechanicsApplied then return false end
            for _,material in ipairs(model.materials) do
                if material.expectedQuantity~=nil then
                    local covered=model.professionProjected and material.appliedProfessionRule
                        and model.projectedContext and same(model.projectedContext[key],ctx[key]) or false
                    for _,rule in ipairs(rules or {}) do
                        if rule.ruleID==material.appliedExpectationRule and type(rule.targetConditions)=='table'
                            and same(rule.targetConditions[key],ctx[key]) then covered=true end
                    end
                    if not covered then return false end
                end
            end
        end
    end
    return true,stale
end
local function userWeight(self,key,mode)
    local d=defaults[key]
    if not d then return 0 end
    if (mode==2 and key~='personal') or (mode==3 and key=='personal') then return 0 end
    local enabled=self.db and self.db['source_'..key..'_enabled']
    if enabled==nil then enabled=d[1] end
    if not enabled then return 0 end
    local w=self.db and self.db['source_'..key..'_weight']
    if w==nil then w=d[2] end
    return finite(w) and math.min(100,w)/100 or 0
end
local function sourceModel(self,f,option,r)
    local model={inputCount=r.inputCount,patchBuild=r.patchBuild,referenceContextID=r.referenceContextID,
        sourceKey=r.sourceKey,baselineProfile=r.baselineProfile,baselineStatus=r.baselineStatus,
        duration=r.duration,expectedInputCount=r.expectedInputCount,materials={},source=r.source,
        referenceApplicability=r.referenceApplicability,
        adjustment=(r.baselineStatus or r.referenceApplicability=='unverified-reference')
            and 'provisional source estimate / baseline not normalized' or nil}
    for _,m in ipairs(r.materials) do
        model.materials[#model.materials+1]={id=m.id,expectedQuantity=m.expectedQuantity.value,
            chance=m.dropChance.value,probabilityVerified=m.dropChance.status=='verified' or m.dropChance.status=='measured',
            minQuantity=m.minQuantity.value,maxQuantity=m.maxQuantity.value}
    end
    if r.sourceKey~='itemdb' then return model end
    if self.ApplyProfessionModel then model=self:ApplyProfessionModel(f,option,model) end
    if model.professionProjected then return model end
    local verified=self.ApplyVerifiedMechanics and self:ApplyVerifiedMechanics(f,option,model) or model
    if verified~=model and verified.mechanicsApplied then verified.adjustment='character-adjusted' end
    return verified
end
function LL:ComputeEvidenceModel(f,option,personal,mode,ctx)
    local build=GetBuildInfo and select(2,GetBuildInfo())
    local records={}
    local function include(input)
        for _,record in ipairs(self._evidenceIndex and self._evidenceIndex[option.name..':'..tostring(input)] or {}) do
            records[#records+1]=record
        end
        for _,record in ipairs(self.ImportedEvidenceRecords and self:ImportedEvidenceRecords(option.name..':'..tostring(input)) or {}) do
            records[#records+1]=record
        end
    end
    include(f.id) -- reviewed research may identify a specific gear item
    if option.name=='Disenchant' then include(gearKey(f)) end
    local eligible,transformed,hasExpected,staleRecord={},{},{},{}
    for _,r in ipairs(records) do
        local hasMean=false
        for _,material in ipairs(r.materials) do
            if self:EvidenceReliability(material.expectedQuantity,r)>0 then hasMean=true;break end
        end
        local model=sourceModel(self,f,option,r)
        transformed[r]=model
        hasExpected[r]=hasMean
        -- Applicability defines the output universe. An unknown expectation must
        -- remain an unknown cooutput rather than disappear as if impossible.
        if userWeight(self,r.sourceKey,mode)>0 and (not r.recipeID or r.recipeID==option.recipeID)
            and (not r.inputQualityRank or r.inputQualityRank==ctx.inputQuality)
            and (not r.expansionID or r.expansionID==f.expansionID) then
            local ok,stale=contextEligible(r,ctx,build,model,self.ItemDB.mechanicRules)
            if ok then eligible[#eligible+1]=r;staleRecord[r]=stale or nil end
        end
    end
    if personal and personal.observationContext and ctx.simulated and self.ProjectPersonalEstimate then
        personal=self:ProjectPersonalEstimate(f,option,personal,ctx,build)
    end
    if personal and personal.observationContext and ((ctx.simulated and not personal.professionProjected)
        or ctx.character~=personal.observationContext.character) then
        personal=nil
    end
    if personal and userWeight(self,'personal',mode)>0 and (personal.effectiveSamples or 0)>0 then
        local r={recordID='personal',sourceKey='personal',studyID=personal.studyID or ('personal:'..tostring(ctx.character)),
            source='Personal recorded results',inputCount=personal.inputCount or option.inputCount or 1,
            samples=personal.effectiveSamples,referenceConditions=copy(ctx),
            referenceContextID=personal.referenceContextID,patchBuild=personal.patchBuild,expectedInputCount=personal.expectedInputCount,
            materials={},fixedReference=personal.professionProjected,
            provisional=personal.professionProjected or (personal.effectiveSamples or 0)<(self.ProcessingMinimum and self:ProcessingMinimum() or 30)}
        for _,m in ipairs(personal.materials or {}) do
            r.materials[#r.materials+1]={id=m.id,quality=m.quality,rarity=m.rarity,
                expectedQuantity={value=m.expectedQuantity,confidence=85,status='observed'},
                dropChance={value=m.chance,confidence=85,status='observed'},
                minQuantity={value=m.minQuantity,confidence=85,status='observed'},
                maxQuantity={value=m.maxQuantity,confidence=85,status='observed'},
                personalHistogram=m.quantityCounts,personalSamples=m.samples}
        end
        if #r.materials>0 then
            eligible[#eligible+1]=r
            for _,material in ipairs(r.materials) do
                if self:EvidenceReliability(material.expectedQuantity,r)>0 then hasExpected[r]=true;break end
            end
            if personal.professionProjected then
                transformed[r]={inputCount=r.inputCount,materials=personal.materials,sourceKey='personal',
                    mechanicsApplied=true,adjustment=personal.adjustment,projectionRules=personal.projectionRules}
            end
        end
    end
    -- Primary database first, then an independent measured personal context.
    -- Incompatible/unknown historical contexts are never silently pooled.
    table.sort(eligible,function(a,b)
        if sourcePriority[a.sourceKey]~=sourcePriority[b.sourceKey] then
            return sourcePriority[a.sourceKey]<sourcePriority[b.sourceKey]
        end
        return a.recordID<b.recordID
    end)
    -- The anchor fixes the reference context. Within the best source, pick the
    -- strongest evidence so a low-confidence guess (working estimate or stale
    -- record) can never push real measurements of another context out.
    local anchor,anchorStrength
    for _,r in ipairs(eligible) do
        if hasExpected[r] and (not anchor or sourcePriority[r.sourceKey]==sourcePriority[anchor.sourceKey]) then
            local strength=0
            for _,material in ipairs(r.materials) do
                strength=math.max(strength,self:EvidenceReliability(material.expectedQuantity,r))
            end
            if staleRecord[r] then strength=strength*STALE_FACTOR end
            if not anchor or strength>anchorStrength then anchor,anchorStrength=r,strength end
        end
    end
    if not anchor then
        local enabled=false
        for _,r in ipairs(records) do if userWeight(self,r.sourceKey,mode)>0 then enabled=true end end
        local why=#records==0 and 'No researched yield record for this item'
            or not enabled and 'Matching yield sources are disabled by Database & Accuracy / Observation policy'
            or #eligible==0 and 'Yield records do not match this recipe, patch or character context'
            or 'Matching yield records have no usable expected quantities'
        return nil,'Insufficient Data: '..why
    end
    local batch=option.inputCount or anchor.inputCount
    local result={kind='weighted-evidence',inputCount=batch,materials={},sources={},
        source='Weighted evidence',context=ctx,adjustment='baseline / unadjusted',
        provisional=false,confidence=0,excludedSources={},unknownOutputs=false}
    if anchor.sourceKey=='personal' and personal and personal.observationContext then
        result.context=copy(personal.observationContext)
        result.provisional=true
        result.confidenceUnscored=true -- capture quality weights are not scientific review
        result.adjustment='measured character context / unadjusted'
    end
    local bins,studySeen={},{}
    local function sameContext(r)
        if r==anchor then return true end
        return r.referenceContextID and r.referenceContextID==anchor.referenceContextID
            and r.patchBuild==anchor.patchBuild and same(r.referenceConditions,anchor.referenceConditions)
    end
    for _,r in ipairs(eligible) do
        if not sameContext(r) and not r.fixedReference then
            result.excludedSources[#result.excludedSources+1]=r.sourceKey..': reference context cannot be normalized'
        else
            -- Build a model, then apply the preserved PR #4 adapter exactly once.
            local model=transformed[r] or sourceModel(self,f,option,r)
            if r==anchor and model.adjustment then result.adjustment=model.adjustment end
            if model.referenceApplicability=='unverified-reference' then result.unverifiedReference=true end
            if r==anchor and model.expectedInputCount~=nil then
                result.expectedInputCount=model.expectedInputCount*batch/r.inputCount
            end
            if model.mechanicsApplied then
                result.adjustment=model.adjustment or 'character-adjusted';result.mechanicsApplied=true
                if r==anchor then
                    result.expectedInputCount=model.expectedInputCount and model.expectedInputCount*batch/r.inputCount
                    result.duration=model.duration
                end
            end
            for i,m in ipairs(model.materials) do
                local original=r.materials[i]
                local id=m.id
                local b=bins[id] or {id=id,quality=original.quality,rarity=original.rarity,
                    fields={},contributions={},sourceEstimates={}};bins[id]=b
                b.sourceEstimates[r.sourceKey]={expectedQuantity=m.expectedQuantity,dropChance=m.chance,
                    minQuantity=m.minQuantity,maxQuantity=m.maxQuantity,sourceConflict=original.sourceConflict,
                    inputCount=r.inputCount,originalTSM=original.originalTSM,
                    appliedRule=m.appliedProfessionRule or m.appliedExpectationRule}
                for field,modelField in pairs({expectedQuantity='expectedQuantity',dropChance='chance'}) do
                    local key=r.studyID..':'..id..':'..field
                    local metadata=copy(original[field]);metadata.value=m[modelField]
                    if m.transformConfidence then metadata.confidence=math.min(metadata.confidence,m.transformConfidence) end
                    local weight=userWeight(self,r.sourceKey,mode)*self:EvidenceReliability(metadata,r)
                    -- Legacy now blends in at its (low) source weight instead of only filling gaps.
                    if staleRecord[r] then
                        weight=weight*STALE_FACTOR
                        metadata.confidence=math.floor((metadata.confidence or 0)*.5+.5)
                    end
                    -- A per-cast chance for another batch size is a different quantity
                    -- (not a weak version of this one); the mean still converts.
                    if field=='dropChance' and r.inputCount~=batch then weight=0 end
                    if weight>0 and not studySeen[key] then
                        studySeen[key]=true
                        local v=m[modelField]
                        if field=='expectedQuantity' then v=v*batch/r.inputCount end
                        local acc=b.fields[field] or {sum=0,weight=0};b.fields[field]=acc
                        acc.minimum=math.min(acc.minimum or v,v);acc.maximum=math.max(acc.maximum or v,v)
                        acc.sum=acc.sum+v*weight;acc.weight=acc.weight+weight
                        if field=='expectedQuantity' then
                            local c=(metadata.confidence or 0)>0 and metadata.confidence or UNKNOWN_CONFIDENCE
                            acc.confidence=(acc.confidence or 0)+c*weight
                        end
                        if metadata.workingEstimate then b.workingEstimate=true;result.workingEstimate=true;result.provisional=true end
                        if staleRecord[r] then b.staleEvidence=true;result.staleEvidence=true;result.provisional=true end
                        if field=='expectedQuantity' then
                            b.contributions[r.sourceKey]=(b.contributions[r.sourceKey] or 0)+weight
                            result.provisional=result.provisional or r.provisional==true
                            if mode==2 and r.sourceKey=='personal' and r.provisional then result.insufficientSamples=true end
                        elseif field=='dropChance' then
                            b.chanceProvisional=b.chanceProvisional or metadata.status=='provisional'
                                or metadata.status=='modeled' or metadata.status=='historical'
                            -- C1b: the chance becomes casts and drops for the counts model,
                            -- scaled by the source weight (and STALE_FACTOR when stale).
                            local casts=self:EvidenceCasts(metadata,r)
                            local w=userWeight(self,r.sourceKey,mode)*(staleRecord[r] and STALE_FACTOR or 1)
                            if casts>0 and v<=1 then
                                b.chanceSources=b.chanceSources or {}
                                b.chanceSources[#b.chanceSources+1]={casts=casts,chance=v,weight=w,key=r.sourceKey}
                                b.chanceContributions=b.chanceContributions or {}
                                b.chanceContributions[r.sourceKey]=(b.chanceContributions[r.sourceKey] or 0)+casts*w
                            end
                        end
                    end
                end
                if original.personalHistogram then
                    b.personalHistogram=original.personalHistogram;b.personalSamples=original.personalSamples
                end
                -- Conditional bounds belong to one named source, never an average.
                local lo,hi=m.minQuantity,m.maxQuantity
                if not b.boundsSource and lo and hi and r.inputCount==batch
                    and self:EvidenceReliability(original.minQuantity,r)>0
                    and self:EvidenceReliability(original.maxQuantity,r)>0 then
                    b.minQuantity=lo;b.maxQuantity=hi;b.boundsSource=r.source
                end
            end
        end
    end
    local totalContribution,confidenceTotal=0,0
    for _,b in pairs(bins) do
        local e,p=b.fields.expectedQuantity,b.fields.dropChance
        b.expectedQuantity=e and e.sum/e.weight
        if e and e.maximum>math.max(1e-9,e.minimum*2) then
            b.conflictingMeans=true;result.conflictingMeans=true
        end
        -- Batch normalization rescales means, not occurrence distributions.
        -- C1b: drop chance = weighted drops / weighted casts (LL:CountsEstimate),
        -- with its confidence; falls back to the plain blend if no casts are known.
        local counts=b.chanceSources and self:CountsEstimate({sources=b.chanceSources})
        if counts then
            b.chance=counts.chance;b.chanceCasts=counts.casts;b.chanceConfidence=counts.confidence
        else
            b.chance=p and p.sum/p.weight
        end
        if b.chance and b.expectedQuantity and b.minQuantity and b.maxQuantity
            and (b.expectedQuantity+1e-9<b.chance*b.minQuantity or b.expectedQuantity>b.chance*b.maxQuantity+1e-9) then
            b.minQuantity=nil;b.maxQuantity=nil;b.boundsSource=nil
        end
        local stated=e and math.min(100,math.floor((e.confidence or 0)/e.weight+.5))
        -- Fill a missing average from the chance, or a missing chance from the
        -- average (middle of the quantity range). Filled figures count at half
        -- confidence (FILLED_CONFIDENCE_FACTOR).
        if (b.chance==nil)~=(b.expectedQuantity==nil) then
            local chance,average,filled=self:FillChanceOrAverage(b.chance,b.expectedQuantity,b.minQuantity,b.maxQuantity)
            if filled=='average' and b.chanceConfidence then
                b.expectedQuantity=average;b.filled='average';result.filledFigures=true
                e={} -- now a known output
                b.contributions=b.chanceContributions or {}
            elseif filled=='chance' then
                b.chance=chance;b.filled='chance';result.filledFigures=true
                b.chanceConfidence=math.floor((stated or 0)*LL.FILLED_CONFIDENCE_FACTOR+.5)
            end
        end
        if e then
            -- Per-material confidence (A3): shown on request, and used to value-weight the
            -- option's figure. C1b: from casts and drops when the chance has them; a
            -- filled average counts at half; never above the
            -- average's stated confidence; otherwise the sources' stated confidence.
            if b.filled=='average' then
                b.confidence=math.floor(b.chanceConfidence*LL.FILLED_CONFIDENCE_FACTOR+.5)
            elseif counts and stated then
                -- The value comes from the average, so never above its own stated confidence.
                b.confidence=math.min(counts.confidence,stated)
            elseif counts then
                b.confidence=counts.confidence
            else
                b.confidence=stated
            end
            confidenceTotal=confidenceTotal+b.confidence
        end
        b.sourceContributions={}
        local total=0 for _,v in pairs(b.contributions) do total=total+v end
        for source,w in pairs(b.contributions) do
            b.sourceContributions[source]=w/total
            result.sources[source]=(result.sources[source] or 0)+w/total
        end
        if e then totalContribution=totalContribution+1 else result.unknownOutputs=true end
        b.fields=nil;b.contributions=nil;b.chanceSources=nil;b.chanceContributions=nil
        result.materials[#result.materials+1]=b
    end
    for key,v in pairs(result.sources) do result.sources[key]=v/math.max(1,totalContribution) end
    if personal and (result.sources.personal or 0)>0 then
        result.personalStats={total=personal.samples or 0,effectiveSamples=personal.effectiveSamples or personal.samples or 0}
    end
    table.sort(result.materials,function(a,b) return a.id<b.id end)
    if totalContribution==0 then return nil,'Insufficient Data: expected quantities unknown' end
    -- Conservative score of the actual contributing field evidence, not slider values.
    result.confidence=math.min(100,math.floor(confidenceTotal/math.max(1,totalContribution)+.5))
    if result.conflictingMeans then
        result.confidence=math.floor(result.confidence*.5)
        result.warning='Compatible sources disagree by more than 2x; confidence discounted'
    end
    if result.unknownOutputs then result.warning='Partial: some output quantities unknown' end
    return result
end
local function fingerprint(value)
    if type(value)~='table' then return type(value)..':'..tostring(value) end
    local keys={} for k in pairs(value) do keys[#keys+1]=k end
    table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
    local parts={}
    for _,key in ipairs(keys) do parts[#parts+1]=tostring(key)..'='..fingerprint(value[key]) end
    return '{'..table.concat(parts,';')..'}'
end
function LL:ResolveEvidenceModel(f,option,personal,mode)
    local ctx=self.ProcessingPlayerConditions and self:ProcessingPlayerConditions(f,option.name,option.recipeID,option.character) or {}
    local build=GetBuildInfo and select(2,GetBuildInfo())
    local key=table.concat({tostring(f.id),tostring(f.quality),tostring(f.classID),tostring(f.expansionID),
        tostring(option.name),tostring(option.inputCount),tostring(option.recipeID),tostring(option.character),
        tostring(ctx._cacheIdentity or fingerprint(ctx)),tostring(build),tostring(self.ItemDB and self.ItemDB.version),
        tostring(mode),tostring(personal and personal.effectiveSamples),tostring(personal and personal.samples),
        tostring(personal and personal.studyID),tostring(personal and personal.observationContextID),
        tostring(personal and personal.expectedInputCount),
        tostring(userWeight(self,'itemdb',mode)),tostring(userWeight(self,'personal',mode)),
        tostring(userWeight(self,'legacy',mode)),tostring(userWeight(self,'imported',mode)),tostring(self._importedRevision),
        tostring(self.ItemDB and self.ItemDB.modelRevision),fingerprint(personal and personal.materials),
        fingerprint(personal and personal.projectionRules)},'|')
    self._processingModelCache=self._processingModelCache or {count=0}
    local cached=self._processingModelCache[key]
    if cached then return cached.model,cached.reason end
    if self._processingModelCache.count>=512 then self._processingModelCache={count=0} end
    local model,reason=self:ComputeEvidenceModel(f,option,personal,mode,ctx)
    self._processingModelCache[key]={model=model,reason=reason}
    self._processingModelCache.count=self._processingModelCache.count+1
    return model,reason
end
function LL:EvidenceDatabaseStatus()
    local counts={itemdb=0,legacy=0,imported=self.ImportedResultsCount and self:ImportedResultsCount() or 0}
    for _,records in pairs(self._evidenceIndex or {}) do
        for _,r in ipairs(records) do counts[r.sourceKey]=(counts[r.sourceKey] or 0)+1 end
    end
    local manifest=self.ItemDB and self.ItemDB.researchManifest or {}
    return ('ItemDB compiler %s: %d mappings (provisional unless normalized); legacy: %d; imported casts: %d; profession rules: %d; personal patch rules: %d'):format(
        tostring(manifest.compilerVersion or 'unknown'),counts.itemdb,
        counts.legacy,counts.imported,#(self.ItemDB and self.ItemDB.professionRules or {}),#(self.ItemDB and self.ItemDB.personalPatchRules or {}))
end
LL:InitializeItemDB()

