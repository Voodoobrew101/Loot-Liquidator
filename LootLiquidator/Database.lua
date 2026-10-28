-- Versioned evidence interface. No prices or live scans are cached here.
local _, LL = ...
local defaults={itemdb={true,100},personal={true,60},tsm={true,30},legacy={false,10}}
LL.SourceDefaults=defaults
local order={'itemdb','personal','tsm','legacy'}
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
function LL:MigrateEvidenceSettings()
    if not self.db then return end
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
    self.db.evidenceSchemaVersion=1
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
            or not defaults[r.sourceKey] or not finite(r.inputCount) or r.inputCount<=0 or r.inputCount%1~=0
            or (not (finite(r.inputItemID) and r.inputItemID>0 and r.inputItemID%1==0)
                and not (r.method=='Disenchant' and type(r.gearKey)=='string' and
                    (r.gearKey:match('^gear:%d+:%d+:armor$') or r.gearKey:match('^gear:%d+:%d+:weapon$'))))
            or (r.recipeID~=nil and (not finite(r.recipeID) or r.recipeID<1 or r.recipeID%1~=0))
            or (r.referenceConditions~=nil and type(r.referenceConditions)~='table')
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
function LL:InitializeItemDB()
    self._processingModelCache=nil
    local ok,reason=self:ValidateItemDB(self.ItemDB)
    self.itemDBError=not ok and reason or nil
    self._evidenceIndex={}
    if not ok then return false end
    for _,r in ipairs(self.ItemDB.processing) do
        local key=r.method..':'..tostring(r.inputItemID or r.gearKey)
        local list=self._evidenceIndex[key] or {};self._evidenceIndex[key]=list
        list[#list+1]=r
    end
    local compat=self.ItemDB.compat or {}
    for k,v in pairs(compat) do self[k]=v end -- aliases, never copied data
    self.GameData=self.GameData or {}
    self.GameData.verifiedMechanicsRules=self.ItemDB.mechanicRules
    self.GameDataVersion=self.ItemDB.version
    self.ResearchProcessingOutputs=self.ItemDB.inputs
    return true
end
function LL:ResearchProcessingInput(id)
    return self.ItemDB and self.ItemDB.inputs and self.ItemDB.inputs[id]
end
-- A confidence score is an ordinal evidence-quality score, not a posterior.
-- Sample saturation and provenance class are independent conservative discounts.
function LL:EvidenceReliability(field,record)
    if not field or field.value==nil or field.status=='unknown' or field.status=='contradictory' then return 0 end
    local score=math.min(1,math.max(0,(field.confidence or 0)/100))
    local n=field.samples or record.samples
    local sampleFactor=finite(n) and n/(n+30) or 0.35
    local class=({verified=1,measured=1,observed=1,provisional=.6,modeled=.25,historical=.4})[field.status] or 0
    return score*sampleFactor*class
end
local function gearKey(f)
    return 'gear:'..tostring(f.expansionID)..':'..tostring(f.quality)..':'..
        (f.classID==2 and 'weapon' or 'armor')
end
local function contextEligible(record,ctx,build,model,rules)
    if record.targetBuild and tostring(record.targetBuild)~=tostring(build) then return false end
    if record.patchEndBuild and (not tonumber(build) or tonumber(build)>record.patchEndBuild) then return false end
    if record.patchStartBuild and (not tonumber(build) or tonumber(build)<record.patchStartBuild) then return false end
    if record.obsolete or record.hotfixBlocked then return false end
    for key,v in pairs(record.referenceConditions or {}) do
        if not same(ctx[key],v) then
            if not model or not model.mechanicsApplied then return false end
            for _,material in ipairs(model.materials) do
                if material.expectedQuantity~=nil then
                    local covered=false
                    for _,rule in ipairs(rules or {}) do
                        if rule.ruleID==material.appliedExpectationRule and same(rule.targetConditions[key],ctx[key]) then covered=true end
                    end
                    if not covered then return false end
                end
            end
        end
    end
    return true
end
local function userWeight(self,key,mode)
    local d=defaults[key]
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
        duration=r.duration,expectedInputCount=r.expectedInputCount,materials={},source=r.source}
    for _,m in ipairs(r.materials) do
        model.materials[#model.materials+1]={id=m.id,expectedQuantity=m.expectedQuantity.value,
            chance=m.dropChance.value,probabilityVerified=m.dropChance.status=='verified' or m.dropChance.status=='measured',
            minQuantity=m.minQuantity.value,maxQuantity=m.maxQuantity.value}
    end
    return self.ApplyVerifiedMechanics and self:ApplyVerifiedMechanics(f,option,model) or model
