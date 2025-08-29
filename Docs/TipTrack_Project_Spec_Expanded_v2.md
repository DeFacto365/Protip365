# TipTrack Project – Comprehensive Specification (MVP)

## Vision and Goal
TipTrack is a cross‑platform solution for tipped workers to replace paper notes and Excel with a modern app.  
The app will make it simple to **record shifts**, **track income**, **set targets**, and **export reports**.

- **Target users**: waitresses, bartenders, and anyone paid with base hourly + tips.  
- **Platforms**: iOS, Android, and Web (one‑pager).  
- **Backend**: Supabase (Auth, Postgres, Row Level Security).  
- **Design**: Apple’s Liquid Glass UI (iOS 26) for a native and modern look.  
- **Version control**: GitHub repository, managed with Cursor for AI‑assisted development.

---

## Problem Statement
Today, tipped workers often use paper slips and Excel to calculate income. This is prone to error and time‑consuming. They lack:  
- Instant visibility of daily, weekly, and monthly totals.  
- Simple dashboards for targets and progress.  
- Centralized data accessible across iPhone, iPad, laptop, or Android.  

TipTrack solves this with a **central Supabase database**, a **clean Apple‑style interface**, and **exports for peace of mind**.

---

## Core Features

### Authentication
- Sign up with email and password (Supabase Auth).  
- Face ID, Touch ID, or passcode unlock.  
- Secure session tokens, persisted in Secure Storage.

### Shift Entry
- Inputs: date, hours, hourly rate, sales, tips, notes.  
- Auto‑fill hourly rate from user profile if blank.  
- Quick add from home screen.

### Dashboard
- Daily income = base (hours × rate) + tips.  
- Weekly totals (respecting week start preference).  
- Monthly totals.  
- Tip targets vs actual (daily, weekly, monthly).  
- Cards styled with `.regularMaterial` to match Apple’s Liquid Glass.

### Reports
- Export daily/weekly/monthly data as CSV or PDF.  
- Send via email.  
- Totals at the bottom of exported reports.

### Settings
- Default hourly rate.  
- Week start day (Sunday, Monday, etc.).  
- Tip targets (daily/weekly/monthly).  
- Toggle Face ID / passcode.

### Sync
- Centralized Supabase database ensures all devices stay consistent.

---

## Database Schema

### users_profile
```sql
create table public.users_profile (
  user_id uuid primary key references auth.users(id) on delete cascade,
  default_hourly_rate numeric(10,2) not null default 0,
  week_start int not null default 0,
  target_tip_daily numeric(10,2) not null default 0,
  target_tip_weekly numeric(10,2) not null default 0,
  target_tip_monthly numeric(10,2) not null default 0,
  created_at timestamptz not null default now()
);
```

### shifts
```sql
create table public.shifts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  shift_date date not null,
  hours numeric(6,2) not null check (hours >= 0),
  hourly_rate numeric(10,2) not null check (hourly_rate >= 0),
  sales numeric(12,2) not null check (sales >= 0),
  tips numeric(12,2) not null check (tips >= 0),
  notes text,
  created_at timestamptz not null default now()
);
```

### v_shift_income
```sql
create view public.v_shift_income as
select
  s.*,
  (s.hours * s.hourly_rate) as base_income,
  (s.hours * s.hourly_rate) + s.tips as total_income
from public.shifts s;
```

---

## Row Level Security (RLS)
```sql
alter table public.users_profile enable row level security;
alter table public.shifts enable row level security;

create policy "profile_is_own"
on public.users_profile for all
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "shifts_are_own"
on public.shifts for all
using (user_id = auth.uid())
with check (user_id = auth.uid());
```

---

## Report Functions

### Daily totals
```sql
create or replace function public.totals_by_day(p_user uuid, p_day date)
returns table(hours numeric, sales numeric, tips numeric, base_income numeric, total_income numeric)
language sql stable as $$
  select coalesce(sum(hours),0),
         coalesce(sum(sales),0),
         coalesce(sum(tips),0),
         coalesce(sum(hours*hourly_rate),0),
         coalesce(sum(hours*hourly_rate + tips),0)
  from public.shifts
  where user_id = p_user and shift_date = p_day;
$$;
```

