-- =============================================================================
-- Migration 11: Product image storage bucket and policies
-- =============================================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('product_images', 'product_images', true)
ON CONFLICT (id) DO NOTHING;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'storage'
          AND tablename = 'objects'
          AND policyname = 'Public Access Product Images'
    ) THEN
        CREATE POLICY "Public Access Product Images"
        ON storage.objects FOR SELECT
        USING (bucket_id = 'product_images');
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'storage'
          AND tablename = 'objects'
          AND policyname = 'Authenticated Users Upload Product Images'
    ) THEN
        CREATE POLICY "Authenticated Users Upload Product Images"
        ON storage.objects FOR INSERT
        WITH CHECK (
            bucket_id = 'product_images'
            AND auth.role() = 'authenticated'
        );
    END IF;
END $$;
