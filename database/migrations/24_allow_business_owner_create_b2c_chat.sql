-- =============================================================================
-- Migration 24: Let a business owner create a B2C chat with a customer
-- =============================================================================
-- Problem: chats_insert_b2c's WITH CHECK is (customer_id = auth.uid() AND
-- is_b2b = false) — only the customer themselves could ever create a B2C
-- chat row. That was fine while every B2C chat was customer-initiated (e.g.
-- tapping "Message" on a business), but the dashboard's "Message Customer"
-- button (on a posted Need, under Recent Inquiries) has the BUSINESS OWNER
-- creating the chat on the customer's behalf — auth.uid() there is the
-- owner, not the customer, so the insert was rejected with 42501
-- (insufficient_privilege).
--
-- Fix: add a second, additive INSERT policy for this exact case — a
-- business owner may create a B2C chat row for one of their own
-- businesses, for any customer_id. Postgres ORs multiple permissive
-- policies for the same command, so this doesn't touch the existing
-- customer-initiated path at all.
-- =============================================================================

CREATE POLICY chats_insert_b2c_by_owner ON public.chats
    FOR INSERT
    WITH CHECK (
        is_b2b = false
        AND business_id IN (
            SELECT business_id FROM public.businesses WHERE owner_id = auth.uid()
        )
    );
