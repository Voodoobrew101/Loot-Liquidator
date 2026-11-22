-- Versioned evidence interface. No prices or live scans are cached here.
local _, LL = ...
-- Legacy (old disenchant tables) is on by default since A1: weak evidence counts
-- for less, it is not thrown away. Its low weight keeps it from outvoting ItemDB.
-- Owner clarification: usable tables and calculator estimates are admitted as
-- a labeled fallback, without changing live TSM market-price behavior.
-- B7: results imported from other players are their own source (default weight 25).
local defaults={itemdb={true,100},personal={true,60},imported={true,25},legacy={true,10},reference={true,10}}
-- Weak-evidence multipliers (owner decision 15: weight down, never reject).
local STALE_FACTOR=.25          -- pre-hotfix, obsolete or past its patch window
local UNKNOWN_CONFIDENCE=10     -- a value whose source gave no confidence figure
LL.SourceDefaults=defaults
local order={'itemdb','personal','imported','legacy','reference'}
local sourcePriority={itemdb=1,personal=2,imported=3,legacy=4,reference=5}
local methods={Mill=true,Prospect=true,Disenchant=true,Smelt=true,Recycle=true,
    Craft=true,Research=true,Unravel=true,Crush=true,Thaumaturgy=true,Refine=true,Use=true}
local statuses={unknown=true,contradictory=true,verified=true,measured=true,observed=true,provisional=true,historical=true,modeled=true}
LL.SourceOrder=order
local function finite(n) return type(n)=='number' and n==n and n>=0 and n<math.huge end
local function copy(t) local out={} for k,v in pairs(t or {}) do out[k]=v end return out end
local function copyReference(value)
    if type(value)~='table' then return value end
    local result={} for key,child in pairs(value) do result[key]=copyReference(child) end return result
end
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
    -- Retire the old dedicated frozen-table controls; all restored tables now
    -- share the visible reference source. Never overwrite its saved preference.
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
local function violatedYieldBound(chance,mean,minimum,maximum)
    if chance==nil or mean==nil then return nil end
    if minimum and mean+1e-9<chance*minimum then return minimum end
    if maximum and mean>chance*maximum+1e-9 then return maximum end
end
local function validSamplingVariation(record,material,bound)
    local chance,mean=material.dropChance,material.expectedQuantity
    if not (bound and record.fieldSpecificEvidence==true and record.sourceKey=='itemdb'
        and record.recordID:match('^evidence:v3:') and material.samplingVariation==true
        and chance.status=='measured' and mean.status=='measured' and chance.sampleSizeKnown==true
        and mean.sampleSizeKnown==true and finite(chance.samples) and chance.samples>=2
        and finite(mean.samples) and mean.samples>=2) then return false end
    local p,q=chance.value,mean.value/bound
    if p<=0 or q<=0 or q>1 then return false end
    -- The importer marks separately sampled fields. Check the same tolerance
    -- here before allowing both numbers through the database validator.
    local uncertainty=2*math.sqrt(p*(1-p)/chance.samples+q*(1-q)/mean.samples)
    return math.abs(p-q)<=math.min(.01,.1*math.max(p,q),uncertainty)+1e-9
