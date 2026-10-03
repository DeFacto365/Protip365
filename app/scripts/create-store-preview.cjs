// Isolated screenshot fixture; never bundled into the app.
const fs = require('node:fs'), path = require('node:path'), http = require('node:http');
const root = path.resolve(__dirname, '../../Docs/google-play');
fs.mkdirSync(path.join(root,'preview'),{recursive:true});
fs.cpSync(path.resolve(__dirname,'../dist-web'),path.join(root,'preview'),{recursive:true});
const jobs = [
  {id:'j1',name:'Bar Le Zinc',role:'Bartender',rate:1330,color:'#A67B65',start:'17:00',end:'23:30',brk:30},
  {id:'j2',name:'Chez Lou',role:'Server',rate:1330,color:'#6F8FA3',start:'11:00',end:'15:00',brk:0},
];
const shifts = [
  ['2026-09-25','j1',58,121,23],['2026-09-26','j1',92,150,32],
  ['2026-09-27','j2',26,74,9],['2026-09-29','j2',18,58,10],
  ['2026-09-30','j1',42,103,19],['2026-10-01','j2',20,74,13],
].map(([date,job,cash,card,out],i)=>({id:'demo'+i,job,date,start:job==='j1'?'17:00':'11:00',end:job==='j1'?'23:00':'15:00',brk:0,cash:cash*100,card:card*100,tipIn:0,tipOut:out*100,sales:120000,other:null,note:'',rate:1330,createdAt:date+'T12:00:00.000Z',updatedAt:date+'T12:00:00.000Z'}));
shifts.push({id:'next',job:'j1',date:'2026-10-04',start:'17:00',end:'23:30',brk:30,cash:null,card:null,tipIn:null,tipOut:null,sales:null,other:null,note:'',rate:1330,planned:true,createdAt:'2026-10-02T12:00:00.000Z',updatedAt:'2026-10-02T12:00:00.000Z'});
const demo = {version:1,onboarded:true,jobs,shifts,settings:{language:'fr',weekStart:1,reminder:false,offset:15,goal:60000,name:'Maya'}};
const index = path.join(root,'preview/index.html');
fs.writeFileSync(index,fs.readFileSync(index,'utf8').replace('<head>',`<head><script>const fixture=${JSON.stringify(demo)};fixture.settings.language=new URLSearchParams(location.search).get('lang')==='en'?'en':'fr';localStorage.setItem('protip365.new-app.v1',JSON.stringify(fixture));</script>`));
const captions = {
  'fr-CA':[
    ['Tes quarts.\nTes pourboires.','Vois ta semaine s’additionner.'],
    ['Ajoute tes pourboires.\nVois ton total.','Espèces, carte et partage entre collègues.'],
    ['Ton horaire,\nen un coup d’œil.','Planifie tes quarts, même après minuit.'],
    ['Comprends ce\nque tu gagnes.','Semaine, mois, année. À chaque employeur.'],
    ['Tous tes employeurs.\nUne seule appli.','Tes taux horaires et tes couleurs, à ta façon.'],
    ['Tes documents,\nsans casse-tête.','Relevé PDF, résumé annuel et export CSV.'],
  ],
  'en-US':[
    ['Your shifts.\nYour tips.','Watch your week add up.'],
    ['Log your tips.\nSee your total.','Cash, card and tips shared with coworkers.'],
    ['Your schedule,\nat a glance.','Plan your shifts, including overnight work.'],
    ['Know what\nyou earn.','Week, month, year. For every job.'],
    ['Every job.\nOne app.','Your hourly rates and colours, your way.'],
    ['Paperwork,\nmade simple.','PDF statements, year summaries and CSV export.'],
  ],
};
const fontRoot=path.resolve(__dirname,'../node_modules/@expo-google-fonts');
fs.mkdirSync(path.join(root,'fonts'),{recursive:true});
for(const [name,file] of [['Fraunces','fraunces/600SemiBold/Fraunces_600SemiBold.ttf'],['WorkSans','work-sans/400Regular/WorkSans_400Regular.ttf'],['WorkSansBold','work-sans/600SemiBold/WorkSans_600SemiBold.ttf']]) fs.copyFileSync(path.join(fontRoot,file),path.join(root,'fonts',name+'.ttf'));
fs.copyFileSync(path.resolve(__dirname,'../assets/logo.svg'),path.join(root,'logo.svg'));
const style=`@font-face{font-family:Fraunces;src:url('/fonts/Fraunces.ttf')}@font-face{font-family:WorkSans;src:url('/fonts/WorkSans.ttf')}@font-face{font-family:WorkSans;src:url('/fonts/WorkSansBold.ttf');font-weight:600}*{box-sizing:border-box}body{margin:0;background:#FAF8F3;color:#3F2A22;font-family:WorkSans}.asset{position:relative;width:1080px;height:1920px;overflow:hidden;padding:65px 80px}.brand{display:flex;align-items:center;gap:18px;font-size:36px;letter-spacing:-1px}.brand img{width:64px;height:64px}.brand b{font-weight:600}.brand span{font-weight:400}h1{font-family:Fraunces;font-size:78px;line-height:1.06;letter-spacing:-2px;font-weight:600;white-space:pre-line;margin:43px 0 22px}p{font-size:31px;line-height:1.4;max-width:910px;margin:0}.wash{position:absolute;z-index:-1;width:810px;height:1330px;top:540px;left:145px;background:#E0E5D6;border-radius:240px 240px 55px 55px}.device{position:absolute;top:450px;left:170px;width:740px;border:9px solid #3F2A22;border-radius:40px;overflow:hidden;background:#FAF8F3;box-shadow:0 26px 45px #3f2a2220}.device img{display:block;width:100%;height:auto}.sample{position:absolute;bottom:35px;left:80px;font-size:21px;color:#6B564C}.feature{width:1024px;height:500px;padding:60px}.feature h1{font-size:64px;margin-top:40px}.feature p{font-size:23px;max-width:540px}.feature .device{left:690px;top:45px;width:265px;border-width:5px;border-radius:22px}.feature .brand{font-size:30px}.feature .brand img{width:48px;height:48px}.feature .sample{display:none}`;
for(const lang of Object.keys(captions)) for(let n=0;n<6;n++) fs.writeFileSync(path.join(root,lang,`${n+1}.html`),`<!doctype html><meta charset="utf-8"><style>${style}</style><div class="asset"><div class="brand"><img src="/logo.svg"><b>protip<span>365</span></b></div><h1>${captions[lang][n][0]}</h1><p>${captions[lang][n][1]}</p><div class="wash"></div><div class="device"><img src="/source/${lang}-${n+1}.jpg"></div><div class="sample">${lang==='fr-CA'?'Données de démonstration':'Demonstration data'}</div></div>`);
for(const lang of Object.keys(captions)) fs.writeFileSync(path.join(root,lang,'feature.html'),`<!doctype html><meta charset="utf-8"><style>${style}</style><div class="asset feature"><div class="brand"><img src="/logo.svg"><b>protip<span>365</span></b></div><h1>${captions[lang][0][0]}</h1><p>${lang==='fr-CA'?'Pourboires, horaires et revenus.\nÀ chaque employeur.':'Tips, schedules and earnings.\nFor every job.'}</p><div class="device"><img src="/source/${lang}-1.jpg"></div></div>`);
const brand=JSON.parse(fs.readFileSync(path.resolve(__dirname,'../src/brand.ts'),'utf8').split('export const brand = ')[1].replace(/ as const;\s*$/,''));
const {createCanvas,Path2D}=require('@napi-rs/canvas');
const icon=createCanvas(512,512),ctx=icon.getContext('2d');ctx.fillStyle=brand.sage;ctx.fillRect(0,0,512,512);ctx.scale(512/48,512/48);ctx.fillStyle=brand.cream;ctx.fill(new Path2D(brand.markPath));fs.writeFileSync(path.join(root,'play-icon.png'),icon.toBuffer('image/png'));
const types={'.html':'text/html','.js':'text/javascript','.ttf':'font/ttf','.svg':'image/svg+xml','.jpg':'image/jpeg','.png':'image/png','.ico':'image/x-icon','.json':'application/json'};
http.createServer((req,res)=>{const file=path.resolve(root,'.'+decodeURIComponent(new URL(req.url,'http://localhost').pathname).replace(/^\/(?:_expo|assets)\//, match => '/preview'+match));if(!file.startsWith(root+path.sep)){res.writeHead(403);res.end();return;}fs.readFile(file,(error,bytes)=>{res.writeHead(error?404:200,{'Content-Type':types[path.extname(file)]||'application/octet-stream'});res.end(error?'Not found':bytes);});}).listen(8084,'127.0.0.1',()=>console.log('Store assets preview: http://127.0.0.1:8084/preview/index.html?lang=fr'));
