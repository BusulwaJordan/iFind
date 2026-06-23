-- =============================================================================
-- Migration 14: Database Schema Harmonization & Robust Proximity Function
-- =============================================================================
-- Goals:
-- 1. Ensure public.users table has the columns expected by the Flutter app:
--    - id (UUID, UNIQUE, referencing auth.users)
--    - role (TEXT, checked)
--    - full_name (TEXT)
--    - updated_at (TIMESTAMPTZ)
-- 2. Ensure public.businesses table has:
--    - owner_id (UUID, referencing public.users(id))
--    - description (TEXT)
--    - address (TEXT)
--    - email (TEXT)
--    - is_arcade (BOOLEAN)
--    - verification_status (TEXT)
--    - rating_average (NUMERIC)
--    - rating_count (INTEGER)
--    - updated_at (TIMESTAMPTZ)
-- 3. Migrate and align existing seed data columns to the new columns.
-- 4. Recreate the get_nearby_businesses RPC with robust fuzzy category matching.
-- 5. Update public.handle_new_user() trigger for clean inserts.
-- =============================================================================

-- Enable extension for generating UUIDs if not present
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. HARMONIZE USERS TABLE
-- -----------------------------------------------------------------------------

-- Add columns if they do not exist
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS id UUID UNIQUE;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS role TEXT CHECK (role IN ('customer', 'business_owner', 'manager'));
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS full_name TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Fallback for primary/unique keys if user_id was NOT NULL
ALTER TABLE public.users ALTER COLUMN user_id SET DEFAULT gen_random_uuid()::text;
ALTER TABLE public.users ALTER COLUMN user_id DROP NOT NULL;

-- Migrate existing users seed data to the new columns
UPDATE public.users
SET role = COALESCE(
        CASE 
            WHEN user_type = 'business_owner' THEN 'business_owner'::text
            WHEN user_type = 'manager' THEN 'manager'::text
            ELSE 'customer'::text
        END, 
        'customer'
    )
WHERE role IS NULL;

UPDATE public.users
SET full_name = COALESCE(
        NULLIF(TRIM(COALESCE(first_name, '') || ' ' || COALESCE(last_name, '')), ''),
        email,
        'New User'
    )
WHERE full_name IS NULL;

-- -----------------------------------------------------------------------------
-- 2. HARMONIZE BUSINESSES TABLE
-- -----------------------------------------------------------------------------

-- Add columns if they do not exist
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS owner_id UUID;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS is_arcade BOOLEAN DEFAULT FALSE;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected'));
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS rating_average NUMERIC(2,1) DEFAULT 0.0 CHECK (rating_average >= 0 AND rating_average <= 5);
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS rating_count INTEGER DEFAULT 0;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Migrate existing businesses seed data to the new columns
UPDATE public.businesses
SET rating_average = COALESCE(avg_rating, 0.0),
    rating_count = COALESCE(review_count, 0),
    email = COALESCE(email, owner_email),
    address = COALESCE(address, neighbourhood, 'Kampala'),
    description = COALESCE(description, '')
WHERE rating_average IS NULL OR rating_count IS NULL;

-- Now add foreign key constraint to owner_id if possible (making it reference users(id) ON DELETE CASCADE)
-- We use a DO block to prevent errors if the constraint already exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'businesses_owner_id_fkey' 
          AND table_name = 'businesses'
    ) THEN
        ALTER TABLE public.businesses 
        ADD CONSTRAINT businesses_owner_id_fkey 
        FOREIGN KEY (owner_id) 
        REFERENCES public.users(id) 
        ON DELETE CASCADE;
    END IF;
END $$;

-- -----------------------------------------------------------------------------
-- 3. RECREATE GET_NEARBY_BUSINESSES RPC
-- -----------------------------------------------------------------------------

-- Drop all old overloads
DROP FUNCTION IF EXISTS public.get_nearby_businesses(double precision, double precision, double precision);
DROP FUNCTION IF EXISTS public.get_nearby_businesses(double precision, double precision, double precision, text);
DROP FUNCTION IF EXISTS get_nearby_businesses(double precision, double precision, double precision);
DROP FUNCTION IF EXISTS get_nearby_businesses(double precision, double precision, double precision, text);

-- Recreate canonical version
CREATE OR REPLACE FUNCTION public.get_nearby_businesses(
    lat double precision,
    long double precision,
    radius_km double precision,
    category_filter text DEFAULT NULL
)
RETURNS TABLE (
    id text,
    owner_id uuid,
    name text,
    description text,
    category text,
    sub_category text,
    address text,
    phone text,
    website text,
    email text,
    logo_url text,
    cover_image_url text,
    is_arcade boolean,
    is_verified boolean,
    verification_status text,
    rating_average numeric,
    rating_count integer,
    created_at timestamptz,
    updated_at timestamptz,
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
        COALESCE(b.business_id, b.id::text) AS id,
        b.owner_id,
        b.name,
        COALESCE(b.description, '')::text AS description,
        COALESCE(NULLIF(b.category, ''), 'other')::text AS category,
        b.sub_category,
        b.address,
        b.phone,
        b.website,
        b.email,
        b.logo_url,
        b.cover_image_url,
        COALESCE(b.is_arcade, false),
        COALESCE(b.is_verified, false),
        COALESCE(b.verification_status, 'pending')::text AS verification_status,
        COALESCE(b.rating_average, 0.0)::numeric AS rating_average,
        COALESCE(b.rating_count, 0)::integer AS rating_count,
        b.created_at::timestamptz,
        b.updated_at::timestamptz,
        COALESCE(b.latitude, ST_Y(b.location::geometry))::double precision AS latitude,
        COALESCE(b.longitude, ST_X(b.location::geometry))::double precision AS longitude,
        (ST_Distance(
            b.location,
            ST_SetSRID(ST_MakePoint(long, lat), 4326)::geography
        ) / 1000.0)::double precision AS distance
    FROM public.businesses b
    WHERE b.location IS NOT NULL
      AND ST_DWithin(
          b.location,
          ST_SetSRID(ST_MakePoint(long, lat), 4326)::geography,
          radius_km * 1000.0
      )
      AND (
          category_filter IS NULL
          OR category_filter = ''
          OR b.category ILIKE '%' || category_filter || '%'
          OR category_filter ILIKE '%' || b.category || '%'
          OR (category_filter = 'real_estate' AND b.category ILIKE '%real%estate%')
          OR (category_filter = 'service' AND b.category ILIKE '%services%')
      )
    ORDER BY distance ASC, b.rating_average DESC, b.rating_count DESC;
END;
$$;

-- Grant execute to authenticated users and the anon role
GRANT EXECUTE ON FUNCTION public.get_nearby_businesses(
    double precision, double precision, double precision, text
) TO authenticated, anon;

-- -----------------------------------------------------------------------------
-- 4. UPDATE SIGNUP TRIGGER
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  extracted_name TEXT;
  extracted_role TEXT;
BEGIN
  extracted_name := COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    split_part(NEW.email, '@', 1)
  );

  extracted_role := COALESCE(NEW.raw_user_meta_data->>'role', 'customer');

  INSERT INTO public.users (id, email, role, full_name, phone)
  VALUES (
    NEW.id,
    NEW.email,
    extracted_role,
    extracted_name,
    NEW.raw_user_meta_data->>'phone'
  )
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger if needed (safeguard)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';
