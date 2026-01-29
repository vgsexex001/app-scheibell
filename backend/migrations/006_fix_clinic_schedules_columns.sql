-- =====================================================
-- MIGRAÇÃO 006: Corrigir colunas da tabela clinic_schedules
--               O Prisma usa openTime/closeTime mas o banco pode ter
--               startTime/endTime que são NOT NULL
-- Execute este script no Supabase SQL Editor
-- =====================================================

-- 1. Verificar quais colunas existem
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'clinic_schedules'
ORDER BY ordinal_position;

-- 2. Se startTime existe e é NOT NULL, tornar nullable
ALTER TABLE clinic_schedules ALTER COLUMN "startTime" DROP NOT NULL;

-- 3. Se endTime existe e é NOT NULL, tornar nullable
ALTER TABLE clinic_schedules ALTER COLUMN "endTime" DROP NOT NULL;

-- 4. Garantir que openTime existe (caso não exista)
ALTER TABLE clinic_schedules ADD COLUMN IF NOT EXISTS "openTime" TEXT;

-- 5. Garantir que closeTime existe (caso não exista)
ALTER TABLE clinic_schedules ADD COLUMN IF NOT EXISTS "closeTime" TEXT;

-- 6. Copiar dados de startTime para openTime se openTime estiver vazio
UPDATE clinic_schedules
SET "openTime" = "startTime"
WHERE "openTime" IS NULL AND "startTime" IS NOT NULL;

-- 7. Copiar dados de endTime para closeTime se closeTime estiver vazio
UPDATE clinic_schedules
SET "closeTime" = "endTime"
WHERE "closeTime" IS NULL AND "endTime" IS NOT NULL;

-- 8. Verificação final
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'clinic_schedules'
ORDER BY ordinal_position;
