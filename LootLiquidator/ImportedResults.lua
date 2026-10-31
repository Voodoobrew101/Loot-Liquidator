-- B7: import recorded results that another player exported (Export button).
-- Imported casts are kept as their own evidence source ("imported"), separate
-- from your own recordings, with their own confidence and settings weight.
-- Only counts are stored (casts, how often each material dropped, totals and
-- the smallest/largest amount seen), never the other player's raw records.
local _,LL=...
local SCHEMA="loot-liquidator.cast-log/1"
local MAX_TEXT=500000          -- characters; one export page is far smaller
local MAX_RECORDS=1000         -- per pasted page (exports hold 25 per page)
local MAX_INPUTS_PER_CAST=20   -- mass milling uses 20; disenchanting uses 1
local MAX_PER_MATERIAL=100     -- no processing cast returns more of one item
local MAX_OUTPUTS=20
local MAX_SEEN=50000           -- remembered cast IDs, to refuse duplicates
local SUPPORTED={Disenchant=true,Mill=true,Prospect=true,Smelt=true}

local function integer(n,lo,hi) return type(n)=="number" and n==n and n%1==0 and n>=(lo or 1) and n<=(hi or 2147483647) end
local function build() return GetBuildInfo and tostring(select(2,GetBuildInfo())) or "unknown" end

