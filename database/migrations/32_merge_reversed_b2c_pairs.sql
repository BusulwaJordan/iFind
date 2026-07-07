-- =============================================================================
-- Migration 32: Merge reversed-direction B2C/B2C chat pairs into one B2B chat
-- =============================================================================
-- Problem: two business owners can end up with two separate B2C chats
-- between them — owner A messaging business B as an individual customer,
-- and separately owner B messaging business A as an individual customer.
-- Both display the OTHER party's business name in the chat list (display
-- logic prefers a customer's own business over their personal name), so
-- the same business appears to show up twice, even though the two rows are
-- technically different (customer_id, business_id) pairs in opposite
-- directions.
--
-- Fix: same principle as migration 29 (canonicalize on B2B once both
-- parties are known to be businesses) — merge the newer chat of the pair
-- into the older, converting the survivor into a proper B2B chat.
-- =============================================================================

CREATE TEMP TABLE _reversed_b2c_merges AS
WITH b2c_chats AS (
    SELECT c.id, c.customer_id, c.business_id, c.created_at
    FROM public.chats c
    WHERE c.is_b2b = false
      AND c.customer_id IS NOT NULL
      AND c.business_id IS NOT NULL
),
b2c_with_owned_business AS (
    SELECT bc.id, bc.customer_id, bc.business_id, bc.created_at,
           cb.business_id AS customer_owned_business_id
    FROM b2c_chats bc
    JOIN public.businesses cb ON cb.owner_id = bc.customer_id
),
reversed_pairs AS (
    SELECT
        c1.id AS chat1_id, c1.created_at AS created1, c1.business_id AS biz1,
        c2.id AS chat2_id, c2.created_at AS created2, c2.business_id AS biz2
    FROM b2c_with_owned_business c1
    JOIN b2c_with_owned_business c2
      ON c2.business_id = c1.customer_owned_business_id
     AND c1.business_id = c2.customer_owned_business_id
     AND c1.id < c2.id
)
SELECT
    CASE WHEN created1 <= created2 THEN chat1_id ELSE chat2_id END AS canonical_id,
    CASE WHEN created1 <= created2 THEN chat2_id ELSE chat1_id END AS dup_id,
    CASE WHEN created1 <= created2 THEN biz1 ELSE biz2 END AS canonical_biz_a,
    CASE WHEN created1 <= created2 THEN biz2 ELSE biz1 END AS canonical_biz_b
FROM reversed_pairs;

-- 1. Move messages from the duplicate onto the canonical chat
UPDATE public.messages m
SET chat_id = r.canonical_id
FROM _reversed_b2c_merges r
WHERE m.chat_id = r.dup_id;

-- 2. Convert the canonical chat to B2B
UPDATE public.chats c
SET is_b2b = true,
    business_a_id = r.canonical_biz_a,
    business_b_id = r.canonical_biz_b,
    customer_id = NULL,
    business_id = NULL
FROM _reversed_b2c_merges r
WHERE c.id = r.canonical_id;

-- 3. Drop the now-emptied duplicate chats
DELETE FROM public.chats c
USING _reversed_b2c_merges r
WHERE c.id = r.dup_id;

-- 4. Refresh last_message/last_message_at on the surviving chats in case the
--    merged-in duplicate had the more recent message
UPDATE public.chats c
SET last_message = m.content,
    last_message_at = m.created_at
FROM (
    SELECT DISTINCT ON (chat_id) chat_id, content, created_at
    FROM public.messages
    ORDER BY chat_id, created_at DESC
) m
WHERE c.id = m.chat_id
  AND c.id IN (SELECT canonical_id FROM _reversed_b2c_merges)
  AND (c.last_message_at IS NULL OR m.created_at > c.last_message_at);

DROP TABLE _reversed_b2c_merges;

-- -----------------------------------------------------------------------------
-- 5. Prevent future reversed-direction duplicates
-- -----------------------------------------------------------------------------
-- Called from getOrCreateChat when the customer initiating a new B2C chat
-- owns a business themselves: checks whether the OTHER business's owner
-- already has a separate B2C chat with THIS customer's own business (the
-- reverse direction) and, if so, upgrades it to B2B in place instead of a
-- third chat being created.
CREATE OR REPLACE FUNCTION public.find_reverse_b2c_chat(
    p_my_business_id TEXT,
    p_other_business_id TEXT
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    other_owner_id UUID;
    reverse_chat_id UUID;
BEGIN
    SELECT owner_id INTO other_owner_id
    FROM public.businesses
    WHERE business_id = p_other_business_id;

    IF other_owner_id IS NULL THEN
        RETURN NULL;
    END IF;

    SELECT id INTO reverse_chat_id
    FROM public.chats
    WHERE is_b2b = false
      AND business_id = p_my_business_id
      AND customer_id = other_owner_id
    LIMIT 1;

    IF reverse_chat_id IS NULL THEN
        RETURN NULL;
    END IF;

    UPDATE public.chats
    SET is_b2b = true,
        business_a_id = p_my_business_id,
        business_b_id = p_other_business_id,
        customer_id = NULL,
        business_id = NULL
    WHERE id = reverse_chat_id;

    RETURN reverse_chat_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.find_reverse_b2c_chat(TEXT, TEXT) TO authenticated;

NOTIFY pgrst, 'reload schema';
