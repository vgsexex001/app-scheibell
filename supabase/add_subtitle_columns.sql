-- Adicionar colunas de legendas na tabela clinic_videos
-- Execute este script no Supabase Dashboard > SQL Editor

ALTER TABLE clinic_videos
ADD COLUMN IF NOT EXISTS "subtitleStatus" text DEFAULT 'PENDING',
ADD COLUMN IF NOT EXISTS "subtitleUrl" text,
ADD COLUMN IF NOT EXISTS "subtitleError" text,
ADD COLUMN IF NOT EXISTS "subtitleLanguage" text DEFAULT 'pt';

-- Atualizar o vídeo existente para ter status PENDING
UPDATE clinic_videos SET "subtitleStatus" = 'PENDING' WHERE "subtitleStatus" IS NULL;
