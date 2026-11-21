"""Actual addon query/render checks for the finite native-positive addendum."""
from pathlib import Path
import argparse,json,sys
from hashlib import sha256

def main():
 p=argparse.ArgumentParser();p.add_argument('--research-root',type=Path,required=True);p.add_argument('--pipeline-root',type=Path,required=True);args=p.parse_args()
 args.research_root=args.research_root.resolve();args.pipeline_root=args.pipeline_root.resolve()
 sys.path.insert(0,str(args.pipeline_root.parent/'.tools/python313'));sys.path.insert(0,str(args.pipeline_root/'tools'))
 from lupa.lua51 import LuaRuntime
 from evidence_to_baselines import lua
 folder=args.research_root/'research/v3/evidence/master/backlog-catalogue-20261120'
 policy=json.loads((folder/'astroid-gnarm-cutoff-addendum-admitted-models.json').read_text(encoding='utf8'))
 review=json.loads((folder/'astroid-gnarm-cutoff-addendum-review.json').read_text(encoding='utf8'))
 l=LuaRuntime(unpack_returned_tuples=True)
 l.globals().ADDENDUM_FACTS=l.eval(lua(policy['facts']))
 l.globals().MODULE_ROOT=str((args.pipeline_root/'LootLiquidator').resolve()).replace('\\','/')
 result=l.execute('''
 local LL={db={tooltipDetail=3,showResearchDetails=true}}
 CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
 GetBuildInfo=function()return '12.1.5','70961','',120105 end
 GetItemInfo=function(id)return 'Source material '..id end
 for _,file in ipairs({'Database.lua','Observations.lua','ReviewedSourceFacts.lua','Badges.lua'})do
  assert(loadfile(MODULE_ROOT..'/'..file))('LL',LL)
 end
 LL.MarkupColor=function()return ''end
 LL.Money=function()error('Informational positive-event fact cannot be priced')end
 LL.ProfessionProgression=function()return {}end
 local checks,queryable,rendered,mean,range=0,0,0,0,0
 local function check(ok,why)checks=checks+1;assert(ok,why)end
 local option={name='Disenchant',profession='Enchanting',available=false,eligibleInput=false,
  value=nil,recipeID=0,yieldModel={materials={},confidence=0}}
 LL.ItemDB={reviewedSourceFacts={schemaVersion=1,facts=ADDENDUM_FACTS}}
 local ids={};for _,fact in ipairs(ADDENDUM_FACTS)do ids[fact.inputItemID]=true end
 for id in pairs(ids)do
  local got=LL:ReviewedProcessingSourceFacts({id=id,classID=4,quality=2,expansionID=11},option)
  local index={}for _,fact in ipairs(got)do index[fact.factID]=fact end
  for _,fact in ipairs(ADDENDUM_FACTS)do if fact.inputItemID==id then
   check(index[fact.factID]~=nil,'all exact-item native source facts are queryable in the full collection')
  end end
 end
 for _,fact in ipairs(ADDENDUM_FACTS)do
  LL.ItemDB.reviewedSourceFacts.facts={fact}
  local f={id=fact.inputItemID,classID=4,quality=2,expansionID=11,nativeInputVariant='different current target variant'}
  local got=LL:ReviewedProcessingSourceFacts(f,option,{skill=999,simulated=true})
  check(#got==1 and got[1].factID==fact.factID,'exact source fact queried')
  check(got[1].sourceContextOnly and got[1].targetProfileAdjusted==false,'source facts are not target calibration')
  check(got[1].nativeInputVariant==fact.nativeInputVariant,'native source variant retained unchanged')
  check(got[1].samples==0 and got[1].confidence0to100==0,'no observed N or target confidence invented')
  check(got[1].expectedQuantity==nil and got[1].dropChance==nil and got[1].chance==nil,'conditional source units never become unconditional fields')
  queryable=queryable+1
  local t={lines={}}
  function t:AddLine(s)self.lines[#self.lines+1]=s end
  function t:AddDoubleLine(a,b)self.lines[#self.lines+1]=a..' | '..b end
  LL:AppendRecommendationTooltip(t,{facts=f,conversionOptions={option}})
  local text=table.concat(t.lines,'\\n')
  check(text:find('Processing source facts',1,true),'actual addon tooltip section rendered')
  check(text:find('units per positive result',1,true),'positive-event unit is explicit')
  check(text:find('Confidence 0%',1,true),'uncertainty remains confidence0')
  check(got[1].sourceProfile.skill==nil and not text:find('skill 999',1,true),'selected target skill does not replace original source context')
  check(option.available==false and option.value==nil and #option.yieldModel.materials==0,'rendering cannot grant access or create EV')
  rendered=rendered+1
  if fact.metric=='conditionalMeanUnitsPerPositiveEvent'then mean=mean+1 else range=range+1 end
  LL.db.source_itemdb_enabled=false
  check(#LL:ReviewedProcessingSourceFacts(f,option)==0,'source preference excludes informational fact')
  LL.db.source_itemdb_enabled=nil;LL.db.disenchantDataMode=2
  check(#LL:ReviewedProcessingSourceFacts(f,option)==0,'personal-only mode excludes historical fact')
  LL.db.disenchantDataMode=nil;LL.db.professionTooltipProfiles={Enchanting='@hide'}
  check(#LL:ReviewedProcessingSourceFacts(f,option)==0,'hidden profession source facts stay hidden')
  LL.db.professionTooltipProfiles=nil
 end
 check(mean==837,'all native837 conditional means checked')
 return {checks=checks,queryable=queryable,rendered=rendered,conditionalMeans=mean,observedPositiveRanges=range}
 ''')
 receipt={str(k):v for k,v in result.items()}
 receipt.update(runtime='Lua5.1 (lupa.lua51)',moduleFiles=['Database.lua','Observations.lua','ReviewedSourceFacts.lua','Badges.lua'],
  nativePhysicalRows=837,historicalGroupRows=23,historicalGroupFactsEmitted=0,modelsEmitted=0,activeObservedSamplesAdded=0,
  allCurrentLookupRejectionsPreserved=True,sourceEvidenceMutated=False,liveGameActions=False,combinedGeneratedItemDBInclusionVerified=False,
  admittedArtifactSHA256=sha256((folder/'astroid-gnarm-cutoff-addendum-admitted-models.json').read_bytes()).hexdigest())
 path=folder/'astroid-gnarm-cutoff-addendum-support/runtime-validation.json'
 path.write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf8',newline='\n')
 print(json.dumps(receipt,sort_keys=True))
if __name__=='__main__':main()
