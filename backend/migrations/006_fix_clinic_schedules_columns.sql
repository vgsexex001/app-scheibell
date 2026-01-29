-- =====================================================
-- MIGRAÇÃO 006: Corrigir colunas da tabela clinic_schedules
--
-- PROBLEMA: O banco usa startTime/endTime (tipo TIME) mas o
-- Prisma schema espera openTime/closeTime (tipo TEXT/String).
--
-- SOLUÇÃO: Converter startTime/endTime de TIME para TEXT,
-- renomear para openTime/closeTime, e limpar dados.
--
-- Execute este script no Supabase SQL Editor
-- =====================================================

-- 1. Primeiro, verificar estrutura atual
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'clinic_schedules'
ORDER BY ordinal_position;

-- 2. Adicionar colunas openTime e closeTime como TEXT (se não existirem)
ALTER TABLE clinic_schedules ADD COLUMN IF NOT EXISTS "openTime" TEXT;
ALTER TABLE clinic_schedules ADD COLUMN IF NOT EXISTS "closeTime" TEXT;

-- 3. Copiar dados de startTime -> openTime (convertendo TIME para texto HH:MM)
UPDATE clinic_schedules
SET "openTime" = TO_CHAR("startTime", 'HH24:MI')
WHERE "startTime" IS NOT NULL AND ("openTime" IS NULL OR "openTime" = '');

-- 4. Copiar dados de endTime -> closeTime (convertendo TIME para texto HH:MM)
UPDATE clinic_schedules
SET "closeTime" = TO_CHAR("endTime", 'HH24:MI')
WHERE "endTime" IS NOT NULL AND ("closeTime" IS NULL OR "closeTime" = '');

-- 5. Definir valores padrão para registros que não têm nenhum dos dois
UPDATE clinic_schedules
SET "openTime" = '08:00'
WHERE "openTime" IS NULL;

UPDATE clinic_schedules
SET "closeTime" = '18:00'
WHERE "closeTime" IS NULL;

-- 6. Tornar openTime e closeTime NOT NULL
ALTER TABLE clinic_schedules ALTER COLUMN "openTime" SET NOT NULL;
ALTER TABLE clinic_schedules ALTER COLUMN "closeTime" SET NOT NULL;

-- 7. Tornar startTime e endTime nullable (para que o Prisma não precise mais deles)
ALTER TABLE clinic_schedules ALTER COLUMN "startTime" DROP NOT NULL;
ALTER TABLE clinic_schedules ALTER COLUMN "endTime" DROP NOT NULL;

-- 8. Verificação final
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'clinic_schedules'
ORDER BY ordinal_position;

-- 9. Mostrar dados atuais para confirmar
SELECT id, "dayOfWeek", "openTime", "closeTime", "startTime", "endTime", "isActive", "appointmentType", "appointmentTypeId"
FROM clinic_schedules
ORDER BY "dayOfWeek";
