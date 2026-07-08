-- =============================================================================
-- Migration 34: Let footwear businesses match with other footwear businesses
-- =============================================================================
-- Problem: the B2B hybrid recommender's rule-based scorer (ifind_backend/
-- main.py, final_hybrid_recommend) only awards a rule_score for a pair when
-- there's a category_connections row with category_a == the SOURCE
-- business's category. Migration 22 gave "footwear" exactly one such row
-- (footwear -> fashion), so a footwear business's only rule-scored matches
-- are fashion businesses. Two footwear businesses get zero rule_score
-- between them and fall back to content_score alone — which is usually weak,
-- since the TF-IDF vectorizer's input is "category neighbourhood" and IDF
-- down-weights the category token once many businesses share it, letting
-- neighbourhood-token overlap dominate instead. Net effect: footwear
-- businesses rarely see other footwear businesses recommended at all,
-- consistently losing out to categories that DO have a rule_score boost
-- (like fashion).
--
-- Fix: add a self-referential connection so footwear-to-footwear pairs get
-- a real rule_score too, on equal footing with footwear-to-fashion.
--
-- Note: ifind_backend/main.py loads category_connections once at process
-- start (module-level `connections = pd.DataFrame(...)`), so the running
-- Render service needs a restart/redeploy to pick this row up.
-- =============================================================================

INSERT INTO public.category_connections (category_a, category_b, connection_type)
VALUES
    ('footwear', 'footwear', 'similar')
ON CONFLICT DO NOTHING;
