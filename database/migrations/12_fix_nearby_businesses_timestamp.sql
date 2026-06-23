-- =============================================================================
-- Migration 12: Fix get_nearby_businesses timestamp type mismatch
-- =============================================================================
-- Problem: Multiple overloaded versions of get_nearby_businesses have been
-- applied. Older versions were deployed with `timestamp without time zone`
-- in the RETURNS TABLE, while the businesses table has
-- `TIMESTAMP WITH TIME ZONE`. PostgreSQL error 42804 fires because the
-- stale overload's declared return type conflicts with what the SELECT
-- actually produces.
--
-- Fix: Drop ALL overloads (3-param and 4-param variants in both public and
-- default schemas) and redeploy one single, canonical version with explicit
-- ::timestamptz casts so the declared return type always matches reality.
-- =============================================================================

-- Drop every known overload so no stale signature survives.
DROP FUNCTION IF EXISTS public.get_nearby_businesses(double precision, double precision, double precision);
DROP FUNCTION IF EXISTS public.get_nearby_businesses(double precision, double precision, double precision, text);
DROP FUNCTION IF EXISTS        get_nearby_businesses(double precision, double precision, double precision);
DROP FUNCTION IF EXISTS        get_nearby_businesses(double precision, double precision, double precision, text);

-- Single authoritative definition.
-- • created_at / updated_at are cast to timestamptz explicitly so the
--   declared RETURNS TABLE always matches even if a future ALTER TABLE changes
--   the storage type.
-- • distance returned in kilometres (÷ 1000) to match the Flutter models.
-- • Results ordered by distance ASC, then rating DESC for "Nearby Top Rated".
CREATE OR REPLACE FUNCTION public.get_nearby_businesses(
    lat            double precision,
    long           double precision,
    radius_km      double precision,
    category_filter text DEFAULT NULL
)
RETURNS TABLE (
    id                  uuid,
    owner_id            uuid,
    name                text,
    description         text,
    category            text,
    address             text,
    phone               text,
    email               text,
    is_arcade           boolean,
    is_verified         boolean,
    verification_status text,
    rating_average      numeric,
    rating_count        integer,
    created_at          timestamptz,
    updated_at          timestamptz,
    latitude            double precision,
    longitude           double precision,
    distance            double precision
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
        b.created_at::timestamptz,
        b.updated_at::timestamptz,
        ST_Y(b.location::geometry)::double precision                       AS latitude,
        ST_X(b.location::geometry)::double precision                       AS longitude,
        (ST_Distance(
            b.location,
            ST_SetSRID(ST_MakePoint(long, lat), 4326)::geography
        ) / 1000.0)::double precision                                      AS distance
    FROM public.businesses b
    WHERE b.location IS NOT NULL
      AND ST_DWithin(
              b.location,
              ST_SetSRID(ST_MakePoint(long, lat), 4326)::geography,
              radius_km * 1000.0   -- km → metres
          )
      AND (
            category_filter IS NULL
            OR category_filter = ''
            OR b.category = category_filter
          )
    ORDER BY distance ASC, b.rating_average DESC, b.rating_count DESC;
END;
$$;

-- Grant execute to authenticated users and the anon role.
GRANT EXECUTE ON FUNCTION public.get_nearby_businesses(
    double precision, double precision, double precision, text
) TO authenticated, anon;
