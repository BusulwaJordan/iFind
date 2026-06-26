-- ============================================================
-- Migration 16: User avatar column + profile_images bucket
-- ============================================================
-- Run this in your Supabase SQL editor.

-- 1. Add avatar_url column to users table
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- 2. Create the profile_images storage bucket (public read, auth write)
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile_images', 'profile_images', true)
ON CONFLICT (id) DO NOTHING;

-- 3. Allow anyone to read profile images (public avatars)
CREATE POLICY "Public read profile images"
ON storage.objects FOR SELECT
USING ( bucket_id = 'profile_images' );

-- 4. Allow authenticated users to upload their own avatar
CREATE POLICY "Authenticated users upload profile images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'profile_images'
  AND auth.role() = 'authenticated'
);

-- 5. Allow authenticated users to update/replace their own avatar
CREATE POLICY "Authenticated users update profile images"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'profile_images'
  AND auth.role() = 'authenticated'
);

-- 6. Allow authenticated users to delete their own avatar
CREATE POLICY "Authenticated users delete profile images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'profile_images'
  AND auth.role() = 'authenticated'
);
