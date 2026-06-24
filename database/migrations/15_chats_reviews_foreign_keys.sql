-- =============================================================================
-- Migration 15: Harmonize Foreign Keys for Chats, Reviews, Messages, and Products
-- =============================================================================
-- Problem: The chats and reviews tables in the live database were created with
-- text columns (e.g. business_id = 'BIZ0012') to reference seed data, rather
-- than UUIDs. This prevents the app from joining the tables (PostgREST error PGRST200).
--
-- Solution:
-- 1. Identify text columns and dynamically map them to the proper UUID columns
--    created in public.users (id) and public.businesses (id).
-- 2. Drop the old columns and rename the harmonized UUID columns.
-- 3. Add proper foreign key constraints between chats, reviews, messages,
--    products, recommendations and users/businesses.
-- 4. Recreate unique constraints and triggers to ensure data integrity.
-- =============================================================================

DO $$
DECLARE
    col_type TEXT;
BEGIN
    -- -------------------------------------------------------------------------
    -- 1. HARMONIZE CHATS TABLE
    -- -------------------------------------------------------------------------
    
    -- customer_id
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'chats' AND column_name = 'customer_id';
    
    IF col_type = 'character varying' OR col_type = 'text' THEN
        RAISE NOTICE 'Harmonizing chats.customer_id type...';
        ALTER TABLE public.chats ADD COLUMN IF NOT EXISTS customer_id_uuid UUID;
        UPDATE public.chats c
        SET customer_id_uuid = u.id
        FROM public.users u
        WHERE c.customer_id = u.user_id OR c.customer_id = u.id::text;
        
        ALTER TABLE public.chats DROP COLUMN customer_id CASCADE;
        ALTER TABLE public.chats RENAME COLUMN customer_id_uuid TO customer_id;
    END IF;

    -- business_id
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'chats' AND column_name = 'business_id';
    
    IF col_type = 'character varying' OR col_type = 'text' THEN
        RAISE NOTICE 'Harmonizing chats.business_id type...';
        ALTER TABLE public.chats ADD COLUMN IF NOT EXISTS business_id_uuid UUID;
        UPDATE public.chats c
        SET business_id_uuid = b.id
        FROM public.businesses b
        WHERE c.business_id = b.business_id OR c.business_id = b.id::text;
        
        ALTER TABLE public.chats DROP COLUMN business_id CASCADE;
        ALTER TABLE public.chats RENAME COLUMN business_id_uuid TO business_id;
    END IF;
    
    ALTER TABLE public.chats ALTER COLUMN customer_id SET NOT NULL;
    ALTER TABLE public.chats ALTER COLUMN business_id SET NOT NULL;

    -- -------------------------------------------------------------------------
    -- 2. HARMONIZE REVIEWS TABLE
    -- -------------------------------------------------------------------------
    
    -- customer_id
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'reviews' AND column_name = 'customer_id';
    
    IF col_type = 'character varying' OR col_type = 'text' THEN
        RAISE NOTICE 'Harmonizing reviews.customer_id type...';
        ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS customer_id_uuid UUID;
        UPDATE public.reviews r
        SET customer_id_uuid = u.id
        FROM public.users u
        WHERE r.customer_id = u.user_id OR r.customer_id = u.id::text;
        
        ALTER TABLE public.reviews DROP COLUMN customer_id CASCADE;
        ALTER TABLE public.reviews RENAME COLUMN customer_id_uuid TO customer_id;
    END IF;

    -- business_id
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'reviews' AND column_name = 'business_id';
    
    IF col_type = 'character varying' OR col_type = 'text' THEN
        RAISE NOTICE 'Harmonizing reviews.business_id type...';
        ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS business_id_uuid UUID;
        UPDATE public.reviews r
        SET business_id_uuid = b.id
        FROM public.businesses b
        WHERE r.business_id = b.business_id OR r.business_id = b.id::text;
        
        ALTER TABLE public.reviews DROP COLUMN business_id CASCADE;
        ALTER TABLE public.reviews RENAME COLUMN business_id_uuid TO business_id;
    END IF;

    ALTER TABLE public.reviews ALTER COLUMN customer_id SET NOT NULL;
    ALTER TABLE public.reviews ALTER COLUMN business_id SET NOT NULL;

    -- -------------------------------------------------------------------------
    -- 3. HARMONIZE MESSAGES TABLE
    -- -------------------------------------------------------------------------
    
    -- sender_id
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'messages' AND column_name = 'sender_id';
    
    IF col_type = 'character varying' OR col_type = 'text' THEN
        RAISE NOTICE 'Harmonizing messages.sender_id type...';
        ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS sender_id_uuid UUID;
        UPDATE public.messages m
        SET sender_id_uuid = u.id
        FROM public.users u
        WHERE m.sender_id = u.user_id OR m.sender_id = u.id::text;
        
        ALTER TABLE public.messages DROP COLUMN sender_id CASCADE;
        ALTER TABLE public.messages RENAME COLUMN sender_id_uuid TO sender_id;
    END IF;

    ALTER TABLE public.messages ALTER COLUMN sender_id SET NOT NULL;

    -- -------------------------------------------------------------------------
    -- 4. HARMONIZE PRODUCTS TABLE
    -- -------------------------------------------------------------------------
    
    -- business_id
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'products' AND column_name = 'business_id';
    
    IF col_type = 'character varying' OR col_type = 'text' THEN
        RAISE NOTICE 'Harmonizing products.business_id type...';
        ALTER TABLE public.products ADD COLUMN IF NOT EXISTS business_id_uuid UUID;
        UPDATE public.products p
        SET business_id_uuid = b.id
        FROM public.businesses b
        WHERE p.business_id = b.business_id OR p.business_id = b.id::text;
        
        ALTER TABLE public.products DROP COLUMN business_id CASCADE;
        ALTER TABLE public.products RENAME COLUMN business_id_uuid TO business_id;
    END IF;

    -- -------------------------------------------------------------------------
    -- 5. HARMONIZE RECOMMENDATIONS TABLE
    -- -------------------------------------------------------------------------
    
    -- user_id
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'recommendations' AND column_name = 'user_id';
    
    IF col_type = 'character varying' OR col_type = 'text' THEN
        RAISE NOTICE 'Harmonizing recommendations.user_id type...';
        ALTER TABLE public.recommendations ADD COLUMN IF NOT EXISTS user_id_uuid UUID;
        UPDATE public.recommendations r
        SET user_id_uuid = u.id
        FROM public.users u
        WHERE r.user_id = u.user_id OR r.user_id = u.id::text;
        
        ALTER TABLE public.recommendations DROP COLUMN user_id CASCADE;
        ALTER TABLE public.recommendations RENAME COLUMN user_id_uuid TO user_id;
    END IF;

    -- business_id
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'recommendations' AND column_name = 'business_id';
    
    IF col_type = 'character varying' OR col_type = 'text' THEN
        RAISE NOTICE 'Harmonizing recommendations.business_id type...';
        ALTER TABLE public.recommendations ADD COLUMN IF NOT EXISTS business_id_uuid UUID;
        UPDATE public.recommendations r
        SET business_id_uuid = b.id
        FROM public.businesses b
        WHERE r.business_id = b.business_id OR r.business_id = b.id::text;
        
        ALTER TABLE public.recommendations DROP COLUMN business_id CASCADE;
        ALTER TABLE public.recommendations RENAME COLUMN business_id_uuid TO business_id;
    END IF;

    -- -------------------------------------------------------------------------
    -- 6. CREATE FOREIGN KEY CONSTRAINTS
    -- -------------------------------------------------------------------------
    
    -- Chats fkeys
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'chats_customer_id_fkey' AND table_name = 'chats'
    ) THEN
        ALTER TABLE public.chats ADD CONSTRAINT chats_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.users(id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'chats_business_id_fkey' AND table_name = 'chats'
    ) THEN
        ALTER TABLE public.chats ADD CONSTRAINT chats_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;
    END IF;

    -- Reviews fkeys
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'reviews_customer_id_fkey' AND table_name = 'reviews'
    ) THEN
        ALTER TABLE public.reviews ADD CONSTRAINT reviews_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.users(id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'reviews_business_id_fkey' AND table_name = 'reviews'
    ) THEN
        ALTER TABLE public.reviews ADD CONSTRAINT reviews_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;
    END IF;

    -- Messages fkeys
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'messages_sender_id_fkey' AND table_name = 'messages'
    ) THEN
        ALTER TABLE public.messages ADD CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE CASCADE;
    END IF;

    -- Products fkeys
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'products_business_id_fkey' AND table_name = 'products'
    ) THEN
        ALTER TABLE public.products ADD CONSTRAINT products_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;
    END IF;

    -- Recommendations fkeys
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'recommendations_user_id_fkey' AND table_name = 'recommendations'
    ) THEN
        ALTER TABLE public.recommendations ADD CONSTRAINT recommendations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'recommendations_business_id_fkey' AND table_name = 'recommendations'
    ) THEN
        ALTER TABLE public.recommendations ADD CONSTRAINT recommendations_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;
    END IF;

    -- -------------------------------------------------------------------------
    -- 7. RECREATE UNIQUE CONSTRAINTS
    -- -------------------------------------------------------------------------
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'chats_customer_id_business_id_key' AND table_name = 'chats'
    ) THEN
        ALTER TABLE public.chats ADD CONSTRAINT chats_customer_id_business_id_key UNIQUE(customer_id, business_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'reviews_business_id_customer_id_key' AND table_name = 'reviews'
    ) THEN
        ALTER TABLE public.reviews ADD CONSTRAINT reviews_business_id_customer_id_key UNIQUE(business_id, customer_id);
    END IF;

END $$;

-- -----------------------------------------------------------------------------
-- 8. RECREATE TRIGGERS
-- -----------------------------------------------------------------------------

-- Reviews triggers
DROP TRIGGER IF EXISTS update_rating_on_review_insert ON public.reviews;
CREATE TRIGGER update_rating_on_review_insert
    AFTER INSERT ON public.reviews
    FOR EACH ROW
    EXECUTE FUNCTION public.update_business_rating();

DROP TRIGGER IF EXISTS update_rating_on_review_update ON public.reviews;
CREATE TRIGGER update_rating_on_review_update
    AFTER UPDATE ON public.reviews
    FOR EACH ROW
    EXECUTE FUNCTION public.update_business_rating();

DROP TRIGGER IF EXISTS update_rating_on_review_delete ON public.reviews;
CREATE TRIGGER update_rating_on_review_delete
    AFTER DELETE ON public.reviews
    FOR EACH ROW
    EXECUTE FUNCTION public.update_business_rating();

-- Messages trigger
DROP TRIGGER IF EXISTS update_chat_on_message ON public.messages;
CREATE TRIGGER update_chat_on_message
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.update_chat_last_message();

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
