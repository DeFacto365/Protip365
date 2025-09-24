{\rtf1\ansi\ansicpg1252\cocoartf2865
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 Database schema:\
\
create table public.achievements (\
  id uuid not null default gen_random_uuid (),\
  user_id uuid not null,\
  achievement_type text not null,\
  unlocked_at timestamp with time zone null default CURRENT_TIMESTAMP,\
  data jsonb null,\
  created_at timestamp with time zone null default CURRENT_TIMESTAMP,\
  constraint achievements_pkey primary key (id),\
  constraint unique_user_achievement unique (user_id, achievement_type),\
  constraint achievements_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete CASCADE\
) TABLESPACE pg_default;\
\
create index IF not exists idx_achievements_user_id on public.achievements using btree (user_id) TABLESPACE pg_default;\
\
create index IF not exists idx_achievements_type on public.achievements using btree (achievement_type) TABLESPACE pg_default;\
\
create table public.alerts (\
  id uuid not null default gen_random_uuid (),\
  user_id uuid not null,\
  alert_type text not null,\
  title text not null,\
  message text not null,\
  is_read boolean null default false,\
  action text null,\
  data jsonb null,\
  created_at timestamp with time zone null default CURRENT_TIMESTAMP,\
  read_at timestamp with time zone null,\
  constraint alerts_pkey primary key (id),\
  constraint alerts_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete CASCADE\
) TABLESPACE pg_default;\
\
create index IF not exists idx_alerts_user_id on public.alerts using btree (user_id) TABLESPACE pg_default;\
\
create index IF not exists idx_alerts_is_read on public.alerts using btree (is_read) TABLESPACE pg_default;\
\
create index IF not exists idx_alerts_created_at on public.alerts using btree (created_at desc) TABLESPACE pg_default;\
\
create table public.employers (\
  id uuid not null default gen_random_uuid (),\
  user_id uuid null,\
  name character varying(255) not null,\
  hourly_rate numeric(10, 2) not null default 15.00,\
  created_at timestamp with time zone null default now(),\
  active boolean null default true,\
  constraint employers_pkey primary key (id),\
  constraint employers_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete CASCADE\
) TABLESPACE pg_default;\
\
create table public.entries (\
  id uuid not null default gen_random_uuid (),\
  user_id uuid not null,\
  employer_id uuid null,\
  entry_date date not null,\
  sales numeric(10, 2) null default 0,\
  tips numeric(10, 2) null default 0,\
  hourly_rate numeric(10, 2) null default 0,\
  cash_out numeric(10, 2) null default 0,\
  other numeric(10, 2) null default 0,\
  notes text null,\
  created_at timestamp with time zone null default CURRENT_TIMESTAMP,\
  updated_at timestamp with time zone null default CURRENT_TIMESTAMP,\
  constraint entries_pkey primary key (id),\
  constraint entries_employer_id_fkey foreign KEY (employer_id) references employers (id) on delete set null,\
  constraint entries_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete CASCADE\
) TABLESPACE pg_default;\
\
create index IF not exists idx_entries_user_id on public.entries using btree (user_id) TABLESPACE pg_default;\
\
create index IF not exists idx_entries_entry_date on public.entries using btree (entry_date desc) TABLESPACE pg_default;\
\
create index IF not exists idx_entries_employer_id on public.entries using btree (employer_id) TABLESPACE pg_default;\
\
create table public.password_reset_tokens (\
  id uuid not null default extensions.uuid_generate_v4 (),\
  user_id uuid not null,\
  token text not null,\
  expires_at timestamp with time zone not null,\
  used boolean null default false,\
  created_at timestamp with time zone null default now(),\
  constraint password_reset_tokens_pkey primary key (id),\
  constraint password_reset_tokens_token_key unique (token),\
  constraint password_reset_tokens_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete CASCADE\
) TABLESPACE pg_default;\
\
create table public.shift_income (\
  id uuid not null default extensions.uuid_generate_v4 (),\
  shift_id uuid not null,\
  user_id uuid not null,\
  actual_hours numeric(5, 2) not null,\
  sales numeric(10, 2) not null default 0,\
  tips numeric(10, 2) not null default 0,\
  cash_out numeric(10, 2) not null default 0,\
  other numeric(10, 2) not null default 0,\
  actual_start_time time without time zone null,\
  actual_end_time time without time zone null,\
  notes text null,\
  created_at timestamp with time zone null default now(),\
  updated_at timestamp with time zone null default now(),\
  entry_notes text null,\
  constraint shift_income_pkey primary key (id),\
  constraint shift_income_shift_id_fkey foreign KEY (shift_id) references shifts (id) on delete CASCADE,\
  constraint shift_income_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete CASCADE\
) TABLESPACE pg_default;\
\
create table public.shifts (\
  id uuid not null default gen_random_uuid (),\
  user_id uuid null,\
  shift_date date not null,\
  hours numeric(4, 2) not null,\
  hourly_rate numeric(10, 2) null,\
  sales numeric(10, 2) null default 0,\
  tips numeric(10, 2) null default 0,\
  notes text null,\
  created_at timestamp with time zone null default now(),\
  employer_id uuid null,\
  cash_out numeric(10, 2) null default 0,\
  cash_out_note text null,\
  start_time time without time zone null,\
  end_time time without time zone null,\
  other double precision null default 0,\
  expected_hours numeric(5, 2) null,\
  lunch_break_hours numeric(3, 2) not null default 0.0,\
  status text null default 'completed'::text,\
  lunch_break_minutes integer null default 0,\
  constraint shifts_pkey primary key (id),\
  constraint shifts_employer_id_fkey foreign KEY (employer_id) references employers (id) on delete CASCADE,\
  constraint shifts_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete CASCADE\
) TABLESPACE pg_default;\
\
create index IF not exists idx_shifts_notes on public.shifts using gin (to_tsvector('english'::regconfig, notes)) TABLESPACE pg_default\
where\
  (notes is not null);\
\
create trigger auto_hourly_rate BEFORE INSERT on shifts for EACH row\
execute FUNCTION set_default_hourly_rate ();\
\
create table public.user_subscriptions (\
  id uuid not null default gen_random_uuid (),\
  user_id uuid null,\
  product_id text null,\
  status text null,\
  expires_at timestamp with time zone null,\
  transaction_id text null,\
  purchase_date timestamp with time zone null,\
  environment text null,\
  created_at timestamp with time zone null default now(),\
  updated_at timestamp with time zone null default now(),\
  constraint user_subscriptions_pkey primary key (id),\
  constraint user_subscriptions_user_id_key unique (user_id),\
  constraint user_subscriptions_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete CASCADE,\
  constraint user_subscriptions_environment_check check (\
    (\
      environment = any (array['sandbox'::text, 'production'::text])\
    )\
  ),\
  constraint user_subscriptions_status_check check (\
    (\
      status = any (\
        array[\
          'active'::text,\
          'expired'::text,\
          'cancelled'::text\
        ]\
      )\
    )\
  )\
) TABLESPACE pg_default;\
\
create index IF not exists idx_user_subscriptions_user_id on public.user_subscriptions using btree (user_id) TABLESPACE pg_default;\
\
create index IF not exists idx_user_subscriptions_status on public.user_subscriptions using btree (status) TABLESPACE pg_default;\
\
create index IF not exists idx_user_subscriptions_expires_at on public.user_subscriptions using btree (expires_at) TABLESPACE pg_default;\
\
create table public.users_profile (\
  user_id uuid not null,\
  default_hourly_rate numeric(10, 2) null default 15.00,\
  week_start integer null default 0,\
  target_tip_daily numeric(10, 2) null default 100,\
  target_tip_weekly numeric(10, 2) null default 500,\
  target_tip_monthly numeric(10, 2) null default 2000,\
  created_at timestamp with time zone null default now(),\
  language character varying(5) null default 'en'::character varying,\
  name character varying(255) null,\
  target_sales_daily numeric(10, 2) null default 0,\
  target_sales_weekly numeric(10, 2) null default 0,\
  target_sales_monthly numeric(10, 2) null default 0,\
  target_hours_daily numeric(6, 1) null default 0,\
  target_hours_weekly numeric(6, 1) null default 0,\
  target_hours_monthly numeric(6, 1) null default 0,\
  use_multiple_employers boolean null default false,\
  default_employer_id uuid null,\
  tip_target_percentage numeric(10, 2) null default 0,\
  has_variable_schedule boolean null default false,\
  average_deduction_percentage numeric(5, 2) null default 30.00,\
  preferred_language text null default 'en'::text,\
  constraint users_profile_pkey primary key (user_id),\
  constraint fk_users_profile_default_employer foreign KEY (default_employer_id) references employers (id),\
  constraint users_profile_default_employer_id_fkey foreign KEY (default_employer_id) references employers (id),\
  constraint users_profile_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete CASCADE,\
  constraint check_preferred_language check (\
    (\
      preferred_language = any (array['en'::text, 'fr'::text, 'es'::text])\
    )\
  ),\
  constraint users_profile_week_start_check check (\
    (\
      (week_start >= 0)\
      and (week_start <= 6)\
    )\
  ),\
  constraint check_average_deduction_percentage check (\
    (\
      (average_deduction_percentage >= (0)::numeric)\
      and (average_deduction_percentage <= (100)::numeric)\
    )\
  )\
) TABLESPACE pg_default;\
\
View v_shift_income\
}