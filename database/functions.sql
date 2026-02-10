-- ==========================================
-- Database Functions
-- ==========================================

-- Get nearby businesses with optional category filter
-- usage: select * from get_nearby_businesses(0.3476, 32.5825, 5, 'food');
CREATE OR REPLACE FUNCTION get_nearby_businesses(
  lat double precision,
  long double precision,
  radius_km double precision,
  category_filter text DEFAULT NULL
)
RETURNS SETOF public.businesses
LANGUAGE sql
STABLE
AS $$
  SELECT *
  FROM public.businesses
  WHERE
    ST_DWithin(
      location,
      ST_SetSRID(ST_MakePoint(long, lat), 4326),
      radius_km * 1000 -- radius in meters
    )
    AND (category_filter IS NULL OR category = category_filter)
  ORDER BY
    location <-> ST_SetSRID(ST_MakePoint(long, lat), 4326);
$$;
