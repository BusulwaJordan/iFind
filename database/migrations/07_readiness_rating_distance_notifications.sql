-- =============================================================================
-- Migration 07: Readiness fixes for ratings, proximity and notifications
-- =============================================================================

-- Keep business rating_average/rating_count accurate after every review change.
CREATE OR REPLACE FUNCTION public.update_business_rating()
RETURNS TRIGGER AS $$
DECLARE
    target_business_id UUID;
BEGIN
    target_business_id := COALESCE(NEW.business_id, OLD.business_id);

    UPDATE public.businesses
    SET
        rating_average = (
            SELECT COALESCE(ROUND(AVG(rating)::numeric, 1), 0)
            FROM public.reviews
            WHERE business_id = target_business_id
        ),
        rating_count = (
            SELECT COUNT(*)
            FROM public.reviews
            WHERE business_id = target_business_id
        ),
        updated_at = NOW()
    WHERE id = target_business_id;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS update_rating_on_review_insert ON public.reviews;
DROP TRIGGER IF EXISTS update_rating_on_review_update ON public.reviews;
DROP TRIGGER IF EXISTS update_rating_on_review_delete ON public.reviews;

CREATE TRIGGER update_rating_on_review_insert
    AFTER INSERT ON public.reviews
    FOR EACH ROW
    EXECUTE FUNCTION public.update_business_rating();

CREATE TRIGGER update_rating_on_review_update
    AFTER UPDATE ON public.reviews
    FOR EACH ROW
    EXECUTE FUNCTION public.update_business_rating();

CREATE TRIGGER update_rating_on_review_delete
    AFTER DELETE ON public.reviews
    FOR EACH ROW
    EXECUTE FUNCTION public.update_business_rating();

-- Return distance in kilometers. The app displays and filters in kilometers.
CREATE OR REPLACE FUNCTION public.get_nearby_businesses(
    lat double precision,
    long double precision,
    radius_km double precision,
    category_filter text DEFAULT NULL
)
RETURNS TABLE (
    id uuid,
    owner_id uuid,
    name text,
    description text,
    category text,
    address text,
    phone text,
    email text,
    is_arcade boolean,
    is_verified boolean,
    verification_status text,
    rating_average numeric,
    rating_count integer,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
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
        b.id,
        b.owner_id,
        b.name,
        b.description,
        b.category,
        b.address,
        b.phone,
        b.email,
        b.is_arcade,
        b.is_verified,
        b.verification_status,
        b.rating_average,
        b.rating_count,
        b.created_at,
        b.updated_at,
        ST_Y(b.location::geometry) AS latitude,
        ST_X(b.location::geometry) AS longitude,
        ST_Distance(
            b.location,
            ST_SetSRID(ST_MakePoint(long, lat), 4326)::geography
        ) / 1000.0 AS distance
    FROM public.businesses b
    WHERE b.location IS NOT NULL
      AND ST_DWithin(
          b.location,
          ST_SetSRID(ST_MakePoint(long, lat), 4326)::geography,
          radius_km * 1000.0
      )
      AND (category_filter IS NULL OR category_filter = '' OR b.category = category_filter)
    ORDER BY distance ASC, b.rating_average DESC, b.rating_count DESC;
END;
$$;

-- Existing migration 06 used buyer_id/seller_id, but this schema uses
-- customer_id/business_id. Notify only the customer or the owner of that chat's
-- business, keeping inquiries tied to the correct business.
CREATE OR REPLACE FUNCTION public.on_chat_message_sent()
RETURNS TRIGGER AS $$
DECLARE
    chat_rec RECORD;
    recipient_id UUID;
    sender_name TEXT;
BEGIN
    SELECT c.customer_id, c.business_id, b.owner_id, b.name AS business_name
    INTO chat_rec
    FROM public.chats c
    JOIN public.businesses b ON b.id = c.business_id
    WHERE c.id = NEW.chat_id;

    IF chat_rec IS NULL THEN
        RETURN NEW;
    END IF;

    IF NEW.sender_id = chat_rec.customer_id THEN
        recipient_id := chat_rec.owner_id;
    ELSIF NEW.sender_id = chat_rec.owner_id THEN
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
            chat_rec.business_id,
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_chat_message_notification ON public.messages;
CREATE TRIGGER trg_chat_message_notification
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.on_chat_message_sent();