end
local function validObservedBoundIndependence(record,material)
    local proof=material.observedBoundIndependence
    if not (type(proof)=='table' and proof.version==1 and material.samplingVariation==nil
        and record.fieldSpecificEvidence==true and record.sourceKey=='itemdb'
        and record.recordID:match('^evidence:v3:')) then return false end
    for key in pairs(proof) do
        if key~='version' and key~='field' and key~='meanCohorts' and key~='boundCohorts' then return false end
    end
    local chance,mean=material.dropChance,material.expectedQuantity
    if not (chance.status=='measured' and mean.status=='measured'
        and chance.sampleSizeKnown==true and mean.sampleSizeKnown==true
        and finite(chance.samples) and chance.samples>0 and finite(mean.samples) and mean.samples>0
        and finite(chance.value) and chance.value>0 and chance.value<=1
        and finite(mean.value) and mean.value+1e-9>=chance.value) then return false end
    local lo,hi=material.minQuantity.value,material.maxQuantity.value
    local field=lo and mean.value+1e-9<chance.value*lo and 'minQuantity'
        or hi and mean.value>chance.value*hi+1e-9 and 'maxQuantity'
    if proof.field~=field then return false end
    local bound=material[field]
    if not (bound and bound.basis=='observed-sample' and bound.status=='measured' and bound.sampleSizeKnown==true
        and finite(bound.samples) and bound.samples>0) then return false end
    local function cohortSet(ids)
        if type(ids)~='table' or #ids==0 or #ids>256 then return nil end
        local seen,count={},0
        for key,id in pairs(ids) do
            if type(key)~='number' or key%1~=0 or key<1 or key>#ids
                or type(id)~='string' or #id~=64 or id:find('[^0-9a-f]') or seen[id] then return nil end
            seen[id]=true
            count=count+1
        end
        return count==#ids and seen or nil
    end
    local means,bounds=cohortSet(proof.meanCohorts),cohortSet(proof.boundCohorts)
    if not means or not bounds then return false end
    for id in pairs(means) do if bounds[id] then return false end end
    return true
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
                    (r.gearKey:match('^gear:%d+:%d+:armor$') or r.gearKey:match('^gear:%d+:%d+:weapon$')
                        or r.gearKey:match('^gear:%d+:%d+:profession$'))))
            or (r.recipeID~=nil and (not finite(r.recipeID) or r.recipeID<1 or r.recipeID%1~=0))
            or (r.inputRarity~=nil and (not finite(r.inputRarity) or r.inputRarity>8 or r.inputRarity%1~=0))
            or (r.inputClassID~=nil and (not finite(r.inputClassID) or r.inputClassID>20 or r.inputClassID%1~=0))
            or (r.isDisenchantCategory~=nil and type(r.isDisenchantCategory)~='boolean')
            or (r.isDisenchantCategory and (r.method~='Disenchant' or r.inputItemID~=nil
                or not finite(r.expansionID) or r.expansionID%1~=0 or not finite(r.inputRarity)
                or (r.inputClassID~=2 and r.inputClassID~=4 and r.inputClassID~=19)
                or r.gearKey~=('gear:'..tostring(r.expansionID)..':'..tostring(r.inputRarity)..':'..
                    (r.inputClassID==2 and 'weapon' or r.inputClassID==19 and 'profession' or 'armor'))))
            or (r.categoryItemLevelMin~=nil and (not finite(r.categoryItemLevelMin) or r.categoryItemLevelMin%1~=0))
            or (r.categoryItemLevelMax~=nil and (not finite(r.categoryItemLevelMax) or r.categoryItemLevelMax%1~=0
                or r.categoryItemLevelMin==nil or r.categoryItemLevelMax<r.categoryItemLevelMin))
            or (r.categoryItemLevelMin~=nil and r.categoryItemLevelMax==nil)
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
                or (r.fieldSpecificEvidence and p==0 and e and e>0) then
                return false,'Contradictory probability/quantity fields'
            end
            local bound
            if r.fieldSpecificEvidence then bound=violatedYieldBound(p,e,lo or 1,hi)
            elseif lo and hi then bound=violatedYieldBound(p,e,lo,hi) end
            local independent=m.observedBoundIndependence~=nil and validObservedBoundIndependence(r,m)
            if (m.observedBoundIndependence~=nil and not independent)
                or ((bound or m.samplingVariation~=nil) and not independent and not validSamplingVariation(r,m,bound)) then
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
        -- C4b3 (owner, session 15; decisions 1 and 15): research token lists are used at their
        -- stated confidence, like research scaling rules (C7). A reviewed record (APPROVED) still
        -- needs everything the old gate asked for; an unreviewed one needs an ID, scope, at
        -- least one https source and a confidence, and no requirement it can't check.
        local reviewed=r.independentReview=='APPROVED'
        if type(r)~='table' or type(r.recordID)~='string' or r.recordID=='' or seen[r.recordID]
            or not positive(r.tokenID) or (r.kind~='open' and r.kind~='exchange') or r.gameMode~='Retail'
            or (r.inputClassID~=nil and (not finite(r.inputClassID) or r.inputClassID>20 or r.inputClassID%1~=0 or r.inputClassID==7))
            or (reviewed and r.inputClassID==nil)
            or r.evidenceStatus=='REJECTED'
            or (reviewed and (r.evidenceStatus~='VERIFIED_RELATIONSHIP' or type(r.reviewedBy)~='string' or r.reviewedBy==''
                or r.listComplete~=true or r.requirementsReviewed~=true or r.confidence0to100==nil or r.confidence0to100<90
                or not array(r.sourceURLs) or #r.sourceURLs<2))
            or type(r.requirements)~='table' or next(r.requirements)
            or not finite(r.confidence0to100) or r.confidence0to100>100
            or not positive(r.patchStartBuild) or not positive(r.patchEndBuild) or r.patchStartBuild>r.patchEndBuild
            or type(r.sourceRevision)~='string' or r.sourceRevision==''
            or not array(r.sourceURLs) or #r.sourceURLs<1 or not array(r.rewards) or #r.rewards==0 or #r.rewards>500
            or r.expectedQuantity~=nil or r.dropChance~=nil or r.probability~=nil then
            return false,'Token catalog requires an ID, explicit scope, a confidence and at least one https source (reviewed records: the full review)'
        end
        if (r.costsComplete~=nil and type(r.costsComplete)~='boolean')
            or (reviewed and r.costsComplete==false)
            or (r.rewardSelection~=nil and r.rewardSelection~='choice' and r.rewardSelection~='class')
            or (r.protectCollection~=nil and type(r.protectCollection)~='boolean')
            or (r.merchantName~=nil and (type(r.merchantName)~='string' or r.merchantName==''))
            or (r.rewardLinks~=nil and type(r.rewardLinks)~='table') then return false,'Invalid token redemption metadata' end
        if (r.rewardClassMasks~=nil and type(r.rewardClassMasks)~='table')
            or (r.rewardRequirements~=nil and type(r.rewardRequirements)~='table')
            or (r.rewardVariants~=nil and type(r.rewardVariants)~='table')
            or (r.finalRewardVariants~=nil and (r.rewardVariants~=nil or r.kind~='exchange'
                or type(r.finalRewardVariants)~='table'))
            or (r.rewardSources~=nil and type(r.rewardSources)~='table') then return false,'Invalid reward eligibility metadata' end
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
            local link=r.rewardLinks and r.rewardLinks[tostring(id)]
            if link~=nil and (type(link)~='string' or tonumber(link:match('item:(%d+)'))~=id) then return false,'Invalid exact reward link' end
            local mask=r.rewardClassMasks and r.rewardClassMasks[tostring(id)]
            if mask~=nil and (not positive(mask) or mask>=2^13) then return false,'Invalid reward class mask' end
            local requirement=r.rewardRequirements and r.rewardRequirements[tostring(id)]
            if requirement~=nil and (type(requirement)~='table'
                or (requirement.minimumLevel~=nil and not positive(requirement.minimumLevel))
                or (requirement.covenantID~=nil and (not positive(requirement.covenantID) or requirement.covenantID>4))
                or (requirement.faction~=nil and requirement.faction~='Alliance' and requirement.faction~='Horde')
                or (requirement.hasAppearance~=nil and type(requirement.hasAppearance)~='boolean')
                or (requirement.unverified~=nil and type(requirement.unverified)~='boolean')) then return false,'Invalid reward requirements' end
            if r.kind=='exchange' and (reviewed or r.costsComplete~=false) then
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
        for id,source in pairs(r.rewardSources or {}) do
            if type(id)~='string' or not rewards[tonumber(id)] or not positive(source) then
                return false,'Invalid token reward appearance source'
            end
        end
        for context,sources in pairs(r.rewardVariants or r.finalRewardVariants or {}) do
            if type(context)~='string' or not context:match('^[1-9]%d*$') or type(sources)~='table'
                or not next(sources) then return false,'Invalid token reward variant' end
            for id,source in pairs(sources) do
                if type(id)~='string' or not id:match('^[1-9]%d*$') or not positive(source)
                    or (not r.finalRewardVariants and not rewards[tonumber(id)]) then
                    return false,'Invalid token reward appearance source'
                end
            end
        end
    end
    return true
end
-- C3: everything static lives in ItemDB. Unpack the old disenchant estimates
-- and the DB2 no-disenchant list / processing hints into the lookup tables the
-- rest of the addon already reads (LegacyDB, ItemRestrictions, DB2Processable).
function LL:UnpackItemDBTables()
    local db=self.ItemDB
    if type(db)~='table' then return end
    if db.legacy and not self.LegacyDB then self.LegacyDB=db.legacy end
    local r=db.restrictions
    if type(r)=='table' then
        self.ItemRestrictions=self.ItemRestrictions or {}
        for _,id in ipairs(r.noDisenchant or {}) do self.ItemRestrictions[id]=true end
        -- Older builds flattened catalog observations into item-wide flags.
        -- Retire only those research additions; never remove a native DB2 flag.
        local native={} for _,id in ipairs(r.noDisenchant or {}) do native[id]=true end
        for _,id in ipairs(r.researchNoDisenchant or {}) do
            if r.researchNoDisenchantPolicy=='native-proof-only' then self.ItemRestrictions[id]=true
            elseif not native[id] then self.ItemRestrictions[id]=nil end
        end
        self.ResearchNoDisenchantGlobalProofs=r.researchNoDisenchantGlobalProofs or {}
        self.ItemRestrictionsBuild=r.build
        self.DB2Processable=self.DB2Processable or {}
        for id,method in pairs(r.processable or {}) do self.DB2Processable[id]=method end
    end
end
LL:UnpackItemDBTables()
function LL:InitializeItemDB()
    self._processingModelCache=nil
    self._categorySourceProjectionCache=nil
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
    local reviewedMilling={}
    for _,r in ipairs(all) do
        if r.sourceKey=='reference' and r.sourceKind=='calculator' and r.method=='Mill'
            and r.expansionID==11 and r.recipeID==1269575 and r.realStudy==false then
            reviewedMilling[r.inputItemID]=true
        end
    end
    for _,original in ipairs(all) do
        local r=original
        if r.sourceKey=='legacy' and r.method=='Mill' and reviewedMilling[r.inputItemID] then
            -- Curate the runtime view, keeping the frozen historical table
            -- byte-for-byte intact. An old modeled milling profile is a
            -- reference fallback, not a sampled primary quantity.
            r=copy(original)
            r.originalRecordID=original.recordID
            r.recordID='reference:legacy-model:'..original.recordID
            r.sourceKey='reference';r.sourceKind='legacy-model'
            r.fallbackOnly=true;r.fixedReference=true
            r.referenceApplicability='unverified-reference'
            r.sourceAssumption='Unmeasured historical milling profile; original values and lineage retained'
        end
        local key=r.method..':'..tostring(r.inputItemID or r.gearKey)
        local list=self._evidenceIndex[key] or {};self._evidenceIndex[key]=list
        list[#list+1]=r
        if r.sourceKey=='itemdb' and r.inputItemID and r.recipeID and methods[r.method] and r.method~='Disenchant'
            and ((type(r.profession)=='string' and r.profession~='')
                or r.method=='Mill' or r.method=='Prospect' or r.method=='Smelt') then
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
    for _,method in ipairs({'Mill','Prospect','Smelt','Recycle','Craft','Research','Unravel','Crush','Thaumaturgy','Refine'}) do
        for _,r in ipairs(self._evidenceIndex and self._evidenceIndex[method..':'..tostring(f.id)] or {}) do
            local profession=r.profession or ({Mill='Inscription',Prospect='Jewelcrafting',Smelt='Mining'})[method]
            if r.sourceKey=='itemdb' and r.recipeID and (not r.expansionID or r.expansionID==f.expansionID)
                and type(profession)=='string' and profession~=''
                and (not r.inputQualityRank or r.inputQualityRank==f.reagentQuality) then
                local key=table.concat({method,profession,r.recipeID,r.expansionID or '',r.inputCount},':')
                if not seen[key] then
                    seen[key]=true
                    local totals,required,extras={},{},{}
                    local contract=r.requiredInputs or r.reagents
                    local complete=type(contract)=='table' and #contract>0 and r.requiredInputsResolved~=false
                    for _,input in ipairs(type(contract)=='table' and contract or {}) do
                        local id=type(input)=='table' and (input.id or input.itemID or input[1])
                        local amount=type(input)=='table' and (input.amount or input.quantity or input.quantityRequired or input[2])
                        if finite(id) and id>0 and id%1==0 and finite(amount) and amount>0 and amount%1==0 then
                            totals[id]=(totals[id] or 0)+amount
                        else complete=false end
                    end
                    if complete and totals[f.id]~=r.inputCount then complete=false end
                    for id,amount in pairs(totals) do
                        required[#required+1]={id=id,amount=amount}
                        if id~=f.id then extras[#extras+1]={id=id,amount=amount} end
                    end
                    table.sort(required,function(a,b) return a.id<b.id end)
                    table.sort(extras,function(a,b) return a.id<b.id end)
                    -- Milling/prospecting consume only the stated target batch.
                    -- Other crafts need a complete reagent contract, or the
                    -- exact reviewed single-target Shatter recipe definition.
                    if method=='Mill' or method=='Prospect' then complete=true end
                    local data=self.ItemDB and self.ItemDB.professionProfiles
                    local native=data and data.recipes and data.recipes[r.recipeID]
                    local curve=data and data.recipeQualityModels and data.recipeQualityModels[r.recipeID]
                    if r.recipeID==470726 and method=='Craft' and r.profession=='Enchanting' and r.expansionID==10
                        and r.inputCount==1 and native and native.salvage==true and native.inputCount==1
                        and curve and curve.profession=='Enchanting' and curve.expansionID==10
                        and curve.inputRankItemIDs and curve.inputRankItemIDs[f.reagentQuality]==f.id then
                        complete=true;required={{id=f.id,amount=1}};extras={}
                    end
                    operations[#operations+1]={method=method,recipeID=r.recipeID,requiredSpell=r.recipeID,
                        inputCount=r.inputCount,profession=profession,expansionID=r.expansionID,
                        requiredInputs=required,extraReagents=extras,allocationCostUnknown=not complete,
                        source=r.source}
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
-- Imported quantity fields retain their historical ordinal weight separately
-- from unknown statistical confidence. This is compatibility, not calibration.
local function evidenceScore(field)
    if finite(field.evidenceScore) then return field.evidenceScore end
    return field.confidence
end
-- A confidence score is an ordinal evidence-quality score, not a posterior.
-- Sample saturation and provenance class are independent conservative discounts.
function LL:EvidenceReliability(field,record)
    if not field or field.value==nil or field.status=='unknown' or field.status=='contradictory' then return 0 end
    -- A value with no stated confidence is weak, not worthless (owner decision 1).
    local rawScore=evidenceScore(field)
    local stated=finite(rawScore) and rawScore>0 and rawScore or UNKNOWN_CONFIDENCE
    local score=math.min(1,stated/100)
    local n=field.samples or (record and record.samples)
    local unknownSize=field.sampleSizeKnown==false
        or (field.sampleSizeKnown==nil and record and record.sampleSizeKnown==false)
    -- A reported mean with an unknown sample size is a weak reference. Its
    -- explicit zero observed samples is not a measured zero-cast study.
    local sampleFactor=unknownSize and (n==nil or n==0) and .35
        or (finite(n) and n/(n+30) or .35)
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
    local rawScore=evidenceScore(field)
    local stated=finite(rawScore) and rawScore>0 and rawScore or UNKNOWN_CONFIDENCE
    local class=({verified=1,measured=1,observed=1,provisional=.6,modeled=.25,historical=.4})[field.status] or 0
    return LL.PRIOR_CASTS*math.min(1,stated/100)*class,false
end
local function gearKey(f)
    if not finite(f.expansionID) or f.expansionID%1~=0
        or not finite(f.quality) or f.quality%1~=0
        or (f.classID~=2 and f.classID~=4 and f.classID~=19) then return nil end
    return 'gear:'..tostring(f.expansionID)..':'..tostring(f.quality)..':'..
        (f.classID==2 and 'weapon' or f.classID==19 and 'profession' or 'armor')
end
function LL:DisenchantCategoryKey(f) return gearKey(f) end
local function mixedGemPool(items,material)
    if type(material.rankIDs)~='table' or #material.rankIDs<2 then return false end
    local family,rank,mixed
    for _,id in ipairs(material.rankIDs) do
        local item=items[id]
        if not item or not finite(item.qualityFamilyID) or item.qualityFamilyID<=0
            or not finite(item.qualityRank) or item.qualityRank<=0 then return false end
        if rank and rank~=item.qualityRank then return false end
        rank=item.qualityRank
        if family and family~=item.qualityFamilyID then mixed=true end
        family=family or item.qualityFamilyID
    end
    return mixed==true
end
local function itemCategoryException(record)
    if type(record.categoryExceptionReason)~='string' or not record.categoryExceptionReason:match('%S') then return false end
    for _,url in ipairs(record.categoryExceptionSources or {}) do
        if type(url)=='string' and url:match('^https://%S+$') then return true end
    end
    return false
end
-- Returns eligible, stale. Stale evidence (pre-hotfix, obsolete, or past the end
-- of its patch window) still counts, at STALE_FACTOR weight and lower confidence.
local function contextEligible(record,ctx,build,model,rules)
    if model and model.projectionIncomplete then return false end
    if record.clientVersion and (not GetBuildInfo or GetBuildInfo()~=record.clientVersion) then return false end
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
-- Informational source references obey the same observation policy as yields.
function LL:EvidenceSourceWeight(key,mode) return userWeight(self,key,mode) end
local function buildSourceModel(self,f,option,r,projectionMemo)
    local model={recordID=r.recordID,inputItemID=r.inputItemID,inputCount=r.inputCount,patchBuild=r.patchBuild,referenceContextID=r.referenceContextID,
        sourceKey=r.sourceKey,baselineProfile=r.baselineProfile,baselineStatus=r.baselineStatus,
        baselineProfileAssumed=r.baselineProfileAssumed,
        sourceQuantityBasis=r.sourceQuantityBasis,requiresSourceNormalization=r.requiresSourceNormalization,
        reviewedQualityProjection=r.reviewedQualityProjection,reviewedBacklogModel=r.reviewedBacklogModel,
          reviewedPublishedPriorModel=r.reviewedPublishedPrior~=nil,
        reviewedQualityZeroShares=r.reviewedQualityZeroShares,
        reviewedEffectOverrides=r.reviewedEffectOverrides,
        reviewedDisenchantProjection=r.reviewedDisenchantProjection,
        namedOutputs=r.namedOutputs,unknownOutputs=r.unknownOutputs,
        expectedInputCount=r.expectedInputCount,materials={},source=r.source,
        referenceApplicability=r.referenceApplicability,
        operationUnverified=r.operationUnverified,
        sourceReferenceOnly=r.sourceReferenceOnly,observedSourceOperations=r.observedSourceOperations,
        currentPatchApplicabilityConfidence=r.currentPatchApplicabilityConfidence,
        normalizationAssumptions=r.normalizationAssumptions,
        adjustment=(r.baselineStatus or r.referenceApplicability=='unverified-reference')
            and 'provisional source estimate / baseline not normalized' or nil}
    for _,m in ipairs(r.materials) do
        local material={id=m.id,expectedQuantity=m.expectedQuantity.value,
            rankIDs=m.rankIDs,economicPolicy=m.economicPolicy,
            chance=m.dropChance.value,probabilityVerified=m.dropChance.status=='verified' or m.dropChance.status=='measured',
            minQuantity=m.minQuantity.value,maxQuantity=m.maxQuantity.value}
        if m.conditionalReference then
            material.conditionalExpectedQuantity=material.expectedQuantity
            material.conditionalConfidence=m.expectedQuantity.confidence
            material.conditionalRequirement=m.conditionalReference
            material.expectedQuantity=nil
        end
        -- Resolve supported P(hit) x conditional yield before anchor selection.
        -- Previously an all-missing-mean record was rejected before this could
        -- run. This is a modeled expectation, never another measured study.
        if not m.conditionalReference and not m.expectedQuantity.inferenceBlocked
            and self:EvidenceReliability(m.expectedQuantity,r)==0
            and self:EvidenceReliability(m.dropChance,r)>0
            and ((material.chance==0) or
                (self:EvidenceReliability(m.minQuantity,r)>0 and self:EvidenceReliability(m.maxQuantity,r)>0)) then
            local _,average,filled=self:FillChanceOrAverage(material.chance,nil,material.minQuantity,material.maxQuantity)
            if material.chance==0 then average=0;filled='average' end
            if filled then
                local stated=math.min(m.dropChance.confidence or UNKNOWN_CONFIDENCE,
                    m.minQuantity.confidence or UNKNOWN_CONFIDENCE,m.maxQuantity.confidence or UNKNOWN_CONFIDENCE)
                material.expectedQuantity=average
                material.derivedExpected={value=average,status='modeled',
                    confidence=math.floor(stated*LL.FILLED_CONFIDENCE_FACTOR+.5),
                    assumption='P(hit) times midpoint of stated conditional yield range'}
            end
        end
        model.materials[#model.materials+1]=material
    end
    if r.reviewedPublishedPrior and r.operationUnverified and r.quantityBasis=='per-input' then
        model.adjustment='Published per-input reference'
    end
    if self.ProjectReviewedDisenchantPrior and r.reviewedDisenchantProjection then
        model=self:ProjectReviewedDisenchantPrior(f,option,model)
    end
    if r.reviewedDisenchantProjection and r.requiresSourceNormalization and not model.reviewedDisenchantProjected then
        model=copy(model);model.projectionIncomplete=true
        model.normalizationFailure=model.normalizationFailure or 'Reviewed disenchant source projection is unavailable'
    end
    if self.ApplyGeneralProfessionModel and r.sourceKey~='personal' and r.sourceKey~='imported' then
        model=self:ApplyGeneralProfessionModel(f,option,model,nil,projectionMemo)
    end
    if r.sourceKey~='itemdb' then return model end
    if self.ApplyProfessionModel then model=self:ApplyProfessionModel(f,option,model) end
    if model.professionProjected then return model end
    local verified=self.ApplyVerifiedMechanics and self:ApplyVerifiedMechanics(f,option,model) or model
    if verified~=model and verified.mechanicsApplied then verified.adjustment='character-adjusted'..(verified.unreviewedRule and ' / research rule, not yet reviewed' or '') end
    return verified
end
local categoryIdentityFields={inputID=true,_cacheKey=true,_cacheIdentity=true}
local function categoryFingerprint(value,ignoreIdentity)
    local visiting,nodes={},0
    local function encode(item,root)
        if issecretvalue and issecretvalue(item) then return nil end
        local kind=type(item)
        if kind=='nil' then return 'nil' end
        if kind=='string' then return 's'..#item..':'..item end
        if kind=='number' or kind=='boolean' then return kind..':'..tostring(item) end
        if kind~='table' or visiting[item] then return nil end
        nodes=nodes+1;if nodes>1024 then return nil end
        visiting[item]=true
        local keys={}
        for key in pairs(item) do
            if not (root and ignoreIdentity and categoryIdentityFields[key]) then
                if type(key)~='string' and type(key)~='number' then return nil end
                keys[#keys+1]=key
            end
        end
        table.sort(keys,function(a,b)if type(a)==type(b) then return a<b end return type(a)<type(b) end)
        local parts={'{'}
        for _,key in ipairs(keys) do
            local encoded=encode(item[key],false)
            if not encoded then return nil end
            parts[#parts+1]=encode(key,false)..'='..encoded..';'
        end
        parts[#parts+1]='}';visiting[item]=nil
        return table.concat(parts)
    end
    return encode(value,true)
end
local function categoryProjectionScope(self,f,option,ctx,mode)
    local key=option.name=='Disenchant' and option.inputCount==1 and gearKey(f)
    if not key or not self.ProfessionCategoryProjectionIndependent
        or not self:ProfessionCategoryProjectionIndependent(f,option,ctx) then return nil end
    if not self.ProcessingPlayerConditions or self:ProcessingPlayerConditions(
        f,option.name,option.recipeID,option.character,'Enchanting')~=ctx then return nil end
    local db=self.ItemDB
    -- These adapters can select a source transform by exact item identity.
    -- Keep their original path even if their current coefficient is neutral.
    for _,name in ipairs({'professionRules','mechanicRules'}) do
        for _,rule in ipairs(db[name] or {}) do
            if (not rule.method or rule.method==option.name)
                and (not rule.expansionID or rule.expansionID==f.expansionID) then return nil end
        end
    end
    local contextKey=categoryFingerprint(ctx,true)
    local operationKey=categoryFingerprint(option,false)
    if not contextKey or not operationKey then return nil end
    local data=db.professionProfiles
    local profile=data and data.profiles and data.profiles['Enchanting:'..tostring(f.expansionID)]
    local version,build
    if GetBuildInfo then version,build=GetBuildInfo() end
    local signature=table.concat({key,tostring(f.reagentQuality),tostring(f.inputQuality),
        tostring(mode),tostring(version),tostring(build),contextKey,operationKey},'\030')
    local cache=self._categorySourceProjectionCache
    if not cache or cache.db~=self.db or cache.database~=db or cache.evidence~=self._evidenceIndex
        or cache.modelCache~=self._processingModelCache or cache.data~=data
        or cache.dataRevision~=(data and data.revision) or cache.dataBuild~=(data and data.build)
        or cache.version~=db.version or cache.revision~=db.modelRevision
        or cache.specializationRevision~=db.specializationRevision then
        cache={db=self.db,database=db,evidence=self._evidenceIndex,modelCache=self._processingModelCache,
            data=data,version=db.version,revision=db.modelRevision,
            dataRevision=data and data.revision,dataBuild=data and data.build,
            specializationRevision=db.specializationRevision,scopes={}}
        self._categorySourceProjectionCache=cache
    end
    local now=GetTime and GetTime() or 0
    local kept,found={}
    for _,scope in ipairs(cache.scopes) do
        if now-scope.at<5 and scope.profile==profile then
            kept[#kept+1]=scope
            if scope.key==signature then found=scope end
        end
    end
    if not found then
        if #kept>=2 then table.remove(kept,1) end
        found={key=signature,at=now,profile=profile,models={},count=0}
        kept[#kept+1]=found
    end
    cache.scopes=kept
    return found
end
local function bindingStamp(item)
    return item and table.concat({tostring(item.bindType),tostring(item.itemBinding),
        tostring(item.bonding),tostring(item.qualityFamilyID),tostring(item.qualityRank)},':') or ''
end
local function outputBinding(items,result,id,previous)
    if id==nil then return true end
    local item=items[id] or items[tostring(id)]
    local old=result[id]
    if previous then return old and old.item==item and old.stamp==bindingStamp(item) end
    result[id]={item=item,stamp=bindingStamp(item)}
    return true
end
local function outputBindings(self,record,previous)
    local data=self.ItemDB and self.ItemDB.professionProfiles
    local items=data and data.items or {}
    local result=previous or {}
    for _,material in ipairs(record and record.materials or {}) do
        if type(material.rankIDs)=='table' and #material.rankIDs>0 then
            for _,id in ipairs(material.rankIDs) do
                if not outputBinding(items,result,id,previous) then return false end
            end
        elseif not outputBinding(items,result,material.id,previous) then return false end
    end
    -- Group-only observations also depend on native output family identities.
    for _,group in ipairs(record and record.groupedSourceQuantities or {}) do
        for _,id in ipairs(group.outputItemIDs or {}) do
            if not outputBinding(items,result,id,previous) then return false end
        end
    end
    return result
end
local function reboundSource(model,f,memo)
    local result=copy(model)
    if model.projectedContext then
        -- Every ordinary source uses this actual target context; the general
        -- projection changes only effectiveSkill. Copy once per evaluation,
        -- rather than once for every source behind the same gear category.
        memo.categoryContexts=memo.categoryContexts or {}
        local skill=model.projectedContext.effectiveSkill
        local key=type(skill)..':'..tostring(skill)
        local context=memo.categoryContexts[key]
        if not context then
            context=copyReference(memo.categoryContext);context.effectiveSkill=skill
            memo.categoryContexts[key]=context
        end
        result.projectedContext=context
    end
    if model.professionParameters then
        result.professionParameters=copy(model.professionParameters)
        result.professionParameters.inputItemID=f.id
    end
    return result
end
local function sourceModel(self,f,option,r,projectionMemo)
    local scope=projectionMemo and projectionMemo.categoryScope
    if not scope or r.inputItemID~=nil or r.gearKey~=gearKey(f) or r.inputCount~=1
        or (r.sourceKey~='itemdb' and r.sourceKey~='legacy' and r.sourceKey~='reference')
        or r.categoryExceptionReason or r.reviewedEffectOverrides or r.reviewedDisenchantProjection then
        return buildSourceModel(self,f,option,r,projectionMemo)
    end
    local cached=scope.models[r]
    local model
    if cached and outputBindings(self,r,cached.bindings) then model=cached.model
    else
        model=buildSourceModel(self,f,option,r,projectionMemo)
        if cached or scope.count<256 then
            if not cached then scope.count=scope.count+1 end
            scope.models[r]={model=model,bindings=outputBindings(self,r)}
        end
    end
    -- Fusion creates fresh public materials. Only its target context can retain
    -- this source view, so give it an isolated context with current input IDs.
    return reboundSource(model,f,projectionMemo)
end
local function modelMetadata(original,material,field,modelField)
    local meta=copy((field=='expectedQuantity' and material.derivedExpected) or original[field])
    meta.value=material[modelField]
    if material.transformConfidence then
        -- Retain the source's ordinal support weight; target-model uncertainty
        -- caps the displayed confidence rather than reweighting source units.
        meta.evidenceScore=evidenceScore(meta)
        meta.confidence=math.min(meta.confidence,material.transformConfidence)
        meta.modelConfidenceCap=math.min(meta.modelConfidenceCap or 100,material.transformConfidence)
    end
    return meta
end
local function unavailableReason(record,material)
    local conditions=record.researchConditions or {}
    if conditions.eligibilityStatus=='REQUIRES_ORE_SPECIFIC_PROFICIENT_PROCESSOR_SPECIALIZATION' then
        return 'Requires ore-specific Proficient Processor unlock; rate not established for this profile'
    end
    for _,blocker in ipairs(material.expectedQuantity.blockers or {}) do
        if blocker=='SOURCE_ZERO_NOT_PROVEN' then return 'Source zero is unverified; no supported average for this profile' end
    end
    return 'Average unavailable for this source/character context'
end
-- C2: borrow from a sibling. The same herb or ore at another quality rank is a
-- different item with the same name. When an item has no usable data, the
-- nearest-rank sibling's estimate is shown as "Estimated from <name> rank N" at
-- lower confidence (a borrowed guess is worth at most PRIOR_CASTS casts, and
-- never more than BORROWED_CONFIDENCE_FACTOR of the sibling's own confidence).
LL.BORROWED_CONFIDENCE_FACTOR=.5
local function itemName(id)
    if C_Item and C_Item.GetItemNameByID then
        local ok,n=pcall(C_Item.GetItemNameByID,id);if ok and type(n)=='string' and n~='' then return n end
    end
    if GetItemInfo then
        local ok,n=pcall(GetItemInfo,id);if ok and type(n)=='string' and n~='' then return n end
    end
    if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID,id) end
end
-- Returns siblings (nearest rank first) and whether a name is still loading.
function LL:FindRankSiblings(f,option)
    if not f or type(f.id)~='number' or not option or not option.name then return {},false end
    local name=f.name or itemName(f.id)
    if not name then return {},true end
    local prefix=option.name..':'
    local out,pending,seen={},false,{}
    for key,list in pairs(self._evidenceIndex or {}) do
        local id=key:sub(1,#prefix)==prefix and tonumber(key:sub(#prefix+1))
        if id and id~=f.id and not seen[id] then
            seen[id]=true
            local rank,sameExpansion
            for _,r in ipairs(list) do
                rank=rank or r.inputQualityRank
                if not r.expansionID or r.expansionID==f.expansionID then sameExpansion=true end
            end
            if sameExpansion then
                local n=itemName(id)
                if n==nil then pending=true
                elseif n==name then out[#out+1]={id=id,rank=rank,name=n} end
            end
        end
    end
    local mine=f.reagentQuality or 0
    table.sort(out,function(a,b)
        local da,db=math.abs((a.rank or 0)-mine),math.abs((b.rank or 0)-mine)
        if da~=db then return da<db end
        return a.id<b.id
    end)
    return out,pending
end
function LL:BorrowFromSibling(f,option,mode,ctx)
    local siblings,pending=self:FindRankSiblings(f,option)
    for _,s in ipairs(siblings) do
        local facts=copy(f);facts.id=s.id;facts.name=s.name;facts.reagentQuality=s.rank
        local sctx=copy(ctx);sctx.inputQuality=s.rank
        local m=self:ComputeEvidenceModel(facts,option,nil,mode,sctx,true)
        if m then
            local label='Estimated from '..s.name..(s.rank and (' rank '..s.rank) or '')
            local total,count=0,0
            for _,b in ipairs(m.materials) do
                if type(b.confidence)=='number' then
                    local c=math.floor(b.confidence*LL.BORROWED_CONFIDENCE_FACTOR+.5)
                    if b.chance then
                        local prior=self:CountsEstimate({prior={chance=b.chance,
                            casts=math.min(LL.PRIOR_CASTS,b.chanceCasts or LL.PRIOR_CASTS)}})
                        if prior then c=math.min(c,prior.confidence) end
                    end
                    b.confidence=c;total=total+c;count=count+1
                end
            end
            m.confidence=count>0 and math.floor(total/count+.5) or 0
            if m.conflictingMeans then m.confidence=math.floor(m.confidence*.5) end
            m.estimatedFrom=label;m.borrowedFromItemID=s.id;m.provisional=true
            m.warning=m.warning and (label..'; '..m.warning) or label
            return m
        end
    end
    return nil,pending
end
function LL:ComputeEvidenceModel(f,option,personal,mode,ctx,noBorrow,importedRecords)
    -- All sources in this evaluation share the same input and operation.
    -- Reuse their target-profile calculation only for this call.
    local projectionMemo={}
    projectionMemo.categoryScope=categoryProjectionScope(self,f,option,ctx,mode)
    projectionMemo.categoryContext=ctx
    local build=GetBuildInfo and select(2,GetBuildInfo())
    local records,seenRecords={},{}
    local function include(input)
        if input==nil then return end
        for _,record in ipairs(self._evidenceIndex and self._evidenceIndex[option.name..':'..tostring(input)] or {}) do
            if not seenRecords[record] then records[#records+1]=record;seenRecords[record]=true end
        end
        local imports=input==f.id and importedRecords
            or (self.ImportedEvidenceRecords and self:ImportedEvidenceRecords(option.name..':'..tostring(input),f,option,ctx))
        for _,record in ipairs(imports or {}) do
            if not seenRecords[record] then records[#records+1]=record;seenRecords[record]=true end
        end
    end
    include(f.id) -- preserved source studies and documented item exceptions
    if option.name=='Disenchant' then include(gearKey(f)) end
    local nativeItems=self.ItemDB.professionProfiles and self.ItemDB.professionProfiles.items or {}
    local mixedPools,hasGrouped={},{}
    local function groupOnly(material)
        local known=mixedPools[material]
        if known==nil then known=option.name=='Prospect' and mixedGemPool(nativeItems,material);mixedPools[material]=known end
        return known
    end
    local eligible,transformed,hasExpected,staleRecord,partialStrength={},{},{},{},{}
    local hasEligibleSalvage=false
    for _,r in ipairs(records) do
        -- Input rarity can change on the same gear item ID (for example an
        -- upgraded Courtly Wrists). Mechanics must never normalize away that
        -- physical identity mismatch or apply a rare study to an epic copy.
        local lo,hi=r.categoryItemLevelMin,r.categoryItemLevelMax
        local bandMatches=lo==nil or finite(f.itemLevel) and f.itemLevel>=lo and f.itemLevel<=hi
            or not finite(f.itemLevel) and lo==1 and hi==999
        if (r.inputRarity==nil or r.inputRarity==f.quality)
            and (r.inputClassID==nil or r.inputClassID==f.classID) and bandMatches
            and userWeight(self,r.sourceKey,mode)>0 and (not r.recipeID or r.recipeID==option.recipeID)
            and (not r.inputQualityRank or r.inputQualityRank==ctx.inputQuality)
            and (not r.expansionID or r.expansionID==f.expansionID) then
        local model=sourceModel(self,f,option,r,projectionMemo)
        local hasMean=false
        for i,material in ipairs(model.materials) do
            local original=r.materials[i]
            if groupOnly(original) then
                hasGrouped[r]=true
            elseif self:EvidenceReliability(modelMetadata(original,material,'expectedQuantity','expectedQuantity'),r)>0 then
                hasMean=true;break
            elseif r.fieldSpecificEvidence and (not option.inputCount or option.inputCount==r.inputCount) then
                partialStrength[r]=math.max(partialStrength[r] or 0,
                    self:EvidenceReliability(modelMetadata(original,material,'dropChance','chance'),r),
                    self:EvidenceReliability(original.minQuantity,r),
                    self:EvidenceReliability(original.maxQuantity,r))
            end
        end
        transformed[r]=model
        hasExpected[r]=hasMean
        -- Applicability defines the output universe. An unknown expectation must
        -- remain an unknown cooutput rather than disappear as if impossible.
        local ok,stale=contextEligible(r,ctx,build,model,self.ItemDB.mechanicRules)
        if ok then
            eligible[#eligible+1]=r;staleRecord[r]=stale or nil
            hasEligibleSalvage=hasEligibleSalvage or r.salvage==true
        end
        end
    end
    if personal and personal.observationContext and ctx.simulated and self.ProjectPersonalEstimate then
        personal=self:ProjectPersonalEstimate(f,option,personal,ctx,build)
    end
    if personal and personal.observationContext and ((ctx.simulated and not personal.professionProjected)
        or ctx.character~=personal.observationContext.character) then
        personal=nil
    end
    local measuredReferencePreferred=false
    if personal and userWeight(self,'personal',mode)>0 and (personal.effectiveSamples or 0)>0 then
        local r={recordID='personal',sourceKey='personal',studyID=personal.studyID or ('personal:'..tostring(ctx.character)),
            source='Personal recorded results',inputCount=personal.inputCount or option.inputCount or 1,
            samples=personal.effectiveSamples,referenceConditions=copy(ctx),
            referenceContextID=personal.referenceContextID,patchBuild=personal.patchBuild,expectedInputCount=personal.expectedInputCount,
            materials={},fixedReference=personal.professionProjected,
            provisional=personal.professionProjected or (personal.effectiveSamples or 0)<(self.ProcessingMinimum and self:ProcessingMinimum() or 30)}
        r.personalReference={}
        for _,key in ipairs({'sourcePatchBuild','targetPatchBuild','sourceReferenceOnly',
            'currentPatchApplicabilityConfidence','sourceApplicabilityConfidence','observationBuildPolicy',
            'personalSourceProfileMatched','numericTransformApplied','studyCoverageCensored','coverageCensored',
            'excludedUnresolvedOperations','excludedUnresolvedRecordIDs','studyCoverageGaps'}) do
            r.personalReference[key]=copyReference(personal[key])
        end
        for _,m in ipairs(personal.materials or {}) do
            r.materials[#r.materials+1]={id=m.id,quality=m.quality,rarity=m.rarity,
                expectedQuantity={value=m.expectedQuantity,confidence=math.min(85,m.confidence or 85,personal.ruleConfidence or 100),
                    status=personal.professionProjected and 'modeled' or 'observed'},
                dropChance={value=m.chance,confidence=85,status='observed'},
                minQuantity={value=m.minQuantity,confidence=85,status='observed'},
                maxQuantity={value=m.maxQuantity,confidence=85,status='observed'},
                personalHistogram=m.quantityCounts,personalSamples=m.samples}
        end
        if #r.materials>0 then
            eligible[#eligible+1]=r
            measuredReferencePreferred=option.name=='Disenchant' and personal.personalSourceProfileMatched==true
                and personal.numericTransformApplied==false and personal.coverageCensored==false
                and personal.effectiveSamples>=(self.ProcessingMinimum and self:ProcessingMinimum() or 30)
            for _,material in ipairs(r.materials) do
                if self:EvidenceReliability(material.expectedQuantity,r)>0 then hasExpected[r]=true;break end
            end
            if personal.professionProjected then
                transformed[r]={inputCount=r.inputCount,materials=personal.materials,sourceKey='personal',
                    mechanicsApplied=true,adjustment=personal.adjustment,projectionRules=personal.projectionRules,
                    generalProfessionApplied=personal.generalProfessionApplied,projectedContext=personal.projectedContext,
                    professionParameters=personal.professionParameters,ruleConfidence=personal.ruleConfidence}
            end
        end
    end
    if measuredReferencePreferred then
        local scoped={}
        for _,record in ipairs(eligible) do
            -- A matching measured category is a better reference than a
            -- source whose invested profile was never identified. Such rows
            -- remain fallbacks for other profiles; they cannot import a maxed
            -- character's extras into this known zero-specialization cohort.
            local unknownProfile=record.baselineProfile==nil or record.baselineProfileAssumed==true
            if record.sourceKey=='personal' or record.sourceKey=='imported' or not unknownProfile then
                scoped[#scoped+1]=record
            end
        end
        eligible=scoped
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
    local anchor,anchorStrength,anchorSpecificity,anchorExactInput,anchorCategoryRank,anchorExactBatch
    for _,r in ipairs(eligible) do
        if hasExpected[r] and (not anchor or sourcePriority[r.sourceKey]==sourcePriority[anchor.sourceKey]) then
            local strength=0
            for i,material in ipairs((transformed[r] or sourceModel(self,f,option,r,projectionMemo)).materials) do
                if not groupOnly(r.materials[i]) then
                    strength=math.max(strength,self:EvidenceReliability(modelMetadata(r.materials[i],material,'expectedQuantity','expectedQuantity'),r))
                end
            end
            if staleRecord[r] then strength=strength*STALE_FACTOR end
            -- Prefer a cohort that identifies this exact rarity/class variant
            -- over a mixed or unspecified variant of the same item. Sources
            -- still keep their normal priority and incompatible cohorts remain
            -- separate rather than lending one another probabilities or means.
            local specificity=(r.inputRarity~=nil and 1 or 0)+(r.inputClassID~=nil and 1 or 0)
            local exactInput=r.inputItemID==f.id and 1 or 0
            local exactBatch=r.inputCount==option.inputCount and 1 or 0
            -- One input is this reference's unit normalization, not a verified
            -- one-input operation that can outrank an actual measured batch.
            if r.reviewedPublishedPrior and r.operationUnverified and r.quantityBasis=='per-input' then exactBatch=0 end
            -- Ordinary disenchant studies describe a physical gear category.
            -- The preserved exact-item source rows must not override the
            -- category aggregate or count a study for a second time. An item
            -- exception requires a documented reason and supporting source.
            local categoryRank=1
            if option.name=='Disenchant' then
                if exactInput==1 and itemCategoryException(r) then categoryRank=4
                elseif r.isDisenchantCategory then
                    categoryRank=r.categoryReferenceOnly and 0 or 2
                    if ctx.referenceContextID and ctx.referenceContextID==r.referenceContextID then categoryRank=3 end
                end
            end
            if not anchor or categoryRank>anchorCategoryRank
                or (categoryRank==anchorCategoryRank and (exactInput>anchorExactInput
                    or (exactInput==anchorExactInput and (specificity>anchorSpecificity
                        or (specificity==anchorSpecificity and (exactBatch>anchorExactBatch
                            or (exactBatch==anchorExactBatch and strength>anchorStrength))))))) then
                anchor,anchorStrength,anchorSpecificity=r,strength,specificity
                anchorExactInput,anchorCategoryRank,anchorExactBatch=exactInput,categoryRank,exactBatch
            end
        end
    end
    local partialOnly=false
    if not anchor then
        -- A scoped occurrence or range can still describe an operation whose
        -- expected return is unknown. It cannot anchor a priced comparison.
        for _,r in ipairs(eligible) do
            local strength=(partialStrength[r] or 0)*(staleRecord[r] and STALE_FACTOR or 1)
            local exactInput=r.inputItemID==f.id and 1 or 0
            if strength>0 and (not anchor or exactInput>anchorExactInput
                or (exactInput==anchorExactInput and strength>anchorStrength)) then
                anchor,anchorStrength,anchorExactInput=r,strength,exactInput
                partialOnly=true
            end
        end
    end
    if not anchor then
        -- Group totals can identify possible gem outputs, but never supply
        -- numeric anchor strength or an individual gem's processing value.
        for _,record in ipairs(eligible) do
            if hasGrouped[record] then anchor=record;partialOnly=true;break end
        end
    end
    if not anchor then
        local enabled=false
        for _,r in ipairs(records) do if userWeight(self,r.sourceKey,mode)>0 then enabled=true end end
        local why=#records==0 and 'No researched yield record for this item'
            or not enabled and 'Matching yield sources are disabled by Database & Accuracy / Observation policy'
            or #eligible==0 and 'Yield records do not match this recipe, patch or character context'
            or 'Matching yield records have no usable expected quantities'
        if not noBorrow then
            local borrowed,pending=self:BorrowFromSibling(f,option,mode,ctx)
            if borrowed then return borrowed end
            -- A sibling's name is still loading: answer now, but don't cache the miss.
            if pending then return nil,'Insufficient Data: '..why,true end
        end
        return nil,'Insufficient Data: '..why
    end
    local batch=option.inputCount or anchor.inputCount
    local result={kind='weighted-evidence',inputCount=batch,materials={},sources={},
        source='Weighted evidence',context=ctx,adjustment='baseline / unadjusted',
        provisional=false,confidence=0,excludedSources={},unknownOutputs=false,outputQuantityCompletenessTracked=true,
        gearKey=anchor.gearKey,isDisenchantCategory=anchor.isDisenchantCategory,
        referenceContextID=anchor.referenceContextID,
        categorySourceStudyIDs=anchor.categorySourceStudyIDs,memberInputItemIDs=anchor.memberInputItemIDs}
    if anchor.sourceReferenceOnly then
        result.sourceReferenceOnly=true
        result.sourceReference={recordID=anchor.recordID,sourcePatchBuild=anchor.patchBuild,
            observedSourceOperations=anchor.observedSourceOperations,observedTargetOperations=0,
            currentPatchApplicabilityConfidence=anchor.currentPatchApplicabilityConfidence,
            normalizationAssumptions=copyReference(anchor.normalizationAssumptions)}
    end
    if anchor.sourceKey=='personal' and personal and personal.observationContext then
        result.observationContext=copyReference(personal.observationContext)
        result.context=copyReference(personal.projectedContext or personal.observationContext)
        result.projectedContext=personal.projectedContext and copyReference(personal.projectedContext) or nil
        result.provisional=true
        -- The scoped reader supplies actual retained observation counts and
        -- distributions. Keep its source support score, independently from
        -- current-build applicability; arbitrary capture-quality weights are
        -- still unscored on other personal paths.
        result.confidenceUnscored=not (personal.personalSourceProfileMatched
            and personal.numericTransformApplied==false and personal.coverageCensored==false) or nil
        result.adjustment=personal.adjustment or 'measured character context / unadjusted'
    end
    local bins,studySeen,outputReasons,groupOutputIDs={},{},{},{}
    local consumptionSum,consumptionWeight,consumptionIncomplete=0,0,false
    local contributingSalvage=false
    for _,r in ipairs(eligible) do
        for _,m in ipairs(r.materials) do
            if not groupOnly(m) then outputReasons[m.id]=outputReasons[m.id] or unavailableReason(r,m) end
        end
    end
    local function sameContext(r)
        if r==anchor then return true end
        return r.referenceContextID and r.referenceContextID==anchor.referenceContextID
            and r.inputItemID==anchor.inputItemID and r.gearKey==anchor.gearKey
            and r.inputRarity==anchor.inputRarity and r.inputClassID==anchor.inputClassID
            and r.patchBuild==anchor.patchBuild and same(r.referenceConditions,anchor.referenceConditions)
    end
    local function outputFamily(material)
        local item=nativeItems[material.id] or nativeItems[tostring(material.id)]
        return item and item.qualityFamilyID
    end
    local measuredFamilies={}
    if option.name=='Mill' or option.name=='Prospect' then
        for _,record in ipairs(eligible) do
            if sameContext(record) or record.fixedReference then
                local model=transformed[record] or sourceModel(self,f,option,record,projectionMemo)
                for index,material in ipairs(model.materials or {}) do
                    local original=record.materials[index]
                    local field=original and original.expectedQuantity or {}
                    local family=outputFamily(material)
                    if not groupOnly(original) and family and finite(material.expectedQuantity) and material.expectedQuantity>0
                        and (field.status=='measured' or field.status=='observed' or field.status=='verified')
                        and finite(field.samples or record.samples) and (field.samples or record.samples)>0 then
                        measuredFamilies[family]=measuredFamilies[family] or {}
                        measuredFamilies[family][material.id]=true
                    end
                end
            end
        end
    end
    for _,r in ipairs(eligible) do
        local compatible=sameContext(r)
        if anchor.isDisenchantCategory and r.sourceKey==anchor.sourceKey and r.inputItemID
            and not itemCategoryException(r) then
            result.excludedSources[#result.excludedSources+1]=r.sourceKey..': source study represented by disenchant category'
        elseif not compatible and (not r.fixedReference or anchor.categoryReferenceOnly) then
            -- An explicitly selected source cohort keeps its own distribution.
            -- A generic fixed baseline is not evidence of that cohort's hits
            -- or quantities merely because both now share a gear category.
            result.excludedSources[#result.excludedSources+1]=r.sourceKey..': reference context cannot be normalized'
        else
            -- Build a model, then apply the preserved PR #4 adapter exactly once.
            local model=transformed[r] or sourceModel(self,f,option,r,projectionMemo)
            if model.unknownOutputs or #(model.namedOutputs or {})>0 then
                result.unknownOutputs=true
                result.unknownOutputIdentities=true
                result.namedOutputs=result.namedOutputs or {}
                for _,named in ipairs(model.namedOutputs or {}) do
                    local found=false
                    for _,old in ipairs(result.namedOutputs) do if same(old,named) then found=true;break end end
                    if not found then result.namedOutputs[#result.namedOutputs+1]=copy(named) end
                end
            end
            if model.generalProfessionApplied then
                result.generalProfessionApplied=true;result.professionProjected=true
                result.projectedContext=model.projectedContext
                result.context=model.projectedContext
                -- Source normalization/calibration belongs to that source.
                -- The final quality pass uses the selected target, not whichever
                -- source happened to be visited last (possibly a confidence-zero prior).
                if not result.generalProfessionParameters then
                    local parameters=model.professionParameters or {}
                    result.generalProfessionParameters=self:ProfessionProfileParameters(
                        parameters.profession or ctx.profession,parameters.expansionID or f.expansionID,
                        ctx,option,f)
                end
                result.generalProjectionInputCount=model.inputCount
                result.generalProjectedSources=result.generalProjectedSources or {}
                result.generalProjectedSources[r.sourceKey]=true
                -- Its uncertainty is already attached to the contributing
                -- fields. A weak source must not cap every other source at zero.
            end
            if r==anchor and model.adjustment then result.adjustment=model.adjustment end
            if model.referenceApplicability=='unverified-reference' then result.unverifiedReference=true end
            if r==anchor then
                if model.expectedInputCount~=nil and not r.salvage then
                    result.expectedInputCount=model.expectedInputCount*batch/r.inputCount
                end
            end
            if model.mechanicsApplied then
                result.adjustment=model.adjustment or 'character-adjusted';result.mechanicsApplied=true
            end
            local acceptedMeanWeight=0
            for i,m in ipairs(model.materials) do
                local original=r.materials[i]
                if groupOnly(original) then
                    result.groupedSourceQuantities=result.groupedSourceQuantities or {}
                    result.groupedSourceQuantities[#result.groupedSourceQuantities+1]={recordID=r.recordID,
                        inputCount=r.inputCount,outputItemIDs=copyReference(original.rankIDs),
                        expectedQuantity=m.expectedQuantity,sourceExpectedQuantity=original.expectedQuantity.value,
                        status=original.expectedQuantity.status,confidence=original.expectedQuantity.confidence,
                        quantityBasis='unallocated-gem-group-total'}
                    for _,id in ipairs(original.rankIDs) do groupOutputIDs[id]=true end
                else
                local id=m.id
                -- A known rank-family expectation already includes its rank
                -- alternatives. Do not add exact-rank fallback rows on top.
                local familyCovered=false
                local family=outputFamily(m)
                -- Pooled references are family fallbacks. A positive exact
                -- prospecting quality remains a distinct output even when
                -- another quality in that family already has measurements.
                local unknownProfilePrior=r.reviewedBacklogModel and r.baselineProfileAssumed
                    and not r.sampleSizeKnown and (r.samples==nil or r.samples==0)
                local reported=r.referenceConditions or {}
                local reportedProfile=reported.skill~=nil or reported.effectiveSkill~=nil
                    or reported.specialization~=nil or reported.stats~=nil
                local unidentifiedReference=(r.sourceKey=='reference' or r.sourceKey=='legacy')
                    and not reportedProfile and (r.baselineProfile==nil or r.baselineProfileAssumed)
                if family and measuredFamilies[family] and (unknownProfilePrior or unidentifiedReference)
                    and (m.rankIDs or m.expectedQuantity==0
                        or option.name~='Prospect' and not measuredFamilies[family][m.id]) then
                    familyCovered=true
                    result.excludedSources[#result.excludedSources+1]=r.recordID..': measured family baseline already available'
                end
                local unpricedOverlaps={}
                local rankReferences={}
                if r.fallbackOnly then
                    for _,existing in pairs(bins) do
                        local overlap=false
                        for _,rankID in ipairs(original.rankIDs or {}) do if rankID==existing.id then overlap=true end end
                        for _,rankID in ipairs(existing.rankIDs or {}) do if rankID==id then overlap=true end end
                        if overlap then
                            if existing.fields.expectedQuantity then familyCovered=true
                            else
                                unpricedOverlaps[#unpricedOverlaps+1]=existing.id
                                local p=existing.fields.dropChance
                                if p or existing.minQuantity then rankReferences[#rankReferences+1]={id=existing.id,
                                    chance=p and p.sum/p.weight,minQuantity=existing.minQuantity,maxQuantity=existing.maxQuantity} end
                            end
                        end
                    end
                end
                if not familyCovered then
                -- A wholly unknown exact-rank placeholder may be replaced by
                -- a supported family reference. Its rank-specific P/range do
                -- not become the pooled distribution. Priced ranks above are
                -- always protected from overlap/double counting.
                if #unpricedOverlaps>0 and (original.rankIDs or not bins[id]) then
                    for _,overlapID in ipairs(unpricedOverlaps) do bins[overlapID]=nil end
                end
                local b=bins[id] or {id=id,quality=original.quality,rarity=original.rarity,
                    economicPolicy=original.economicPolicy,
                    rankIDs=original.rankIDs, -- D1c2: rank unknown, priced at the cheapest rank
                    fields={},contributions={},sourceEstimates={}};bins[id]=b
                if #rankReferences>0 then b.rankReferences=rankReferences end
                b.fieldSpecificEvidence=b.fieldSpecificEvidence or r.fieldSpecificEvidence
                b.chanceInferenceBlocked=b.chanceInferenceBlocked or original.dropChance.inferenceBlocked
                b.quantityInferenceBlocked=b.quantityInferenceBlocked or original.expectedQuantity.inferenceBlocked
                if original.samplingVariation and r.inputCount==batch and not m.expectationTransformed then b.samplingEvidence=original end
                if original.observedBoundIndependence and r.inputCount==batch and not m.expectationTransformed
                    and m.chance==original.dropChance.value and m.expectedQuantity==original.expectedQuantity.value
                    and m.minQuantity==original.minQuantity.value and m.maxQuantity==original.maxQuantity.value then
                    b.independentBoundsEvidence={recordID=r.recordID,material=original}
                end
                if m.conditionalExpectedQuantity~=nil then
                    b.conditionalExpectedQuantity=m.conditionalExpectedQuantity*batch/r.inputCount
                    b.conditionalConfidence=m.conditionalConfidence
                    b.conditionalRequirement=m.conditionalRequirement
                    result.hasConditionalReferences=true
                end
                local previousSource=b.sourceEstimates[r.sourceKey]
                local sourceRecords=previousSource and previousSource.records or {}
                sourceRecords[#sourceRecords+1]={recordID=r.recordID,studyID=r.studyID,inputCount=r.inputCount,
                    expectedQuantity=m.expectedQuantity,originalExpectedQuantity=original.expectedQuantity.value,
                    dropChance=m.chance,minQuantity=m.minQuantity,maxQuantity=m.maxQuantity,
                    reviewedQualityProjected=model.reviewedQualityProjected,
                    reviewedDisenchantProjected=model.reviewedDisenchantProjected,
                    personalReference=copyReference(r.personalReference)}
                b.sourceEstimates[r.sourceKey]={expectedQuantity=m.expectedQuantity,dropChance=m.chance,
                    minQuantity=m.minQuantity,maxQuantity=m.maxQuantity,sourceConflict=original.sourceConflict,
                    heldDropChance=original.heldDropChance,heldExpectedQuantity=original.heldExpectedQuantity,
                    inputCount=r.inputCount,originalTSM=original.originalTSM,
                    recordID=r.recordID,studyID=r.studyID,records=sourceRecords,
                    appliedRule=m.appliedProfessionRule or m.appliedExpectationRule}
                for field,modelField in pairs({expectedQuantity='expectedQuantity',dropChance='chance'}) do
                    local key=r.studyID..':'..id..':'..field
                    local metadata=modelMetadata(original,m,field,modelField)
                    local weight=userWeight(self,r.sourceKey,mode)*self:EvidenceReliability(metadata,r)
                    -- These sources fill missing fields only. A second copy of
                    -- a historical rate cannot dilute or double-count an
                    -- already usable research/personal/legacy expectation.
                    if r.fallbackOnly and b.fields[field] then weight=0 end
                    -- Legacy now blends in at its (low) source weight instead of only filling gaps.
                    if staleRecord[r] then
                        weight=weight*STALE_FACTOR
                        metadata.confidence=metadata.confidence and math.floor(metadata.confidence*.5+.5)
                        if metadata.evidenceScore then metadata.evidenceScore=math.floor(metadata.evidenceScore*.5+.5) end
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
                        local score=evidenceScore(metadata)
                        local c=(score or 0)>0 and score or UNKNOWN_CONFIDENCE
                        -- Source support keeps its weighting independently of
                        -- an explicit model/transform applicability cap.
                        if finite(metadata.modelConfidenceCap)
                            and (field=='expectedQuantity' or r.reviewedBacklogModel) then
                            c=math.min(c,metadata.modelConfidenceCap)
                        end
                        if field=='expectedQuantity' then
                            if v>0 and model.generalProfessionApplied and family then
                                result.familyQualityConfidence=result.familyQualityConfidence or {}
                                local cap=model.professionParameters and model.professionParameters.confidence or 100
                                result.familyQualityConfidence[family]=math.min(result.familyQualityConfidence[family] or 100,cap)
                            end
                            if r.reviewedPublishedPrior then b.reviewedPriorQuantity=true
                            else b.otherQuantityContribution=true end
                        end
                        acc.confidence=(acc.confidence or 0)+c*weight
                        if field=='expectedQuantity' then
                            b.sourceMeanAccumulators=b.sourceMeanAccumulators or {}
                            local sourceMean=b.sourceMeanAccumulators[r.sourceKey] or {sum=0,weight=0}
                            b.sourceMeanAccumulators[r.sourceKey]=sourceMean
                            sourceMean.sum=sourceMean.sum+v*weight;sourceMean.weight=sourceMean.weight+weight
                            if model.reviewedQualityProjected then
                                sourceMean.reviewedQualitySum=(sourceMean.reviewedQualitySum or 0)+v*weight
                                sourceMean.reviewedQualityWeight=(sourceMean.reviewedQualityWeight or 0)+weight
                            end
                            if model.reviewedDisenchantProjected then
                                sourceMean.reviewedDisenchantSum=(sourceMean.reviewedDisenchantSum or 0)+v*weight
                                sourceMean.reviewedDisenchantWeight=(sourceMean.reviewedDisenchantWeight or 0)+weight
                            end
                            b.independentQuantityConfidence=b.independentQuantityConfidence or metadata.independentConfidence
                            if hasEligibleSalvage then acceptedMeanWeight=math.max(acceptedMeanWeight,weight) end
                            if model.operationUnverified then result.operationUnverified=true end
                            if m.derivedExpected then
                                b.derivedMean=true;b.filled='average';b.meanBasis=m.derivedExpected.assumption
                                result.filledFigures=true;result.provisional=true
                            end
                            if metadata.confidenceUnscored then
                                b.confidenceUnscored=true;result.confidenceUnscored=true
                            end
                        end
                        if metadata.workingEstimate then b.workingEstimate=true;result.workingEstimate=true;result.provisional=true end
                        if staleRecord[r] then b.staleEvidence=true;result.staleEvidence=true;result.provisional=true end
                        if field=='expectedQuantity' then
                            b.contributions[r.sourceKey]=(b.contributions[r.sourceKey] or 0)+weight
                            if r.fallbackOnly then
                                b.referenceFallback=true;result.referenceFallback=true
                                if original.referenceCorrection then result.referenceCorrection=true end
                            end
                            result.provisional=result.provisional or r.provisional==true
                            if mode==2 and r.sourceKey=='personal'
                                and personal.effectiveSamples<(self.ProcessingMinimum and self:ProcessingMinimum() or 30) then
                                result.insufficientSamples=true
                            end
                        elseif field=='dropChance' then
                            b.chanceProvisional=b.chanceProvisional or metadata.status=='provisional'
                                or metadata.status=='modeled' or metadata.status=='historical'
                            -- C1b: the chance becomes casts and drops for the counts model,
                            -- scaled by the source weight (and STALE_FACTOR when stale).
                            local casts=r.fieldSpecificEvidence and metadata.sampleSizeKnown==false
                                and 0 or self:EvidenceCasts(metadata,r)
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
                if original.personalHistogram and not m.expectationTransformed then
                    b.personalHistogram=original.personalHistogram;b.personalSamples=original.personalSamples
                end
                -- Conditional bounds belong to one named source, never an average.
                local lo,hi=m.minQuantity,m.maxQuantity
                if r.inputCount==batch and (not b.minQuantity or not b.maxQuantity) then
                    lo=self:EvidenceReliability(original.minQuantity,r)>0 and lo or nil
                    hi=self:EvidenceReliability(original.maxQuantity,r)>0 and hi or nil
                    if (lo and hi) or (not b.boundsSource and r.fieldSpecificEvidence and (lo or hi)) then
                        b.minQuantity=lo;b.maxQuantity=hi;b.boundsSource=r.source;b.boundsRecordID=r.recordID
                    end
                end
                end -- reference family already covered
                end -- individually identified material
            end
            -- Use the strongest accepted mean weight once per cohort. Refunds
            -- are per cast, so additional cooutputs do not add refund evidence.
            if acceptedMeanWeight>0 then
                contributingSalvage=contributingSalvage or r.salvage==true
                local consumed=model.expectedInputCount
                if compatible and finite(consumed) and consumed<=r.inputCount then
                    consumptionSum=consumptionSum+(consumed/r.inputCount)*acceptedMeanWeight
                    consumptionWeight=consumptionWeight+acceptedMeanWeight
                else
                    consumptionIncomplete=true
                end
            end
        end
    end
    if contributingSalvage then
        -- Price output only when any contributor has unknown net consumption.
        result.expectedInputCount=not consumptionIncomplete and batch*(consumptionSum/consumptionWeight) or nil
    end
    -- Existing per-gem baselines own their quantities. Keep uncovered legal
    -- identities as unknowns, without allocating the group total or duplicating
    -- a native quality family already covered by an individual baseline.
    local covered={}
    for _,material in pairs(bins) do
        for _,id in ipairs(material.rankIDs or {material.id}) do covered[id]=true end
    end
    local unidentified={}
    for id in pairs(groupOutputIDs) do
        if not covered[id] then
            local family=nativeItems[id].qualityFamilyID
            unidentified[family]=unidentified[family] or {}
            unidentified[family][#unidentified[family]+1]=id
        end
    end
    for _,ids in pairs(unidentified) do
        table.sort(ids,function(a,b)return nativeItems[a].qualityRank<nativeItems[b].qualityRank end)
        bins[ids[1]]={id=ids[1],rankIDs=#ids>1 and ids or nil,fields={},contributions={},sourceEstimates={},
            groupReference=true,unavailableReason='Grouped source total does not identify this gem quantity'}
    end
    local totalContribution,confidenceTotal=0,0
    local acceptedReviewedPrior,acceptedOtherQuantity=false,false
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
            b.chanceConfidence=p and math.floor(p.confidence/p.weight+.5)
        end
        local observed=b.samplingEvidence
        b.samplingEvidence=nil
        local independent=b.independentBoundsEvidence
        b.independentBoundsEvidence=nil
        local independentMaterial=independent and independent.material
        if observed and b.chance and b.expectedQuantity and math.abs(b.chance-observed.dropChance.value)<=1e-9
            and math.abs(b.expectedQuantity-observed.expectedQuantity.value)<=1e-9
            and b.minQuantity==observed.minQuantity.value and b.maxQuantity==observed.maxQuantity.value then
            b.samplingVariation=true
        elseif independentMaterial and independent.recordID==b.boundsRecordID
            and b.chance and b.expectedQuantity
            and math.abs(b.chance-independentMaterial.dropChance.value)<=1e-9
            and math.abs(b.expectedQuantity-independentMaterial.expectedQuantity.value)<=1e-9
            and b.minQuantity==independentMaterial.minQuantity.value and b.maxQuantity==independentMaterial.maxQuantity.value then
            -- Keep the actual observations. Another cohort's sampled extreme
            -- does not become a universal cap on this independently measured mean.
            b.observedBoundIndependence=copyReference(independentMaterial.observedBoundIndependence)
        elseif b.minQuantity and b.maxQuantity
            and violatedYieldBound(b.chance,b.expectedQuantity,b.minQuantity,b.maxQuantity) then
            -- A disagreement is useful evidence. Retain the named source's
            -- range instead of silently replacing observed bounds with '?'.
            b.inconsistentFields=true;result.fieldConflict=true
        end
        local stated=e and math.min(100,math.floor((e.confidence or 0)/e.weight+.5))
        -- Fill a missing average from the chance, or a missing chance from the
        -- average (middle of the quantity range). Filled figures count at half
        -- confidence (FILLED_CONFIDENCE_FACTOR).
        if (b.chance==nil and b.expectedQuantity~=nil and not b.chanceInferenceBlocked)
            or (b.expectedQuantity==nil and b.chance~=nil and not b.quantityInferenceBlocked) then
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
            b.reviewedPublishedPriorOnly=b.reviewedPriorQuantity and not b.otherQuantityContribution or nil
            acceptedReviewedPrior=acceptedReviewedPrior or b.reviewedPublishedPriorOnly==true
            acceptedOtherQuantity=acceptedOtherQuantity or b.reviewedPublishedPriorOnly~=true
            -- Per-material confidence (A3): shown on request, and used to value-weight the
            -- option's figure. C1b: from casts and drops when the chance has them; a
            -- filled average counts at half; never above the
            -- average's stated confidence; otherwise the sources' stated confidence.
            if b.derivedMean then
                b.confidence=math.floor(math.min(stated or 0,counts and counts.confidence*LL.FILLED_CONFIDENCE_FACTOR or (stated or 0))+.5)
            elseif b.filled=='average' then
                b.confidence=math.floor(b.chanceConfidence*LL.FILLED_CONFIDENCE_FACTOR+.5)
            elseif b.independentQuantityConfidence then
                b.confidence=stated
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
        for source,accumulator in pairs(b.sourceMeanAccumulators or {}) do
            local estimate=b.sourceEstimates[source]
            estimate.expectedQuantity=accumulator.sum/accumulator.weight
            estimate.inputCount=batch
            if accumulator.reviewedQualitySum~=nil then
                estimate.unprojectedQualityExpectedQuantity=(accumulator.sum-accumulator.reviewedQualitySum)/accumulator.weight
                estimate.reviewedQualityProjected=accumulator.reviewedQualityWeight>=accumulator.weight-1e-12
            end
            if accumulator.reviewedDisenchantSum~=nil then
                estimate.unprojectedDisenchantExpectedQuantity=(accumulator.sum-accumulator.reviewedDisenchantSum)/accumulator.weight
                estimate.reviewedDisenchantProjected=accumulator.reviewedDisenchantWeight>=accumulator.weight-1e-12
            end
            if #(estimate.records or {})>1 then
                estimate.recordID=nil;estimate.studyID=nil;estimate.aggregate=true
                estimate.dropChance=nil -- Individual occurrence evidence stays in records.
            end
        end
        b.sourceMeanAccumulators=nil
        local total=0 for _,v in pairs(b.contributions) do total=total+v end
        for source,w in pairs(b.contributions) do
            b.sourceContributions[source]=w/total
            result.sources[source]=(result.sources[source] or 0)+w/total
        end
        if e then totalContribution=totalContribution+1 else result.unknownOutputs=true end
        if not e then b.unavailableReason=b.conditionalRequirement and ('Requires '..b.conditionalRequirement..'; conditional estimate excluded from current value')
            or outputReasons[b.id] or 'Average unavailable for this source/character context' end
        b.fields=nil;b.contributions=nil;b.chanceSources=nil;b.chanceContributions=nil
        b.reviewedPriorQuantity=nil;b.otherQuantityContribution=nil
        b.chanceInferenceBlocked=nil;b.quantityInferenceBlocked=nil
        b.boundsRecordID=nil
        result.materials[#result.materials+1]=b
    end
    for key,v in pairs(result.sources) do result.sources[key]=v/math.max(1,totalContribution) end
    result.reviewedPublishedPriorOnly=acceptedReviewedPrior and not acceptedOtherQuantity or nil
    if personal and (result.sources.personal or 0)>0 then
        result.personalStats={total=personal.samples or 0,effectiveSamples=personal.effectiveSamples or personal.samples or 0}
        result.personalReference={}
        for _,key in ipairs({'sourcePatchBuild','targetPatchBuild','sourceReferenceOnly',
            'currentPatchApplicabilityConfidence','sourceApplicabilityConfidence','observationBuildPolicy',
            'personalSourceProfileMatched','numericTransformApplied','studyCoverageCensored','coverageCensored',
            'excludedUnresolvedOperations','excludedUnresolvedRecordIDs','studyCoverageGaps'}) do
            result.personalReference[key]=copyReference(personal[key])
        end
    end
    table.sort(result.materials,function(a,b) return a.id<b.id end)
    if totalContribution==0 then
        if not partialOnly then return nil,'Insufficient Data: expected quantities unknown' end
        result.confidenceUnscored=true
    end
    -- Conservative score of the actual contributing field evidence, not slider values.
    result.confidence=math.min(100,math.floor(confidenceTotal/math.max(1,totalContribution)+.5))
    if result.conflictingMeans then
        result.confidence=math.floor(result.confidence*.5)
        result.warning='Compatible sources disagree by more than 2x; confidence discounted'
    end
    if result.unknownOutputs then result.warning='Partial: some output quantities unknown' end
    if result.fieldConflict then
        local note='Source average/chance and retained conditional range disagree'
        result.warning=result.warning and (result.warning..'; '..note) or note
    end
    if result.referenceFallback then
        local note=result.referenceCorrection and 'Reference fallback; conflicting source mean replaced by a conservative estimate'
            or 'Reference fallback; current skill/patch applicability unverified'
        result.warning=result.warning and (result.warning..'; '..note) or note
    end
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
    local importedContext,importedRecords
    if self.ImportedSalvageContextKey then importedContext,importedRecords=self:ImportedSalvageContextKey(f,option,ctx) end
    local build=GetBuildInfo and select(2,GetBuildInfo())
    local key=table.concat({tostring(f.id),tostring(f.quality),tostring(f.classID),tostring(f.expansionID),tostring(f.itemLevel),
        tostring(option.name),tostring(option.inputCount),tostring(option.recipeID),tostring(option.character),
        tostring(ctx._cacheKey or ctx._cacheIdentity or fingerprint(ctx)),tostring(build),tostring(self.ItemDB and self.ItemDB.version),
        tostring(mode),tostring(personal and personal.effectiveSamples),tostring(personal and personal.samples),
        tostring(personal and personal.studyID),tostring(personal and personal.observationContextID),
        tostring(personal and personal.expectedInputCount),
        tostring(userWeight(self,'itemdb',mode)),tostring(userWeight(self,'personal',mode)),
        tostring(userWeight(self,'legacy',mode)),tostring(userWeight(self,'imported',mode)),
        tostring(userWeight(self,'reference',mode)),tostring(self._importedRevision),
        tostring(self.ItemDB and self.ItemDB.modelRevision),fingerprint(personal and personal.materials),
        tostring(self.ItemDB and self.ItemDB.specializationRevision),fingerprint(personal and personal.projectionRules),
        tostring(importedContext)},'|')
    self._processingModelCache=self._processingModelCache or {count=0}
    local cache=self._processingModelCache
    cache.count=cache.count or 0
    local now=GetTime and GetTime() or 0
    local cached=cache[key]
    if cached and cached.bindings and cached.contextIdentity==ctx._cacheIdentity and now-(cached.at or 0)<30
        and outputBindings(self,cached.model,cached.bindings) then
        return cached.model,cached.reason
    end
    if now-(cache.sweptAt or 0)>=5 or cache.count>=256 then
        local oldestKey,oldestAt
        for existing,entry in pairs(cache) do
            if type(entry)=='table' then
                if now-(entry.at or 0)>=30 then cache[existing]=nil;cache.count=cache.count-1
                elseif not oldestAt or (entry.at or 0)<oldestAt then oldestKey=existing;oldestAt=entry.at or 0 end
            end
        end
        cache.sweptAt=now
        if cache.count>=256 and not cache[key] and oldestKey then cache[oldestKey]=nil;cache.count=cache.count-1 end
    end
    local model,reason,retry=self:ComputeEvidenceModel(f,option,personal,mode,ctx,nil,importedRecords)
    if self.ApplyDisenchantBaseline then model=self:ApplyDisenchantBaseline(f,option,model,ctx,mode) end
    if model and self.ApplyGeneralProfessionAdditions then model=self:ApplyGeneralProfessionAdditions(f,option,model,ctx) end
    if model and self.ApplyGeneralProfessionQuality then model=self:ApplyGeneralProfessionQuality(f,option,model,ctx) end
    if model and not model.disenchantBaselineApplied then
        if model.generalProfessionApplied and model.projectedContext then ctx=model.projectedContext end
        if self.ApplySkillQualityModel then model=self:ApplySkillQualityModel(f,option,model,ctx) end
        if self.ApplySpecializationEffects then model=self:ApplySpecializationEffects(f,option,model,ctx) end
    end
    if model and self.ApplyProfessionOutputGates then model=self:ApplyProfessionOutputGates(f,option,model,ctx) end
    if retry then return model,reason end -- C2: an item name is loading; try again later
    if not cache[key] then cache.count=cache.count+1 end
    cache[key]={model=model,reason=reason,contextIdentity=ctx._cacheIdentity,at=now,
        bindings=outputBindings(self,model)}
    return model,reason
end
function LL:EvidenceDatabaseStatus()
    local counts={itemdb=0,legacy=0,imported=self.ImportedResultsCount and self:ImportedResultsCount() or 0}
    for _,records in pairs(self._evidenceIndex or {}) do
        for _,r in ipairs(records) do counts[r.sourceKey]=(counts[r.sourceKey] or 0)+1 end
    end
    local manifest=self.ItemDB and self.ItemDB.researchManifest or {}
    return ('ItemDB compiler %s: %d mappings (provisional unless normalized); legacy: %d; reference fallbacks: %d; imported casts: %d; profession rules: %d; personal patch rules: %d; v3 source %s'):format(
        tostring(manifest.compilerVersion or 'unknown'),counts.itemdb,
        counts.legacy,counts.reference or 0,counts.imported,#(self.ItemDB and self.ItemDB.professionRules or {}),#(self.ItemDB and self.ItemDB.personalPatchRules or {}),
        tostring(self.ItemDB and self.ItemDB.researchV3Manifest and self.ItemDB.researchV3Manifest.revision or 'unknown'):sub(1,12))
end
LL:InitializeItemDB()
