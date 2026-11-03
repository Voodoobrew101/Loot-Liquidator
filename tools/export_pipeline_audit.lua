-- Read-only export of source and compiled data for the source-to-tooltip audit.
-- Run from repository root with Lua 5.1; no WoW APIs or market prices are used.
local function json(value)
    local kind=type(value)
    if kind=='nil' then return 'null' end
    if kind=='boolean' then return tostring(value) end
    if kind=='number' then
        assert(value==value and math.abs(value)<math.huge,'Non-finite audit value')
        return string.format('%.17g',value)
    end
    if kind=='string' then
        return '"'..value:gsub('[%z\1-\31\\"]',function(c)
            if c=='"' then return '\\"' end
            if c=='\\' then return '\\\\' end
            return string.format('\\u%04x',c:byte())
        end)..'"'
    end
    assert(kind=='table','Unsupported audit value: '..kind)
    local keys,count,array={},0,true
    for k in pairs(value) do
        count=count+1;keys[#keys+1]=k
        if type(k)~='number' or k<1 or k%1~=0 then array=false end
    end
    array=array and count>0 and count==#value
    local parts={}
    if array then
        for i=1,#value do parts[#parts+1]=json(value[i]) end
        return '['..table.concat(parts,',')..']'
    end
    table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
    for _,k in ipairs(keys) do parts[#parts+1]=json(tostring(k))..':'..json(value[k]) end
    return '{'..table.concat(parts,',')..'}'
end
local sources,runtime={},{}
assert(loadfile('database/sources/ReferenceData.lua'))('LootLiquidator',sources)
assert(loadfile(arg[3] or 'LootLiquidator/ItemDBRuntime.lua'))('LootLiquidator',runtime)
local data={reference=sources.ReferenceData,
    research=assert(loadfile('database/research/itemdb.lua'))(),
    evidence=assert(loadfile('database/evidence-baselines.lua'))(),
    calculators=assert(loadfile('database/reference-calculator-baselines.lua'))(),
    v3=assert(loadfile('database/research-v3-baselines.lua'))(),
    compiled=runtime.ItemDB}
if arg[2]=='--probe' then
    -- Controlled offline source-to-renderer checks, never a live eligibility or
    -- profit census. Quotes are synthetic NET material prices, 100 copper each.
    CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
    GetBuildInfo=function()return '12.1.5','123456','',120105 end
    GetTime=function()return 100 end
    for _,name in ipairs({'ProfessionModels.lua','Database.lua','ConversionEngine.lua','Badges.lua'}) do
        assert(loadfile('LootLiquidator/'..name))('LootLiquidator',runtime)
    end
    runtime.db={source_itemdb_enabled=true,source_legacy_enabled=true,source_reference_enabled=true,
        source_personal_enabled=false,source_imported_enabled=false,
        tooltipDetail=3,showAverageQuantity=true,tooltipOutputSort='value'}
    runtime:MigrateEvidenceSettings();assert(runtime:InitializeItemDB(),runtime.itemDBError)
    runtime.GetOutputPrice=function()return 100 end
    runtime.MarkupColor=function()return ''end
    runtime.Money=function(_,n)return string.format('%.6f copper (synthetic net price)',n)end
    runtime.ProfessionProgression=function()return {}end
    local candidates,probes={},{}
    local function add(r)
        local input=r.inputItemID or r.gearKey
        local batch=r.inputCount or r.inputCountPerOperation
        if not input or not batch then return end
        if not ({Mill=true,Prospect=true,Disenchant=true,Smelt=true})[r.method] then return end
        local key=r.method..':'..tostring(input)..':x'..batch
        if candidates[key] then return end
        candidates[key]={input=input,batch=batch,method=r.method,recipeID=r.recipeID or r.recipeSpellID,
            expansion=r.expansionID,quality=r.inputQualityRank}
    end
    -- Define profiles from immutable source metadata first so admission of a
    -- new compiled fallback cannot change the before/after test conditions.
    for _,dataset in ipairs({data.reference.frozen,data.reference.legacy,data.research,data.compiled}) do
        for _,r in ipairs(dataset.processing or {}) do add(r) end
    end
    local keys={} for key in pairs(candidates) do keys[#keys+1]=key end;table.sort(keys)
    for _,key in ipairs(keys) do
        local r=candidates[key]
        local hint=runtime.ItemDB.inputs[r.input] or {}
        local f={id=tonumber(r.input) or -1,classID=r.method=='Disenchant' and 4 or 7,
            count=r.batch,expansionID=hint.expansion or r.expansion,quality=2,reagentQuality=r.quality}
        if type(r.input)=='string' then
            local exp,quality,kind=r.input:match('^gear:(%d+):(%d+):(%a+)$')
            if exp then f.expansionID=tonumber(exp);f.quality=tonumber(quality);f.classID=kind=='weapon' and 2 or 4 end
        end
        local option={name=r.method,inputCount=r.batch,recipeID=r.recipeID}
        if not option.recipeID then
            if r.method=='Disenchant' then option.recipeID=13262
            elseif r.method=='Mill' then option.recipeID=({[9]=382981,[10]=444181,[11]=1269575})[f.expansionID] or 51005
            elseif r.method=='Prospect' then option.recipeID=({[9]=374627,[10]=434018,[11]=1231127})[f.expansionID] or 31252 end
        end
        local ctx={skill=1000,effectiveSkill=1000,inputQuality=r.quality,character='Offline source audit'}
        local ok,model,reason=pcall(runtime.ComputeEvidenceModel,runtime,f,option,nil,1,ctx,true)
        local probe={key=key,input=r.input,method=r.method,inputCount=r.batch,
            eligibility='Not tested; source audit only',materials={}}
        if not ok then probe.state='runtime_error';probe.reason=tostring(model)
        elseif not model then probe.state='no_model';probe.reason=reason
        else
            local value=runtime:ValueProcessingModel(model,0,true,f)
            probe.state=value~=nil and (model.partial and 'partial_value' or 'value') or 'no_value'
            probe.valueCopperPerInput=value;probe.referenceFallback=model.referenceFallback
            probe.warning=model.warning
            probe.operationUnverified=model.operationUnverified
            for _,m in ipairs(model.materials) do
                probe.materials[#probe.materials+1]={id=m.id,rankIDs=m.rankIDs,expectedQuantity=m.expectedQuantity,
                    chance=m.chance,minQuantity=m.minQuantity,maxQuantity=m.maxQuantity,
                    netExpectedValue=m.netExpectedValue,referenceFallback=m.referenceFallback,
                    conditionalExpectedQuantity=m.conditionalExpectedQuantity,conditionalExpectedValue=m.conditionalExpectedValue,
                    unavailableReason=m.unavailableReason,derivedMean=m.derivedMean,meanBasis=m.meanBasis,
                    inconsistentFields=m.inconsistentFields,boundsSource=m.boundsSource,rankReferences=m.rankReferences}
            end
            option.letter=({Mill='M',Prospect='P',Disenchant='D',Smelt='S'})[r.method]
            option.value=value;option.yieldModel=model;option.available=false
            local tip={lines={}}
            function tip:AddLine(s)self.lines[#self.lines+1]=s end
            function tip:AddDoubleLine(a,b)self.lines[#self.lines+1]=a..' | '..(b or '') end
            runtime:AppendRecommendationTooltip(tip,{action=option.letter,facts=f,count=r.batch,conversionOptions={option}})
            probe.tooltip=table.concat(tip.lines,'\n')
        end
        probes[#probes+1]=probe
    end
    data.probes=probes
    data.probeProfile={gameBuild='123456 (synthetic)',skill=1000,priceCopperPerMaterial=100,
        scope='Known method/input/batch records; no real character eligibility, live market prices or best-action coverage claim'}
end
local file=assert(io.open(assert(arg[1],'Output JSON path required'),'w'))
file:write(json(data),'\n');file:close()
