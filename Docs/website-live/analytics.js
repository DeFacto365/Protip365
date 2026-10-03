/* ProTip365 website analytics. No Google requests before opt-in. */
(() => {
  'use strict';
  const ID = 'G-E1C2B8QG1G';
  const KEY = 'pt365.analytics-consent.v1';
  const MAX_AGE = 180 * 24 * 60 * 60 * 1000;
  const copy = {
    en: { title: 'Optional website analytics', text: 'Allow Google Analytics to measure visits and clicks so we can improve this website? Your choice does not affect the app. No advertising tracking.', accept: 'Allow analytics', reject: 'Reject analytics', settings: 'Cookie settings', privacy: 'Privacy policy' },
    fr: { title: 'Statistiques facultatives du site', text: 'Autoriser Google Analytics à mesurer les visites et les clics pour améliorer ce site? Votre choix ne change rien à l’application. Aucun suivi publicitaire.', accept: 'Autoriser les statistiques', reject: 'Refuser les statistiques', settings: 'Préférences de témoins', privacy: 'Confidentialité' },
    es: { title: 'Estadísticas opcionales del sitio', text: '¿Permites que Google Analytics mida visitas y clics para mejorar este sitio? Tu elección no afecta a la app. Sin seguimiento publicitario.', accept: 'Permitir estadísticas', reject: 'Rechazar estadísticas', settings: 'Preferencias de cookies', privacy: 'Privacidad' }
  };
  let started = false;
  let allowed = false;
  let previousFocus;
  const lang = () => {
    const value = document.documentElement.lang.slice(0, 2);
    return copy[value] ? value : 'en';
  };
  function preference() {
    try {
      const saved = JSON.parse(localStorage.getItem(KEY));
      if (saved && ['granted', 'denied'].includes(saved.value) && Date.now() - saved.at < MAX_AGE) return saved.value;
    } catch {}
    return null;
  }
  function cleanURL(value, campaigns = false) {
    try {
      const url = new URL(value, location.origin);
      const clean = new URL(url.origin + url.pathname);
      if (campaigns) ['utm_source', 'utm_medium', 'utm_campaign', 'utm_content', 'utm_term'].forEach(key => {
        const value = url.searchParams.get(key);
        if (value && /^[a-zA-Z0-9_-]{1,100}$/.test(value)) clean.searchParams.set(key, value);
      });
      return clean.href;
    } catch { return ''; }
  }
  function start() {
    if (started || !allowed) return;
    // Never send preview or local development traffic to the production property.
    if (!['www.protip365.com', 'protip365.com'].includes(location.hostname)) return;
    started = true;
    window['ga-disable-' + ID] = false;
    window.dataLayer = window.dataLayer || [];
    window.gtag = function () { window.dataLayer.push(arguments); };
    window.gtag('consent', 'default', { analytics_storage: 'denied', ad_storage: 'denied', ad_user_data: 'denied', ad_personalization: 'denied' });
    window.gtag('consent', 'update', { analytics_storage: 'granted' });
    window.gtag('js', new Date());
    window.gtag('config', ID, {
      page_location: cleanURL(location.href, true),
      page_referrer: document.referrer ? cleanURL(document.referrer) : '',
      allow_google_signals: false,
      allow_ad_personalization_signals: false,
      cookie_expires: 15552000,
      cookie_flags: 'SameSite=Lax;Secure'
    });
    const script = document.createElement('script');
    script.async = true;
    script.src = 'https://www.googletagmanager.com/gtag/js?id=' + ID;
    document.head.appendChild(script);
  }
  function removeCookies() {
    document.cookie.split(';').forEach(cookie => {
      const name = cookie.split('=')[0].trim();
      if (!/^_ga(?:_|$)|^_gid$|^_gat/.test(name)) return;
      ['', location.hostname, '.protip365.com', 'protip365.com'].forEach(domain => {
        document.cookie = name + '=; Max-Age=0; path=/; SameSite=Lax' + (domain ? '; domain=' + domain : '');
      });
    });
  }
  const panel = document.createElement('section');
  panel.id = 'pt365-consent';
  panel.setAttribute('role', 'region');
  panel.setAttribute('aria-labelledby', 'pt365-consent-title');
  panel.innerHTML = '<h2 id="pt365-consent-title"></h2><p></p><a class="pt365-consent-privacy"></a><div class="pt365-consent-actions"><button type="button" data-consent="denied"></button><button type="button" data-consent="granted"></button></div>';
  panel.hidden = true;
  document.body.appendChild(panel);
  const settings = document.createElement('button');
  settings.type = 'button';
  settings.className = 'pt365-consent-settings';
  settings.setAttribute('aria-controls', panel.id);
  (document.querySelector('.lp-foot-nav') || document.querySelector('footer') || document.body).appendChild(settings);
  function translate() {
    const L = copy[lang()];
    panel.querySelector('h2').textContent = L.title;
    panel.querySelector('p').textContent = L.text;
    panel.querySelector('[data-consent="denied"]').textContent = L.reject;
    panel.querySelector('[data-consent="granted"]').textContent = L.accept;
    const privacy = panel.querySelector('a');
    privacy.textContent = L.privacy;
    privacy.href = '/privacy/?lang=' + lang() + '#section-11';
    settings.textContent = L.settings;
  }
  translate();
  new MutationObserver(translate).observe(document.documentElement, { attributes: true, attributeFilter: ['lang'] });
  settings.addEventListener('click', () => {
    previousFocus = settings;
    panel.hidden = false;
    panel.querySelector('button').focus();
  });
  panel.addEventListener('click', event => {
    const button = event.target.closest('[data-consent]');
    if (!button) return;
    const value = button.dataset.consent;
    try { localStorage.setItem(KEY, JSON.stringify({ value, at: Date.now() })); } catch {}
    allowed = value === 'granted';
    panel.hidden = true;
    if (previousFocus) previousFocus.focus();
    if (allowed) start();
    else {
      window['ga-disable-' + ID] = true;
      removeCookies();
      // Unload Google and its automatic event listeners after withdrawing consent.
      if (started) location.reload();
    }
  });
  document.addEventListener('click', event => {
    if (!allowed || !started) return;
    const link = event.target.closest('a[href]');
    if (!link) return;
    const url = new URL(link.href, location.href);
    let name;
    if (url.hostname === 'play.google.com' && url.pathname === '/store/apps/details') name = 'app_store_click';
    else if (url.origin === location.origin && url.pathname === '/prototype.html') name = 'demo_open';
    else if (url.hostname === 'www.facebook.com' || url.hostname === 'facebook.com') name = 'facebook_click';
    if (!name) return;
    window.gtag('event', name, { send_to: ID, page_language: lang(), link_url: cleanURL(url.href), cta_location: link.closest('header') ? 'header' : link.closest('footer') ? 'footer' : link.closest('#pricing') ? 'pricing' : 'content' });
  });
  const saved = preference();
  window.addEventListener('storage', event => {
    if (event.key === KEY && preference() !== 'granted' && started) {
      window['ga-disable-' + ID] = true;
      removeCookies();
      location.reload();
    }
  });
  allowed = saved === 'granted';
  if (allowed) start();
  else {
    removeCookies();
    panel.hidden = saved === 'denied';
  }
})();
