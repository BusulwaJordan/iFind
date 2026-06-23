-- =============================================================================
-- Migration 08: Friendly chat previews for product inquiries
-- =============================================================================

CREATE OR REPLACE FUNCTION public.update_chat_last_message()
RETURNS TRIGGER AS $$
DECLARE
    product_payload JSONB;
    preview TEXT;
BEGIN
    preview := NEW.content;

    IF NEW.content LIKE 'IFIND_PRODUCT_INQUIRY::%' THEN
        BEGIN
            product_payload := substring(NEW.content from length('IFIND_PRODUCT_INQUIRY::') + 1)::jsonb;
            preview := 'Product inquiry: ' || COALESCE(product_payload->>'title', 'product');
        EXCEPTION WHEN OTHERS THEN
            preview := 'Product inquiry';
        END;
    ELSIF NEW.content LIKE '[MEDIA_INQUIRY]|%' THEN
        preview := 'Product inquiry';
    END IF;

    UPDATE public.chats
    SET
        last_message = preview,
        last_message_at = NEW.created_at
    WHERE id = NEW.chat_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
