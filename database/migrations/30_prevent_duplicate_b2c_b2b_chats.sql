-- =============================================================================
-- Migration 30: Prevent future B2C/B2B chat duplicates
-- =============================================================================
-- Companion to migration 29 (which merges existing duplicates). This adds a
-- SECURITY DEFINER function the app calls from getOrCreateB2BChat before
-- creating a new B2B chat: if a B2C chat already exists between these two
-- businesses' owners (in either direction), it's upgraded in place to a B2B
-- chat (keeping its id and message history) instead of a second, redundant
-- chat being created.
--
-- SECURITY DEFINER is needed because the update clears customer_id/business_id
-- while setting business_a_id/business_b_id — the existing "Users can access
-- own chats" RLS policy's WITH CHECK (implied from its USING clause on FOR ALL)
-- would otherwise reject a row that no longer matches on customer_id once it's
-- nulled out mid-update.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.upgrade_b2c_chat_to_b2b(
    p_business_a_id TEXT,
    p_business_b_id TEXT
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    owner_a UUID;
    owner_b UUID;
    existing_b2c_id UUID;
BEGIN
    SELECT owner_id INTO owner_a FROM public.businesses WHERE business_id = p_business_a_id;
    SELECT owner_id INTO owner_b FROM public.businesses WHERE business_id = p_business_b_id;

    SELECT id INTO existing_b2c_id
    FROM public.chats
    WHERE is_b2b = false
      AND (
            (customer_id = owner_a AND business_id = p_business_b_id)
         OR (customer_id = owner_b AND business_id = p_business_a_id)
      )
    LIMIT 1;

    IF existing_b2c_id IS NULL THEN
        RETURN NULL;
    END IF;

    UPDATE public.chats
    SET is_b2b = true,
        business_a_id = p_business_a_id,
        business_b_id = p_business_b_id,
        customer_id = NULL,
        business_id = NULL
    WHERE id = existing_b2c_id;

    RETURN existing_b2c_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.upgrade_b2c_chat_to_b2b(TEXT, TEXT) TO authenticated;

NOTIFY pgrst, 'reload schema';
