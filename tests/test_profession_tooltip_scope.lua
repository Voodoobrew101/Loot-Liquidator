-- Actual native identities plus isolated saved recipes; no new drop claims.
GetBuildInfo=function()return '12.1.5','70961'end
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
local LL={db={characters={}}}
for _,file in ipairs({'ItemDBRuntime.lua','ProfessionCatalog.lua','ProfessionModels.lua','Professions.lua'})do
 assert(loadfile('LootLiquidator/'..file))('LL',LL)
end
local checks=0
local function check(value,why)checks=checks+1;assert(value,why)end
local function count(t)local n=0;for _ in pairs(t or{})do n=n+1 end;return n end
local function stats(p)local out={};for _,s in ipairs(LL:ProfessionSimulationStatOptions(p))do out[s.key]=true end;return out end
local function support(p)return LL:GetProfessionSimulationControlSupport(p,11)end
check(count(LL:ProfessionTooltipMethods())==10,'one shared ten-profession page/method map')
for _,p in ipairs({'Herbalism','Skinning','Fishing','Unknown'})do
 check(LL:ProfessionTooltipMethods(p)==nil,'unsupported profession has no editor method: '..p)
 local s=support(p);check(not s.skill and not next(s.nodes)and not next(s.stats),'unsupported profession exposes no controls')
end
local de=support('Enchanting')
for _,id in ipairs({'107646','107647','107648','107649'})do check(de.nodes[id],'actual disenchant node retained '..id)end
check(count(de.nodes)==4 and not next(de.stats),'DE retains exactly its four nodes and no crafting stats')
local jc=support('Jewelcrafting')
for _,id in ipairs({'106978','106979','106980','106981','106982','106983'})do check(jc.nodes[id],'prospecting skill and real ore-specific unlock retained '..id)end
for _,id in ipairs({'107057','107058','107056','107013','107012'})do check(not jc.nodes[id],'unrelated JC crafting/concentration node omitted '..id)end
check(jc.stats.resourcefulness and not jc.stats.multicraft and not jc.stats.ingenuity and not jc.stats.craftingSpeed,
 'Prospecting exposes resourcefulness only')
local mill=support('Inscription')
for _,id in ipairs({'109653','109655','109660'})do check(mill.nodes[id],'milling node retained '..id)end
for _,id in ipairs({'106184','106189','106190','109656','106277','106279'})do check(not mill.nodes[id],'unrelated Inscription branch omitted '..id)end
check(mill.stats.resourcefulness and not mill.stats.multicraft and not mill.stats.ingenuity and not mill.stats.craftingSpeed,
 'Milling exposes resourcefulness only')
check(not next(stats('Enchanting'))and count(stats('Jewelcrafting'))==1 and stats('Jewelcrafting').resourcefulness,
 'public stat choices use the same method scope')
check(stats('Alchemy').resourcefulness and stats('Alchemy').multicraft and count(stats('Alchemy'))==2,
 'actual Craft professions retain value stats without time/concentration controls')

-- The same native crafting effect becomes useful only for an actual learned
-- item-output recipe. No profession ownership or generic recipe is fabricated.
local native=LL.ItemDB.professionProfiles
local recipeID,recipe
for id,r in pairs(assert(loadfile('database/profession-profile-rules.lua'))().recipes)do
 if r.profession=='Alchemy'and r.expansionID==11 and r.supportsMulticraft==true
  and not r.salvage and #(r.outputIDs or{})>0 then recipeID,recipe=id,r;break end
end
check(recipeID~=nil,'actual native Alchemy material recipe fixture exists')
local inactive=support('Alchemy')
check(not inactive.skill and not next(inactive.nodes)and not next(inactive.stats),'unlearned Craft branches are not editable')
local saved={learned=true,outputID=recipe.outputIDs[1],outputCount=recipe.outputCount or 1,
 reagentSlots={{quantityRequired=1,alternatives={{itemID=1}}}}}
