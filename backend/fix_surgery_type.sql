-- =====================================================
-- FIX: Corrigir tipo de cirurgia de "Cirurgia Cardíaca" para "Rinoplastia"
-- Execute este SQL no Supabase SQL Editor
-- Data: 2026-01-12
-- =====================================================

-- 1. Atualizar todos os pacientes que têm "Cirurgia Cardíaca"
UPDATE "patients"
SET
    "surgeryType" = 'Rinoplastia',
    "updatedAt" = NOW()
WHERE "surgeryType" = 'Cirurgia Cardíaca';

-- 2. Atualizar protocolos de treino
UPDATE "training_protocols"
SET
    "surgeryType" = 'Rinoplastia',
    "name" = 'Protocolo Pós-Operatório Rinoplastia',
    "description" = 'Protocolo padrão de recuperação pós-rinoplastia',
    "updatedAt" = NOW()
WHERE "surgeryType" = 'Cirurgia Cardíaca';

-- 3. Verificar resultado
SELECT id, name, "surgeryType" FROM "patients" WHERE id = 'patient-001';
SELECT id, name, "surgeryType" FROM "training_protocols" WHERE id = 'protocol-default-001';

-- =====================================================
-- Resultado esperado:
-- patients: surgeryType = 'Rinoplastia'
-- training_protocols: surgeryType = 'Rinoplastia'
-- =====================================================
