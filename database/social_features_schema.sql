-- ==========================================
-- iFind Social Features Schema
-- Comments and Likes for Portfolio Items
-- ==========================================

-- 1. Comments Table
CREATE TABLE IF NOT EXISTS public.media_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    portfolio_item_id UUID NOT NULL REFERENCES public.portfolio_items(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    comment TEXT NOT NULL CHECK (char_length(comment) > 0 AND char_length(comment) <= 500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Likes Table
CREATE TABLE IF NOT EXISTS public.media_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    portfolio_item_id UUID NOT NULL REFERENCES public.portfolio_items(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_user_like_per_item UNIQUE(portfolio_item_id, user_id)
);

-- 3. Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_comments_portfolio_item 
    ON public.media_comments(portfolio_item_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_comments_user 
    ON public.media_comments(user_id);

CREATE INDEX IF NOT EXISTS idx_likes_portfolio_item 
    ON public.media_likes(portfolio_item_id);

CREATE INDEX IF NOT EXISTS idx_likes_user 
    ON public.media_likes(user_id);

-- 4. RLS Policies for Comments
ALTER TABLE public.media_comments ENABLE ROW LEVEL SECURITY;

-- Everyone can view comments
CREATE POLICY "Public can view comments"
    ON public.media_comments FOR SELECT
    USING (TRUE);

-- Authenticated users can create comments
CREATE POLICY "Authenticated users can create comments"
    ON public.media_comments FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own comments
CREATE POLICY "Users can delete own comments"
    ON public.media_comments FOR DELETE
    USING (auth.uid() = user_id);

-- 5. RLS Policies for Likes
ALTER TABLE public.media_likes ENABLE ROW LEVEL SECURITY;

-- Everyone can view likes
CREATE POLICY "Public can view likes"
    ON public.media_likes FOR SELECT
    USING (TRUE);

-- Authenticated users can create likes
CREATE POLICY "Authenticated users can create likes"
    ON public.media_likes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own likes (unlike)
CREATE POLICY "Users can delete own likes"
    ON public.media_likes FOR DELETE
    USING (auth.uid() = user_id);
