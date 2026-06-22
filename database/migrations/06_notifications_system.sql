-- =============================================================================
-- Migration 06: Notification System Redesign & Triggers
-- =============================================================================

-- Drop the old table and dependencies
DROP TABLE IF EXISTS public.notifications CASCADE;

-- Create notifications table
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- Nullable in schema, populated by trigger if omitted
    business_id UUID REFERENCES public.businesses(id) ON DELETE CASCADE,
    need_id UUID REFERENCES public.needs(id) ON DELETE SET NULL,
    type TEXT NOT NULL DEFAULT 'system', -- 'system', 'chat', 'b2b_match', 'need_match'
    data JSONB DEFAULT '{}'::jsonb NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Indexes for fast querying
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_business ON public.notifications(business_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);

-- Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 1. Row Level Security Policies
-- =============================================================================

CREATE POLICY "Users can view their own notifications"
    ON public.notifications FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
    ON public.notifications FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notifications"
    ON public.notifications FOR DELETE
    USING (auth.uid() = user_id);

CREATE POLICY "Authenticated users can insert notifications"
    ON public.notifications FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- =============================================================================
-- 2. Trigger: Set Default user_id & type before insert
-- =============================================================================

CREATE OR REPLACE FUNCTION public.set_notification_defaults()
RETURNS TRIGGER AS $$
BEGIN
    -- If user_id is omitted but business_id is set, resolve owner_id
    IF NEW.user_id IS NULL AND NEW.business_id IS NOT NULL THEN
        SELECT owner_id INTO NEW.user_id
        FROM public.businesses
        WHERE id = NEW.business_id;
    END IF;

    -- Ensure user_id is set
    IF NEW.user_id IS NULL THEN
        RAISE EXCEPTION 'user_id must be provided or resolvable via business_id';
    END IF;

    -- Default type
    IF NEW.type IS NULL THEN
        NEW.type := 'system';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_set_notification_defaults
    BEFORE INSERT ON public.notifications
    FOR EACH ROW
    EXECUTE FUNCTION public.set_notification_defaults();

-- =============================================================================
-- 3. Trigger: Automatically create notifications on chat messages
-- =============================================================================

CREATE OR REPLACE FUNCTION public.on_chat_message_sent()
RETURNS TRIGGER AS $$
DECLARE
    chat_rec RECORD;
    recipient_id UUID;
    sender_name TEXT;
BEGIN
    -- Get chat details
    SELECT buyer_id, seller_id, business_id INTO chat_rec
    FROM public.chats
    WHERE id = NEW.chat_id;

    -- Determine recipient
    IF NEW.sender_id = chat_rec.buyer_id THEN
        recipient_id := chat_rec.seller_id;
    ELSIF NEW.sender_id = chat_rec.seller_id THEN
        recipient_id := chat_rec.buyer_id;
    ELSE
        recipient_id := COALESCE(chat_rec.seller_id, chat_rec.buyer_id);
    END IF;

    -- Get sender name
    SELECT full_name INTO sender_name
    FROM public.users
    WHERE id = NEW.sender_id;

    IF recipient_id IS NOT NULL THEN
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
            COALESCE(sender_name, 'New Message'),
            NEW.content,
            jsonb_build_object(
                'chat_id', NEW.chat_id,
                'sender_name', COALESCE(sender_name, 'Someone'),
                'buyer_id', chat_rec.buyer_id,
                'seller_id', chat_rec.seller_id,
                'business_id', chat_rec.business_id
            )
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_chat_message_notification ON public.messages;
CREATE TRIGGER trg_chat_message_notification
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.on_chat_message_sent();

-- =============================================================================
-- 4. Trigger: Automatically create notifications on high-scoring B2B matches
-- =============================================================================

CREATE OR REPLACE FUNCTION public.on_b2b_match_created()
RETURNS TRIGGER AS $$
DECLARE
    business_a_rec RECORD;
    business_b_rec RECORD;
    compatibility_pct INT;
BEGIN
    -- Only notify on high compatibility (>= 0.70)
    IF NEW.compatibility_score >= 0.70 THEN
        -- Get details for Business A and B
        SELECT name, owner_id INTO business_a_rec FROM public.businesses WHERE id = NEW.business_a_id;
        SELECT name, owner_id INTO business_b_rec FROM public.businesses WHERE id = NEW.business_b_id;

        compatibility_pct := ROUND(NEW.compatibility_score * 100);

        -- Notify Owner of Business A about Business B
        IF business_a_rec.owner_id IS NOT NULL AND business_b_rec.owner_id != business_a_rec.owner_id THEN
            INSERT INTO public.notifications (
                user_id,
                business_id,
                type,
                title,
                body,
                data
            ) VALUES (
                business_a_rec.owner_id,
                NEW.business_a_id,
                'b2b_match',
                'New Business Partner Match!',
                business_b_rec.name || ' is a highly compatible partner (' || compatibility_pct || '% match) nearby!',
                jsonb_build_object(
                    'partner_business_id', NEW.business_b_id,
                    'business_name', business_b_rec.name,
                    'compatibility_score', NEW.compatibility_score
                )
            );
        END IF;

        -- Notify Owner of Business B about Business A
        IF business_b_rec.owner_id IS NOT NULL AND business_b_rec.owner_id != business_a_rec.owner_id THEN
            INSERT INTO public.notifications (
                user_id,
                business_id,
                type,
                title,
                body,
                data
            ) VALUES (
                business_b_rec.owner_id,
                NEW.business_b_id,
                'b2b_match',
                'New Business Partner Match!',
                business_a_rec.name || ' is a highly compatible partner (' || compatibility_pct || '% match) nearby!',
                jsonb_build_object(
                    'partner_business_id', NEW.business_a_id,
                    'business_name', business_a_rec.name,
                    'compatibility_score', NEW.compatibility_score
                )
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_b2b_match_notification ON public.b2b_matches;
CREATE TRIGGER trg_b2b_match_notification
    AFTER INSERT ON public.b2b_matches
    FOR EACH ROW
    EXECUTE FUNCTION public.on_b2b_match_created();
