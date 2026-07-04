-- =============================================================================
-- Migration 18: Fix products RLS to check business ownership, not shop_id
-- =============================================================================
-- Problem: the "Shop managers can manage products" policy checks
-- products.shop_id against a shops table (shops.manager_id = auth.uid()).
-- The app has never used shop_id — it writes to products.business_id, which
-- references businesses(id). Since shop_id is never populated, this policy
-- always evaluates to false, rejecting every product insert/update/delete
-- with "new row violates row-level security policy" (42501).
-- =============================================================================

DROP POLICY IF EXISTS "Shop managers can manage products" ON public.products;

CREATE POLICY "Business owners can manage products"
    ON public.products
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.businesses
            WHERE businesses.id = products.business_id
              AND businesses.owner_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.businesses
            WHERE businesses.id = products.business_id
              AND businesses.owner_id = auth.uid()
        )
    );
