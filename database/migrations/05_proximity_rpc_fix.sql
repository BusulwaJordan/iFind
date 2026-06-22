-- =============================================================================
-- Migration 05: Overloaded Proximity RPC Fix
-- =============================================================================
-- This migration adds an overloaded version of get_nearby_businesses that
-- matches the parameters passed by the Flutter BusinessRemoteDataSource:
--   - lat (user latitude)
--   - long (user longitude)
--   - radius_km (radius in kilometers)
--   - category_filter (optional category text string)
--
-- This ensures that proximity searches on the Home Screen work seamlessly.
-- =============================================================================

CREATE OR REPLACE FUNCTION get_nearby_businesses(
    lat double precision,
    long double precision,
    radius_km double precision,
    category_filter text DEFAULT NULL
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
        ST_Distance(b.location, ST_SetSRID(ST_MakePoint(long, lat), 4326)::geography) AS distance
    FROM businesses b
    WHERE ST_DWithin(
        b.location,
        ST_SetSRID(ST_MakePoint(long, lat), 4326)::geography,
        radius_km * 1000.0 -- Convert km to meters
    )
    AND (category_filter IS NULL OR category_filter = '' OR b.category = category_filter)
    ORDER BY distance ASC;
END;
$$;
