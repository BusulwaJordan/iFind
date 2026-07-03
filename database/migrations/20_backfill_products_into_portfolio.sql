-- =============================================================================
-- Migration 20: Backfill existing products into the gallery
-- =============================================================================
-- One-time backfill for products created before product-to-gallery sync
-- existed (migration is idempotent — re-running it skips products that
-- already have a matching gallery item).
-- =============================================================================

INSERT INTO public.portfolio_items (business_id, media_type, media_url, thumbnail_url, caption, price)
SELECT
    p.business_id,
    'image',
    p.images[1],
    NULL,
    p.name,
    p.price
FROM public.products p
WHERE array_length(p.images, 1) > 0
  AND NOT EXISTS (
    SELECT 1 FROM public.portfolio_items pi
    WHERE pi.business_id = p.business_id
      AND pi.media_url = p.images[1]
  );
