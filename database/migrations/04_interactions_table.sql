-- =============================================================================
-- Migration 04: Interactions Table
-- =============================================================================
-- Required by MODEL 2 (B2C Collaborative Filtering / ALS)
-- Stores user-business interaction events used for training the recommender.
--
-- The B2C model was trained on these interaction_type values:
--   view, search_click, profile_view, saved_business, inquiry_sent, review_posted
--
-- Higher-weight interactions (inquiry_sent, review_posted) indicate stronger
-- user preference and are weighted more heavily during model training.
-- =============================================================================

CREATE TABLE IF NOT EXISTS interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,

    -- Interaction type (matches the training dataset values)
    interaction_type TEXT NOT NULL CHECK (
        interaction_type IN (
            'view',
            'search_click',
            'profile_view',
            'saved_business',
            'inquiry_sent',
            'review_posted'
        )
    ),

    -- Optional metadata
    session_id TEXT,                               -- For deduplication
    duration_seconds INTEGER,                      -- How long they viewed (for 'view' type)

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_interactions_user ON interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_interactions_business ON interactions(business_id);
CREATE INDEX IF NOT EXISTS idx_interactions_type ON interactions(interaction_type);
CREATE INDEX IF NOT EXISTS idx_interactions_created ON interactions(created_at DESC);

-- Composite: used for training data export
CREATE INDEX IF NOT EXISTS idx_interactions_user_business
    ON interactions(user_id, business_id, interaction_type);

-- RLS
ALTER TABLE interactions ENABLE ROW LEVEL SECURITY;

-- Users can see their own interaction history
CREATE POLICY "Users can view own interactions"
    ON interactions FOR SELECT
    USING (auth.uid() = user_id);

-- App can insert interactions (authenticated users)
CREATE POLICY "Authenticated users can log interactions"
    ON interactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Business owners can see interactions with their businesses (analytics)
CREATE POLICY "Business owners can view interactions on their businesses"
    ON interactions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM businesses
            WHERE id = interactions.business_id
            AND owner_id = auth.uid()
        )
    );

-- =============================================================================
-- Convenience view: interaction weights for model training export
-- =============================================================================
CREATE OR REPLACE VIEW interaction_weights AS
SELECT
    user_id,
    business_id,
    interaction_type,
    CASE interaction_type
        WHEN 'view'           THEN 1.0
        WHEN 'search_click'   THEN 2.0
        WHEN 'profile_view'   THEN 2.5
        WHEN 'saved_business' THEN 4.0
        WHEN 'inquiry_sent'   THEN 5.0
        WHEN 'review_posted'  THEN 6.0
        ELSE 1.0
    END AS weight,
    created_at
FROM interactions;
