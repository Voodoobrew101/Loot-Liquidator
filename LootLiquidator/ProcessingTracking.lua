-- Shared research for stochastic processing other than disenchanting.
-- Requires a confirmed cast AND an unambiguous one-input bag delta.
-- Observations, quantity histograms and the processed quantity are SavedVariables.
local ADDON, LL = ...
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
    local recipe=(method=="Mill" or method=="Prospect") and "generic"
        or tostring(recipeID or "unknown-recipe")
    return table.concat({method,tostring(f.id),tostring(f.expansionID or "?"),
        tostring(f.quality or "?"),tostring(consumed),recipe,skill,specialization},"|"),
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

-- The recorded input must disappear in a completed spell cast. Never infer
-- processing from bag changes without a matching successful spell.
local function Snapshot()
    if not C_Container or not C_Container.GetContainerNumSlots
        or not C_Container.GetContainerItemInfo then return nil end
    local snap={counts={},candidates={}}
    for bag=0,5 do
        for slot=1,(C_Container.GetContainerNumSlots(bag) or 0) do
            local item=C_Container.GetContainerItemInfo(bag,slot)
            if item and type(item.itemID)=="number" then
                local id=item.itemID
                snap.counts[id]=(snap.counts[id] or 0)+(item.stackCount or 1)
                if LL.GetItemFacts then
                    local known=(LL.Conversions and LL.Conversions[id])
                        or (LL.DestroyInputs and LL.DestroyInputs[id])
                        or (LL.db and LL.db.processingLearning and LL.db.processingLearning.inputs
                            and LL.db.processingLearning.inputs[id])
                    if known or item.hyperlink then
                        local f=LL:GetItemFacts(item.hyperlink or ("item:"..id),{count=item.stackCount or 1})
                        if f then snap.candidates[id]=f end
                    end
                end
            end
        end
    end
    return snap
end
LL.SnapshotProcessingBags=Snapshot
local function Match(before,after,method,spellID)
    if not before or not after then return nil,"missing snapshot" end
    local removed,added={},{}
    for id,n in pairs(before.counts) do
        local diff=n-(after.counts[id] or 0)
        if diff>0 then removed[id]=diff end
    end
    for id,n in pairs(after.counts) do
        local diff=n-(before.counts[id] or 0)
        if diff>0 then added[id]=diff end
    end
    local id,quantity,distinct=nil,nil,0
    for source,n in pairs(removed) do id=source;quantity=n;distinct=distinct+1 end
    if distinct>1 then return nil,"multiple source items removed" end
    if distinct==0 then return nil,"not exactly one source item removed" end
    local f=before.candidates[id]
    if not f then return nil,"missing source information" end
    local expectedOutput
    if method=="Mill" or method=="Prospect" then
        -- Midnight milling uses 10 herbs; older milling and prospecting
        -- commonly use 5. Always store the actual consumed batch size.
        local modern=LL.ResearchProcessingInput and LL:ResearchProcessingInput(f.id)
        local minBatch=(modern and modern.method==method and modern.batch)
            or (method=="Mill" and (f.expansionID==10 or f.expansionID==11) and 10 or 5)
        if (modern and modern.method~=method)
            or f.classID~=7 or f.subClassID~=(method=="Mill" and 9 or 7)
            or quantity<minBatch or quantity%minBatch~=0 then
            return nil,"not a valid reagent batch" end
    else
        local matched=false
        for _,c in ipairs((LL.Conversions and LL.Conversions[id]) or {}) do
            if c.method==method and (c.requiredSpell==spellID or c.recipeID==spellID)
                and (not c.inputCount or c.inputCount==quantity) then
                matched=true;expectedOutput=c.outputID;break end
        end
        for _,c in pairs(LL.db and LL.db.recipeCandidates and LL.db.recipeCandidates[id] or {}) do
            if c.method==method and c.recipeID==spellID and
                (not c.inputCount or c.inputCount==quantity) then
                matched=true;expectedOutput=c.outputID;break end
        end
        if not matched then return nil,"recipe/source unverified" end
    end
    local has=false;for output,n in pairs(added) do
        if output==id or n<1 then return nil,"invalid output" end
        if expectedOutput and output~=expectedOutput then return nil,"unexpected recipe output" end
        if method=="Mill" or method=="Prospect" then
            -- Use synchronous class information, not arbitrary bag gains.
            local instant=C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
            if type(instant)~="function" then return nil,"cannot verify output class" end
            local ok,_,_,_,_,_,classID=pcall(instant,output)
            if not ok or (method=="Mill" and classID~=7)
                or (method=="Prospect" and classID~=3 and classID~=7) then
                return nil,"unrelated or unverified output item" end
        end
        has=true
    end
    if not has then return nil,"no outputs yet" end
    return f,quantity,added
