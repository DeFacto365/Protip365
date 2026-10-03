export const INITIAL_SCHEMA = `
  CREATE TABLE IF NOT EXISTS employers (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    color TEXT NOT NULL,
    default_hourly_rate INTEGER NOT NULL CHECK (default_hourly_rate > 0),
    deduction_rate_bp INTEGER NOT NULL DEFAULT 0 CHECK (deduction_rate_bp BETWEEN 0 AND 10000),
    archived INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS roles (
    id TEXT PRIMARY KEY NOT NULL,
    employer_id TEXT NOT NULL REFERENCES employers(id),
    name TEXT NOT NULL,
    hourly_rate INTEGER NOT NULL CHECK (hourly_rate > 0),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    UNIQUE (id, employer_id)
  );
  CREATE TABLE IF NOT EXISTS shifts (
    id TEXT PRIMARY KEY NOT NULL,
    employer_id TEXT NOT NULL REFERENCES employers(id),
    role_id TEXT,
    date TEXT NOT NULL,
    start_min INTEGER NOT NULL,
    end_min INTEGER NOT NULL,
    breaks_json TEXT NOT NULL DEFAULT '[]',
    hourly_rate_snapshot INTEGER NOT NULL CHECK (hourly_rate_snapshot > 0),
    planned_expected_tips INTEGER,
    planned_other_income INTEGER,
    status TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'worked', 'missed', 'cancelled')),
    transition_at TEXT NOT NULL,
    not_worked_reason TEXT,
    not_worked_note TEXT,
    actual_start_min INTEGER,
    actual_end_min INTEGER,
    actual_breaks_json TEXT,
    actual_hourly_rate_snapshot INTEGER CHECK (actual_hourly_rate_snapshot IS NULL OR actual_hourly_rate_snapshot > 0),
    tip_method TEXT,
    direct_tips INTEGER,
    pool_contribution INTEGER,
    tip_share_received INTEGER,
    tip_out_paid INTEGER,
    sales INTEGER,
    other_income INTEGER,
    deduction_rate_snapshot_bp INTEGER CHECK (deduction_rate_snapshot_bp IS NULL OR deduction_rate_snapshot_bp BETWEEN 0 AND 10000),
    notes TEXT,
    source_template_id TEXT,
    source_recurrence_rule_id TEXT,
    recurrence_key TEXT UNIQUE,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (role_id, employer_id) REFERENCES roles(id, employer_id)
  );
  CREATE INDEX IF NOT EXISTS idx_shifts_date ON shifts(date);
  CREATE INDEX IF NOT EXISTS idx_shifts_employer ON shifts(employer_id);
  CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY NOT NULL,
    value TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS schedule_templates (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    employer_id TEXT NOT NULL REFERENCES employers(id),
    role_id TEXT,
    start_min INTEGER NOT NULL,
    end_min INTEGER NOT NULL,
    breaks_json TEXT NOT NULL DEFAULT '[]',
    planned_expected_tips INTEGER,
    planned_other_income INTEGER,
    notes TEXT,
    archived INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (role_id, employer_id) REFERENCES roles(id, employer_id)
  );
  CREATE TABLE IF NOT EXISTS recurrence_rules (
    id TEXT PRIMARY KEY NOT NULL,
    template_id TEXT NOT NULL REFERENCES schedule_templates(id),
    cadence_weeks INTEGER NOT NULL,
    weekdays_json TEXT NOT NULL,
    start_date TEXT NOT NULL,
    end_date TEXT,
    occurrence_count INTEGER,
    active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );
  CREATE INDEX IF NOT EXISTS idx_templates_employer ON schedule_templates(employer_id);
  CREATE INDEX IF NOT EXISTS idx_recurrence_template ON recurrence_rules(template_id);
  CREATE TABLE IF NOT EXISTS weekly_goals (
    id TEXT PRIMARY KEY NOT NULL,
    week_start TEXT NOT NULL,
    metric TEXT NOT NULL,
    target INTEGER NOT NULL CHECK (target > 0),
    employer_id TEXT REFERENCES employers(id),
    repeat INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );
  CREATE INDEX IF NOT EXISTS idx_goals_week ON weekly_goals(week_start);
  `;
