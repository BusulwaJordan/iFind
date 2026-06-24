-- =============================================================================
-- Migration 13: Business loading deployment readiness
-- =============================================================================
-- Canonicalizes the business table shape expected by the app, then recreates
-- get_nearby_businesses with a stable return payload.

CREATE EXTENSION IF NOT EXISTS postgis;

ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS id UUID;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS business_id TEXT;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'businesses'
          AND column_name = 'business_id'
    ) THEN
        EXECUTE '
            UPDATE public.businesses
            SET id = business_id::uuid
            WHERE id IS NULL
              AND business_id ~* ''^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$''
        ';
    END IF;
END $$;

UPDATE public.businesses
SET id = gen_random_uuid()
WHERE id IS NULL;

UPDATE public.businesses
SET business_id = id::text
WHERE business_id IS NULL;

ALTER TABLE public.businesses ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE public.businesses ALTER COLUMN id SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS businesses_id_key ON public.businesses(id);

ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS location GEOGRAPHY(POINT, 4326);
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS website TEXT;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS sub_category TEXT;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS logo_url TEXT;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS cover_image_url TEXT;

UPDATE public.businesses
SET location = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
WHERE location IS NULL
  AND latitude IS NOT NULL
  AND longitude IS NOT NULL;

UPDATE public.businesses
SET
    latitude = COALESCE(latitude, ST_Y(location::geometry)),
    longitude = COALESCE(longitude, ST_X(location::geometry))
WHERE location IS NOT NULL
  AND (latitude IS NULL OR longitude IS NULL);

CREATE OR REPLACE FUNCTION public.sync_business_location()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
        NEW.location = ST_SetSRID(
            ST_MakePoint(NEW.longitude, NEW.latitude),
            4326
        )::geography;
    ELSIF NEW.location IS NOT NULL THEN
        NEW.latitude = ST_Y(NEW.location::geometry);
        NEW.longitude = ST_X(NEW.location::geometry);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_sync_business_location ON public.businesses;
CREATE TRIGGER trigger_sync_business_location
BEFORE INSERT OR UPDATE ON public.businesses
FOR EACH ROW
EXECUTE FUNCTION public.sync_business_location();

INSERT INTO storage.buckets (id, name, public)
VALUES ('business_images', 'business_images', true)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;

DROP POLICY IF EXISTS "Public Access Business Images" ON storage.objects;
CREATE POLICY "Public Access Business Images"
ON storage.objects FOR SELECT
USING (bucket_id = 'business_images');

DROP POLICY IF EXISTS "Business Owners Upload Business Images" ON storage.objects;
CREATE POLICY "Business Owners Upload Business Images"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'business_images'
    AND auth.role() = 'authenticated'
);

DROP FUNCTION IF EXISTS public.get_nearby_businesses(double precision, double precision, double precision);
DROP FUNCTION IF EXISTS public.get_nearby_businesses(double precision, double precision, double precision, text);
DROP FUNCTION IF EXISTS get_nearby_businesses(double precision, double precision, double precision);
DROP FUNCTION IF EXISTS get_nearby_businesses(double precision, double precision, double precision, text);

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
        b.verification_status,
        COALESCE(b.rating_average, 0),
        COALESCE(b.rating_count, 0),
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
          OR b.category = category_filter
      )
    ORDER BY distance ASC, b.rating_average DESC, b.rating_count DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_nearby_businesses(
    double precision, double precision, double precision, text
) TO authenticated, anon;

NOTIFY pgrst, 'reload schema';
