-- ==========================================
-- iFind Schema V3: Needs, Notifications & Portfolio
-- ==========================================

-- 1. Needs Table (The "Demand")
create table if not exists public.needs (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null, -- e.g. "I need a wedding cake"
  description text,
  category text not null, -- e.g. "food", "services"
  latitude double precision not null,
  longitude double precision not null,
  status text not null default 'active', -- active, fulfilled, expired
  created_at timestamptz not null default now(),
  
  constraint needs_pkey primary key (id)
);

-- 2. Business Notifications (The "Alerts")
create table if not exists public.notifications (
  id uuid not null default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  need_id uuid references public.needs(id) on delete set null,
  title text not null,
  body text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now(),
  
  constraint notifications_pkey primary key (id)
);

-- 3. Portfolio Items (The "Showcase")
create table if not exists public.portfolio_items (
  id uuid not null default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  media_type text not null, -- 'image' or 'video'
  media_url text not null,
  thumbnail_url text, -- for videos
  caption text,
  created_at timestamptz not null default now(),
  
  constraint portfolio_items_pkey primary key (id)
);

-- 4. Storage Buckets
insert into storage.buckets (id, name, public) 
values ('business_portfolios', 'business_portfolios', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public) 
values ('business_videos', 'business_videos', true)
on conflict (id) do nothing;

-- 5. RLS Policies

-- Needs: Users create, Everyone reads (for AI/Business matching)
alter table public.needs enable row level security;

create policy "Users can create their own needs" 
on public.needs for insert 
with check (auth.uid() = user_id);

create policy "Users can view their own needs" 
on public.needs for select 
using (auth.uid() = user_id);

create policy "Public/Businesses can view active needs" 
on public.needs for select 
using (status = 'active');

-- Notifications: Businesses view their own
alter table public.notifications enable row level security;

create policy "Businesses can view their notifications" 
on public.notifications for select 
using (
  exists (
    select 1 from public.businesses 
    where id = notifications.business_id 
    and owner_id = auth.uid()
  )
);

-- Portfolio: Business owners create, Everyone reads
alter table public.portfolio_items enable row level security;

create policy "Public can view portfolios" 
on public.portfolio_items for select 
using (true);

create policy "Business owners can manage their portfolio" 
on public.portfolio_items for all 
using (
  exists (
    select 1 from public.businesses 
    where id = portfolio_items.business_id 
    and owner_id = auth.uid()
  )
);

-- Storage Policies
-- Portfolios
create policy "Public Access Portfolios"
on storage.objects for select
using ( bucket_id = 'business_portfolios' );

create policy "Business Owners Upload Portfolios"
on storage.objects for insert
with check ( bucket_id = 'business_portfolios' and auth.role() = 'authenticated' );

-- Videos
create policy "Public Access Videos"
on storage.objects for select
using ( bucket_id = 'business_videos' );

create policy "Business Owners Upload Videos"
on storage.objects for insert
with check ( bucket_id = 'business_videos' and auth.role() = 'authenticated' );
