-- =============================================================================
-- Migration 23: Merge duplicate chats and prevent new ones from being created
-- =============================================================================
-- Problem: getOrCreateChat/getOrCreateB2BChat (chat_remote_datasource.dart)
-- check for an existing chat and only insert if none is found. That
-- check-then-insert is not atomic, so two near-simultaneous calls (e.g. a
-- fast double-tap on "Message", or two entry points into the same chat
-- firing at once) can both pass the check before either insert completes,
-- creating two separate chat rows for the same (customer, business) or
-- (business, business) pair. Once that happens, which one a given "Message"
-- button opens is arbitrary, so conversations appear to split/reset.
--
-- Fix:
-- 1. Merge duplicate chats: move every message from the newer duplicate(s)
--    onto the oldest chat for that pair, then delete the now-empty
--    duplicates.
-- 2. Add unique indexes so the database itself rejects a duplicate insert
--    going forward — chat_remote_datasource.dart now catches that as a
--    23505 (unique_violation) and re-fetches the existing chat instead of
--    erroring out, so a race no longer produces a second chat at all.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1a. Merge duplicate B2C chats (same customer_id + business_id)
-- -----------------------------------------------------------------------------
WITH canonical_b2c_chat AS (
    SELECT DISTINCT ON (customer_id, business_id)
        id AS canonical_id, customer_id, business_id
    FROM public.chats
    WHERE is_b2b = false
    ORDER BY customer_id, business_id, created_at ASC
)
UPDATE public.messages m
SET chat_id = cc.canonical_id
FROM public.chats c
JOIN canonical_b2c_chat cc
    ON cc.customer_id = c.customer_id AND cc.business_id = c.business_id
WHERE m.chat_id = c.id
  AND c.is_b2b = false
  AND c.id <> cc.canonical_id;

WITH canonical_b2c_chat AS (
    SELECT DISTINCT ON (customer_id, business_id)
        id AS canonical_id, customer_id, business_id
    FROM public.chats
    WHERE is_b2b = false
    ORDER BY customer_id, business_id, created_at ASC
)
DELETE FROM public.chats c
USING canonical_b2c_chat cc
WHERE c.customer_id = cc.customer_id
  AND c.business_id = cc.business_id
  AND c.is_b2b = false
  AND c.id <> cc.canonical_id;

-- -----------------------------------------------------------------------------
-- 1b. Merge duplicate B2B chats (same business pair, either direction)
-- -----------------------------------------------------------------------------
WITH b2b_pairs AS (
    SELECT id, created_at,
           LEAST(business_a_id, business_b_id) AS biz_lo,
           GREATEST(business_a_id, business_b_id) AS biz_hi
    FROM public.chats
    WHERE is_b2b = true
),
canonical_b2b_chat AS (
    SELECT DISTINCT ON (biz_lo, biz_hi) id AS canonical_id, biz_lo, biz_hi
    FROM b2b_pairs
    ORDER BY biz_lo, biz_hi, created_at ASC
)
UPDATE public.messages m
SET chat_id = cc.canonical_id
FROM b2b_pairs bp
JOIN canonical_b2b_chat cc ON cc.biz_lo = bp.biz_lo AND cc.biz_hi = bp.biz_hi
WHERE m.chat_id = bp.id
  AND bp.id <> cc.canonical_id;

WITH b2b_pairs AS (
    SELECT id, created_at,
           LEAST(business_a_id, business_b_id) AS biz_lo,
           GREATEST(business_a_id, business_b_id) AS biz_hi
    FROM public.chats
    WHERE is_b2b = true
),
canonical_b2b_chat AS (
    SELECT DISTINCT ON (biz_lo, biz_hi) id AS canonical_id, biz_lo, biz_hi
    FROM b2b_pairs
    ORDER BY biz_lo, biz_hi, created_at ASC
)
DELETE FROM public.chats c
USING b2b_pairs bp
JOIN canonical_b2b_chat cc ON cc.biz_lo = bp.biz_lo AND cc.biz_hi = bp.biz_hi
WHERE c.id = bp.id
  AND bp.id <> cc.canonical_id;

-- -----------------------------------------------------------------------------
-- 2. Prevent future duplicates at the database level
-- -----------------------------------------------------------------------------
DROP INDEX IF EXISTS public.chats_b2c_unique_pair;
CREATE UNIQUE INDEX chats_b2c_unique_pair
    ON public.chats (customer_id, business_id)
    WHERE is_b2b = false;

DROP INDEX IF EXISTS public.chats_b2b_unique_pair;
CREATE UNIQUE INDEX chats_b2b_unique_pair
    ON public.chats (LEAST(business_a_id, business_b_id), GREATEST(business_a_id, business_b_id))
    WHERE is_b2b = true;
