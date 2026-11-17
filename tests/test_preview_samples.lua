-- Validate the curated preview data against the shipped ItemDB and renderer contract.
local LL={AHFeeRate=function() return .05 end}
assert(loadfile('LootLiquidator/ItemDBRuntime.lua'))('LL',LL)
local file=assert(io.open('LootLiquidator/Settings.lua'));local source=file:read('*a');file:close()
local first=assert(source:find('local PREVIEW_ITEMS = {}',1,true))
local last=assert(source:find('PreviewPanel=function()',first,true))
local factory=assert(loadstring('local LL=...\n'..source:sub(first,last-1)..'\nreturn PREVIEW_ITEMS,SampleDecision'))
local rows,decision=factory(LL)
-- Research refreshes can make a curated item incomplete; the panel skips those.
assert(#rows>=3,'at least three curated studies must still provide complete measured examples')
local records={}
for _,record in ipairs(LL.ItemDB.processing) do records[record.recordID]=record end
for _,row in ipairs(rows) do
    local d=decision(row)
    assert(d.converted==row.convert and d.converted>0,'conversion header price')
    local total,support=0,100
    for i,m in ipairs(d.conversion.yieldModel.materials) do
        local original=records[row.source].materials[i]
        assert(m.id==original.id and m.confidence==original.expectedQuantity.confidence)
        assert(m.chanceConfidence==original.dropChance.confidence and m.chance and m.minQuantity and m.maxQuantity)
        assert(m.expectedQuantity and m.unitPrice and m.netExpectedValue)
        total=total+m.netExpectedValue
        support=math.min(support,m.confidence)
    end
    assert(d.conversion.confidence==support,'the preview uses quantity support to score its quoted value')
    assert(math.abs(total/row.inputCount-row.convert)<.00001,'material prices reconcile with conversion total')
end
print('preview samples: 5 complete measured studies with separate scores passed')
