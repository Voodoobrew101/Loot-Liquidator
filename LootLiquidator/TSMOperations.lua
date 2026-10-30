-- Read-only TradeSkillMaster v4 operation adapter.
-- TradeSkillMasterDB internals are NOT a public API and can change across versions.
-- All TSM price expressions are evaluated by TSM_API.GetCustomPriceValue.
local _, LL = ...
local function Number(n) return type(n)=="number" and n>0 and n<math.huge and n or nil end
local function SafeActiveProfile()
    if type(TSM_API)~="table" or type(TSM_API.GetActiveProfile)~="function" then return nil end
    local ok,v=pcall(TSM_API.GetActiveProfile,TSM_API)
    if ok and type(v)=="string" and v~="" then return v end
    ok,v=pcall(TSM_API.GetActiveProfile)
    return ok and type(v)=="string" and v~="" and v or nil
end
function LL:GetTSMOperationsDB()
    if self.db and self.db.enableTSMIntegration==false then
        return nil,"TSM integration disabled in Loot Liquidator"
    end
    local db=TradeSkillMasterDB
    if type(db)~="table" then return nil,"TSM saved operations not loaded" end
    if db["g@ @coreOptions@globalOperations"] then
        local shared=db["g@ @userData@sharedOperations"]
        return type(shared)=="table" and shared or nil,"TSM shared operations unavailable"
    end
    local profile=SafeActiveProfile()
    if not profile then return nil,"TSM active profile unavailable" end
    local ops=db["p@"..profile.."@userData@operations"]
    if type(ops)~="table" then return nil,"No operations found in active profile '"..profile.."'" end
    return ops,nil,profile
end
function LL:GetAuctionOperationNames()
    local db,reason=self:GetTSMOperationsDB()
    local ops=db and db.Auctioning
    local names={}
    if type(ops)=="table" then
        for name,value in pairs(ops) do
            if type(name)=="string" and type(value)=="table" then
                names[#names+1]=name
            end
        end
        table.sort(names)
    end
    return names,reason
end
function LL:GetTSMAuctionOperation(name)
    local db,err=self:GetTSMOperationsDB()
    local ops=db and db.Auctioning
    local entry=type(ops)=="table" and ops[name]
    if type(entry)=="table" then return entry end
    return nil,err or ("TSM Auctioning operation '"..tostring(name).."' not found")
end
local function EffectiveGroupOp(groups,path)
    for _=1,32 do
        local row=groups[path]
        local a=row and row.Auctioning
        if type(a)=="table" and (a.override or path=="") then
            return a[1]
        end
        if path=="" then break end
        path=path:match("^(.+)`[^`]+$") or ""
    end
end
function LL:GetAssignedTSMAuctionOperation(f)
    if type(TSM_API)~="table" or not f or not f.tsmString then return nil end
    local db=self:GetTSMOperationsDB()
    if not db then return nil end
    local profile=SafeActiveProfile()
    local root=TradeSkillMasterDB
    local groups=profile and root["p@"..profile.."@userData@groups"]
    local items=profile and root["p@"..profile.."@userData@items"]
    local path
    if type(TSM_API.GetGroupPathByItem)=="function" then
        local ok,result=pcall(TSM_API.GetGroupPathByItem,TSM_API,f.tsmString)
        if ok and type(result)=="string" then path=result end
        if not path then
            ok,result=pcall(TSM_API.GetGroupPathByItem,f.tsmString)
            if ok and type(result)=="string" then path=result end
        end
    end
    if not path and type(items)=="table" then
        path=items[f.tsmString] or (f.id and items["i:"..f.id])
    end
    local name=path and type(groups)=="table" and EffectiveGroupOp(groups,path)
    -- A default operation is a TSM fallback for items without explicit group ops.
    if not name and type(db.Auctioning)=="table" and db.Auctioning["#Default"] then
        name="#Default"
    end
    if type(name)=="string" and db.Auctioning and type(db.Auctioning[name])=="table" then
        return db.Auctioning[name],name
    end
end
function LL:ChosenTSMAuctionOperation(f)
    -- No fixed gear/reagent classification: arbitrary TSM group inheritance wins.
    -- Legacy v0.5 overrides are deliberately ignored (but retained in saved
    -- variables) because their settings UI is gone and could otherwise trap users.
    local op,name=self:GetAssignedTSMAuctionOperation(f)
    if op then return op,name,false,nil end
    local fallback=self.db and self.db.tsmFallbackOperation
    if fallback and fallback~="@none" then
        local fallbackOp,reason=self:GetTSMAuctionOperation(fallback)
        return fallbackOp,fallback,true,reason
    end
    return nil,nil,false,"No assigned TSM auctioning operation"
end
function LL:EvalTSMOperationExpression(expression,itemString,countField)
    if type(expression)=="number" then return Number(expression) end
    if type(expression)~="string" or expression=="" then return nil end
    if countField then
        local literal=tonumber(expression)
        if literal then return literal end
    end
    return self:Price(expression,itemString)
end
local function ChosenPolicy(name,low,normal,maxPrice)
    if name=="minPrice" then return low end
    if name=="normalPrice" then return normal end
    if name=="maxPrice" then return maxPrice end
    return nil
end
function LL:QuoteTSMAuctionOperation(f, op)
    local key=f.tsmString
    local opMin=self:EvalTSMOperationExpression(op.minPrice,key)
    local normal=self:EvalTSMOperationExpression(op.normalPrice,key)
    local opMax=self:EvalTSMOperationExpression(op.maxPrice,key)
    if not (opMin and normal and opMax) then
        return nil,"TSM operation minimum/normal/maximum expression invalid or missing"
    end
    if opMin>opMax then return nil,"TSM operation minimum above maximum" end
    local cap=self:EvalTSMOperationExpression(op.postCap,key,true)
    if cap==nil then return nil,"TSM post cap unknown (cannot verify posting permitted)" end
    if cap<1 then return nil,"TSM operation post cap disables posting" end
    local bid=self:Price("dbminbuyout",key)
    local undercut=op.undercut and (self:EvalTSMOperationExpression(op.undercut,key,true) or 0) or 0
    local ask
    if not bid then
        ask=normal
    elseif bid-undercut<opMin then
        ask=ChosenPolicy(op.priceReset,opMin,normal,opMax)
        if not ask then return nil,"Competition below TSM minimum; operation skips posting" end
    elseif bid-undercut>opMax then
        ask=ChosenPolicy(op.aboveMax,opMin,normal,opMax)
        if not ask then return nil,"Competition above TSM maximum; operation skips posting" end
    else
        ask=bid-undercut
    end
    return math.max(opMin,math.floor(ask+0.5)),nil
end
