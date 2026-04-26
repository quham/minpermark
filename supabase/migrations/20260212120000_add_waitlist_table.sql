-- Waitlist table for landing page email signups
CREATE TABLE public.waitlist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for duplicate checks
CREATE INDEX idx_waitlist_email ON public.waitlist(email);

-- Enable RLS
ALTER TABLE public.waitlist ENABLE ROW LEVEL SECURITY;

-- Allow anonymous inserts (landing page has no auth)
CREATE POLICY "Anyone can join waitlist" ON public.waitlist
    FOR INSERT WITH CHECK (true);

-- Only service role can read (admin dashboard later)
CREATE POLICY "Service role can read waitlist" ON public.waitlist
    FOR SELECT USING (auth.role() = 'service_role');
