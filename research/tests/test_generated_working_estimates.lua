-- Decode the generated file with Lua 5.1: preview completion must not fill raw evidence.
local db=assert(loadfile('research/proposed/itemdb.lua'))()
assert(db.schemaVersion=='0.2.0' and db.artifactStatus=='RESEARCH_ONLY_NOT_SHIPPED')
local fields={'dropChance','yieldMin','yieldMax','expectedQuantity'}
local slots,unknown,assumed=0,0,0
for _,r in ipairs(db.processing) do
    local w=assert(r.workingEstimate,'missing working estimate')
    assert(w.economicUse=='PREVIEW_ONLY' and w.normalizedVerified==false and w.evidenceFieldsPreserved==true)
    for _,key in ipairs(fields) do
        local n=w[key]
        assert(type(n)=='number' and n==n and n>=0 and n<math.huge,'nonfinite working metric')
        slots=slots+1
        if r[key].value==nil then
            unknown=unknown+1
            assert(w.fieldConfidence[key]==0,'missing evidence cannot gain confidence through imputation')
        end
    end
    assert(w.dropChance<=1 and w.yieldMin%1==0 and w.yieldMax%1==0 and w.yieldMin<=w.yieldMax)
    assert(w.expectedQuantity+1e-9>=w.dropChance*w.yieldMin and w.expectedQuantity<=w.dropChance*w.yieldMax+1e-9)
    if #(w.assumptions or {})>0 then assert(w.confidence==0);assumed=assumed+1 end
end
assert(#db.processing>0 and slots==#db.processing*4)
assert(unknown>0 and assumed>0,'fixture must exercise preserved gaps and assumed values')
print(('PASS: Lua 5.1 decodes %d mappings/%d complete working cells; %d evidence gaps preserved; %d assumed records'):format(#db.processing,slots,unknown,assumed))
