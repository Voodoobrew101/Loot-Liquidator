-- Account-wide per-character participation.  Rules are only consulted when
-- considering a DIFFERENT character; the current player is never disabled.
local _, LL = ...
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
-- Shared per-skill behavior for the compact Professions & Alts menu.
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
    if not entry or not ({T=true,D=true,M=true,P=true,S=true,C=true,R=true,X=true})[method] then return false end
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
    local allowed=self:ItemPermitsClass(f.id,class)
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
            and self:ItemPermitsClass(f.id,record.class)==true then
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
                if self:ItemPermitsClass(rewardID,candidate.class)==true then
                    local collected=self:AppearanceCollectionState("item:"..rewardID)
                    local usable=true
                    if candidate.current and C_TransmogCollection
                        and type(C_TransmogCollection.GetItemInfo)=="function"
                        and type(C_TransmogCollection.GetAppearanceInfoBySource)=="function" then
                        local ok,_,source=pcall(C_TransmogCollection.GetItemInfo,"item:"..rewardID)
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
