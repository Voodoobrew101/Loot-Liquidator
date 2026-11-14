"""Real archived DE receipts remain references, never rates. No new game data.
Python validates real compact bytes; a Lua codec bridge returns those exact
validated bytes (the WoW C_EncodingUtil implementation requires live QA).
"""
import base64
import copy
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import zlib

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / 'research/integration/measured-captures'
LUA = shutil.which('lua5.1') or '/workspace/.loot-liquidator-tools/lua/usr/bin/lua5.1'
SUFFIXES = ['82-skill-194-update', '82-skill-200-additional', '104-skill-199-casts']

SETUP = r'''
GetTime=function() return 0 end;time=function() return 1000 end
GetBuildInfo=function() return 'test','70783','',120105 end
UnitName=function() return 'Tester' end;GetRealmName=function() return 'Realm' end
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
hooksecurefunc=function() end;C_Timer={After=function() end}
LL={db={characters={},recordConversions=true,recordDisenchants=true}}
for _,name in ipairs({'ItemDBRuntime.lua','Database.lua','Professions.lua','Observations.lua','CraftRecording.lua','ImportedResults.lua','ConversionEngine.lua'}) do
 assert(loadfile('LootLiquidator/'..name))('LootLiquidator',LL)
end
LL.ItemDB={schemaVersion=1,version='archive-fixture',inputs={},processing={},mechanicRules={}}
assert(LL:InitializeItemDB());LL:MigrateEvidenceSettings()
LL:SetEvidenceSource('legacy',false);LL:SetEvidenceSource('reference',false)
function read(p) local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
function paste(n) return LL:ImportRecordedResults(read(arg[1]..'/'..n..'.json')) end
function held() return LL:HeldDisenchantResultsCount() end
function sets() local a={} for _,s in pairs(LL.db.importedResults and LL.db.importedResults.sets or {}) do a[#a+1]=s end return a end
function absent()
 assert(LL:ImportedEvidenceRecords('Disenchant:244752')==nil)
 assert(LL:ImportedEvidenceRecords('Disenchant:gear:11:3:armor')==nil)
 local f={id=244752,quality=3,classID=4,expansionID=11,itemLevel=165,reagentQuality=1}
 local option={name='Disenchant',inputCount=1,recipeID=13262}
 for _,ctx in ipairs({{effectiveSkill=82},{effectiveSkill=104},{simulated=true,effectiveSkill=82},{offline=true,effectiveSkill=82}}) do
  for _,mode in ipairs({1,2,3}) do assert(LL:ComputeEvidenceModel(f,option,nil,mode,ctx)==nil) end
 end
 LL:SetEvidenceSource('imported',false)
 assert(LL:ComputeEvidenceModel(f,option,nil,1,{effectiveSkill=82})==nil)
 LL:SetEvidenceSource('imported',true)
end
'''


def original(suffix):
    return json.loads((SOURCES / ('2026-11-07-pr49-' + suffix) / 'export-page-1.json').read_text())


def sample(suffix=SUFFIXES[0]):
    d = original(suffix)
    d['records'] = d['records'][:1]
    # Representative envelope, not a claim of full study completeness.
    d['retainedRecords'] = d['totalRetainedRecords'] = 1
    return d


