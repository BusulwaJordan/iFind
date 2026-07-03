-- =============================================================================
-- Migration 21: Link portfolio_items back to their source product
-- =============================================================================
-- Lets a gallery post that was created from a product (see
-- ProductRepositoryImpl.createProduct) link back to that product, so the
-- gallery/detail view can show all of the product's photos, not just the
-- single cover photo stored as portfolio_items.media_url.
-- =============================================================================

ALTER TABLE public.portfolio_items
  ADD COLUMN IF NOT EXISTS product_id UUID REFERENCES public.products(id) ON DELETE SET NULL;

-- Backfill: link existing gallery posts (from migration 20's backfill, or
-- created before this migration) back to their source product by matching
-- the cover photo URL.
UPDATE public.portfolio_items pi
SET product_id = p.id
FROM public.products p
WHERE pi.product_id IS NULL
  AND pi.media_url = p.images[1]
  AND pi.business_id = p.business_id;
