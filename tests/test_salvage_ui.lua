-- Reproduce the client's uncached-name crash and exercise real load ordering.
local checks=0
local function check(value,message)assert(value,message);checks=checks+1 end
local function eq(a,b,message)check(a==b,(message or 'mismatch')..': '..tostring(a)..' ~= '..tostring(b))end
local frames={}
CreateFrame=function()
    local frame={events={}}
    function frame:RegisterEvent(event)self.events[event]=true end
    function frame:SetScript(_,callback)self.callback=callback end
    frames[#frames+1]=frame;return frame
end
local function emit(event,...)
    for _,frame in ipairs(frames)do if frame.events[event]then frame.callback(frame,event,...)end end
end
TRADESKILL_REAGENT_COUNT='%d/%d'
RETRIEVING_ITEM_INFO='Retrieving item information'
PROFESSIONS_ADD_SALVAGE='Select an item'
local craftCalls=0
C_TradeSkillUI={CraftSalvage=function()craftCalls=craftCalls+1 end,
    CraftRecipe=function()craftCalls=craftCalls+1 end}
local LL={}
assert(loadfile('LootLiquidator/Professions.lua'))('LL',LL)
eq(ProfessionsSalvageSlotMixin,nil,'do not invent or load Blizzard UI')

-- The same formatter and SetItem -> Update path as Blizzard's live salvage mixin.
local nativeCalls=0
local function NativeAllocationText(self)
    nativeCalls=nativeCalls+1
    local quantity=self.allocationItem and self.allocationItem:GetStackCount()
    if quantity then
        self:SetNameText(('%s %s'):format(
            TRADESKILL_REAGENT_COUNT:format(quantity,self.quantityRequired),
            self.allocationItem:GetItemName()))
        return true
    end
    return false
end
local function newSlot()
    local slot={quantityRequired=5,updates=0}
    for k,v in pairs(ProfessionsSalvageSlotMixin)do slot[k]=v end
    function slot:SetNameText(text)self.text=text end
    function slot:Update()
        self.updates=self.updates+1
        if not self:UpdateAllocationText()then self:SetNameText(PROFESSIONS_ADD_SALVAGE)end
        self.addIcon=self.allocationItem==nil
    end
    function slot:SetItem(item)
        self.allocationItem=item;self.buttonItemID=item:GetItemID();self:Update()
    end
    function slot:ClearReagent()self.allocationItem=nil;self:Update()end
    return slot
end
local function newItem(id,name,count)
    local item={id=id,name=name,count=count,requests=0,callbacks={}}
    function item:GetItemID()return self.id end
    function item:GetItemName()return self.name end
    function item:GetStackCount()return self.count end
    function item:ContinueOnItemLoad(callback)
        self.requests=self.requests+1;self.callbacks[#self.callbacks+1]=callback
    end
    function item:Loaded(name)
        self.name=name;local callbacks=self.callbacks;self.callbacks={}
        for _,callback in ipairs(callbacks)do callback()end
    end
    return item
end
ProfessionsSalvageSlotMixin={UpdateAllocationText=NativeAllocationText}
local existing=newSlot()
ProfessionsFrame={CraftingPage={SchematicForm={salvageSlot=existing}}}
local pigment=newItem(245807,nil,995)
local ok,err=pcall(existing.SetItem,existing,pigment)
check(not ok and tostring(err):find('string expected',1,true),'reproduce the original nil-name format error')
emit('ADDON_LOADED','Unrelated_Addon')
eq(existing.UpdateAllocationText,NativeAllocationText,'unrelated addon loads do not install hooks')
emit('ADDON_LOADED','Blizzard_ProfessionsTemplates')
check(existing.UpdateAllocationText~=NativeAllocationText,'patch an existing copied mixin')
check(ProfessionsSalvageSlotMixin.UpdateAllocationText~=NativeAllocationText,'patch future slots')

existing:SetItem(pigment)
eq(existing.text,'995/5 '..RETRIEVING_ITEM_INFO)
eq(existing.allocationItem,pigment,'preserve the actual selected item')
eq(existing.buttonItemID,245807);eq(existing.addIcon,false);eq(pigment.requests,1)
for _=1,20 do existing:Update()end
eq(pigment.requests,1,'one outstanding name request per selected item')
pigment.count=990;existing:Update();eq(existing.text,'990/5 '..RETRIEVING_ITEM_INFO)
local before=nativeCalls
pigment:Loaded('Powder Pigment')
eq(existing.text,'990/5 Powder Pigment');eq(nativeCalls,before+1,'loaded names use the native formatter')

local future=newSlot()
local emptyName=newItem(245808,'',0)
future:SetItem(emptyName);eq(future.text,'0/5 '..RETRIEVING_ITEM_INFO)
emptyName:Loaded('Powder Pigment R2');eq(future.text,'0/5 Powder Pigment R2')
local a,b=newItem(245807,nil,995),newItem(245808,nil,10)
future:SetItem(a);future:SetItem(b)
local updates=future.updates
a:Loaded('Old selection')
eq(future.updates,updates,'a stale callback cannot update the new selection')
eq(future.allocationItem,b);eq(future.buttonItemID,245808)
eq(future.text,'10/5 '..RETRIEVING_ITEM_INFO)
b:Loaded('Current selection');eq(future.text,'10/5 Current selection')

local cleared=newItem(245807,nil,5)
future:SetItem(cleared);future:ClearReagent();updates=future.updates
cleared:Loaded('Cleared selection')
eq(future.updates,updates);eq(future.text,PROFESSIONS_ADD_SALVAGE);eq(future.addIcon,true)
local sync=newItem(245807,nil,5)
function sync:ContinueOnItemLoad(callback)self.requests=self.requests+1;self.name='Already loaded';callback()end
future:SetItem(sync);eq(future.text,'5/5 Already loaded');eq(sync.requests,1)
local failed=newItem(245807,nil,5)
function failed:ContinueOnItemLoad(callback)self.requests=self.requests+1;callback()end
future:SetItem(failed)
for _=1,20 do future:Update()end
eq(failed.requests,1,'an immediate callback with no name cannot recurse or keep requesting')
eq(future.text,'5/5 '..RETRIEVING_ITEM_INFO)
failed.name='Later available';future:Update();eq(future.text,'5/5 Later available')
local moved=newItem(245807,nil,5)
function moved:ContinueOnItemLoad()error('invalid item location')end
check(pcall(future.SetItem,future,moved),'a vanished location cannot turn the name guard into another error')
future:ClearReagent();eq(future.text,PROFESSIONS_ADD_SALVAGE)
local noQuantity=newItem(245807,nil,nil)
future:SetItem(noQuantity);eq(future.text,PROFESSIONS_ADD_SALVAGE);eq(noQuantity.requests,0)

local wrapper=ProfessionsSalvageSlotMixin.UpdateAllocationText
local existingWrapper=existing.UpdateAllocationText
for _=1,10 do LL:InstallSalvageNameGuard()end
emit('PLAYER_LOGIN');emit('TRADE_SKILL_SHOW')
eq(ProfessionsSalvageSlotMixin.UpdateAllocationText,wrapper,'repeated installs do not stack wrappers')
eq(existing.UpdateAllocationText,existingWrapper)
-- Addon enabled after an existing profession slot was created.
ProfessionsSalvageSlotMixin={UpdateAllocationText=NativeAllocationText}
existing=newSlot();ProfessionsFrame.CraftingPage.SchematicForm.salvageSlot=existing
LL:InstallSalvageNameGuard()
existing:SetItem(newItem(245807,nil,995))
eq(existing.text,'995/5 '..RETRIEVING_ITEM_INFO)
eq(craftCalls,0,'the display guard cannot create or consume items')
eq(LL.db,nil,'the display guard does not change recorded results')
print('PASS: '..checks..' salvage UI nil-name, asynchronous load, selection, clear and load-order checks')
