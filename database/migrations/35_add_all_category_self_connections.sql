-- =============================================================================
-- Migration 35: Let every category match with itself (app-wide)
-- =============================================================================
-- Same root cause as migration 34 (footwear specifically), generalized: the
-- B2B hybrid recommender's rule-based scorer only awards a rule_score for a
-- pair when category_connections has a row with category_a == the SOURCE
-- business's category. No category had a self-referential row, so ANY two
-- businesses in the same category always scored rule_score = 0 against each
-- other and fell back to a usually-weak content_score alone — same-category
-- businesses were systematically outranked by whichever categories DID have
-- a rule_score-boosted connection defined.
--
-- Fix: give every category in BusinessCategory (see storageValue in
-- lib/features/business/domain/entities/business.dart) a self-connection,
-- so same-category businesses get a real rule_score everywhere, not just
-- footwear.
--
-- Note: ifind_backend/main.py loads category_connections once at process
-- start, so the running Render service needs a restart/redeploy to pick
-- these rows up.
-- =============================================================================

INSERT INTO public.category_connections (category_a, category_b, connection_type)
VALUES
    ('retail', 'retail', 'similar'),
    ('service', 'service', 'similar'),
    ('food', 'food', 'similar'),
    ('fashion', 'fashion', 'similar'),
    ('footwear', 'footwear', 'similar'),
    ('electronics', 'electronics', 'similar'),
    ('home', 'home', 'similar'),
    ('beauty', 'beauty', 'similar'),
    ('automotive', 'automotive', 'similar'),
    ('health', 'health', 'similar'),
    ('sports', 'sports', 'similar'),
    ('kids', 'kids', 'similar'),
    ('education', 'education', 'similar'),
    ('entertainment', 'entertainment', 'similar'),
    ('arcade', 'arcade', 'similar'),
    ('travel', 'travel', 'similar'),
    ('real_estate', 'real_estate', 'similar'),
    ('pets', 'pets', 'similar'),
    ('finance', 'finance', 'similar'),
    ('agriculture', 'agriculture', 'similar'),
    ('wholesale', 'wholesale', 'similar'),
    ('manufacturing', 'manufacturing', 'similar'),
    ('construction', 'construction', 'similar'),
    ('other', 'other', 'similar')
ON CONFLICT DO NOTHING;
