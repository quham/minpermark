-- Questions bank (populated by separate ingestion pipeline; app reads only)
create table if not exists public.questions (
    id text primary key,
    board text not null check (board in ('edexcel','aqa','ocr')),
    level text not null check (level in ('gcse','asLevel','aLevel')),
    tier text check (tier in ('foundation','higher')),
    paper_year int not null,
    paper_code text not null,
    question_number text not null,
    question_image_url text not null,
    mark_scheme_image_url text not null,
    total_marks int not null,
    subtopic_tags text[] not null default '{}',
    skill_tags text[] not null default '{}',
    difficulty int not null check (difficulty between 1 and 5),
    created_at timestamptz not null default now()
);

create index if not exists questions_filter_idx
    on public.questions (level, board, tier);

-- Attempts (per-user, mirrored from device)
create table if not exists public.attempts (
    id uuid primary key,
    user_id uuid references auth.users(id) on delete cascade,
    question_id text not null references public.questions(id),
    submitted_at timestamptz not null,
    marks_awarded int not null,
    total_marks int not null,
    criterion_results jsonb not null,
    skills_correct text[] not null default '{}',
    skills_incorrect text[] not null default '{}',
    improvement_tip text not null default '',
    seconds_spent int not null default 0,
    marking_mode text not null check (marking_mode in ('ai','selfMark')),
    created_at timestamptz not null default now()
);

create index if not exists attempts_user_idx on public.attempts (user_id, submitted_at desc);

-- Skill stats (per-user mirror of device weakness model)
create table if not exists public.skill_stats (
    user_id uuid not null references auth.users(id) on delete cascade,
    tag text not null,
    kind text not null check (kind in ('subtopic','skill')),
    attempts_count int not null default 0,
    marks_scored int not null default 0,
    marks_possible int not null default 0,
    recency_weighted_pct double precision not null default 0,
    last_attempted_at timestamptz,
    primary key (user_id, kind, tag)
);

-- RLS
alter table public.questions enable row level security;
alter table public.attempts enable row level security;
alter table public.skill_stats enable row level security;

create policy "questions readable by all authenticated"
    on public.questions for select to authenticated using (true);

create policy "attempts owner-only"
    on public.attempts for all to authenticated
    using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "skill_stats owner-only"
    on public.skill_stats for all to authenticated
    using (auth.uid() = user_id) with check (auth.uid() = user_id);
