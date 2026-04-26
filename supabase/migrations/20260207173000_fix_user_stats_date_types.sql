-- Change DATE columns to TIMESTAMPTZ to match Swift Date decoding expectations

ALTER TABLE public.user_stats 
ALTER COLUMN last_streak_date TYPE TIMESTAMPTZ USING last_streak_date::TIMESTAMPTZ,
ALTER COLUMN last_reset_date TYPE TIMESTAMPTZ USING last_reset_date::TIMESTAMPTZ,
ALTER COLUMN last_weekly_review_date TYPE TIMESTAMPTZ USING last_weekly_review_date::TIMESTAMPTZ;
