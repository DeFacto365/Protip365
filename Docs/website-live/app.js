(() => {
const TODAY = '2026-10-02';
const COLORS = ['#A67B65', '#6F8FA3', '#8A9C7D', '#C9A15B', '#9C7A9A'];

const state = {
  lang: 'en',
  weekStart: 1, // 0=Sun,1=Mon...
  reminder: true,
  goal: 600,
  jobs: [
    { id: 'j1', name: 'Bar Le Zinc', role: 'Bartender', rate: 13.30, color: COLORS[0], start: '17:00', end: '23:30' },
    { id: 'j2', name: 'Chez Lou', role: 'Server', rate: 13.30, color: COLORS[1], start: '11:00', end: '15:00' },
  ],
  shifts: [],
  draft: null,
  lastSaved: null,
  statsRange: 'week',
  calSel: TODAY,
  calMonth: 10,
  onbJob: { name: '', role: 'Server', rate: '13.30', color: COLORS[0] },
};

// seed sample data
(function seed() {
  const s = [
    ['j1','2026-09-04','17:00','23:30',30,62,118,0,24],['j2','2026-09-05','11:00','15:00',0,20,64,0,8],
    ['j1','2026-09-05','18:00','01:00',30,88,140,0,30],['j1','2026-09-06','17:00','23:00',30,40,96,0,18],
    ['j2','2026-09-09','11:00','15:00',0,12,52,0,6],['j1','2026-09-11','17:00','23:30',30,70,132,0,26],
    ['j1','2026-09-12','18:00','01:30',30,105,166,0,36],['j2','2026-09-13','10:00','15:00',15,30,82,0,10],
    ['j2','2026-09-16','11:00','15:00',0,18,58,0,7],['j1','2026-09-18','17:00','23:30',30,66,124,0,25],
    ['j1','2026-09-19','18:00','01:00',30,92,150,0,32],['j2','2026-09-20','10:00','15:00',15,26,74,0,9],
    ['j2','2026-09-23','11:00','15:00',0,14,61,0,7],['j1','2026-09-25','17:00','23:30',30,58,121,0,23],
    ['j1','2026-09-26','18:00','01:30',30,110,172,0,38],['j2','2026-09-27','10:00','15:00',15,28,79,0,10],
    ['j2','2026-09-29','11:00','15:00',0,16,57,0,7],['j1','2026-09-30','17:00','23:00',30,44,101,0,19],
    ['j2','2026-10-01','11:00','15:00',0,22,68,0,9],
  ];
  state.shifts = s.map((r, i) => ({ id: 's' + i, job: r[0], date: r[1], start: r[2], end: r[3], brk: r[4], cash: r[5], card: r[6], tipIn: r[7], tipOut: r[8], sales: Math.round((r[5] + r[6]) / 0.15), note: '' }));
})();

// ---------- helpers ----------
const $ = (s, el = document) => el.querySelector(s);
const money = (n, d = 0) => '$' + Number(n || 0).toLocaleString('en-CA', { minimumFractionDigits: d, maximumFractionDigits: d });
const money2 = n => money(n, 2);
const job = id => state.jobs.find(j => j.id === id) || state.jobs[0];
const toMin = t => { const [h, m] = t.split(':').map(Number); return h * 60 + m; };
const hoursOf = s => { let d = toMin(s.end) - toMin(s.start); if (d <= 0) d += 1440; return Math.max(0, (d - (Number(s.brk) || 0)) / 60); };
const net = s => (+s.cash || 0) + (+s.card || 0) + (+s.tipIn || 0) - (+s.tipOut || 0);
const wage = s => hoursOf(s) * job(s.job).rate;
const perHour = s => { const h = hoursOf(s); return h ? (wage(s) + net(s)) / h : 0; };
const d2 = str => { const [y, m, d] = str.split('-').map(Number); return new Date(y, m - 1, d); };
const iso = dt => dt.getFullYear() + '-' + String(dt.getMonth() + 1).padStart(2, '0') + '-' + String(dt.getDate()).padStart(2, '0');
const addDays = (str, n) => { const x = d2(str); x.setDate(x.getDate() + n); return iso(x); };
const DOW = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const DOWL = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
const MON = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const fmtDay = str => { const x = d2(str); return DOW[x.getDay()] + ' ' + MON[x.getMonth()] + ' ' + x.getDate(); };
const weekStartOf = str => { const x = d2(str); const diff = (x.getDay() - state.weekStart + 7) % 7; x.setDate(x.getDate() - diff); return iso(x); };
function rangeOf(kind) {
  if (kind === 'week') { const a = weekStartOf(TODAY); return [a, addDays(a, 6)]; }
  if (kind === 'month') return ['2026-10-01', '2026-10-31'];
  return ['2026-01-01', '2026-12-31'];
}
const inRange = (s, [a, b]) => s.date >= a && s.date <= b;
const sum = (arr, f) => arr.reduce((t, x) => t + f(x), 0);
const sorted = () => [...state.shifts].sort((a, b) => (b.date + b.start).localeCompare(a.date + a.start));
const icon = {
  back: '<svg viewBox="0 0 24 24"><path d="M15 5l-7 7 7 7" stroke-linecap="round" stroke-linejoin="round"/></svg>',
  check: '<svg viewBox="0 0 24 24"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>',
  logo: '<svg viewBox="0 0 48 48" aria-label="ProTip365"><rect width="48" height="48" rx="12" fill="#8A9C7D"/><text x="23" y="34" text-anchor="middle" font-family="Fraunces, Georgia, serif" font-weight="600" font-size="32" fill="#FBFAF6">p.</text></svg>',
  leaf: '<svg class="leaf" viewBox="0 0 120 200" aria-hidden="true"><path d="M70 6 C78 60 76 120 52 196" stroke="#C3CDB9" stroke-width="4" fill="none" stroke-linecap="round"/><path d="M72 58 C40 30 6 34 4 44 C20 62 52 66 72 58Z" fill="#C3CDB9"/><path d="M76 74 C78 46 100 30 118 30 C116 56 100 70 76 74Z" fill="#C3CDB9"/><path d="M66 120 C36 98 4 104 0 112 C18 130 48 132 66 120Z" fill="#C3CDB9"/><path d="M60 158 C66 128 94 114 116 116 C110 144 88 156 60 158Z" fill="#C3CDB9"/></svg>',
  doc: '<svg viewBox="0 0 24 24"><path d="M6 3h8l4 4v14H6z M14 3v4h4 M9 13h6 M9 17h6"/></svg>',
  cal: '<svg viewBox="0 0 24 24"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/></svg>',
  dl: '<svg viewBox="0 0 24 24"><path d="M12 4v11M7 10l5 5 5-5M5 20h14"/></svg>',
  cloud: '<svg viewBox="0 0 24 24"><path d="M7 18a4 4 0 010-8 6 6 0 0111.5 1.5A3.5 3.5 0 0117.5 18z"/></svg>',
  bell: '<svg viewBox="0 0 24 24"><path d="M6 16V11a6 6 0 0112 0v5l2 2H4z M10 21h4"/></svg>',
  plus: '<svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>',
  globe: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18"/></svg>',
};
const back = to => `<button class="back" data-go="${to}" aria-label="Back">${icon.back}</button>`;

// ---------- screen meta (flow + design notes) ----------
const FLOW = [
  { group: 'First launch', items: [
    { id: 'welcome', label: 'Welcome' },
    { id: 'onbJob', label: 'Add first job' },
    { id: 'onbWeek', label: 'Week & reminder' },
  ]},
  { group: 'Every shift', items: [
    { id: 'reminder', label: 'End-of-shift reminder' },
    { id: 'log1', label: 'Log shift · job & hours' },
    { id: 'log2', label: 'Log shift · tips' },
    { id: 'saved', label: 'Saved summary' },
  ]},
  { group: 'Check my money', items: [
    { id: 'home', label: 'Home · this week' },
    { id: 'calendar', label: 'Calendar' },
    { id: 'stats', label: 'Stats · week/month/year' },
  ]},
  { group: 'Paperwork', items: [
    { id: 'jobs', label: 'Me · jobs & exports' },
    { id: 'statement', label: 'Tip statement (Québec)' },
  ]},
];
const ORDER = FLOW.flatMap(g => g.items.map(i => i.id));

const NOTES = {
  welcome: { t: 'Start in one tap, no account', n: ['Pick French or English up front. Everything else can wait.', 'There\'s no sign-up wall. Data stays on the phone until the user chooses to back it up, because competitors get criticized for forcing accounts first.', 'The importer helps people switching from ServerLife, TipKeepr or a spreadsheet.'], next: 'Add first job' },
  onbJob: { t: 'One job, three fields', n: ['Only the employer name is required. Role and rate come pre-filled.', 'The rate defaults to Québec\'s tipped minimum ($13.30/h since May 1, 2026). Users can change it.', 'Each job gets a colour. That colour follows it everywhere: calendar, lists and charts.'], next: 'Week & reminder' },
  onbWeek: { t: 'Week that matches the paycheque', n: ['The user picks the day their week starts, so totals line up with their real pay period. This is the most requested fix in competitor reviews.', 'The end-of-shift reminder is on by default. It is the habit loop that keeps the data complete.', 'This is the last onboarding screen. A new user is on Home within about 30 seconds.'], next: 'Home' },
  home: { t: 'Home answers "how am I doing this week?"', n: ['The week\'s total is the biggest thing on screen, with progress toward a goal under it.', 'The + button is always in the same spot. It is the only primary action in the app.', 'Recent shifts show net tips plus the real hourly rate (wage + tips ÷ hours).'], next: 'Calendar, Stats, or tap +' },
  reminder: { t: 'The nudge that opens step 1', n: ['The reminder fires at the job\'s usual end time plus 15 minutes.', 'Tapping it opens Log shift with the job, date and usual hours already filled in. Most nights it\'s just a matter of typing the tips.', 'Swiping it away snoozes until morning. The tone never nags.'], next: 'Log shift · job & hours' },
  log1: { t: 'Which job, when, how long', n: ['Job, date and hours are pre-filled from the reminder or from the last shift. Usually there is nothing to change.', 'Start and end times rather than "hours worked". The app works out the hours, including overnight shifts and breaks.', 'Several shifts on the same day are allowed, for example a lunch at Chez Lou and an evening at Le Zinc.'], next: 'Tips' },
  log2: { t: 'Tips in plain words', n: ['Four amounts: cash, card, received from the pool, and given to others. Every field is optional.', 'The take-home total updates live at the bottom, so there is no math to do.', 'Sales and a note are hidden under "More". They are only needed for the Québec 8% check and the tip statement.'], next: 'Saved summary' },
  saved: { t: 'Instant payoff', n: ['A clear confirmation with the two numbers people care about: tips made and real hourly rate.', 'A comparison to the user\'s average for that weekday gives a reason to come back.', 'Undo and Edit are right there, which builds trust for low-tech users.'], next: 'Home' },
  calendar: { t: 'See the month at a glance', n: ['Each day shows the net tips and coloured dots for the jobs worked.', 'Tapping a day lists its shifts below. Tapping a shift edits it.', 'Planned shifts could also show as outlined days later (V2: schedule import).'], next: 'Stats' },
  stats: { t: 'Week · Month · Year, one tap', n: ['Three fixed ranges with no date pickers. A custom range is under "More" for power users.', 'Splits by employer and finds the best day of the week, the insights servers say they want most.', 'Shows a Québec 8% check when sales were entered: tips as a percentage of sales against the allocation threshold.'], next: 'Me' },
  jobs: { t: 'Jobs, exports, backup', n: ['Unlimited jobs for free. Competitors charge about $6 per extra job.', 'Exports are free: the pay-period tip statement, a yearly summary for line 10400, and CSV.', 'Backup is optional and explained in one line. It is offered, never forced.'], next: 'Tip statement' },
  statement: { t: 'Québec tip statement, generated', n: ['Same structure as Revenu Québec\'s TP-1019.4-V: B tips received, D tips from sharing, E tips given out. Net = B + C + D − E.', 'One tap shares it as a PDF with the manager at the end of each pay period, which is a legal obligation in restaurants and bars.', 'This feature is something the US apps don\'t offer and a strong reason to choose this app in Québec.'], next: 'Back to Home' },
};

// ---------- screens ----------
const S = {};

S.welcome = () => `
  <div class="welcome-art">${welcomeArt()}</div>
  <div class="eyebrow">ProTip365</div>
  <div class="h1">Your shifts.<br>Your tips.</div>
  <p class="muted" style="margin-bottom:20px">Tips, hours and pay for all your jobs in one place. Free, private, and fast.</p>
  <div class="lang" style="margin-bottom:12px">
    <button class="chip ${state.lang === 'fr' ? 'on' : ''}" data-act="lang" data-v="fr">Français</button>
    <button class="chip ${state.lang === 'en' ? 'on' : ''}" data-act="lang" data-v="en">English</button>
  </div>
  <div class="stack">
    <button class="btn" data-go="onbJob">Get started</button>
    <button class="btn ghost small" data-act="toast" data-v="Import from ServerLife, TipKeepr or CSV">I already use another app</button>
  </div>
  <p class="sub-sm" style="text-align:center;margin-top:12px">No account needed. Your data stays on your phone.</p>`;

S.onbJob = () => {
  const o = state.onbJob;
  return `
  <div class="topbar">${back('welcome')}<div class="steps"><i class="on"></i><i></i></div><span style="width:40px"></span></div>
  <div class="h1">Where do you work?</div>
  <div class="stack">
    <div class="field"><label for="oName">Employer name</label><input id="oName" class="input" placeholder="e.g. Bar Le Zinc" value="${o.name}" data-bind="onb.name" autocomplete="off"></div>
    <div class="field"><label>Your role</label>
      <div class="chips">${['Server', 'Bartender', 'Busser', 'Host', 'Barback'].map(r => `<button class="chip ${o.role === r ? 'on' : ''}" data-act="onbRole" data-v="${r}">${r}</button>`).join('')}</div></div>
    <div class="field"><label for="oRate">Hourly wage</label><div class="money"><span>$</span><input id="oRate" class="input" inputmode="decimal" value="${o.rate}" data-bind="onb.rate"></div><div class="help">Québec tipped minimum is $13.30/h. Change it if you earn more.</div></div>
    <div class="field"><label>Colour</label><div class="swatches">${COLORS.map(c => `<button class="sw ${o.color === c ? 'on' : ''}" style="background:${c}" data-act="onbColor" data-v="${c}" aria-label="colour"></button>`).join('')}</div></div>
    <button class="btn" data-act="onbSave">Continue</button>
    <button class="link" data-act="onbSkip" style="margin:0 auto">Use sample jobs for the demo</button>
  </div>`;
};

S.onbWeek = () => `
  <div class="topbar">${back('onbJob')}<div class="steps"><i class="on"></i><i class="on"></i></div><span style="width:40px"></span></div>
  <div class="h1">When does your week start?</div>
  <p class="muted" style="margin-bottom:12px">Pick the first day of your pay week so your totals match your paycheque.</p>
  <div class="chips" style="margin-bottom:24px">${[1, 2, 3, 4, 5, 6, 0].map(d => `<button class="chip ${state.weekStart === d ? 'on' : ''}" data-act="week" data-v="${d}">${DOW[d]}</button>`).join('')}</div>
  <div class="card row" style="margin-bottom:12px">
    <div><div class="title-sm">Remind me after each shift</div><div class="sub-sm">15 min after your usual end time</div></div>
    <button class="toggle ${state.reminder ? 'on' : ''}" data-act="rem" aria-label="toggle reminder"></button>
  </div>
  <div class="card row" style="margin-bottom:24px">
    <div><div class="title-sm">Weekly tip goal</div><div class="sub-sm">Optional, you can change it later</div></div>
    <div class="money" style="width:110px"><span>$</span><input class="input" style="height:44px;font-size:16px" inputmode="numeric" value="${state.goal}" data-bind="goal"></div>
  </div>
  <button class="btn" data-go="home">Done</button>`;

S.home = () => {
  const r = rangeOf('week');
  const wk = state.shifts.filter(s => inRange(s, r));
  const tot = sum(wk, net), hrs = sum(wk, hoursOf), pay = sum(wk, s => wage(s) + net(s));
  const pct = Math.min(100, Math.round(tot / state.goal * 100));
  const mo = sum(state.shifts.filter(s => inRange(s, rangeOf('month'))), net);
  const recent = sorted().slice(0, 4);
  return `
  <div class="row" style="margin:4px 0 14px"><div class="brandmark"><span class="mark">${icon.logo}</span><span class="wm">protip<span>365</span></span></div><span class="sub-sm">Hi Maya</span></div>
  <div class="hero-card">
    ${icon.leaf}
    <div class="eyebrow">Your tips this week</div>
    <div class="big-total" style="margin:10px 0 6px">${money2(tot)}</div>
    <div class="sub-ink">tips you kept · ${wk.length} shifts logged</div>
    <div class="progress" style="margin:14px 0 6px"><i style="width:${pct}%"></i></div>
    <div class="sub-sm" style="margin-bottom:16px">${pct}% of your ${money(state.goal)} goal</div>
    <button class="btn pill" data-go="log1">${icon.plus.replace('<svg', '<svg width="20" height="20" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round"')} Add my tips</button>
  </div>
  <div class="kpis" style="margin:12px 0 4px">
    <div class="kpi tint-blush"><div class="eyebrow">This month</div><div class="v">${money(mo)}</div><div class="k">tips you kept</div></div>
    <div class="kpi tint-sage"><div class="eyebrow">Tips / hour</div><div class="v">${hrs ? money2(pay / hrs) : '$0'}</div><div class="k">wage + tips</div></div>
  </div>
  <div class="h2">Recent shifts</div>
  <div class="card" style="padding:4px 16px">${recent.map(shiftRow).join('')}</div>`;
};

function shiftRow(s) {
  const j = job(s.job);
  return `<div class="shift-row"><span class="dot" style="background:${j.color}"></span>
    <div><div class="title-sm">${j.name}</div><div class="sub-sm">${fmtDay(s.date)} · ${hoursOf(s).toFixed(1)} h</div></div>
    <div class="amt">${money2(net(s))}<small>${money2(perHour(s))}/h</small></div></div>`;
}

S.reminder = () => `
  <div class="lock">
    <div class="time">23:45</div><div class="date">Friday, October 2</div>
    <button class="notif" data-act="fromReminder">
      <span class="app">${icon.logo}</span>
      <span><b style="display:block;font-size:14px">ProTip365 · now</b>
      <span style="font-size:14px;opacity:.9">How did your shift at Bar Le Zinc go? Tap to add your tips (10 sec).</span></span>
    </button>
    <p style="text-align:center;font-size:12px;opacity:.6;margin-top:24px">Tap the notification</p>
  </div>`;

function ensureDraft(prefillJob) {
  if (!state.draft) {
    const last = sorted()[0];
    const j = job(prefillJob || (last ? last.job : state.jobs[0].id));
    state.draft = { job: j.id, date: TODAY, start: j.start, end: j.end, brk: 30, cash: '', card: '', tipIn: '', tipOut: '', sales: '', note: '', more: false };
  }
  return state.draft;
}

S.log1 = () => {
  const d = ensureDraft();
  const h = hoursOf(d);
  const yday = addDays(TODAY, -1);
  return `
  <div class="topbar">${back('home')}<div class="steps"><i class="on"></i><i></i></div><span style="width:40px"></span></div>
  <div class="h1">Log a shift</div>
  <div class="field" style="margin-bottom:16px"><label>Which job?</label>
    <div class="stack" style="gap:8px">${state.jobs.map(j => `
      <button class="job-pick ${d.job === j.id ? 'on' : ''}" data-act="pickJob" data-v="${j.id}">
        <span class="dot" style="background:${j.color};width:16px;height:16px"></span>
        <span><span class="title-sm" style="display:block">${j.name}</span><span class="sub-sm">${j.role} · ${money2(j.rate)}/h</span></span><span class="chk"></span>
      </button>`).join('')}
    </div></div>
  <div class="field" style="margin-bottom:16px"><label>When?</label>
    <div class="chips">
      <button class="chip ${d.date === TODAY ? 'on' : ''}" data-act="date" data-v="${TODAY}">Today</button>
      <button class="chip ${d.date === yday ? 'on' : ''}" data-act="date" data-v="${yday}">Yesterday</button>
      <label class="chip ${d.date !== TODAY && d.date !== yday ? 'on' : ''}" style="position:relative">${d.date !== TODAY && d.date !== yday ? fmtDay(d.date) : 'Other day'}<input type="date" data-bind="draft.date" style="position:absolute;inset:0;opacity:0" value="${d.date}"></label>
    </div></div>
  <div class="field" style="margin-bottom:12px"><label>Hours</label>
    <div class="time-grid">
      <div><div class="sub-sm" style="margin-bottom:4px">Start</div><input type="time" class="input" value="${d.start}" data-bind="draft.start"></div>
      <div><div class="sub-sm" style="margin-bottom:4px">End</div><input type="time" class="input" value="${d.end}" data-bind="draft.end"></div>
    </div></div>
  <div class="field" style="margin-bottom:16px"><label>Unpaid break</label>
    <div class="chips">${[0, 15, 30, 45, 60].map(b => `<button class="chip ${+d.brk === b ? 'on' : ''}" data-act="brk" data-v="${b}">${b ? b + ' min' : 'None'}</button>`).join('')}</div></div>
  <div class="row" style="margin-bottom:16px"><span class="calc-pill" id="hrsPill">${h.toFixed(2).replace(/\.?0+$/, '')} h worked</span><span class="sub-sm">Overnight works too</span></div>
  <button class="btn" data-go="log2">Next: tips</button>`;
};

S.log2 = () => {
  const d = ensureDraft();
  const j = job(d.job);
  const mf = (k, label, help) => `<div class="field"><label for="f_${k}">${label}</label><div class="money"><span>$</span><input id="f_${k}" class="input" inputmode="decimal" placeholder="0" value="${d[k]}" data-bind="draft.${k}"></div>${help ? `<div class="help">${help}</div>` : ''}</div>`;
  return `
  <div class="topbar">${back('log1')}<div class="steps"><i class="on"></i><i class="on"></i></div><span style="width:40px"></span></div>
  <div class="h1" style="margin-bottom:4px">Your tips</div>
  <p class="sub-sm" style="margin-bottom:16px"><span class="dot" style="display:inline-block;width:8px;height:8px;background:${j.color};vertical-align:middle"></span> ${j.name} · ${fmtDay(d.date)} · ${hoursOf(d).toFixed(1)} h</p>
  <div class="stack">
    ${mf('cash', 'Cash tips')}
    <div class="quick" style="margin-top:-6px">${[5, 10, 20, 50].map(v => `<button data-act="addCash" data-v="${v}">+${v}</button>`).join('')}</div>
    ${mf('card', 'Card tips', 'On your end-of-shift report')}
    ${mf('tipIn', 'Received from the pool', 'Tips other people shared with you')}
    ${mf('tipOut', 'Given to others (tip-out)', 'To bar, kitchen, bussers…')}
    <button class="link" data-act="more" style="text-align:left">${d.more ? '− Hide' : '+ More'}: sales & note</button>
    ${d.more ? `${mf('sales', 'Your sales (before tax)', 'Optional. Used for the Québec 8% check and your tip statement.')}
      <div class="field"><label for="f_note">Note</label><input id="f_note" class="input" placeholder="e.g. Hockey night, busy patio" value="${d.note}" data-bind="draft.note"></div>` : ''}
  </div>
  <div class="tip-sum">
    <div class="row" style="margin-bottom:10px"><span class="muted">You take home</span><span id="liveNet" style="font-family:var(--display);font-weight:600;font-size:26px">${money2(net(d))}</span></div>
    <button class="btn" data-act="save">Save shift</button>
  </div>`;
};

S.saved = () => {
  const s = state.lastSaved || sorted()[0];
  const j = job(s.job);
  const dow = d2(s.date).getDay();
  const same = state.shifts.filter(x => x.id !== s.id && d2(x.date).getDay() === dow && x.job === s.job);
  const avg = same.length ? sum(same, net) / same.length : 0;
  const diff = net(s) - avg;
  const pctSales = +s.sales ? ((+s.cash || 0) + (+s.card || 0)) / s.sales * 100 : null;
  return `
  <div class="success-ring">${icon.check}</div>
  <div class="h1" style="text-align:center;margin-bottom:4px">Shift saved</div>
  <p class="muted" style="text-align:center;margin-bottom:20px">${j.name} · ${fmtDay(s.date)}</p>
  <div class="kpis" style="margin-bottom:12px">
    <div class="kpi"><div class="k">Tips you made</div><div class="v">${money2(net(s))}</div></div>
    <div class="kpi"><div class="k">Real hourly</div><div class="v">${money2(perHour(s))}</div></div>
  </div>
  ${same.length ? `<div class="alert ${diff >= 0 ? 'ok' : ''}" style="margin-bottom:10px">${diff >= 0 ? '▲' : '▼'} ${money(Math.abs(diff))} ${diff >= 0 ? 'more' : 'less'} than your usual ${DOWL[dow]} at ${j.name}.</div>` : ''}
  ${pctSales !== null && pctSales < 8 ? `<div class="alert" style="margin-bottom:10px">Tips were ${pctSales.toFixed(1)}% of sales. Under 8%, your employer may add an allocation on your pay.</div>` : ''}
  <div class="stack" style="margin-top:16px">
    <button class="btn" data-go="home">Done</button>
    <div class="row"><button class="btn ghost small" data-act="undo" style="width:48%">Undo</button><button class="btn ghost small" data-act="edit" style="width:48%">Edit</button></div>
  </div>`;
};

S.calendar = () => {
  const mm = state.calMonth, mStr = '2026-' + String(mm).padStart(2, '0');
  const nDays = new Date(2026, mm, 0).getDate();
  const first = d2(mStr + '-01');
  const lead = (first.getDay() - state.weekStart + 7) % 7;
  const days = [];
  for (let i = 0; i < lead; i++) days.push(null);
  for (let d = 1; d <= nDays; d++) days.push(mStr + '-' + String(d).padStart(2, '0'));
  const order = [0, 1, 2, 3, 4, 5, 6].map(i => (state.weekStart + i) % 7);
  const selShifts = state.shifts.filter(s => s.date === state.calSel);
  const monthTot = sum(state.shifts.filter(s => s.date.startsWith(mStr)), net);
  return `
  <div class="row" style="margin:4px 0 4px"><div class="row" style="gap:8px"><button class="back" data-act="calMonth" data-v="9" aria-label="Previous month" ${mm === 9 ? 'disabled style="opacity:.3"' : ''}>${icon.back}</button><div class="h1" style="margin:0">${mm === 10 ? 'October' : 'September'}</div><button class="back" data-act="calMonth" data-v="10" aria-label="Next month" style="transform:scaleX(-1);${mm === 10 ? 'opacity:.3' : ''}">${icon.back}</button></div><div class="title-sm">${money(monthTot)}</div></div>
  <div class="chips" style="margin:10px 0 14px">${state.jobs.map(j => `<span class="sub-sm" style="display:inline-flex;align-items:center;gap:6px"><span class="dot" style="background:${j.color};width:8px;height:8px"></span>${j.name}</span>`).join('')}</div>
  <div class="cal">
    ${order.map(i => `<div class="dow">${DOW[i][0]}</div>`).join('')}
    ${days.map(dt => {
      if (!dt) return '<div class="d empty"></div>';
      const ss = state.shifts.filter(s => s.date === dt);
      const v = sum(ss, net);
      return `<button class="d ${dt === TODAY ? 'today' : ''} ${dt === state.calSel ? 'sel' : ''}" data-act="calSel" data-v="${dt}">
        <span>${+dt.slice(8)}</span>
        <span>${ss.length ? `<span class="ds">${ss.map(s => `<i style="background:${job(s.job).color}"></i>`).join('')}</span><span class="v">${money(v)}</span>` : ''}</span></button>`;
    }).join('')}
  </div>
  <div class="h2">${fmtDay(state.calSel)}</div>
  ${selShifts.length ? `<div class="card" style="padding:4px 16px">${selShifts.map(shiftRow).join('')}</div>`
    : `<div class="card" style="text-align:center"><p class="muted" style="margin-bottom:12px">No shift this day.</p><button class="btn small" data-act="logOn" data-v="${state.calSel}">Add a shift on this day</button></div>`}`;
};

S.stats = () => {
  const r = rangeOf(state.statsRange);
  const ss = state.shifts.filter(s => inRange(s, r));
  const tot = sum(ss, net), hrs = sum(ss, hoursOf), pay = sum(ss, s => wage(s) + net(s));
  const byJob = state.jobs.map(j => ({ j, v: sum(ss.filter(s => s.job === j.id), net) }));
  const maxJ = Math.max(1, ...byJob.map(x => x.v));
  const all = state.shifts;
  const byDow = [0, 1, 2, 3, 4, 5, 6].map(d => { const a = all.filter(s => d2(s.date).getDay() === d); return { d, avg: a.length ? sum(a, net) / a.length : 0 }; });
  const best = byDow.reduce((a, b) => b.avg > a.avg ? b : a);
  const maxD = Math.max(1, ...byDow.map(x => x.avg));
  const withSales = ss.filter(s => +s.sales);
  const pct = withSales.length ? sum(withSales, s => (+s.cash || 0) + (+s.card || 0)) / sum(withSales, s => +s.sales) * 100 : null;
  const label = { week: 'This week', month: 'October', year: '2026 so far' }[state.statsRange];
  return `
  <div class="h1">Stats</div>
  <div class="seg">${['week', 'month', 'year'].map(k => `<button class="${state.statsRange === k ? 'on' : ''}" data-act="range" data-v="${k}">${k[0].toUpperCase() + k.slice(1)}</button>`).join('')}</div>
  <div class="card" style="margin-bottom:10px"><div class="h-eyebrow">${label} · tips</div><div class="big-total" style="font-size:44px;margin-top:6px">${money(tot)}</div>
    <div class="sub-sm" style="margin-top:6px">${ss.length} shifts · ${hrs.toFixed(1)} h · total pay incl. wage ${money(pay)}</div></div>
  <div class="kpis" style="margin-bottom:10px">
    <div class="kpi"><div class="k">Real hourly</div><div class="v">${hrs ? money2(pay / hrs) : '—'}</div></div>
    <div class="kpi"><div class="k">Avg per shift</div><div class="v">${ss.length ? money(tot / ss.length) : '—'}</div></div>
  </div>
  ${state.statsRange === 'week' ? weekGlance() : ''}
  <div class="h2">By job</div>
  <div class="card bars">${byJob.map(x => `<div class="bar-row"><span>${x.j.name.split(' ').slice(-1)[0]}</span><span class="track"><i style="width:${x.v / maxJ * 100}%;background:${x.j.color}"></i></span><b>${money(x.v)}</b></div>`).join('')}</div>
  <div class="h2">Best day: ${DOWL[best.d]}</div>
  <div class="card bars">${[1, 2, 3, 4, 5, 6, 0].map(d => { const x = byDow[d]; return `<div class="bar-row"><span>${DOW[d]}</span><span class="track"><i style="width:${x.avg / maxD * 100}%;background:${d === best.d ? 'var(--green)' : '#D9D6C8'}"></i></span><b>${money(x.avg)}</b></div>`; }).join('')}
    <div class="sub-sm">Average tips per shift, all time</div></div>
  ${pct !== null ? `<div class="alert ${pct >= 8 ? 'ok' : ''}" style="margin-top:12px">Your tips are ${pct.toFixed(1)}% of sales. ${pct >= 8 ? 'Above the Québec 8% threshold, so no allocation is expected.' : 'Under 8%, so your employer may allocate the difference.'}</div>` : ''}`;
};

S.jobs = () => `
  <div class="h1">Me</div>
  <div class="h2" style="margin-top:0">My jobs</div>
  <div class="card" style="padding:4px 16px">
    ${state.jobs.map(j => `<div class="shift-row"><span class="dot" style="background:${j.color};width:16px;height:16px"></span><div><div class="title-sm">${j.name}</div><div class="sub-sm">${j.role} · ${money2(j.rate)}/h · usually ${j.start}–${j.end}</div></div><span class="amt sub-sm">Edit</span></div>`).join('')}
    <button class="list-btn" data-go="onbJob"><span class="ic">${icon.plus}</span><span class="title-sm">Add a job</span><span class="chev">›</span></button>
  </div>
  <div class="h2">Paperwork</div>
  <div class="card" style="padding:0 16px">
    <button class="list-btn" data-go="statement"><span class="ic">${icon.doc}</span><span><span class="title-sm" style="display:block">Tip statement for my boss</span><span class="sub-sm">Québec pay-period statement · PDF</span></span><span class="chev">›</span></button>
    <button class="list-btn" data-act="toast" data-v="2026 summary PDF ready: total tips by employer, for line 10400"><span class="ic">${icon.cal}</span><span><span class="title-sm" style="display:block">Year summary for taxes</span><span class="sub-sm">Jan 1 – Dec 31, by employer</span></span><span class="chev">›</span></button>
    <button class="list-btn" data-act="toast" data-v="CSV exported: 19 shifts"><span class="ic">${icon.dl}</span><span><span class="title-sm" style="display:block">Export all my data</span><span class="sub-sm">CSV · free, always</span></span><span class="chev">›</span></button>
  </div>
  <div class="h2">Settings</div>
  <div class="card" style="padding:0 16px">
    <div class="list-btn"><span class="ic">${icon.cloud}</span><span><span class="title-sm" style="display:block">Back up my data</span><span class="sub-sm">So you never lose it if you change phones</span></span><span class="chev link">Turn on</span></div>
    <div class="list-btn"><span class="ic">${icon.bell}</span><span class="title-sm">Shift reminders</span><button class="toggle ${state.reminder ? 'on' : ''}" data-act="rem" style="margin-left:auto" aria-label="toggle reminder"></button></div>
    <button class="list-btn" data-go="onbWeek"><span class="ic">${icon.cal}</span><span><span class="title-sm" style="display:block">Week starts on</span><span class="sub-sm">${DOWL[state.weekStart]}</span></span><span class="chev">›</span></button>
    <button class="list-btn" data-act="lang" data-v="${state.lang === 'en' ? 'fr' : 'en'}"><span class="ic">${icon.globe}</span><span class="title-sm">Language</span><span class="chev">${state.lang === 'en' ? 'English' : 'Français'}</span></button>
  </div>`;

S.statement = () => {
  const j = state.jobs[0];
  const a = weekStartOf(addDays(TODAY, -7)), b = addDays(TODAY, 0);
  const ss = state.shifts.filter(s => s.job === j.id && s.date >= a && s.date <= b).sort((x, y) => x.date.localeCompare(y.date));
  const T = k => sum(ss, s => +s[k] || 0);
  const B = T('cash') + T('card'), D = T('tipIn'), E = T('tipOut');
  return `
  <div class="topbar">${back('jobs')}<span class="title-sm">Tip statement</span><span style="width:40px"></span></div>
  <div class="card" style="margin-bottom:12px">
    <div class="row"><div><div class="title-sm">${j.name}</div><div class="sub-sm">Pay period ${fmtDay(a)} – ${fmtDay(b)}</div></div><span class="dot" style="background:${j.color};width:14px;height:14px"></span></div>
    <table class="sheet-table" style="margin-top:12px">
      <thead><tr><th>Day</th><th>Sales</th><th>B · Tips</th><th>D · In</th><th>E · Out</th></tr></thead>
      <tbody>${ss.map(s => `<tr><td>${fmtDay(s.date).slice(0, 10)}</td><td>${money(s.sales)}</td><td>${money2((+s.cash || 0) + (+s.card || 0))}</td><td>${money2(s.tipIn)}</td><td>${money2(s.tipOut)}</td></tr>`).join('')}
      <tr class="tot"><td>Total</td><td>${money(T('sales'))}</td><td>${money2(B)}</td><td>${money2(D)}</td><td>${money2(E)}</td></tr></tbody>
    </table>
  </div>
  <div class="card row" style="margin-bottom:10px"><div><div class="h-eyebrow">Net tips to declare</div><div class="sub-sm">B + C + D − E</div></div><div style="font-family:var(--display);font-weight:600;font-size:26px">${money2(B + D - E)}</div></div>
  <div class="alert ok" style="margin-bottom:16px">Tips are ${(B / Math.max(1, T('sales')) * 100).toFixed(1)}% of sales. Above 8%, so no allocation is expected.</div>
  <div class="stack">
    <button class="btn" data-act="toast" data-v="PDF ready: share by text, email or print">Share PDF with my manager</button>
    <p class="sub-sm" style="text-align:center">Based on Revenu Québec form TP-1019.4-V. Declare your tips in writing at the end of each pay period.</p>
  </div>`;
};

function weekGlance() {
  const a0 = rangeOf('week')[0];
  const days = [0, 1, 2, 3, 4, 5, 6].map(i => { const dt = addDays(a0, i); return { dt, v: sum(state.shifts.filter(s => s.date === dt), net) }; });
  const mx = Math.max(1, ...days.map(d => d.v));
  return `<div class="h2">Your week at a glance</div><div class="card"><div class="vbars">${days.map(d => `<div class="vb"><span class="vbv">${d.v ? money(d.v) : ''}</span><i style="height:${Math.max(4, d.v / mx * 96)}px;background:${d.dt === TODAY ? 'var(--clay)' : 'var(--sage)'}"></i><span class="sub-sm">${DOW[d2(d.dt).getDay()]}</span></div>`).join('')}</div></div>`;
}

function welcomeArt() {
  return `<div class="welcome-wrap"><div class="welcome-leaf">${icon.leaf}</div><div class="welcome-mark">${icon.logo}</div></div>`;
}

// ---------- render ----------
let current = 'welcome';
const NO_TABS = ['welcome', 'onbJob', 'onbWeek', 'reminder', 'log1', 'log2', 'saved', 'statement'];
const TAB_OF = { home: 'home', calendar: 'calendar', stats: 'stats', jobs: 'jobs' };

function go(id, opts = {}) {
  if (id === 'onbJob') state.onbReturn = current === 'jobs' ? 'jobs' : 'onbWeek';
  if (id === 'log1' && opts.fresh !== false && !['log2'].includes(current)) { if (!opts.keepDraft) state.draft = null; }
  current = id;
  render();
}
function render() {
  const scr = $('#screen');
  scr.innerHTML = S[current]();
  scr.scrollTop = 0;
  scr.classList.remove('enter'); void scr.offsetWidth; scr.classList.add('enter');
  $('#tabbar').classList.toggle('hide', NO_TABS.includes(current));
  document.querySelectorAll('#tabbar [data-go]').forEach(b => b.classList.toggle('on', TAB_OF[current] === b.dataset.go));
  // flow nav
  document.querySelectorAll('.flow-item').forEach(b => b.classList.toggle('active', b.dataset.screen === current));
  const idx = ORDER.indexOf(current);
  const n = NOTES[current];
  $('#notesStep').textContent = `Screen ${idx + 1} of ${ORDER.length}`;
  $('#notesTitle').textContent = n.t;
  $('#notesList').innerHTML = n.n.map(x => `<li>${x}</li>`).join('');
  $('#notesNext').innerHTML = `Next in the flow: <b>${n.next}</b>`;
}

function buildFlowNav() {
  let k = 0;
  $('#flowNav').innerHTML = FLOW.map(g => `<div class="flow-group"><h3>${g.group}</h3>${g.items.map(i => `<button class="flow-item" data-screen="${i.id}"><span class="n">${++k}</span>${i.label}</button>`).join('')}</div>`).join('');
  $('#flowNav').addEventListener('click', e => {
    const b = e.target.closest('.flow-item'); if (!b) return;
    const id = b.dataset.screen;
    if (id === 'log2') ensureDraft();
    if (id === 'saved' && !state.lastSaved) state.lastSaved = sorted()[0];
    current = id; render();
  });
}

function toast(msg) {
  const t = document.createElement('div');
  t.textContent = msg;
  Object.assign(t.style, { position: 'absolute', left: '16px', right: '16px', bottom: '96px', background: '#3F2A22', color: '#fff', padding: '14px 16px', borderRadius: '14px', fontSize: '14px', zIndex: 10, textAlign: 'center' });
  $('#phone').appendChild(t);
  setTimeout(() => t.remove(), 2200);
}

// ---------- events ----------
document.addEventListener('click', e => {
  const g = e.target.closest('[data-go]');
  if (g && $('#phone').contains(g)) { go(g.dataset.go); return; }
  const a = e.target.closest('[data-act]'); if (!a) return;
  const v = a.dataset.v;
  switch (a.dataset.act) {
    case 'lang': state.lang = v; if (current === 'jobs') toast('Language: ' + (v === 'fr' ? 'Français' : 'English')); render(); break;
    case 'onbRole': state.onbJob.role = v; render(); break;
    case 'onbColor': state.onbJob.color = v; render(); break;
    case 'onbSave': {
      const o = state.onbJob;
      if (o.name.trim()) {
        state.jobs.push({ id: 'j' + Date.now(), name: o.name.trim(), role: o.role, rate: parseFloat(o.rate) || 13.30, color: o.color, start: '17:00', end: '23:00' });
        state.onbJob = { name: '', role: 'Server', rate: '13.30', color: COLORS[state.jobs.length % COLORS.length] };
      }
      go(state.onbReturn || 'onbWeek'); break;
    }
    case 'onbSkip': go(state.onbReturn || 'onbWeek'); break;
    case 'week': state.weekStart = +v; render(); break;
    case 'rem': state.reminder = !state.reminder; a.classList.toggle('on'); break;
    case 'fromReminder': state.draft = null; ensureDraft('j1'); current = 'log1'; render(); break;
    case 'pickJob': { const d = ensureDraft(); const j = job(v); d.job = v; d.start = j.start; d.end = j.end; render(); break; }
    case 'date': ensureDraft().date = v; render(); break;
    case 'brk': ensureDraft().brk = +v; render(); break;
    case 'addCash': { const d = ensureDraft(); d.cash = String(((+d.cash || 0) + +v)); render(); break; }
    case 'more': { const d = ensureDraft(); d.more = !d.more; render(); break; }
    case 'save': {
      const d = ensureDraft();
      const s = { id: 's' + Date.now(), job: d.job, date: d.date, start: d.start, end: d.end, brk: d.brk, cash: +d.cash || 0, card: +d.card || 0, tipIn: +d.tipIn || 0, tipOut: +d.tipOut || 0, sales: +d.sales || 0, note: d.note };
      state.shifts.push(s); state.lastSaved = s; state.draft = null; go('saved'); break;
    }
    case 'undo': state.shifts = state.shifts.filter(s => s !== state.lastSaved); state.lastSaved = null; toast('Shift removed'); go('home'); break;
    case 'edit': {
      const s = state.lastSaved; if (!s) break;
      state.shifts = state.shifts.filter(x => x !== s);
      state.draft = { ...s, cash: s.cash || '', card: s.card || '', tipIn: s.tipIn || '', tipOut: s.tipOut || '', sales: s.sales || '', more: !!s.sales };
      current = 'log1'; render(); break;
    }
    case 'calSel': state.calSel = v; render(); break;
    case 'calMonth': state.calMonth = +v; state.calSel = +v === 10 ? TODAY : '2026-09-26'; render(); break;
    case 'logOn': state.draft = null; ensureDraft().date = v; current = 'log1'; render(); break;
    case 'range': state.statsRange = v; render(); break;
    case 'toast': toast(v); break;
  }
});

document.addEventListener('input', e => {
  const b = e.target.dataset.bind; if (!b) return;
  const val = e.target.value;
  if (b === 'goal') { state.goal = +val || 0; return; }
  const [obj, key] = b.split('.');
  if (obj === 'onb') { state.onbJob[key] = val; return; }
  if (obj === 'draft') {
    const d = ensureDraft(); d[key] = val;
    const live = $('#liveNet'); if (live) live.textContent = money2(net(d));
    const pill = $('#hrsPill'); if (pill) pill.textContent = hoursOf(d).toFixed(2).replace(/\.?0+$/, '') + ' h worked';
    if (key === 'date') render();
  }
});

const TABBAR = () => `<nav class="tabbar">
  <button class="TAB_home"><svg viewBox="0 0 24 24"><path d="M3 11l9-7 9 7v9a1 1 0 01-1 1h-5v-6H9v6H4a1 1 0 01-1-1z"/></svg>Home</button>
  <button class="TAB_calendar"><svg viewBox="0 0 24 24"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/></svg>Calendar</button>
  <button class="tab-plus"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg></button>
  <button class="TAB_stats"><svg viewBox="0 0 24 24"><path d="M4 20V10M10 20V4M16 20v-7M22 20H2"/></svg>Stats</button>
  <button class="TAB_jobs"><svg viewBox="0 0 24 24"><circle cx="12" cy="8" r="4"/><path d="M4 21c1-4 4-6 8-6s7 2 8 6"/></svg>Me</button></nav>`;

function phoneFor(id) {
  const tabs = NO_TABS.includes(id) ? '' : TABBAR().replace('class="TAB_' + (TAB_OF[id] || 'x') + '"', 'class="on"');
  return `<div class="phone static" aria-hidden="true"><div class="notch"></div><div class="statusbar"><span>9:41</span><span class="sb-icons">●●● ▮</span></div><div class="screen">${S[id]()}</div>${tabs}</div>`;
}

function prepFor(id) {
  if (id === 'onbJob') state.onbJob = { name: 'Bar Le Zinc', role: 'Bartender', rate: '13.30', color: COLORS[0] };
  if (id === 'log1' || id === 'log2') state.draft = { job: 'j1', date: TODAY, start: '17:00', end: '23:30', brk: 30, cash: '60', card: '142', tipIn: '', tipOut: '28', sales: '', note: '', more: false };
  if (id === 'saved') state.lastSaved = { id: 'demo', job: 'j1', date: TODAY, start: '17:00', end: '23:30', brk: 30, cash: 60, card: 142, tipIn: 0, tipOut: 28, sales: 1290, note: '' };
  if (id === 'calendar') state.calSel = '2026-10-01';
  if (id === 'stats') state.statsRange = 'week';
}

function buildShowcase() {
  const hero = $('#heroPhone'); if (hero) hero.innerHTML = phoneFor('home');
  const host = $('#screens');
  let k = 0;
  host.innerHTML = FLOW.map(g => `
    <div class="stage-head" id="stage-${g.group.toLowerCase().replace(/\s+/g, '-')}"><span class="eyebrow">${g.group}</span></div>
    ${g.items.map(it => {
      prepFor(it.id); k++;
      const n = NOTES[it.id];
      return `<article class="shot ${k % 2 ? '' : 'flip'}" id="screen-${it.id}">
        <div class="shot-phone">${phoneFor(it.id)}</div>
        <div class="shot-copy">
          <div class="shot-num"><span>${String(k).padStart(2, '0')}</span>${it.label}</div>
          <h3>${n.t}</h3>
          <ul>${n.n.map(x => `<li>${x}</li>`).join('')}</ul>
          <div class="shot-next">Next → <b>${n.next}</b></div>
        </div></article>`;
    }).join('')}`).join('');
  const nav = $('#flowOverview');
  if (nav) { let j = 0; nav.innerHTML = FLOW.map((g, gi) => `<div class="ov-card ov-${gi}"><div class="eyebrow">${String(gi + 1).padStart(2, '0')} · ${g.group}</div><ol>${g.items.map(it => `<li><a href="#screen-${it.id}"><span>${++j}</span>${it.label}</a></li>`).join('')}</ol></div>`).join(''); }
}

if (document.body.dataset.mode === 'showcase') buildShowcase();
else { buildFlowNav(); render(); }
})();

