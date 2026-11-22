-- Build-only adapter. A category contains independent source studies, not a
-- fabricated pooled distribution. Original records and material fields are
-- never mutated; offline source files remain the complete evidence archive.
local kinds={[2]='weapon',[4]='armor',[19]='profession'}
local function copy(record)
    local result={}
    for key,value in pairs(record) do result[key]=value end
    return result
end
local function integer(value)
    return type(value)=='number' and value==value and value>=0 and value<math.huge and value%1==0
end
local function policyFor(mapping,record,item)
    return mapping.recordPolicies and mapping.recordPolicies[record.recordID]
        or item and item.policy
end
local function exception(policy)
    if not policy or policy.disposition~='exception' or type(policy.reason)~='string'
        or not policy.reason:match('%S') then return false end
    for _,url in ipairs(policy.sources or {}) do
        if type(url)=='string' and url:match('^https://%S+$') then return true end
    end
    return false
end
local function levelBand(mapping,key,level)
    local lo,hi,ids
    for _,band in ipairs(mapping.bands and mapping.bands[key] or {}) do
        if not level or band.min<=level and level<=band.max then
            if not level and (band.min~=1 or band.max~=999) then return nil end
            lo=math.max(lo or band.min,band.min)
            hi=math.min(hi or band.max,band.max)
            ids=ids or {};ids[#ids+1]=band.id
        end
    end
    if not ids or lo>hi then return nil end
    table.sort(ids)
    return lo,hi,ids
end

return function(records,mapping)
    assert(type(mapping)=='table' and mapping.schemaVersion==1,'Unsupported disenchant item category mapping')
    local output,archive={},{}
    local report={converted=0,archived=0,exceptions=0,replaced=0,represented=0,
        categories={},unmapped={},aliases={}}
    for _,original in ipairs(records) do
        local record=original
        if record.method=='Disenchant' then
            local item=record.inputItemID and mapping.items[record.inputItemID]
            local policy=policyFor(mapping,record,item)
            local represented=mapping.represented and mapping.represented[record.recordID]
            if represented or policy and policy.disposition=='archive' then
                archive[#archive+1]={recordID=record.recordID,inputItemID=record.inputItemID,
                    reason=represented and 'Source lineages already represented by category evidence' or policy.reason,
                    sources=policy and policy.sources,representedBy=represented}
                report.archived=report.archived+1
                if represented then
                    report.represented=report.represented+1
                    report.aliases[record.recordID]=represented
                end
                record=nil
            else
                local replacement=mapping.replacements and mapping.replacements[record.recordID]
                if replacement then record=replacement;report.replaced=report.replaced+1 end
                if record.inputItemID then
                    local documented=exception(policy) and policy or {
                        disposition='exception',reason=record.categoryExceptionReason,
                        sources=record.categoryExceptionSources}
                    if exception(documented) then
                        record=copy(record)
                        record.categoryExceptionReason=documented.reason
                        record.categoryExceptionSources=documented.sources
                        report.exceptions=report.exceptions+1
                    elseif not item or item.disposition~='category' then
                        report.unmapped[#report.unmapped+1]=record.recordID
                    else
                        record=copy(record)
                        local scope=policy and policy.scope or {}
                        local expansion=scope.expansionID or record.expansionID or item.expansionID
                        local rarity=scope.inputRarity or record.inputRarity or item.rarity
                        local classID=scope.inputClassID or record.inputClassID or item.classID
                        assert(integer(expansion) and integer(rarity) and kinds[classID],
                            'Invalid disenchant category scope: '..record.recordID)
                        local key='gear:'..expansion..':'..rarity..':'..kinds[classID]
                        local level=scope.itemLevel or record.inputItemLevel or item.itemLevel
                        local lo,hi,ids=levelBand(mapping,key,level)
                        if not lo then
                            report.unmapped[#report.unmapped+1]=record.recordID
                        else
                            record.categorySourceInputItemID=record.inputItemID
                            record.inputItemID=nil
                            record.gearKey=key;record.isDisenchantCategory=true
                            record.expansionID=expansion;record.inputRarity=rarity;record.inputClassID=classID
                            record.categoryItemLevelMin=lo;record.categoryItemLevelMax=hi
                            record.categoryNativeBandIDs=ids
                            record.categoryVariantUnverified=true
                            if scope.expansionID and original.expansionID~=scope.expansionID then
                                record.categorySourceExpansionID=original.expansionID
                            end
                            -- Preserve actual context IDs/profiles/conditions, study IDs,
                            -- all numerical fields, source cohorts, and confidence.
                            report.converted=report.converted+1
                            report.categories[key]=(report.categories[key] or 0)+1
                        end
                    end
                end
            end
        end
        if record then output[#output+1]=record end
    end
    table.sort(report.unmapped)
    return output,report,archive
end
