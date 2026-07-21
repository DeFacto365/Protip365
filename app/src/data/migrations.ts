export const WEEKLY_GOALS_IDENTITY_MIGRATION = `
  DELETE FROM weekly_goals
  WHERE id NOT IN (
    SELECT winner.id
    FROM weekly_goals AS winner
    WHERE winner.id = (
      SELECT candidate.id
      FROM weekly_goals AS candidate
      WHERE candidate.week_start = winner.week_start
        AND candidate.metric = winner.metric
        AND candidate.employer_id IS winner.employer_id
      ORDER BY candidate.updated_at DESC, candidate.id DESC
      LIMIT 1
    )
  );
  CREATE UNIQUE INDEX IF NOT EXISTS idx_goals_identity
    ON weekly_goals(week_start, metric, COALESCE(employer_id, ''));
`;