window.LAND = {
  en: {
    title: "Tip Tracker & Shift Planner for Servers | ProTip365",
    desc: "Log your shifts and tips for every job in seconds. See what you really make this week, this month and this year. ProTip365 is a private tip tracker for servers and bartenders.",
    s: {
      navFlow: "The flow", navScreens: "Screens", navDemo: "Demo", navCta: "Get it on Google Play",
      heroEyebrow: "Tip & shift tracker · Québec",
      heroH1: "Your shifts.<br>Your tips.",
      heroLede: "Log a shift in ten seconds. See what you really make this week, this month and this year, across every job you work.",
      ctaPlay: "Get it on Google Play", ctaDemo: "Try the demo",
      iosNote: "<strong>Coming soon for iOS.</strong> Same app, same records.",
      k1Label: "Screens", k1Note: "one simple flow",
      k2Label: "To log a shift", k2Note: "pre-filled from your schedule",
      k3Label: "Jobs", k3Value: "All of them", k3Note: "every employer, one app",
      flowEyebrow: "The user flow", flowH2: "Four moments. That's the whole app.",
      flowSub: "Set it up once, log every shift, check your money, and handle the paperwork. Tap a screen to jump to it.",
      scrEyebrow: "Screen by screen", scrH2: "Every screen, and why it's built that way.", scrSub: "Screens shown with sample data.",
      closeEyebrow: "Get started", closeH2: "Log a shift. Watch your week add up.",
      closeSub: "Download ProTip365 on Android, or try the interactive demo right here in your browser. It runs on sample data and every number updates as you go.",
      footTag: "Built for servers, bartenders and bussers",
      footPrivacy: "Privacy", footTerms: "Terms", footSupport: "Support",
      nextPrefix: "Next → "
    },
    groups: ["First launch", "Every shift", "Check my money", "Paperwork"],
    phone: { eyebrow: "Your tips this week", kept: "tips you kept", logged: "shifts logged", btn: "Add my tips", goal: "{p}% of your ${v} goal", m1e: "This month", m1k: "tips you kept", m2e: "Tips / hour", m2k: "wage + tips", recent: "Recent shifts" }
  },
  fr: {
    title: "Tes quarts. Tes pourboires. | ProTip365",
    desc: "Ajoute tes quarts et tes pourboires pour tous tes emplois en quelques secondes. Vois ce que tu gagnes vraiment — cette semaine, ce mois, cette année. ProTip365 est un suivi de pourboires privé pour serveuses, serveurs et personnel de bar.",
    s: {
      navFlow: "Le parcours", navScreens: "Écrans", navDemo: "Démo", navCta: "Disponible sur Google Play",
      heroEyebrow: "Suivi de quarts et de pourboires · Québec",
      heroH1: "Tes quarts.<br>Tes pourboires.",
      heroLede: "Ajoute un quart en dix secondes. Vois ce que tu gagnes vraiment — cette semaine, ce mois, cette année — peu importe le nombre d'emplois.",
      ctaPlay: "Disponible sur Google Play", ctaDemo: "Essayer la démo",
      iosNote: "<strong>Bientôt sur iOS.</strong> La même appli, les mêmes données.",
      k1Label: "Écrans", k1Note: "un parcours tout simple",
      k2Label: "Pour ajouter un quart", k2Note: "prérempli à partir de ton horaire",
      k3Label: "Emplois", k3Value: "Illimités", k3Note: "tous tes employeurs, une seule appli",
      flowEyebrow: "Le parcours utilisateur", flowH2: "Quatre moments. C'est toute l'appli.",
      flowSub: "On configure une fois, on ajoute chaque quart, on vérifie son argent et on s'occupe du papier. Touche un écran pour y sauter.",
      scrEyebrow: "Écran par écran", scrH2: "Chaque écran, et pourquoi il est conçu ainsi.", scrSub: "Écrans affichés avec des données de démonstration.",
      closeEyebrow: "Pour commencer", closeH2: "Ajoute un quart. Regarde ta semaine s'additionner.",
      closeSub: "Télécharge ProTip365 sur Android, ou essaie la démo interactive ici même dans ton navigateur. Elle tourne sur des données d'exemple et chaque nombre se met à jour.",
      footTag: "Pensé pour le personnel de salle et de bar",
      footPrivacy: "Confidentialité", footTerms: "Conditions", footSupport: "Support",
      nextPrefix: "Ensuite → "
    },
    groups: ["Premier lancement", "Chaque quart", "Voir mon argent", "Papier"],
    phone: { eyebrow: "Tes pourboires cette semaine", kept: "pourboires gardés", logged: "quarts enregistrés", btn: "Ajouter mes pourboires", goal: "{p} % de ton objectif de {v} $", m1e: "Ce mois-ci", m1k: "pourboires gardés", m2e: "Pourboires / heure", m2k: "salaire + pourboires", recent: "Quarts récents" },
    items: { welcome: "Bienvenue", onbJob: "Ajouter un premier emploi", onbWeek: "Semaine et rappel", reminder: "Rappel de fin de quart", log1: "Ajouter un quart · emploi et heures", log2: "Ajouter un quart · pourboires", saved: "Quart enregistré", home: "Accueil · cette semaine", calendar: "Calendrier", stats: "Statistiques · semaine/mois/année", jobs: "Moi · emplois et exports", statement: "Relevé de pourboires (Québec)" },
    notes: {
      welcome: { t: "On commence en un geste, sans compte", n: ["Choisis ta langue au départ. Tout le reste peut attendre.", "Aucun mur de connexion. Les données restent sur le téléphone jusqu'à ce que tu choisisses de les sauvegarder — les concurrents se font critiquer pour ça.", "L'importateur aide les gens qui arrivent de ServerLife, TipKeepr ou d'un tableur."], next: "Ajouter un premier emploi" },
      onbJob: { t: "Un emploi, trois champs", n: ["Seul le nom de l'employeur est obligatoire. Le poste et le taux sont déjà remplis.", "Le taux par défaut est le salaire minimum au pourboire du Québec (13,30 $/h depuis le 1er mai 2026), modifiable en tout temps.", "Chaque emploi reçoit une couleur qui le suit partout : calendrier, listes et graphiques."], next: "Semaine et rappel" },
      onbWeek: { t: "Une semaine alignée sur la paie", n: ["La personne choisit le premier jour de sa semaine, pour que les totaux suivent sa vraie période de paie. C'est la correction la plus demandée dans les avis des concurrents.", "Le rappel de fin de quart est activé par défaut : c'est lui qui garde les données complètes.", "C'est le dernier écran de configuration. Quelqu'un de nouveau arrive à l'accueil en environ 30 secondes."], next: "Accueil" },
      reminder: { t: "La relance qui ouvre l'étape 1", n: ["Le rappel part 15 minutes après l'heure habituelle de fin.", "Un appui ouvre l'ajout de quart avec l'emploi, la date et les heures déjà remplis. La plupart du temps, il ne reste qu'à taper les pourboires.", "Si on le glisse de côté, il revient le lendemain matin. Le ton ne harcèle jamais."], next: "Ajouter un quart · emploi et heures" },
      log1: { t: "Quel emploi, quand, combien d'heures", n: ["Emploi, date et heures sont préremplis à partir du rappel ou du dernier quart. Souvent, rien à changer.", "On saisit l'heure de début et de fin, pas des « heures travaillées ». L'appli calcule tout, y compris les quarts de nuit et les pauses.", "Plusieurs quarts le même jour sont permis : un lunch au Chez Lou, une soirée au Zinc."], next: "Pourboires" },
      log2: { t: "Des pourboires en mots simples", n: ["Quatre montants : comptant, carte, reçus du partage et donnés aux autres. Chaque champ est optionnel.", "Le total que tu gardes se met à jour en direct en bas : aucun calcul à faire.", "Les ventes et la note sont repliées sous « Plus ». Elles ne servent qu'au vérificateur du 8 % et au relevé."], next: "Quart enregistré" },
      saved: { t: "La récompense, tout de suite", n: ["Une confirmation claire avec les deux chiffres qui comptent : les pourboires et le vrai taux horaire.", "La comparaison avec la moyenne de ce jour de semaine donne une raison de revenir.", "Annuler et Modifier sont là, à portée de main : ça installe la confiance."], next: "Accueil" },
      calendar: { t: "Le mois d'un coup d'œil", n: ["Chaque jour affiche les pourboires nets et des pastilles de couleur par emploi.", "Un appui sur un jour liste ses quarts en dessous; un appui sur un quart le modifie.", "Les quarts planifiés pourraient s'afficher en contour plus tard (V2 : import d'horaire)."], next: "Statistiques" },
      stats: { t: "Semaine · Mois · Année, en un geste", n: ["Trois plages fixes, sans sélecteur de dates. Une plage personnalisée arrive en V2.", "La répartition par employeur et le meilleur jour de la semaine : les chiffres que le personnel demande le plus.", "Le vérificateur du 8 % du Québec s'affiche quand les ventes ont été saisies."], next: "Moi" },
      jobs: { t: "Emplois, exports, sauvegarde", n: ["Un nombre illimité d'emplois, gratuitement. Les concurrents facturent environ 6 $ par emploi additionnel.", "Les exports sont gratuits : relevé par période de paie, sommaire annuel pour la ligne 10400, CSV.", "La sauvegarde est optionnelle, expliquée en une phrase. Proposée, jamais imposée."], next: "Relevé de pourboires" },
      statement: { t: "Le relevé de pourboires du Québec, généré", n: ["La même structure que le formulaire TP-1019.4-V de Revenu Québec : B pourboires reçus, D pourboires du partage, E pourboires donnés. Net = B + C + D − E.", "Un geste partage le PDF au gestionnaire à chaque période de paie — une obligation légale dans les restaurants et les bars.", "Cette fonction n'existe dans aucune appli américaine : c'est une raison forte de choisir ProTip365 au Québec."], next: "Retour à l'accueil" }
    }
  },
  es: {
    title: "Tus turnos. Tus propinas. | ProTip365",
    desc: "Registra tus turnos y propinas de todos tus trabajos en segundos. Mira lo que de verdad ganas esta semana, este mes y este año. ProTip365 es un rastreador privado de propinas para meseros y bartenders.",
    s: {
      navFlow: "El recorrido", navScreens: "Pantallas", navDemo: "Demo", navCta: "Disponible en Google Play",
      heroEyebrow: "Control de turnos y propinas · Quebec",
      heroH1: "Tus turnos.<br>Tus propinas.",
      heroLede: "Registra un turno en diez segundos. Mira lo que de verdad ganas esta semana, este mes y este año, con todos tus trabajos.",
      ctaPlay: "Disponible en Google Play", ctaDemo: "Probar la demo",
      iosNote: "<strong>Muy pronto en iOS.</strong> La misma app, los mismos datos.",
      k1Label: "Pantallas", k1Note: "un recorrido sencillo",
      k2Label: "Para registrar un turno", k2Note: "precargado desde tu horario",
      k3Label: "Trabajos", k3Value: "Todos", k3Note: "todos tus empleos, una sola app",
      flowEyebrow: "El recorrido", flowH2: "Cuatro momentos. Eso es toda la app.",
      flowSub: "Configura una vez, registra cada turno, consulta tu dinero y resuelve los trámites. Toca una pantalla para saltar a ella.",
      scrEyebrow: "Pantalla por pantalla", scrH2: "Cada pantalla, y por qué está así diseñada.", scrSub: "Pantallas con datos de ejemplo.",
      closeEyebrow: "Para empezar", closeH2: "Registra un turno. Mira cómo suma tu semana.",
      closeSub: "Descarga ProTip365 en Android, o prueba la demo interactiva aquí en tu navegador. Usa datos de ejemplo y cada cifra se actualiza.",
      footTag: "Hecho para meseros, bartenders y asistentes",
      footPrivacy: "Privacidad", footTerms: "Términos", footSupport: "Soporte",
      nextPrefix: "Después → "
    },
    groups: ["Primer inicio", "Cada turno", "Consultar mi dinero", "Trámites"],
    phone: { eyebrow: "Tus propinas esta semana", kept: "propinas netas", logged: "turnos registrados", btn: "Añadir mis propinas", goal: "{p} % de tu meta de {v} $", m1e: "Este mes", m1k: "propinas netas", m2e: "Propinas / hora", m2k: "salario + propinas", recent: "Turnos recientes" },
    items: { welcome: "Bienvenida", onbJob: "Añadir el primer trabajo", onbWeek: "Semana y recordatorio", reminder: "Recordatorio de fin de turno", log1: "Registrar turno · trabajo y horas", log2: "Registrar turno · propinas", saved: "Turno guardado", home: "Inicio · esta semana", calendar: "Calendario", stats: "Estadísticas · semana/mes/año", jobs: "Yo · trabajos y exportaciones", statement: "Estado de propinas (Quebec)" },
    notes: {
      welcome: { t: "Empieza en un toque, sin cuenta", n: ["Elige tu idioma al empezar. Todo lo demás puede esperar.", "Sin muro de registro. Los datos quedan en el teléfono hasta que decidas respaldarlos; a las apps rivales las critican por exigir cuenta primero.", "El importador ayuda a quien llega de ServerLife, TipKeepr o una hoja de cálculo."], next: "Añadir el primer trabajo" },
      onbJob: { t: "Un trabajo, tres campos", n: ["Solo el nombre del empleador es obligatorio. El puesto y la tarifa ya vienen listos.", "La tarifa por omisión es el salario mínimo con propinas de Quebec (13,30 $/h desde el 1 de mayo de 2026); se puede cambiar.", "Cada trabajo recibe un color que lo sigue a todas partes: calendario, listas y gráficos."], next: "Semana y recordatorio" },
      onbWeek: { t: "Una semana que sigue tu paga", n: ["La persona elige el día en que empieza su semana, para que los totales cuadren con su período real de pago. Es lo más pedido en las reseñas de las apps rivales.", "El recordatorio de fin de turno viene activado: es el hábito que mantiene los datos completos.", "Es la última pantalla de configuración. Alguien nuevo llega al inicio en unos 30 segundos."], next: "Inicio" },
      reminder: { t: "El aviso que abre el paso 1", n: ["El recordatorio llega 15 minutos después de la hora habitual de salida.", "Al tocarlo se abre el registro del turno con el trabajo, la fecha y las horas ya listos: casi siempre solo falta escribir las propinas.", "Si se desliza, se pospone a la mañana siguiente. Nunca insiste más de la cuenta."], next: "Registrar turno · trabajo y horas" },
      log1: { t: "Qué trabajo, cuándo, cuántas horas", n: ["Trabajo, fecha y horas vienen precargados desde el recordatorio o del último turno. Normalmente no hay que cambiar nada.", "Se captura hora de entrada y de salida, no «horas trabajadas». La app calcula todo: turnos nocturnos y pausas incluidos.", "Se permiten varios turnos el mismo día: un almuerzo en un lugar y una cena en otro."], next: "Propinas" },
      log2: { t: "Propinas en palabras simples", n: ["Cuatro montos: efectivo, tarjeta, recibidos del fondo y entregados a otros. Todos opcionales.", "El total que te llevas se actualiza al instante abajo: cero cálculos mentales.", "Ventas y nota van plegados en «Más». Solo sirven para la verificación del 8 % y el estado de cuenta."], next: "Turno guardado" },
      saved: { t: "La recompensa inmediata", n: ["Confirmación clara con los dos números que importan: propinas ganadas y tarifa horaria real.", "La comparación con tu promedio de ese día de semana da una razón para volver.", "Deshacer y Editar están ahí mismo: eso genera confianza."], next: "Inicio" },
      calendar: { t: "El mes de un vistazo", n: ["Cada día muestra las propinas netas y puntos de color por trabajo.", "Tocar un día lista sus turnos; tocar un turno lo edita.", "Los turnos planeados podrían mostrarse en contorno más adelante (V2: importar horario)."], next: "Estadísticas" },
      stats: { t: "Semana · Mes · Año, en un toque", n: ["Tres rangos fijos, sin selectores de fecha. Un rango personalizado llega en V2.", "Reparto por empleador y mejor día de la semana: los datos que el personal de sala más pide.", "Aviso del 8 % de Quebec cuando se capturaron las ventas."], next: "Yo" },
      jobs: { t: "Trabajos, exportaciones, respaldo", n: ["Trabajos ilimitados y gratis. Las apps rivales cobran unos 6 $ por trabajo extra.", "Las exportaciones son gratuitas: estado por período de pago, resumen anual para la línea 10400, CSV.", "El respaldo es opcional y se explica en una línea. Se ofrece, nunca se impone."], next: "Estado de propinas" },
      statement: { t: "Estado de propinas de Quebec, generado", n: ["La misma estructura del formulario TP-1019.4-V de Revenu Québec: B propinas recibidas, D del reparto, E entregadas. Neto = B + C + D − E.", "Un toque comparte el PDF con el gerente cada período de pago: obligación legal en restaurantes y bares.", "Ninguna app estadounidense ofrece esto: una razón fuerte para elegir ProTip365 en Quebec."], next: "Volver al inicio" }
    }
  }
};

