-- Deterministic build-time migration. Run from repository root with Lua 5.1.
-- Source snapshots are NOT runtime modules and are never fetched at runtime.
local LL={}
for _,file in ipairs({'ResearchDB.lua','GameData.lua','StatYieldProfiles.lua'}) do
    assert(loadfile('database/sources/'..file))('LootLiquidator',LL)
end
local gd=LL.GameData
local db={schemaVersion=1,version='1.0.0',processing={},mechanicRules={},
    provenance='main 051f582 / v0.9.70; schema-validated provisional migration',
    compat={Conversions=LL.Conversions,DisenchantTables=LL.DisenchantTables,
        ResearchTokenCandidates=LL.ResearchTokenCandidates,ResearchProcessingInputs=LL.ResearchProcessingInputs}}
local methods={Mill='Inscription',Prospect='Jewelcrafting',Disenchant='Enchanting',Smelt='Mining'}
local function clone(t) local n={} for k,v in pairs(t or {}) do n[k]=v end return n end
local function field(value,confidence,status)
    return {value=value,confidence=confidence or 0,status=status or 'unknown'}
end
local function add(method,input,batch,materials,meta,sourceKey,study)
    meta=meta or {}
    local r={recordID=method..':'..input..':'..sourceKey,method=method,profession=methods[method],
        inputItemID=input,inputCount=batch,sourceKey=sourceKey,studyID=study,
        expansionID=meta.expansion or meta.expansionID,inputQualityRank=meta.inputRank,
        recipeID=meta.recipeID,patchBuild=meta.patchBuild,referenceContextID=meta.referenceContextID,
        referenceConditions=meta.referenceConditions or {},samples=meta.samples,
        source=meta.source or meta.evidence or 'v0.9.70 snapshot',provisional=true,
        fieldConfidence=meta.confidenceCap or 35,materials={}}
    for _,m in ipairs(materials or {}) do
        if type(m.id)=='number' and m.id>0 then
            local e=m.expectedQuantity
            local measured=m.probabilityVerified==true
            local bounds=m.boundsVerified==true
            r.materials[#r.materials+1]={id=m.id,quality=m.targetQuality,rarity=m.rarity,
                expectedQuantity=field(e,r.fieldConfidence,e~=nil and 'provisional' or 'unknown'),
                dropChance=field(measured and m.chance or nil,measured and r.fieldConfidence or 0,measured and 'verified' or 'unknown'),
                minQuantity=field(bounds and m.minQuantity or nil,bounds and r.fieldConfidence or 0,bounds and 'verified' or 'unknown'),
                maxQuantity=field(bounds and m.maxQuantity or nil,bounds and r.fieldConfidence or 0,bounds and 'verified' or 'unknown')}
        end
    end
    if #r.materials>0 then db.processing[#db.processing+1]=r end
end
local inputs={}
for method,dict in pairs({Mill=gd.mill,Prospect=gd.prospect}) do
    for input,row in pairs(dict) do
        local metadata=LL.ResearchProcessingInputs[input]
        inputs[input]={method=method,batch=row.batch or (metadata and metadata.batch) or 5,
            expansion=metadata and metadata.expansion,evidence=row.evidence}
        local meta=clone(row);meta.expansion=metadata and metadata.expansion
        -- Remove duplicated historical TSM copies from the primary source.
        if not (method=='Prospect' and gd.midnightProspectingProfiles[input])
            and not tostring(row.source):lower():find('tsm',1,true)
            and not tostring(row.source):lower():find('tradeskillmaster',1,true)
            and not tostring(row.evidence):lower():find('tsm',1,true) then
            add(method,input,inputs[input].batch,row.materials,meta,'itemdb','compiled:'..method..':'..input)
        end
    end