end
LL.MatchProcessingBagDiff=Match
local function CastMethod(spell)
    if CAST_METHOD[spell] then return CAST_METHOD[spell] end
    -- Only explicitly recorded one-input recipes are candidates.
    for _,set in pairs(LL.Conversions or {}) do
        for _,c in ipairs(set) do
            if (c.requiredSpell==spell or c.recipeID==spell)
                and METHODS[c.method] then return c.method end
        end
    end
    for _,set in pairs(LL.db and LL.db.recipeCandidates or {}) do
        for _,c in pairs(set) do
            if c.recipeID==spell and METHODS[c.method] then return c.method end
        end
    end
end
local pending
local frame=CreateFrame("Frame")
for _,event in ipairs({"UNIT_SPELLCAST_SENT","UNIT_SPELLCAST_START","UNIT_SPELLCAST_SUCCEEDED",
    "UNIT_SPELLCAST_FAILED","UNIT_SPELLCAST_INTERRUPTED","LOOT_CLOSED","BAG_UPDATE_DELAYED",
    "PLAYER_LOGOUT"}) do frame:RegisterEvent(event) end
local function Finish()
    if not pending or not pending.success then return false end
    local p=pending
    local f,quantity,outputs=Match(p.before,Snapshot(),p.method,p.spellID)
    if f then
        pending=nil
        return LL:SaveProcessingObservation(p.method,f,quantity,outputs,p.spellID)
    end
    -- Only absent loot/source removals are allowed to wait for loot delivery.
    if quantity~="not exactly one source item removed" and quantity~="no outputs yet" then
        pending=nil
    elseif GetTime and GetTime()-p.started>12 then pending=nil end
    return false
end
LL.FinishProcessingTracking=Finish
local function Schedule(delay)
    if not pending or not pending.success or pending.scheduled
        or not C_Timer or type(C_Timer.After)~="function" then return end
    local p=pending;p.scheduled=true
    C_Timer.After(delay,function()
        p.scheduled=false
        if pending==p then Finish() end
    end)
end
frame:SetScript("OnEvent",function(_,event,unit,a,b,c)
    if event=="PLAYER_LOGOUT" then pending=nil;return end
    if event=="BAG_UPDATE_DELAYED" or event=="LOOT_CLOSED" then
        if pending and pending.success then Schedule(.5) end
        return
    end
    if unit~="player" then return end
    local guid,spell
    if event=="UNIT_SPELLCAST_SENT" then guid,spell=b,c else guid,spell=a,b end
    local method=CastMethod(spell)
    if not method or not LL.db or LL.db.recordConversions==false then return end
    if event=="UNIT_SPELLCAST_SENT" or event=="UNIT_SPELLCAST_START" then
        if pending and GetTime and GetTime()-pending.started<=12 then return end
        local before=Snapshot()
        if before then pending={guid=guid,method=method,spellID=spell,before=before,
            started=GetTime and GetTime() or 0,success=false} end
    elseif (event=="UNIT_SPELLCAST_FAILED" or event=="UNIT_SPELLCAST_INTERRUPTED") then
        if pending and pending.spellID==spell then pending=nil end
    elseif event=="UNIT_SPELLCAST_SUCCEEDED" then
        if pending and pending.spellID==spell and not pending.success then
            pending.success=true
            Schedule(1.25)
        end
    end
end)
