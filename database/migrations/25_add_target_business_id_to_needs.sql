-- =============================================================================
-- Migration 25: Add target_business_id to needs (direct-to-business posts)
-- =============================================================================
-- Problem: "Post a Need" on a business's profile page now sends the need
-- directly to that one business, instead of broadcasting it to nearby
-- category matches. But nothing on the needs row itself recorded which
-- business it was aimed at — only the notification did — so the Leads
-- Dashboard's "Recent Inquiries" (businessLeadsProvider), which re-derives
-- relevance purely from distance + AI-inferred category, could easily miss
-- a targeted need entirely (sender wasn't nearby, or the free-text category
-- guess didn't match the business's actual category).
--
-- Fix: add a nullable target_business_id column (the app's custom TEXT
-- business id, matching every other business_id column in this schema) so
-- a targeted need can be looked up directly regardless of distance/category.
-- No FK constraint, matching how other business_id TEXT columns in this
-- schema (e.g. chats.business_id) are already handled.
-- =============================================================================

ALTER TABLE public.needs
    ADD COLUMN IF NOT EXISTS target_business_id TEXT;

CREATE INDEX IF NOT EXISTS needs_target_business_id_idx
    ON public.needs (target_business_id)
    WHERE target_business_id IS NOT NULL;
