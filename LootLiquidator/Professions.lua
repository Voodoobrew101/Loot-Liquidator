-- Loot Liquidator profession snapshots and conservative cross-profession conversion discovery.
-- This module NEVER presumes that simply having a profession means a recipe is learned.
local _, LL = ...
local PROF = {Disenchant="Enchanting",Mill="Inscription",Prospect="Jewelcrafting",
    Smelt="Mining",Recycle="Engineering",Tailor="Tailoring",Leatherwork="Leatherworking",Engineering="Engineering"}
local KNOWN_SPELLS = {Mill=51005,Prospect=31252,Disenchant=13262}
local function Now() return time and time() or 0 end
local function SpellKnown(id)
    if not id then return false end
    if IsPlayerSpell and IsPlayerSpell(id) then return true end
    if IsSpellKnown and IsSpellKnown(id) then return true end
    return false
end
local function PositiveInt(n) return type(n)=="number" and n>0 and n<math.huge and n==math.floor(n) end

-- Operation identity/batch only. Eligibility comes from the client's complete
-- salvage list, never from an item name, bag contents or assumed output rates.
local SALVAGE_RECIPES={
    [1229930]={method="Recycle",profession="Engineering",expansionID=11,inputCount=5},
}
function LL:SalvageRecipeDefinition(recipeID) return SALVAGE_RECIPES[recipeID] end
function LL:ReadSalvageInputs(recipeID)
    local api=C_TradeSkillUI and C_TradeSkillUI.GetSalvagableItemIDs
    if not SALVAGE_RECIPES[recipeID] or type(api)~="function" then return nil end
    local ok,ids=pcall(api,recipeID)
    if not ok or type(ids)~="table" or (issecretvalue and issecretvalue(ids)) then return nil end
    local inputs={}
    for _,id in ipairs(ids) do
        if not (issecretvalue and issecretvalue(id)) and PositiveInt(id) then inputs[id]=true end
    end
    return inputs
end
function LL:SalvageConversionOptions(f)
    local out={}
    for recipeID,definition in pairs(SALVAGE_RECIPES) do
        for _,char in pairs(self.db and self.db.characters or {}) do
            local scan=char.salvageRecipes and char.salvageRecipes[recipeID]
            if scan and scan.inputs and scan.inputs[f.id] then
                out[#out+1]={method=definition.method,profession=definition.profession,
                    recipeID=recipeID,requiredSpell=recipeID,inputCount=definition.inputCount,
                    salvage=true,eligibleInput=true,source="In-game Recycling input list",
                    confidence="verified-input",requirement="Output yields need matching recorded results"}
                break
            end
        end
    end
    return out
end

-- Retail 10+ uses ProfessionInfo structures; GetTradeSkillLine was removed.
-- Never use an alt, a linked profession or NPC craft window as a scan of
-- the current character's learned spells.
local function OwnTradeSkillWindow()
    if not C_TradeSkillUI then return false end
    for _,method in ipairs({"IsTradeSkillLinked","IsTradeSkillGuild","IsNPCCrafting"}) do
        if type(C_TradeSkillUI[method])=="function" then
            local ok,yes=pcall(C_TradeSkillUI[method])
            if ok and yes then return false end
        end
    end
    return true
end
local function DisplayedSkillLine()
    if not OwnTradeSkillWindow() then return nil end
    local ui=C_TradeSkillUI
    if type(ui.GetChildProfessionInfo)=="function" then
        local ok,info=pcall(ui.GetChildProfessionInfo)
        if ok and type(info)=="table" and type(info.professionID)=="number" then
            local base
            if type(ui.GetBaseProfessionInfo)=="function" then
                local b,bi=pcall(ui.GetBaseProfessionInfo)
                if b and type(bi)=="table" then base=bi end
            end
            local parentName=info.parentProfessionName or (base and base.professionName)
            local parentID=info.parentProfessionID or (base and base.professionID)
            local name=info.professionName
            if type(name)~="string" or name=="" or name=="Unknown" then
                return nil -- avoid claiming the wrong expansion profession
            end
            return info.professionID,name,info.skillLevel,info.maxSkillLevel,parentID,parentName
        end
    end
    -- Old Retail compatibility, carefully matching the SEVEN values returned
    -- by the API plus pcall's leading success flag.
    if type(ui.GetTradeSkillLine)=="function" then
        local ok,id,name,rank,maxRank,_,parentID,parentName=pcall(ui.GetTradeSkillLine)
        if ok and type(id)=="number" then
            return id,name,rank,maxRank,parentID,parentName
        end
    end
end

function LL:CharacterKey()
    local name=UnitName and UnitName("player")
    local realm=GetRealmName and GetRealmName()
    return name and realm and (name.." - "..realm) or nil
end
function LL:RecordProfessions()
    if not self.db then return end
    local key=self:CharacterKey()
    if not key then return end
    local records=self.db.characters
    local character=records[key] or {}
    local previous=character.professions or {}
    character.name=key
    character.faction=UnitFactionGroup and UnitFactionGroup("player") or nil
    character.level=UnitLevel and UnitLevel("player") or character.level
    if UnitClass then
        local _,class=UnitClass("player")
        character.class=class or character.class
    end
    character.professions={}
    character.details=character.details or {}
    character.recipes=character.recipes or {}
    character.spells=character.spells or {}
    character.reagentUses=character.reagentUses or {}
    character.spells[13262]=SpellKnown(13262)
    character.spells[51005]=SpellKnown(51005)
    character.spells[31252]=SpellKnown(31252)
    for _,id in ipairs({382981,374627,444181,434018,1269575,1231127}) do
        character.spells[id]=SpellKnown(id)
    end
    if GetProfessions and GetProfessionInfo then
        local slots={GetProfessions()}
        for _,slot in pairs(slots) do
            if slot then
                local name,_,skill,maxSkill,_,_,lineID=GetProfessionInfo(slot)
                if name then character.professions[name]={skill=skill,maxSkill=maxSkill,skillLine=lineID} end
            end
        end
        -- Invalidate any previously scanned recipes from a profession now unlearned.
        for id,rec in pairs(character.recipes) do
            if rec.profession and not character.professions[rec.profession] then character.recipes[id]=nil end
        end
    else
        character.professions=previous -- API not available yet; do not wipe the snapshot
    end
    character.observed=Now()
    records[key]=character
end
function LL:RecordDisplayedSkillLine()
    if not self.db or not C_TradeSkillUI then return end
    local key=self:CharacterKey()
    local character=key and self.db.characters[key]
    if not character then return end
    local id,label,rank,maxRank,parentID,parentName=DisplayedSkillLine()
    if not id then return end
    self._activeResearchProfileCache=nil
    character.details[id]={name=label,skill=rank,maxSkill=maxRank,parentID=parentID,
        parentName=parentName,observed=Now()}
    self:RefreshResearchSkillLines()
    if type(parentName)~='string' then return end
    for expansion=0,11 do
        if self:ProfessionDetailMatchesExpansion(character.details[id],expansion) then
            self:GetResearchProfessionSnapshot({expansionID=expansion},parentName)
            self:GetProfessionUIOptions(key,parentName,expansion)
            break
        end
    end
end

-- Research-specific profession snapshots. Unlike GetChildProfessionInfo,
-- GetProfessionInfoBySkillLineID can be queried using a previously verified
-- expansion skill-line ID without requiring an open profession window.
function LL:RefreshResearchSkillLines()
    if not self.db then return end
    local key=self:CharacterKey()
    local char=key and self.db.characters and self.db.characters[key]
    if not char then return end
    local api=C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID
    if type(api)~="function" then return end
    for id,detail in pairs(char.details or {}) do
        local ok,info=pcall(api,tonumber(id) or id)
        if ok and type(info)=="table" and type(info.skillLevel)=="number"
            and info.skillLevel>=0 and type(info.maxSkillLevel)=="number"
            and info.maxSkillLevel>0 then
            detail.skill=info.skillLevel
            detail.maxSkill=info.maxSkillLevel or detail.maxSkill
            detail.skillModifier=type(info.skillModifier)=='number' and info.skillModifier or nil
            detail.observed=Now()
            detail.liveVerified=true
        end
    end
end

