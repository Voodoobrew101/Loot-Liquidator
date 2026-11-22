-- Repeated unrelated aura events must not walk the immutable native trees.
local frames={}
CreateFrame=function()
    local f={events={}}
    function f:RegisterEvent(e)self.events[e]=true end
    function f:SetScript(_,fn)self.onEvent=fn end
    frames[#frames+1]=f;return f
end
GetBuildInfo=function()return '12.1.5','70961','',120105 end
local LL={db={characters={Player={professions={Enchanting=true}}}}}
assert(loadfile('LootLiquidator/Professions.lua'))('LL',LL)
assert(loadfile('LootLiquidator/ProfessionModels.lua'))('LL',LL)
LL.CharacterKey=function()return'Player'end
local visits,reads,invalidations=0,0,0
local active,stacks=false,1
local nativeFilter=LL.ProfessionEffectAffectsTooltip
LL.ProfessionEffectAffectsTooltip=function(self,...)
    visits=visits+1;return nativeFilter(self,...)
end
LL.Invalidate=function()invalidations=invalidations+1 end
C_UnitAuras={GetPlayerAuraBySpellID=function(id)
    reads=reads+1
    if id==5010 and active then return{spellId=id,applications=stacks}end
end}
local function profiles(id)
    return {['Enchanting:11']={nodes={[1]={pointEffects={
        {metric='skill',scope={method='Disenchant'},condition={spellIDs={id}}},
        {metric='multicraft',scope={method='Craft'},condition={spellIDs={5011}}}}}}}}
end
LL.ItemDB={version='fixture',professionProfiles={revision='one',profiles=profiles(5010)}}
local de=LL:KnownProfessionAuraIDs('Enchanting',11,'Disenchant')
assert(de['5010'] and not de['5011'] and not de['1235733'],'operation scope stays isolated')
assert(LL:RefreshProfessionAuraFingerprint(),'initial live fingerprint is established')
local walked=visits
local event
for _,frame in ipairs(frames)do if frame.events.UNIT_AURA then event=frame.onEvent end end
assert(event,'the live event path must be exercised')
for i=1,500 do event(nil,'UNIT_AURA','player')end
assert(visits==walked,'irrelevant aura events must not traverse native effects again')
assert(reads>500 and invalidations==0,'live state is reread without false quote invalidations')
active=true;event(nil,'UNIT_AURA','player')
assert(invalidations==1,'real buff gain refreshes quotes immediately')
event(nil,'UNIT_AURA','player');assert(invalidations==1,'unchanged state remains cached')
stacks=2;event(nil,'UNIT_AURA','player');assert(invalidations==2,'real stack change refreshes quotes')
active=false;event(nil,'UNIT_AURA','player');assert(invalidations==3,'expiration refreshes quotes')
assert(visits==walked,'buff changes reuse the immutable ID set too')
local oldReads=reads;event(nil,'UNIT_AURA','target');assert(reads==oldReads,'foreign unit updates stay ignored')
LL.ItemDB.professionProfiles.profiles=profiles(5020)
de=LL:KnownProfessionAuraIDs('Enchanting',11,'Disenchant')
assert(de['5020'] and not de['5010'] and visits>walked,'profile replacement rebuilds the scoped ID set')
LL.ItemDB.professionRules={{profession='Enchanting',expansionID=11,method='Disenchant',
    condition={spellIDs={5030}}}}
de=LL:KnownProfessionAuraIDs('Enchanting',11,'Disenchant')
assert(de['5030'],'new rule arrays invalidate the ID cache')
LL.ItemDB.professionRules={}
de=LL:KnownProfessionAuraIDs('Enchanting',11,'Disenchant')
assert(not de['5030'],'removed rule IDs cannot remain captured')
LL.ItemDB={version='two',professionProfiles={revision='two',profiles=profiles(5040)}}
de=LL:KnownProfessionAuraIDs('Enchanting',11,'Disenchant')
assert(de['5040'] and not de['5020'],'a reloaded database cannot retain old IDs')
print('PASS: immutable aura ID reuse, live gain/stack/expiration, source scope and database reload')