end
function LL:ComputeEvidenceModel(f,option,personal,mode,ctx)
    if ctx.simulated then personal=nil end
    local build=GetBuildInfo and select(2,GetBuildInfo())
    local input=option.name=='Disenchant' and gearKey(f) or f.id
    local records=self._evidenceIndex and self._evidenceIndex[option.name..':'..tostring(input)] or {}
    local eligible,transformed={},{}
    for _,r in ipairs(records) do
        local hasMean=false
        for _,material in ipairs(r.materials) do
            if self:EvidenceReliability(material.expectedQuantity,r)>0 then hasMean=true;break end
        end
        local model=sourceModel(self,f,option,r)
        transformed[r]=model
        if hasMean and userWeight(self,r.sourceKey,mode)>0 and (not r.recipeID or r.recipeID==option.recipeID)
            and (not r.inputQualityRank or r.inputQualityRank==ctx.inputQuality)
            and (not r.expansionID or r.expansionID==f.expansionID)
            and contextEligible(r,ctx,build,model,self.ItemDB.mechanicRules) then eligible[#eligible+1]=r end
    end
    if personal and personal.observationContext and (ctx.simulated or ctx.character~=personal.observationContext.character) then
        personal=nil -- measured current-character samples cannot stand in for a simulation or alt
    end
    if personal and userWeight(self,'personal',mode)>0 and (personal.effectiveSamples or 0)>0 then
        local r={recordID='personal',sourceKey='personal',studyID=personal.studyID or ('personal:'..tostring(ctx.character)),
            source='Personal recorded results',inputCount=personal.inputCount or option.inputCount or 1,
            samples=personal.effectiveSamples,referenceConditions=copy(ctx),
            referenceContextID=personal.referenceContextID,patchBuild=personal.patchBuild,expectedInputCount=personal.expectedInputCount,
            materials={},provisional=(personal.effectiveSamples or 0)<(self.ProcessingMinimum and self:ProcessingMinimum() or 30)}
        for _,m in ipairs(personal.materials or {}) do
            r.materials[#r.materials+1]={id=m.id,quality=m.quality,rarity=m.rarity,
                expectedQuantity={value=m.expectedQuantity,confidence=85,status='observed'},
                dropChance={value=m.chance,confidence=85,status='observed'},
                minQuantity={value=m.minQuantity,confidence=85,status='observed'},
                maxQuantity={value=m.maxQuantity,confidence=85,status='observed'},
                personalHistogram=m.quantityCounts,personalSamples=m.samples}
        end
        if #r.materials>0 then eligible[#eligible+1]=r end
    end
    -- Primary database first, then an independent measured personal context.
    -- Incompatible/unknown historical contexts are never silently pooled.
    table.sort(eligible,function(a,b)
        local rank={itemdb=1,personal=2,tsm=3,legacy=4}
        if rank[a.sourceKey]~=rank[b.sourceKey] then return rank[a.sourceKey]<rank[b.sourceKey] end
        return a.recordID<b.recordID
    end)
    local anchor=eligible[1]
    if not anchor then return nil,'Insufficient Data: no enabled compatible source' end
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
        if not sameContext(r) then
            result.excludedSources[#result.excludedSources+1]=r.sourceKey..': reference context cannot be normalized'
        else
            -- Build a model, then apply the preserved PR #4 adapter exactly once.
            local model=transformed[r] or sourceModel(self,f,option,r)
            if r==anchor and model.expectedInputCount~=nil then
                result.expectedInputCount=model.expectedInputCount*batch/r.inputCount
            end
            if model.mechanicsApplied then
                result.adjustment='character-adjusted';result.mechanicsApplied=true
                if r==anchor then
                    result.expectedInputCount=model.expectedInputCount and model.expectedInputCount*batch/r.inputCount
                    result.duration=model.duration
                end
            end
            for i,m in ipairs(model.materials) do
                local original=r.materials[i]
                local id=m.id
                local b=bins[id] or {id=id,quality=original.quality,rarity=original.rarity,
                    fields={},contributions={}};bins[id]=b
                for field,modelField in pairs({expectedQuantity='expectedQuantity',dropChance='chance'}) do
                    local key=r.studyID..':'..id..':'..field
                    local metadata=copy(original[field]);metadata.value=m[modelField]
                    if m.transformConfidence then metadata.confidence=math.min(metadata.confidence,m.transformConfidence) end
                    local weight=userWeight(self,r.sourceKey,mode)*self:EvidenceReliability(metadata,r)
                    if field=='dropChance' and r.inputCount~=batch then weight=0 end
                    if weight>0 and not studySeen[key] then
                        studySeen[key]=true
                        local v=m[modelField]
                        if field=='expectedQuantity' then v=v*batch/r.inputCount end
                        local acc=b.fields[field] or {sum=0,weight=0};b.fields[field]=acc
                        acc.minimum=math.min(acc.minimum or v,v);acc.maximum=math.max(acc.maximum or v,v)
                        acc.sum=acc.sum+v*weight;acc.weight=acc.weight+weight
                        if field=='expectedQuantity' then acc.confidence=(acc.confidence or 0)+(metadata.confidence or 0)*weight end
                        if field=='expectedQuantity' then
                            b.contributions[r.sourceKey]=(b.contributions[r.sourceKey] or 0)+weight
                            result.provisional=result.provisional or r.provisional==true
                            if mode==2 and r.sourceKey=='personal' and r.provisional then result.insufficientSamples=true end
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
        b.chance=p and p.sum/p.weight
        if b.chance and b.expectedQuantity and b.minQuantity and b.maxQuantity
            and (b.expectedQuantity+1e-9<b.chance*b.minQuantity or b.expectedQuantity>b.chance*b.maxQuantity+1e-9) then
            b.minQuantity=nil;b.maxQuantity=nil;b.boundsSource=nil
        end
        if e then confidenceTotal=confidenceTotal+(e.confidence or 0)/e.weight end
        b.sourceContributions={}
        local total=0 for _,v in pairs(b.contributions) do total=total+v end
        for source,w in pairs(b.contributions) do
            b.sourceContributions[source]=w/total
            result.sources[source]=(result.sources[source] or 0)+w/total
        end
        if e then totalContribution=totalContribution+1 else result.unknownOutputs=true end
        b.fields=nil;b.contributions=nil
        result.materials[#result.materials+1]=b
    end
    for key,v in pairs(result.sources) do result.sources[key]=v/math.max(1,totalContribution) end
    table.sort(result.materials,function(a,b) return a.id<b.id end)
    if totalContribution==0 then return nil,'Insufficient Data: expected quantities unknown' end
    -- Conservative score of the actual contributing field evidence, not slider values.
    result.confidence=math.min(100,math.floor(confidenceTotal/math.max(1,totalContribution)+.5))
    if result.conflictingMeans then
        result.confidence=math.floor(result.confidence*.5)
        result.warning='Compatible sources disagree by more than 2x; confidence discounted'
    end
    if result.unknownOutputs then result.warning='Insufficient Data: some output quantities unknown' end
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
        tostring(mode),tostring(personal and personal.effectiveSamples),
        tostring(personal and personal.studyID),tostring(personal and personal.observationContextID),
        tostring(personal and personal.expectedInputCount),
        tostring(userWeight(self,'itemdb',mode)),tostring(userWeight(self,'personal',mode)),
        tostring(userWeight(self,'tsm',mode)),tostring(userWeight(self,'legacy',mode))},'|')
    self._processingModelCache=self._processingModelCache or {count=0}
    local cached=self._processingModelCache[key]
    if cached then return cached.model,cached.reason end
    if self._processingModelCache.count>=512 then self._processingModelCache={count=0} end
    local model,reason=self:ComputeEvidenceModel(f,option,personal,mode,ctx)
    self._processingModelCache[key]={model=model,reason=reason}
    self._processingModelCache.count=self._processingModelCache.count+1
    return model,reason
end
LL:InitializeItemDB()
