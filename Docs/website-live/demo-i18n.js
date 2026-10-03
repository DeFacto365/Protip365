(() => {
 const dictionaries={};
 for(const [i,lang] of ['en','fr','es'].entries())dictionaries[lang]=Object.fromEntries(window.DEMO_ROWS.map(r=>[r[0],r[i]]));
 const locales={en:'en-CA',fr:'fr-FR',es:'es-ES'};
 const dayKeys=['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
 const shortDays={en:dayKeys,fr:['dim.','lun.','mar.','mer.','jeu.','ven.','sam.'],es:['dom.','lun.','mar.','mié.','jue.','vie.','sáb.']};
 const months=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
 const pattern=(lang,en,fr,es)=>({en,fr,es}[lang]);
 function text(raw,lang) {
  if(!raw||!dictionaries[lang])return raw;
  const lead=raw.match(/^\s*/)[0],tail=raw.match(/\s*$/)[0],key=raw.trim();
  if(!key)return raw;
  if(lang==='en')return raw;
  const dict=dictionaries[lang];
  let s=Object.hasOwn(dict,key)?dict[key]:key;
  if(s===key&&!Object.hasOwn(dict,key)){
   s=s.replace(/^tips you kept · (\d+) shifts logged$/,(_,n)=>pattern(lang,'',`pourboires gardés · ${n} quarts enregistrés`,`propinas netas · ${n} turnos registrados`));
   s=s.replace(/^(\d+)% of your (\$[\d,.]+) goal$/,(_,n,v)=>pattern(lang,'',`${n} % de ton objectif de ${v}`,`${n} % de tu meta de ${v}`));
   s=s.replace(/^([\d.]+) h worked$/,(_,n)=>pattern(lang,'',`${n} h travaillées`,`${n} h trabajadas`));
   s=s.replace(/^(\d+) shifts · ([\d.]+) h · total pay incl\. wage (\$[\d,.]+)$/,(_,n,h,v)=>pattern(lang,'',`${n} quarts · ${h} h · revenus avec salaire ${v}`,`${n} turnos · ${h} h · ingresos con salario ${v}`));
   s=s.replace(/^(This week|October|2026 so far) · tips$/,(_,period)=>(dict[period]||period)+pattern(lang,'',' · pourboires',' · propinas'));
   s=s.replace(/^Best day: (.+)$/,(_,day)=>pattern(lang,'','Meilleur jour : ','Mejor día: ')+(dict[day]||day));
   s=s.replace(/^(Tips were|Your tips are|Tips are) ([\d.]+)% of sales\.$/,(_,prefix,n)=>pattern(lang,'',`Les pourboires représentent ${n} % des ventes.`,`Las propinas son el ${n} % de las ventas.`));
   s=s.replace(/^([▲▼]) (\$[\d,.]+) (more|less) than your usual (\w+) at (.+)\.$/,(_,arrow,v,direction,day,employer)=>pattern(lang,'',`${arrow} ${v} de ${direction==='more'?'plus':'moins'} que ton ${dict[day]?.toLowerCase()||day} habituel chez ${employer}.`,`${arrow} ${v} ${direction==='more'?'más':'menos'} que tu ${dict[day]?.toLowerCase()||day} habitual en ${employer}.`));
   s=s.replace(/^Pay period /,pattern(lang,'','Période de paie : ','Período de pago: '));
   s=s.replace(/^(Server|Bartender|Busser|Host|Barback) · /,(_,role)=>(dict[role]||role)+' · ');
   s=s.replace(/ · usually /g,pattern(lang,'',' · habituellement ',' · normalmente '));
   s=s.replace(/^Demo: CSV export preview · (\d+) shifts$/,(_,n)=>pattern(lang,'',`Démo : aperçu CSV · ${n} quarts`,`Demo: vista previa CSV · ${n} turnos`));
   s=s.replace(/^Screen (\d+) of (\d+)$/,(_,n,total)=>pattern(lang,'',`Écran ${n} sur ${total}`,`Pantalla ${n} de ${total}`));
  }
  s=s.replace(/\b(Sun|Mon|Tue|Wed|Thu|Fri|Sat) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) (\d{1,2})\b/g,(_,d,m,n)=>new Intl.DateTimeFormat(locales[lang],{weekday:'short',month:'short',day:'numeric'}).format(new Date(2026,months.indexOf(m),+n)));
  if(dayKeys.includes(s))s=shortDays[lang][dayKeys.indexOf(s)];
  s=s.replace(/\$([\d,]+(?:\.\d+)?)/g,(_,n)=>new Intl.NumberFormat(locales[lang],{minimumFractionDigits:n.includes('.')?n.split('.')[1].length:0,maximumFractionDigits:2}).format(Number(n.replaceAll(',','')))+'\u00a0$');
  s=s.replace(/\b(\d+)\.(\d+)\b/g,'$1,$2');
  return lead+s+tail;
 }
 function localize(root,lang,weekStart=1) {
  root.lang=lang;
  const walker=document.createTreeWalker(root,NodeFilter.SHOW_TEXT);
  let n;
  while(n=walker.nextNode()){
   if(n.parentElement.closest('[data-user-text]'))continue;
   n.nodeValue=text(n.nodeValue,lang);
  }
  root.querySelectorAll('[placeholder],[aria-label]').forEach(el=>{
   for(const attr of ['placeholder','aria-label'])if(el.hasAttribute(attr))el.setAttribute(attr,text(el.getAttribute(attr),lang));
  });
  const letters={en:['S','M','T','W','T','F','S'],fr:['D','L','M','M','J','V','S'],es:['D','L','M','X','J','V','S']};
  root.querySelectorAll('.dow').forEach((el,i)=>el.textContent=letters[lang][(weekStart+i)%7]);
  // Only numeric input display changes. Dates/times and user notes stay machine-safe.
  if(lang!=='en')root.querySelectorAll('input[inputmode="decimal"]').forEach(el=>{el.value=el.value.replace('.',',');});
 }
 function chrome(lang) {
  document.documentElement.lang=lang;
  document.title=pattern(lang,'Interactive demo | ProTip365','Démo interactive | ProTip365','Demo interactiva | ProTip365');
  document.querySelector('.brand-sub').textContent=text('Interactive demo · ← back to home',lang);
  document.querySelector('.flow .hint').textContent=text('Tap anything in the phone. Logging a shift really updates the totals.',lang);
  document.querySelector('.flow').setAttribute('aria-label',text('User flow',lang));
  document.querySelector('.demo-language').setAttribute('aria-label',text('Language',lang));
  document.querySelector('.brand').href={en:'/',fr:'/fr/',es:'/es/'}[lang];
  document.querySelectorAll('.demo-language [data-act="lang"]').forEach(b=>{
   b.classList.toggle('on',b.dataset.v===lang);b.setAttribute('aria-pressed',String(b.dataset.v===lang));
  });
 }
 window.DemoI18n={text,localize,chrome};
})();
