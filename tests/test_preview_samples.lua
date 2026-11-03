-- Validate the curated preview data against the shipped ItemDB and renderer contract.
local LL={AHFeeRate=function() return .05 end}
assert(loadfile('LootLiquidator/ItemDBRuntime.lua'))('LL',LL)
local file=assert(io.open('LootLiquidator/Settings.lua'));local source=file:read('*a');file:close()
local first=assert(source:find('local PREVIEW_ITEMS = {}',1,true))
local last=assert(source:find('PreviewPanel=function()',first,true))
local factory=assert(loadstring('local LL=...\n'..source:sub(first,last-1)..'\nreturn PREVIEW_ITEMS,SampleDecision'))
local rows,decision=factory(LL)
assert(#rows==5,'all curated studies must remain complete and confident')
for _,row in ipairs(rows) do
    local d=decision(row)
    assert(d.converted==row.convert and d.converted>0,'conversion header price')
    assert(d.conversion.confidence>=85)
    local total=0
    for _,m in ipairs(d.conversion.yieldModel.materials) do
        assert(m.confidence>=85 and m.chance and m.minQuantity and m.maxQuantity)
        assert(m.expectedQuantity and m.unitPrice and m.netExpectedValue)
        total=total+m.netExpectedValue
    end
    assert(math.abs(total/row.inputCount-row.convert)<.00001,'material prices reconcile with conversion total')
end
print('preview samples: 5 complete high-confidence studies passed')
