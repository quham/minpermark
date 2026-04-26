-- Fix goals table local_id uniqueness
-- Current: local_id is UNIQUE globally
-- Fix: local_id should be UNIQUE per user_id to prevent RLS conflicts during sync

ALTER TABLE public.goals DROP CONSTRAINT IF EXISTS goals_local_id_key;
ALTER TABLE public.goals ADD CONSTRAINT goals_local_id_user_id_key UNIQUE (local_id, user_id);
