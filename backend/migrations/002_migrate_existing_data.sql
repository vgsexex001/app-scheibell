-- =====================================================
-- MIGRAÇÃO MULTI-CLÍNICA - FASE 2: MIGRAR DADOS EXISTENTES
-- Execute este script APÓS o 001_multi_clinic_tables.sql
-- =====================================================

-- 1. Migrar Pacientes existentes para patient_clinic_associations
-- Cada paciente existente terá uma associação com sua clínica atual
INSERT INTO patient_clinic_associations (
  patient_id,
  clinic_id,
  surgery_date,
  surgery_type,
  surgeon,
  status,
  is_primary,
  created_at
)
SELECT
  p.id as patient_id,
  p.clinic_id as clinic_id,
  p."surgeryDate" as surgery_date,
  p."surgeryType" as surgery_type,
  p.surgeon as surgeon,
  'ACTIVE' as status,
  true as is_primary,  -- Clínica atual é a primária
  p."createdAt" as created_at
FROM patients p
WHERE p.clinic_id IS NOT NULL
  AND p."deletedAt" IS NULL
  AND NOT EXISTS (
    -- Evitar duplicatas se executar novamente
    SELECT 1 FROM patient_clinic_associations pca
    WHERE pca.patient_id = p.id AND pca.clinic_id = p.clinic_id
  );

-- 2. Migrar Staff/Admin existentes para user_clinic_assignments
INSERT INTO user_clinic_assignments (
  user_id,
  clinic_id,
  role,
  is_active,
  is_default,
  started_at
)
SELECT
  u.id as user_id,
  u.clinic_id as clinic_id,
  u.role as role,
  true as is_active,
  true as is_default,  -- Clínica atual é a default
  u."createdAt" as started_at
FROM users u
WHERE u.clinic_id IS NOT NULL
  AND u.role IN ('CLINIC_ADMIN', 'CLINIC_STAFF')
  AND u."deletedAt" IS NULL
  AND NOT EXISTS (
    -- Evitar duplicatas se executar novamente
    SELECT 1 FROM user_clinic_assignments uca
    WHERE uca.user_id = u.id AND uca.clinic_id = u.clinic_id
  );

-- 3. Verificar migração
SELECT 'Pacientes migrados:' as info, COUNT(*) as total FROM patient_clinic_associations;
SELECT 'Staff migrados:' as info, COUNT(*) as total FROM user_clinic_assignments;

-- 4. Verificar integridade
SELECT 'Pacientes sem associação:' as info, COUNT(*) as total
FROM patients p
WHERE p.clinic_id IS NOT NULL
  AND p."deletedAt" IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM patient_clinic_associations pca
    WHERE pca.patient_id = p.id
  );

SELECT 'Staff sem associação:' as info, COUNT(*) as total
FROM users u
WHERE u.clinic_id IS NOT NULL
  AND u.role IN ('CLINIC_ADMIN', 'CLINIC_STAFF')
  AND u."deletedAt" IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM user_clinic_assignments uca
    WHERE uca.user_id = u.id
  );
