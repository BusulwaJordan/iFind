-- ==========================================
-- iFind Social Features Migration
-- Gallery Likes & Comments
-- ==========================================

-- 1. Gallery Likes
CREATE TABLE IF NOT EXISTS public.portfolio_likes (
  id UUID NOT NULL DEFAULT gen_random_uuid(),
  portfolio_item_id UUID NOT NULL REFERENCES public.portfolio_items(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT portfolio_likes_pkey PRIMARY KEY (id),
  UNIQUE(portfolio_item_id, user_id)
);

-- 2. Gallery Comments
CREATE TABLE IF NOT EXISTS public.portfolio_comments (
  id UUID NOT NULL DEFAULT gen_random_uuid(),
  portfolio_item_id UUID NOT NULL REFERENCES public.portfolio_items(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  comment TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT portfolio_comments_pkey PRIMARY KEY (id)
);

-- 3. RLS Policies
ALTER TABLE public.portfolio_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.portfolio_comments ENABLE ROW LEVEL SECURITY;

-- Likes Policies
DROP POLICY IF EXISTS "Public can view likes" ON public.portfolio_likes;
CREATE POLICY "Public can view likes" ON public.portfolio_likes FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Users can like portfolio items" ON public.portfolio_likes;
CREATE POLICY "Users can like portfolio items" ON public.portfolio_likes FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can unlike portfolio items" ON public.portfolio_likes;
CREATE POLICY "Users can unlike portfolio items" ON public.portfolio_likes FOR DELETE USING (auth.uid() = user_id);

-- Comments Policies
DROP POLICY IF EXISTS "Public can view comments" ON public.portfolio_comments;
CREATE POLICY "Public can view comments" ON public.portfolio_comments FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Users can comment on portfolio items" ON public.portfolio_comments;
CREATE POLICY "Users can comment on portfolio items" ON public.portfolio_comments FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own comments" ON public.portfolio_comments;
CREATE POLICY "Users can manage own comments" ON public.portfolio_comments FOR ALL USING (auth.uid() = user_id);
