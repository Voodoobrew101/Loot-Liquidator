-- Reviewed source facts are informational. They never join the yield/price or
-- eligibility model: conditional amounts, unit shares and website counters have
-- different denominators from unconditional expected material quantities.
local _,LL=...
local function finite(n) return type(n)=='number' and n==n and n>=0 and n<math.huge end
local function integer(n) return finite(n) and n%1==0 end
local function clone(value)
    if type(value)~='table' then return value end
    local out={} for key,child in pairs(value) do out[key]=clone(child) end
    return out
end
local metrics={conditionalMeanUnitsPerPositiveEvent=true,sourceOccurrenceFraction=true,
    conditionalStackRange=true,rankUnitShare=true,referenceMeanUnitsPerInput=true,
    referenceMeanUnitsPerOperation=true,sourceProfileMeanUnitsPerInput=true,
    sourceProfileMeanUnitsPerOperation=true,
    sourceProfileMeanUnitsPerInputRange=true,sourceProfileMeanUnitsPerOperationRange=true,
    sourceProfileMeanUnitsPerInputLowerBound=true,sourceProfileMeanUnitsPerOperationLowerBound=true,
    sourceReportedChanceRange=true,sourceReportedChanceLowerBound=true,
    sourceKnowledgePointsPerOperation=true,reportedPositiveOutcome=true,conditionalStackLowerBound=true,
    sourceReportedMaterialUnits=true,sourceRefundFractionOfReportedInputBudget=true,
    sourceModeledReturnFractionPerResourcefulnessEvent=true,
    sourceReturnFractionPerAcceptedResourcefulnessEvent=true,
    sourceNominalEventsPerInput=true,sourceNominalEventsPerOperation=true}
local professions={Disenchant='Enchanting',Mill='Inscription',Prospect='Jewelcrafting',Smelt='Mining'}
local dimensionUnits={
    sourceRefundFractionOfReportedInputBudget='returned-input-per-nominal-input',
    sourceModeledReturnFractionPerResourcefulnessEvent='modeled-returned-input-fraction-per-resourcefulness-event',
    sourceReturnFractionPerAcceptedResourcefulnessEvent='returned-input-fraction-per-accepted-resourcefulness-event',
    sourceNominalEventsPerInput='events-per-modeled-input',sourceNominalEventsPerOperation='events-per-modeled-operation'}
local rarity={uncommon=2,rare=3,epic=4,common=1,poor=0,legendary=5}
local function facts(self)
    local data=self.ItemDB and self.ItemDB.reviewedSourceFacts
    return type(data)=='table' and data.schemaVersion==1 and type(data.facts)=='table' and data.facts or {}
end
local function sourceAllowed(self,method,mode)
    if mode==nil and self.ProcessingDataMode then mode=self:ProcessingDataMode(method) end
    if mode==2 then return false end -- personal observations only
    if type(self.EvidenceSourceWeight)=='function' then
        local weight=self:EvidenceSourceWeight('itemdb',mode)
        return finite(weight) and weight>0
    end
    -- Fail closed if the evidence-policy module is not loaded.
    return false
end
local function member(list,value)
    if type(list)~='table' then return false end
    for _,v in ipairs(list) do if v==value then return true end end
    return false
end
local function gearKey(f)
    if not integer(f.expansionID) or not integer(f.quality)
        or (f.classID~=2 and f.classID~=4) then return nil end
    return ('gear:%d:%d:%s'):format(f.expansionID,f.quality,f.classID==2 and 'weapon' or 'armor')