local function ReadSpec(skillLine)
    if not skillLine or not C_ProfSpecs or not C_Traits then return nil end
    local api=C_ProfSpecs
    if not (api.GetConfigIDForSkillLine and api.GetSpecTabIDsForSkillLine
        and api.GetRootPathForTab and api.GetChildrenForPath and C_Traits.GetNodeInfo) then return nil end
    local ok,config=pcall(api.GetConfigIDForSkillLine,skillLine)
    if not ok or type(config)~="number" or config<=0 then return nil end
    local tabsOK,tabs=pcall(api.GetSpecTabIDsForSkillLine,skillLine)
    if not tabsOK or type(tabs)~="table" or #tabs==0 then return nil end
    local seen,rankList={},{}
    local failed=false
    local function Visit(path)
        if failed then return end
        if type(path)~="number" then failed=true;return end
        if seen[path] then return end
        seen[path]=true
        local valid,node=pcall(C_Traits.GetNodeInfo,config,path)
        if not valid or type(node)~="table" or type(node.currentRank)~="number" then
            failed=true;return
        end
        if node.currentRank>0 then rankList[#rankList+1]=path.."="..node.currentRank end
        local validChildren,children=pcall(api.GetChildrenForPath,path)
        if not validChildren then failed=true;return end
        -- Blizzard can return nil for a leaf specialization path.
        if children == nil then return end
        if type(children)~="table" then failed=true;return end
        for _,child in ipairs(children) do
            Visit(type(child)=="table" and (child.pathID or child.id) or child)
        end
    end
    for _,tab in ipairs(tabs) do
        local rootOK,root=pcall(api.GetRootPathForTab,tab)
        if rootOK then Visit(root) else failed=true end
    end
    if failed then return nil end
    table.sort(rankList)
    return #rankList>0 and table.concat(rankList,",") or "none"
end

-- Returns (skill, spec, skillLine) for THIS character and expansion.
-- A previously verified spec can be reused when Blizzard temporarily hides
-- trait data. 'Unknown' data is not silently upgraded or merged with verified.
function LL:GetResearchProfessionSnapshot(f,profession)
    local key=self:CharacterKey()
    local char=key and self.db and self.db.characters and self.db.characters[key]
    if not char then return nil,nil,nil end
    local exp=f and f.expansionID
    local cacheKey=key..":"..tostring(profession)..":"..tostring(exp)
    local now=GetTime and GetTime() or 0
    self._activeResearchProfileCache=self._activeResearchProfileCache or {}
    local cachedRead=self._activeResearchProfileCache[cacheKey]
    if cachedRead and now-cachedRead.at<5 then
        return cachedRead.skill,cachedRead.spec,cachedRead.lineID
    end
    local chosenID,detail
    for id,rec in pairs(char.details or {}) do
        local parent=rec.parentName or ""
        if (parent==profession or (parent=="" and char.professions
            and char.professions[profession]))
           and self:ProfessionDetailMatchesExpansion(rec,exp) then
            chosenID,detail=id,rec
            break
        end
    end
    if not chosenID then return nil,nil,nil end
    self:RefreshResearchSkillLines()
    local skill=type(detail.skill)=="number" and detail.skill or nil
    local profileKey=tostring(profession)..":"..tostring(exp)
    char.researchProfiles=char.researchProfiles or {}
    local cached=char.researchProfiles[profileKey]
    local spec=ReadSpec(tonumber(chosenID) or chosenID)
    if spec then
        char.researchProfiles[profileKey]={skill=skill,specialization=spec,
            bonusSkill=detail.skillModifier,equipment=char.professionEquipment,
            lineID=chosenID,observed=Now(),specializationVerified=true}
    else
        -- Historical values remain exportable, but are not a live trait read.
        char.researchProfiles[profileKey]={skill=skill,bonusSkill=detail.skillModifier,
            equipment=char.professionEquipment,lineID=chosenID,observed=Now(),
            specializationVerified=false,previousSnapshot=cached and {
                specialization=cached.specialization,observed=cached.observed} or nil}
    end
    self._activeResearchProfileCache[cacheKey]={at=now,skill=skill,
        spec=spec,lineID=chosenID}
    return skill,spec,chosenID
end

-- A recorder context is always measured for the logged-in character. It never
-- reads Manual profiles and never substitutes an offline or cached trait value.
function LL:CaptureCraftContext(recipeID,f,method,allocation,applyConcentration,allocationItemGUID)
    local function read(fn,...)
        if type(fn)~="function" then return nil end
        local ok,value=pcall(fn,...)
        return ok and type(value)=="table" and value or nil
    end
    local ui=C_TradeSkillUI
    local info=OwnTradeSkillWindow() and read(ui and ui.GetProfessionInfoByRecipeID,recipeID)
    if method=='Disenchant' and f and f.expansionID~=nil then
        -- The generic Disenchant spell describes parent Enchanting, not the
        -- input's expansion. Never label parent skill as expansion skill.
        info=nil
        self:RefreshResearchSkillLines()
        local char=self.db and self.db.characters and self.db.characters[self:CharacterKey()]
        local catalog=self.ProfessionCatalog and self.ProfessionCatalog['Enchanting:'..f.expansionID]
        local expectedLine=catalog and catalog.lineID
        for id,detail in pairs(char and char.details or {}) do
            if detail.parentName=='Enchanting' and self:ProfessionDetailMatchesExpansion(detail,f.expansionID) then
                expectedLine=tonumber(id)
                break
            end
        end
        if expectedLine then
            local live=OwnTradeSkillWindow() and read(ui and ui.GetProfessionInfoBySkillLineID,expectedLine)
            if live and live.professionID==expectedLine and type(live.maxSkillLevel)=='number' and live.maxSkillLevel>0 then
                info=live
            else
                -- Known line identity / spec are useful even when live skill is
                -- unavailable. Cached skill and API 0/0 placeholders stay unknown.
                info={professionID=expectedLine,parentProfessionID=333,parentProfessionName='Enchanting',
                    expansionName=self:ProfessionExpansionName(f.expansionID)}
            end
        end
    end
    local line=info and info.professionID
    local spec=line and ReadSpec(line)
    local context={character=self:CharacterKey(),recipeID=recipeID,method=method,
        profession=info and (info.parentProfessionName or info.professionName) or self:ProfessionForMethod(method),
        skillLineID=line,parentProfessionID=info and info.parentProfessionID,expansionName=info and info.expansionName,
        baseSkill=info and info.skillLevel,maxSkill=info and info.maxSkillLevel,bonusSkill=info and info.skillModifier,
        specialization=spec,equipment={},fieldStatus={},observed=Now(),profileKind="measured",
        inputExpansionID=f and f.expansionID,allocationKnown=type(allocation)=="table"}
    if type(context.baseSkill)=="number" and type(context.bonusSkill)=="number" then
        context.effectiveSkill=context.baseSkill+context.bonusSkill
    end
    local slots=read(ui and ui.GetProfessionInventorySlots)
    if slots and GetInventoryItemLink then
        for _,slot in ipairs(slots) do
            local ok,link=pcall(GetInventoryItemLink,"player",slot)
            if ok and type(link)=="string" then context.equipment[tostring(slot)]=link end
        end
        context.fieldStatus.equipment="measured"
    else context.fieldStatus.equipment="unknown" end
    if OwnTradeSkillWindow() and allocation and type(applyConcentration)=="boolean" then
        local operation=read(ui and ui.GetCraftingOperationInfo,recipeID,allocation,allocationItemGUID,applyConcentration)
        if operation then
            context.operationStats=operation.bonusStats
            context.operationBaseSkill=operation.baseSkill;context.operationBonusSkill=operation.bonusSkill
            context.craftingQuality=operation.craftingQuality
            -- Preserve directly measured quality context in exported research.
            -- This is not a quantity/probability formula for random cooutputs.
            for _,name in ipairs({'baseDifficulty','bonusDifficulty','lowerSkillThreshold','upperSkillTreshold'}) do
                local value=operation[name]
                if type(value)=='number' and value==value and value>=0 and value<math.huge
                    and not (issecretvalue and issecretvalue(value)) then context[name]=value end
            end
            if f and allocationItemGUID and applyConcentration==false and self.FindSkillQualityTarget then
                local guid=self:FindSkillQualityTarget(f,allocationItemGUID)
                if guid==allocationItemGUID then
                    context.operationInputItemID=f.id;context.operationInputQualityRank=f.reagentQuality
                    context.allocationVerified=true
                    if self.RememberSkillQualityOperation then self:RememberSkillQualityOperation(f,recipeID,operation) end
                end
            end
            if type(operation.baseSkill)=="number" and type(operation.bonusSkill)=="number" then
                context.effectiveSkill=operation.baseSkill+operation.bonusSkill
                context.skillBasis="recipe-operation"
            end
        end
    end
    for _,name in ipairs({"baseSkill","bonusSkill","effectiveSkill","specialization","skillLineID","operationStats"}) do
        context.fieldStatus[name]=context[name]~=nil and "measured" or "unknown"
    end
    context.applyConcentration=applyConcentration
    context.simulated=false
    return context
end

function LL:ProfessionForMethod(method) return PROF[method] end
-- Blizzard's UI catalog supplies labels and rank bounds, never yield factors.
function LL:ProfessionExpansionName(expansion)
    return _G['EXPANSION_NAME'..tostring(expansion)]
        or (self.DisenchantTables and self.DisenchantTables[expansion] and self.DisenchantTables[expansion].name)
        or ({[0]='Classic','The Burning Crusade','Wrath of the Lich King','Cataclysm',
            'Mists of Pandaria','Warlords of Draenor','Legion','Battle for Azeroth',
            'Shadowlands','Dragonflight','The War Within','Midnight'})[expansion]
        or 'Unknown expansion'
end
function LL:ProfessionDetailMatchesExpansion(detail,expansion)
    if type(detail)~='table' or type(detail.name)~='string' then return false end
    local alias=({[9]='Dragon Isles',[10]='Khaz Algar'})[expansion]
    return detail.name:find(self:ProfessionExpansionName(expansion),1,true)~=nil
        or (alias and detail.name:find(alias,1,true)~=nil)
        or (expansion==0 and detail.name==detail.parentName)
end
-- The bundled public catalog is independent of learned professions/config IDs.
-- Client metadata can localize/enrich it without scanning a character.
function LL:GetBundledProfessionUIOptions(profession,expansion)
    local catalog=self.ProfessionCatalog and self.ProfessionCatalog[profession..':'..expansion]
    if not catalog then return nil end
    local function read(fn,...)
        if type(fn)~='function' then return nil end
        local ok,value=pcall(fn,...);if ok then return value end
    end
    local api=C_ProfSpecs
    local options={nodes={},buffs={},lineID=catalog.lineID,source='Wago',build=self.ProfessionCatalogBuild}
    for _,source in ipairs(catalog.nodes) do
        local n={} for k,v in pairs(source) do n[k]=v end
        n.rank=0;n.milestones={}
        n.requirementText='Unlock requirements are unverified for this simulated allocation.'
        local definition=read(C_Traits and C_Traits.GetDefinitionInfo,n.definitionID)
        local name=definition and definition.overrideName
        if (not name or name=='') and definition and definition.spellID then
            name=read(C_Spell and C_Spell.GetSpellName,definition.spellID)
        end
        if type(name)=='string' and name~='' then n.name=name end
        local description=read(api and api.GetDescriptionForPath,n.id)
        if type(description)=='string' and description~='' then n.description=description end
        for _,perk in ipairs(read(api and api.GetPerksForPath,n.id) or {}) do
            local id=type(perk)=='table' and perk.perkID or perk
            local rank=read(api and api.GetUnlockRankForPerk,id)
            local text=read(api and api.GetDescriptionForPerk,id)
            if type(rank)=='number' and type(text)=='string' and text~='' then
                n.milestones[#n.milestones+1]={rank=rank,description=text,source='Blizzard specialization'}
            end
        end
        table.sort(n.milestones,function(a,b)return a.rank<b.rank end)
        options.nodes[#options.nodes+1]=n
    end
    return options
end
function LL:GetProfessionUIOptions(character,profession,expansion)
    local bundled=self:GetBundledProfessionUIOptions(profession,expansion)
    local char=self.db.characters and self.db.characters[character]
    if not char then return bundled or {nodes={},buffs={}} end
    local key=profession..':'..expansion
    char.professionOptions=char.professionOptions or {}
    local previous=char.professionOptions[key] or {nodes={},buffs={}}
    if #(previous.nodes or {})==0 then
        for _,other in pairs(self.db.characters or {}) do
            local catalog=other.professionOptions and other.professionOptions[key]
            if catalog and #(catalog.nodes or {})>0 then previous=catalog;break end
        end
    end
    if bundled then
        bundled.buffs=previous.buffs or {}
        bundled.operation=previous.operation
        previous=bundled
    end
    if character~=self:CharacterKey() or not OwnTradeSkillWindow() then return previous end
    local line
    local snapshot=char.researchProfiles and char.researchProfiles[key]
    if snapshot then line=snapshot.lineID end
    for id,detail in pairs(char.details or {}) do
        if detail.parentName==profession and self:ProfessionDetailMatchesExpansion(detail,expansion) then
            line=tonumber(id) or id;break
        end
    end
    if not line then return previous end
    local function read(fn,...)
        if type(fn)~='function' then return nil end
        local ok,value=pcall(fn,...);if ok then return value end
    end
    local form=ProfessionsFrame and ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.SchematicForm
    local selectedRecipe=form and read(form.GetRecipeInfo,form)
    if selectedRecipe and selectedRecipe.recipeID and self.GetCachedOperationInfo then
        self:GetCachedOperationInfo(selectedRecipe.recipeID)
    end
    local api,traits=C_ProfSpecs,C_Traits
    local config=read(api and api.GetConfigIDForSkillLine,line)
    local tabs=read(api and api.GetSpecTabIDsForSkillLine,line)
    local options={nodes={},buffs=previous.buffs or {},lineID=line,observed=Now(),
        operation=char.professionOperationProfiles and char.professionOperationProfiles[tostring(line)]}
    local seen={}
    local function Visit(path,tab,parentID,depth)
        if type(path)~='number' or seen[path] then return end
        seen[path]=true
        local node=read(traits and traits.GetNodeInfo,config,path)
        local entryID=read(api and api.GetSpendEntryForPath,path)
        local entry=entryID and read(traits and traits.GetEntryInfo,config,entryID)
        local unlockID=read(api and api.GetUnlockEntryForPath,path)
        local unlock=unlockID and read(traits and traits.GetEntryInfo,config,unlockID)
        local unlockRanks=unlock and unlock.maxRanks or 0
        local milestones={}
        for _,perk in ipairs(read(api and api.GetPerksForPath,path) or {}) do
            local perkID=type(perk)=='table' and perk.perkID or perk
            local at=read(api and api.GetUnlockRankForPerk,perkID)
            local text=read(api and api.GetDescriptionForPerk,perkID)
            if type(at)=='number' and type(text)=='string' and text~='' then
                milestones[#milestones+1]={rank=at,description=text,source='Blizzard specialization'}
            end
        end
        table.sort(milestones,function(a,b)return a.rank<b.rank end)
        local definition=entry and read(traits and traits.GetDefinitionInfo,entry.definitionID)
        local name=definition and definition.overrideName
        if (not name or name=='') and definition and definition.spellID then
            name=read(C_Spell and C_Spell.GetSpellName,definition.spellID)
        end
        if node and type(name)=='string' and name~='' and type(node.maxRanks)=='number' then
            options.nodes[#options.nodes+1]={id=path,name=name,tab=tab,maxRank=math.max(0,node.maxRanks-unlockRanks),
                rank=math.max(0,(node.currentRank or 0)-unlockRanks),description=read(api.GetDescriptionForPath,path),
                parentID=parentID,depth=depth or 0,milestones=milestones,
                requirementText=read(api.GetSourceTextForPath,path,config),
                -- Live condition booleans describe the real character, not a
                -- simulated allocation. Do not treat them as simulated access.
                requirementsKnown=false}
        end
        local children=read(api and api.GetChildrenForPath,path)
        for _,child in ipairs(type(children)=='table' and children or {}) do
            Visit(type(child)=='table' and (child.pathID or child.id) or child,tab,path,(depth or 0)+1)
        end
    end
    if config and type(tabs)=='table' then
        for _,tabID in ipairs(tabs) do
            local info=read(api.GetTabInfo,tabID)
            Visit(read(api.GetRootPathForTab,tabID),info and info.name or profession)
        end
        if #tabs>0 and #options.nodes==0 then options.nodes=previous.nodes or {} end
    else options.nodes=previous.nodes or {} end
    table.sort(options.nodes,function(a,b) return a.tab==b.tab and a.name<b.name or a.tab<b.tab end)
    -- Retain actual helpful aura identities for explicit simulations. No
    -- profession relevance, rating conversion or yield bonus is inferred.
    local buffs={}
    for _,buff in ipairs(options.buffs) do buffs[buff.id]=buff end
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i=1,255 do
            local aura=read(C_UnitAuras.GetAuraDataByIndex,'player',i,'HELPFUL')
            if not aura then break end
            if type(aura.spellId)=='number' and type(aura.name)=='string'
                and not (issecretvalue and (issecretvalue(aura.spellId) or issecretvalue(aura.name))) then
                buffs[aura.spellId]={id=aura.spellId,name=aura.name}
            end
        end
    end
    options.buffs={} for _,buff in pairs(buffs) do options.buffs[#options.buffs+1]=buff end
    table.sort(options.buffs,function(a,b) return a.name<b.name end)
    char.professionOptions[key]=options
    return options
end
-- Manual benchmark percentages are assumptions, never profession ratings.
-- Return a fresh complete table so caller-owned or SavedVariables tables cannot
-- be shared with cached simulation contexts.
function LL:NormalizeSyntheticBenchmark(values)
    if type(values)~='table' then return nil end
    local limits={outputLevel=200,specializationBonus=100,resourcefulnessChance=100,resourcefulnessSaved=100}
    for key in pairs(values) do if not limits[key] then return nil end end
    local normalized={}
    for key,upper in pairs(limits) do
        local value=values[key]
        if value==nil then value=key=='outputLevel' and 100 or 0 end
        if type(value)~='number' or value~=value or value<0 or value>upper or value%1~=0 then return nil end
        normalized[key]=value
    end
    return normalized
end
-- Keep simulated ratings and percentages independent; no universal rating curve.
LL.ProfessionSimulationStats={
    {key='resourcefulness',name='Resourcefulness'},{key='multicraft',name='Multicraft'},
    {key='ingenuity',name='Ingenuity'},{key='craftingSpeed',name='Crafting speed'},
    {key='finesse',name='Finesse'},{key='perception',name='Perception'},{key='deftness',name='Deftness'}}
function LL:ProfessionSimulationStatOptions(profession)
    local gathering=profession=='Herbalism' or profession=='Mining' or profession=='Skinning'
    local out={}
    for i,stat in ipairs(self.ProfessionSimulationStats) do
        if gathering and i>=5 or not gathering and i<=4 then out[#out+1]=stat end
    end
    return out
end
local function finiteStat(v,max)
    return v==nil or type(v)=='number' and v==v and v>=0 and v<math.huge and (max==nil or v<=max)
end
function LL:IsProfessionChanceStat(key)
    return key=='resourcefulness' or key=='multicraft' or key=='ingenuity' or key=='finesse'
end
function LL:SimulatedProfessionOperationStats(profile)
    if type(profile.stats)~='table' then return nil end
    local out={}
    for _,stat in ipairs(self.ProfessionSimulationStats) do
        local v=profile.stats[stat.key]
        if v and (v.rating~=nil or v.percent~=nil) then
            out[#out+1]={bonusStatName=stat.name,bonusStatValue=v.rating,ratingPct=v.percent,
                simulated=true,statKey=stat.key}
        end
    end
    return #out>0 and out or nil
end
-- Point sliders store the same node=rank signature as measured snapshots.
-- Expose a fresh allocation for recipe/category-specific research rules;
-- an absent allocation remains unknown rather than becoming zero points.
function LL:ProfessionSpecializationPoints(signature)
    if signature=='none' then return {} end
    if type(signature)~='string' or signature=='' then return nil end
    local points={}
    for token in (signature..','):gmatch('(.-),') do
        local node,rank=token:match('^%s*(%d+)=(%d+)%s*$')
        node,rank=tonumber(node),tonumber(rank)
        if not PositiveInt(node) or not finiteStat(node) or not finiteStat(rank) or rank==nil or rank%1~=0 then return nil end
        local key=tostring(node)
        if points[key]~=nil then return nil end
        points[key]=rank
    end
    return points
end
function LL:ProfessionNodeRequirements(node,points,skill)
    -- Only structured, source-backed requirements are executable. Text and
    -- the live character's isMet flag cannot validate a different allocation.
    for _,req in ipairs(node.requirements or {}) do
        if req.kind=='node' and type(req.nodeID)=='number' and type(req.rank)=='number' then
            if (points[tostring(req.nodeID)] or 0)<req.rank then
                return false,('Requires %d points in %s'):format(req.rank,req.name or ('node '..req.nodeID))
            end
        elseif req.kind=='skill' and type(req.skill)=='number' then
            if not skill or skill<req.skill then return false,('Requires skill %d'):format(req.skill) end
        else return false,'Unlock requirements not yet supported' end
    end
    if node.requirementsKnown==false then return nil,node.requirementText or 'Unlock requirements not captured' end
    return true
end
function LL:ProfessionNodeTooltip(node,rank,points,skill)
    local lines={node.name,('%d / %d points'):format(rank,node.maxRank)}
    if node.description then lines[#lines+1]=node.description end
    local allowed,why=self:ProfessionNodeRequirements(node,points,skill)
    if allowed~=true then lines[#lines+1]=why end
    for _,m in ipairs(node.milestones or {}) do
        lines[#lines+1]=('%s %d points: %s'):format(rank>=m.rank and 'Reached' or 'At',m.rank,m.description)
    end
    if #(node.milestones or {})==0 then lines[#lines+1]='Milestone descriptions are unavailable from the client.' end
    return lines
end
function LL:ProfessionThresholdNotes(f,option,ctx)
    local lines,breakpoints={},{}
    if not ctx then return lines end
    local skill=ctx.effectiveSkill or ctx.skill
    local build=GetBuildInfo and select(2,GetBuildInfo())
    local seen={}
    for _,rule in ipairs(self.ItemDB and self.ItemDB.professionRules or {}) do
        if self.IsApprovedNumericRule and self:IsApprovedNumericRule(rule)
            and rule.method==option.name and rule.recipeID==option.recipeID
            and rule.inputItemID==f.id and rule.expansionID==f.expansionID
            and (rule.inputQualityRank==nil or rule.inputQualityRank==f.reagentQuality)
            and tostring(rule.build)==tostring(build)
            and self.ProfessionFactor and self:ProfessionFactor(rule,ctx) then
            for _,point in ipairs(rule.skillFactors or {}) do
                if type(skill)=='number' and type(point.skill)=='number' and point.skill>skill and not seen[point.skill] then
                    seen[point.skill]=true
                    breakpoints[#breakpoints+1]=point.skill
                    break
                end
            end
        end
    end
    table.sort(breakpoints)
    for _,point in ipairs(breakpoints) do
        lines[#lines+1]=('Next researched skill breakpoint: %g (+%g skill)'):format(point,point-skill)
    end
    if #lines==0 and ctx.simulated then lines[1]='No researched skill breakpoint is available for this recipe.' end
    return lines
end
function LL:SetManualProfessionProfile(character,profession,expansion,values)
    if not self.db or type(character)~='string' or type(profession)~='string'
        or type(expansion)~='number' or type(values)~='table' then return false end
    if not finiteStat(values.skill) then return false end
    local benchmark=values.benchmark~=nil and self:NormalizeSyntheticBenchmark(values.benchmark) or nil
    if values.benchmark~=nil and not benchmark then return false end
    if values.specialization~=nil then
        if type(values.specialization)~='string' then return false end
        if values.specialization~='none' then
            local parts,seen={},{}
            for token in (values.specialization..','):gmatch('(.-),') do
                local node,rank=token:match('^%s*(%d+)=(%d+)%s*$')
                if not node or seen[node] then return false end
                seen[node]=true;parts[#parts+1]=node..'='..rank
            end
            if #parts==0 then return false end
            table.sort(parts);values.specialization=table.concat(parts,',')
        end
    end
    self.db.manualProfessionProfiles=self.db.manualProfessionProfiles or {}
    local chars=self.db.manualProfessionProfiles
    chars[character]=chars[character] or {}
    if values.buffs~=nil then
        if type(values.buffs)~='table' then return false end
        for id,enabled in pairs(values.buffs) do
            if not tonumber(id) or tonumber(id)<=0 or tonumber(id)%1~=0 or enabled~=true then return false end
        end
    end
    local buffs
    if values.buffs and next(values.buffs) then
        buffs={} for id,enabled in pairs(values.buffs) do buffs[id]=enabled end
    end
    local stats
    if values.stats~=nil then
        if type(values.stats)~='table' then return false end
        stats={}
        for _,stat in ipairs(self.ProfessionSimulationStats) do
            local v=values.stats[stat.key]
            if v~=nil then
                if type(v)~='table' or not finiteStat(v.rating)
                    or not finiteStat(v.percent,self:IsProfessionChanceStat(stat.key) and 100 or nil) then return false end
                stats[stat.key]={rating=v.rating,percent=v.percent}
            end
        end
    end
    local profile={enabled=values.enabled==true,skill=values.skill,specialization=values.specialization,stats=stats,
        buffs=buffs,benchmark=benchmark,
        character=character,profession=profession,expansionID=expansion,simulated=true}
    chars[character][profession..':'..expansion]=profile
    if self.Invalidate then self:Invalidate() end
    return true
end
function LL:RecordProfessionEquipment()
    local key=self:CharacterKey()
    local char=key and self.db and self.db.characters and self.db.characters[key]
    local api=C_TradeSkillUI and C_TradeSkillUI.GetProfessionInventorySlots
    if not char or type(api)~='function' or not GetInventoryItemLink then return end
    local ok,slots=pcall(api)
    if not ok or type(slots)~='table' then return end
    local equipment={}
    for _,slot in ipairs(slots) do
        if type(slot)=='number' then
            local read,link=pcall(GetInventoryItemLink,'player',slot)
            if read and type(link)=='string' then equipment[slot]=link end
        end
    end
    -- Links identify actual equipped variants; no undocumented bonus is inferred.
    char.professionEquipment=equipment
end
function LL:GetManualProfessionProfile(character,profession,expansion)
    local profiles=self.db and self.db.manualProfessionProfiles
    local p=profiles and profiles[character]
    return p and p[profession..':'..tostring(expansion)]
end
local function qualityNumber(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return type(value)=='number' and value==value and value>=0 and value<math.huge and value or nil
end
local function qualityRead(fn,...)
    if type(fn)~='function' then return nil end
    local ok,value=pcall(fn,...)
    if ok and not (issecretvalue and issecretvalue(value)) then return value end
end
local function qualityCopy(value)
    if type(value)~='table' then return value end
    local result={} for key,v in pairs(value) do result[key]=qualityCopy(v) end return result
end
local function qualityBuild() return GetBuildInfo and tostring(select(2,GetBuildInfo())) or nil end
-- Verify a real inventory target. A raw GUID supplied in tooltip context alone
-- cannot establish that it belongs to this item or reagent rank.
function LL:FindSkillQualityTarget(f,expectedGUID)
    if type(f)~='table' or not PositiveInt(f.id) or not ItemLocation or not C_Item then return nil end
    local function inspect(location)
        if not location or qualityRead(C_Item.GetItemID,location)~=f.id then return nil end
        local guid=qualityRead(C_Item.GetItemGUID,location)
        if type(guid)~='string' or guid=='' then return nil end
        if expectedGUID and guid~=expectedGUID then return nil end
        local rank=qualityRead(C_TradeSkillUI and C_TradeSkillUI.GetItemReagentQualityByItemInfo,'item:'..f.id)
        if rank~=nil and rank~=f.reagentQuality then return nil end
        return guid
    end
    local context=f.context or {}
    if context.itemLocation then
        local guid=inspect(context.itemLocation);if guid then return guid end
    end
    local function bagSlot(bag,slot)
        local location=qualityRead(ItemLocation.CreateFromBagAndSlot,ItemLocation,bag,slot)
        return inspect(location)
    end
    if type(context.bagID)=='number' and type(context.slotID)=='number' then
        local guid=bagSlot(context.bagID,context.slotID);if guid then return guid end
    end
    if C_Container and C_Container.GetContainerNumSlots then
        for bag=0,5 do
            local slots=qualityRead(C_Container.GetContainerNumSlots,bag)
            if PositiveInt(slots) then for slot=1,slots do
                local guid=bagSlot(bag,slot);if guid then return guid end
            end end
        end
    end
end
-- Only the actual two-quality salvage operation supplies a usable boundary.
-- No quality-count or minimum-skill inference is made from recipe difficulty.
function LL:RememberSkillQualityOperation(f,recipeID,operation)
    if type(f)~='table' or not PositiveInt(f.id) or not PositiveInt(f.reagentQuality)
        or not qualityNumber(f.expansionID) or type(operation)~='table' or operation.recipeID~=recipeID
        or operation.isQualityCraft~=true then return nil end
    local recipe=qualityRead(C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo,recipeID)
    if type(recipe)~='table' or recipe.supportsQualities~=true or recipe.maxQuality~=2
        or recipe.isSalvageRecipe~=true then return nil end
    local base,bonus=qualityNumber(operation.baseSkill),qualityNumber(operation.bonusSkill)
    local low,high=qualityNumber(operation.lowerSkillThreshold),qualityNumber(operation.upperSkillTreshold)
    local q=qualityNumber(operation.craftingQuality)
    if not base or not bonus or not low or not high or high<low or (q~=1 and q~=2) then return nil end
    local skill=base+bonus
    local threshold=q==1 and high or low
    if not qualityNumber(skill) or threshold<=0 or (q==1 and skill>=threshold) or (q==2 and skill<threshold) then return nil end
    local current=self.CharacterKey and self:CharacterKey()
    local char=current and self.db and self.db.characters and self.db.characters[current]
    local build=qualityBuild()
    if not char or not build then return nil end
    local snapshot={recipeID=recipeID,inputItemID=f.id,inputQualityRank=f.reagentQuality,expansionID=f.expansionID,
        character=current,build=build,observed=Now(),effectiveSkill=skill,craftingQuality=q,
        highQualitySkillThreshold=threshold,maxQuality=2,allocationVerified=true,concentration=false}
    char.skillQualityOperations=char.skillQualityOperations or {}
    local snapshots=char.skillQualityOperations
    local key=tostring(recipeID)..':'..tostring(f.id)
    if not snapshots[key] then
        local count,oldest,oldestAt=0
        for id,entry in pairs(snapshots) do
            count=count+1
            local at=type(entry)=='table' and qualityNumber(entry.observed) or nil
            if not oldest or (at or 0)<oldestAt then oldest,oldestAt=id,at or 0 end
        end
        if count>=128 and oldest then snapshots[oldest]=nil end
    end
    snapshots[key]=snapshot
    return qualityCopy(snapshot)
end
-- Operation API reads are allocation-specific for milling/prospecting. The
-- legacy recipe-only branch remains available for general stat context, but
-- can never qualify a skill-to-quality snapshot.
function LL:GetCachedOperationInfo(recipeID,f)
    if not recipeID or not OwnTradeSkillWindow() then return nil end
    local api=C_TradeSkillUI and C_TradeSkillUI.GetCraftingOperationInfo
    if type(api)~='function' then return nil end
    self._professionOperationCache=self._professionOperationCache or {}
    if f then
        local guid=self:FindSkillQualityTarget(f)
        if not guid then return nil end
        local key=table.concat({'quality',tostring(recipeID),tostring(f.id),tostring(f.reagentQuality),guid},':')
        local entry=self._professionOperationCache[key]
        local now=GetTime and GetTime() or 0
        if entry and now-entry.at<5 then return entry.info or nil end
        local info=qualityRead(api,recipeID,{},guid,false)
        if type(info)~='table' then info=nil end
        if (self._professionOperationCache.qualityCount or 0)>=128 then self._professionOperationCache={} end
        self._professionOperationCache[key]={at=now,info=info}
        self._professionOperationCache.qualityCount=(self._professionOperationCache.qualityCount or 0)+1
        if info then self:CaptureProfessionOperation(recipeID,info) end
        local snapshot=info and self:RememberSkillQualityOperation(f,recipeID,info)
        if not snapshot then
            local current=self.CharacterKey and self:CharacterKey()
            local char=current and self.db and self.db.characters and self.db.characters[current]
            if char and char.skillQualityOperations then
                char.skillQualityOperations[tostring(recipeID)..':'..tostring(f.id)]=nil
            end
        end
        return info
    end
    local cached=self._professionOperationCache[recipeID]
    if cached~=nil then return cached or nil end
    local ok,info=pcall(api,recipeID,{},nil,false)
    self._professionOperationCache[recipeID]=ok and type(info)=='table' and info or false
    if ok and type(info)=='table' then self:CaptureProfessionOperation(recipeID,info) end
    return self._professionOperationCache[recipeID] or nil
end
function LL:GetSkillQualityOperation(f,recipeID,character,allowStored)
    if type(f)~='table' then return nil end
    local current=self.CharacterKey and self:CharacterKey()
    character=character or current
    if character==current and not allowStored then
        -- Cached API reads are invalidated with skills, equipment and talents;
        -- if an exact operation is unavailable, a live quote stays unqualified.
        local info=self:GetCachedOperationInfo(recipeID,f)
        if not info then return nil end
    end
    local char=character and self.db and self.db.characters and self.db.characters[character]
    local snapshots=char and char.skillQualityOperations
    local snapshot=snapshots and snapshots[tostring(recipeID)..':'..tostring(f.id)]
    if type(snapshot)~='table' or snapshot.character~=character or snapshot.recipeID~=recipeID
        or snapshot.inputItemID~=f.id or snapshot.inputQualityRank~=f.reagentQuality or snapshot.expansionID~=f.expansionID
        or snapshot.build~=qualityBuild() or snapshot.allocationVerified~=true or snapshot.concentration~=false
        or not qualityNumber(snapshot.highQualitySkillThreshold) or snapshot.highQualitySkillThreshold<=0
        or not qualityNumber(snapshot.effectiveSkill) or not qualityNumber(snapshot.observed)
        or (snapshot.craftingQuality~=1 and snapshot.craftingQuality~=2) then return nil end
    return qualityCopy(snapshot)
end
function LL:CaptureProfessionOperation(recipeID,info)
    local api=C_TradeSkillUI
    if not api or not api.GetProfessionInfoByRecipeID then return end
    local ok,profession=pcall(api.GetProfessionInfoByRecipeID,recipeID)
    if not ok or type(profession)~='table' or type(profession.professionID)~='number' then return end
    local char=self.db and self.db.characters and self.db.characters[self:CharacterKey()]
    if not char then return end
    local function number(v) return type(v)=='number' and not (issecretvalue and issecretvalue(v)) and v==v and v or nil end
    local saved={recipeID=recipeID,observed=Now(),baseSkill=number(info.baseSkill),bonusSkill=number(info.bonusSkill),
        lowerSkillThreshold=number(info.lowerSkillThreshold),upperSkillThreshold=number(info.upperSkillTreshold),stats={}}
    for _,stat in ipairs(info.bonusStats or {}) do
        if type(stat.bonusStatName)=='string' and not (issecretvalue and issecretvalue(stat.bonusStatName)) then
            saved.stats[#saved.stats+1]={name=stat.bonusStatName,rating=number(stat.bonusStatValue),percent=number(stat.ratingPct)}
        end
    end
    char.professionOperationProfiles=char.professionOperationProfiles or {}
    char.professionOperationProfiles[tostring(profession.professionID)]=saved
end
function LL:HasCurrentProfession(name)
    if not name then return false end
    local key=self:CharacterKey()
    local char=key and self.db and self.db.characters[key]
    return not not (char and char.professions and char.professions[name])
end
function LL:CanTransferToAlt(f)
    local c=f and f.context or {}
    if c.isQuest then return false end
    -- An item's binding can change *after* receipt or equipping. The instance
    -- status wins over its template's bind type. Ambiguous bound+account-bound
    -- records are treated as non-transferable until separately verified.
    if c.isSoulbound == true then return false end
    if c.isBound == true and c.verifiedWarbound ~= true then return false end
    if c.verifiedWarbound == true then return true end
    if c.isBoundToAccount == true or c.isWarbound == true then
        return false -- Account-bound hint alone does not prove THIS COPY can transfer.
    end
    if f and (f.bindType==1 or f.bindType==4) then return false end
    if c.verifiedUnbound == true then return true end
    if f and f.classID==7 and c.isBound~=true and f.bindType~=1 and f.bindType~=4 then
        -- Reagents that are not specifically bound are usually transferable.
        return true
    end
    return false
end
function LL:CanUseConversion(f, conversion)
    local method=conversion.method
    local letter=({Disenchant="D",Mill="M",Prospect="P",Smelt="S",
        Craft="C",Recycle="R",Research="R",Exchange="X",Combine="X",Split="X"})[method] or "C"
    local mode=self.ProcessingMethodMode and self:ProcessingMethodMode(letter) or 2
    if mode==3 then return false,"Disabled" end
    if method=="Exchange" or method=="Combine" or method=="Split" then
        -- These operations need no learned profession, but Manual must still
        -- respect the actual character selections in the roster table.
        local current=self:CharacterKey()
        if mode~=4 or not self.AltMethodEnabled or self:AltMethodEnabled(current,"X") then
            return true,nil,"Current character"
        end
        if self.db.includeVerifiedAlts~=false and self:CanTransferToAlt(f) then
            for name in pairs(self.db.characters or {}) do
                if name~=current and self:AltMethodEnabled(name,"X") then return true,nil,name end
            end
        end
        return false,"No character selected for exchanges"
    end
    local spell=conversion.requiredSpell or KNOWN_SPELLS[method]
    local profession=conversion.profession or PROF[method]
    if not profession then return false,"Profession requirement not verified" end
    local key=self:CharacterKey()
    local function targetKnown(char)
        if not conversion.salvage then return true end
        local scan=char and char.salvageRecipes and char.salvageRecipes[conversion.recipeID]
        return scan and scan.inputs and scan.inputs[f.id]==true
    end
    if (mode~=4 or not self.AltMethodEnabled or self:AltMethodEnabled(key,letter))
        and (self:HasCurrentProfession(profession) or (method=="Disenchant" and self:CurrentHasEnchanting())) then
        if conversion.recipeID then
            local char=self.db.characters[key]
            local recipe=char and char.recipes and char.recipes[conversion.recipeID]
            if recipe and recipe.learned and recipe.disabled~=true and targetKnown(char) then
                return true,nil,"Current character"
            end
            -- Learned recipe checked from actual spellbook as a fallback.
            if conversion.requiredSpell and SpellKnown(conversion.requiredSpell) and targetKnown(char) then
                return true,nil,"Current character"
            end
        elseif spell and SpellKnown(spell) then
            return true,nil,"Current character"
        elseif method=="Disenchant" and self:CurrentHasEnchanting() then
            -- Current profession is enough to make DE a candidate, but the game
            -- still makes the final check on the exact item.
            return true,nil,"Current character"
        end
    end
    if self.db.includeVerifiedAlts~=false and self:CanTransferToAlt(f) then
        for name,char in pairs(self.db.characters or {}) do
            if name~=key and char.professions and char.professions[profession] then
                local known=conversion.recipeID and char.recipes and char.recipes[conversion.recipeID]
                local spellAccess=(not conversion.recipeID and spell and char.spells and char.spells[spell])
                if (not self.AltMethodEnabled or self:AltMethodEnabled(name,letter))
                    and targetKnown(char) and ((known and known.learned and not known.disabled) or spellAccess) then
                    return true,nil,name
                end
                -- Profession alone never makes an alt eligible: recipe/specialization
                -- and expansion skill are not proven by profession ownership.
            end
        end
    end
    -- A deliberate Manual checkbox authorizes a baseline processing estimate.
    -- It does NOT attest to profession specialization, equipment, or an
    -- individually learned recipe. Keep explicit recipe-ID crafts verified.
    if mode==4 and not conversion.recipeID then
        local selected={}
        for name in pairs(self.db.characters or {}) do
            if self.AltMethodEnabled and self:AltMethodEnabled(name,letter)
                and self.db.characters[name] and self.db.characters[name].altMethods
                and self.db.characters[name].altMethods[letter]==true
                and (name==key or self:CanTransferToAlt(f)) then
                selected[#selected+1]=name
            end
        end
        if #selected>0 then
            -- Prefer the selected current character, then a selected alt with
            -- VERIFIED expansion skill; use a minimum-skill Manual assumption
            -- only if no such character exists. Do not select alphabetically.
            local chosen
            for _,name in ipairs(selected) do
                if name==key then
                    if self:HasCurrentProfession(profession) then
                        chosen=name
                        break
                    end
                end
            end
            if not chosen then
                local bestSkill=-1
                for _,name in ipairs(selected) do
                    local char=self.db.characters[name]
                    local profile=char and char.researchProfiles and
                        char.researchProfiles[tostring(profession)..":"..tostring(f and f.expansionID)]
                    local skill=profile and tonumber(profile.skill)
                    if not skill and char and type(char.details)=="table" then
                        local family=self.DisenchantTables and self.DisenchantTables[f and f.expansionID]
                        local expName=family and family.name
                        for _,detail in pairs(char.details) do
                            if type(detail)=="table" and detail.parentName==profession
                                and type(detail.name)=="string" and expName
                                and (detail.name:find(expName,1,true)
                                    or (f and f.expansionID==10 and detail.name:find("Khaz Algar",1,true)))
                                and type(detail.skill)=="number" then
                                skill=detail.skill
                                break
                            end
                        end
                    end
                    if skill and skill>=0 and skill>bestSkill then
                        chosen,bestSkill=name,skill
                    end
                end
            end
            -- All remaining eligible characters are explicit Manual
            -- selections with unknown profession conditions.
            if not chosen then
                table.sort(selected)
                chosen=selected[1]
            end
            local display=chosen==key and "Current character" or chosen
            return true,"Manual minimum-skill assumption if skill unknown; specialization unlock unverified",display
        end
    end
    local manual={Mill="manualMilling",Prospect="manualProspecting",
        Smelt="manualSmelting",Disenchant="manualDisenchanting"}
    if manual[method] and self.db[manual[method]] then
        return false,"Ability manually indicated, but no character/recipe verified"
    end
    return false,"No eligible character with verified recipe/unlock"
end

-- Scan the open profession window in small batches to avoid repeated, expensive
-- per-item UI queries. Save only a) materials consumed by other professions, and
-- b) single-reagent recipes with a fixed output. This is a discovery catalogue,
-- NOT proof all WoW recipes have been scanned.
function LL:ScanProfessionRecipes()
    if not self.db or self.db.enableLearnedRecipeDiscovery==false then return end
    if not C_TradeSkillUI or not C_TradeSkillUI.GetAllRecipeIDs
        or not C_TradeSkillUI.GetRecipeInfo or not C_TradeSkillUI.GetRecipeSchematic then return end
    local lineID,lineName,_,_,_,parentName=DisplayedSkillLine()
    local key=self:CharacterKey()
    local char=key and self.db.characters[key]
    if not lineID or not char then return end
    local profession=parentName or lineName
    if not char.professions[profession] then return end
    local ok,ids=pcall(C_TradeSkillUI.GetAllRecipeIDs)
    if not ok or type(ids)~="table" then return end
    self._recipeScanSerial=(self._recipeScanSerial or 0)+1
    local serial=self._recipeScanSerial
    self.db.recipeCandidates=self.db.recipeCandidates or {}
    self.db.reagentConsumers=self.db.reagentConsumers or {}
    char.reagentUses=char.reagentUses or {}
    char.salvageRecipes=char.salvageRecipes or {}
    for recipeID,scan in pairs(char.salvageRecipes) do
        if scan.skillLineID==lineID then char.salvageRecipes[recipeID]=nil end
    end
    -- Replace this profession's prior reagent records; a recipe may have
    -- become unlearned since its last scan. Other professions are preserved.
    for reagentID,used in pairs(char.reagentUses) do
        for recipeID,record in pairs(used) do
            if type(record)=="table" and record.skillLineID==lineID then
                used[recipeID]=nil
            end
        end
        if not next(used) then char.reagentUses[reagentID]=nil end
    end
    local n=1
    local function Step()
        if serial~=self._recipeScanSerial then return end
        -- Stop if the user opened a different profession while we're scanning.
        local currentID=DisplayedSkillLine()
        if currentID~=lineID then return end
        local processed=0
        while n<=#ids and processed<35 do
            local recipeID=ids[n]; n=n+1; processed=processed+1
            local goodInfo,info=pcall(C_TradeSkillUI.GetRecipeInfo,recipeID)
            local goodSchem,schem=pcall(C_TradeSkillUI.GetRecipeSchematic,recipeID,false)
            if goodInfo and type(info)=="table" and goodSchem and type(schem)=="table" then
                local slots=schem.reagentSlotSchematics or {}
                local mainID,mainAmount,distinct= nil,nil,0
                local allInputs,consumerIDs,requiredIDs={},{},{}
                for _,slot in ipairs(slots) do
                    local rs=slot.reagents or {}
                    local id= #rs==1 and (rs[1].itemID or rs[1].itemId)
                    local amount=slot.quantityRequired
                    if id and PositiveInt(amount) then
                        distinct=distinct+1
                        mainID=id;mainAmount=amount
                        allInputs[#allInputs+1]={id=id,amount=amount}
                        consumerIDs[id]=true
                        -- Single fixed reagent is proven; alternative/optional
                        -- slots are not a reliable requirement for this item.
                        if not slot.isOptional then requiredIDs[id]=true end
                    else
                        distinct=999 -- Optional, selectable, or unknown input: skip candidate.
                    end
                    -- Different professions consuming reagents is useful even
                    -- when the recipe itself is multi-ingredient.
                    for _,r in ipairs(rs) do
                        local consumed=r.itemID or r.itemId
                        if consumed then consumerIDs[consumed]=true end
                    end
                end
                for id in pairs(consumerIDs) do
                    self.db.reagentConsumers[id]=self.db.reagentConsumers[id] or {}
                    self.db.reagentConsumers[id][profession]=true
                end
                -- Also accept one core reagent plus extra vendor-purchased supplies.
                -- Only trust vendorBuy when TSM knows the vendor cost; never
                -- assume an absent cost is zero.
                local vendorSupplies={}
                if distinct>1 and distinct<999 then
                    local core={}
                    for _,v in ipairs(allInputs) do
                        local cost=v.fixedBuyPrice -- Only verified vendor costs, not TSM data
                        if cost then vendorSupplies[#vendorSupplies+1]={id=v.id,amount=v.amount}
                        else core[#core+1]=v end
                    end
                    if #core==1 then
                        mainID=core[1].id;mainAmount=core[1].amount
                        distinct=1
                    end
                end
                -- Salvage-style profession recipes are not fixed-output crafts.
                -- Record verified learned spell accessibility, not fake output
                -- item IDs or vendor/recipe conversions.
                if info.isSalvageRecipe and info.learned and info.disabled~=true then
                    char.spells=char.spells or {}
                    char.spells[recipeID]=true
                    local definition=self:SalvageRecipeDefinition(recipeID)
                    local inputs=definition and definition.profession==profession and self:ReadSalvageInputs(recipeID)
                    if inputs then
                        char.salvageRecipes[recipeID]={inputs=inputs,skillLineID=lineID,scanned=Now()}
                        for id in pairs(inputs) do
                            self.db.reagentConsumers[id]=self.db.reagentConsumers[id] or {}
                            self.db.reagentConsumers[id][profession]=true
                            char.reagentUses[id]=char.reagentUses[id] or {}
                            char.reagentUses[id][recipeID]={skillLineID=lineID}
                        end
                    end
                end
                local output=schem.outputItemID
                local qmin=schem.quantityMin; local qmax=schem.quantityMax
                if info.learned then
                    char.recipes[recipeID]={learned=true, disabled=info.disabled,
                        profession=profession,skillLineID=lineID,skillLineName=lineName,
                        relativeDifficulty=info.relativeDifficulty,
                        maxTrivialLevel=info.maxTrivialLevel,
                        canSkillUp=info.canSkillUp,numSkillUps=info.numSkillUps,
                        firstCraft=info.firstCraft,scanned=Now(),name=info.name}
                    if info.disabled~=true then
                        for id in pairs(requiredIDs) do
                            char.reagentUses[id]=char.reagentUses[id] or {}
                            char.reagentUses[id][recipeID]={skillLineID=lineID}
                        end
                    end
                else
                    -- Never keep a no-longer-learned recipe eligible.
                    char.recipes[recipeID]=nil
                end
                if distinct==1 and mainID and output and PositiveInt(qmin)
                    and qmin==qmax and info.isRecraft~=true and schem.isRecraft~=true
                    and schem.recipeType~=2 and not info.isSalvageRecipe then
                    local c=self.db.recipeCandidates[mainID] or {}
                    c[recipeID]={recipeID=recipeID,requiredSpell=recipeID,
                        method="Craft",profession=profession,expansion=lineName,
                        inputCount=mainAmount,outputID=output,outputCount=qmin,
                        vendorSupplies=vendorSupplies,
                        source="In-game profession recipes",verifiedOutput=true}
                    self.db.recipeCandidates[mainID]=c
                end
            end
        end
        if n<=#ids and C_Timer and C_Timer.After then C_Timer.After(0.05,Step)
        else
            if self.Invalidate then self:Invalidate() end
        end
    end
    Step()
end

function LL:ProfessionAlternatives(f,result)
    if not self.db or self.db.showResearchDetails~=true then return {} end -- B3: shown with notes
    local list={}
    for _,c in ipairs(result and result.conversionOptions or {}) do
        if c.profession or self:ProfessionForMethod(c.name) then
            local profession=c.profession or self:ProfessionForMethod(c.name)
            local text=c.name.." - "..profession
            if c.expansion then text=text.." ("..c.expansion..")" end
            if c.available then text=text.."; "..(c.character or "current character")
            else text=text.."; unavailable/unverified" end
            list[#list+1]={method=c.name,profession=profession,description=text,entry=c}
        end
    end
    return list
end
-- Optional progression advice, drawn ONLY from currently learned recipes
-- that explicitly require the hovered item. Scanned snapshots are per character.
-- Neither 'firstCraft' nor a difficulty color proves a recipe DISCOVERY;
-- the public recipe API does not provide reliable discovery chances.
local DIFFICULTY={ [0]="orange",[1]="yellow",[2]="green",[3]="gray" }
function LL:ProfessionProgression(f,result)
    if not self.db or not f or not f.id then return {} end
    local key=self:CharacterKey()
    local candidates={}
    for characterKey,char in pairs(self.db.characters or {}) do
        local current=characterKey==key
        if current or (self.db.includeVerifiedAlts~=false and self:CanTransferToAlt(f)
            and (not self.AltMethodEnabled or self:AltMethodEnabled(characterKey,"C"))) then
            for recipeID in pairs((char.reagentUses and char.reagentUses[f.id]) or {}) do
                local rec=char.recipes and char.recipes[recipeID]
                local prof=rec and rec.profession
                if rec and rec.learned and rec.disabled~=true and prof
                    and char.professions and char.professions[prof] then
                    local progress=(char.details and rec.skillLineID and char.details[rec.skillLineID])
                    local lineName=(progress and progress.name) or rec.skillLineName
                    -- Never label a broad profession (e.g., Engineering) as
                    -- the current expansion unless an actual skill line was seen.
                    local title=lineName or prof
                    if lineName and not lineName:find(prof,1,true) then
                        title=lineName.." "..prof
                    end
                    local parts={title}
                    if progress and type(progress.skill)=="number" and
                        type(progress.maxSkill)=="number" then
                        parts[#parts+1]=("%d/%d"):format(progress.skill,progress.maxSkill)
                    end
                    parts[#parts+1]=current and "current" or characterKey
                    local benefit
                    local diff=DIFFICULTY[rec.relativeDifficulty]
                    if rec.canSkillUp==true then
                        local points=(type(rec.numSkillUps)=="number" and rec.numSkillUps>0)
                            and ("up to +"..rec.numSkillUps.." skill") or "skill-up possible"
                        benefit=points..(diff and (" ("..diff..")") or " (chance unknown)")
                    elseif rec.canSkillUp==false then
                        benefit=nil -- no skill-up benefit; first-craft may still help
                    -- Unknown canSkillUp is not a positive profession benefit.
                    end
                    if rec.firstCraft==true then
                        benefit=benefit and (benefit.."; first-craft flagged")
                            or "first-craft flagged"
                    end
                    if benefit then
                        local hint=table.concat(parts," / ")..": "..tostring(rec.name or ("Recipe "..recipeID)).." — "..benefit
                        local rank=(current and 100 or 0)+
                            (rec.canSkillUp==true and 10 or 0)+
                            (rec.firstCraft==true and 5 or 0)
                        candidates[#candidates+1]={text=hint,rank=rank}
                    end
                end
            end
        end
    end
    table.sort(candidates,function(a,b)
        if a.rank~=b.rank then return a.rank>b.rank end
        return a.text<b.text
    end)
    local out={}
    for i=1,math.min(3,#candidates) do out[#out+1]=candidates[i].text end
    return out
end

function LL:MatchingCharacters(profession)
    local out={}
    local method=({Enchanting="D",Inscription="M",Jewelcrafting="P",Mining="S"})[profession] or "C"
    for characterKey,character in pairs(self.db and self.db.characters or {}) do
        local scannedProfession=character.professions and character.professions[profession]
        if scannedProfession and (not self.AltMethodEnabled or self:AltMethodEnabled(characterKey,method)) then
            out[#out+1]={name=characterKey,skill=scannedProfession.skill,
                maxSkill=scannedProfession.maxSkill,details=character.details,faction=character.faction}
        end
    end
    table.sort(out,function(a,b) return a.name<b.name end)
    return out
end
local events=CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("SKILL_LINES_CHANGED")
events:RegisterEvent("TRADE_SKILL_SHOW")
events:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:RegisterEvent("TRAIT_CONFIG_UPDATED")
events:SetScript("OnEvent",function(_,event)
    if not LL.db then return end
    if event=="PLAYER_LOGIN" or event=="SKILL_LINES_CHANGED" then LL:RecordProfessions() end
    if event=="PLAYER_LOGIN" or event=="SKILL_LINES_CHANGED"
       or event=="PLAYER_EQUIPMENT_CHANGED" or event=="TRAIT_CONFIG_UPDATED" then
        LL._activeResearchProfileCache=nil
        LL:RecordProfessionEquipment()
        LL:RefreshResearchSkillLines()
        if LL.Invalidate then LL:Invalidate() end
    end
    if event=="TRADE_SKILL_SHOW" or event=="TRADE_SKILL_LIST_UPDATE" then
        LL:RecordDisplayedSkillLine()
        -- Some clients fire frequent list updates; don't restart immediately.
        local now=GetTime and GetTime() or 0
        if event=="TRADE_SKILL_SHOW" or now-(LL._lastRecipeScan or -100)>10 then
            LL._lastRecipeScan=now
            LL:ScanProfessionRecipes()
        end
    end
end)

do -- Per-character method participation policy
-- Account-wide per-character participation.  Rules are only consulted when
-- considering a DIFFERENT character; the current player is never disabled.

local METHOD_PROFESSION={D="Enchanting", M="Inscription", P="Jewelcrafting", S="Mining"}
local CLASS_LABELS={WARRIOR="Warrior",PALADIN="Paladin",HUNTER="Hunter",ROGUE="Rogue",PRIEST="Priest",
    DEATHKNIGHT="Death Knight",SHAMAN="Shaman",MAGE="Mage",WARLOCK="Warlock",MONK="Monk",
    DRUID="Druid",DEMONHUNTER="Demon Hunter",EVOKER="Evoker"}
local CLASS_IDS={WARRIOR=1,PALADIN=2,HUNTER=3,ROGUE=4,PRIEST=5,DEATHKNIGHT=6,
    SHAMAN=7,MAGE=8,WARLOCK=9,MONK=10,DRUID=11,DEMONHUNTER=12,EVOKER=13}
local function ShortName(key)
    if type(key)~="string" then return "Unknown" end
    return key:match("^(.-) %- ") or key
end
function LL:AltDisplayName(key) return ShortName(key) end
function LL:AltClassLabel(class) return CLASS_LABELS[class] or class or "Unknown class" end
-- Per-method modes. The Professions & Alts table that set them was removed
-- in B5b and saved modes are cleared on load, so every method runs as Auto.
-- "Force on" enables evaluation and diagnostic display; it NEVER bypasses
-- Blizzard spell checks, recipe requirements, class masks or binding restrictions.
local MODES={T=true,D=true,M=true,P=true,S=true,C=true,R=true,X=true}
function LL:ProcessingMethodMode(method)
    if not MODES[method] then return 2 end
    local modes=self.db and self.db.processingModes
    local mode=type(modes)=="table" and modes[method] or nil
    return (type(mode)=="number" and mode>=1 and mode<=4) and mode or 2
end
function LL:SetProcessingMethodMode(method,mode)
    if not MODES[method] or not ({[1]=true,[2]=true,[3]=true,[4]=true})[mode] or not self.db then
        return false
    end
    self.db.processingModes=self.db.processingModes or {}
    self.db.processingModes[method]=mode
    self._altRosterRevision=(self._altRosterRevision or 0)+1
    if self.Invalidate then self:Invalidate() end
    return true
end
function LL:AltMethodEnabled(key,method)
    local current=self.CharacterKey and self:CharacterKey()
    if not self.db then return false end
    local mode=self:ProcessingMethodMode(method)
    if mode==3 then return false end
    -- The current character is always checked automatically, but a Manual
    -- setting must also work for this row of the visible table.
    if key==current and mode~=4 then return true end
    if key~=current and self.db.includeVerifiedAlts==false then return false end
    local entry=self.db.characters and self.db.characters[key]
    if not entry then return false end
    local opts=entry.altMethods
    if type(opts)=="table" and opts.all==false then return false end
    if mode==4 then
        if type(opts)=="table" and opts[method]~=nil then return opts[method]==true end
        -- Manual defaults to what the most recent scan actually established.
        if method=="T" then return entry.class~=nil end
        if METHOD_PROFESSION[method] then
            return type(entry.professions)=="table" and entry.professions[METHOD_PROFESSION[method]]~=nil
        end
        if method=="X" then return true end
        if method=="R" then return type(entry.professions)=="table" and entry.professions.Engineering~=nil end
        return type(entry.recipes)=="table" and next(entry.recipes)~=nil
    end
    -- Respect explicit per-alt exclusions from existing profiles, including
    -- T/D transmog/disenchant choices. Never silently reactivate an excluded alt.
    if type(opts)=="table" and opts[method]==false then return false end
    return true
end
function LL:SetAltMethodEnabled(key,method,enabled)
    local entry=self.db and self.db.characters and self.db.characters[key]
    if not entry or not MODES[method] then return false end
    entry.altMethods=entry.altMethods or {}
    entry.altMethods[method]=enabled==true
    self._altRosterRevision=(self._altRosterRevision or 0)+1
    if self.Invalidate then self:Invalidate() end
    return true
end
function LL:SetAltFullyEnabled(key,enabled)
    local entry=self.db and self.db.characters and self.db.characters[key]
    if not entry then return false end
    entry.altMethods=entry.altMethods or {}
    entry.altMethods.all=enabled==true
    self._altRosterRevision=(self._altRosterRevision or 0)+1
    if self.Invalidate then self:Invalidate() end
    return true
end
function LL:ItemPermitsClass(itemID,class)
    local id=CLASS_IDS[class]
    if not id then return nil end
    local mask=self.ItemClassMasks and self.ItemClassMasks[itemID]
    if not mask then return nil end
    -- ItemSparse.AllowableClass = 1 << (classID-1).  Avoid bit libraries,
    -- overflow-prone shifts, and incorrect fallbacks for missing records.
    return math.floor(mask/(2^(id-1)))%2==1
end
-- C5 (owner decision): an alt counts for a missing appearance on ANY armor
-- their armor type can wear, not only class-restricted (tier) pieces.
-- Armor subclasses: 1 cloth, 2 leather, 3 mail, 4 plate, 5 cosmetic, 6 shield.
local ARMOR_TYPE={PRIEST=1,MAGE=1,WARLOCK=1,ROGUE=2,MONK=2,DRUID=2,DEMONHUNTER=2,
    HUNTER=3,SHAMAN=3,EVOKER=3,WARRIOR=4,PALADIN=4,DEATHKNIGHT=4}
local SHIELD_CLASSES={WARRIOR=true,PALADIN=true,SHAMAN=true}
LL.ArmorTypeByClass=ARMOR_TYPE
function LL:ArmorTypePermitsClass(f,class)
    if not f or f.classID~=4 or not ARMOR_TYPE[class] then return nil end
    local sub=f.subClassID
    if f.equipLoc=="INVTYPE_CLOAK" or sub==5 then return true end -- cloaks, cosmetics: any class
    if sub==6 then return SHIELD_CLASSES[class]==true end
    if sub==1 or sub==2 or sub==3 or sub==4 then return ARMOR_TYPE[class]==sub end
    return nil -- rings, trinkets, off-hands: no armor-type answer
end
-- true/false when the class mask or the armor type gives an answer, else nil.
-- A "no" from either wins, so a plate item never counts a cloth alt.
function LL:AltCanWearAppearance(f,class)
    local mask=self:ItemPermitsClass(f.id,class)
    local armor=self:ArmorTypePermitsClass(f,class)
    if mask==false or armor==false then return false end
    if mask==true or armor==true then return true end
    return nil
end
function LL:AltProfessionEligible(key,method,recipeOrSpell)
    if not self:AltMethodEnabled(key,method) then return false end
    local char=self.db.characters[key]
    local profession=METHOD_PROFESSION[method]
    if not profession then return false end
    if not (char.professions and char.professions[profession]) then return false end
    if method=="D" then return char.spells and char.spells[13262]==true end
    if recipeOrSpell then
        local rec=char.recipes and char.recipes[recipeOrSpell]
        return (rec and rec.learned and rec.disabled~=true)
            or (char.spells and char.spells[recipeOrSpell]==true) or false
    end
    return false -- having a profession without its recipe is insufficient
end
function LL:DirectTransmogRecipient(f)
    if not f then return nil end
    local current=self.CharacterKey and self:CharacterKey()
    local char=current and self.db and self.db.characters and self.db.characters[current]
    local liveClass
    if UnitClass then local _,id=UnitClass("player");liveClass=id end
    local class=(char and char.class) or liveClass
    local allowed=self:AltCanWearAppearance(f,class)
    -- The class-mask database can be absent for old/outlier gear. A current
    -- character that Blizzard explicitly says cannot use the appearance is
    -- not a verified collection recipient. Other eligible alts are tested next.
    if allowed~=false and C_TransmogCollection
        and type(C_TransmogCollection.GetItemInfo)=="function"
        and type(C_TransmogCollection.GetAppearanceInfoBySource)=="function" then
        local ok,_,source=pcall(C_TransmogCollection.GetItemInfo,f.link or ("item:"..f.id))
        if ok and type(source)=="number" and source>0 then
            local good,info=pcall(C_TransmogCollection.GetAppearanceInfoBySource,source)
            if good and type(info)=="table" and info.appearanceIsUsable==false then
                allowed=false
            end
        end
    end
    if allowed~=false and (not self.AltMethodEnabled or self:AltMethodEnabled(current,"T")) then
        return {name=current or "Current character",displayName=ShortName(current),
            class=class,classLabel=self:AltClassLabel(class),current=true}
    end
    if not self:CanTransferToAlt(f) or not self.db or not self.db.characters then return nil end
    local keys={}
    for key in pairs(self.db.characters) do keys[#keys+1]=key end
    table.sort(keys)
    for _,key in ipairs(keys) do
        local record=self.db.characters[key]
        if key~=current and record.class and self:AltMethodEnabled(key,"T")
            and self:AltCanWearAppearance(f,record.class)==true then
            return {name=key,displayName=ShortName(key),class=record.class,classLabel=self:AltClassLabel(record.class),current=false}
        end
    end
end
function LL:TokenTransmogRecipient(f,token)
    if not self.db or not token or type(token.rewards)~="table" then return nil end
    if type(self.AppearanceCollectionState)~="function" then return nil end
    local key=self.CharacterKey and self:CharacterKey()
    local characters=self.db.characters or {}
    local candidates={}
    local present=characters[key]
    local liveClass
    if UnitClass then local _,id=UnitClass("player");liveClass=id end
    local currentClass=(present and present.class) or liveClass
    if currentClass and (not self.AltMethodEnabled or self:AltMethodEnabled(key,"T")) then
        candidates[#candidates+1]={key=key or "Current character",class=currentClass,current=true}
    end
    if self:CanTransferToAlt(f) then
        for name,char in pairs(characters) do
            if name~=key and type(char)=="table" and char.class and self:AltMethodEnabled(name,"T") then
                candidates[#candidates+1]={key=name,class=char.class,current=false}
            end
        end
    end
    table.sort(candidates,function(a,b)
        if a.current~=b.current then return a.current end
        return a.key<b.key
    end)
    for _,candidate in ipairs(candidates) do
        -- An explicit mask on the token prevents choosing an excluded class.
        local tokenAllowed=self:ItemPermitsClass(f.id,candidate.class)
        if tokenAllowed~=false then
            for _,rewardID in ipairs(token.rewards) do
                -- Class-specific appearances must only be assigned to eligible
                -- recipients. Unknown class masks are not proof of eligibility.
                local rewardAllowed
                if self.TokenRewardPermitsClass then rewardAllowed=self:TokenRewardPermitsClass(token,rewardID,candidate.class)
                else rewardAllowed=self:ItemPermitsClass(rewardID,candidate.class) end
                if rewardAllowed==true then
                    local rewardLink=self.TokenRewardLink and self:TokenRewardLink(token,rewardID) or ("item:"..rewardID)
                    local collected=self:AppearanceCollectionState(rewardLink)
                    -- Keep missing looks for an eligible recipient even when
                    -- their other exchange items or currency are not on hand.
                    -- Economic quotes retain their immediate-cost checks.
                    local usable=self.TokenAppearanceEligibility
                        and self:TokenAppearanceEligibility(token,rewardID,candidate.current,candidate.key)
                    if token.kind=='exchange' and self.AltMethodEnabled and not self:AltMethodEnabled(candidate.key,'X') then usable=false end
                    if candidate.current and C_TransmogCollection
                        and type(C_TransmogCollection.GetItemInfo)=="function"
                        and type(C_TransmogCollection.GetAppearanceInfoBySource)=="function" then
                        local ok,_,source=pcall(C_TransmogCollection.GetItemInfo,rewardLink)
                        if ok and type(source)=="number" and source>0 then
                            local good,info=pcall(C_TransmogCollection.GetAppearanceInfoBySource,source)
                            if good and type(info)=="table" and info.appearanceIsUsable==false then
                                usable=false
                            end
                        end
                    end
                    if collected==false and usable then
                            return {name=candidate.key,displayName=ShortName(candidate.key),
                                class=candidate.class,classLabel=self:AltClassLabel(candidate.class),
                                current=candidate.current,rewardID=rewardID,
                                kind=token.kind}
                    end
                end
            end
        end
    end
end

end
