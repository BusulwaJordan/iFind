-- =============================================================================
-- Migration 22: Add category_connections rows for the new Footwear category
-- =============================================================================
-- Context: the B2B hybrid recommender's rule-based scorer (ifind_backend/
-- main.py) looks up partner categories in category_connections. The seeded
-- demo dataset never included a footwear category, so a new "Footwear"
-- business category (added alongside Agriculture/Wholesale/Manufacturing/
-- Construction to stop generic buckets like "retail" from swallowing
-- unrelated business types) has zero rule-based partners without this.
--
-- Rows use the app's canonical single-word category vocabulary directly
-- (see BusinessCategoryStorage in
-- lib/features/business/domain/entities/business.dart, mirrored by
-- normalize_category() in ifind_backend/main.py) rather than the seed
-- dataset's descriptive strings — both forms normalize to the same bucket,
-- so this is consistent with the existing rows either way.
-- =============================================================================

INSERT INTO public.category_connections (category_a, category_b, connection_type)
VALUES
    ('wholesale', 'footwear', 'supplies'),
    ('manufacturing', 'footwear', 'supplies'),
    ('beauty', 'footwear', 'supplies'),
    ('fashion', 'footwear', 'complements'),
    ('footwear', 'fashion', 'complements')
ON CONFLICT DO NOTHING;
