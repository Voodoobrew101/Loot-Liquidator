'use strict';
// F005 source-independent compact Lua audit. Input files are exact original Lua sources, not F002's derived JSON.
// Usage: node research/tests/v2/test_f005_v02_v08_direct_lua_identity_reparse.js <old-v0.2-itemdb.lua> <new-v0.8-itemdb.lua>
const fs=require('node:fs');
function parseRaw(lua){
 const k=lua.indexOf("local raw=");if(k<0)throw Error("missing local raw");
 let i=lua.indexOf("{",k),start=i,depth=0,q=false,esc=false;
 for(;i<lua.length;i++){const ch=lua[i];if(q){if(esc)esc=false;else if(ch==="\\")esc=true;else if(ch==='"')q=false;}else if(ch==='"')q=true;else if(ch==="{")depth++;else if(ch==="}"&&--depth===0){i++;break;}}
 if(depth!==0)throw Error("unclosed raw");const s=lua.slice(start,i);
 let out="",quote=false,escaped=false;for(const ch of s){if(quote){out+=ch;if(escaped)escaped=false;else if(ch==="\\")escaped=true;else if(ch==='"')quote=false;}else if(ch==='"'){quote=true;out+=ch;}else if(ch==="{")out+="[";else if(ch==="}")out+="]";else out+=ch;}
 return JSON.parse(out);
}
function audit(oldRows,newRows){
 let checks=0;const ok=(x,m)=>{checks++;if(!x)throw Error(m)},eq=(x,y,m)=>ok(JSON.stringify(x)===JSON.stringify(y),m+": "+JSON.stringify(x)+" != "+JSON.stringify(y));
 eq([oldRows.length,newRows.length],[976,1018],"source record counts");
 const old=new Map(oldRows.map(r=>[r[0],r])),now=new Map(newRows.map(r=>[r[0],r]));
 eq([old.size,now.size],[976,1018],"unique IDs");
 const retired=oldRows.filter(r=>!now.has(r[0])),added=newRows.filter(r=>!old.has(r[0]));
 eq([retired.length,added.length],[3,45],"source partition");
 const fields=[9,10,11,12];let changes=[0,0,0,0],upgrades=0,rankChanges=[],metadataChanged=0;
 for(const r of oldRows){const n=now.get(r[0]);if(!n)continue;
  for(let j=0;j<4;j++){let x=r[fields[j]][0],y=n[fields[j]][0];if(x!==y){changes[j]++;ok(typeof x==="number"&&Number.isFinite(x)&&y===false,"non-quarantine field mutation "+r[0]+" "+j);if(x===false&&typeof y==="number")upgrades++;}}
  if(r[7]!==n[7]||r[8]!==n[8]||r[2]!==n[2]||r[6]!==n[6]){rankChanges.push(r[0]);eq([r[2],n[2],r[6],n[6],r[7],n[7],r[8],n[8]],[0,0,5,5,1,false,r[8],r[8]],"fish rank identity "+r[0]);ok(r[0].startsWith("tsm:mill:200061:"),"unexpected identity change");}
 }
 eq(changes,[49,0,0,55],"direct source evidence quarantine");
 eq(upgrades,0,"no source promotions");
 eq(rankChanges.length,12,"fish input rank downgrades");
 const family=rankChanges.map(id=>old.get(id)).sort((a,b)=>a[4]-b[4]);
 eq(family.map(r=>r[4]),Array.from({length:12},(_,i)=>198412+i),"fish output IDs");
 for(const r of family){const n=now.get(r[0]);eq([r[3],n[3],r[9][0],r[12][0],n[9][0],n[12][0]],[200061,200061,0.2462,0.8615,false,false],"fish historical P/E quarantine "+r[0]);eq(r[8],n[8],"fish output rank unchanged");}
 const oldIds=["dragonflight:188658:192869:10","dragonflight:189143:192869:10","dragonflight:190311:192869:10"];
 const newIds=["tsm:prospect:188658:192869:L1204","tsm:prospect:189143:192869:L1242","tsm:prospect:190311:192869:L1280"];
 eq(retired.map(r=>r[0]).sort(),oldIds.slice().sort(),"only three retirements");
 for(let j=0;j<3;j++){const o=old.get(oldIds[j]),n=now.get(newIds[j]);ok(!!o&&!!n,"source pair exists "+j);eq([o[1],o[2],o[3],o[4],o[6],o[7],o[8]],[2,9,[188658,189143,190311][j],192869,5,[2,1,3][j],false],"old mapping identity "+j);
 eq([n[1],n[2],n[3],n[4],n[6],n[7],n[8]],[2,0,o[3],192869,5,o[7],1],"new non-equivalent mapping "+j);
 eq([o[9][0],o[12][0],n[9][0],n[12][0]],[0.0142,0.014,false,false],"no transferred proxy P/E "+j);
 ok(n[9][2]===0&&n[12][2]===0,"quarantine confidence zero "+j);
 }
 const id="retail12.0.5:prospect:36910:46849:globalmenace";const o=old.get(id),n=now.get(id);
 ok(!!o&&!!n,"tooltip record exists");eq([o[12][0],n[12][0]],[0.715,false],"gross input proxy not economic E");
 ok(String(n[12][3]).includes("GROSS_INPUT_PROXY_NOT_COMPLETED_CAST_E"),"gross input blocker");
 ok(Array.isArray(n[37])&&n[37][13]==="PROVISIONAL_TOOLTIP_ONLY_NOT_ECONOMIC","tooltip status");
 const oldNumeric=oldRows.reduce((a,r)=>a+fields.filter(k=>typeof r[k][0]==="number").length,0),newNumeric=newRows.reduce((a,r)=>a+fields.filter(k=>typeof r[k][0]==="number").length,0);
 eq([oldNumeric,newNumeric],[3610,3558],"direct source numeric totals");
 return {checks,oldRecords:oldRows.length,newRecords:newRows.length,retired:retired.length,added:added.length,fieldQuarantines:changes,fishRankChanges:rankChanges.length,nonEquivalentPairs:newIds,oldNumeric,newNumeric};
}
function mutants(oldRows,newRows){
 let rejected=0;function reject(name,fn){let a=oldRows.map(x=>JSON.parse(JSON.stringify(x))),b=newRows.map(x=>JSON.parse(JSON.stringify(x)));fn(a,b);try{audit(a,b)}catch(e){rejected++;return}throw Error("escaped "+name)}
 const by=(arr,id)=>arr.find(x=>x[0]===id);
 reject("retired rank",a=>by(a,"dragonflight:188658:192869:10")[8]=1);
 reject("successor rank",(_,b)=>by(b,"tsm:prospect:188658:192869:L1204")[8]=false);
 reject("successor expansion",(_,b)=>by(b,"tsm:prospect:189143:192869:L1242")[2]=9);
 reject("successor P",(_,b)=>by(b,"tsm:prospect:190311:192869:L1280")[9][0]=0.0142);
 reject("successor E",(_,b)=>by(b,"tsm:prospect:190311:192869:L1280")[12][0]=0.014);
 reject("fish rank",(_,b)=>by(b,"tsm:mill:200061:198412:L1998")[7]=1);
 reject("fish output rank",(_,b)=>by(b,"tsm:mill:200061:198412:L1998")[8]=2);
 reject("fish P",(_,b)=>by(b,"tsm:mill:200061:198413:L1999")[9][0]=0.2462);
 reject("tooltip economic E",(_,b)=>by(b,"retail12.0.5:prospect:36910:46849:globalmenace")[12][0]=0.715);
 reject("tooltip status",(_,b)=>by(b,"retail12.0.5:prospect:36910:46849:globalmenace")[37][13]="LIVE");
 reject("missing new row",(_,b)=>b.pop());
 reject("duplicate new ID",(_,b)=>b[1][0]=b[0][0]);
 reject("unexpected identity",(_,b)=>by(b,"tsm:mill:200061:198414:L2000")[2]=9);
 reject("unquarantine unrelated E",(_,b)=>by(b,"tsm:mill:200061:198414:L2000")[12][0]=0.8615);
 return rejected;
}
if(require.main===module){const [oldPath,newPath]=process.argv.slice(2);if(!oldPath||!newPath)throw Error('Provide BOTH pinned original Lua source paths; no derived reconciliation substitute');const a=parseRaw(fs.readFileSync(oldPath,'utf8')),b=parseRaw(fs.readFileSync(newPath,'utf8'));console.log(JSON.stringify({...audit(a,b),mutantsRejected:mutants(a,b)},null,2));}
module.exports={parseRaw,audit,mutants};