end
for _,id in ipairs({210808,210809,210810,36721,87821}) do inputs[id]=nil end
for input,p in pairs(gd.midnightProspectingProfiles or {}) do
    local mats={}
    for _,m in ipairs(p.materials) do
        -- A missing diamond unlock formula is not proof of zero output.
        mats[#mats+1]={id=m.id,expectedQuantity=m.category~='diamond' and m.low or nil}
    end
    local meta=clone(p);meta.expansion=11
    add('Prospect',input,5,mats,meta,'itemdb','midnight-low:'..input)
end
for method,profiles in pairs(gd.statYieldProfiles or {}) do
    for input,p in pairs(profiles) do
        local mats={}
        for _,m in ipairs(p.rows) do mats[#mats+1]={id=m.id,expectedQuantity=m.low} end
        -- Historical/scenario rows remain opt-in legacy evidence.
        local historical=(tostring(p.source)..' '..tostring(p.evidence)):lower():find('tsm',1,true)
        add(method,input,p.batch,mats,p,'legacy',(historical and 'tsm:' or 'profile:')..method..':'..input)
    end
end
for method,dict in pairs({Mill=gd.tsmRetail.mill,Prospect=gd.tsmRetail.prospect}) do
    for input,mats in pairs(dict) do
        if inputs[input] then
            local rows={}
            for _,m in ipairs(mats) do
                -- Unknown reagent/output rank is never summed across rank variants.
                if (not m.sourceQuality or m.sourceQuality==1) and (not m.targetQuality or m.targetQuality==1) then
                    rows[#rows+1]={id=m.id,expectedQuantity=m.amountOfMats and m.amountOfMats*inputs[input].batch,
                        targetQuality=m.targetQuality}
                end
            end
            add(method,input,inputs[input].batch,rows,{source='TradeSkillMaster historical conversion data',
                expansion=inputs[input].expansion,confidenceCap=40,inputRank=mats[1] and mats[1].sourceQuality},
                'tsm','tsm:'..method..':'..input)
        end
    end
end
for exp,tiers in pairs(gd.disenchant) do
    for quality,kinds in pairs(tiers) do
        for kind,row in pairs(kinds) do
            if type(row)=='table' and row.outputs then
                local key='gear:'..exp..':'..quality..':'..kind
                local before=#db.processing
                add('Disenchant',key,1,row.outputs,{expansion=exp,samples=row.samples,
                    source=row.evidence,confidenceCap=45},'itemdb',key)
                if #db.processing>before then
                    local r=db.processing[#db.processing];r.inputItemID=nil;r.gearKey=key
                end
            end
        end
    end
end
-- Deterministic recipes are primary records too; no runtime copy of yields.
for input,list in pairs(LL.Conversions or {}) do
    for _,recipe in ipairs(list) do
        if recipe.method=='Smelt' and recipe.outputID and recipe.outputCount and recipe.inputCount then
            local id=recipe.recipeID or recipe.requiredSpell
            if id then
                local before=#db.processing
                add('Smelt',input,recipe.inputCount,{{id=recipe.outputID,expectedQuantity=recipe.outputCount,
                    chance=1,minQuantity=recipe.outputCount,maxQuantity=recipe.outputCount,probabilityVerified=true,boundsVerified=true}},
                    {source=recipe.source or recipe.requirement or 'Documented recipe',recipeID=id,confidenceCap=100},
                    'itemdb','recipe:'..id)
                if #db.processing>before then
                    local r=db.processing[#db.processing]
                    r.recordID=r.recordID..':'..id;r.provisional=false
                    for _,m in ipairs(r.materials) do for _,field in pairs(m) do
                        if type(field)=='table' and field.status then field.status='verified' end
                    end end
                end
            end
        end
    end
end
-- Reviewed additions use the same versioned interface, independent of engine code.
local additions=assert(loadfile('database/records.lua'))()
for _,r in ipairs(additions.processing or {}) do db.processing[#db.processing+1]=r end
for _,r in ipairs(additions.mechanicRules or {}) do
    assert(r.evidenceStatus=='VERIFIED_NUMERIC' and r.applyPolicy=='EXECUTE' and r.numericTransformValidated==true
        and type(r.sourceClaimIDs)=='table' and #r.sourceClaimIDs>0 and r.independentReview=='APPROVED',
        'Mechanics require numerical validation and independent approval')
    db.mechanicRules[#db.mechanicRules+1]=r
end
table.sort(db.processing,function(a,b) return a.recordID<b.recordID end)
-- Fixed conversions remain one copy; the valuation engine adapts these to a model.
db.inputs=inputs
db.compat.GameData={tokens=gd.tokens,recipeRequirements=gd.recipeRequirements}
local function finite(n) return type(n)=='number' and n==n and n<math.huge and n>=0 end
local seen={}
for _,r in ipairs(db.processing) do
    for _,m in ipairs(r.materials) do for name,f in pairs(m) do
        if type(f)=='table' and f.status then f.sourceClaimIDs=f.sourceClaimIDs or {r.studyID..':'..m.id..':'..name} end
    end end
    assert(not seen[r.recordID],'duplicate record '..r.recordID);seen[r.recordID]=true
    assert(r.studyID and r.source and finite(r.inputCount) and r.inputCount>0)
    local ids={}
    for _,m in ipairs(r.materials) do
        assert(not ids[m.id],'duplicate output '..r.recordID);ids[m.id]=true
        for _,key in ipairs({'expectedQuantity','dropChance','minQuantity','maxQuantity'}) do
            local v=m[key].value
            assert(v==nil or finite(v),'invalid field '..r.recordID..':'..key)
        end
        local p,e=m.dropChance.value,m.expectedQuantity.value
        assert(p==nil or p<=1)
        assert(not (e==0 and p and p>0),'zero/chance contradiction')
    end
end
local function encode(v)
    if type(v)=='number' then return string.format('%.17g',v) end
    if type(v)=='string' then return string.format('%q',v) end
    if type(v)=='boolean' then return tostring(v) end
    assert(type(v)=='table','unsupported compiled value')
    local keys={} for k in pairs(v) do keys[#keys+1]=k end
    table.sort(keys,function(a,b) if type(a)==type(b) then return a<b end return type(a)<type(b) end)
    local out={'{'}
    for _,k in ipairs(keys) do out[#out+1]='['..encode(k)..']='..encode(v[k])..',' end
    out[#out+1]='}';return table.concat(out)
end
LL.ItemDB=db
assert(loadfile('LootLiquidator/Database.lua'))('LootLiquidator',LL)
assert(not LL.itemDBError,LL.itemDBError)
local output=arg[1] or 'LootLiquidator/ItemDBRuntime.lua'
local file=assert(io.open(output,'w'))
file:write('-- Generated by tools/compile_itemdb.lua. Unknown fields are absent, not zero.\nlocal _, LL = ...\nLL.ItemDB=',(encode(db):gsub('},%[','},\n[')),'\n')
file:close()
print('Compiled '..#db.processing..' source records (provisional and documented recipes) to '..output)
