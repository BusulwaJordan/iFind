-- ==========================================
-- Fix Business Visibility RLS Policies
-- ==========================================

-- 1. Drop the restrictive policy that only allows viewing verified businesses
DROP POLICY IF EXISTS "Public can view verified businesses" ON public.businesses;

-- 2. Create a new policy to allow everyone to view ALL businesses
-- This ensures when your friend creates a shop, you can see it immediately.
CREATE POLICY "Public can view all businesses"
ON public.businesses FOR SELECT
USING (true);

-- 3. Ensure the nearby discovery function returns results to all users
-- This updates the RLS context so get_nearby_businesses works for everyone
ALTER FUNCTION get_nearby_businesses(double precision, double precision, double precision, text) 
SECURITY DEFINER;

-- 4. (Optional) If you want to restrict viewing of 'rejected' businesses:
-- DROP POLICY IF EXISTS "Public can view all businesses" ON public.businesses;
-- CREATE POLICY "Public can view non-rejected businesses"
-- ON public.businesses FOR SELECT
-- USING (verification_status != 'rejected');
