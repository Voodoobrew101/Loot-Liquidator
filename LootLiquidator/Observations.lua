-- Source policy and read-only legacy history exports.
-- Complete cast capture and personal estimates are owned by CraftRecording.lua.
-- Legacy positive-only aggregates never enter the executable yield model.
local _, LL = ...
local function Mode(method)
    local db=LL.db or {}
    if method=="Disenchant" then return db.disenchantDataMode or 1 end
    if method=="Mill" then return db.millingDataMode or 1 end
    if method=="Prospect" then return db.prospectingDataMode or 1 end
    return db.otherConversionDataMode or 1
end
function LL:ProcessingDataMode(method) return Mode(method) end
function LL:ProcessingMinimum() return math.max(1,tonumber(self.db and self.db.minPersonalSamples) or 30) end


function LL:ShowDisenchantStats()
    local d=self.db and self.db.disenchantLearning or {}
    local lines={}
    for key,b in pairs(d.brackets or {}) do
        lines[#lines+1]=key..": "..b.total.." samples (legacy export only)"
    end
    table.sort(lines)
    table.insert(lines,1,"Loot Liquidator disenchant observations: "..tostring(d.total or 0))
    return table.concat(lines,"\n")
end
function LL:ExportDisenchantData()
    local lines={}
    for _,b in pairs(self.db and self.db.disenchantLearning and self.db.disenchantLearning.brackets or {}) do
        for id,mat in pairs(b.mats) do
            lines[#lines+1]=table.concat({b.expansion,b.quality,b.mode,b.skill or "",'"'..tostring(b.specialization):gsub('"','""')..'"',
                b.total,id,mat.occurrences,mat.quantity,mat.min,mat.max,
                '"'..(function() local h={} for n,c in pairs(mat.quantityCounts or {}) do h[#h+1]=tostring(n)..'='..tostring(c) end table.sort(h) return table.concat(h,';') end)()..'"'},",")
        end
    end
    table.sort(lines)
    table.insert(lines,1,"expansion,quality,gearType,skill,specialization,samples,materialID,occurrences,totalQuantity,minQuantity,maxQuantity,quantityHistogram")
    return table.concat(lines,"\n")
end


function LL:ExportProcessingData()
    local lines={"method,inputID,expansion,quality,inputsPerCast,samples,materialID,occurrences,totalQuantity,quantityHistogram"}
    for _,b in pairs(self.db and self.db.processingLearning and self.db.processingLearning.brackets or {}) do
        for id,m in pairs(b.mats or {}) do
            local hist={}
            for q,n in pairs(m.quantityCounts or {}) do hist[#hist+1]=tostring(q).."="..n end
            table.sort(hist)
            lines[#lines+1]=table.concat({b.method,b.inputID,b.expansion or "",b.quality or "",
                b.inputCount,b.total,id,m.occurrences,m.quantity,'"'..table.concat(hist,";")..'"'},",")
        end
    end
    table.sort(lines, function(a,b) if a:find("^method,") then return true end
        if b:find("^method,") then return false end return a<b end)
    return table.concat(lines,"\n")
end

