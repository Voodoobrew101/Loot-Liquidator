-- A decisive current positive needs no legacy API read. Missing appearance
-- metadata and all negative/unknown/cross-source paths retain their provenance.
local checks=0
local function check(v,why)assert(v,why);checks=checks+1 end
local function eq(a,b,why)check(a==b,(why or '')..': '..tostring(a)..' ~= '..tostring(b))end
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
local LL={}
assert(loadfile('LootLiquidator/Tokens.lua'))('LootLiquidator',LL)
local current,legacy,alternate
local calls
local function reset()
 calls={item=0,current=0,legacy=0,filtered=0,all=0}
 current={itemAppearanceID=700,isCollected=true}
 legacy={appearanceID=700,appearanceIsCollected=false,sourceIsCollected=false}
 alternate=nil;issecretvalue=nil
 C_TransmogCollection={
  GetItemInfo=function()calls.item=calls.item+1;return 700,101 end,
  GetAppearanceSourceInfo=function(id)
   calls.current=calls.current+1;if id==101 then return current end;return alternate
  end,
  GetAppearanceInfoBySource=function(id)calls.legacy=calls.legacy+1;if id==101 then return legacy end end,
  GetAppearanceSources=function()calls.filtered=calls.filtered+1;return{}end,
  GetAllAppearanceSources=function()calls.all=calls.all+1;return alternate and{202}or{}end,
 }
end
local function expect(state,appearance,sourceOnly)
 local collected,source,id=LL:AppearanceCollectionState(sourceOnly and nil or'item:1',sourceOnly and 101 or nil)
 eq(collected,state,'collection state');eq(source,101,'original source identity');eq(id,appearance,'appearance identity')
end
reset();expect(true,700)
eq(calls.current,1);eq(calls.legacy,0,'decisive positive skips the legacy API')
eq(calls.filtered+calls.all,0,'decisive positive skips source enumeration')
reset();expect(true,700,true)
eq(calls.item,0,'explicit source does not request item metadata')
eq(calls.legacy,0,'current source metadata supplied its appearance identity')
reset();current={isCollected=true};expect(true,700)
eq(calls.legacy,0,'appearance already identified by the item API is sufficient')
reset();current={isCollected=true};expect(true,700,true)
eq(calls.legacy,1,'source-only positive retains legacy appearance metadata recovery')
reset();current.isCollected=false;expect(false,700)
eq(calls.legacy,1,'negative current result retains the legacy query')
eq(calls.filtered,1);eq(calls.all,1,'negative result retains full-source fallback')
reset();current=nil;legacy={sourceIsCollected=false};expect(nil,700)
eq(calls.legacy,1,'unknown appearance ownership remains unknown after legacy source-only false')
eq(calls.all,1)
reset();current.isCollected=false;legacy.appearanceIsCollected=true;expect(true,700)
eq(calls.legacy,1,'legacy affirmative still overrides a negative current source')
reset();current.itemAppearanceID=701;expect(false,700)
eq(calls.legacy,1,'a positive for another appearance is not decisive')
reset();current.isCollected=false;alternate={itemAppearanceID=700,isCollected=true};expect(true,700)
eq(calls.current,2,'another source of the same appearance is still checked')
eq(calls.legacy,1);eq(calls.all,1)
reset();current.isCollected=false;alternate={itemAppearanceID=701,isCollected=true};expect(false,700)
eq(calls.all,1,'different-appearance alternate cannot claim ownership')
reset();issecretvalue=function(value)return value==true end;expect(false,700)
eq(calls.legacy,1,'secret current positive cannot take the shortcut')
reset();C_TransmogCollection.GetAppearanceSourceInfo=function()calls.current=calls.current+1;error('metadata pending')end
legacy.appearanceIsCollected=true;expect(true,700)
eq(calls.legacy,1,'current API errors retain the legacy fallback')
reset();expect(true,700);current.isCollected=false;expect(false,700)
eq(calls.current,2,'later calls always reread current collection state')
eq(calls.legacy,1,'a later negative cannot reuse an earlier positive')
print('APPEARANCE POSITIVE SHORTCUT: '..checks..' checks passed')
