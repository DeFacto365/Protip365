const {chromium}=require('playwright');
const assert=require('node:assert/strict');
const screens=['welcome','onbJob','onbWeek','reminder','log1','log2','saved','home','calendar','stats','jobs','statement'];
const amount=s=>{
 const n=s.replace(/[$\s\u00a0\u202f]/g,'');
 return n.includes(',')&&!n.includes('.')?Number(n.replace(',','.')):Number(n.replaceAll(',',''));
};
async function check(page,lang){
 const state=await page.evaluate(lang=>{
  const keys=window.DEMO_ROWS.filter(r=>r[0]!==r[lang==='fr'?1:2]).map(r=>r[0]);
  const root=document.querySelector('#screen'),walker=document.createTreeWalker(root,NodeFilter.SHOW_TEXT),texts=[];let n;
  while(n=walker.nextNode())if(!n.parentElement.closest('[data-user-text]')&&n.nodeValue.trim())texts.push(n.nodeValue.trim());
  const leftovers=lang==='en'?[]:texts.filter(t=>keys.includes(t)||/\b(shifts logged|total pay incl|h worked|than your usual|of sales|Best day:|Pay period|usually)\b/.test(t));
  const employerWords=lang==='fr'?document.querySelector('.stage').innerText.match(/\bemplois?\b/gi):null;
  return{lang:document.documentElement.lang,leftovers,employerWords,overflow:document.documentElement.scrollWidth>innerWidth};
 },lang);
 assert.equal(state.lang,lang);assert.deepEqual(state.leftovers,[]);assert.equal(state.employerWords,null);assert.equal(state.overflow,false);
}
(async()=>{
 const browser=await chromium.launch({headless:true,...(process.env.CHROME_PATH?{executablePath:process.env.CHROME_PATH}:{}),args:['--no-sandbox']});
 const base=process.argv[2]||'http://localhost:4317';
 const page=await browser.newPage({viewport:{width:1440,height:1000}});
 await page.addInitScript(()=>{window.demoClicks=[];document.addEventListener('click',e=>{window.demoClicks.push({tag:e.target.tagName,text:e.target.textContent,act:e.target.dataset.act,v:e.target.dataset.v});},true);});
 const errors=[];page.on('pageerror',e=>{errors.push(e.message);console.error('Browser error:',e.stack);});
 for(const lang of ['en','fr','es']){
  await page.goto(base+'/prototype.html?lang='+lang,{waitUntil:'networkidle'});
  for(const id of screens){
   await page.locator('[data-screen="'+id+'"]').click();await check(page,lang);
   if(lang!=='en'&&id==='home')assert.ok(!(await page.locator('#notesTitle').innerText()).includes('Home answers'));
  }
  await page.locator('[data-screen="stats"]').click();
  for(const range of ['month','year','week']){await page.locator('[data-act="range"][data-v="'+range+'"]').click();await check(page,lang);}
  await page.locator('[data-screen="calendar"]').click();
  await page.locator('[data-act="calMonth"][data-v="9"]').click();await check(page,lang);
  await page.locator('[data-act="calMonth"][data-v="10"]').click();
  await page.locator('[data-act="calSel"][data-v="2026-10-03"]').click();await check(page,lang);
  await page.setViewportSize({width:375,height:812});await check(page,lang);
  await page.setViewportSize({width:1440,height:1000});
  await page.locator('[data-screen="home"]').click();
  const before=amount(await page.locator('.hero-card .big-total').innerText());
  await page.locator('#tabbar [data-go="log1"]').click();
  await page.locator('.job-pick').first().click();
  await page.locator('[data-bind="draft.start"]').fill('17:00');
  await page.locator('[data-bind="draft.end"]').fill('01:00');
  await page.locator('[data-act="brk"][data-v="30"]').click();
  await page.locator('#screen [data-go="log2"]').click();
  for(const [id,value]of[['cash','60,50'],['card','100,25'],['tipIn','20'],['tipOut','10,00']])await page.locator('#f_'+id).fill(value);
  assert.equal(amount(await page.locator('#liveNet').innerText()),170.75);
  await page.locator('[data-act="more"]').click();
  await page.locator('#f_sales').fill('1000');
  const note='Server, emploi, partido: café <note>';
  await page.locator('#f_note').fill(note);
  for(const selected of ['fr','es','en',lang]){
   await page.locator('.demo-language [data-v="'+selected+'"]').click();
   try {await page.waitForFunction(lang=>document.documentElement.lang===lang,selected,{timeout:3000});}
   catch(error){
    console.error('Language switch failed',lang,selected,await page.evaluate(()=>({url:location.href,lang:document.documentElement.lang,clicks:window.demoClicks.slice(-8),scrollX,scrollY})));
    await page.screenshot({path:'/home/user/workspace/demo-switch-failure.png'});
    await browser.close();throw error;
   }
   assert.equal(await page.locator('#f_note').inputValue(),note);
   assert.equal(amount(await page.locator('#liveNet').innerText()),170.75);
   await check(page,selected);
  }
  await page.locator('[data-act="save"]').click();
  assert.equal(amount(await page.locator('#screen .kpi .v').first().innerText()),170.75);await check(page,lang);
  await page.locator('[data-act="edit"]').click();await page.locator('#screen [data-go="log2"]').click();
  await page.locator('#f_cash').fill('61,50');await page.locator('[data-act="save"]').click();
  assert.equal(amount(await page.locator('#screen .kpi .v').first().innerText()),171.75);
  await page.locator('[data-act="undo"]').click();
  assert.equal(amount(await page.locator('.hero-card .big-total').innerText()),before);
  console.log(lang+': 12 screens, dynamic states, mobile, comma decimals, draft switching, save/edit/undo passed');
 }
 assert.deepEqual(errors,[]);await browser.close();
})().catch(e=>{console.error(e);process.exit(1);});
