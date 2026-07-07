-- =============================================================================
-- Migration 28: Block user + Report user (chat "more options" menu)
-- =============================================================================
-- Adds the two safety actions for the chat room's "more options" menu:
-- Block (stop someone from messaging you again) and Report (flag a
-- conversation for review). "Delete conversation" reuses the existing
-- ChatRemoteDataSource.deleteChat(), no schema change needed for that one.
--
-- Scope: block enforcement is applied to B2C chats (customer <-> business
-- owner) only, which covers the marketplace's actual abuse surface —
-- strangers contacting each other. B2B chats (business <-> business) are
-- not blocked at the message level since both sides already went through
-- the B2B match/recommendation flow.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. blocked_users
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.blocked_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blocker_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CHECK (blocker_id <> blocked_id),
    UNIQUE (blocker_id, blocked_id)
);

CREATE INDEX IF NOT EXISTS idx_blocked_users_blocker ON public.blocked_users(blocker_id);
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocked ON public.blocked_users(blocked_id);

ALTER TABLE public.blocked_users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS blocked_users_select_own ON public.blocked_users;
CREATE POLICY blocked_users_select_own ON public.blocked_users
    FOR SELECT USING (blocker_id = auth.uid());

DROP POLICY IF EXISTS blocked_users_insert_own ON public.blocked_users;
CREATE POLICY blocked_users_insert_own ON public.blocked_users
    FOR INSERT WITH CHECK (blocker_id = auth.uid());

DROP POLICY IF EXISTS blocked_users_delete_own ON public.blocked_users;
CREATE POLICY blocked_users_delete_own ON public.blocked_users
    FOR DELETE USING (blocker_id = auth.uid());

-- -----------------------------------------------------------------------------
-- 2. reports
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    reported_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    chat_id UUID REFERENCES public.chats(id) ON DELETE SET NULL,
    reason TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reports_reported_user ON public.reports(reported_user_id);

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS reports_insert_own ON public.reports;
CREATE POLICY reports_insert_own ON public.reports
    FOR INSERT WITH CHECK (reporter_id = auth.uid());

DROP POLICY IF EXISTS reports_select_own ON public.reports;
CREATE POLICY reports_select_own ON public.reports
    FOR SELECT USING (reporter_id = auth.uid());

-- -----------------------------------------------------------------------------
-- 3. Enforce blocking at message-send time
-- -----------------------------------------------------------------------------
-- Resolves "the other participant" of a B2C chat relative to a given user,
-- mirroring on_chat_message_sent()'s customer/owner resolution logic
-- (migration 17). Returns NULL for B2B chats or if the chat/business can't
-- be resolved, in which case the block check below is a no-op.
CREATE OR REPLACE FUNCTION public.get_chat_other_party(p_chat_id UUID, p_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    chat_rec RECORD;
BEGIN
    SELECT c.customer_id, c.is_b2b, b.owner_id AS business_owner_id
    INTO chat_rec
    FROM public.chats c
    LEFT JOIN public.businesses b ON b.business_id = c.business_id
    WHERE c.id = p_chat_id;

    IF chat_rec IS NULL OR chat_rec.is_b2b THEN
        RETURN NULL;
    END IF;

    IF p_user_id = chat_rec.customer_id THEN
        RETURN chat_rec.business_owner_id;
    ELSIF chat_rec.business_owner_id IS NOT NULL AND p_user_id = chat_rec.business_owner_id THEN
        RETURN chat_rec.customer_id;
    ELSE
        RETURN NULL;
    END IF;
END;
$$;

-- RESTRICTIVE so it ANDs with the existing permissive messages-insert
-- policy instead of OR'ing (which would just widen access) — this is the
-- one place in this schema blocking needs to actually subtract permission
-- rather than add it.
DROP POLICY IF EXISTS messages_not_blocked ON public.messages;
CREATE POLICY messages_not_blocked ON public.messages
    AS RESTRICTIVE
    FOR INSERT
    WITH CHECK (
        NOT EXISTS (
            SELECT 1 FROM public.blocked_users bu
            WHERE bu.blocked_id = sender_id
              AND bu.blocker_id = public.get_chat_other_party(chat_id, sender_id)
        )
    );

NOTIFY pgrst, 'reload schema';
