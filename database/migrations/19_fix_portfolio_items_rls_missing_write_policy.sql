-- =============================================================================
-- Migration 19: Add missing write policy for portfolio_items
-- =============================================================================
-- Problem: portfolio_items has RLS enabled with only a public SELECT policy.
-- No INSERT/UPDATE/DELETE policy exists, so with RLS enabled every write is
-- denied by default — every gallery upload failed with "new row violates
-- row-level security policy" regardless of any app-side fix.
-- =============================================================================

CREATE POLICY "Business owners can manage portfolio items"
    ON public.portfolio_items
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.businesses
            WHERE businesses.id = portfolio_items.business_id
              AND businesses.owner_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.businesses
            WHERE businesses.id = portfolio_items.business_id
              AND businesses.owner_id = auth.uid()
        )
    );
