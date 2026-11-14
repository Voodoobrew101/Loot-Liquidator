-- Synthetic API fixture, not evidence of current live-client eligibility.
local function loadDB(path)
    local holder={}; assert(loadfile(path))('LootLiquidator',holder)
    local map={};for _,r in ipairs(holder.ItemDB.tokenRewards) do map[r.tokenID]=r end
    return map
end
local guarded,original=loadDB(arg[1]),loadDB(arg[2])
local LL={db={characters={}}}
assert(loadfile('LootLiquidator/Tokens.lua'))('LootLiquidator',LL)
UnitLevel=function() return 90 end
C_Item={GetItemInfo=function() return 'Fixture','item:1',4,42,1 end}
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
local selected={[45661]=true,[45658]=true,[45643]=true}
local changes,count=0,0
for id,r in pairs(guarded) do
    count=count+1
    if selected[id] then
        changes=changes+1
        assert(r.kind=='open')
        assert(#r.rewards==7)
        if id~=45661 then
            assert(r.rewardSelection=='class' and r.sourceOrigin=='ATT')
            for _,reward in ipairs(r.rewards) do assert(r.rewardClassMasks[tostring(reward)]) end
        end
        assert(original[id].kind=='exchange' and original[id].costsComplete==false)
        assert(original[id].rewardSelection=='choice')
        local known=LL:TokenRedemptionCost({id=id},r,r.rewards[1],true)
        local held=LL:TokenRedemptionCost({id=id},original[id],r.rewards[1],true)
        assert(known.known and known.available and known.inputCount==1 and known.value==0)
        assert(not held.known and not held.available and held.inputCount==1)
    else
        assert(equal(r,original[id]),'Unrelated compiled token changed '..id)
    end
end
assert(count==307 and changes==3)
print('TOKEN SOURCE RUNTIME: 307 catalog records; three regressions; all unrelated entries equal')
