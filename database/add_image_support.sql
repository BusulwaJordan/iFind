-- ==========================================
-- Add Image Support to Businesses
-- ==========================================

-- 1. Add missing columns to businesses table
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS logo_url TEXT;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS cover_image_url TEXT;

-- 2. Ensure storage bucket exists
INSERT INTO storage.buckets (id, name, public) 
VALUES ('business_images', 'business_images', true)
ON CONFLICT (id) DO NOTHING;

-- 3. Storage Policies for business_images
CREATE POLICY "Public Access Business Images"
ON storage.objects FOR SELECT
USING ( bucket_id = 'business_images' );

CREATE POLICY "Business Owners Upload Business Images"
ON storage.objects FOR INSERT
WITH CHECK ( bucket_id = 'business_images' AND auth.role() = 'authenticated' );
