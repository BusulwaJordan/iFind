-- =============================================================================
-- Migration 27: Create the chat_attachments storage bucket (photo sharing)
-- =============================================================================
-- Problem: the chat's "Photo sharing" attachment icon now actually uploads
-- to Supabase Storage and sends the resulting URL as a message, but there's
-- no bucket for it yet — uploads would fail with "Bucket not found".
--
-- Public bucket (matching profile_images / business_portfolios) so the
-- uploaded image loads directly via its public URL for both chat
-- participants, no signed URLs needed.
-- =============================================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('chat_attachments', 'chat_attachments', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY chat_attachments_upload ON storage.objects
    FOR INSERT
    WITH CHECK (bucket_id = 'chat_attachments' AND auth.role() = 'authenticated');

CREATE POLICY chat_attachments_read ON storage.objects
    FOR SELECT
    USING (bucket_id = 'chat_attachments');
