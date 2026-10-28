-- Item decision filters. Saved in the existing account-wide LootLiquidatorDB.
-- Static DB2 data is stored separately and NEVER copied into SavedVariables.
local _, LL = ...
LL.ItemRestrictions = LL.ItemRestrictions or {}
local function State(self)
    if not self.db then return nil end
    self.db.ignoredItems = self.db.ignoredItems or {}
    return self.db.ignoredItems
end
local function Id(item)
    if type(item)=="number" then return item end
    if type(item)~="string" then return nil end
    return tonumber(item:match("item:(%d+)")) or tonumber(item)
end
function LL:IgnoreEntry(item)
    local id=Id(item)
    local s=State(self)
    return id and s and (s[id] or s[tostring(id)]) or nil
end
function LL:IsIgnoredAction(item, method)
    local entry=self:IgnoreEntry(item)
    if not entry then return false end
    if entry.all == true then return true end
    if (method=="T" or method=="Transmog") and entry.T==nil
        and entry.A==true and entry.D==true and entry.V==true and entry.P==true then
        return true
    end
    local normalized=({Auction="A",Disenchant="D",Vendor="V",Transmog="T",Mill="P",Prospect="P",
        Smelt="P",Recycle="P",Research="P",Combine="P",Split="P",Exchange="P",Craft="P"})[method] or method
    return entry[normalized] == true
end
function LL:SetIgnoreEntry(item, flags, name)
    local id=Id(item)
    if not id or id<=0 or id~=math.floor(id) then return false end
    local s=State(self)
    if not s then return false end
    if flags==nil then s[id]=nil;s[tostring(id)]=nil
    else
        local entry=s[id] or s[tostring(id)] or {}
        s[tostring(id)]=nil
        entry.A = flags.A == true; entry.D= flags.D == true
        entry.V = flags.V == true; entry.P = flags.P == true; entry.T = flags.T == true or (flags.T == nil
            and flags.A == true and flags.D == true and flags.V == true and flags.P == true)
        entry.all=nil
        if type(name)=="string" and name~="" then entry.name=name end
        s[id]=entry
    end
    if self.Invalidate then self:Invalidate() end
    return true
end
-- DB2 no-disenchant flags take priority over estimates, regardless of price.
function LL:ExternalDisenchantRestriction(item)
    local id=Id(item)
    if not id then return nil end
    if self.ItemRestrictions and self.ItemRestrictions[id] then
        return "Item database: Cannot be disenchanted"
    end
    return nil
end