class DisenchantArchiveTests(unittest.TestCase):
    def run_lua(self, code, files=None, raw=None):
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            for name, value in (files or {}).items():
                (folder / (name + '.json')).write_text(json.dumps(value))
            for name, value in (raw or {}).items():
                (folder / name).write_bytes(value)
            script = folder / 'test.lua'
            script.write_text(SETUP + code)
            result = subprocess.run([LUA, str(script), directory], cwd=ROOT, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_original_profile_separation_and_lossless_retention(self):
        self.run_lua(r'''
local ok,msg,c=paste('82');assert(ok,msg);assert(c.retainedOnly==1);assert(msg:find('reference only',1,true));absent()
ok,msg,c=paste('104');assert(ok,msg);assert(c.retainedOnly==1);absent()
assert(#sets()==2 and held()==2)
local skills={}
for _,s in ipairs(sets()) do
 local a=s.disenchantArchive;assert(a and s.referenceOnly)
 local context=assert(LL.DecodeImportJSON(a.contextJSON));skills[context.effectiveSkill]=true
 assert(context.operationStats==nil and context.fieldStatus.operationStats=='unknown')
 assert(not a.contextJSON:find('qualityRank',1,true))
 assert(a.inputJSON:find('hyperlink',1,true) and a.inputJSON:find('itemLevel',1,true))
 local n=0;for id,r in pairs(a.sourceRecords) do n=n+1;assert(LL.DecodeImportJSON(r).operationID==id) end;assert(n==1)
 if context.effectiveSkill==104 then assert(a.holdReason=='same-recipe-or-unknown-gap')
 else assert(a.holdReason=='applicability-unverified') end
end
assert(skills[82] and skills[104]);ok,msg,c=paste('82');assert(not ok and c.duplicate==1 and held()==2)
local exported=LL:ExportHeldDisenchantResults();assert(LL.DecodeImportJSON(exported).sampleKind=='REFERENCE_ONLY_ARCHIVE')
assert(not LL:ImportRecordedResults(exported));assert(held()==2)
''', {'82': sample(), '104': sample(SUFFIXES[2])})

    def test_missing_malformed_and_contradictory_contexts(self):
        changes = [
            lambda d,r,c,s:d.pop('contexts'), lambda d,r,c,s:d.pop('studies'),
            lambda d,r,c,s:d['contexts'].__setitem__(r['contextID'],None),
            lambda d,r,c,s:d['contexts'].__setitem__(r['contextID'],[]),
            lambda d,r,c,s:c.__setitem__('profession','Engineering'),
            lambda d,r,c,s:c.__setitem__('recipeID',13263),
            lambda d,r,c,s:c.__setitem__('effectiveSkill',104),
            lambda d,r,c,s:c.__setitem__('effectiveSkill',None),
            lambda d,r,c,s:c.__setitem__('simulated',True),
            lambda d,r,c,s:c['inputIdentity'][0].__setitem__('itemLevel',166),
            lambda d,r,c,s:c['inputIdentity'][0].__setitem__('hyperlink','wrong'),
            lambda d,r,c,s:c['inputIdentity'][0].__setitem__('itemID',244753),
            lambda d,r,c,s:s.__setitem__('build','70784'),
            lambda d,r,c,s:s.__setitem__('character','Other'),
            lambda d,r,c,s:c.__setitem__('operationStats',{}),
            lambda d,r,c,s:c['fieldStatus'].__setitem__('operationStats','measured'),
            lambda d,r,c,s:c.__setitem__('equipment',[]),
            lambda d,r,c,s:c.__setitem__('unknownPayload','x'*65537),
            lambda d,r,c,s:(r.__setitem__('nominalInputs',copy.deepcopy(r['inputs'])),r['inputs'][0].__setitem__('itemID',244753)),
            lambda d,r,c,s:s.__setitem__('coverageGaps',[]),
            lambda d,r,c,s:s.__setitem__('coverageVersion','2'),
        ]
        files={}
        for i,change in enumerate(changes):
            d=sample();r=d['records'][0];change(d,r,d['contexts'][r['contextID']],d['studies'][r['studyID']]);files[str(i)]=d
        self.run_lua('for i=0,'+str(len(changes)-1)+''' do
 local ok,msg,c=paste(tostring(i));assert(not ok,msg);assert(c.accepted==0 and c.damaged==1);absent();assert(held()==0)
end''', files)

    def test_gaps_late_duplicates_conflicts_and_own(self):
        base=sample();gap=copy.deepcopy(base);r=gap['records'][0];s=gap['studies'][r['studyID']]
        s['coverageGaps']['Disenchant:13262']={'reason':'missing classified receipt'}
        conflict=copy.deepcopy(base);r=conflict['records'][0];c=conflict['contexts'][r['contextID']]
        c['baseSkill']=86;c['effectiveSkill']=104
        changed_record=copy.deepcopy(base);changed_record['records'][0]['outputs'][0]['quantity']=2
        truncated=copy.deepcopy(base);truncated['studies'][r['studyID']]['truncated']=True
        global_gap=copy.deepcopy(base);global_gap['studies'][r['studyID']]['globalCoverageGap']='unknown recipe'
        self.run_lua('''
assert(paste('base'));local ok,msg,c=paste('gap');assert(ok,msg);assert(c.accepted==0 and c.updatedHolds==1 and held()==1)
assert(sets()[1].disenchantArchive.holdReason=='same-recipe-or-unknown-gap')
assert(sets()[1].disenchantArchive.warningStudyJSON~=sets()[1].disenchantArchive.studyJSON);assert(not paste('base'))
assert(sets()[1].disenchantArchive.holdReason=='same-recipe-or-unknown-gap')
ok,msg,c=paste('conflict');assert(ok,msg);assert(c.updatedHolds==1 and held()==1)
assert(sets()[1].disenchantArchive.conflictingMetadata);absent()
LL:ClearImportedResults();assert(paste('base'));assert(paste('changed'));assert(sets()[1].disenchantArchive.conflictingMetadata)
for _,name in ipairs({'truncated','global'}) do
 LL:ClearImportedResults();assert(paste(name));assert(sets()[1].disenchantArchive.holdReason=='incomplete-study');absent()
end
LL:ClearImportedResults();local id=LL.DecodeImportJSON(read(arg[1]..'/base.json')).records[1].operationID
LL.db.craftResearch={records={{operationID=id}}};ok,msg,c=paste('base');assert(not ok and c.own==1 and held()==0)
''', {'base':base,'gap':gap,'conflict':conflict,'changed':changed_record,'truncated':truncated,'global':global_gap})

    def test_same_paste_conflicting_duplicates(self):
        files={}
        for name,quantities in [('ab',[1,2]),('ba',[2,1]),('aba',[1,2,1])]:
            d=sample();r=d['records'][0];d['records']=[]
            for q in quantities:
                record=copy.deepcopy(r);record['outputs'][0]['quantity']=q;d['records'].append(record)
            files[name]=d
        self.run_lua("""
for _,name in ipairs({'ab','ba','aba'}) do
 LL:ClearImportedResults();local ok,msg,c=paste(name);assert(ok,msg)
 assert(c.accepted==1 and c.duplicate>=1 and held()==1)
 assert(sets()[1].disenchantArchive.conflictingMetadata);absent()
end
""",files)

    def test_legacy_persistence_and_export(self):
        self.run_lua('''
local old={method='Disenchant',gearKey='gear:11:3:armor',expansionID=11,inputRarity=3,inputClassID=4,
 inputCount=1,build='70783',casts=2,materials={[243602]={drops=2,total=2,min=1,max=1}},memberInputItemIDs={[244752]=true}}
LL.db.importedResults={version=1,sets={old=old},imports={},seen={old1=true,old2=true},seenCount=2}
-- Even a previously populated index cannot bypass the hold.
LL._importedIndex={build='70783',['Disenchant:244752']={{fixedReference=true}}}
local before=LL:ExportHeldDisenchantResults();absent();assert(held()==2)
assert(LL.db.importedResults.sets.old==old and LL.db.importedResults.seenCount==2)
assert(before==LL:ExportHeldDisenchantResults())
assert(loadfile('LootLiquidator/ImportedResults.lua'))('LL',LL);absent();assert(held()==2)
assert(before==LL:ExportHeldDisenchantResults());assert(LL:ClearImportedResults());assert(held()==0)
''')

    def test_full_original_compact_archives(self):
        raw={}
        for i,suffix in enumerate(SUFFIXES+['82-skill-97-clean']):
            folder=SOURCES/('2026-11-07-pr49-'+suffix)
            wire=(folder/'compact-export.json').read_bytes();packet=json.loads(wire)
            binary=base64.b64decode(packet['payload'],validate=True);decoded=zlib.decompress(binary)
            self.assertEqual(json.loads(decoded),original(suffix))
            self.assertEqual(len(decoded),packet['uncompressedBytes']);self.assertLess(len(wire),500000)
            self.assertLessEqual(len(packet['payload']),65536)
            raw[str(i)+'.json']=wire;raw[str(i)+'.raw']=decoded;raw[str(i)+'.bin']=binary
        self.run_lua(r'''
local expected={194,200,199,97};local total=0
for i=0,3 do
 local wire=read(arg[1]..'/'..i..'.json');local packet=assert(LL.DecodeImportJSON(wire))
end
'''.replace("local packet=assert(LL.DecodeImportJSON(wire))", """
 -- Decode the envelope only after registering the exact independently decoded codec bridge.
 local raw=read(arg[1]..'/'..i..'.raw');local binary=read(arg[1]..'/'..i..'.bin')
 C_EncodingUtil={DecodeBase64=function(payload)
  assert(wire:find(payload,1,true));return binary
 end,DecompressString=function(value,kind) assert(value==binary and kind==1);return raw end}
 local data=assert(LL.DecodeImportJSON(wire));assert(#data.records==expected[i+1])
 local ok,msg,c=LL:ImportRecordedResults(wire)
 if i==3 then assert(c.duplicate==97 and c.accepted==0)
 else assert(ok,msg);assert(c.retainedOnly==expected[i+1],msg);total=total+expected[i+1] end
 assert(held()==total);absent()
 if i==2 then
  assert(loadfile('LootLiquidator/Settings.lua'))('LL',LL)
  LL.ShowCopy=function() error('Must not send an oversized archive to the copy window') end
  local n,message=LL:ShowHeldDisenchantStatus();assert(n==593 and #message<65536)
  assert(message:find('SavedVariables',1,true) and message:find('export is not available',1,true))
 end
 ok,msg,c=LL:ImportRecordedResults(wire);assert(not ok and c.duplicate==expected[i+1]);assert(held()==total)
 """), raw=raw)

    def test_null_missing_identity_variants_and_ui(self):
        a=sample();b=copy.deepcopy(a);r=b['records'][0];r['operationID']+='-variant'
        c=b['contexts'][r['contextID']];c['unknownOptional']=None;c['inputIdentity'][0]['hyperlink']+='-variant';r['inputs'][0]['hyperlink']+='-variant'
        self.run_lua('''
assert(paste('a'));assert(paste('b'));assert(#sets()==2 and held()==2);absent()
local null=0
for _,s in ipairs(sets()) do if s.disenchantArchive.contextJSON:find('"unknownOptional":null',1,true) then null=null+1 end end
assert(null==1)
''',{'a':a,'b':b})
        text=(ROOT/'LootLiquidator/Settings.lua').read_text()
        self.assertIn('including previously imported results',text)
        self.assertIn('Held Disenchant imports',text)
        self.assertIn('REFERENCE_ONLY_ARCHIVE',(ROOT/'LootLiquidator/ImportedResults.lua').read_text())

if __name__=='__main__':
    unittest.main()