-- Small strict JSON reader. Anything malformed fails the whole paste.
local function decode(text)
    local pos,len=1,#text
    local function fail(msg) error(msg.." (character "..pos..")",0) end
    local function ws() pos=text:find("[^ \t\r\n]",pos) or len+1 end
    local escapes={['"']='"',['\\']='\\',['/']='/',b='\b',f='\f',n='\n',r='\r',t='\t'}
    local function str()
        local out={};pos=pos+1
        while true do
            local c=text:sub(pos,pos)
            if c=="" then fail("unfinished text") end
            if c=='"' then pos=pos+1;return table.concat(out) end
            if c=="\\" then
                local e=text:sub(pos+1,pos+1)
                if escapes[e] then out[#out+1]=escapes[e];pos=pos+2
                elseif e=="u" and text:sub(pos+2,pos+5):match("^%x%x%x%x$") then
                    local n=tonumber(text:sub(pos+2,pos+5),16);out[#out+1]=n<128 and string.char(n) or "?";pos=pos+6
                else fail("bad escape") end
            else
                local _,e=text:find('^[^"\\]+',pos);out[#out+1]=text:sub(pos,e);pos=e+1
            end
        end
    end
    local value
    function value(depth)
        if depth>24 then fail("nested too deeply") end
        ws();local c=text:sub(pos,pos)
        if c=="{" then
            local t={};pos=pos+1;ws()
            if text:sub(pos,pos)=="}" then pos=pos+1;return t end
            while true do
                ws();if text:sub(pos,pos)~='"' then fail("expected a name") end
                local k=str();ws()
                if text:sub(pos,pos)~=":" then fail("expected ':'") end
                pos=pos+1;t[k]=value(depth+1);ws()
                local d=text:sub(pos,pos);pos=pos+1
                if d=="}" then return t elseif d~="," then fail("expected ',' or '}'") end
            end
        elseif c=="[" then
            local t,i={},0;pos=pos+1;ws()
            if text:sub(pos,pos)=="]" then pos=pos+1;return t end
            while true do
                i=i+1;t[i]=value(depth+1);ws()
                local d=text:sub(pos,pos);pos=pos+1
                if d=="]" then return t elseif d~="," then fail("expected ',' or ']'") end
            end
        elseif c=='"' then return str()
        elseif text:sub(pos,pos+3)=="true" then pos=pos+4;return true
        elseif text:sub(pos,pos+4)=="false" then pos=pos+5;return false
        elseif text:sub(pos,pos+3)=="null" then pos=pos+4;return nil
        end
        local s,e=text:find("^-?%d+%.?%d*[eE]?[-+]?%d*",pos)
        local n=s and tonumber(text:sub(s,e))
        if not n or n~=n or n==math.huge or n==-math.huge then fail("unexpected character") end
        pos=e+1;return n
    end
    local ok,result=pcall(function()
        local v=value(0);ws()
        if pos<=len then fail("extra text after the data") end
        return v
    end)
    if ok then return result end
    return nil,result
end
LL.DecodeImportJSON=decode

-- Returns a clean cast {method,input,batch,build,outputs={[id]=qty}} or nil, why.
local function checkRecord(r)
    if type(r)~="table" then return nil,"damaged" end
    if r.outputCoverage~="complete" then return nil,"incomplete" end
    if not SUPPORTED[r.method] then return nil,"unsupported" end
    if r.successful~=true or type(r.operationID)~="string" or r.operationID=="" or #r.operationID>160 then return nil,"damaged" end
    local inputs=type(r.nominalInputs)=="table" and r.nominalInputs or r.inputs
    if type(inputs)~="table" or #inputs~=1 or type(inputs[1])~="table" then return nil,"unsupported" end
    local input,batch=inputs[1].itemID,inputs[1].quantity
    if not integer(input) or not integer(batch,1,MAX_INPUTS_PER_CAST) then return nil,"damaged" end
    if r.method=="Disenchant" and batch~=1 then return nil,"damaged" end
    if type(r.outputs)~="table" or #r.outputs>MAX_OUTPUTS then return nil,"damaged" end
    if #r.outputs==0 and r.zeroEvidence~="operator-confirmed-empty" then return nil,"damaged" end
    local outputs={}
    for _,m in ipairs(r.outputs) do
        if type(m)~="table" or not integer(m.itemID) or not integer(m.quantity,1,MAX_PER_MATERIAL)
            or m.itemID==input or outputs[m.itemID] then return nil,"damaged" end
        outputs[m.itemID]=m.quantity
    end
    local b=r.build
    if type(b)=="number" then b=tostring(b) end
    if type(b)~="string" or not (b:match("^%d+$") or b=="unknown") then return nil,"damaged" end
    return {id=r.operationID,method=r.method,input=input,batch=batch,build=b,outputs=outputs}
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
    local data,why=decode(text)
    if type(data)~="table" then return false,"That text could not be read (it looks damaged or incomplete). Nothing was imported.",{error=why} end
    if data.schemaVersion~=SCHEMA or data.sampleKind~="RAW_CAST_LOG" or type(data.records)~="table" then
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
        local key=cast.method..":"..cast.input..":"..cast.batch..":"..cast.build
        local set=d.sets[key]
        if not set then
            set={method=cast.method,inputItemID=cast.input,inputCount=cast.batch,build=cast.build,casts=0,materials={}}
            d.sets[key]=set
        end
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
            if SUPPORTED[set.method] and integer(set.casts) and integer(set.inputItemID) and integer(set.inputCount) then
                local r={recordID="imported:"..key,studyID="imported:"..key,sourceKey="imported",source="Imported results",
                    method=set.method,inputItemID=set.inputItemID,inputCount=set.inputCount,samples=set.casts,
                    patchBuild=set.build,fixedReference=true,referenceConditions={},provisional=true,
                    -- Results from another game build count for less (stale), never zero.
                    obsolete=set.build~=current or nil,materials={}}
                local ids={} for id in pairs(set.materials) do ids[#ids+1]=id end
                table.sort(ids)
                for _,id in ipairs(ids) do
                    local m=set.materials[id]
                    local c=chanceConfidence(m.drops,set.casts)
                    local function field(v) return {value=v,confidence=c,status="observed",samples=set.casts} end
                    r.materials[#r.materials+1]={id=id,expectedQuantity=field(m.total/set.casts),
                        dropChance=field(m.drops/set.casts),minQuantity=field(m.min),maxQuantity=field(m.max)}
                end
                if #r.materials>0 then
                    local k=set.method..":"..set.inputItemID
                    index[k]=index[k] or {};table.insert(index[k],r)
                end
            end
        end
        self._importedIndex=index
    end
    return self._importedIndex[indexKey]
end
