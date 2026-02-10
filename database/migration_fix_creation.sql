-- Migration: Fix Business Creation
-- Adds latitude and longitude columns to businesses table and keeps them in sync with PostGIS location

-- 1. Add columns
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- 2. Populate existing data
UPDATE businesses 
SET 
  latitude = ST_Y(location::geometry),
  longitude = ST_X(location::geometry);

-- 3. Create Sync Function
CREATE OR REPLACE FUNCTION sync_business_location()
RETURNS TRIGGER AS $$
BEGIN
  -- If lat/long are provided, update location
  IF (NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL) AND 
     (OLD.latitude IS NULL OR OLD.latitude != NEW.latitude OR OLD.longitude != NEW.longitude) THEN
    NEW.location = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
  -- If location is provided but lat/long are not, update lat/long
  ELSIF (NEW.location IS NOT NULL) AND 
        (OLD.location IS NULL OR OLD.location != NEW.location) THEN
    NEW.latitude = ST_Y(NEW.location::geometry);
    NEW.longitude = ST_X(NEW.location::geometry);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Create Trigger
DROP TRIGGER IF EXISTS trigger_sync_business_location ON businesses;
CREATE TRIGGER trigger_sync_business_location
BEFORE INSERT OR UPDATE ON businesses
FOR EACH ROW
EXECUTE FUNCTION sync_business_location();
