-- Shared direct observations must reach ItemDB without becoming invented rates.
local LL={}
CreateFrame=function() return {RegisterEvent=function() end,SetScript=function() end} end
GetBuildInfo=function() return 'test','70783','',120105 end
GetTime=function() return 100 end
for _,file in ipairs({'ItemDBRuntime.lua','ProfessionModels.lua','Database.lua','ConversionEngine.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LootLiquidator',LL)
end
LL.db={};LL:MigrateEvidenceSettings();assert(LL:InitializeItemDB(),LL.itemDBError)
local records,casts=0,0
local row
for _,r in ipairs(LL.ItemDB.processing) do
    if r.sourceKind=='direct-player-cast-observation' then
        records=records+1;casts=casts+r.observedOperations
        assert(r.observationOnly and r.studyCoverageIncomplete and #r.sourceRecordIDs==r.observedOperations)
        for _,m in ipairs(r.materials) do
            for _,key in ipairs({'expectedQuantity','dropChance','minQuantity','maxQuantity'}) do
                assert(m[key].value==nil and m[key].status=='unknown')
                assert(LL:EvidenceReliability(m[key],r)==0,'histogram is not a rate estimate')
            end
        end
        if r.inputItemID==275544 then row=r end
    end
end
assert(records==38 and casts==42,'complete unique owner captures reach the shared database')
assert(row and row.materials[1].id==243606,'observed Dawn Crystal identity retained')
-- Isolate direct captures: they cannot produce a numerical valuation alone.
LL.ItemDB.processing={row};assert(LL:InitializeItemDB())
LL.db.source_legacy_enabled=false;LL.db.source_reference_enabled=false
LL.db.source_imported_enabled=false;LL.db.source_personal_enabled=false
local model=LL:ComputeEvidenceModel({id=275544,quality=4,classID=2,expansionID=11},
    {name='Disenchant',recipeID=13262,inputCount=1},nil,1,{})
if model then
    for _,m in ipairs(model.materials) do
        assert(m.expectedQuantity==nil and m.chance==nil,'observed stacks cannot imply rates')
    end
    LL.GetOutputPrice=function() return 10000 end
    assert(LL:ValueProcessingModel(model,0,true)==nil,'candidate identities alone cannot imply gold value')
end
print('PASS: 38 shared direct capture identities from 42 casts; no inferred rates or gold value')
