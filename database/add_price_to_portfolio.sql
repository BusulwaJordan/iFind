-- Migration: Add price to portfolio items
-- This enables shop owners to attach a price tag to gallery items

ALTER TABLE public.portfolio_items 
ADD COLUMN IF NOT EXISTS price NUMERIC(15,2);

-- Note: We use NUMERIC(15,2) to handle large amounts like UGX comfortably
