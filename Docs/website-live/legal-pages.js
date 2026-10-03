(() => {
  const KIND = document.body.dataset.page;
  const labels = {
    en:{home:'Home',app:'Get the app',privacy:'Privacy',terms:'Terms',support:'Support',eyebrow:'ProTip365 · Information',contents:'On this page',presentation:'Design and translations updated: October 3, 2026',termsDate:'Terms last updated: August 3, 2026',privacyDate:'App privacy policy: August 3, 2026 · Website disclosure added: October 3, 2026',note:'Product features and commercial terms below describe the published mobile app. The website demo and Android build specification may include features planned for a future version.',language:'Language',titles:{terms:'Terms of Service',privacy:'Privacy Policy',support:'Support'}},
    fr:{home:'Accueil',app:'Découvrir l’appli',privacy:'Confidentialité',terms:'Conditions',support:'Assistance',eyebrow:'ProTip365 · Informations',contents:'Sur cette page',presentation:'Design et traductions mis à jour : 3 octobre 2026',termsDate:'Dernière mise à jour des conditions : 3 août 2026',privacyDate:'Politique de l’appli : 3 août 2026 · Informations sur le site ajoutées : 3 octobre 2026',note:'Les fonctionnalités et conditions commerciales ci-dessus décrivent l’application mobile publiée. La démo du site et le cahier des charges Android peuvent inclure des fonctionnalités prévues pour une prochaine version.',language:'Langue',titles:{terms:'Conditions d’utilisation',privacy:'Politique de confidentialité',support:'Assistance'}},
    es:{home:'Inicio',app:'Conocer la app',privacy:'Privacidad',terms:'Términos',support:'Soporte',eyebrow:'ProTip365 · Información',contents:'En esta página',presentation:'Diseño y traducciones actualizados: 3 de octubre de 2026',termsDate:'Última actualización de los términos: 3 de agosto de 2026',privacyDate:'Política de la app: 3 de agosto de 2026 · Información del sitio añadida: 3 de octubre de 2026',note:'Las funciones y condiciones comerciales anteriores describen la aplicación móvil publicada. La demo del sitio y la especificación Android pueden incluir funciones previstas para una versión futura.',language:'Idioma',titles:{terms:'Términos de servicio',privacy:'Política de privacidad',support:'Soporte'}}
  };
  let english;
  let lang;
  try {
    lang = new URLSearchParams(location.search).get('lang') || localStorage.getItem('pt365lang');
  } catch { lang = new URLSearchParams(location.search).get('lang'); }
  if (!labels[lang]) {
    const device=(navigator.language||'en').slice(0,2).toLowerCase();
    lang=labels[device]?device:'en';
  }
  function render(language,updateUrl=false) {
    lang=language;
    const L=labels[lang], data=(lang==='en'?english:window.LEGAL_TRANSLATIONS[lang])[KIND];
    if(!data)return;
    document.documentElement.lang=lang;
    document.title=`ProTip365 — ${L.titles[KIND]}`;
    document.querySelector('meta[name="description"]').content=`${L.titles[KIND]} · ProTip365`;
    document.querySelector('h1').textContent=L.titles[KIND];
    document.querySelector('.legal-intro').innerHTML=data.intro;
    document.querySelector('.legal-content').innerHTML=data.sections.map(([t,p],i)=>`<section id="section-${i+1}"><h2>${i+1}. ${t}</h2><p>${p}</p></section>`).join('');
    document.querySelector('.legal-contents summary').textContent=L.contents;
    document.querySelector('.legal-contents ol').innerHTML=data.sections.map(([t],i)=>`<li><a href="#section-${i+1}">${t}</a></li>`).join('');
    document.querySelector('.legal-meta').innerHTML=(KIND==='terms'?`<span>${L.termsDate}</span>`:KIND==='privacy'?`<span>${L.privacyDate}</span>`:'')+`<span>${L.presentation}</span>`;
    document.querySelector('.legal-note').textContent=L.note;
    document.querySelectorAll('[data-label]').forEach(e=>e.textContent=L[e.dataset.label]);
    document.querySelector('.lp-lang').setAttribute('aria-label',L.language);
    document.querySelectorAll('[data-lang]').forEach(b=>{
      b.classList.toggle('on',b.dataset.lang===lang);
      b.setAttribute('aria-pressed',String(b.dataset.lang===lang));
    });
    document.querySelectorAll('.language-link').forEach(a=>{
      const url=new URL(a.getAttribute('href'),location.origin);
      url.searchParams.set('lang',lang);
      a.href=url.pathname+url.search;
    });
    // Localize cross-links within policy text without touching email addresses.
    document.querySelectorAll('.legal-main a[href^="/"]').forEach(a=>{
      const url=new URL(a.getAttribute('href'),location.origin);
      url.searchParams.set('lang',lang);
      a.href=url.pathname+url.search;
    });
    try {localStorage.setItem('pt365lang',lang);}catch{}
    if(updateUrl){
      const url=new URL(location.href);
      url.searchParams.set('lang',lang);
      history.replaceState(null,'',url);
    }
  }
  fetch('/legal-en.json').then(r=>{
    if(!r.ok)throw new Error('Legal content unavailable');
    return r.json();
  }).then(data=>{
    english=data;
    render(lang);
    document.querySelectorAll('[data-lang]').forEach(b=>b.addEventListener('click',()=>render(b.dataset.lang,true)));
  }).catch(e=>console.error(e));
})();
