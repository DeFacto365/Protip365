// Rebuild static phone mockups from the English version, preserving translated page copy.
// Usage: node Docs/website-tools/localize-landing.cjs <site-directory> <local-server-url>
const fs = require('fs');
const path = require('path');
const rows = [
['Hi Maya','Salut Maya','Hola Maya'],
['Your tips this week','Tes pourboires cette semaine','Tus propinas esta semana'],
['tips you kept · 3 shifts logged','pourboires gardés · 3 quarts enregistrés','propinas netas · 3 turnos registrados'],
['46% of your $600 goal','46 % de ton objectif de $600','46 % de tu meta de $600'],
['Add my tips','Ajouter mes pourboires','Añadir mis propinas'],
['This month','Ce mois-ci','Este mes'],
['tips you kept','pourboires gardés','propinas netas'],
['Tips / hour','Pourboires / heure','Propinas / hora'],
['wage + tips','salaire + pourboires','salario + propinas'],
['Recent shifts','Quarts récents','Turnos recientes'],
['Home','Accueil','Inicio'],['Calendar','Calendrier','Calendario'],['Stats','Statistiques','Estadísticas'],['Me','Moi','Yo'],
['Your shifts.','Tes quarts.','Tus turnos.'],['Your tips.','Tes pourboires.','Tus propinas.'],
['Tips, hours and pay for all your jobs in one place. Free, private, and fast.','Pourboires, heures et revenus de tous tes emplois au même endroit. Gratuit, privé et rapide.','Propinas, horas e ingresos de todos tus trabajos en un solo lugar. Gratis, privado y rápido.'],
['Get started','Commencer','Empezar'],
['I already use another app','J’utilise déjà une autre appli','Ya uso otra app'],
['No account needed. Your data stays on your phone.','Aucun compte requis. Tes données restent sur ton téléphone.','No necesitas una cuenta. Tus datos quedan en tu teléfono.'],
['Where do you work?','Où travailles-tu ?','¿Dónde trabajas?'],
['Employer name','Nom de l’employeur','Nombre del empleador'],
['Your role','Ton poste','Tu puesto'],
['Server','Service en salle','Servicio de mesas'],['Bartender','Service au bar','Servicio de bar'],
['Busser','Aide en salle','Ayudante de sala'],['Host','Accueil','Recepción'],['Barback','Aide au bar','Ayudante de bar'],
['Hourly wage','Salaire horaire','Salario por hora'],
['Sample rate. Enter the hourly wage for this job.','Taux d’exemple. Saisis le salaire horaire de cet emploi.','Tarifa de ejemplo. Introduce el salario por hora de este trabajo.'],
['Colour','Couleur','Color'],['Continue','Continuer','Continuar'],
['Use sample jobs for the demo','Utiliser les emplois de démonstration','Usar los trabajos de ejemplo'],
['When does your week start?','Quand commence ta semaine ?','¿Cuándo empieza tu semana?'],
['Pick the first day of your pay week so your totals match your paycheque.','Choisis le premier jour de ta semaine de paie pour aligner tes totaux.','Elige el primer día de tu semana de pago para que los totales coincidan.'],
['Remind me after each shift','Me rappeler après chaque quart','Recordarme después de cada turno'],
['15 min after your usual end time','15 min après ta fin habituelle','15 min después de tu salida habitual'],
['Weekly tip goal','Objectif hebdomadaire','Meta semanal de propinas'],
['Optional, you can change it later','Facultatif, modifiable plus tard','Opcional, puedes cambiarla después'],
['Done','Terminer','Listo'],
['Friday, October 2','Vendredi 2 octobre','Viernes, 2 de octubre'],
['ProTip365 · now','ProTip365 · maintenant','ProTip365 · ahora'],
['How did your shift at Bar Le Zinc go? Tap to add your tips (10 sec).','Comment s’est passé ton quart au Bar Le Zinc ? Touche pour ajouter tes pourboires (10 s).','¿Cómo fue tu turno en Bar Le Zinc? Toca para añadir tus propinas (10 s).'],
['Tap the notification','Touche la notification','Toca la notificación'],
['Log a shift','Ajouter un quart','Registrar un turno'],['Which job?','Quel emploi ?','¿Qué trabajo?'],
['Bartender · $13.30/h','Service au bar · $13.30/h','Servicio de bar · $13.30/h'],
['Server · $13.30/h','Service en salle · $13.30/h','Servicio de mesas · $13.30/h'],
['When?','Quand ?','¿Cuándo?'],['Today','Aujourd’hui','Hoy'],['Yesterday','Hier','Ayer'],['Other day','Autre jour','Otro día'],
['Hours','Heures','Horas'],['Start','Début','Entrada'],['End','Fin','Salida'],
['Unpaid break','Pause non payée','Descanso no pagado'],['None','Aucune','Ninguno'],
['6 h worked','6 h travaillées','6 h trabajadas'],
['Overnight works too','Les quarts de nuit aussi','También admite turnos nocturnos'],
['Next: tips','Suivant : pourboires','Siguiente: propinas'],
['Your tips','Tes pourboires','Tus propinas'],
['Cash tips','Pourboires en espèces','Propinas en efectivo'],
['Card tips','Pourboires par carte','Propinas con tarjeta'],
['On your end-of-shift report','Sur ton relevé de fin de quart','En tu informe de fin de turno'],
['Received from the pool','Reçus du partage','Recibidas del fondo común'],
['Tips other people shared with you','Pourboires partagés avec toi','Propinas que otros compartieron contigo'],
['Given to others (tip-out)','Donnés aux autres','Entregadas a otros'],
['To bar, kitchen, bussers…','Au bar, à la cuisine, aux aides…','Al bar, cocina y ayudantes…'],
['+ More: sales & note','+ Plus : ventes et note','+ Más: ventas y nota'],
['You take home','Tu gardes','Te llevas'],
['Save shift','Enregistrer le quart','Guardar turno'],
['Shift saved','Quart enregistré','Turno guardado'],
['Tips you made','Pourboires gagnés','Propinas ganadas'],
['Real hourly','Taux horaire réel','Ingreso real por hora'],
['▲ $11 more than your usual Friday at Bar Le Zinc.','▲ $11 de plus que ton vendredi habituel au Bar Le Zinc.','▲ $11 más que tu viernes habitual en Bar Le Zinc.'],
['Tips were 15.7% of sales.','Les pourboires représentaient 15.7 % des ventes.','Las propinas fueron el 15.7 % de las ventas.'],
['Undo','Annuler','Deshacer'],['Edit','Modifier','Editar'],
['October','Octobre','Octubre'],
['Week','Semaine','Semana'],['Month','Mois','Mes'],['Year','Année','Año'],
['This week · tips','Cette semaine · pourboires','Esta semana · propinas'],
['3 shifts · 13.5 h · total pay incl. wage $453','3 quarts · 13.5 h · revenus avec salaire $453','3 turnos · 13.5 h · ingresos con salario $453'],
['Avg per shift','Moyenne par quart','Promedio por turno'],
['Your week at a glance','Ta semaine en un coup d’œil','Tu semana de un vistazo'],
['By job','Par emploi','Por trabajo'],
['Best day: Saturday','Meilleur jour : samedi','Mejor día: sábado'],
['Average tips per shift, all time','Pourboires moyens par quart, depuis le début','Propinas medias por turno, todo el historial'],
['Your tips are 15.0% of sales.','Tes pourboires représentent 15.0 % des ventes.','Tus propinas son el 15.0 % de las ventas.'],
['My jobs','Mes emplois','Mis trabajos'],
['Bartender · $13.30/h · usually 17:00–23:30','Service au bar · $13.30/h · habituellement 17:00–23:30','Servicio de bar · $13.30/h · normalmente 17:00–23:30'],
['Server · $13.30/h · usually 11:00–15:00','Service en salle · $13.30/h · habituellement 11:00–15:00','Servicio de mesas · $13.30/h · normalmente 11:00–15:00'],
['Add a job','Ajouter un emploi','Añadir un trabajo'],
['Paperwork','Documents','Documentos'],
['Tip statement for my boss','Relevé pour mon employeur','Resumen para mi empleador'],
['Pay-period tip statement · PDF','Relevé par période de paie · PDF','Resumen por período de pago · PDF'],
['Year summary for taxes','Sommaire annuel des revenus','Resumen anual de ingresos'],
['Jan 1 – Dec 31, by employer','Du 1er janv. au 31 déc., par employeur','Del 1 ene. al 31 dic., por empleador'],
['Export all my data','Exporter toutes mes données','Exportar todos mis datos'],
['CSV · free, always','CSV · toujours gratuit','CSV · siempre gratis'],
['Settings','Réglages','Ajustes'],
['Back up my data','Sauvegarder mes données','Respaldar mis datos'],
['So you never lose it if you change phones','Pour garder tes données si tu changes de téléphone','Para conservar tus datos si cambias de teléfono'],
['Turn on','Activer','Activar'],
['Shift reminders','Rappels de quart','Recordatorios de turno'],
['Week starts on','Début de la semaine','La semana empieza el'],
['Monday','Lundi','Lunes'],['Language','Langue','Idioma'],
['Tip statement','Relevé de pourboires','Resumen de propinas'],
['Pay period Mon Sep 21 – Fri Oct 2','Période de paie : Mon Sep 21 – Fri Oct 2','Período de pago: Mon Sep 21 – Fri Oct 2'],
['Day','Jour','Día'],['Sales','Ventes','Ventas'],
['B · Tips','B · Pourboires','B · Propinas'],['D · In','D · Reçus','D · Recibidas'],['E · Out','E · Donnés','E · Entregadas'],
['Total','Total','Total'],
['Net tips to declare','Pourboires nets à déclarer','Propinas netas a declarar'],
['Tips are 15.0% of sales.','Les pourboires représentent 15.0 % des ventes.','Las propinas son el 15.0 % de las ventas.'],
['Share PDF with my manager','Partager mon relevé.','Compartir PDF con mi responsable'],
['Keep a record of your tips for each pay period. Reporting requirements depend on your country and region.','Garde un relevé de tes pourboires par période de paie. Les règles de déclaration dépendent de ton pays et de ta région.','Guarda tus propinas por período de pago. Las normas de declaración dependen de tu país y región.'],
['Back','Retour','Volver'],['colour','couleur','color'],
['toggle reminder','activer le rappel','activar recordatorio'],
['Previous month','Mois précédent','Mes anterior'],['Next month','Mois suivant','Mes siguiente'],
['e.g. Bar Le Zinc','Ex. : Bar Le Zinc','Ej.: Bar Le Zinc']
].map(row=>[row[0],row[1].replace(/\bemplois?\b/gi,word=>{
 const plural=word.toLowerCase()==='emplois';
 const value=plural?'employeurs':'employeur';
 return word[0]===word[0].toUpperCase()?value[0].toUpperCase()+value.slice(1):value;
}),row[2]]);
async function main() {
 const {chromium}=require('playwright');
 const dir=process.argv[2]||path.resolve(__dirname,'../website-live');
 const base=process.argv[3]||'http://localhost:4317';
 const b=await chromium.launch({headless:true,...(process.env.CHROME_PATH?{executablePath:process.env.CHROME_PATH}:{}),args:['--no-sandbox']});
 const p=await b.newPage();
 await p.goto(base+'/prototype.html?lang=en',{waitUntil:'networkidle'});
 const captions=await p.evaluate(()=>window.LAND);
 await p.goto(base+'/',{waitUntil:'networkidle'});
 const originals=await p.locator('.phone').evaluateAll(els=>els.map(e=>e.outerHTML));
 for(const [lang,route] of [['en','/'],['fr','/fr/'],['es','/es/']]){
  await p.goto(base+route,{waitUntil:'networkidle'});
  const count=await p.locator('.phone').count();if(count!==originals.length)throw Error('Phone count mismatch '+lang);
  await p.evaluate(({lang,originals,rows,captions})=>{
   const locale={en:'en-CA',fr:'fr-FR',es:'es-ES'}[lang];
   const dictionary=Object.fromEntries(rows.map(r=>[r[0],r[lang==='fr'?1:lang==='es'?2:0]]));
   const days={en:['Mon','Tue','Wed','Thu','Fri','Sat','Sun'],fr:['lun.','mar.','mer.','jeu.','ven.','sam.','dim.'],es:['lun.','mar.','mié.','jue.','vie.','sáb.','dom.']};
   const months=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
   [...document.querySelectorAll('.phone')].forEach((ph,i)=>{ph.outerHTML=originals[i];});
   const translate=text=>{
    const lead=text.match(/^\s*/)[0],tail=text.match(/\s*$/)[0],key=text.trim();
    if(!key)return text;
    let s=dictionary[key]||key;
    if(lang!=='en'){
     s=s.replace(/\b(Mon|Tue|Wed|Thu|Fri|Sat|Sun) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) (\d{1,2})\b/g,(_,d,m,n)=>new Intl.DateTimeFormat(locale,{weekday:'short',month:'short',day:'numeric'}).format(new Date(2026,months.indexOf(m),+n)));
     if(days.en.includes(s))s=days[lang][days.en.indexOf(s)];
     s=s.replace(/\$([\d,]+(?:\.\d+)?)/g,(_,n)=>new Intl.NumberFormat(locale,{minimumFractionDigits:n.includes('.')?n.split('.')[1].length:0,maximumFractionDigits:2}).format(Number(n.replaceAll(',','')))+'\u00a0$');
     s=s.replace(/\b(\d+)\.(\d+)\b/g,'$1,$2');
    }
    return lead+s+tail;
   };
   document.querySelectorAll('.phone').forEach(ph=>{
    ph.lang=lang;
    const w=document.createTreeWalker(ph,NodeFilter.SHOW_TEXT);let n;
    while(n=w.nextNode())if(n.parentElement.tagName!=='SCRIPT'&&n.parentElement.tagName!=='STYLE')n.nodeValue=translate(n.nodeValue);
    ph.querySelectorAll('[placeholder],[aria-label]').forEach(e=>['placeholder','aria-label'].forEach(attr=>{if(e.hasAttribute(attr))e.setAttribute(attr,translate(e.getAttribute(attr)));}));
    const choices=ph.querySelector('.lang');
    if(choices){
     choices.innerHTML=['fr','en','es'].map(l=>'<button class="chip '+(l===lang?'on':'')+'">'+({fr:'Français',en:'English',es:'Español'}[l])+'</button>').join('');
    }
    ph.querySelectorAll('.dow').forEach((e,j)=>e.textContent={en:['M','T','W','T','F','S','S'],fr:['L','M','M','J','V','S','D'],es:['L','M','X','J','V','S','D']}[lang][j]);
    ph.querySelectorAll('input').forEach(e=>{
     if(e.type==='date'){const dt=new Date(e.value+'T12:00:00');e.type='text';e.value=new Intl.DateTimeFormat(locale).format(dt);}
     else if(lang!=='en'&&e.type!=='time'&&/^\d+\.\d+$/.test(e.value))e.value=e.value.replace('.',',');
     e.setAttribute('value',e.value);
    });
   });
   // Show the selected language in settings without translating endonyms in language choices.
   document.querySelectorAll('#screen-jobs .phone .list-btn').forEach(row=>{
    if(row.innerText.includes(dictionary.Language||'Language')){
     const last=row.querySelector('.chev');if(last)last.textContent={en:'English',fr:'Français',es:'Español'}[lang];
    }
   });
   if(lang==='en'){
    const firstNote=document.querySelector('#screen-welcome .shot-copy li');
    if(firstNote)firstNote.textContent='Pick French, English or Spanish up front. Everything else can wait.';
   }
   if(lang!=='en'){
    const L=captions[lang];
    document.querySelectorAll('article.shot').forEach(article=>{
     const id=article.id.replace('screen-',''),note=L.notes[id];
     if(!note)throw Error('Missing translated caption '+lang+' '+id);
     article.querySelector('.shot-num').lastChild.nodeValue=L.items[id];
     article.querySelector('h3').textContent=note.t;
     [...article.querySelectorAll('.shot-copy li')].forEach((el,i)=>el.textContent=note.n[i]);
     const next=article.querySelector('.shot-next');next.firstChild.nodeValue=L.s.nextPrefix;next.querySelector('b').textContent=note.next;
    });
   }
   if(lang==='fr'){
    const normalize=text=>text.replace(/\bemplois?\b/gi,word=>{
     const value=word.toLowerCase()==='emplois'?'employeurs':'employeur';
     return word[0]===word[0].toUpperCase()?value[0].toUpperCase()+value.slice(1):value;
    });
    const walker=document.createTreeWalker(document.body,NodeFilter.SHOW_TEXT);let node;
    while(node=walker.nextNode())if(!['SCRIPT','STYLE'].includes(node.parentElement.tagName))node.nodeValue=normalize(node.nodeValue);
    document.querySelectorAll('meta[name="description"],meta[property="og:description"],meta[name="twitter:description"]').forEach(e=>e.content=normalize(e.content));
    document.querySelectorAll('script[type="application/ld+json"]').forEach(e=>e.textContent=normalize(e.textContent));
   }
   document.querySelectorAll('a[href^="/prototype.html"]').forEach(a=>a.setAttribute('href','/prototype.html?lang='+lang));
  },{lang,originals,rows,captions});
  fs.writeFileSync(path.join(dir,lang==='en'?'index.html':lang+'/index.html'),'<!DOCTYPE html>\n'+await p.locator('html').evaluate(e=>e.outerHTML));
  console.log(lang,await p.locator('.phone').count(),'localized phones');
 }
 await b.close();
}
module.exports={rows};
if(require.main===module)main().catch(e=>{console.error(e);process.exit(1);});
