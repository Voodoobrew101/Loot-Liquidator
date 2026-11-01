-- D1c end to end on the shipped database: research v3 baselines are valid ItemDB
-- records, nothing is counted twice, nothing is lost, and the addon values them.
local LL={}
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
GetBuildInfo=function()return '12.1.5','123456','Oct 29 2026',120105 end
GetTime=function()return 100 end
for _,file in ipairs({'ItemDBRuntime.lua','ProfessionModels.lua','Database.lua','ConversionEngine.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LootLiquidator',LL)
end
local passed=0
local function ok(cond,label) assert(cond,label);passed=passed+1 end
ok(LL:InitializeItemDB() and not LL.itemDBError,LL.itemDBError)
ok(LL:ValidateItemDB(LL.ItemDB),'shipped ItemDB validates')
local v3,covered,count={}, {},0
for _,r in ipairs(LL.ItemDB.processing) do
    if r.recordID:match('^evidence:v3:') then
        count=count+1;v3[r.recordID]=r
        for _,m in ipairs(r.materials) do covered[r.method..':'..tostring(r.inputItemID or r.gearKey)..':'..m.id]=r.recordID end
        -- The Python confidence port matches LL:RateConfidence (halved when the chance was worked out from an average).
        for _,m in ipairs(r.materials) do
            local f=m.dropChance
            local full=LL:RateConfidence(f.value*f.samples,f.samples)
            ok(f.confidence==full or (f.status=='provisional' and f.confidence==math.floor(full/2)),
                'confidence port for '..r.recordID..':'..m.id)
        end
    end
end
ok(count>50,'research v3 records ship')
-- No double counting: no older research row for a material v3 covers survives ...
for _,r in ipairs(LL.ItemDB.processing) do
    if r.recordID:match('^research:') then
        for _,m in ipairs(r.materials) do
            ok(not covered[r.method..':'..tostring(r.inputItemID or r.gearKey)..':'..m.id],
                'older row '..r.recordID..' would count v3 studies twice')
        end
    end
end
-- ... and nothing is lost: every replaced row names a v3 record that exists.
ok(#LL.ItemDB.buildReport.researchSuperseded>0,'some older rows were replaced')
for _,line in ipairs(LL.ItemDB.buildReport.researchSuperseded) do
    local by=line:match(' %-> (.+)$');ok(by and v3[by],'replaced by an existing v3 record: '..line)
end
-- Unlock-only gems from the old research (not in v3) are still there.
local conditional=false
for _,r in ipairs(LL.ItemDB.processing) do if r.recordID:match('^research:candidate:conditional:') then conditional=true end end
ok(conditional,'older rows for materials v3 does not carry are kept')
-- The addon values Saronite Ore (the owner's reference tooltip) from the v3 record.
LL.db={source_itemdb_enabled=true,source_itemdb_weight=100,source_personal_enabled=false,
    source_legacy_enabled=false,processingModes={M=1,P=1,S=1}}
LL:MigrateEvidenceSettings()
LL.CanUseConversion=function()return true,nil,'Tester - Realm'end
LL.ProfessionForMethod=function(_,m)return ({Mill='Inscription',Prospect='Jewelcrafting',Smelt='Mining'})[m]end
LL.ProcessingPlayerConditions=function()return {skill=450,effectiveSkill=450}end
LL.EligibleDisenchant=function()return false end
LL.GetOutputPrice=function()return 100 end
LL.ProfessionProgression=function()return {}end
local options=LL:ConversionOptions({id=36912,classID=7,count=20,expansionID=2})
local prospect
for _,o in ipairs(options) do if o.name=='Prospect' then prospect=o end end
ok(prospect and prospect.inputCount==5,'Saronite has a Prospect option')
local model=assert(prospect.yieldModel,'Saronite has a yield model')
local byID={} for _,m in ipairs(model.materials) do byID[m.id]=m end
ok(byID[36917] and math.abs(byID[36917].expectedQuantity-0.1792)<0.02,'Bloodstone average comes from v3 (~0.18 per prospect)')
ok(type(model.confidence)=='number' and model.confidence>0,'the option gets a confidence')
ok(type(prospect.value)=='number' and prospect.value>0,'the option gets a gold value')
-- D1c4: a research no-disenchant flag (Moth-Ridden Slippers, a Delver item the game-file
-- list lacks) reaches the lookup the disenchant check reads; game-file entries stay.
ok(LL.ItemRestrictions[220308]==true,'research no-disenchant flag is used')
ok(#LL.ItemDB.restrictions.researchNoDisenchant>100,'research no-disenchant flags ship')
for _,id in ipairs(LL.ItemDB.restrictions.noDisenchant) do
    if not LL.ItemRestrictions[id] then ok(false,'game-file no-disenchant entry lost: '..id) end
end
print('RESEARCH V3 RUNTIME: '..passed..' passed, 0 failed; '..count..' v3 records ship, '..
    #LL.ItemDB.buildReport.researchSuperseded..' older rows replaced')
