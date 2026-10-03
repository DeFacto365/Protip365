// Run with Playwright installed: node Docs/website-tools/check-localization.cjs <site-url> [screenshot-directory]
const fs=require('fs');
const path=require('path');
const {chromium}=require('playwright');
const {rows}=require('./localize-landing.cjs');
(async()=>{
 const b=await chromium.launch({headless:true,...(process.env.CHROME_PATH?{executablePath:process.env.CHROME_PATH}:{}),args:['--no-sandbox']});
 const base=process.argv[2]||'http://localhost:4317';
 const shots=process.argv[3];if(shots)fs.mkdirSync(shots,{recursive:true});
 for(const [lang,route]of[['en','/'],['fr','/fr/'],['es','/es/']]){
  const p=await b.newPage({javaScriptEnabled:false,viewport:{width:1440,height:1000}});
  const response=await p.goto(base+route,{waitUntil:'networkidle'});
  if(response.status()!==200)throw Error('HTTP '+response.status());
  const result=await p.evaluate(({lang,rows})=>{
   const texts=[...document.querySelectorAll('.phone')].flatMap(ph=>{
    const walker=document.createTreeWalker(ph,NodeFilter.SHOW_TEXT);let n,out=[];
    while(n=walker.nextNode())if(n.nodeValue.trim())out.push(n.nodeValue.trim());return out;
   });
   const translatedKeys=rows.filter(r=>r[0]!==r[lang==='fr'?1:2]).map(r=>r[0]);
   const leftovers=lang==='en'?[]:texts.filter(t=>translatedKeys.includes(t));
   return{lang:document.documentElement.lang,phones:document.querySelectorAll('.phone').length,screens:document.querySelectorAll('article.shot').length,leftovers,overflow:document.documentElement.scrollWidth>innerWidth,settings:document.querySelector('#screen-jobs .phone').innerText};
  },{lang,rows});
  if(result.lang!==lang||result.phones!==13||result.screens!==12||result.leftovers.length||result.overflow)throw Error(JSON.stringify(result));
  if(shots){
   for(const id of ['welcome','onbJob','onbWeek','reminder','log1','log2','saved','home','calendar','stats','jobs','statement']){
    await p.locator('#screen-'+id+' .phone').screenshot({path:path.join(shots,lang+'-'+id+'.png')});
   }
  }
  await p.setViewportSize({width:375,height:812});
  const overflow=await p.evaluate(()=>document.documentElement.scrollWidth>innerWidth);
  if(overflow)throw Error('Mobile overflow '+lang);
  console.log(JSON.stringify({lang,phones:13,screens:12,englishLeftovers:result.leftovers,desktopOverflow:false,mobileOverflow:false,settingsLanguage:result.settings.slice(-60)}));
  await p.close();
 }
 await b.close();
})().catch(e=>{console.error(e);process.exit(1);});
