-- Source policy and read-only legacy history exports.
-- Complete cast capture and personal estimates are owned by CraftRecording.lua.
-- Legacy positive-only aggregates never enter the executable yield model.
local _, LL = ...
function LL:ProcessingDataMode(method)
    local db=LL.db or {}
    if method=="Disenchant" then return db.disenchantDataMode or 1 end
    if method=="Mill" then return db.millingDataMode or 1 end
    if method=="Prospect" then return db.prospectingDataMode or 1 end
    return db.otherConversionDataMode or 1
end
function LL:ProcessingMinimum() return math.max(1,tonumber(self.db and self.db.minPersonalSamples) or 30) end

function LL:ShowDisenchantStats()
    local history=self.db and self.db.disenchantLearning or {}
    local lines={}
    for key,bracket in pairs(history.brackets or {}) do
        lines[#lines+1]=key..": "..bracket.total.." samples (legacy export only)"
    end
    table.sort(lines)
    table.insert(lines,1,"Loot Liquidator disenchant observations: "..tostring(history.total or 0))
    return table.concat(lines,"\n")
end
function LL:ExportDisenchantData()
    local lines={}
    for _,bracket in pairs(self.db and self.db.disenchantLearning and self.db.disenchantLearning.brackets or {}) do
        for materialID,material in pairs(bracket.mats) do
            local histogram={}
            for quantity,count in pairs(material.quantityCounts or {}) do
                histogram[#histogram+1]=tostring(quantity)..'='..tostring(count)
            end
            table.sort(histogram)
            lines[#lines+1]=table.concat({bracket.expansion,bracket.quality,bracket.mode,bracket.skill or "",
                '"'..tostring(bracket.specialization):gsub('"','""')..'"',bracket.total,materialID,
                material.occurrences,material.quantity,material.min,material.max,
                '"'..table.concat(histogram,';')..'"'},",")
        end
    end
    table.sort(lines)
    table.insert(lines,1,"expansion,quality,gearType,skill,specialization,samples,materialID,occurrences,totalQuantity,minQuantity,maxQuantity,quantityHistogram")
    return table.concat(lines,"\n")
end

function LL:ExportProcessingData()
    local lines={"method,inputID,expansion,quality,inputsPerCast,samples,materialID,occurrences,totalQuantity,quantityHistogram"}
    for _,bracket in pairs(self.db and self.db.processingLearning and self.db.processingLearning.brackets or {}) do
        for materialID,material in pairs(bracket.mats or {}) do
            local histogram={}
            for quantity,count in pairs(material.quantityCounts or {}) do
                histogram[#histogram+1]=tostring(quantity).."="..count
            end
            table.sort(histogram)
            lines[#lines+1]=table.concat({bracket.method,bracket.inputID,bracket.expansion or "",bracket.quality or "",
                bracket.inputCount,bracket.total,materialID,material.occurrences,material.quantity,
                '"'..table.concat(histogram,";")..'"'},",")
        end
    end
    table.sort(lines,function(first,second)
        if first:find("^method,") then return true end
        if second:find("^method,") then return false end
        return first<second
    end)
    return table.concat(lines,"\n")
end

