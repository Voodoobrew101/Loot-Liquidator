local transform=assert(loadfile('tools/disenchant_category_records.lua'))()
local checks=0
local function check(value,message) checks=checks+1;assert(value,message) end
local materials={{id=1,expectedQuantity={value=2.35,confidence=80,samples=20},
    dropChance={value=.75,confidence=70,samples=10},minQuantity={value=1},maxQuantity={value=4}}}
local source={recordID='exact:a',studyID='real-study',method='Disenchant',inputItemID=207160,
    inputCount=1,sourceKey='itemdb',materials=materials,referenceContextID='actual-profile',
    baselineProfile={skill=55},referenceConditions={specialization='actual'},samples=20}
local mapping={schemaVersion=1,items={[207160]={disposition='category',classID=4,rarity=4,expansionID=9,itemLevel=441}},
    bands={['gear:9:4:armor']={{id=310,min=1,max=999}},['gear:10:3:weapon']={{id=318,min=1,max=999}}},recordPolicies={}}
local result,report=transform({source},mapping)
local row=result[1]
check(report.converted==1 and #report.unmapped==0,'ordinary record converted')
check(row.inputItemID==nil and row.gearKey=='gear:9:4:armor','ordinary category no per-item eligibility')
check(row.recordID==source.recordID and row.studyID==source.studyID,'actual study lineage preserved')
check(row.materials==materials and source.materials==materials,'all numerical payloads preserved without copies')
check(row.referenceConditions==source.referenceConditions and row.baselineProfile==source.baselineProfile,
    'actual character conditions remain distinct')
check(source.inputItemID==207160 and source.gearKey==nil,'source record immutable')
check(row.categorySourceInputItemID==207160 and row.categoryNativeBandIDs[1]==310,'native/source provenance retained')
local explicit={};for k,v in pairs(source) do explicit[k]=v end
explicit.expansionID=10;explicit.inputRarity=3;explicit.inputClassID=2
result=transform({explicit},mapping)
check(result[1].gearKey=='gear:10:3:weapon','explicit source variant beats base identity')
mapping.recordPolicies['exact:a']={disposition='category',scope={expansionID=9},reason='Native era reviewed',sources={'https://example.com'}}
result=transform({source},mapping)
check(result[1].expansionID==9,'reviewed scope override honored')
mapping.recordPolicies['exact:a']={disposition='archive',reason='Unresolved historical band',sources={'https://example.com'}}
local archive
result,report,archive=transform({source},mapping)
check(#result==0 and report.archived==1 and archive[1].reason=='Unresolved historical band','unresolved version held offline, not made special')
mapping.recordPolicies['exact:a']=nil
mapping.represented={['exact:a']={'real-category'}}
result,report,archive=transform({source},mapping)
check(#result==0 and report.represented==1 and report.aliases['exact:a'][1]=='real-category','only actual represented lineages archived')
mapping.represented=nil
local fresh={{id=2,expectedQuantity={value=1.5,samples=7}}}
mapping.replacements={['exact:a']={recordID='exact:a',studyID='remainder-study',method='Disenchant',inputItemID=207160,materials=fresh}}
result,report=transform({source},mapping)
check(result[1].materials==fresh and report.replaced==1,'independent remainder retains existing compiler result')
mapping.replacements=nil
local proven={};for key,value in pairs(source) do proven[key]=value end
proven.categoryExceptionReason='Actual independently documented item-only behavior'
proven.categoryExceptionSources={'https://example.com/primary-proof'}
result,report=transform({proven},mapping)
check(report.exceptions==1 and result[1].inputItemID==207160 and result[1].gearKey==nil,
    'existing documented real exception retains exact scope')
proven.categoryExceptionSources={}
result,report=transform({proven},mapping)
check(report.exceptions==0 and result[1].inputItemID==nil,'reason alone cannot make ordinary gear special')
mapping.items[207160].disposition='unmapped'
result,report=transform({source},mapping)
check(#report.unmapped==1 and result[1]==source,'unmapped source explicitly reported, never silently dropped or made special')
print('DISENCHANT CATEGORY RECORDS: '..checks..' checks passed')
