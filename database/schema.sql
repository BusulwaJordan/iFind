-- iFind Database Schema
-- PostgreSQL + Supabase
-- Designed for scalability and RLS security

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    role TEXT NOT NULL CHECK (role IN ('customer', 'business_owner', 'manager')),
    full_name TEXT NOT NULL,
    phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies for users
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
    ON users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- ============================================
-- BUSINESSES TABLE
-- ============================================
CREATE TABLE businesses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    address TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    is_arcade BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT FALSE,
    verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected')),
    rating_average NUMERIC(2,1) DEFAULT 0 CHECK (rating_average >= 0 AND rating_average <= 5),
    rating_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_businesses_owner ON businesses(owner_id);
CREATE INDEX idx_businesses_category ON businesses(category);
CREATE INDEX idx_businesses_location ON businesses USING GIST(location);
CREATE INDEX idx_businesses_verified ON businesses(is_verified) WHERE is_verified = TRUE;

-- RLS Policies for businesses
ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view verified businesses"
    ON businesses FOR SELECT
    USING (is_verified = TRUE);

CREATE POLICY "Owners can view own businesses"
    ON businesses FOR SELECT
    USING (auth.uid() = owner_id);

CREATE POLICY "Owners can manage own businesses"
    ON businesses FOR ALL
    USING (auth.uid() = owner_id);

-- ============================================
-- ARCADES TABLE
-- ============================================
CREATE TABLE arcades (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE UNIQUE,
    max_shops INTEGER DEFAULT 50,
    current_shops INTEGER DEFAULT 0,
    policies JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE arcades ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view arcades"
    ON arcades FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM businesses
            WHERE id = arcades.business_id
            AND is_verified = TRUE
        )
    );

CREATE POLICY "Owners can manage arcades"
    ON arcades FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM businesses
            WHERE id = arcades.business_id
            AND owner_id = auth.uid()
        )
    );

-- ============================================
-- SHOPS TABLE
-- ============================================
CREATE TABLE shops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    arcade_id UUID NOT NULL REFERENCES arcades(id) ON DELETE CASCADE,
    manager_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_shops_arcade ON shops(arcade_id);
CREATE INDEX idx_shops_manager ON shops(manager_id);

ALTER TABLE shops ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view active shops"
    ON shops FOR SELECT
    USING (is_active = TRUE);

CREATE POLICY "Managers can manage own shops"
    ON shops FOR ALL
    USING (auth.uid() = manager_id);

CREATE POLICY "Arcade owners can manage shops"
    ON shops FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM arcades a
            JOIN businesses b ON a.business_id = b.id
            WHERE a.id = shops.arcade_id
            AND b.owner_id = auth.uid()
        )
    );

-- ============================================
-- PRODUCTS TABLE
-- ============================================
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    images TEXT[] DEFAULT '{}',
    stock_quantity INTEGER DEFAULT 0 CHECK (stock_quantity >= 0),
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CHECK (
        (shop_id IS NOT NULL AND business_id IS NULL) OR
        (shop_id IS NULL AND business_id IS NOT NULL)
    )
);

CREATE INDEX idx_products_shop ON products(shop_id);
CREATE INDEX idx_products_business ON products(business_id);
CREATE INDEX idx_products_available ON products(is_available) WHERE is_available = TRUE;

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view available products"
    ON products FOR SELECT
    USING (is_available = TRUE);

CREATE POLICY "Business owners can manage products"
    ON products FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM businesses
            WHERE id = products.business_id
            AND owner_id = auth.uid()
        )
    );

CREATE POLICY "Shop managers can manage products"
    ON products FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM shops
            WHERE id = products.shop_id
            AND manager_id = auth.uid()
        )
    );

-- ============================================
-- CHATS TABLE
-- ============================================
CREATE TABLE chats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    last_message TEXT,
    last_message_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(customer_id, business_id)
);

CREATE INDEX idx_chats_customer ON chats(customer_id);
CREATE INDEX idx_chats_business ON chats(business_id);

ALTER TABLE chats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can access own chats"
    ON chats FOR ALL
    USING (
        auth.uid() = customer_id
        OR
        EXISTS (
            SELECT 1 FROM businesses
            WHERE id = chats.business_id
            AND owner_id = auth.uid()
        )
    );

-- ============================================
-- MESSAGES TABLE
-- ============================================
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_messages_chat ON messages(chat_id, created_at DESC);

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can access messages in their chats"
    ON messages FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM chats
            WHERE id = messages.chat_id
            AND (
                customer_id = auth.uid()
                OR
                EXISTS (
                    SELECT 1 FROM businesses
                    WHERE id = chats.business_id
                    AND owner_id = auth.uid()
                )
            )
        )
    );

-- ============================================
-- REVIEWS TABLE
-- ============================================
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(business_id, customer_id)
);

CREATE INDEX idx_reviews_business ON reviews(business_id);

ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view reviews"
    ON reviews FOR SELECT
    USING (TRUE);

CREATE POLICY "Customers can create reviews"
    ON reviews FOR INSERT
    WITH CHECK (
        auth.uid() = customer_id
        AND
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid()
            AND role = 'customer'
        )
    );

CREATE POLICY "Customers can update own reviews"
    ON reviews FOR UPDATE
    USING (auth.uid() = customer_id);

CREATE POLICY "Customers can delete own reviews"
    ON reviews FOR DELETE
    USING (auth.uid() = customer_id);

-- ============================================
-- RECOMMENDATIONS TABLE
-- ============================================
CREATE TABLE recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    score NUMERIC(5,4) DEFAULT 0,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_recommendations_user ON recommendations(user_id, score DESC);

ALTER TABLE recommendations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own recommendations"
    ON recommendations FOR SELECT
    USING (auth.uid() = user_id);

-- ============================================
-- TRIGGERS
-- ============================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_businesses_updated_at
    BEFORE UPDATE ON businesses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shops_updated_at
    BEFORE UPDATE ON shops
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Update business ratings on review insert/update/delete
CREATE OR REPLACE FUNCTION update_business_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE businesses
    SET 
        rating_average = (
            SELECT COALESCE(AVG(rating), 0)
            FROM reviews
            WHERE business_id = COALESCE(NEW.business_id, OLD.business_id)
        ),
        rating_count = (
            SELECT COUNT(*)
            FROM reviews
            WHERE business_id = COALESCE(NEW.business_id, OLD.business_id)
        )
    WHERE id = COALESCE(NEW.business_id, OLD.business_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_rating_on_review_insert
    AFTER INSERT ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_business_rating();

CREATE TRIGGER update_rating_on_review_update
    AFTER UPDATE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_business_rating();

CREATE TRIGGER update_rating_on_review_delete
    AFTER DELETE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_business_rating();

-- Update chat last_message on message insert
CREATE OR REPLACE FUNCTION update_chat_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE chats
    SET 
        last_message = NEW.content,
        last_message_at = NEW.created_at
    WHERE id = NEW.chat_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_chat_on_message
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_chat_last_message();

-- Update arcade current_shops count
CREATE OR REPLACE FUNCTION update_arcade_shop_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE arcades
        SET current_shops = current_shops + 1
        WHERE id = NEW.arcade_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE arcades
        SET current_shops = current_shops - 1
        WHERE id = OLD.arcade_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_shop_count_on_insert
    AFTER INSERT ON shops
    FOR EACH ROW
    EXECUTE FUNCTION update_arcade_shop_count();

-- ============================================
-- AUTH HOOKS (Trigger to create user profile)
-- ============================================

-- Function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, role, full_name, phone)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'customer'),
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
    NEW.raw_user_meta_data->>'phone'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger execution
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
