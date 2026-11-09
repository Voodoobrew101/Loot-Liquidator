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
local function checkRecord(r)
    if not object(r) then return nil,"damaged" end
    if r.outputCoverage~="complete" then return nil,"incomplete" end
    if not SUPPORTED[r.method] then return nil,"unsupported" end
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
    return {id=r.operationID,method=r.method,input=input,batch=batch,build=b,outputs=outputs,
        expansionID=expansion,inputRarity=rarity,inputClassID=classID,
        gearKey=r.method=="Disenchant" and disenchantCategory(expansion,rarity,classID) or nil}
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
    local own={}
    for _,r in ipairs(self.db.craftResearch and self.db.craftResearch.records or {}) do own[r.operationID]=true end
    local d=store(self)
    local counts={accepted=0,damaged=0,incomplete=0,unsupported=0,duplicate=0,own=0}
    local clean,inPaste={},{}
    for _,r in ipairs(data.records) do
        local cast,reason=checkRecord(r)
        if cast and (d.seen[cast.id] or inPaste[cast.id]) then cast,reason=nil,"duplicate"
        elseif cast and own[cast.id] then cast,reason=nil,"own" end
        if cast then clean[#clean+1]=cast;inPaste[cast.id]=true else counts[reason]=counts[reason]+1 end
    end
    -- A paste with many impossible values is treated as damaged or fake as a whole.
    local total=#data.records
    if counts.damaged>0 and counts.damaged>=math.max(2,total*.2) then
        return false,("%d of %d results had impossible values, so this text looks damaged or edited. Nothing was imported."):format(counts.damaged,total),counts
    end
    for _,cast in ipairs(clean) do
        local inputKey=cast.gearKey or tostring(cast.input)
        -- Partial category metadata is still useful as a physical scope guard;
        -- separate it from old unscoped per-item sets rather than losing it.
        if cast.method=="Disenchant" and not cast.gearKey
            and (cast.expansionID~=nil or cast.inputRarity~=nil or cast.inputClassID~=nil) then
            inputKey=inputKey..":"..tostring(cast.expansionID)..":"..tostring(cast.inputRarity)..":"..tostring(cast.inputClassID)
        end
        local key=cast.method..":"..inputKey..":"..cast.batch..":"..cast.build
        local set=d.sets[key]
        if not set then
            set={method=cast.method,inputItemID=not cast.gearKey and cast.input or nil,gearKey=cast.gearKey,
                expansionID=cast.expansionID,inputRarity=cast.inputRarity,inputClassID=cast.inputClassID,
                inputCount=cast.batch,build=cast.build,casts=0,materials={},memberInputItemIDs={}}
            d.sets[key]=set
        end
        set.memberInputItemIDs=set.memberInputItemIDs or {}
        set.memberInputItemIDs[cast.input]=true
        set.casts=set.casts+1
        for id,qty in pairs(cast.outputs) do
            local m=set.materials[id] or {drops=0,total=0};set.materials[id]=m
            m.drops=m.drops+1;m.total=m.total+qty
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
function LL:ImportedEvidenceRecords(indexKey)
    local d=self.db and self.db.importedResults
    if type(d)~="table" or type(d.sets)~="table" then return nil end
    local current=build()
    if not self._importedIndex or self._importedIndex.build~=current then
        local index={build=current}
        for key,set in pairs(d.sets) do
            local category=set.method=="Disenchant" and disenchantCategory(set.expansionID,set.inputRarity,set.inputClassID)
            category=category and category==set.gearKey and category or nil
            if SUPPORTED[set.method] and integer(set.casts) and (category or integer(set.inputItemID)) and integer(set.inputCount) then
                local r={recordID="imported:"..key,studyID="imported:"..key,sourceKey="imported",source="Imported results",
                    method=set.method,inputItemID=not category and set.inputItemID or nil,gearKey=category,
                    expansionID=set.expansionID,inputRarity=set.inputRarity,inputClassID=set.inputClassID,
                    isDisenchantCategory=category and true or nil,
                    inputCount=set.inputCount,samples=set.casts,
                    patchBuild=set.build,fixedReference=true,referenceConditions={},provisional=true,
                    -- Results from another game build count for less (stale), never zero.
                    obsolete=set.build~=current or nil,materials={}}
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
                    -- Preserve the existing ordinal selection weight, but do not
                    -- call drop-rate precision confidence in a quantity or bound.
                    local function field(v,probability)
                        return {value=v,confidence=probability and c or nil,
                            evidenceScore=c,confidenceUnscored=not probability or nil,
                            confidenceBasis=probability and 'drop-rate-normal-approximation-5pp' or nil,
                            status="observed",samples=set.casts}
                    end
                    r.materials[#r.materials+1]={id=id,expectedQuantity=field(m.total/set.casts),
                        dropChance=field(m.drops/set.casts,true),minQuantity=field(m.min),maxQuantity=field(m.max)}
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
    return self._importedIndex[indexKey]
end
