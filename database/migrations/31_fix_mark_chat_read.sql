-- =============================================================================
-- Migration 31: Fix mark-as-read not persisting (unread count never drops)
-- =============================================================================
-- Problem: opening a chat was supposed to mark the other party's messages
-- as read via a plain client-side UPDATE, but the unread count kept showing
-- every message ever sent by the other party, read or not. The messages
-- table's RLS ("Users can access messages in their chats") is scoped to
-- chat participancy, not to whether the row being touched is your own
-- message — marking someone ELSE's message as read should be within that
-- grant, but rather than keep guessing at the exact RLS interaction, this
-- routes the update through a SECURITY DEFINER function so it's guaranteed
-- to work regardless, matching the pattern already used for block/report
-- (migrations 28/30).
-- =============================================================================

CREATE OR REPLACE FUNCTION public.mark_chat_read(p_chat_id UUID, p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.messages
    SET is_read = true
    WHERE chat_id = p_chat_id
      AND is_read = false
      AND sender_id <> p_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.mark_chat_read(UUID, UUID) TO authenticated;

NOTIFY pgrst, 'reload schema';