### Week totals
```sql
create or replace function public.week_range(p_day date, p_week_start int)
returns table(start_date date, end_date date)
language sql immutable as $$
  select (p_day - ((extract(dow from p_day)::int - p_week_start + 7) % 7))::date,
         ((p_day - ((extract(dow from p_day)::int - p_week_start + 7) % 7))::date + 6);
$$;

create or replace function public.totals_by_week(p_user uuid, p_day date)
returns table(start_date date, end_date date, hours numeric, sales numeric, tips numeric, base_income numeric, total_income numeric)
language sql stable as $$
  with prefs as (select week_start from public.users_profile where user_id = p_user),
       wr as (select * from week_range(p_day, (select week_start from prefs)))
  select wr.start_date, wr.end_date,
         coalesce(sum(s.hours),0),
         coalesce(sum(s.sales),0),
         coalesce(sum(s.tips),0),
         coalesce(sum(s.hours*s.hourly_rate),0),
         coalesce(sum(s.hours*s.hourly_rate + s.tips),0)
  from public.shifts s
  cross join wr
  where s.user_id = p_user and s.shift_date between wr.start_date and wr.end_date;
$$;
```

### Month totals
```sql
create or replace function public.totals_by_month(p_user uuid, p_day date)
returns table(start_date date, end_date date, hours numeric, sales numeric, tips numeric, base_income numeric, total_income numeric)
language sql stable as $$
  with bounds as (
    select date_trunc('month', p_day)::date as start_date,
           (date_trunc('month', p_day) + interval '1 month - 1 day')::date as end_date
  )
  select b.start_date, b.end_date,
         coalesce(sum(s.hours),0),
         coalesce(sum(s.sales),0),
         coalesce(sum(s.tips),0),
         coalesce(sum(s.hours*s.hourly_rate),0),
         coalesce(sum(s.hours*s.hourly_rate + s.tips),0)
  from public.shifts s
  cross join bounds b
  where s.user_id = p_user and s.shift_date between b.start_date and b.end_date;
$$;
```

---

## Design Guidelines

### iOS (Liquid Glass)
- SwiftUI only. Liquid Glass comes free with system `.regularMaterial`.  
- Use large rounded rectangles, glass blur cards.  
- Typography: San Francisco, Dynamic Type.  
- Icons: SF Symbols.  
- Motion: default SwiftUI transitions.  
- Dark mode supported by default.  

### Android
- Material 3 defaults.  
- Simple card layout.  
- No attempt to replicate Apple glass.  

### Web
- Next.js one‑pager.  
- Glass feel with CSS `backdrop-filter: blur()`.  
- Focus on clarity of text, simple CTA.

---

## SwiftUI Starter
```swift
struct HomeView: View {
  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        SummaryCard(title: "Today", amount: "$205")
        SummaryCard(title: "Week", amount: "$1,120")
      }
      .padding()
      .navigationTitle("Dashboard")
    }
  }
}

struct SummaryCard: View {
  let title: String
  let amount: String
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title).font(.title3)
      Text(amount).font(.largeTitle).fontWeight(.semibold)
    }
    .padding()
    .background(.regularMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
  }
}
```

---

## Developer Workflow

### Repository Structure
```
/ios       → SwiftUI iOS app
/android   → React Native or Kotlin Android app
/web       → Next.js one‑pager
/db        → SQL migrations for Supabase
```

### Development Flow
1. Use Cursor to develop features in each folder.  
2. Store migrations in `/db/migrations`.  
3. Commit and push to GitHub.  
4. CI/CD builds apps and deploys web.

---

## Roadmap (Post‑MVP)
- Income charts (daily/weekly/monthly).  
- Multi‑job support.  
- Tip pool / sharing.  
- Reminders to log shift.  
- Notifications when targets are met.  
- Offline entry + sync queue.  
- Multi‑currency support.

---

## Security & Privacy
- Supabase RLS ensures users only see their own data.  
- Secure Storage for tokens.  
- Face ID / passcode unlock.  
- Always allow user to export their data.  

---

## Testing
- SQL unit tests for functions.  
- SwiftUI snapshot tests.  
- E2E integration with Supabase local dev.  
- Manual tests across iPhone and iPad.

---

## Landing Page Draft (Web)
**Headline**: Track your shifts and tips in seconds.  
**Subhead**: Stop using paper and Excel. Enter once, see everything.  
**Features**: One‑tap entry, instant dashboards, targets, exports.  
**CTA**: Get early access.  

---
