-- B7: import recorded results that another player exported (Export button).
-- Imported casts are kept as their own evidence source ("imported"), separate
-- from your own recordings, with their own confidence and settings weight.
-- Only counts are stored (casts, how often each material dropped, totals and
-- the smallest/largest amount seen), never the other player's raw records.
local _,LL=...
local SCHEMA="loot-liquidator.cast-log/1"
local MAX_TEXT=500000          -- characters; one export page is far smaller
local MAX_RECORDS=2000         -- matches the recorder's bounded retained ledger
local MAX_INPUTS_PER_CAST=20   -- mass milling uses 20; disenchanting uses 1
local MAX_PER_MATERIAL=100     -- no processing cast returns more of one item
local MAX_OUTPUTS=20
local MAX_SEEN=50000           -- remembered cast IDs, to refuse duplicates
local SUPPORTED={Disenchant=true,Mill=true,Prospect=true,Smelt=true}

local function integer(n,lo,hi) return type(n)=="number" and n==n and n%1==0 and n>=(lo or 1) and n<=(hi or 2147483647) end
local function build() return GetBuildInfo and tostring(select(2,GetBuildInfo())) or "unknown" end
local function disenchantCategory(expansion,rarity,classID)
    if integer(expansion,0,11) and integer(rarity,2,4) and (classID==2 or classID==4) then
        return ('gear:%d:%d:%s'):format(expansion,rarity,classID==2 and 'weapon' or 'armor')
    end
end

-- Small strict JSON reader. Anything malformed fails the whole paste.
-- Preserve null entries and container types so a damaged array cannot silently
-- shrink into a different set of casts or materials during validation.
local JSON_NULL,JSON_OBJECT,JSON_ARRAY={},{},{}
local function object(v) return type(v)=="table" and getmetatable(v)==JSON_OBJECT end
local function array(v) return type(v)=="table" and getmetatable(v)==JSON_ARRAY end
local function plain(v)
    if v==JSON_NULL then return nil end
    if type(v)~='table' then return v end
    local result={} for k,x in pairs(v) do result[k]=plain(x) end return result
