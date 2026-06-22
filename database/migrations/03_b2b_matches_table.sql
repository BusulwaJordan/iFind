-- =============================================================================
-- Migration 03: B2B Matches Table
-- =============================================================================
-- Required by MODEL 3 (B2B Random Forest Regression)
-- This table stores historical B2B partnership data used for training.
-- The Edge Function reads from b2b_model.pkl (pre-trained), NOT this table.
-- This table is used for: re-training, analytics, and storing new match data.
-- =============================================================================

CREATE TABLE IF NOT EXISTS b2b_matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_a_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    business_b_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    compatibility_score NUMERIC(4,3) CHECK (
        compatibility_score >= 0 AND compatibility_score <= 1
    ),
    distance_km NUMERIC(8,3),  -- Computed from PostGIS at insert time
    is_confirmed BOOLEAN DEFAULT FALSE, -- True = actual partnership formed
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Prevent duplicate pairs (A↔B = B↔A)
    CONSTRAINT no_duplicate_pairs CHECK (business_a_id < business_b_id),
    UNIQUE(business_a_id, business_b_id)
);

CREATE INDEX IF NOT EXISTS idx_b2b_business_a ON b2b_matches(business_a_id);
CREATE INDEX IF NOT EXISTS idx_b2b_business_b ON b2b_matches(business_b_id);
CREATE INDEX IF NOT EXISTS idx_b2b_score ON b2b_matches(compatibility_score DESC);

-- RLS: Only business owners can see their own matches
ALTER TABLE b2b_matches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Business owners can view their B2B matches"
    ON b2b_matches FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM businesses
            WHERE (id = b2b_matches.business_a_id OR id = b2b_matches.business_b_id)
            AND owner_id = auth.uid()
        )
    );

-- Service role can insert (from Edge Function)
CREATE POLICY "Service role can insert B2B matches"
    ON b2b_matches FOR INSERT
    WITH CHECK (TRUE);

-- =============================================================================
-- Auto-compute distance_km when inserting a new match
-- =============================================================================
CREATE OR REPLACE FUNCTION compute_b2b_distance()
RETURNS TRIGGER AS $$
BEGIN
    NEW.distance_km := (
        SELECT ST_Distance(
            a.location::geography,
            b.location::geography
        ) / 1000.0  -- Convert meters to km
        FROM businesses a, businesses b
        WHERE a.id = NEW.business_a_id
          AND b.id = NEW.business_b_id
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_b2b_distance ON b2b_matches;
CREATE TRIGGER set_b2b_distance
    BEFORE INSERT ON b2b_matches
    FOR EACH ROW
    EXECUTE FUNCTION compute_b2b_distance();
