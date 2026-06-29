-- ============================================================
-- Run this in your Supabase SQL Editor (Dashboard > SQL Editor)
-- ============================================================

-- ── 1. Favorites table ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS favorites (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  business_id  UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, business_id)
);

ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own favorites"
  ON favorites FOR ALL
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ── 2. Reviews table RLS ───────────────────────────────────
-- (Create the table if it doesn't exist yet)
CREATE TABLE IF NOT EXISTS reviews (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id  UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  customer_id  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating       SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment      TEXT,
  owner_reply  TEXT,
  replied_at   TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- Anyone can read reviews
DROP POLICY IF EXISTS "reviews_read" ON reviews;
CREATE POLICY "reviews_read"
  ON reviews FOR SELECT
  USING (true);

-- Authenticated users can post reviews
DROP POLICY IF EXISTS "reviews_insert" ON reviews;
CREATE POLICY "reviews_insert"
  ON reviews FOR INSERT
  WITH CHECK (auth.uid() = customer_id);

-- Business owners can reply to their reviews
DROP POLICY IF EXISTS "reviews_owner_reply" ON reviews;
CREATE POLICY "reviews_owner_reply"
  ON reviews FOR UPDATE
  USING (
    auth.uid() IN (
      SELECT owner_id FROM businesses WHERE id = reviews.business_id
    )
  );

-- ── 3. Optional: FK so reviews can join users table ────────
-- This lets getReviews show reviewer names automatically.
-- Only run if reviews.customer_id is not already an FK to public.users:
ALTER TABLE reviews
  ADD CONSTRAINT IF NOT EXISTS reviews_customer_id_fkey
  FOREIGN KEY (customer_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- ── 4. Make business_images bucket public ──────────────────
-- Alternatively: Supabase Dashboard > Storage > business_images > Make Public
UPDATE storage.buckets
  SET public = true
  WHERE id = 'business_images';

UPDATE storage.buckets
  SET public = true
  WHERE id = 'profile_images';
