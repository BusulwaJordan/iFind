-- MVP Bug Fixes & Adjustments

-- 1. Fix AI Discovery by removing the strict verification requirement
-- This ensures newly created (unverified) test shops instantly appear on the map and AI Matchmaking.
DROP FUNCTION IF EXISTS get_nearby_businesses(double precision, double precision, double precision);

CREATE OR REPLACE FUNCTION get_nearby_businesses(
    user_lat double precision,
    user_lon double precision,
    radius_meters double precision DEFAULT 5000
) 
RETURNS TABLE (
    id uuid,
    owner_id uuid,
    name text,
    description text,
    category text,
    address text,
    phone text,
    email text,
    is_arcade boolean,
    is_verified boolean,
    verification_status text,
    rating_average numeric,
    rating_count integer,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    latitude double precision,
    longitude double precision,
    distance double precision
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.id,
        b.owner_id,
        b.name,
        b.description,
        b.category,
        b.address,
        b.phone,
        b.email,
        b.is_arcade,
        b.is_verified,
        b.verification_status,
        b.rating_average,
        b.rating_count,
        b.created_at,
        b.updated_at,
        ST_Y(b.location::geometry) AS latitude,
        ST_X(b.location::geometry) AS longitude,
        ST_Distance(b.location, ST_SetSRID(ST_MakePoint(user_lon, user_lat), 4326)::geography) AS distance
    FROM businesses b
    WHERE ST_DWithin(
        b.location,
        ST_SetSRID(ST_MakePoint(user_lon, user_lat), 4326)::geography,   
        radius_meters
    )
    ORDER BY distance ASC;
END;
$$;


-- 2. Relax RLS on Reviews for MVP
-- The original policy restricted reviews to only users with role='customer'.
-- We are removing that restriction so business owners can also test the review system.
DROP POLICY IF EXISTS "Customers can create reviews" ON reviews;
DROP POLICY IF EXISTS "Anyone can create reviews for testing" ON reviews;

CREATE POLICY "Anyone can create reviews for testing"
    ON reviews FOR INSERT
    WITH CHECK (auth.uid() = customer_id);

-- End of MVP Tweaks
