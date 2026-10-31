-- Measured cast logs for mechanics research, empirical baselines and valuation.
-- No observations become approved mechanics or overwrite either item database.
local _,LL=...
local SCHEMA="loot-liquidator.cast-log/1"
local METHODS={Disenchant=true,Mill=true,Prospect=true,Smelt=true,Craft=true,Recycle=true,Research=true,Unravel=true,Thaumaturgy=true}
local SPELLS={[13262]="Disenchant",[51005]="Mill",[31252]="Prospect",[382981]="Mill",[374627]="Prospect",
    [444181]="Mill",[434018]="Prospect",[1269575]="Mill",[1231127]="Prospect"}
local MAX_RECORDS=2000
local pending
local request
local sessionStarted=false
local function finite(n) return type(n)=="number" and n==n and n>=0 and n<math.huge end
local function integer(n) return finite(n) and n>0 and n%1==0 end
local function secret(v) return issecretvalue and issecretvalue(v) end
local function copy(t,depth)
    if secret(t) then return nil end
    if type(t)=="string" or type(t)=="boolean" then return t end
    if type(t)=="number" then return finite(t) and t or nil end
    if type(t)~="table" or (depth or 0)>12 then return nil end
    local out={} for k,v in pairs(t) do
        if type(k)=="string" or type(k)=="number" then out[k]=copy(v,(depth or 0)+1) end
    end return out
