-- =============================================================================
-- Migration 26: Create the missing favorites table
-- =============================================================================
-- Problem: the "Add to Favorites" feature (favourites_provider.dart) has
-- always been fully built client-side — the provider, the heart-icon UI, the
-- Saved Businesses screen — but the underlying `favorites` table was never
-- actually created in the database. Every toggle() call fails with a
-- Postgrest 404 "Could not find the table 'public.favorites'" error, which
-- gets silently swallowed by the provider's `catch (_) {}` (it just reverts
-- the optimistic UI update), making it look like tapping the button quietly
-- does nothing.
--
-- business_id is TEXT (the app's custom id, e.g. "BIZ0122") to match the
-- value the UI actually passes in (Business.id) and the convention used by
-- every other business_id column in this schema (chats, interactions, etc).
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    business_id TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, business_id)
);

CREATE INDEX IF NOT EXISTS favorites_user_id_idx ON public.favorites (user_id);
CREATE INDEX IF NOT EXISTS favorites_business_id_idx ON public.favorites (business_id);

ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY favorites_select_own ON public.favorites
    FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY favorites_insert_own ON public.favorites
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY favorites_delete_own ON public.favorites
    FOR DELETE
    USING (user_id = auth.uid());
