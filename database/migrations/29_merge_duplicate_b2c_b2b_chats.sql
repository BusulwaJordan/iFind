-- =============================================================================
-- Migration 29: Merge duplicate B2C/B2B chats between the same two businesses
-- =============================================================================
-- Problem: a business owner can end up with two separate conversations with
-- the same other business — a B2C chat (created via that business's page's
-- plain "Message" button, keyed by customer_id + business_id) and a B2B chat
-- (created via the B2B Matches screen, keyed by business_a_id + business_b_id).
-- Both represent "my business talking to that business", so they show up
-- twice in the chat list — one tagged B2B, one not — which reads as
-- redundant duplicates rather than two real conversations.
--
-- Fix: since both parties are businesses, the B2B chat is the canonical one.
-- Merge each duplicate B2C chat's messages into the matching B2B chat, then
-- drop the B2C chat. See 30_prevent_duplicate... (app-side) for the
-- create-time check that stops this from recurring.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Move messages from the duplicate B2C chat onto the canonical B2B chat
-- -----------------------------------------------------------------------------
WITH b2b_pairs AS (
    SELECT
        c.id AS b2b_chat_id,
        c.business_a_id,
        c.business_b_id,
        oa.owner_id AS owner_a,
        ob.owner_id AS owner_b
    FROM public.chats c
    JOIN public.businesses oa ON oa.business_id = c.business_a_id
    JOIN public.businesses ob ON ob.business_id = c.business_b_id
    WHERE c.is_b2b = true
),
dup_b2c AS (
    SELECT bp.b2b_chat_id, cc.id AS b2c_chat_id
    FROM b2b_pairs bp
    JOIN public.chats cc
      ON cc.is_b2b = false
     AND (
           (cc.customer_id = bp.owner_a AND cc.business_id = bp.business_b_id)
        OR (cc.customer_id = bp.owner_b AND cc.business_id = bp.business_a_id)
     )
)
UPDATE public.messages m
SET chat_id = d.b2b_chat_id
FROM dup_b2c d
WHERE m.chat_id = d.b2c_chat_id;

-- -----------------------------------------------------------------------------
-- 2. Drop the now-emptied duplicate B2C chats
-- -----------------------------------------------------------------------------
WITH b2b_pairs AS (
    SELECT
        c.id AS b2b_chat_id,
        c.business_a_id,
        c.business_b_id,
        oa.owner_id AS owner_a,
        ob.owner_id AS owner_b
    FROM public.chats c
    JOIN public.businesses oa ON oa.business_id = c.business_a_id
    JOIN public.businesses ob ON ob.business_id = c.business_b_id
    WHERE c.is_b2b = true
),
dup_b2c AS (
    SELECT cc.id AS b2c_chat_id
    FROM b2b_pairs bp
    JOIN public.chats cc
      ON cc.is_b2b = false
     AND (
           (cc.customer_id = bp.owner_a AND cc.business_id = bp.business_b_id)
        OR (cc.customer_id = bp.owner_b AND cc.business_id = bp.business_a_id)
     )
)
DELETE FROM public.chats c
USING dup_b2c d
WHERE c.id = d.b2c_chat_id;

-- -----------------------------------------------------------------------------
-- 3. Refresh last_message/last_message_at on the surviving B2B chats in case
--    the merged-in B2C chat had the more recent message
-- -----------------------------------------------------------------------------
UPDATE public.chats c
SET last_message = m.content,
    last_message_at = m.created_at
FROM (
    SELECT DISTINCT ON (chat_id) chat_id, content, created_at
    FROM public.messages
    ORDER BY chat_id, created_at DESC
) m
WHERE c.id = m.chat_id
  AND c.is_b2b = true
  AND m.created_at > c.last_message_at;

NOTIFY pgrst, 'reload schema';
