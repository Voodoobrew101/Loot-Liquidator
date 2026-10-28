-- Loot Liquidator: passive, opt-out disenchant research.
-- Only commit when a player's confirmed Disenchant cast consumes EXACTLY ONE
-- eligible piece of gear and yields one or more known Enchanting materials.
-- A bag change by itself is not proof of disenchanting. Never count trades,
-- vendor sales, crafting, multiple simultaneous changes, or unrelated loot.
local ADDON, LL = ...
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
    local key=table.concat({tostring(f.expansionID),tostring(f.quality),mode,
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
            skill=skill,specialization=specialization,total=0,mats={},items={}}
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
        if b.expansion==f.expansionID and b.quality==f.quality and b.mode==mode then
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

local pending,token
local function TrackStatus(why)
    if not LL.db then return end
    local state=LL.db.disenchantTrackDiagnostics or {accepted=0,rejected=0,recent={}}
    LL.db.disenchantTrackDiagnostics=state
    if why=="recorded" then state.accepted=state.accepted+1
    else state.rejected=state.rejected+1 end
    state.recent=state.recent or {}
    state.recent[#state.recent+1]={at=time and time() or 0,reason=why}
    if #state.recent>25 then table.remove(state.recent,1) end
end
function LL:DisenchantTrackingReport()
    local d=self.db and self.db.disenchantTrackDiagnostics or {}
    local lines={("Disenchant recorder: %d accepted, %d rejected/expired"):format(
        d.accepted or 0,d.rejected or 0)}
    for i=math.max(1,#(d.recent or {})-9),#(d.recent or {}) do
        local r=d.recent[i]
        lines[#lines+1]=tostring(r.at).." - "..r.reason
    end
    return table.concat(lines,"\n")
end
function LL:TrackingStart(castGUID)
    if not self.db or self.db.recordDisenchants==false then return end
    if pending and (GetTime and GetTime() or 0)-pending.started>10 then pending=nil end
    if pending then return end
    local before=Snapshot()
    if not before then return end
    pending={guid=castGUID,before=before,started=(GetTime and GetTime() or 0),success=false}
end
function LL:TrackingFinish()
    if not pending or not pending.success then return false end
    local p=pending
    local after=Snapshot()
    local gear,yieldsOrReason=ResultDiff(p.before,after)
    if not gear then
        -- Loot might still be in Blizzard's loot window. Stay pending until
        -- LOOT_CLOSED / BAG_UPDATE_DELAYED for at most 12 seconds. Reject
        -- truly ambiguous changes immediately instead of misattributing them.
        local reason=yieldsOrReason
        if reason~="not exactly one consumed gear item"
            and reason~="no tracked Enchanting materials received" then
            TrackStatus(reason)
            pending=nil
        elseif (GetTime and GetTime() or 0)-p.started>12 then
            TrackStatus("timeout: "..reason)
            pending=nil
        end
        if pending==p and C_Timer and type(C_Timer.After)=="function" then
            -- Defer once more if the loot window has not delivered materials;
            -- the event handler also triggers a recheck on bag/loot changes.
            C_Timer.After(1.2,function()
                if pending==p then LL:TrackingFinish() end
            end)
        end
        return false
    end
    pending=nil
    local saved=self:SaveDisenchantObservation(gear,yieldsOrReason)
    TrackStatus(saved and "recorded" or "observation rejected")
    return saved
end
local frame=CreateFrame("Frame")
for _,event in ipairs({"UNIT_SPELLCAST_SENT","UNIT_SPELLCAST_START","UNIT_SPELLCAST_SUCCEEDED",
    "UNIT_SPELLCAST_FAILED","UNIT_SPELLCAST_INTERRUPTED","PLAYER_LOGOUT",
    "LOOT_CLOSED","BAG_UPDATE_DELAYED"}) do
    frame:RegisterEvent(event)
end
local function ScheduleRecheck(delay)
    if not pending or not pending.success or pending.recheckScheduled then return end
    if not C_Timer or type(C_Timer.After)~="function" then return end
    local p=pending
    p.recheckScheduled=true
    C_Timer.After(delay,function()
        p.recheckScheduled=false
        if pending==p then LL:TrackingFinish() end
    end)
end
frame:SetScript("OnEvent",function(_,event,unit,a,b,c)
    if event=="PLAYER_LOGOUT" then pending=nil;return end
    if event=="BAG_UPDATE_DELAYED" or event=="LOOT_CLOSED" then
        if pending and pending.success then ScheduleRecheck(.45) end
        return
    end
    if unit~="player" then return end
    local castGUID,spellID
    if event=="UNIT_SPELLCAST_SENT" then
        castGUID,spellID=b,c -- unit, target, castGUID, spellID
    else
        castGUID,spellID=a,b -- unit, castGUID, spellID
    end
    if spellID~=DE_SPELL then return end
    if event=="UNIT_SPELLCAST_SENT" or event=="UNIT_SPELLCAST_START" then
        LL:TrackingStart(castGUID)
    elseif event=="UNIT_SPELLCAST_FAILED" or event=="UNIT_SPELLCAST_INTERRUPTED" then
        if pending then TrackStatus("cast failed or interrupted") end
        pending=nil
    elseif event=="UNIT_SPELLCAST_SUCCEEDED" and pending and not pending.success then
        pending.success=true
        token=(token or 0)+1
        local this=token
        if C_Timer and type(C_Timer.After)=="function" then
            -- Wait for material loot and bag updates, not just the cast event.
            local p=pending
            C_Timer.After(1.25,function()
                if token==this and pending==p then LL:TrackingFinish() end
            end)
        else
            pending=nil -- fail closed without a reliable bag-settle delay
        end
    end
end)