end
local function signature(v,legacy)
    -- Lua 5.1 tostring rounds doubles; preserve every native numeric bit in
    -- grouping and profile equality. Persisted seen IDs still deduplicate imports.
    if type(v)=='number' and not legacy then return 'number:'..(v==0 and '0' or string.format('%.17g',v)) end
    if type(v)~='table' then return type(v)..':'..tostring(v) end
    local keys={} for k in pairs(v) do keys[#keys+1]=k end
    table.sort(keys,function(a,b)return tostring(a)<tostring(b) end)
    local result={}
    for _,k in ipairs(keys) do
        local key,value=signature(k,legacy),signature(v[k],legacy)
        result[#result+1]=#key..':'..key..#value..':'..value
    end
    return '{'..table.concat(result)..'}'
end
-- Reconcile a partial upgrade only when both aggregate memberships are complete
-- and disjoint. Never infer per-cast outputs from overlapping or damaged history.
local function mergeDisjointSalvage(target,legacy)
    local seen={}
    for _,set in ipairs({target,legacy}) do
        if not integer(set.casts,1,MAX_SEEN) or not integer(set.consumed,0)
            or type(set.sourceRecordIDs)~='table' or #set.sourceRecordIDs~=set.casts
            or type(set.materials)~='table' then return false end
        local count=0
        for k,id in pairs(set.sourceRecordIDs) do
            if not integer(k,1,set.casts) or type(id)~='string' or id=='' or seen[id] then return false end
            seen[id]=true;count=count+1
        end
        if count~=set.casts or set.consumed>set.casts*set.inputCount then return false end
        for id,m in pairs(set.materials) do
            if not integer(id) or type(m)~='table' or not integer(m.drops,1,set.casts)
                or not integer(m.total,m.drops) or not integer(m.min,1,MAX_PER_MATERIAL)
                or not integer(m.max,m.min,MAX_PER_MATERIAL) or not integer(m.quality,1,5)
                or m.total<m.drops*m.min or m.total>m.drops*m.max then return false end
            local other=target.materials[id]
            if other and other.quality~=m.quality then return false end
        end
    end
    if target.casts+legacy.casts>MAX_SEEN then return false end
    for id,m in pairs(legacy.materials) do
        local n=target.materials[id]
        if n then
            n.drops=n.drops+m.drops;n.total=n.total+m.total
            n.min=math.min(n.min,m.min);n.max=math.max(n.max,m.max)
        else target.materials[id]=plain(m) end
    end
    for _,id in ipairs(legacy.sourceRecordIDs) do target.sourceRecordIDs[#target.sourceRecordIDs+1]=id end
    target.casts=target.casts+legacy.casts;target.consumed=target.consumed+legacy.consumed
    return true
end
local function sameSalvageContext(a,b)
    return a.salvage and b.salvage and a.studyID==b.studyID
        and a.recipeID==b.recipeID and a.method==b.method
        and a.inputItemID==b.inputItemID and a.inputCount==b.inputCount
        and a.inputQualityRank==b.inputQualityRank and a.build==b.build
        and a.applyConcentration==b.applyConcentration
        and signature(a.allocation)==signature(b.allocation)
        and signature(a.observationContext)==signature(b.observationContext)
end
-- Verify the complete encoded key, treating the embedded cohort as opaque. Its
-- recipe/input/rank components are bounded integers and unchanged by precision.
-- This avoids guessing context IDs that are absent from saved aggregate fields.
local function exactPartnerKey(key,set)
    if type(key)~='string' or not set.salvage or type(set.observationContext)~='table' then return nil end
    local length,offset=key:match('^salvage:{8:number:1(%d+):()')
    length=tonumber(length)
    if not length or length>#key then return nil end
    local value=key:sub(offset,offset+length-1)
    if value:sub(1,7)~='string:' then return nil end
    local cohort=value:sub(8)
    if key~='salvage:'..signature({cohort,signature(set.observationContext,true)},true) then return nil end
    local exact='salvage:'..signature({cohort,signature(set.observationContext)})
    return exact~=key and exact or nil
end
local function reconcileSavedPairs(sets)
    local changed,held,groups=false,{},{}
    -- Group first, then mutate. Two old signed-zero keys can share one canonical
    -- identity even before an exact-key aggregate has ever been imported.
    for legacyKey,legacy in pairs(sets) do
        local key=exactPartnerKey(legacyKey,legacy)
        if key then
            groups[key]=groups[key] or {}
            groups[key][#groups[key]+1]=legacyKey
        end
    end
    for key,legacyKeys in pairs(groups) do
        table.sort(legacyKeys)
        local targetKey=sets[key] and key or legacyKeys[1]
        local target=sets[targetKey]
        for _,legacyKey in ipairs(legacyKeys) do
            local legacy=sets[legacyKey]
            if legacyKey~=targetKey and legacy and sameSalvageContext(target,legacy) then
                if mergeDisjointSalvage(target,legacy) then sets[legacyKey]=nil;changed=true
                else held[targetKey]=true;held[legacyKey]=true end
            end
        end
    end
    return changed,held
end
local function measuredProfile(context)
    local result=plain(context)
    result.character=nil;result.observed=nil;result.previousSnapshot=nil
    result.inputExpansionID=nil;result.inputIdentity=nil
    return result
end
local function boundedContext(context)
    local nodes,characters=0,0
    local function visit(v)
        nodes=nodes+1
        if type(v)=='string' then characters=characters+#v end
        if nodes>4096 or characters>65536 then return false end
        if type(v)=='table' then for k,x in pairs(v) do if not visit(k) or not visit(x) then return false end end end
        return true
    end
    return visit(context) and plain(context) or nil
end
local function decode(text)
    local pos,len=1,#text
    local function fail(msg) error(msg.." (character "..pos..")",0) end
    local function ws() pos=text:find("[^ \t\r\n]",pos) or len+1 end
    local escapes={['"']='"',['\\']='\\',['/']='/',b='\b',f='\f',n='\n',r='\r',t='\t'}
    local function codepoint()
        local hex=text:sub(pos,pos+3)
        if not hex:match("^%x%x%x%x$") then fail("bad Unicode escape") end
        pos=pos+4;return tonumber(hex,16)
    end
    local function utf8(n)
        if n<128 then return string.char(n) end
        if n<2048 then return string.char(192+math.floor(n/64),128+n%64) end
        if n<65536 then return string.char(224+math.floor(n/4096),128+math.floor(n/64)%64,128+n%64) end
        return string.char(240+math.floor(n/262144),128+math.floor(n/4096)%64,128+math.floor(n/64)%64,128+n%64)
    end
    local function str()
        local out={};pos=pos+1
        while true do
            local c=text:sub(pos,pos)
            if c=="" then fail("unfinished text") end
            if c=='"' then pos=pos+1;return table.concat(out) end
            if c=="\\" then
                local e=text:sub(pos+1,pos+1)
                if escapes[e] then out[#out+1]=escapes[e];pos=pos+2
                elseif e=="u" then
                    pos=pos+2;local n=codepoint()
                    if n>=55296 and n<=56319 then
                        if text:sub(pos,pos+1)~="\\u" then fail("missing Unicode surrogate") end
                        pos=pos+2;local low=codepoint()
                        if low<56320 or low>57343 then fail("bad Unicode surrogate") end
                        n=65536+(n-55296)*1024+low-56320
                    elseif n>=56320 and n<=57343 then fail("unexpected Unicode surrogate") end
                    out[#out+1]=utf8(n)
                else fail("bad escape") end
            else
                if c:byte()<32 then fail("unescaped control character") end
                local _,e=text:find('^[^"\\%z\1-\31]+',pos);out[#out+1]=text:sub(pos,e);pos=e+1
            end
        end
    end
    local value
    function value(depth)
        if depth>24 then fail("nested too deeply") end
        ws();local c=text:sub(pos,pos)
        if c=="{" then
            local t=setmetatable({},JSON_OBJECT);pos=pos+1;ws()
            if text:sub(pos,pos)=="}" then pos=pos+1;return t end
            while true do
                ws();if text:sub(pos,pos)~='"' then fail("expected a name") end
                local k=str();ws()
                if t[k]~=nil then fail("repeated name") end
                if text:sub(pos,pos)~=":" then fail("expected ':'") end
                pos=pos+1;t[k]=value(depth+1);ws()
                local d=text:sub(pos,pos);pos=pos+1
                if d=="}" then return t elseif d~="," then fail("expected ',' or '}'") end
            end
        elseif c=="[" then
            local t,i=setmetatable({},JSON_ARRAY),0;pos=pos+1;ws()
            if text:sub(pos,pos)=="]" then pos=pos+1;return t end
            while true do
                i=i+1;t[i]=value(depth+1);ws()
                local d=text:sub(pos,pos);pos=pos+1
                if d=="]" then return t elseif d~="," then fail("expected ',' or ']'") end
            end
        elseif c=='"' then return str()
        elseif text:sub(pos,pos+3)=="true" then pos=pos+4;return true
        elseif text:sub(pos,pos+4)=="false" then pos=pos+5;return false
        elseif text:sub(pos,pos+3)=="null" then pos=pos+4;return JSON_NULL
        end
        local start=pos
        local function digits()
            local s,e=text:find("^%d+",pos)
            if not s then fail("expected a digit") end
            pos=e+1
        end
        if text:sub(pos,pos)=="-" then pos=pos+1 end
        if text:sub(pos,pos)=="0" then pos=pos+1 else digits() end
        if text:sub(pos,pos)=="." then pos=pos+1;digits() end
        local exp=text:sub(pos,pos)
        if exp=="e" or exp=="E" then
            pos=pos+1;local sign=text:sub(pos,pos)
            if sign=="+" or sign=="-" then pos=pos+1 end
            digits()
        end
        local n=tonumber(text:sub(start,pos-1))
        if not n or n~=n or n==math.huge or n==-math.huge then fail("unexpected character") end
        return n
    end
    local ok,result=pcall(function()
        local v=value(0);ws()
        if pos<=len then fail("extra text after the data") end
        return v
    end)
    if ok then return result end
    return nil,result
end
local function decodeTransfer(text)
    local data,why=decode(text)
    if not data then return nil,why end
    if not object(data) or data.schemaVersion~='loot-liquidator.cast-transfer/1' then return data,nil,text end
    if data.encoding~='zlib-base64' or not integer(data.uncompressedBytes,1,16777216)
        or type(data.payload)~='string' or #data.payload>65536 then return nil,'Invalid compact export' end
    local api=C_EncodingUtil
    if not api or type(api.DecodeBase64)~='function' or type(api.DecompressString)~='function' then
        return nil,'This client cannot read compact exports; ask for Export pages.'
    end
    local ok,compressed=pcall(api.DecodeBase64,data.payload)
    if not ok or type(compressed)~='string' then return nil,'Damaged compact export' end
    local raw;ok,raw=pcall(api.DecompressString,compressed,1)
    if not ok or type(raw)~='string' or #raw~=data.uncompressedBytes then return nil,'Damaged compact export length' end
    local inner;inner,why=decode(raw)
    if not object(inner) or inner.schemaVersion~=SCHEMA then return nil,why or 'Invalid compact research data' end
    return inner,nil,raw
end
LL.DecodeImportJSON=decodeTransfer

-- Returns a clean cast {method,input,batch,build,outputs={[id]=qty}} or nil, why.
local function salvageDefinition(self,r)
    local definition=self.SalvageRecipeDefinition and self:SalvageRecipeDefinition(r.recipeID)
    if definition and definition.method==r.method then return definition end
end
local function checkRecord(self,r)
    if not object(r) then return nil,"damaged" end
    if r.outputCoverage~="complete" then return nil,"incomplete" end
    local salvage=salvageDefinition(self,r)
    if not SUPPORTED[r.method] and not salvage then return nil,"unsupported" end
    if r.successful~=true or type(r.operationID)~="string" or r.operationID=="" or #r.operationID>160 then return nil,"damaged" end
    local inputs=r.nominalInputs
    if inputs==nil then inputs=r.inputs end
    if not array(inputs) then return nil,"damaged" end
    if #inputs~=1 then return nil,"unsupported" end
    if not object(inputs[1]) then return nil,"damaged" end
    local input,batch=inputs[1].itemID,inputs[1].quantity
    if not integer(input) or not integer(batch,1,MAX_INPUTS_PER_CAST) then return nil,"damaged" end
    if r.method=="Disenchant" and batch~=1 then return nil,"damaged" end
    -- Modern cast exports carry the physical input category. Keep it instead
    -- of restricting every imported result to the sampled item ID. Missing
    -- fields in older exports are unknown, never guessed from item IDs.
    local expansion,rarity,classID
    if r.method=="Disenchant" then
        local item=inputs[1]
        expansion=item.expansionID;if expansion==JSON_NULL then expansion=nil end
        rarity=item.rarity;if rarity==JSON_NULL then rarity=nil end
        classID=item.classID;if classID==JSON_NULL then classID=nil end
        if (expansion~=nil and not integer(expansion,0,11))
            or (rarity~=nil and not integer(rarity,2,4))
            or (classID~=nil and classID~=2 and classID~=4) then return nil,"damaged" end
    end
    if not array(r.outputs) or #r.outputs>MAX_OUTPUTS then return nil,"damaged" end
    if #r.outputs==0 and r.zeroEvidence~="operator-confirmed-empty" then return nil,"damaged" end
    local outputs={}
    for _,m in ipairs(r.outputs) do
        if not object(m) or not integer(m.itemID) or not integer(m.quantity,1,MAX_PER_MATERIAL)
            or m.itemID==input or outputs[m.itemID] then return nil,"damaged" end
        outputs[m.itemID]=m.quantity
    end
    local b=r.build
    if type(b)=="number" then b=tostring(b) end
    if type(b)~="string" or not (b:match("^%d+$") or b=="unknown") then return nil,"damaged" end
    return {id=r.operationID,method=r.method,input=input,batch=batch,build=b,outputs=outputs,salvage=salvage and true or nil,
        expansionID=expansion,inputRarity=rarity,inputClassID=classID,
        gearKey=r.method=="Disenchant" and disenchantCategory(expansion,rarity,classID) or nil}
end

-- Additional methods use the recorder's exact, verified salvage contract. A
-- positive result alone is insufficient: all native receipts and the complete
-- shared inventory reconciliation must survive import before any counts enter
-- a cohort. Legacy four-method imports retain their existing contract.
local function salvageCasts(self,data)
    local result,batches,nativeIDs,castIDs,cohorts,contexts={},{},{},{},{},{}
    local function vector(items,zero)
        if not array(items) then return nil end
        local values={}
        for _,item in ipairs(items) do
            if not object(item) or not integer(item.itemID) or not integer(item.quantity,zero and 0 or 1)
                or values[item.itemID]~=nil then return nil end
            values[item.itemID]=item.quantity
        end
        return values
    end
    local function validate(r,cast)
        local def=salvageDefinition(self,r)
        local context=object(data.contexts) and data.contexts[r.contextID]
        local study=object(data.studies) and data.studies[r.studyID]
        if data.artifactStatus~='RESEARCH_ONLY_NOT_SHIPPED' or data.registryContract~='profession-mechanics/0.2'
            or data.automaticMechanicsPromotion~=false or r.schemaVersion~=SCHEMA or r.gameMode~='RETAIL'
            or type(r.character)~='string' or r.character=='' or #r.character>160
            or not object(context) or not object(study) or context.character~=r.character or study.character~=r.character
            or study.build~=r.build or context.recipeID~=r.recipeID or context.method~=r.method
            or context.profileKind~='measured' or context.simulated~=false or context.profession~=def.profession
            or context.inputExpansionID~=def.expansionID or not integer(context.skillLineID)
            or not integer(context.baseSkill,0) or not integer(context.bonusSkill,0) or not integer(context.effectiveSkill,0)
            or type(context.specialization)~='string' or context.specialization==''
            or not array(context.operationStats) or not object(context.equipment)
            or not object(context.fieldStatus) or context.fieldStatus.equipment~='measured'
            or type(r.applyConcentration)~='boolean' or context.applyConcentration~=r.applyConcentration
            or not object(r.allocation) or next(r.allocation) then return 'damaged' end
        local measured=contexts[context]
        if measured==nil then
            local value=boundedContext(context)
            measured=value and {value=value,profile=signature(measuredProfile(value)),identity=signature(value),keys={}} or false
            contexts[context]=measured
        end
        if not measured then return 'damaged' end
        local provenance=r.provenance
        if not object(provenance) or provenance.sampleKind~='RAW_CAST_LOG'
            or provenance.numericTransformValidated~=false or provenance.applyPolicy~='NO_NUMERIC_TRANSFORM'
            or provenance.independentReview~='PENDING' then return 'damaged' end
        if study.truncated or study.globalCoverageGap then return 'incomplete' end
        if study.censored and (study.coverageVersion~=2 or not object(study.coverageGaps)
            or not next(study.coverageGaps) or study.coverageGaps[r.method..':'..r.recipeID]) then return 'incomplete' end
        local nominal,net=vector(r.nominalInputs),vector(r.inputs,true)
        local input=r.nominalInputs and r.nominalInputs[1]
        if not nominal or not net or #r.nominalInputs~=1 or #r.inputs~=1
            or cast.batch~=def.inputCount or net[cast.input]==nil or net[cast.input]>cast.batch
            or input.expansionID~=def.expansionID or not integer(input.qualityRank,1,5)
            or not array(context.inputIdentity) or #context.inputIdentity~=1 or not object(context.inputIdentity[1])
            or context.inputIdentity[1].itemID~=cast.input or context.inputIdentity[1].quantity~=cast.batch
            or context.inputIdentity[1].qualityRank~=input.qualityRank then return 'damaged' end
        local target=r.salvageTarget
        if r.attribution~='cast-result-batch-bag' or r.captureVersion~=3 or not object(target)
            or target.itemID~=cast.input or target.quantity~=cast.batch or type(target.itemGUID)~='string'
            or target.itemGUID=='' or target.itemGUID~=r.allocationItemGUID
            or target.eligibilitySource~='C_TradeSkillUI.GetSalvagableItemIDs'
            or not array(r.resultMetadata) or #r.resultMetadata==0 or #r.resultMetadata>MAX_OUTPUTS then return 'damaged' end
        local typed,operation,refunds,returnSignature={}
        local receiptSeen={}
        local quality={}
        for _,receipt in ipairs(r.resultMetadata) do
            if not object(receipt) or not integer(receipt.operationID,1,9007199254740991) or not integer(receipt.itemID)
                or not integer(receipt.quantity,1,MAX_PER_MATERIAL) or receipt.itemID==cast.input
                or type(receipt.itemGUID)~='string' or receipt.itemGUID==''
                or (operation and operation~=receipt.operationID) then return 'damaged' end
            local receiptKey=signature(receipt)
            if receiptSeen[receiptKey] then return 'damaged' end
            receiptSeen[receiptKey]=true
            operation=receipt.operationID;typed[receipt.itemID]=(typed[receipt.itemID] or 0)+receipt.quantity
            if receipt.resourcesReturned~=nil then
                if not array(receipt.resourcesReturned) then return 'damaged' end
                local sig=signature(receipt.resourcesReturned)
                if returnSignature and returnSignature~=sig then return 'damaged' end
                if not returnSignature then
                    returnSignature=sig;refunds=0
                    for _,returned in ipairs(receipt.resourcesReturned) do
                        if not object(returned) or not object(returned.reagent) or returned.reagent.itemID~=cast.input
                            or not integer(returned.quantity,1,cast.batch) then return 'damaged' end
                        refunds=refunds+returned.quantity
                    end
                end
            end
        end
        if signature(typed)~=signature(cast.outputs) or net[cast.input]~=cast.batch-(refunds or 0) then return 'damaged' end
        for _,material in ipairs(r.outputs) do
            if not integer(material.qualityRank,1,5) then return 'damaged' end
            quality[material.itemID]=material.qualityRank
        end
        local evidence=r.bagReconciliation
        if not object(evidence) or type(evidence.id)~='string' or evidence.id==''
            or not integer(evidence.operations,1,MAX_RECORDS) or not vector(evidence.inputs) or not vector(evidence.outputs) then return 'damaged' end
        cast.recipeID=r.recipeID;cast.studyID=r.studyID;cast.contextID=r.contextID
        cast.observationContext=measured.value;cast.profileKey=measured.profile
        cast.inputQualityRank=input.qualityRank;cast.outputQualities=quality
        cast.expansionID=def.expansionID;cast.consumed=net[cast.input]
        cast.allocation=plain(r.allocation);cast.applyConcentration=r.applyConcentration
        cast.sourceCharacter=r.character;cast.nativeID=table.concat({r.character,cast.build,r.recipeID,operation},':')
        cast.cohortKey=table.concat({r.studyID,r.contextID,r.recipeID},':')
        cast.batchKey=table.concat({r.studyID,r.method,r.recipeID,evidence.id},':')
        cast.reconciliation=evidence
        local cohort=signature({r.character,cast.build,r.studyID,r.contextID,r.recipeID,cast.input,input.qualityRank,r.applyConcentration})
        measured.keys[cohort]=measured.keys[cohort] or ('salvage:'..signature({cohort,measured.identity}))
        cast.storageKey=measured.keys[cohort]
        local legacyCohort=signature({r.character,cast.build,r.studyID,r.contextID,r.recipeID,cast.input,input.qualityRank,r.applyConcentration},true)
        measured.legacyKeys=measured.legacyKeys or {}
        if not measured.legacyKeys[legacyCohort] then
            measured.legacyIdentity=measured.legacyIdentity or signature(measured.value,true)
            measured.legacyKeys[legacyCohort]='salvage:'..signature({legacyCohort,measured.legacyIdentity},true)
        end
        cast.legacyStorageKey=measured.legacyKeys[legacyCohort]
        return nil
    end
    for i,r in ipairs(data.records) do
        if object(r) and salvageDefinition(self,r) then
            local cast,reason=checkRecord(self,r)
            if cast then reason=validate(r,cast) end
            result[i]={cast=cast,reason=reason}
            local cohort=type(r.studyID)=='string' and type(r.contextID)=='string'
                and table.concat({r.studyID,r.contextID,r.recipeID},':')
            if cohort then
                cohorts[cohort]=cohorts[cohort] or {members={}}
                local group=cohorts[cohort];group.members[#group.members+1]=i
                group.invalid=group.invalid or reason
            end
            if cast and not reason then
                if castIDs[cast.id] then
                    result[i].reason='damaged';result[castIDs[cast.id]].reason='damaged'
                end
                castIDs[cast.id]=i
                local batch=batches[cast.batchKey] or {members={},inputs={},outputs={},ids={},evidence=cast.reconciliation}
                batches[cast.batchKey]=batch;batch.members[#batch.members+1]=i;batch.ids[cast.id]=true
                if signature(batch.evidence)~=signature(cast.reconciliation) or nativeIDs[cast.nativeID] then batch.invalid=true end
                if nativeIDs[cast.nativeID] then result[nativeIDs[cast.nativeID]].reason='damaged' end
                nativeIDs[cast.nativeID]=i
                batch.inputs[cast.input]=(batch.inputs[cast.input] or 0)+cast.consumed
                for id,n in pairs(cast.outputs) do batch.outputs[id]=(batch.outputs[id] or 0)+n end
            end
        end
    end
    local missingBatch=false
    for _,batch in pairs(batches) do
        for id,n in pairs(batch.inputs) do if n==0 then batch.inputs[id]=nil end end
        if #batch.members<batch.evidence.operations or not batch.ids[batch.evidence.id] then
            missingBatch=true
            for _,i in ipairs(batch.members) do result[i].reason='incomplete' end
        elseif batch.invalid or #batch.members~=batch.evidence.operations
            or signature(batch.inputs)~=signature(vector(batch.evidence.inputs))
            or signature(batch.outputs)~=signature(vector(batch.evidence.outputs)) then
            for _,i in ipairs(batch.members) do result[i].reason='damaged' end
        end
    end
    -- An invalid member cannot leave a positive-only remainder of its cohort.
    for _,cohort in pairs(cohorts) do
        local invalid=cohort.invalid
        for _,i in ipairs(cohort.members) do invalid=invalid or result[i].reason end
        if invalid then for _,i in ipairs(cohort.members) do result[i].reason=invalid end end
    end
    return result,missingBatch
end

local function store(self)
    local d=self.db.importedResults
    if type(d)~="table" or d.version~=1 then
        d={version=1,imports={},sets={},seen={},seenCount=0};self.db.importedResults=d
    end
    return d
end

-- Import one pasted export page. Returns ok, plain-words message, details.
function LL:ImportRecordedResults(text,label)
    if not self.db then return false,"Settings are not loaded yet." end
    if type(text)~="string" then return false,"Nothing to import." end
    text=text:gsub("^%s+",""):gsub("%s+$","")
    if text=="" then return false,"Nothing to import: paste the text from another player's Export first." end
    if #text>MAX_TEXT then return false,"That text is too long. Paste one export page at a time." end
    local data,why=decodeTransfer(text)
    if not object(data) then return false,"That text could not be read (it looks damaged or incomplete). Nothing was imported.",{error=why} end
    if data.schemaVersion~=SCHEMA or data.sampleKind~="RAW_CAST_LOG" or not array(data.records) then
        return false,"That text is not a Loot Liquidator results export. Nothing was imported."
    end
    if #data.records>MAX_RECORDS then return false,"That export has too many results for one page. Nothing was imported." end
    local own,ownNative={},{}
    for _,r in ipairs(self.db.craftResearch and self.db.craftResearch.records or {}) do
        own[r.operationID]=true
        if salvageDefinition(self,r) then
            for _,receipt in ipairs(r.resultMetadata or {}) do
                if integer(receipt.operationID,1,9007199254740991) then
                    ownNative[table.concat({r.character,r.build,r.recipeID,receipt.operationID},':')]=true
                end
            end
        end
    end
    local d=store(self)
    local salvage,missingBatch=salvageCasts(self,data)
    if missingBatch then
        return false,'This export omits members of a shared salvage batch. Use the complete Export recorded results document (or its compact export), rather than one split page. Nothing was imported.'
    end
    local counts={accepted=0,damaged=0,incomplete=0,unsupported=0,duplicate=0,own=0}
    local clean,inPaste={},{}
    for i,r in ipairs(data.records) do
        local entry=salvage[i]
        local cast,reason
        if entry then cast,reason=entry.cast,entry.reason else cast,reason=checkRecord(self,r) end
        if reason then cast=nil end
        if cast and (d.seen[cast.id] or inPaste[cast.id]
            or (cast.nativeID and d.nativeSeen and d.nativeSeen[cast.nativeID])) then cast,reason=nil,"duplicate"
        elseif cast and (own[cast.id] or (cast.nativeID and ownNative[cast.nativeID])) then cast,reason=nil,"own" end
        if cast then clean[#clean+1]=cast;inPaste[cast.id]=true else counts[reason]=counts[reason]+1 end
    end
    -- A paste with many impossible values is treated as damaged or fake as a whole.
    local total=#data.records
    if counts.damaged>0 and counts.damaged>=math.max(2,total*.2) then
        return false,("%d of %d results had impossible values, so this text looks damaged or edited. Nothing was imported."):format(counts.damaged,total),counts
    end
    if d.seenCount+#clean>MAX_SEEN then
        for _,cast in ipairs(clean) do if cast.salvage then
            return false,'Import history is full. Remove imported results before adding more verified salvage results.',counts
        end end
    end
    local migrationChecked={}
    for _,cast in ipairs(clean) do
        local inputKey=cast.gearKey or tostring(cast.input)
        -- Partial category metadata is still useful as a physical scope guard;
        -- separate it from old unscoped per-item sets rather than losing it.
        if cast.method=="Disenchant" and not cast.gearKey
            and (cast.expansionID~=nil or cast.inputRarity~=nil or cast.inputClassID~=nil) then
            inputKey=inputKey..":"..tostring(cast.expansionID)..":"..tostring(cast.inputRarity)..":"..tostring(cast.inputClassID)
        end
        local key=cast.method..":"..inputKey..":"..cast.batch..":"..cast.build
        if cast.salvage then key=cast.storageKey end
        local set=d.sets[key]
        if cast.salvage and cast.legacyStorageKey~=key and not migrationChecked[key] then
            migrationChecked[key]=true
            local legacy=d.sets[cast.legacyStorageKey]
            -- Upgrade a single existing aggregate only after exact native identity
            -- verification. Rounded legacy-key collisions must not pool profiles.
            if legacy and legacy.salvage and legacy.studyID==cast.studyID
                and legacy.recipeID==cast.recipeID and legacy.method==cast.method
                and legacy.inputItemID==cast.input and legacy.inputCount==cast.batch
                and legacy.inputQualityRank==cast.inputQualityRank and legacy.build==cast.build
                and legacy.applyConcentration==cast.applyConcentration
                and signature(legacy.allocation)==signature(cast.allocation)
                and signature(legacy.observationContext)==signature(cast.observationContext) then
                if not set then
                    set=legacy;d.sets[key]=legacy;d.sets[cast.legacyStorageKey]=nil
                elseif set~=legacy and sameSalvageContext(set,legacy)
                    and mergeDisjointSalvage(set,legacy) then
                    d.sets[cast.legacyStorageKey]=nil
                end
            end
        end
        if not set then
            set={method=cast.method,inputItemID=not cast.gearKey and cast.input or nil,gearKey=cast.gearKey,
                expansionID=cast.expansionID,inputRarity=cast.inputRarity,inputClassID=cast.inputClassID,
                inputCount=cast.batch,build=cast.build,casts=0,materials={},memberInputItemIDs={}}
            if cast.salvage then
                set.salvage=true;set.recipeID=cast.recipeID;set.studyID=cast.studyID
                set.referenceContextID='imported-salvage:'..signature({cast.recipeID,cast.input,
                    cast.inputQualityRank,cast.build,cast.profileKey})
                set.observationContext=cast.observationContext;set.inputQualityRank=cast.inputQualityRank
                set.allocation=cast.allocation;set.applyConcentration=cast.applyConcentration
                set.consumed=0;set.sourceRecordIDs={}
            end
            d.sets[key]=set
        end
        set.memberInputItemIDs=set.memberInputItemIDs or {}
        set.memberInputItemIDs[cast.input]=true
        set.casts=set.casts+1
        if cast.salvage then
            set.consumed=set.consumed+cast.consumed
            set.sourceRecordIDs[#set.sourceRecordIDs+1]=cast.id
            d.nativeSeen=d.nativeSeen or {};d.nativeSeen[cast.nativeID]=true
        end
        for id,qty in pairs(cast.outputs) do
            local m=set.materials[id] or {drops=0,total=0};set.materials[id]=m
            m.drops=m.drops+1;m.total=m.total+qty
            if cast.salvage then m.quality=cast.outputQualities[id] end
            m.min=math.min(m.min or qty,qty);m.max=math.max(m.max or qty,qty)
        end
        if d.seenCount<MAX_SEEN then d.seen[cast.id]=true;d.seenCount=d.seenCount+1 end
        counts.accepted=counts.accepted+1
    end
    if counts.accepted==0 then
        local detail=counts.duplicate+counts.own>0 and " They were already imported (or are your own)." or ""
        return false,"No usable results found in that text."..detail,counts
    end
    d.imports[#d.imports+1]={importedAt=time and time() or 0,label=type(label)=="string" and label:sub(1,80) or nil,
        casts=counts.accepted,skipped=total-counts.accepted}
    if #d.imports>200 then table.remove(d.imports,1) end
    self._importedIndex=nil;self._importedRevision=(self._importedRevision or 0)+1
    if self.Invalidate then self:Invalidate("evidence") end
    local skipped=total-counts.accepted
    return true,("Imported %d results.%s They count as a separate source (Imported results) with their own confidence."):format(
        counts.accepted,skipped>0 and (" Skipped %d (incomplete, unsupported, damaged or already imported)."):format(skipped) or ""),counts
end

-- Matching native measurements can change without changing the cached generic
-- profession context. Recheck this small eligibility fingerprint before using
-- a cached economic model, including cached missing-data answers.
function LL:ImportedSalvageContextKey(f,option,ctx)
    local key=option.name..':'..tostring(f.id)
    local records=self:ImportedEvidenceRecords(key)
    local present=false
    for _,record in ipairs(records or {}) do if record.salvage then present=true;break end end
    if not present then return nil end
    local included={}
    local eligible=self:ImportedEvidenceRecords(key,f,option,ctx) or {}
    for _,record in ipairs(eligible) do included[record]=true end
    local matches={}
    for i,record in ipairs(records) do if record.salvage and included[record] then matches[#matches+1]=i end end
    return table.concat(matches,','),eligible
end

function LL:ImportedResultsCount()
    local d=self.db and self.db.importedResults;local n=0
    for _,set in pairs(type(d)=="table" and d.sets or {}) do n=n+(set.casts or 0) end
    return n
end
function LL:ClearImportedResults()
    if not self.db then return false,"Nothing imported." end
    local n=self:ImportedResultsCount()
    self.db.importedResults=nil;self._importedIndex=nil;self._importedRevision=(self._importedRevision or 0)+1
    if self.Invalidate then self:Invalidate("evidence") end
    return true,("Removed %d imported results. Your own recorded results are unchanged."):format(n)
end

-- Confidence that the true drop chance is within 5 points of the shown one
-- (normal approximation; 18% over 50 casts gives about 64%).
local function erf(x)
    local t=1/(1+.3275911*x)
    return 1-(((((1.061405429*t-1.453152027)*t)+1.421413741)*t-.284496736)*t+.254829592)*t*math.exp(-x*x)
end
local function chanceConfidence(drops,casts)
    if casts<=0 then return 0 end
    local p=(drops+.5)/(casts+1)
    local se=math.sqrt(p*(1-p)/casts)
    return math.max(1,math.min(95,math.floor(erf(.05/(se*math.sqrt(2)))*100+.5)))
end
LL.ImportChanceConfidence=chanceConfidence

-- Evidence records in the same shape as ItemDB/legacy records. Fixed reference:
-- the other player's skill is unknown, so these are never character-adjusted.
function LL:ImportedEvidenceRecords(indexKey,f,option,ctx)
    local d=self.db and self.db.importedResults
    if type(d)~="table" or type(d.sets)~="table" then return nil end
    local current=build()
    if not self._importedIndex or self._importedIndex.build~=current then
        local changed,held=reconcileSavedPairs(d.sets)
        if changed then self._importedRevision=(self._importedRevision or 0)+1 end
        local index={build=current}
        for key,set in pairs(d.sets) do
            local category=set.method=="Disenchant" and disenchantCategory(set.expansionID,set.inputRarity,set.inputClassID)
            category=category and category==set.gearKey and category or nil
            local salvage=set.salvage and salvageDefinition(self,{method=set.method,recipeID=set.recipeID})
            if (SUPPORTED[set.method] or salvage) and integer(set.casts) and (category or integer(set.inputItemID)) and integer(set.inputCount) then
                local r={recordID="imported:"..key,studyID="imported:"..key,sourceKey="imported",source="Imported results",
                    method=set.method,inputItemID=not category and set.inputItemID or nil,gearKey=category,
                    expansionID=set.expansionID,inputRarity=set.inputRarity,inputClassID=set.inputClassID,
                    isDisenchantCategory=category and true or nil,
                    inputCount=set.inputCount,samples=set.casts,
                    patchBuild=set.build,fixedReference=true,referenceConditions={},provisional=true,
                    -- Results from another game build count for less (stale), never zero.
                    obsolete=set.build~=current or nil,materials={}}
                if salvage then
                    r.recipeID=set.recipeID;r.studyID=set.studyID
                    -- Normalize only the query identity so legacy/new independent
                    -- studies can share their exact retained native context. Keep
                    -- the original saved identifier intact as historical provenance.
                    r.savedReferenceContextID=set.referenceContextID
                    r.referenceContextID=type(set.observationContext)=='table' and
                        ('imported-salvage:'..signature({set.recipeID,set.inputItemID,
                            set.inputQualityRank,set.build,signature(measuredProfile(set.observationContext))}))
                        or set.referenceContextID
                    r.inputQualityRank=set.inputQualityRank;r.targetBuild=set.build
                    r.expectedInputCount=set.consumed/set.casts
                    r.observationContext=set.observationContext;r.allocation=set.allocation
                    r.applyConcentration=set.applyConcentration;r.sourceRecordIDs=set.sourceRecordIDs
                    r.fixedReference=false;r.salvage=true
                    r.legacyProfileConflict=held[key] or nil
                    r.baselineStatus=held[key] and 'Held: legacy profile aggregates require original raw exports to reconcile'
                        or 'Measured imported salvage cohort; exact matching context required'
                end
                if category then
                    r.memberInputItemIDs={}
                    for id in pairs(set.memberInputItemIDs or {}) do
                        if integer(id) then r.memberInputItemIDs[#r.memberInputItemIDs+1]=id end
                    end
                    table.sort(r.memberInputItemIDs)
                end
                local ids={} for id in pairs(set.materials) do ids[#ids+1]=id end
                table.sort(ids)
                for _,id in ipairs(ids) do
                    local m=set.materials[id]
                    local c=chanceConfidence(m.drops,set.casts)
                    local function field(v) return {value=v,confidence=c,status="observed",samples=set.casts} end
                    r.materials[#r.materials+1]={id=id,quality=m.quality,expectedQuantity=field(m.total/set.casts),
                        dropChance=field(m.drops/set.casts),minQuantity=field(m.min),maxQuantity=field(m.max)}
                end
                if #r.materials>0 then
                    -- Index category results once. Looking up the sampled item
                    -- already includes this group, so an exact-ID alias would
                    -- count those same casts a second time.
                    local k=set.method..":"..(category or set.inputItemID)
                    index[k]=index[k] or {};table.insert(index[k],r)
                end
            end
        end
        self._importedIndex=index
    end
    local records=self._importedIndex[indexKey]
    if not records or not f then return records end
    local eligible,queries={},{}
    for _,record in ipairs(records) do
        if not record.salvage then eligible[#eligible+1]=record
        elseif not record.legacyProfileConflict and option and ctx and not ctx.simulated and not ctx.stale and ctx.character==self:CharacterKey()
            and record.recipeID==option.recipeID and record.inputCount==option.inputCount
            and record.inputQualityRank==f.reagentQuality and tostring(record.targetBuild)==current
            and self.CaptureCraftContext and self.FindSkillQualityTarget then
            local guid=self:FindSkillQualityTarget(f)
            if guid then
                local query=signature({record.recipeID,record.method,record.allocation,record.applyConcentration,guid})
                local live=queries[query]
                if live==nil then
                    live=self:CaptureCraftContext(record.recipeID,f,record.method,record.allocation,record.applyConcentration,guid)
                    queries[query]=type(live)=='table' and live or false
                end
                if type(live)=='table' and live.effectiveSkill~=nil and live.specialization~=nil
                    and live.fieldStatus and live.fieldStatus.equipment=='measured'
                    and signature(measuredProfile(live))==signature(measuredProfile(record.observationContext)) then
                    eligible[#eligible+1]=record
                end
            end
        end
    end
    return eligible
end
