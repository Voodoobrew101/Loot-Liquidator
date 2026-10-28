-- Observation ownership: weighted aggregation and passive DE/processing collectors.
local ADDON, LL = ...
local subscriptions={}
local eventFrame=CreateFrame("Frame")
local function NewObserver()
    local observer={events={}}
    function observer:RegisterEvent(event)
        self.events[event]=true
        if not subscriptions[event] then subscriptions[event]={};eventFrame:RegisterEvent(event) end
        subscriptions[event][#subscriptions[event]+1]=self
    end
    function observer:SetScript(_,callback) self.callback=callback end
    return observer
end
eventFrame:SetScript("OnEvent",function(_,event,...)
    for _,observer in ipairs(subscriptions[event] or {}) do
        if observer.callback then observer.callback(observer,event,...) end
    end
end)

do -- Compatible observation aggregation
-- Statistical helpers shared by disenchanting and other processing research.
-- Prior SavedVariables brackets remain untouched. Nearby observations are
-- borrowed only when expansion, rarity, gear/source and specialization
-- mechanics are compatible; never assume a Blizzard probability formula.

local exp, abs, min = math.exp, math.abs, math.min
function LL:ResearchTolerance()
    local n=tonumber(self.db and self.db.researchSkillTolerance) or 10
    return math.max(0,math.min(40,n))
end
function LL:ResearchSpecSkillCorrection(oldSpec,newSpec)
    if oldSpec==newSpec then return 0 end
    return nil -- No reviewed numeric node-to-skill bridge is shipped.
end

-- 'observed' and 'current' are bracket tables with skill/spec fields.
-- Returning nil prevents borrowing. The slider is a HARD distance cap.
function LL:ResearchWeight(observed,current,quality,method,expansion)
    if not observed or not current then return nil end
    if type(observed.specialization)~="string" or type(current.specialization)~="string"
        or observed.specialization:find("unverified",1,true)
        or current.specialization:find("unverified",1,true) then
        -- A string like unverified@Character is NOT proof that the spec stayed
        -- constant between skill increases. Exact legacy keys still match.
        return nil
    end
    local correction=self:ResearchSpecSkillCorrection(observed.specialization,
        current.specialization,quality,method,expansion)
    if correction==nil then return nil end
    local oldSkill,newSkill=tonumber(observed.skill),tonumber(current.skill)
    if not oldSkill or not newSkill then return nil end
    local delta=abs(oldSkill+correction-newSkill)
    local tolerance=self:ResearchTolerance()
    if delta>tolerance or (tolerance==0 and delta~=0) then return nil end
    return tolerance==0 and 1 or exp(-0.5*(delta/tolerance)^2),delta,oldSkill+correction
end

-- Input entries = [{bracket=b, weight=w}]. Zero-drop outcomes are included
-- automatically through the bracket denominator; do NOT multiply by chance
-- twice. Histogram counts are weighted just like material quantities.
function LL:CombineResearchEntries(entries,currentSkill,minimum)
    local mats,weighted,weightSquares,raw={},0,0,0
    local exact,borrowed=0,0
    for _,entry in ipairs(entries or {}) do
        local b,w=entry.bracket,entry.weight
        if b and type(b.total)=="number" and b.total>0 and type(w)=="number" and w>0 then
            weighted=weighted+w*b.total
            weightSquares=weightSquares+w*w*b.total
            raw=raw+b.total
            if entry.exact then exact=exact+b.total else borrowed=borrowed+b.total end
            for id,m in pairs(b.mats or {}) do
                local target=mats[id] or {quantity=0,occurrences=0,quantityCounts={},min=nil,max=nil}
                target.quantity=target.quantity+(m.quantity or 0)*w
                target.occurrences=target.occurrences+(m.occurrences or 0)*w
                if m.min then target.min=math.min(target.min or m.min,m.min) end
                if m.max then target.max=math.max(target.max or m.max,m.max) end
                for q,n in pairs(m.quantityCounts or {}) do
                    target.quantityCounts[q]=(target.quantityCounts[q] or 0)+n*w
                end
                mats[id]=target
            end
        end
    end
    if weighted<=0 then return nil end
    local trendApplied=false -- No unreviewed skill-to-yield regression.
    return {mats=mats,total=raw,exactSamples=exact,borrowedSamples=borrowed,
        trendApplied=trendApplied,effectiveSamples=weighted,
        independentEquivalent=weightSquares>0 and weighted*weighted/weightSquares or 0}
end


end

do -- Disenchant event collection
-- Loot Liquidator: passive, opt-out disenchant research.
-- Only commit when a player's confirmed Disenchant cast consumes EXACTLY ONE
-- eligible piece of gear and yields one or more known Enchanting materials.
-- A bag change by itself is not proof of disenchanting. Never count trades,
-- vendor sales, crafting, multiple simultaneous changes, or unrelated loot.

local floor = math.floor
local DE_SPELL = 13262
local MIN_TRUSTED = 30
local MAX_RECENT = 2000
local candidateMaterial = {}

local function ValidMaterialID(id)
    return type(id)=="number" and candidateMaterial[id] == true
end

local function BuildKnownMaterials()
    candidateMaterial = {}
    for _,exp in pairs(LL.DisenchantTables or {}) do
        for _,rule in pairs(exp.quality or {}) do
            local function put(id) if type(id)=="number" and id>0 then candidateMaterial[id]=true end end
            put(rule.material);put(rule.higherQualityID)
            for _,id in ipairs(rule.candidates or {}) do put(id) end
            for _,id in ipairs(rule.referenceMaterials or {}) do put(id) end
            for _,line in ipairs(rule.averages or {}) do put(line.id) end
            for _,line in ipairs(rule.referenceRates or {}) do put(line.id) end
        end
    end
end
LL.RebuildDisenchantMaterialIDs = BuildKnownMaterials
BuildKnownMaterials()

local function Snapshot()
    local bagAPI = C_Container
    if not bagAPI or not bagAPI.GetContainerNumSlots or not bagAPI.GetContainerItemInfo then return nil end
    local snapshot={counts={},gear={}}
    for bag=0,5 do
        local slots=bagAPI.GetContainerNumSlots(bag) or 0
        for slot=1,slots do
            local info=bagAPI.GetContainerItemInfo(bag,slot)
            if info and type(info.itemID)=="number" and info.itemID>0 then
                local id,n=info.itemID,info.stackCount or 1
                snapshot.counts[id]=(snapshot.counts[id] or 0)+n
                if not ValidMaterialID(id) then
                    local f=LL.GetItemFacts and LL:GetItemFacts(info.hyperlink or ("item:"..id),{bagID=bag,slotID=slot,count=n})
                    if f and LL:EligibleDisenchant(f) then
                        snapshot.gear[id]=f
                    end
                end
            end
        end
    end
    return snapshot
end
LL.SnapshotDisenchantBags = Snapshot

local function Profile(f)
    local character=LL.CharacterKey and LL:CharacterKey() or "unknown character"
    local skill,specialization
    if LL.GetResearchProfessionSnapshot then
        skill,specialization=LL:GetResearchProfessionSnapshot(f,"Enchanting")
    end
    if not specialization then specialization="unverified@"..character end
    local mode=(f.classID==2) and "weapon" or "armor"
    local key=table.concat({tostring(f.expansionID),tostring(f.quality),mode,character,
        tostring(GetBuildInfo and select(2,GetBuildInfo()) or "unknown-build"),
        tostring(skill or "unknown skill"),specialization},"|")
    return key,mode,skill,specialization
end
LL.DisenchantObservationProfile = Profile

local function ResultDiff(before,after)
    if not before or not after then return nil,"missing snapshot" end
    local removed,added={},{}
    local all={}
    for id in pairs(before.counts) do all[id]=true end
    for id in pairs(after.counts) do all[id]=true end
    for id in pairs(all) do
        local b=before.counts[id] or 0
        local a=after.counts[id] or 0
        if b>a then removed[id]=b-a elseif a>b then added[id]=a-b end
    end
    local gear,gearCount=nil,0
    for id,n in pairs(removed) do
        local item=before.gear[id]
        if not item or n~=1 then return nil,"unrelated removal or multiple gear consumed" end
        gear=item;gearCount=gearCount+1
    end
    if gearCount>1 then return nil,"multiple pieces of gear consumed" end
    if gearCount~=1 then return nil,"not exactly one consumed gear item" end
    local yields,hasMats={},false
    for id,n in pairs(added) do
        if not ValidMaterialID(id) then return nil,"unrelated or unrecognized item gained" end
        yields[id]=n;hasMats=true
    end
    if not hasMats then return nil,"no tracked Enchanting materials received" end
    -- Only materials from the same expansion can be attributed to the cast.
    local exp=LL.DisenchantTables and LL.DisenchantTables[gear.expansionID]
    if not exp then return nil,"gear expansion not in recorded tables" end
    local allowed={}
    for _,rule in pairs(exp.quality or {}) do
        for _,id in ipairs(rule.candidates or {}) do allowed[id]=true end
        for _,id in ipairs(rule.referenceMaterials or {}) do allowed[id]=true end
        for _,avg in ipairs(rule.averages or {}) do allowed[avg.id]=true end
        for _,rate in ipairs(rule.referenceRates or {}) do allowed[rate.id]=true end
        if rule.material then allowed[rule.material]=true end
        if rule.higherQualityID then allowed[rule.higherQualityID]=true end
    end
    for id in pairs(yields) do
        if not allowed[id] then return nil,"material from a different expansion" end
    end
    return gear,yields
end
LL.DisenchantBagDiff = ResultDiff

function LL:SaveDisenchantObservation(gear,yields)
    if not self.db or self.db.recordDisenchants==false or not gear or not yields then return false end
    if not self:EligibleDisenchant(gear) then return false end
    local key,mode,skill,specialization=Profile(gear)
    local data=self.db.disenchantLearning
    if not data then data={brackets={},recent={},total=0};self.db.disenchantLearning=data end
    local bracket=data.brackets[key]
    if not bracket then
        bracket={expansion=gear.expansionID,quality=gear.quality,mode=mode,
            skill=skill,specialization=specialization,character=self:CharacterKey(),
            patchBuild=GetBuildInfo and select(2,GetBuildInfo()),total=0,mats={},items={}}
        data.brackets[key]=bracket
    end
    bracket.total=bracket.total+1
    local item=bracket.items[gear.id] or {n=0,level=gear.itemLevel}
    item.n=item.n+1
    bracket.items[gear.id]=item
    for id,quantity in pairs(yields) do
        local mat=bracket.mats[id] or {occurrences=0,quantity=0,min=nil,max=nil,quantityCounts={}}
        mat.occurrences=mat.occurrences+1
        mat.quantity=mat.quantity+quantity
        mat.min=math.min(mat.min or quantity,quantity)
        mat.max=math.max(mat.max or quantity,quantity)
        mat.quantityCounts=mat.quantityCounts or {}
        mat.quantityCounts[quantity]=(mat.quantityCounts[quantity] or 0)+1
        bracket.mats[id]=mat
    end
    data.total=(data.total or 0)+1
    local recent=data.recent
    recent[#recent+1]={time=time and time() or 0,itemID=gear.id,
        itemLevel=gear.itemLevel,expansion=gear.expansionID,quality=gear.quality,
        mode=mode,profile=key,character=self:CharacterKey(),mats=yields}
    if #recent>MAX_RECENT then table.remove(recent,1) end
    if self.Invalidate then self:Invalidate() end
    return true
end

-- Match exact and compatible nearby skill brackets without changing old
-- SavedVariables keys. Unknown skill/spec samples stay quarantined unless
-- their entire original bracket key matches.
function LL:MatchingDisenchantResearch(f)
    local data=self.db and self.db.disenchantLearning
    if not data or not data.brackets then return nil end
    local key,mode,skill,spec=Profile(f)
    local entries={}
    for oldKey,b in pairs(data.brackets) do
        if b.expansion==f.expansionID and b.quality==f.quality and b.mode==mode
            and b.character==self:CharacterKey()
            and b.patchBuild==(GetBuildInfo and select(2,GetBuildInfo())) then
            local weight,delta,adjustedSkill
            if oldKey==key then weight,delta,adjustedSkill=1,0,tonumber(b.skill)
            elseif self.ResearchWeight then
                weight,delta,adjustedSkill=self:ResearchWeight(b,{skill=skill,specialization=spec},
                    f.quality,"Disenchant",f.expansionID)
            end
            if weight then
                entries[#entries+1]={bracket=b,weight=weight,exact=(oldKey==key),distance=delta,
                    adjustedSkill=adjustedSkill}
            end
        end
    end
    if #entries==0 then return nil end
    if self.CombineResearchEntries then
        return self:CombineResearchEntries(entries,skill,self:ProcessingMinimum())
    end
    -- Compatibility with lightweight test harnesses loading the tracker alone.
    local b=data.brackets[key]
    if not b then return nil end
    return {mats=b.mats,total=b.total,exactSamples=b.total,borrowedSamples=0,
        effectiveSamples=b.total,independentEquivalent=b.total}
end

function LL:GetLearnedDisenchantEstimate(f,family)
    if not self.db or not family then return nil end
    local pool=self:MatchingDisenchantResearch(f)
    if not pool then return nil end
    local materials,gross,allPriced={},0,true
    for id,mat in pairs(pool.mats) do
        local chance=mat.occurrences/pool.effectiveSamples
        local expected=mat.quantity/pool.effectiveSamples
        local unit=self:Price("dbminbuyout",self:TSMString(nil,id))
            or self:Price("dbmarket",self:TSMString(nil,id))
            or self:Price("dbregionmarketavg",self:TSMString(nil,id))
        if not unit then allPriced=false else gross=gross+unit*expected end
        materials[#materials+1]={id=id,chance=chance,
            meanQuantity=mat.occurrences>0 and mat.quantity/mat.occurrences or 0,
            expectedQuantity=expected,minQuantity=mat.min,maxQuantity=mat.max,
            expectedValue=unit and unit*expected or nil,unitPrice=unit,
            quantityCounts=mat.quantityCounts,occurrences=mat.occurrences,
            samples=pool.effectiveSamples}
    end
    table.sort(materials,function(a,b) return a.id<b.id end)
    local minimum=self.ProcessingMinimum and self:ProcessingMinimum() or MIN_TRUSTED
    local eligible=pool.effectiveSamples>=minimum
    local net=allPriced and gross*(1-self:AHFeeRate()) or nil
    return {name="Disenchant",value=eligible and net or nil,
        indicativeValue=net,expansion=f.expansionID,expansionName=family.name,
        confidence=eligible and "observed-local" or "observed-provisional",
        samples=pool.total,exactSamples=pool.exactSamples,
        borrowedSamples=pool.borrowedSamples,effectiveSamples=pool.effectiveSamples,
        independentEquivalent=pool.independentEquivalent,trendApplied=pool.trendApplied,
        materials=materials,
        note=("Personal observations: %d exact + %d nearby (%.1f effective / %d required)"):format(
            pool.exactSamples,pool.borrowedSamples,pool.effectiveSamples,minimum)}
end

function LL:DisenchantStatsFor(f)
    if not f or not self.db then return nil end
    local p=self:MatchingDisenchantResearch(f)
    if not p then return nil end
    return {total=p.total,exactSamples=p.exactSamples,
        borrowedSamples=p.borrowedSamples,effectiveSamples=p.effectiveSamples,
        mats=p.mats}
end

function LL:ShowDisenchantStats()
    local d=self.db and self.db.disenchantLearning or {}
    local lines={}
    for key,b in pairs(d.brackets or {}) do
        lines[#lines+1]=key..": "..b.total.." samples ("..
            (b.total>=(self.ProcessingMinimum and self:ProcessingMinimum() or MIN_TRUSTED) and "learned valuation enabled" or ((self.ProcessingMinimum and self:ProcessingMinimum() or MIN_TRUSTED)-b.total).." to threshold")..")"
    end
    table.sort(lines)
    table.insert(lines,1,"Loot Liquidator disenchant observations: "..tostring(d.total or 0))
    return table.concat(lines,"\n")
end
function LL:ExportDisenchantData()
    local lines={}
    for _,b in pairs(self.db and self.db.disenchantLearning and self.db.disenchantLearning.brackets or {}) do
        for id,mat in pairs(b.mats) do
            lines[#lines+1]=table.concat({b.expansion,b.quality,b.mode,b.skill or "",'"'..tostring(b.specialization):gsub('"','""')..'"',
                b.total,id,mat.occurrences,mat.quantity,mat.min,mat.max,
                '"'..(function() local h={} for n,c in pairs(mat.quantityCounts or {}) do h[#h+1]=tostring(n)..'='..tostring(c) end table.sort(h) return table.concat(h,';') end)()..'"'},",")
        end
    end
    table.sort(lines)
    table.insert(lines,1,"expansion,quality,gearType,skill,specialization,samples,materialID,occurrences,totalQuantity,minQuantity,maxQuantity,quantityHistogram")
    return table.concat(lines,"\n")
end

-- Live capture is owned by CraftRecording.lua; legacy aggregates remain
-- readable/exportable and are never silently upgraded to complete cast logs.

end

do -- Other processing event collection
-- Shared research for stochastic processing other than disenchanting.
-- Requires a confirmed cast AND an unambiguous one-input bag delta.
-- Observations, quantity histograms and the processed quantity are SavedVariables.

local MIN_DEFAULT = 30
local RECENT_LIMIT = 2000
local CAST_METHOD = {
    [51005]="Mill",[31252]="Prospect", -- original casts
    [382981]="Mill",[374627]="Prospect", -- Dragon Isles
    [444181]="Mill",[434018]="Prospect", -- Khaz Algar
    [1269575]="Mill",[1231127]="Prospect", -- Midnight
}
local METHODS = {Mill=true,Prospect=true,Smelt=true,Recycle=true,Research=true,
    Craft=true,Unravel=true,Thaumaturgy=true}
local function Mode(method)
    local db=LL.db or {}
    if method=="Disenchant" then return db.disenchantDataMode or 1 end
    if method=="Mill" then return db.millingDataMode or 1 end
    if method=="Prospect" then return db.prospectingDataMode or 1 end
    return db.otherConversionDataMode or 1
end
function LL:ProcessingDataMode(method) return Mode(method) end
function LL:ProcessingMinimum() return math.max(1,tonumber(self.db and self.db.minPersonalSamples) or MIN_DEFAULT) end

local function Profile(f,method,consumed,recipeID)
    local who=LL.CharacterKey and LL:CharacterKey() or "unknown"
    local profession=LL.ProfessionForMethod and LL:ProfessionForMethod(method)
    local skill,specialization
    if LL.GetResearchProfessionSnapshot and profession then
        skill,specialization=LL:GetResearchProfessionSnapshot(f,profession)
    end
    skill=tostring(skill or "unknown")
    specialization=specialization and ("verified:"..specialization)
        or ("unverified@"..who)
    local recipe=tostring(recipeID or "unknown-recipe")
    return table.concat({method,tostring(f.id),tostring(f.expansionID or "?"),
        tostring(f.reagentQuality or "?"),tostring(consumed),recipe,who,
        tostring(GetBuildInfo and select(2,GetBuildInfo()) or "unknown-build"),skill,specialization},"|"),
        skill,specialization
end
LL.ProcessingObservationProfile=Profile
function LL:SaveProcessingObservation(method,f,consumed,outputs,spellID)
    if not self.db or self.db.recordConversions==false or not METHODS[method] then return false end
    if not f or type(f.id)~="number" or type(consumed)~="number" or consumed<1
        or consumed~=math.floor(consumed) or type(outputs)~="table" then return false end
    local has=false
    for id,n in pairs(outputs) do
        if type(id)~="number" or type(n)~="number" or n<1 or n~=math.floor(n)
            or id==f.id then return false end
        has=true
    end
    if not has then return false end
    local key,skill,specialization=Profile(f,method,consumed,spellID)
    self.db.processingLearning=self.db.processingLearning or {brackets={},recent={},inputs={},total=0}
    local data=self.db.processingLearning
    data.brackets=data.brackets or {};data.recent=data.recent or {};data.inputs=data.inputs or {}
    local b=data.brackets[key]
    if not b then
        b={method=method,inputID=f.id,expansion=f.expansionID,quality=f.quality,
            inputCount=consumed,skill=skill,specialization=specialization,
            total=0,mats={}}
        data.brackets[key]=b
    end
    b.total=b.total+1
    for id,n in pairs(outputs) do
        local mat=b.mats[id] or {occurrences=0,quantity=0,min=nil,max=nil,quantityCounts={}}
        mat.occurrences=mat.occurrences+1
        mat.quantity=mat.quantity+n
        mat.min=math.min(mat.min or n,n);mat.max=math.max(mat.max or n,n)
        mat.quantityCounts=mat.quantityCounts or {}
        mat.quantityCounts[n]=(mat.quantityCounts[n] or 0)+1
        b.mats[id]=mat
    end
    data.inputs[f.id]=method
    data.total=(data.total or 0)+1
    local recent=data.recent
    recent[#recent+1]={time=time and time() or 0,method=method,inputID=f.id,
        inputCount=consumed,expansion=f.expansionID,quality=f.quality,
        profile=key,spellID=spellID,outputs=outputs}
    if #recent>RECENT_LIMIT then table.remove(recent,1) end
    if self.Invalidate then self:Invalidate() end
    return true
end
function LL:MatchingProcessingResearch(f,method,consumed,recipeID)
    local d=self.db and self.db.processingLearning
    if not d or not d.brackets then return nil end
    local key,skill,spec=Profile(f,method,consumed or 5,recipeID)
    local entries={}
    for oldKey,b in pairs(d.brackets) do
        -- Match full source/recipe identity; do not blend unlike input counts.
        local prefix=oldKey:match("^(.-)|[^|]*|[^|]*$")
        local targetPrefix=key:match("^(.-)|[^|]*|[^|]*$")
        if prefix==targetPrefix then
            local weight,delta,adjustedSkill
            if oldKey==key then weight,delta,adjustedSkill=1,0,tonumber(b.skill)
            elseif self.ResearchWeight then
                weight,delta,adjustedSkill=self:ResearchWeight(b,{skill=skill,specialization=spec},
                    f.quality,method,f.expansionID)
            end
            if weight then entries[#entries+1]={bracket=b,weight=weight,
                exact=(oldKey==key),distance=delta,
                    adjustedSkill=adjustedSkill} end
        end
    end
    if #entries==0 then return nil end
    if self.CombineResearchEntries then
        return self:CombineResearchEntries(entries,tonumber(skill),self:ProcessingMinimum())
    end
    local b=d.brackets[key]
    if b then
        b.exactSamples=b.total
        b.borrowedSamples=0
        b.effectiveSamples=b.total
    end
    return b
end
function LL:GetProcessingStatsFor(f,method,consumed,recipeID)
    return self:MatchingProcessingResearch(f,method,consumed,recipeID)
end
function LL:GetLearnedProcessingEstimate(f,method,consumed,recipeID)
    local b=self:GetProcessingStatsFor(f,method,consumed,recipeID)
    if not b then return nil end
    local mats,gross,allPriced={},0,true
    for id,mat in pairs(b.mats or {}) do
        local expected=mat.quantity/b.effectiveSamples
        local key=self:TSMString(nil,id)
        local unit=self:Price("dbminbuyout",key) or self:Price("dbmarket",key)
            or self:Price("dbregionmarketavg",key)
        if not unit then allPriced=false else gross=gross+unit*expected end
        mats[#mats+1]={id=id,chance=mat.occurrences/b.effectiveSamples,
            meanQuantity=mat.occurrences>0 and mat.quantity/mat.occurrences or 0,
            expectedQuantity=expected,minQuantity=mat.min,maxQuantity=mat.max,
            quantityCounts=mat.quantityCounts,occurrences=mat.occurrences,
            samples=b.effectiveSamples,expectedValue=unit and unit*expected or nil,unitPrice=unit}
    end
    table.sort(mats,function(a,b) return a.id<b.id end)
    local eligible=b.effectiveSamples>=self:ProcessingMinimum()
    local val=allPriced and gross*(1-self:AHFeeRate())/(consumed or 5) or nil
    -- Value is per input; heading breakdown is gross per whole operation.
    local perCast=allPriced and gross*(1-self:AHFeeRate()) or nil
    return {name=method,samples=b.total,exactSamples=b.exactSamples,
        borrowedSamples=b.borrowedSamples,effectiveSamples=b.effectiveSamples,
        trendApplied=b.trendApplied,inputCount=consumed,materials=mats,perCastValue=perCast,
        value=(eligible and val) or nil,indicativeValue=val,
        confidence=eligible and "observed-local" or "observed-provisional",
        note=("Personal %s: %d exact + %d nearby (%.1f effective / %d required)"):format(
            method,b.exactSamples,b.borrowedSamples,b.effectiveSamples,self:ProcessingMinimum()),
        source="Personal recorded results"}
end
function LL:ShowProcessingStats()
    local data=self.db and self.db.processingLearning or {}
    local lines={"Recorded processing casts: "..tostring(data.total or 0)}
    local keys={};for key in pairs(data.brackets or {}) do keys[#keys+1]=key end
    table.sort(keys)
    for _,key in ipairs(keys) do
        local b=data.brackets[key]
        lines[#lines+1]=key.." | "..b.total.." operations"
        for id,m in pairs(b.mats or {}) do
            lines[#lines+1]=("  Material %d: %.1f%% drops; %.3f avg/unit operation"):format(
                id,100*m.occurrences/b.total,m.quantity/b.total)
        end
    end
    return table.concat(lines,"\n")
end
function LL:ExportProcessingData()
    local lines={"method,inputID,expansion,quality,inputsPerCast,samples,materialID,occurrences,totalQuantity,quantityHistogram"}
    for _,b in pairs(self.db and self.db.processingLearning and self.db.processingLearning.brackets or {}) do
        for id,m in pairs(b.mats or {}) do
            local hist={}
            for q,n in pairs(m.quantityCounts or {}) do hist[#hist+1]=tostring(q).."="..n end
            table.sort(hist)
            lines[#lines+1]=table.concat({b.method,b.inputID,b.expansion or "",b.quality or "",
                b.inputCount,b.total,id,m.occurrences,m.quantity,'"'..table.concat(hist,";")..'"'},",")
        end
    end
    table.sort(lines, function(a,b) if a:find("^method,") then return true end
        if b:find("^method,") then return false end return a<b end)
    return table.concat(lines,"\n")
end

-- Live spell/result attribution is owned by CraftRecording.lua.

end
