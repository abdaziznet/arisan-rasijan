-- Fix: Make member_id nullable in donations table for anonymous donations
-- This addresses the NOT NULL constraint violation when inserting anonymous donations

ALTER TABLE public.donations
ALTER COLUMN member_id DROP NOT NULL;

-- Verify the change
-- \d public.donations