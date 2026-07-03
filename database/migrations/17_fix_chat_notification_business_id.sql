-- =============================================================================
-- Migration 17: Fix on_chat_message_sent() inserting the wrong business id
-- =============================================================================
-- Problem: notifications.business_id is a foreign key to businesses(business_id)
-- (the custom TEXT id, e.g. "BIZ0122"), but the trigger function inserted
-- businesses.id (the UUID primary key) instead. Since that UUID never matches
-- a business_id TEXT value, every message insert into a B2C chat that reached
-- this trigger failed with a foreign key violation (23503) on notifications,
-- which aborted the whole message send. B2B chats didn't hit this because
-- chats.business_id is only populated for B2C chats, so the lookup returned
-- NULL there and NULL passes the FK check silently.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.on_chat_message_sent()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    chat_rec RECORD;
    recipient_id UUID;
    sender_name TEXT;
BEGIN
    -- Join on business_id (TEXT) instead of id (UUID) since chats.business_id is TEXT
    SELECT c.customer_id, c.business_id, b.owner_id, b.name AS business_name
    INTO chat_rec
    FROM public.chats c
    LEFT JOIN public.businesses b ON b.business_id = c.business_id
    WHERE c.id = NEW.chat_id;

    IF chat_rec IS NULL THEN
        RETURN NEW;
    END IF;

    IF NEW.sender_id = chat_rec.customer_id THEN
        recipient_id := chat_rec.owner_id;
    ELSIF chat_rec.owner_id IS NOT NULL AND NEW.sender_id = chat_rec.owner_id THEN
        recipient_id := chat_rec.customer_id;
    ELSE
        RETURN NEW;
    END IF;

    SELECT full_name INTO sender_name
    FROM public.users
    WHERE id = NEW.sender_id;

    IF recipient_id IS NOT NULL AND recipient_id <> NEW.sender_id THEN
        INSERT INTO public.notifications (
            user_id,
            business_id,
            type,
            title,
            body,
            data
        ) VALUES (
            recipient_id,
            chat_rec.business_id, -- FIX: was chat_rec.business_uuid (businesses.id) — FK requires the TEXT business_id
            'chat',
            COALESCE(sender_name, 'New message'),
            NEW.content,
            jsonb_build_object(
                'chat_id', NEW.chat_id,
                'sender_id', NEW.sender_id,
                'sender_name', COALESCE(sender_name, 'Someone'),
                'customer_id', chat_rec.customer_id,
                'business_id', chat_rec.business_id,
                'business_name', chat_rec.business_name
            )
        );
    END IF;

    RETURN NEW;
END;
$function$;
