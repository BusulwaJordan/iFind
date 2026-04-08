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


-- 3. Fix Google OAuth new user profile creation
-- Google users don't have 'role' or 'full_name' in raw_user_meta_data the same way.
-- Google puts the name in 'full_name' or 'name', and there is no role.
-- We update handle_new_user to gracefully handle both cases.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  extracted_name TEXT;
  extracted_role TEXT;
BEGIN
  -- Google OAuth puts name in 'full_name' or 'name'
  extracted_name := COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    split_part(NEW.email, '@', 1)
  );

  -- Role defaults to 'customer' for Google users (they can change it in settings)
  extracted_role := COALESCE(NEW.raw_user_meta_data->>'role', 'customer');

  INSERT INTO public.users (id, email, role, full_name, phone)
  VALUES (
    NEW.id,
    NEW.email,
    extracted_role,
    extracted_name,
    NEW.raw_user_meta_data->>'phone'
  )
  ON CONFLICT (id) DO NOTHING; -- Safe for re-triggers
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Allow all users to view all businesses (MVP: no verification gate)
DROP POLICY IF EXISTS "Public can view verified businesses" ON businesses;
DROP POLICY IF EXISTS "All users can view all businesses" ON businesses;

CREATE POLICY "All users can view all businesses"
    ON businesses FOR SELECT
    USING (TRUE);
