-- =====================================================
-- App Scheibell - Criar Usuários no Supabase
-- Execute este SQL no Supabase SQL Editor
-- =====================================================

-- 1. Criar clínica padrão (se não existir)
INSERT INTO "clinics" ("id", "name", "email", "phone", "address", "isActive", "createdAt", "updatedAt")
VALUES (
    'clinic-default-scheibell',
    'Clínica Scheibell',
    'contato@scheibell.com.br',
    '(11) 99999-9999',
    'São Paulo, SP',
    true,
    NOW(),
    NOW()
)
ON CONFLICT ("id") DO NOTHING;

-- 2. Criar usuário ADMIN (senha: 123456)
INSERT INTO "users" ("id", "email", "passwordHash", "name", "role", "clinicId", "createdAt", "updatedAt")
VALUES (
    'user-admin',
    'admin@teste.com',
    '$2b$10$nfuPBNGNy0rOd3hloKamSewkHiW47akqB8tg9JR8/PsSYs5r2jpfe',
    'Administrador',
    'CLINIC_ADMIN',
    'clinic-default-scheibell',
    NOW(),
    NOW()
)
ON CONFLICT ("email") DO UPDATE SET
    "passwordHash" = '$2b$10$nfuPBNGNy0rOd3hloKamSewkHiW47akqB8tg9JR8/PsSYs5r2jpfe',
    "updatedAt" = NOW();

-- 3. Criar usuário PACIENTE (senha: 123456)
INSERT INTO "users" ("id", "email", "passwordHash", "name", "role", "clinicId", "createdAt", "updatedAt")
VALUES (
    'user-paciente',
    'paciente@teste.com',
    '$2b$10$nfuPBNGNy0rOd3hloKamSewkHiW47akqB8tg9JR8/PsSYs5r2jpfe',
    'Paciente Teste',
    'PATIENT',
    'clinic-default-scheibell',
    NOW(),
    NOW()
)
ON CONFLICT ("email") DO UPDATE SET
    "passwordHash" = '$2b$10$nfuPBNGNy0rOd3hloKamSewkHiW47akqB8tg9JR8/PsSYs5r2jpfe',
    "updatedAt" = NOW();

-- 4. Criar registro de Patient vinculado ao usuário
INSERT INTO "patients" ("id", "userId", "clinicId", "surgeryDate", "surgeryType", "createdAt", "updatedAt")
VALUES (
    'patient-user-paciente',
    'user-paciente',
    'clinic-default-scheibell',
    NOW(),
    'RINOPLASTIA',
    NOW(),
    NOW()
)
ON CONFLICT ("userId") DO NOTHING;

-- =====================================================
-- CREDENCIAIS DE ACESSO:
-- =====================================================
--
-- ADMIN:
--   Email: admin@teste.com
--   Senha: 123456
--
-- PACIENTE:
--   Email: paciente@teste.com
--   Senha: 123456
--
-- =====================================================
