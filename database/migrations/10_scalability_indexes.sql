-- =============================================================================
-- Migration 10: Scalability indexes for 2k+ shops and 5k+ users
-- =============================================================================
-- These indexes target the app's hottest list screens: nearby shops, products,
-- chats, messages, notifications, reviews, and interactions.

CREATE INDEX IF NOT EXISTS idx_businesses_verified_category
    ON public.businesses (is_verified, category);

CREATE INDEX IF NOT EXISTS idx_businesses_owner_created
    ON public.businesses (owner_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_products_business_available_created
    ON public.products (business_id, is_available, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_chats_customer_last_message
    ON public.chats (customer_id, last_message_at DESC NULLS LAST);

CREATE INDEX IF NOT EXISTS idx_chats_business_last_message
    ON public.chats (business_id, last_message_at DESC NULLS LAST);

CREATE INDEX IF NOT EXISTS idx_messages_chat_created
    ON public.messages (chat_id, created_at);

CREATE INDEX IF NOT EXISTS idx_notifications_user_created
    ON public.notifications (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notifications_business_created
    ON public.notifications (business_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_reviews_business_created
    ON public.reviews (business_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_interactions_user_created
    ON public.interactions (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_interactions_business_created
    ON public.interactions (business_id, created_at DESC);