LL.db.characters.Fixture={recipes={[recipeID]=saved}}
LL:RestoreKnownProfessionRecipeMetadata()
local active=support('Alchemy')
check(active.skill and next(active.nodes)and active.stats.resourcefulness and active.stats.multicraft,
 'learned compatible Craft retains skill, recipe-specific nodes and both value stats')
saved.disabled=true
check(#LL:ProfessionTooltipOperations('Alchemy',11)==0 and not next(support('Alchemy').nodes),
 'disabled learned recipes cannot expose crafting controls')
saved.disabled=nil

-- Static source/aura semantics and recorded stat identities remain available;
-- the editor filter does not rewrite what was actually captured.
check(LL:ProfessionEffectAffectsTooltip({metric='craftingSpeed',scope={profession='Alchemy'}},'Alchemy',11,'Craft'),
 'raw effect/source scoping is independent of the narrower control filter')
check(not LL:ProfessionEffectSupportsTooltipControl({metric='craftingSpeed',scope={method='Craft'}},'Alchemy',11),
 'an obsolete time-only effect cannot expose a control')
check(not LL:ProfessionTooltipControlMetrics('Prospect').multicraft
 and LL:ProfessionTooltipControlMetrics('Craft').multicraft,'multicraft belongs only to Craft control scope')

local raw={specialization='106982=10,107057=20',stats={resourcefulness={rating=12,percent=5},
 multicraft={rating=20,percent=8},ingenuity={rating=30,percent=12},craftingSpeed={rating=40,percent=15}},
 learnedSpecializations={['106982']=true,['107057']=true},buffs={['1239755']=true}}
LL.db.characters.Fixture.researchProfiles={['Jewelcrafting:11']=raw}
local profile={enabled=true,skill=0,specialization=raw.specialization,stats=raw.stats,
 learnedSpecializations=raw.learnedSpecializations,buffs=raw.buffs,effectStates={['999999']={active=true}}}
check(LL:SetManualProfessionProfile('Fixture','Jewelcrafting',11,profile,true),'scoped manual profile is accepted')
local manual=LL.db.manualProfessionProfiles.Fixture['Jewelcrafting:11']
check(manual.specialization=='106982=10'and manual.learnedSpecializations['106982']
 and not manual.learnedSpecializations['107057'],'manual copies retain only supported points/learned nodes')
check(manual.stats.resourcefulness and count(manual.stats)==1 and count(manual.statAnchors)==1,
 'manual Prospect copy cannot retain multicraft/ingenuity/speed or their anchors')
check(not next(manual.buffs or{})and not next(manual.effectStates or{}),'irrelevant buffs/conditional states cannot survive a fork')
check(raw.specialization=='106982=10,107057=20'and raw.stats.craftingSpeed.percent==15
 and raw.learnedSpecializations['107057']and raw.buffs['1239755'],'raw scanned snapshot remains unchanged')
check(profile.specialization==raw.specialization,'setter filtering never mutates its caller source table')
check(not LL:SetManualProfessionProfile('Fixture','Herbalism',11,{enabled=true,skill=0},true),
 'unsupported manual pages cannot be recreated through the setter')

LL.db.manualProfessionProfiles.Fixture['Jewelcrafting:11']=profile
local invalidations=0;LL.Invalidate=function()invalidations=invalidations+1 end
LL:CleanupManualProfessionControls()
check(LL.db.manualProfessionProfiles.Fixture['Jewelcrafting:11'].specialization=='106982=10'
 and invalidations==0,'one quiet migration cleans existing saved manual copies without refresh recursion')
GetBuildInfo=function()return 'future','999999'end
check(LL:SetManualProfessionProfile('Fixture','Jewelcrafting',11,profile,true),'unknown-build source profile remains valid')
check(LL.db.manualProfessionProfiles.Fixture['Jewelcrafting:11'].specialization==raw.specialization,
 'unknown build/catalog cannot erase explicit saved point allocations')
print('PASS: '..checks..' operation-scoped controls, learned Craft, real unlocks, manual cleanup and raw-source preservation checks')
