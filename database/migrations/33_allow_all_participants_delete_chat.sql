-- =============================================================================
-- Migration 33: Let any real participant delete a chat (customer or business)
-- =============================================================================
-- Problem: the only general-access policy on chats ("Users can access own
-- chats", from the original schema) joins on businesses.id = chats.business_id
-- — but chats.business_id is the app's custom TEXT id (e.g. "BIZ0122"), not
-- the UUID primary key, so that join can never match. It also never
-- accounts for B2B chats (business_a_id/business_b_id) at all. In practice
-- this meant deleting a chat only reliably worked for the customer side of
-- a B2C chat, not a business owner (B2C or B2B).
--
-- Fix: an additive DELETE policy with the correct TEXT-based join, covering
-- both B2C sides and both B2B sides — so whoever is actually part of a
-- chat (customer or either business) can delete it, regardless of role.
-- =============================================================================

DROP POLICY IF EXISTS chats_delete_participant ON public.chats;
CREATE POLICY chats_delete_participant ON public.chats
    FOR DELETE
    USING (
        customer_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.businesses b
            WHERE b.owner_id = auth.uid()
              AND (
                    b.business_id = chats.business_id
                 OR b.business_id = chats.business_a_id
                 OR b.business_id = chats.business_b_id
              )
        )
    );

NOTIFY pgrst, 'reload schema';
