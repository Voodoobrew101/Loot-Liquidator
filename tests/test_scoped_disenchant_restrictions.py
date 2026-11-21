"""Catalog no-DE observations never become native all-variant flags."""
import hashlib,json,sys,tempfile
from pathlib import Path
sys.dont_write_bytecode=True
sys.path.insert(0,'tools')
import research_v3_no_disenchant as nd
checks=0
def check(ok,why):
    global checks
    assert ok,why
    checks+=1
def row(i,**kw):
    r={'id':i,'type':'noDisenchant','itemID':251786,'itemName':'Ever-Collapsing Void Fissure',
       'source':{'url':'https://www.wowdb.com/items/251786-ever-collapsing-void-fissure'},
       'quote':'Cannot be disenchanted','notes':'LIVE base catalog; base item level 197, build 63534. Do not infer all scaled/bonus variants are ineligible.','patch':'12.0.0'}
    r.update(kw);return r
with tempfile.TemporaryDirectory() as d:
    snap=Path(d);ev=snap/'research/v3/evidence/midnight';ev.mkdir(parents=True)
    native={'kind':'ItemSparseNO_DISENCHANT','scope':'all-item-variants','verified':True,
            'itemID':251799,'flags0':0x8000,'build':70961,'sourceSHA256':'a'*64}
    rows=[row('base'),row('unqualified',itemID=251787,notes='Current page says Cannot be disenchanted'),
          row('native',itemID=251799,nativeRestrictionProof=native),
          row('not-a-native-bit',itemID=251798,nativeRestrictionProof=dict(native,itemID=251798,flags0=524352)),
          row('prose-native',itemID=251797,notes='Verified native NO_DISENCHANT according to a catalog page'),
          row('same-base-copy')]
    text='\n'.join(json.dumps(r) for r in rows)+'\n'
    file=ev/'source.jsonl';file.write_text(text,encoding='utf-8')
    records,notes=nd.build_no_disenchant(snap);byid={r['itemID']:r for r in records}
    check(len(records)==5,'grouped item identities, no source records discarded')
    base=byid[251786]
    check(base['globalRestriction'] is False,'base catalog cannot prohibit every bonus variant')
    check(len(base['observations'])==2,'both original source lineages retained')
    ob=base['observations'][0]
    check(ob['scope']['itemLevel']==197 and ob['scope']['sourceBuild']==63534,'base scope retained')
    check(ob['scope']['sourcePatch']=='12.0.0','historical source patch retained')
    check(ob['sourceLine']==1 and ob['recordID']=='base' and ob['notes']==rows[0]['notes'],'exact source provenance retained')
    expected=hashlib.sha256(json.dumps(rows[0],sort_keys=True,ensure_ascii=False,separators=(',',':')).encode()).hexdigest()
    check(ob['rawSHA256']==expected,'original raw JSON hash retained')
    check(not byid[251787]['globalRestriction'],'unqualified current catalog is still not native proof')
    check(not byid[251797]['globalRestriction'],'the word native in prose cannot fabricate a flag')
    check(not byid[251798]['globalRestriction'],'0x80040 is not the0x8000 NO_DISENCHANT bit')
    check(byid[251799]['globalRestriction'],'explicit hashed verified native all-variant proof retained')
    check(file.read_text(encoding='utf-8')==text,'raw source unchanged')
# Real retained source caused the screenshot: its own scope must survive intake.
records,_=nd.build_no_disenchant(Path('database/research/v3-snapshot'))
matches=[r for r in records if r['itemID']==251786]
if matches:
    check(not matches[0]['globalRestriction'],'real trinket catalog row is not a native hard prohibition')
    check(any(o['scope'].get('itemLevel')==197 for o in matches[0]['observations']),'real trinket197 source scope retained')
print(f'SCOPED DISENCHANT SOURCE: {checks} checks passed')
