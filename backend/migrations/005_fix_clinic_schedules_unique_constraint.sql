-- =====================================================
-- MIGRAÇÃO 005: Corrigir unique constraint em clinic_schedules
--               para incluir appointmentTypeId
-- Execute este script no Supabase SQL Editor
-- =====================================================
-- PROBLEMA: O unique constraint antigo era (clinicId, dayOfWeek, appointmentType)
-- Quando criamos schedules com appointmentTypeId (tipo personalizado),
-- o appointmentType fica NULL, conflitando com o schedule "geral" (também NULL).
-- SOLUÇÃO: Incluir appointmentTypeId no unique constraint.
-- =====================================================

-- 1. Remover o unique constraint antigo
DROP INDEX IF EXISTS "clinic_schedules_clinicId_dayOfWeek_appointmentType_key";

-- 2. Criar o novo unique constraint incluindo appointmentTypeId
CREATE UNIQUE INDEX IF NOT EXISTS "clinic_schedules_clinicId_dayOfWeek_appointmentType_appointmen_key"
    ON clinic_schedules ("clinicId", "dayOfWeek", "appointmentType", "appointmentTypeId");

-- 3. Verificação
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'clinic_schedules'
AND indexname LIKE '%unique%' OR indexname LIKE '%key%'
ORDER BY indexname;
