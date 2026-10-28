-- Loot Liquidator profession snapshots and conservative cross-profession conversion discovery.
-- This module NEVER presumes that simply having a profession means a recipe is learned.
local ADDON, LL = ...
local PROF = {Disenchant="Enchanting",Mill="Inscription",Prospect="Jewelcrafting",
    Smelt="Mining",Tailor="Tailoring",Leatherwork="Leatherworking",Engineering="Engineering"}
local KNOWN_SPELLS = {Mill=51005,Prospect=31252,Disenchant=13262}
local function Now() return time and time() or 0 end
local function SpellKnown(id)
    if not id then return false end
    if IsPlayerSpell and IsPlayerSpell(id) then return true end
    if IsSpellKnown and IsSpellKnown(id) then return true end
    return false
end
local function PositiveInt(n) return type(n)=="number" and n>0 and n==math.floor(n) end

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
            and info.skillLevel>=0 then
            detail.skill=info.skillLevel
            detail.maxSkill=info.maxSkillLevel or detail.maxSkill
            detail.skillModifier=info.skillModifier or 0
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
    local family=self.DisenchantTables and self.DisenchantTables[exp]
    local expName=family and family.name
    local chosenID,detail
    for id,rec in pairs(char.details or {}) do
        local name=rec.name or ""
        local parent=rec.parentName or ""
        if (parent==profession or (parent=="" and char.professions
            and char.professions[profession]))
           and expName and (name:find(expName,1,true)
           or (exp==10 and name:find("Khaz Algar",1,true))) then
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
            lineID=chosenID,observed=Now()}
    elseif cached and cached.lineID==chosenID then
        spec=cached.specialization
    end
    self._activeResearchProfileCache[cacheKey]={at=now,skill=skill,
        spec=spec,lineID=chosenID}
    return skill,spec,chosenID
end

function LL:ProfessionForMethod(method) return PROF[method] end
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
    if mode==3 then return false,"Disabled in Professions & Alts" end
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
    if (mode~=4 or not self.AltMethodEnabled or self:AltMethodEnabled(key,letter))
        and (self:HasCurrentProfession(profession) or (method=="Disenchant" and self:CurrentHasEnchanting())) then
        if conversion.recipeID then
            local char=self.db.characters[key]
            local recipe=char.recipes and char.recipes[conversion.recipeID]
            if recipe and recipe.learned and recipe.disabled~=true then
                return true,nil,"Current character"
            end
            -- Learned recipe checked from actual spellbook as a fallback.
            if conversion.requiredSpell and SpellKnown(conversion.requiredSpell) then
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
                local methodKey=({Disenchant="D",Mill="M",Prospect="P",Smelt="S",
                    Craft="C",Recycle="R",Research="R"})[method] or "C"
                if (not self.AltMethodEnabled or self:AltMethodEnabled(name,methodKey))
                    and ((known and known.learned and not known.disabled) or spellAccess) then
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
                    local active=self.db.characters and self.db.characters[name]
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
    if not self.db or not C_TradeSkillUI or not C_TradeSkillUI.GetAllRecipeIDs
        or not C_TradeSkillUI.GetRecipeInfo or not C_TradeSkillUI.GetRecipeSchematic then return end
    local lineID,lineName,_,_,parentID,parentName=DisplayedSkillLine()
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
    if not self.db or not self.db.showProfessionHints then return {} end
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
    for name,char in pairs(self.db and self.db.characters or {}) do
        local p=char.professions and char.professions[profession]
        if p and (not self.AltMethodEnabled or self:AltMethodEnabled(name,({Enchanting="D",Inscription="M",Jewelcrafting="P",Mining="S"})[profession] or "C")) then out[#out+1]={name=name,skill=p.skill,maxSkill=p.maxSkill,details=char.details,faction=char.faction} end
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
