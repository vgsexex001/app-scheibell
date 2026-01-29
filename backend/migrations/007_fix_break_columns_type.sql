-- =====================================================
-- MIGRAÇÃO 007: Corrigir colunas breakStart/breakEnd
--
-- PROBLEMA: O banco tem breakStart/breakEnd como tipo TIME
-- mas o Prisma schema espera String (TEXT).
-- Erro: "Error converting field breakEnd of expected
-- non-nullable type String, found incompatible value
-- of 1970-01-01 14:00:00 +00:00"
--
-- SOLUÇÃO: Criar colunas temporárias TEXT, copiar dados
-- convertidos, dropar colunas TIME, renomear.
--
-- Execute este script no Supabase SQL Editor
-- =====================================================

-- 1. Verificar estrutura atual
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'clinic_schedules'
  AND column_name IN ('breakStart', 'breakEnd')
ORDER BY ordinal_position;

-- 2. Verificar dados atuais
SELECT id, "dayOfWeek", "breakStart", "breakEnd"
FROM clinic_schedules
WHERE "breakStart" IS NOT NULL OR "breakEnd" IS NOT NULL;

-- 3. Adicionar colunas temporárias TEXT
ALTER TABLE clinic_schedules ADD COLUMN IF NOT EXISTS "breakStart_text" TEXT;
ALTER TABLE clinic_schedules ADD COLUMN IF NOT EXISTS "breakEnd_text" TEXT;

-- 4. Copiar dados convertendo TIME para texto HH:MM
UPDATE clinic_schedules
SET "breakStart_text" = TO_CHAR("breakStart"::time, 'HH24:MI')
WHERE "breakStart" IS NOT NULL;

UPDATE clinic_schedules
SET "breakEnd_text" = TO_CHAR("breakEnd"::time, 'HH24:MI')
WHERE "breakEnd" IS NOT NULL;

-- 5. Dropar colunas TIME antigas
ALTER TABLE clinic_schedules DROP COLUMN IF EXISTS "breakStart";
ALTER TABLE clinic_schedules DROP COLUMN IF EXISTS "breakEnd";

-- 6. Renomear colunas TEXT para os nomes originais
ALTER TABLE clinic_schedules RENAME COLUMN "breakStart_text" TO "breakStart";
ALTER TABLE clinic_schedules RENAME COLUMN "breakEnd_text" TO "breakEnd";

-- 7. Verificação final
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'clinic_schedules'
  AND column_name IN ('breakStart', 'breakEnd')
ORDER BY ordinal_position;

-- 8. Mostrar dados para confirmar conversão
SELECT id, "dayOfWeek", "breakStart", "breakEnd", "openTime", "closeTime", "isActive"
FROM clinic_schedules
ORDER BY "dayOfWeek";