window.initI18n = function () {
  if (document.body.dataset.mode !== 'showcase') return;
  var q = new URLSearchParams(location.search).get('lang');
  var lang = q || localStorage.getItem('pt365lang');
  if (['fr', 'en', 'es'].indexOf(lang) < 0) {
    var nav = (navigator.language || 'en').slice(0, 2).toLowerCase();
    lang = ['fr', 'en', 'es'].indexOf(nav) >= 0 ? nav : 'en';
  }
  var ORDER = ['welcome', 'onbJob', 'onbWeek', 'reminder', 'log1', 'log2', 'saved', 'home', 'calendar', 'stats', 'jobs', 'statement'];

  function apply(lang) {
    var L = window.LAND[lang]; if (!L) return;
    localStorage.setItem('pt365lang', lang);
    document.documentElement.lang = lang;
    document.title = L.title;
    var md = document.querySelector('meta[name="description"]'); if (md) md.setAttribute('content', L.desc);
    document.querySelectorAll('[data-i18n]').forEach(function (el) { var k = el.getAttribute('data-i18n'); if (L.s[k] != null) el.textContent = L.s[k]; });
    document.querySelectorAll('[data-i18n-html]').forEach(function (el) { var k = el.getAttribute('data-i18n-html'); if (L.s[k] != null) el.innerHTML = L.s[k]; });

    document.querySelectorAll('.stage-head .eyebrow').forEach(function (el, i) { if (L.groups[i]) el.textContent = L.groups[i]; });
    document.querySelectorAll('.ov-card').forEach(function (card, gi) {
      var eb = card.querySelector('.eyebrow'); if (eb && L.groups[gi]) eb.textContent = String(gi + 1).padStart(2, '0') + ' · ' + L.groups[gi];
      card.querySelectorAll('ol a').forEach(function (a, ii) {
        var span = a.querySelector('span'), lbl = ORDER[gi * 3 + ii] ? (L.items[ORDER[gi * 3 + ii]] || a.lastChild.nodeValue) : null;
        if (span && lbl != null) { a.lastChild.nodeValue = lbl; }
      });
    });

    document.querySelectorAll('article.shot').forEach(function (art) {
      var id = art.id.replace('screen-', ''), tr = L.notes && L.notes[id]; if (!tr) return;
      var num = art.querySelector('.shot-num'); if (num && num.lastChild) num.lastChild.nodeValue = ' ' + (L.items[id] || '');
      var h3 = art.querySelector('h3'); if (h3) h3.textContent = tr.t;
      var lis = art.querySelectorAll('ul li');
      tr.n.forEach(function (txt, i) { if (lis[i]) lis[i].textContent = txt; });
      var nx = art.querySelector('.shot-next');
      if (nx) { nx.firstChild.nodeValue = L.s.nextPrefix; nx.querySelector('b').textContent = tr.next; }
    });

    // hero phone (Home mockup) key strings
    var ph = L.phone || window.LAND.en.phone;
    document.querySelectorAll('.hero-card').forEach(function (hc) {
      var eb = hc.querySelector('.eyebrow'); if (eb) eb.textContent = ph.eyebrow;
      var sk = hc.querySelector('.sub-ink');
      if (sk) { var m = sk.textContent.match(/(\d+)/); sk.textContent = ph.kept + ' · ' + (m ? m[1] : '3') + ' ' + ph.logged; }
      var btn = hc.querySelector('.btn'); if (btn && btn.lastChild) btn.lastChild.nodeValue = ' ' + ph.btn;
      var sm = hc.querySelector('.sub-sm');
      if (sm) {
        var g = sm.textContent.match(/(\d+)%\s+of your \$([\d,]+) goal/);
        if (g) sm.textContent = ph.goal.replace('{p}', g[1]).replace('{v}', g[2]);
      }
    });
    document.querySelectorAll('#heroPhone .kpi').forEach(function (k, i) {
      var eb = k.querySelector('.eyebrow'), kk = k.querySelector('.k');
      if (i === 0) { if (eb) eb.textContent = ph.m1e; if (kk) kk.textContent = ph.m1k; }
      if (i === 1) { if (eb) eb.textContent = ph.m2e; if (kk) kk.textContent = ph.m2k; }
    });
    var h2s = document.querySelectorAll('#heroPhone .h2'); if (h2s[0]) h2s[0].textContent = ph.recent;

    // phone mockup polish: tab labels, greeting, weekday/month abbreviations
    var TABS = { fr: ['Accueil', 'Calendrier', 'Statistiques', 'Moi'], es: ['Inicio', 'Calendario', 'Estadísticas', 'Yo'], en: ['Home', 'Calendar', 'Stats', 'Me'] };
    var HI = { fr: 'Salut Maya', es: 'Hola Maya', en: 'Hi Maya' };
    var DOWM = {
      fr: { Sun: 'dim.', Mon: 'lun.', Tue: 'mar.', Wed: 'mer.', Thu: 'jeu.', Fri: 'ven.', Sat: 'sam.', Jan: 'janv.', Feb: 'févr.', Mar: 'mars', Apr: 'avr.', May: 'mai', Jun: 'juin', Jul: 'juil.', Aug: 'août', Sep: 'sept.', Oct: 'oct.', Nov: 'nov.', Dec: 'déc.' },
      es: { Sun: 'dom.', Mon: 'lun.', Tue: 'mar.', Wed: 'mié.', Thu: 'jue.', Fri: 'vie.', Sat: 'sáb.', Jan: 'ene.', Feb: 'feb.', Mar: 'mar.', Apr: 'abr.', May: 'may', Jun: 'jun.', Jul: 'jul.', Aug: 'ago.', Sep: 'sep.', Oct: 'oct.', Nov: 'nov.', Dec: 'dic.' }
    };
    document.querySelectorAll('.tabbar button').forEach(function (b) {
      var t = (b.textContent || '').trim(); var i = ['Home', 'Calendar', 'Stats', 'Me'].indexOf(t);
      if (i >= 0 && b.lastChild) b.lastChild.nodeValue = ' ' + TABS[lang][i];
    });
    document.querySelectorAll('.sub-sm').forEach(function (el) { if (el.textContent.trim() === 'Hi Maya') el.textContent = HI[lang]; });
    if (DOWM[lang]) {
      document.querySelectorAll('.shift-row .sub-sm, .sub-sm').forEach(function (el) {
        if (/^[A-Z][a-z]{2} [A-Z][a-z]{2} \d{1,2}/.test(el.textContent)) {
          el.textContent = el.textContent.replace(/\b([A-Z][a-z]{2})\b/g, function (w) { return DOWM[lang][w] || w; });
        }
      });
    }

    document.querySelectorAll('.lp-lang button').forEach(function (b) { b.classList.toggle('on', b.dataset.lang === lang); });
  }

  document.querySelectorAll('.lp-lang button').forEach(function (b) {
    b.addEventListener('click', function () {
      var l = b.dataset.lang; apply(l);
      try { history.replaceState(null, '', '?lang=' + l); } catch (e) {}
    });
  });
  apply(lang);
};
