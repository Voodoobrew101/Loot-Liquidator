-- Storage layout must preserve real profession models, prices and tooltips.
local function copy(v)if type(v)~='table'then return v end local r={}for k,x in pairs(v)do r[k]=copy(x)end return r end
local checks=0
local function same(a,b,path)
    assert(type(a)==type(b),path..': type changed')
    if type(a)~='table'then assert(a==b,path..': value changed');checks=checks+1;return end
    for k,v in pairs(a)do same(v,b[k],path..'.'..tostring(k))end
    for k in pairs(b)do assert(a[k]~=nil,path..': key added '..tostring(k))end
end
local function keyed(v)
    if type(v)=='number'then return string.format('%.17g',v)end
    if type(v)=='string'then return string.format('%q',v)end
    if type(v)=='boolean'then return tostring(v)end
    local keys={}for k in pairs(v)do keys[#keys+1]=k end
    table.sort(keys,function(a,b)if type(a)==type(b)then return a<b end return type(a)<type(b)end)
    local s={'{'}for _,k in ipairs(keys)do s[#s+1]='['..keyed(k)..']='..keyed(v[k])..','end
    s[#s+1]='}';return table.concat(s)
end
GetBuildInfo=function()return'12.1.5','70961'end
GetTime=function()return 100 end;time=function()return 100 end
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
GetItemInfo=function(id)return'Item '..id end
GetItemCount=function()return 100000 end
local current={};assert(loadfile('LootLiquidator/ItemDBRuntime.lua'))('LL',current)
local previous={}
if arg and arg[1]then assert(loadfile(arg[1]))('LL',previous)
else previous.ItemDB=assert(loadstring('return '..keyed(current.ItemDB)))()end
local function setup(data)
    local LL={ItemDB=data,db={characters={Player={professions={}}},rateProfile=3,rateProfileCharacter='Player',
        source_itemdb_enabled=true,source_legacy_enabled=true,source_reference_enabled=true,
        source_personal_enabled=false,source_imported_enabled=false,professionTooltipProfiles={},
        tooltipDetail=3,showAverageQuantity=true,showProfessionDetails=true}}
    for _,file in ipairs({'ProfessionCatalog.lua','Professions.lua','ProfessionModels.lua','ProfessionCalculations.lua',
        'Database.lua','ConversionEngine.lua','Observations.lua','Badges.lua'})do assert(loadfile('LootLiquidator/'..file))('LL',LL)end
    LL.CharacterKey=function()return'Player'end
    LL.GetResearchProfessionSnapshot=function()return 0,'none'end
    LL.GetCachedOperationInfo=function()end
    LL.GetOutputPrice=function(_,id)return 100+id%41 end
    LL.CanUseConversion=function()return false,'Informational test recipe','Player'end
    LL.EligibleDisenchant=function()return false end
    LL.MarkupColor=function()return''end
    LL.Money=function(_,v)return string.format('%.10g copper',v)end
    LL.ProfessionProgression=function()return{}end
    LL.Invalidate=function(self)self._processingContextCache=nil;self._processingModelCache=nil end
    LL:MigrateEvidenceSettings();assert(LL:InitializeItemDB(),LL.itemDBError)
    for profession in pairs(data.professionProfiles.professionParameters)do
        LL.db.characters.Player.professions[profession]=true
        LL.db.professionTooltipProfiles[profession]='@hypothetical'
    end
    return LL
end
local function profile(LL,profession,expansion,full)
    local p=LL.ItemDB.professionProfiles.profiles[profession..':'..expansion]
    local points={}
    if full then for id,node in pairs(p and p.nodes or{})do points[#points+1]=id..'='..node.maxRank end end
    table.sort(points)
    local effects={}
    if full then for _,e in ipairs(LL:GetProfessionConditionalEffects(profession,expansion))do effects[tostring(e.entryID)]={active=true,stacks=e.maxStacks}end end
    assert(LL:SetManualProfessionProfile('Player',profession,expansion,{enabled=true,skill=full and 140 or 0,
        specialization=#points>0 and table.concat(points,',')or'none',effectStates=effects,
        stats=full and{multicraft={percent=25},resourcefulness={percent=25},finesse={percent=25},perception={percent=25},deftness={percent=25}}or{},buffs={}}))
end
local function tooltip(LL,f,options)
    local t={lines={}}
    function t:AddLine(s)self.lines[#self.lines+1]=s end
    function t:AddDoubleLine(a,b)self.lines[#self.lines+1]=a..' | '..b end
    LL:AppendRecommendationTooltip(t,{action=options[1]and options[1].letter or'Q',facts=f,conversionOptions=options})
    return table.concat(t.lines,'\n')
end
local function receipts(LL)
    local out={}
    for _,full in ipairs({false,true})do
        profile(LL,'Enchanting',11,full)
        for _,rarity in ipairs({2,3,4})do for _,classID in ipairs({2,4})do
            local f={id=999900+rarity*10+classID,expansionID=11,classID=classID,quality=rarity,count=1}
            local op={name='Disenchant',profession='Enchanting',recipeID=13262,inputCount=1}
            local model,reason=LL:ResolveEvidenceModel(f,op,nil,1)
            if model then LL:ValueProcessingModel(model,0,true,f)end
            out[#out+1]={model=model,reason=reason,tooltip=tooltip(LL,f,{{name='Disenchant',letter='D',profession='Enchanting',recipeID=13262,
                inputCount=1,available=false,value=model and(model.value or model.partialValue),yieldModel=model}})}
        end end
        profile(LL,'Enchanting',10,full)
        for rank=2,3 do
            local f={id=219948+rank,reagentQuality=rank,expansionID=10,classID=7,quality=3,count=20}
            local options=LL:ConversionOptions(f)
            out[#out+1]={options=options,tooltip=tooltip(LL,f,options)}
        end
    end
    for _,r in ipairs({{'Alchemy',1230867},{'Blacksmithing',1229598},{'Enchanting',1236098},{'Engineering',1229755},
        {'Inscription',1230016},{'Jewelcrafting',1230437},{'Leatherworking',1237486},{'Tailoring',1227926},{'Cooking',1226166}})do
        local profession,spell=r[1],r[2];profile(LL,profession,11,true)
        local native=LL.ItemDB.professionProfiles.recipes[spell]
        local f={id=990000+#out,expansionID=11,classID=7,quality=2,count=100}
        LL.db.recipeCandidates={[f.id]={[spell]={method='Craft',profession=profession,recipeID=spell,inputCount=1,
            outputID=native.outputIDs[1],outputCount=native.outputCount or 1,confidence='verified'}}}
        local options=LL:ConversionOptions(f)
        out[#out+1]={options=options,tooltip=tooltip(LL,f,options)}
    end
    LL.db.recipeCandidates=nil
    for _,profession in ipairs({'Herbalism','Mining','Skinning','Fishing'})do for expansion=9,11 do
        profile(LL,profession,expansion,true)
        for _,target in ipairs(LL:GetGatheringSimulationTargets(profession,expansion))do
            local model=LL:GatheringSimulationPreview(profession,expansion,target.targetID,'Player',true)
            out[#out+1]={target=target.targetID,model=model}
        end
    end end
    local keys={}for k in pairs(LL.ItemDB.professionProfiles.profiles)do keys[#keys+1]=k end;table.sort(keys)
    for _,key in ipairs(keys)do
        local p=LL.ItemDB.professionProfiles.profiles[key];profile(LL,p.profession,p.expansionID,true)
        for _,target in ipairs(LL:GetProfessionOpportunityTargets(p.profession,p.expansionID))do
            local model=LL:ProfessionOpportunityPreview(p.profession,p.expansionID,target.targetID,'Player',true)
            out[#out+1]={target=target.targetID,model=model}
        end
    end
    -- Exercise every distinct exact-input source operation as well as the
    -- native profession scenarios above. Unknown models/reasons are preserved
    -- just as strictly as valued results; no missing field becomes a zero.
    local seen={}
    for _,record in ipairs(LL.ItemDB.processing)do if record.inputItemID then
        local hint=LL.ItemDB.inputs[record.inputItemID]or{}
        local expansion=record.expansionID or hint.expansion or 0
        local key=table.concat({record.method,record.inputItemID,tostring(record.recipeID),record.inputCount,
            expansion,tostring(record.inputQualityRank),tostring(record.inputRarity),tostring(record.inputClassID)},':')
        if not seen[key]then
            seen[key]=true
            local profession=record.profession or LL:ProfessionForMethod(record.method)
            if profession then profile(LL,profession,expansion,true)end
            local f={id=record.inputItemID,expansionID=expansion,reagentQuality=record.inputQualityRank,
                quality=record.inputRarity or 2,classID=record.inputClassID or 7,count=record.inputCount}
            local op={name=record.method,profession=profession,recipeID=record.recipeID,inputCount=record.inputCount}
            local model,reason=LL:ResolveEvidenceModel(f,op,nil,1)
            if model then LL:ValueProcessingModel(model,0,true,f)end
            local letter=({Disenchant='D',Mill='M',Prospect='P',Smelt='S',Recycle='R'})[record.method]or'C'
            out[#out+1]={sourceOperation=key,model=model,reason=reason,tooltip=tooltip(LL,f,{{name=record.method,letter=letter,
                profession=profession,recipeID=record.recipeID,inputCount=record.inputCount,available=false,
                value=model and(model.value or model.partialValue),yieldModel=model}})}
        end
    end end
    return out
end
local old=receipts(setup(previous.ItemDB))
local native=receipts(setup(current.ItemDB))
same(old,native,'source-to-tooltip')
print(('PASS: ItemDB storage parity across %d real source/profile/target receipts and %d scalar fields (including rendered tooltips)'):format(#native,checks))