end
local function stamp() return time and time() or 0 end
local function clock() return GetTime and GetTime() or 0 end
local function build() return GetBuildInfo and tostring(select(2,GetBuildInfo())) or "unknown" end
local function keys(t) local out={} for k in pairs(t) do out[#out+1]=k end table.sort(out,function(a,b)return tostring(a)<tostring(b) end);return out end
local function quote(s)
    return '"'..s:gsub('[%z\1-\31\\"]',function(c)
        return ({['"']='\\"',['\\']='\\\\',['\n']='\\n',['\r']='\\r',['\t']='\\t'})[c] or ('\\u%04x'):format(c:byte())
    end)..'"'
end
local arrayFields={records=true,inputs=true,outputs=true,nominalInputs=true,materials=true,baselines=true,diagnostics=true,resultMetadata=true,sourceRecordIDs=true,expectedInputsConsumed=true,resourcesReturned=true,inputIdentity=true}
local function json(v,forceArray)
    if type(v)=="string" then return quote(v) end
    if type(v)=="number" then assert(finite(v));return ('%.17g'):format(v) end
    if type(v)=="boolean" then return tostring(v) end
    if v==nil then return "null" end
    assert(type(v)=="table","unsupported export type")
    local out={}
    if #v>0 or forceArray then
        for i=1,#v do out[i]=json(v[i]) end
        return '['..table.concat(out,',')..']'
    end
    -- Empty tables encode as objects. Empty item vectors are explicitly handled
    -- by the export envelope below, so consumers never guess zero vs unknown.
    for _,k in ipairs(keys(v)) do out[#out+1]=quote(tostring(k))..':'..json(v[k],arrayFields[k]) end
    return '{'..table.concat(out,',')..'}'
end
local function identity(context)
    local c=copy(context);c.observed=nil;c.previousSnapshot=nil;c.inputExpansionID=nil
    return json(c)
end
local function ledger(self)
    self.db.craftResearch=self.db.craftResearch or {schemaVersion=SCHEMA,records={},contexts={},studies={},sequence=0,droppedRecords=0}
    local d=self.db.craftResearch
    local active=d.activeStudy and d.studies[d.activeStudy]
    if not sessionStarted then
        sessionStarted=true
        -- B6b: a clean logout (no cast pending) pauses the study so a batch can
        -- carry on next login. A study saved without the paused mark means the
        -- client never reached a clean logout, so its denominator is unknown.
        d.pausedStudies=type(d.pausedStudies)=="table" and d.pausedStudies or {}
        if active then
            if active.paused and active.character then d.pausedStudies[active.character]=d.activeStudy
            else active.censored=true;active.coverageReason="Unclosed recording session" end
        end
        d.activeStudy=nil
        local me=self:CharacterKey()
        local id=d.pausedStudies[me];local study=id and d.studies[id]
        d.pausedStudies[me]=nil
        if study then
            study.paused=nil
            if study.build==build() and not study.censored and not study.truncated then
                study.resumedAt=stamp();study.resumeCount=(study.resumeCount or 0)+1;d.activeStudy=id
            else
                -- A new game build is a new sampling frame: close it cleanly, not censored.
                study.closedAt=stamp();study.closedReason=study.closedReason or "Game build changed"
            end
        end
        active=d.activeStudy and d.studies[d.activeStudy]
    end
    if active and (active.character~=self:CharacterKey() or active.build~=build()) then d.activeStudy=nil end
    return d
end
local function enabled(self,method)
    return self.db and ((method=="Disenchant" and self.db.recordDisenchants~=false)
        or (method~="Disenchant" and self.db.recordConversions~=false))
end
function LL:StartCraftStudy(label)
    if pending then return nil,"Wait for the pending cast before starting a new study" end
    if not self.db then return nil end
    local d=ledger(self);d.sequence=d.sequence+1
    local id=tostring(self:CharacterKey())..":"..build()..":"..stamp()..":"..d.sequence
    d.studies[id]={label=type(label)=="string" and label:sub(1,80) or "Measured operations",startedAt=stamp(),
        character=self:CharacterKey(),build=build(),truncated=false}
    d.activeStudy=id
    if self.Invalidate then self:Invalidate() end
    return id
end
local function contextID(self,context)
    local d=ledger(self);local signature=identity(context)
    for id,c in pairs(d.contexts) do if identity(c)==signature then return id end end
    local n=0 for _ in pairs(d.contexts) do n=n+1 end
    if n>=256 then return nil end
    local id="context:"..(n+1);d.contexts[id]=copy(context);return id
end
function LL:ValidateCraftObservation(r)
    if type(r)~="table" or not METHODS[r.method] or not integer(r.recipeID)
        or type(r.operationID)~="string" or r.operationID=="" or r.successful~=true
        or r.character~=self:CharacterKey() or r.build~=build()
        or type(r.context)~="table" or r.context.character~=r.character
        or r.context.profileKind~="measured" or r.context.simulated~=false
        or type(r.inputs)~="table" or #r.inputs==0 or type(r.outputs)~="table" then
        return false,"Missing measured cast/character/recipe/input identity"
    end
    for _,vector in ipairs({r.inputs,r.outputs,r.nominalInputs or r.inputs}) do
        local seen={} for _,item in ipairs(vector) do
            if not integer(item.itemID) or not finite(item.quantity) or item.quantity%1~=0
                or ((vector==r.outputs or vector==r.nominalInputs) and item.quantity==0)
                or (item.quantity==0 and not r.nominalInputs) or seen[item.itemID] then return false,"Invalid item vector" end
            seen[item.itemID]=true
        end
    end
    if r.outputCoverage~="complete" and r.outputCoverage~="unresolved" then return false,"Output coverage unknown" end
    if r.outputCoverage=="complete" and #r.outputs==0 and r.zeroEvidence~="operator-confirmed-empty" then
        return false,"Absence of loot is not evidence of zero output"
    end
    return true
end
function LL:RecordCraftObservation(record)
    if not enabled(self,record and record.method) then return false,"Recording disabled" end
    local ok,reason=self:ValidateCraftObservation(record);if not ok then return false,reason end
    local d=ledger(self)
    for _,r in ipairs(d.records) do if r.operationID==record.operationID then return false,"Duplicate operation" end end
    local measured=copy(record.context);measured.inputIdentity={}
    for _,item in ipairs(record.nominalInputs or record.inputs) do
        measured.inputIdentity[#measured.inputIdentity+1]={itemID=item.itemID,qualityRank=item.qualityRank,rarity=item.rarity,quantity=item.quantity,
            itemLevel=(item.classID==2 or item.classID==4) and item.itemLevel or nil,
            hyperlink=(item.classID==2 or item.classID==4) and item.hyperlink or nil}
    end
    local id=contextID(self,measured);if not id then return false,"Context capacity reached; export research before continuing" end
    local r=copy(record);r.context=nil;r.contextID=id;r.schemaVersion=SCHEMA
    r.studyID=d.activeStudy or self:StartCraftStudy();r.recordedAt=stamp()
    r.provenance={sampleKind="RAW_CAST_LOG",source="measured-addon-capture",independentReview="PENDING",
        numericTransformValidated=false,applyPolicy="NO_NUMERIC_TRANSFORM",registryContract="profession-mechanics/0.2"}
    d.records[#d.records+1]=r
    if #d.records>MAX_RECORDS then
        local evicted=table.remove(d.records,1)
        if d.studies[evicted.studyID] then d.studies[evicted.studyID].truncated=true end
        d.droppedRecords=d.droppedRecords+1
    end
    if self.Invalidate then self:Invalidate() end
    return true,r
end
local function itemVector(counts,facts)
    local out={}
    for _,id in ipairs(keys(counts)) do
        local f=facts and facts[id] or {}
        out[#out+1]={itemID=id,quantity=counts[id],qualityRank=f.reagentQuality,rarity=f.quality,
            itemLevel=f.itemLevel,hyperlink=f.link,expansionID=f.expansionID,classID=f.classID,subClassID=f.subClassID}
    end
    return out
end
local function diff(before,after)
    local removed,added={},{}
    for id,n in pairs(before.counts) do if n>(after.counts[id] or 0) then removed[id]=n-(after.counts[id] or 0) end end
    for id,n in pairs(after.counts) do if n>(before.counts[id] or 0) then added[id]=n-(before.counts[id] or 0) end end
    return removed,added
end
function LL:SnapshotCraftBags()
    if not C_Container or not C_Container.GetContainerNumSlots or not C_Container.GetContainerItemInfo then return nil end
    local out={counts={},facts={},variants={}}
    for bag=0,5 do for slot=1,(C_Container.GetContainerNumSlots(bag) or 0) do
        local i=C_Container.GetContainerItemInfo(bag,slot)
        if i and integer(i.itemID) and integer(i.stackCount or 1) then
            local id=i.itemID;out.counts[id]=(out.counts[id] or 0)+(i.stackCount or 1)
            local link=i.hyperlink or ("item:"..id)
            out.variants[id]=out.variants[id] or {};out.variants[id][link]=true
            if not out.facts[id] then out.facts[id]=self.GetItemFacts and self:GetItemFacts(link,{count=i.stackCount or 1}) or {id=id,link=link} end
        end
    end end
    return out
end
local function call(fn,...)
    if type(fn)~="function" then return nil end
    local ok,v=pcall(fn,...);return ok and v or nil
end
local function describe(self,recipe)
    local operations=self.ResearchProcessingRecipeOperations and self:ResearchProcessingRecipeOperations(recipe)
    local method
    for _,r in ipairs(operations or {}) do
        if method and method~=r.method then return nil end -- conflicting operation identity
        method=r.method
    end
    if method=='Mill' or method=='Prospect' then
        return {method=method,operations=operations}
    end
    if SPELLS[recipe] then return {method=SPELLS[recipe]} end
    for _,list in pairs(self.Conversions or {}) do for _,r in ipairs(list) do
        if (r.recipeID==recipe or r.requiredSpell==recipe) and METHODS[r.method] then
            if method and method~=r.method then return nil end
            return {method=r.method,conversion=r}
        end
    end end
    local ui=C_TradeSkillUI
    if call(ui and ui.IsTradeSkillLinked) or call(ui and ui.IsTradeSkillGuild) or call(ui and ui.IsNPCCrafting) then return nil end
    local info=call(ui and ui.GetRecipeInfo,recipe)
    local schematic=call(ui and ui.GetRecipeSchematic,recipe,false)
    if type(info)=='table' and info.learned==true and type(schematic)=='table' and schematic.recipeID==recipe and not schematic.isRecraft then
        return {method=method or 'Craft',schematic=copy(schematic)}
    end
end
-- Exact recipe/input context takes priority over old expansion-wide hints.
-- Multiple source profiles may agree on one operation; conflicting batches
-- remain diagnostics instead of choosing whichever quantity matches the bags.
local function processingBatch(self,p,f)
    if p.description.operations then
        local batch
        for _,r in ipairs(p.description.operations) do
            if r.inputItemID==f.id and (not r.expansionID or r.expansionID==f.expansionID)
                and (not r.inputQualityRank or r.inputQualityRank==f.reagentQuality) then
                if batch and batch~=r.inputCount then return nil end
                batch=r.inputCount
            end
        end
        return batch
    end
    -- Original generic spells retain their compatibility metadata when no
    -- explicit ItemDB operation exists for that recipe.
    local known=self.ResearchProcessingInput and self:ResearchProcessingInput(f.id)
    if known and known.method~=p.method then return nil end
    return (known and known.batch) or (p.method=='Mill' and (f.expansionID==10 or f.expansionID==11) and 10 or 5)
end
-- A secure post-hook observes the player's actual request; it never calls a
-- crafting API or changes its arguments. Missing allocations remain unknown.
function LL:ObserveCraftRequest(recipe,numCasts,allocation,recipeLevel,orderID,concentration)
    request={recipe=recipe,remaining=integer(numCasts) and numCasts or 1,allocation=copy(allocation),
        recipeLevel=recipeLevel,orderID=orderID,concentration=concentration,at=clock()}
end
if hooksecurefunc and C_TradeSkillUI and type(C_TradeSkillUI.CraftRecipe)=="function" then
    hooksecurefunc(C_TradeSkillUI,"CraftRecipe",function(...) LL:ObserveCraftRequest(...) end)
end
local function allocatedInputs(p)
    local schematic=p.description.schematic
    if not schematic then return nil end
    local allocation=p.request and p.request.allocation
    local selected={}
    for _,a in ipairs(allocation or {}) do
        if not integer(a.dataSlotIndex) or not a.reagent or not integer(a.reagent.itemID) or not integer(a.quantity) then return nil end
        local slot=selected[a.dataSlotIndex] or {};selected[a.dataSlotIndex]=slot
        slot[a.reagent.itemID]=(slot[a.reagent.itemID] or 0)+a.quantity
    end
    local expected={}
    for _,slot in ipairs(schematic.reagentSlotSchematics or {}) do
        local items=slot.dataSlotIndex and selected[slot.dataSlotIndex]
        if slot.dataSlotIndex then selected[slot.dataSlotIndex]=nil end
        if items then
            local total=0
            for id,n in pairs(items) do
                local allowed=false for _,r in ipairs(slot.reagents or {}) do if r.itemID==id then allowed=true end end
                if not allowed then return nil end
                total=total+n;expected[id]=(expected[id] or 0)+n
            end
            if slot.required and total~=slot.quantityRequired then return nil end
        elseif slot.required then
            if #slot.reagents~=1 or not slot.reagents[1].itemID or not integer(slot.quantityRequired) then return nil end
            local id=slot.reagents[1].itemID;expected[id]=(expected[id] or 0)+slot.quantityRequired
        end
    end
    if next(selected) then return nil end
    return expected
end
function LL:BeginCraftCapture(guid,recipe)
    if type(guid)~="string" or not integer(recipe) then return false end
    if pending then
        if pending.guid==guid then return true end
        local previous=pending
        self:FinishCraftCapture(true)
        -- A second cast before the previous result settles contaminates both
        -- operations. Keep a diagnostic gap rather than pooling their loot.
        if pending or previous.finalCoverage~="complete" then
            local d=ledger(self);local study=d.activeStudy or self:StartCraftStudy()
            d.studies[study].censored=true;pending=nil;return false
        end
    end
    local description=describe(self,recipe);if not description then return false end
    if not enabled(self,description.method) then if self.db then ledger(self).activeStudy=nil end;return false end
    local before=self:SnapshotCraftBags();if not before then return false end
    local d=ledger(self);if not d.activeStudy then self:StartCraftStudy() end
    d.confirmableEmpty=nil
    local hint=request and request.recipe==recipe and request.remaining>0 and clock()-request.at<120 and request or nil
    if hint and hint.orderID~=nil and hint.orderID~=0 then return false end -- customer/order inventory is not this character's bags
    local context=self:CaptureCraftContext(recipe,nil,description.method,hint and hint.allocation,hint and hint.concentration)
    if hint then hint.remaining=hint.remaining-1 end
    pending={guid=guid,recipe=recipe,method=description.method,description=description,before=before,
        request=copy(hint),context=copy(context),startedAt=stamp(),started=clock(),success=false,results={},resultKeys={}}
    if C_Timer and C_Timer.After then
        local p=pending;C_Timer.After(60,function()
            if pending==p and not p.success then
                p.uncertainCompletion=true;self:AbandonCraftCapture("No cast completion evidence")
            end
        end)
    end
    return true
end
local function reportedReturns(p)
    local returns,seen={},{}
    for _,result in ipairs(p.results) do
        local refunds=result.resourcesReturned or {}
        if #refunds>0 then
            if not integer(result.operationID) then return nil end
            local signature=json(refunds)
            if seen[result.operationID] and seen[result.operationID]~=signature then return nil end
            if not seen[result.operationID] then
                seen[result.operationID]=signature
                for _,r in ipairs(refunds) do
                    local id=r.reagent and r.reagent.itemID
                    if not integer(id) or not integer(r.quantity) then return nil end
                    returns[id]=(returns[id] or 0)+r.quantity
                end
            end
        end
    end
    return returns
end
local function validateDelta(self,p,after)
    local removed,added=diff(p.before,after)
    local inputs=itemVector(removed,p.before.facts)
    local returned=reportedReturns(p)
    if not returned then return nil,"Ambiguous reported reagent returns" end
    if #inputs==0 and next(returned) then
        local net={} for id in pairs(returned) do net[id]=0 end
        inputs=itemVector(net,p.before.facts)
    end
    if #inputs==0 then return nil,"Inputs have not settled" end
    for _,item in ipairs(inputs) do
        local n=0 for _ in pairs(p.before.variants[item.itemID] or {}) do n=n+1 end
        if n>1 then return nil,"Input item variants are ambiguous" end
    end
    if p.method=="Disenchant" then
        local f=p.before.facts[inputs[1].itemID]
        if next(returned) or #inputs~=1 or inputs[1].quantity~=1 or not self.EligibleDisenchant or not self:EligibleDisenchant(f) then return nil,"Unverified disenchant input" end
    elseif p.method=="Mill" or p.method=="Prospect" then
        local f=p.before.facts[inputs[1].itemID]
        if not f then return nil,"Input metadata unavailable" end
        local batch=processingBatch(self,p,f)
        if not integer(batch) or #inputs~=1 or f.classID~=7 or f.subClassID~=(p.method=="Mill" and 9 or 7)
            or inputs[1].quantity+(returned[inputs[1].itemID] or 0)~=batch then return nil,"Not exactly one validated recipe processing batch" end
        for id in pairs(returned) do if id~=inputs[1].itemID then return nil,"Unrelated reagent return" end end
        if (p.before.counts[inputs[1].itemID] or 0)<batch then return nil,"Missing nominal input batch" end
        local nominal=copy(inputs);nominal[1].quantity=batch;p.nominalInputs=nominal
    else
        local expected={}
        local c=p.description.conversion
        if c then
            for id,list in pairs(self.Conversions or {}) do for _,r in ipairs(list) do if r==c then expected[id]=r.inputCount end end end
            for _,extra in ipairs(c.extraReagents or {}) do expected[extra.id]=extra.amount end
            for _,supply in ipairs(c.vendorSupplies or {}) do expected[supply.id]=supply.amount end
        else
            expected=allocatedInputs(p)
            if not expected then return nil,"Unknown reagent allocation" end
        end
        for id in pairs(returned) do if not expected[id] then return nil,"Unverified reagent return" end end
        for id,n in pairs(removed) do if not expected[id] or n~=expected[id]-(returned[id] or 0) then return nil,"Recipe reagent consumption mismatch" end end
        for id,n in pairs(expected) do if (removed[id] or 0)~=n-(returned[id] or 0) then return nil,"Missing recipe reagent delta" end end
        p.nominalInputs=itemVector(expected,p.before.facts)
        local net={} for id,n in pairs(expected) do net[id]=n-(returned[id] or 0) end
        inputs=itemVector(net,p.before.facts)
        for id,n in pairs(expected) do
            if (p.before.counts[id] or 0)<n then return nil,"Reagents outside measured bags are unsupported" end
            local variants=0 for _ in pairs(p.before.variants[id] or {}) do variants=variants+1 end
            if variants>1 then return nil,"Input item variants are ambiguous" end
        end
        if not next(expected) then return nil,"No verified input allocation" end
    end
    local resultCounts={}
    for _,r in ipairs(p.results) do
        if r.itemID and r.quantity and r.quantity>0 then resultCounts[r.itemID]=(resultCounts[r.itemID] or 0)+r.quantity end
    end
    if #p.results>0 then
        for id,n in pairs(added) do if resultCounts[id]~=n then return nil,"Craft result/bag delta mismatch" end end
        for id,n in pairs(resultCounts) do if added[id]~=n then return nil,"Craft result/bag delta mismatch" end end
    else
        -- Stochastic loot must be a mapped possible output. Unknown materials
        -- remain a research diagnostic, never contaminate a priced baseline.
        local allowed={}
        local input=inputs[1].itemID
        for _,r in ipairs(self.ItemDB and self.ItemDB.processing or {}) do
            if r.method==p.method and (r.recipeID==nil or r.recipeID==p.recipe)
                and (r.inputItemID==input or (p.method=="Disenchant" and r.gearKey==
                ('gear:%s:%s:%s'):format(tostring(p.before.facts[input].expansionID),tostring(p.before.facts[input].quality),p.before.facts[input].classID==2 and 'weapon' or 'armor'))) then
                for _,m in ipairs(r.materials) do allowed[m.id]=true end
            end
        end
        if p.description.conversion and p.description.conversion.outputID then allowed[p.description.conversion.outputID]=true end
        if p.description.schematic and p.description.schematic.outputItemID then allowed[p.description.schematic.outputItemID]=true end
        for id in pairs(added) do if not allowed[id] then return nil,"Unmapped or unrelated output" end end
    end
    return {inputs=inputs,outputs=itemVector(added,after.facts)}
end
local function diagnostic(self,p,reason)
    local d=ledger(self);d.diagnostics=d.diagnostics or {}
    local after=self:SnapshotCraftBags()
    local removed,added={},{}
    if after and p.before then removed,added=diff(p.before,after) end
    d.diagnostics[#d.diagnostics+1]={operationID=p.guid,recipeID=p.recipe,method=p.method,reason=reason,at=stamp(),
        context=copy(p.context),netInputs=itemVector(removed,p.before and p.before.facts),
        observedOutputs=itemVector(added,after and after.facts),resultMetadata=copy(p.results),outputCoverage="unknown"}
    if #d.diagnostics>50 then table.remove(d.diagnostics,1) end
    -- A successful but unattributed operation invalidates this study's sampling
    -- coverage. Export still retains its diagnostic and raw confirmed casts.
    if p.success or p.uncertainCompletion then
        local study=d.activeStudy or self:StartCraftStudy()
        d.studies[study].censored=true
    end
end
function LL:AbandonCraftCapture(reason)
    if pending then diagnostic(self,pending,reason);pending=nil end
end
function LL:FinishCraftCapture(final)
    local p=pending;if not p or not p.success then return false end
    if p.interference then diagnostic(self,p,p.interference);pending=nil;return false end
    local after=self:SnapshotCraftBags();if not after then return false end
    local result,reason=validateDelta(self,p,after)
    if not result then
        if final then diagnostic(self,p,reason);pending=nil end
        return false
    end
    local complete=(#result.outputs>0 and (p.lootClosed or #p.results>0))
    if not complete and not final then return false end
    local record={operationID=p.guid,recipeID=p.recipe,method=p.method,successful=true,character=self:CharacterKey(),
        build=build(),gameMode="RETAIL",context=p.context,inputs=result.inputs,outputs=result.outputs,
        nominalInputs=p.nominalInputs,outputCoverage=complete and "complete" or "unresolved",startedAt=p.startedAt,endedAt=stamp(),
        durationSeconds=clock()-p.started,attribution=p.lootClosed and "cast-loot-bag" or "cast-result-bag",
        resultMetadata=copy(p.results),allocation=p.request and p.request.allocation,applyConcentration=p.request and p.request.concentration,zeroReason=not complete and "No authoritative empty-result signal" or nil}
    local ok,saved=self:RecordCraftObservation(record)
    p.finalCoverage=ok and saved.outputCoverage or "unresolved"
    pending=nil
    if ok and saved.outputCoverage=="unresolved" then ledger(self).confirmableEmpty={operationID=saved.operationID,snapshot=json(after.counts)} end
    if not ok then diagnostic(self,p,saved) end
    return ok
end
function LL:ConfirmEmptyCraft()
    if pending then return false,"Wait for result tracking to finish before confirming an empty operation" end
    if not self.db then return false,"No recording" end
    local d=ledger(self)
    for _,r in ipairs(d.records) do
        if d.confirmableEmpty and r.operationID==d.confirmableEmpty.operationID and r.outputCoverage=="unresolved" and #r.outputs==0
            and r.character==self:CharacterKey() and r.build==build() then
            local now=self:SnapshotCraftBags()
            if not now or json(now.counts)~=d.confirmableEmpty.snapshot then return false,"Inventory changed since the empty capture; do not infer zero" end
            r.outputCoverage="complete";r.zeroEvidence="operator-confirmed-empty";r.confirmedAt=stamp()
            d.confirmableEmpty=nil
            if self.Invalidate then self:Invalidate() end
            return true,"Empty result confirmed and labeled as an operator observation"
        end
    end
    return false,"No isolated empty-result candidate; missing or interrupted captures cannot be confirmed as zero"
end
function LL:CraftBaseline(studyID,contextRef,recipeID)
    local d=self.db and self.db.craftResearch;if not d then return nil end
    local study=d.studies[studyID]
    if not study or study.censored or study.truncated then return nil,"Study has unresolved coverage gaps" end
    local base={schemaVersion=SCHEMA,sampleKind="RAW_CAST_LOG",referenceContextID=contextRef,recipeID=recipeID,
        studyID=studyID,materials={},operations=0,sourceRecordIDs={},status="EMPIRICAL_ESTIMATE",
        numericTransformValidated=false,applyPolicy="NO_NUMERIC_TRANSFORM"}
    base.patchBuild=study.build
    base.observationContext=copy(d.contexts[contextRef])
    local totals,inputTotals,signature={},{},nil
    for _,r in ipairs(d.records) do if r.studyID==studyID and r.contextID==contextRef and r.recipeID==recipeID then
        if r.outputCoverage~="complete" then return nil,"Unresolved output coverage" end
        local inputSignature=json(d.contexts[r.contextID].inputIdentity)
        if signature and signature~=inputSignature then return nil,"Different input batches or variants" end
        signature=inputSignature;base.inputs=r.nominalInputs or r.inputs;base.method=r.method
        for _,item in ipairs(r.inputs) do inputTotals[item.itemID]=(inputTotals[item.itemID] or 0)+item.quantity end
        base.operations=base.operations+1;base.sourceRecordIDs[#base.sourceRecordIDs+1]=r.operationID
        for _,m in ipairs(r.outputs) do
            local t=totals[m.itemID] or {itemID=m.itemID,qualityRank=m.qualityRank,rarity=m.rarity,quantity=0,occurrences=0,histogram={}}
            totals[m.itemID]=t;t.quantity=t.quantity+m.quantity;t.occurrences=t.occurrences+1
            t.minimum=math.min(t.minimum or m.quantity,m.quantity);t.maximum=math.max(t.maximum or m.quantity,m.quantity)
            t.histogram[tostring(m.quantity)]=(t.histogram[tostring(m.quantity)] or 0)+1
        end
    end end
    if base.operations==0 then return nil end
    base.expectedInputsConsumed={}
    for _,item in ipairs(base.inputs) do
        base.expectedInputsConsumed[#base.expectedInputsConsumed+1]={itemID=item.itemID,expectedQuantity=(inputTotals[item.itemID] or 0)/base.operations}
    end
    for _,id in ipairs(keys(totals)) do
        local t=totals[id];t.histogram["0"]=base.operations-t.occurrences
        base.materials[#base.materials+1]={id=id,quality=t.qualityRank,rarity=t.rarity,expectedQuantity=t.quantity/base.operations,
            chance=t.occurrences/base.operations,minQuantity=t.minimum,maxQuantity=t.maximum,
            boundsBasis="observed-positive-range",quantityCounts=t.histogram,samples=base.operations,
            fieldEvidence={expectedQuantity={status="measured",sampleOperations=base.operations,confidence="UNSCORED"},
                dropChance={status="measured",sampleOperations=base.operations,confidence="UNSCORED"},
                conditionalBounds={status="observed-range-not-guaranteed",confidence="UNSCORED"}}}
    end
    return base
end
function LL:GetRecordedProcessingEstimate(f,method,batch,recipeID)
    local d=self.db and self.db.craftResearch;if not d or not self.CaptureCraftContext then return nil end
    d=ledger(self) -- classify an interrupted prior session before valuation
    local checked,queries={},{}
    for i=#d.records,1,-1 do
        local r=d.records[i];local id=r.contextID;local inputs=r.nominalInputs or r.inputs
        local queryID=tostring(r.studyID)..':'..tostring(id)
        if r.recipeID==recipeID and r.method==method and not checked[queryID]
            and #inputs==1 and inputs[1].itemID==f.id and inputs[1].quantity==batch then
            checked[queryID]=true
            -- Re-query the recorded allocation instead of substituting an empty
            -- allocation. This only reads operation data; it never crafts.
            local query=json({allocation=r.allocation,concentration=r.applyConcentration})
            local current=queries[query]
            if not current then
                current=self:CaptureCraftContext(recipeID,f,method,r.allocation,r.applyConcentration)
                current.inputIdentity={{itemID=f.id,qualityRank=f.reagentQuality,rarity=f.quality,quantity=batch,
                    itemLevel=(f.classID==2 or f.classID==4) and f.itemLevel or nil,
                    hyperlink=(f.classID==2 or f.classID==4) and f.link or nil}}
                queries[query]=current
            end
            local context=d.contexts[id]
            -- Incomplete measurements remain exportable, never priced as matched.
            local exact=current.effectiveSkill and current.specialization and current.skillLineID
                and current.fieldStatus.equipment=="measured" and identity(context)==identity(current) and r.build==build()
            if exact or self.ProjectPersonalEstimate then
                local baseline=self:CraftBaseline(r.studyID,id,recipeID)
                if baseline and baseline.method==method and #baseline.inputs==1
                    and baseline.inputs[1].itemID==f.id and baseline.inputs[1].quantity==batch then
                    baseline.inputCount=batch;baseline.expectedInputCount=baseline.expectedInputsConsumed[1].expectedQuantity
                    baseline.patchBuild=r.build;baseline.effectiveSamples=baseline.operations;baseline.samples=baseline.operations
                    baseline.source="Measured personal cast log";baseline.observationContext=copy(context)
                    baseline.observationContextID=id
                    baseline.observationContext.expansionID=f.expansionID
                    baseline.observationContext.skill=context.baseSkill
                    baseline.observationContext.verifiedAt=current.observed
                    baseline.observationContext.incomplete=context.operationStats==nil
                    baseline.provisional=true
                    -- This is not an unskilled or universal profession baseline.
                    baseline.referenceContextID=nil
                    if exact then return baseline end
                    local projected,reason=self:ProjectPersonalEstimate(f,{name=method,recipeID=recipeID,inputCount=batch},baseline,current,build())
                    self.personalProjectionStatus=reason or (projected and projected.adjustment)
                    if projected then return projected end
                end
            end
        end
    end
end
-- Only complete, new cast logs drive personal valuation. Legacy CSV/statistics
-- stay accessible; positive-only legacy brackets cannot supply probabilities.
function LL:GetLearnedProcessingEstimate(f,method,batch,recipeID)
    return self:GetRecordedProcessingEstimate(f,method,batch,recipeID)
end
function LL:GetLearnedDisenchantEstimate(f)
    return self:GetRecordedProcessingEstimate(f,"Disenchant",1,13262)
end
function LL:ExportCraftResearch(page)
    local d=self.db and self.db.craftResearch or {records={},contexts={},studies={},droppedRecords=0}
    page=math.max(1,math.floor(tonumber(page) or 1));local records,contexts={},{}
    for i=(page-1)*25+1,math.min(page*25,#d.records) do
        local r=copy(d.records[i]);records[#records+1]=r;contexts[r.contextID]=copy(d.contexts[r.contextID])
    end
    return json({schemaVersion=SCHEMA,registryContract="profession-mechanics/0.2",sampleKind="RAW_CAST_LOG",
        artifactStatus="RESEARCH_ONLY_NOT_SHIPPED",page=page,pages=math.max(1,math.ceil(#d.records/25)),
        records=records,contexts=contexts,studies=d.studies,diagnostics=d.diagnostics or {},
        retainedRecords=#d.records,droppedRecords=d.droppedRecords,automaticMechanicsPromotion=false})
end
function LL:ExportCraftBaselines()
    local d=self.db and self.db.craftResearch;local baselines,seen={},{}
    for _,r in ipairs(d and d.records or {}) do
        local key=r.studyID..":"..r.contextID..":"..r.recipeID
        if not seen[key] then
            seen[key]=true;local b=self:CraftBaseline(r.studyID,r.contextID,r.recipeID)
            if b then baselines[#baselines+1]=b end
        end
    end
    return json({schemaVersion=SCHEMA,artifactStatus="RESEARCH_ONLY_NOT_SHIPPED",baselines=baselines,contexts=d and d.contexts or {},
        automaticMechanicsPromotion=false})
end
-- B6a: player buttons (Processing Research page). Plain words, no slash commands.
function LL:RecordedResultsCount()
    local d=self.db and self.db.craftResearch
    return d and #d.records or 0
end
-- Each click shows the next page (25 casts per page), then wraps to page 1.
function LL:ExportRecordedResultsPage()
    local d=self.db and self.db.craftResearch
    local pages=math.max(1,math.ceil((d and #d.records or 0)/25))
    local page=(self._recordedExportPage or 0)+1
    if page>pages then page=1 end
    self._recordedExportPage=page
    local title=("Recorded results - page %d of %d"):format(page,pages)
    if pages>1 then title=title.." (click Export again for the next page)" end
    return title,self:ExportCraftResearch(page),page,pages
end
-- The previous set is kept once (recordedResultsBackup) so a mistaken click
-- does not destroy research; the next reset replaces that backup.
function LL:ResetRecordedResults()
    if pending then return false,"Wait a moment: a cast is still being recorded." end
    if not self.db then return false,"Nothing recorded yet." end
    local db=self.db
    db.recordedResultsBackup={savedAt=stamp(),craftResearch=db.craftResearch,
        disenchantLearning=db.disenchantLearning,processingLearning=db.processingLearning}
    db.craftResearch=nil;db.disenchantLearning=nil;db.processingLearning=nil
    self._recordedExportPage=nil
    if self.Invalidate then self:Invalidate() end
    return true,"Recorded results reset. The previous set is kept as a backup until the next reset."
end
-- B6b: the batch currently collecting results (resumed after a clean logout).
function LL:ActiveRecordingBatch()
    if not self.db then return nil end
    local d=ledger(self)
    return d.activeStudy,d.activeStudy and d.studies[d.activeStudy]
end
function LL:StartNewBatch()
    local id,reason=self:StartCraftStudy(("Batch started %s"):format(date and date("%Y-%m-%d %H:%M") or tostring(stamp())))
    if not id then return false,reason or "Could not start a new batch." end
    return true,"New batch started. Results you record from now on are counted together."
end
function LL:CraftRecordingReport()
    local d=self.db and self.db.craftResearch or {records={},droppedRecords=0}
    local complete,unresolved=0,0
    for _,r in ipairs(d.records) do if r.outputCoverage=="complete" then complete=complete+1 else unresolved=unresolved+1 end end
    return ("Craft research: %d complete, %d unresolved, %d evicted.\nExports are provisional observations, not verified mechanics.\n/ll craftexport [page]; /ll craftbaseline; /ll craftstudy LABEL; /ll craftzero\n%s"):
        format(complete,unresolved,d.droppedRecords,pending and "One cast awaits settled results." or "No pending cast.")
end
local schedule
schedule=function()
    local p=pending
    if not p or not p.success or p.scheduled or not C_Timer or not C_Timer.After then return end
    p.scheduled=true
    C_Timer.After(1.25,function()
        if pending==p then
            p.scheduled=false
            if p.lastChange and clock()-p.lastChange<.75 then schedule() else LL:FinishCraftCapture(false) end
        end
    end)
end
local frame=CreateFrame("Frame")
for _,event in ipairs({"UNIT_SPELLCAST_SENT","UNIT_SPELLCAST_START","UNIT_SPELLCAST_SUCCEEDED","UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_INTERRUPTED","LOOT_CLOSED","BAG_UPDATE_DELAYED","TRADE_SKILL_ITEM_CRAFTED_RESULT",
    "TRADE_SHOW","MERCHANT_SHOW","MAIL_SHOW","BANKFRAME_OPENED","PLAYER_LOGOUT"}) do frame:RegisterEvent(event) end
frame:SetScript("OnEvent",function(_,event,unit,a,b,c)
    if pending and not enabled(LL,pending.method) then
        pending=nil
        if LL.db and LL.db.craftResearch then LL.db.craftResearch.activeStudy=nil end
    end
    if event=="PLAYER_LOGOUT" then
        if pending and pending.success then LL:FinishCraftCapture(true) end
        local d=LL.db and LL.db.craftResearch
        if d then
            d=ledger(LL)
            local study=d.activeStudy and d.studies[d.activeStudy]
            if study and pending then
                -- A cast still unsettled at logout leaves the batch's coverage unknown.
                study.censored=true;study.coverageReason="Logged out while a cast was being recorded";d.activeStudy=nil
            elseif study then
                study.paused=true;study.pausedAt=stamp()
            end
        end
        pending=nil;return
    end
    if event=="TRADE_SHOW" or event=="MERCHANT_SHOW" or event=="MAIL_SHOW" or event=="BANKFRAME_OPENED" then
        if pending then pending.interference="Inventory interaction during capture" end;return
    end
    if event=="TRADE_SKILL_ITEM_CRAFTED_RESULT" then
        if not pending or type(unit)~="table" or secret(unit) then return end
        local r=copy(unit);pending.lastChange=clock()
        if r.isEnchant or r.firstCraftReward or not integer(r.itemID) or not integer(r.quantity) or type(r.itemGUID)~="string" or r.itemGUID=="" then
            pending.interference="Unsupported result kind";return
        end
        local key=tostring(r.operationID)..":"..tostring(r.itemGUID)..":"..r.itemID
        if integer(r.operationID) then
            if pending.operationID and pending.operationID~=r.operationID then pending.interference="Multiple result operations" end
            pending.operationID=r.operationID
        end
        local fingerprint=json(r)
        if pending.resultKeys[key] and pending.resultKeys[key]~=fingerprint then pending.interference="Conflicting duplicate result" end
        if not pending.resultKeys[key] then pending.resultKeys[key]=fingerprint;pending.results[#pending.results+1]=r end
        schedule();return
    end
    if event=="LOOT_CLOSED" or event=="BAG_UPDATE_DELAYED" then
        if pending then pending.lastChange=clock();if event=="LOOT_CLOSED" then pending.lootClosed=true end;schedule() end;return
    end
    if unit~="player" then return end
    local guid,recipe=event=="UNIT_SPELLCAST_SENT" and b or a,event=="UNIT_SPELLCAST_SENT" and c or b
    if event=="UNIT_SPELLCAST_SENT" or event=="UNIT_SPELLCAST_START" then LL:BeginCraftCapture(guid,recipe)
    elseif not pending and event=="UNIT_SPELLCAST_SUCCEEDED" and LL.db and describe(LL,recipe) then
        local recorded=false
        for _,r in ipairs(ledger(LL).records) do if r.operationID==guid then recorded=true end end
        if not recorded and enabled(LL,describe(LL,recipe).method) then diagnostic(LL,{guid=guid,recipe=recipe,method=describe(LL,recipe).method,success=true},"Success without an isolated start snapshot") end
    elseif pending and pending.guid==guid and pending.recipe==recipe then
        if event=="UNIT_SPELLCAST_SUCCEEDED" then
            if not pending.success then
                pending.success=true
                if C_Timer and C_Timer.After then
                    local p=pending;C_Timer.After(13,function() if pending==p then LL:FinishCraftCapture(true) end end)
                end
            end
            schedule()
        else pending=nil end
    end
end)
-- Preserve public diagnostic entry points; capture itself uses the unified frame.
function LL:FinishProcessingTracking() return self:FinishCraftCapture(false) end
function LL:TrackingStart(guid) return self:BeginCraftCapture(guid,13262) end
function LL:TrackingFinish() return self:FinishCraftCapture(false) end
function LL:DisenchantTrackingReport() return self:CraftRecordingReport() end

local legacyProcessingStats=LL.ShowProcessingStats
function LL:ShowProcessingStats()
    return self:CraftRecordingReport().."\nLegacy aggregate data (not used as verified cast logs):\n"..
        (legacyProcessingStats and legacyProcessingStats(self) or "None")
end