end
local function matches(fact,f,option,context)
    if type(fact)~='table' or not metrics[fact.metric] or fact.method~=option.name
        or (fact.sourceKey~=nil and fact.sourceKey~='itemdb') then return false end
    if dimensionUnits[fact.metric] and fact.unit~=dimensionUnits[fact.metric] then return false end
    local selected=false
    if fact.inputItemID~=nil then
        if fact.inputItemID~=f.id then return false end
        selected=true
    end
    if fact.inputFamilyIDs~=nil then
        if not member(fact.inputFamilyIDs,f.id) then return false end
        selected=true
    end
    if fact.gearKey~=nil then
        if fact.gearKey~=gearKey(f) then return false end
        selected=true
    end
    -- A report may identify rarity without saying armor versus weapon. Such
    -- reports remain source-only facts; this scope never joins the EV model.
    if fact.gearScope~=nil then
        local scope=fact.gearScope
        if option.name~='Disenchant' or type(scope)~='table'
            or not integer(scope.expansionID) or scope.expansionID~=f.expansionID
            or (f.classID~=2 and f.classID~=4)
            or (scope.rarity==nil and scope.classID==nil)
            or (scope.rarity~=nil and scope.rarity~=f.quality)
            or (scope.classID~=nil and scope.classID~=f.classID) then return false end
        selected=true
    end
    if not selected then return false end -- an unspecific report is not every item
    if fact.expansionID~=nil and fact.expansionID~=f.expansionID then return false end
    if fact.inputQualityRank~=nil and fact.inputQualityRank~=f.reagentQuality then return false end
    local quality=type(fact.inputRarity)=='string' and rarity[fact.inputRarity:lower()] or fact.inputRarity
    if fact.inputRarity~=nil and quality~=f.quality then return false end
    if fact.inputClassID~=nil and fact.inputClassID~=f.classID then return false end
    if fact.recipeID~=nil and fact.recipeID~=option.recipeID then return false end
    if fact.outputRank~=nil and (not integer(fact.outputRank) or fact.outputRank<1 or fact.outputRank>5) then return false end
    if fact.outputItemID~=nil then
        if not integer(fact.outputItemID) or fact.outputItemID<=0 then return false end
        -- Unconditional references here are for named/unpriced outcomes only.
        -- Priced source means are handled by the separately reviewed producer.
        if fact.metric=='referenceMeanUnitsPerInput' or fact.metric=='referenceMeanUnitsPerOperation' then return false end
    elseif type(fact.outputName)~='string' or not fact.outputName:match('%S') then return false end
    if fact.metric=='conditionalStackRange' or fact.metric:match('Range$') then
        if not finite(fact.lower) or not finite(fact.upper) or fact.lower>fact.upper then return false end
    elseif fact.metric=='reportedPositiveOutcome' then
        if fact.value~=nil or fact.unit~='qualitative-outcome' then return false end
    elseif not finite(fact.value) then return false end
    if (fact.metric=='sourceOccurrenceFraction' or fact.metric=='rankUnitShare') and fact.value>1 then return false end
    if fact.metric=='sourceReportedChanceRange' and fact.upper>1 then return false end
    if fact.metric=='sourceReportedChanceLowerBound' and fact.value>1 then return false end
    return true
end

function LL:ReviewedProcessingSourceFacts(f,option,context,mode)
    if type(f)~='table' or not integer(f.id) or f.id<=0
        or type(option)~='table' or type(option.name)~='string'
        or not sourceAllowed(self,option.name,mode) then return {} end
    local profession=option.profession or professions[option.name]
    if profession and self.db and self.db.professionTooltipProfiles
        and self.db.professionTooltipProfiles[profession]=='@hide' then return {} end
    local out={}
    for _,fact in ipairs(facts(self)) do
        if matches(fact,f,option,context) then
            local copy=clone(fact)
            -- These fields identify the observation's context. They never claim
            -- that a target character or variant matches or has been adjusted.
            copy.sourceContextOnly=true
            copy.targetProfileAdjusted=false
            copy.confidence0to100=finite(fact.confidence0to100)
                and math.min(100,fact.confidence0to100) or 0
            copy.sourceSupportConfidence=finite(fact.sourceSupportConfidence)
                and math.min(20,fact.sourceSupportConfidence) or 0
            out[#out+1]=copy
        end
    end
    table.sort(out,function(a,b)
        local aa=tostring(a.factID or '')..'\031'..tostring(a.sourceStudyKey or '')..'\031'..tostring(a.metric)..'\031'..tostring(a.outputItemID or a.outputName)
        local bb=tostring(b.factID or '')..'\031'..tostring(b.sourceStudyKey or '')..'\031'..tostring(b.metric)..'\031'..tostring(b.outputItemID or b.outputName)
        return aa<bb
    end)
    return out
end

local function number(n)
    return ('%.3f'):format(n):gsub('0+$',''):gsub('%.$','')
end
local function safe(text)
    -- Source metadata is plain text, never executable tooltip markup.
    return tostring(text or ''):gsub('|','||'):gsub('[\r\n]+',' ')
end
local function outputName(fact)
    local name=fact.outputName
    if fact.outputItemID and type(GetItemInfo)=='function' then
        local ok,value=pcall(GetItemInfo,fact.outputItemID)
        if ok and type(value)=='string' then name=value end
    end
    if not name and fact.outputItemID and C_Item and type(C_Item.GetItemInfo)=='function' then
        local ok,value=pcall(C_Item.GetItemInfo,fact.outputItemID)
        if ok and type(value)=='string' then name=value end
    end
    name=safe(name or ('Material '..tostring(fact.outputItemID)))
    if fact.outputRank then name=name..(' [R%d]'):format(fact.outputRank) end
    return name
end
local function contextText(fact)
    local fields={}
    local profile=fact.sourceProfile
    if type(profile)=='table' then
        for _,key in ipairs({'skill','specialization','stats','patch','dataDate','published'}) do
            if profile[key]~=nil and tostring(profile[key])~='' then
                fields[#fields+1]=key..' '..safe(profile[key])
            end
        end
    elseif profile~=nil then fields[#fields+1]=safe(profile) end
    if fact.nativeInputVariant then fields[#fields+1]='item variant '..safe(fact.nativeInputVariant) end
    if type(fact.referenceConditions)=='table' then
        local keys={} for key in pairs(fact.referenceConditions) do keys[#keys+1]=key end
        table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
        for _,key in ipairs(keys) do fields[#fields+1]=safe(key)..' '..safe(fact.referenceConditions[key]) end
    end
    if type(fact.sourceURL)=='string' then
        local host=fact.sourceURL:match('^https?://([^/]+)')
        if host then fields[#fields+1]=safe(host) end
    end
    return #fields>0 and '    Source context: '..table.concat(fields,'; ') or nil
end

-- Build a bounded presentation from all matching facts. The public query above
-- remains unbounded for research/export callers. No option is added or changed.
function LL:ReviewedProcessingSourceFactLines(f,options,context,limit)
    if type(f)~='table' then return {} end
    local optionByMethod={}
    for _,option in ipairs(options or {}) do
        if option.name and not optionByMethod[option.name] then optionByMethod[option.name]=option end
    end
    for _,fact in ipairs(facts(self)) do
        if type(fact)=='table' and type(fact.method)=='string' and not optionByMethod[fact.method] then
            optionByMethod[fact.method]={name=fact.method,profession=fact.profession}
        end
    end
    local methods={} for method in pairs(optionByMethod) do methods[#methods+1]=method end
    table.sort(methods)
    local list,seen={},{}
    for _,method in ipairs(methods) do
        for _,fact in ipairs(self:ReviewedProcessingSourceFacts(f,optionByMethod[method],context)) do
            local key=fact.factID or (method..':'..tostring(fact.sourceStudyKey)..':'..fact.metric..':'..tostring(fact.outputItemID or fact.outputName)..':'..tostring(fact.value)..':'..tostring(fact.lower)..':'..tostring(fact.upper))
            if not seen[key] then list[#list+1]=fact;seen[key]=true end
        end
    end
    if #list==0 then return {} end
    local lines={'Processing source facts'}
    limit=math.max(1,math.min(8,tonumber(limit) or 4))
    for i=1,math.min(#list,limit) do
        local fact=list[i]
        local value
        if fact.metric=='conditionalMeanUnitsPerPositiveEvent' then value=number(fact.value)..' units per positive result'
        elseif fact.metric=='conditionalStackLowerBound' then value=(fact.exclusive and 'more than ' or 'at least ')..number(fact.value)..' units per positive result'
        elseif fact.metric=='conditionalStackRange' then value=number(fact.lower)..'–'..number(fact.upper)..' units per positive result'
        elseif fact.metric=='rankUnitShare' then value=number(fact.value*100)..'% of source material units'
        elseif fact.metric=='sourceOccurrenceFraction' then value='source occurrences '..number(fact.value*100)..'%'
        elseif fact.metric=='referenceMeanUnitsPerInput' then value=number(fact.value)..' source units per input'
        elseif fact.metric=='referenceMeanUnitsPerOperation' then value=number(fact.value)..' source units per operation'
        elseif fact.metric=='sourceProfileMeanUnitsPerInput' then
            local unit=fact.unit=='net-input' and 'net input' or fact.unit=='gross-input' and 'gross input' or 'input'
            value='source-profile mean '..number(fact.value)..' units per '..unit
        elseif fact.metric=='sourceProfileMeanUnitsPerOperation' then
            value='source-profile mean '..number(fact.value)..' units per operation'
        elseif fact.metric=='sourceProfileMeanUnitsPerInputRange' or fact.metric=='sourceProfileMeanUnitsPerOperationRange' then
            value='source-profile mean '..number(fact.lower)..'–'..number(fact.upper)..' units per '
                ..(fact.metric=='sourceProfileMeanUnitsPerInputRange' and 'input' or 'operation')
        elseif fact.metric=='sourceProfileMeanUnitsPerInputLowerBound' or fact.metric=='sourceProfileMeanUnitsPerOperationLowerBound' then
            value='source-profile mean '..(fact.exclusive and 'more than ' or 'at least ')..number(fact.value)..' units per '
                ..(fact.metric=='sourceProfileMeanUnitsPerInputLowerBound' and 'input' or 'operation')
        elseif fact.metric=='sourceReportedChanceRange' then
            value='source reported occurrences '..number(fact.lower*100)..'–'..number(fact.upper*100)..'%'
        elseif fact.metric=='sourceReportedChanceLowerBound' then
            value='source reported occurrences '..(fact.exclusive and 'more than ' or 'at least ')..number(fact.value*100)..'%'
        elseif fact.metric=='sourceKnowledgePointsPerOperation' then
            value=number(fact.value)..' knowledge points'..(fact.oneTime and ' (one-time)' or '')
        elseif fact.metric=='reportedPositiveOutcome' then
            value='positive outcome reported; operation count unspecified'
        elseif fact.metric=='sourceReportedMaterialUnits' then
            value=number(fact.value)..' source material units; operation count unspecified'
        elseif fact.metric=='sourceRefundFractionOfReportedInputBudget' then
            value=number(fact.value*100)..'% returned units per reported nominal input budget'
        elseif fact.metric=='sourceModeledReturnFractionPerResourcefulnessEvent' then
            value=number(fact.value*100)..'% modeled returned-input fraction per Resourcefulness event'
        elseif fact.metric=='sourceReturnFractionPerAcceptedResourcefulnessEvent' then
            value=number(fact.value*100)..'% returned-input fraction per accepted Resourcefulness event'
        elseif fact.metric=='sourceNominalEventsPerInput' then
            value=number(fact.value)..' source events per modeled input'
        elseif fact.metric=='sourceNominalEventsPerOperation' then
            value=number(fact.value)..' source events per modeled operation'
        end
        lines[#lines+1]=('  %s: %s — %s (Confidence %d%%)'):format(safe(fact.method),outputName(fact),value,math.floor(fact.confidence0to100+.5))
        local sourceContext=contextText(fact)
        if sourceContext then lines[#lines+1]=sourceContext end
    end
    if #list>limit then lines[#lines+1]=('  +%d more source facts'):format(#list-limit) end
    return lines
end
