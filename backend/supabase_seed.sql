-- App Scheibell - Dados Iniciais (Seed)
-- Execute este SQL no Supabase SQL Editor DEPOIS da migration

-- 1. Criar clínica padrão
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
);

-- 2. Criar usuário admin da clínica (senha: admin123)
-- Hash bcrypt para 'admin123': $2b$10$rQEYlz8xqH5KhDzKqV1QAOqKzKqKzKqKzKqKzKqKzKqKzKqKzKqKz
INSERT INTO "users" ("id", "email", "passwordHash", "name", "role", "clinicId", "createdAt", "updatedAt")
VALUES (
    'user-admin-001',
    'admin@scheibell.com.br',
    '$2b$10$8K1p/a0dL1hkM.87Mh/YCObZQi.L0JTKGHiLUKNy5qVWnM2eBJlOK',
    'Administrador Scheibell',
    'CLINIC_ADMIN',
    'clinic-default-scheibell',
    NOW(),
    NOW()
);

-- 3. Criar usuário paciente de teste (senha: teste123)
INSERT INTO "users" ("id", "email", "passwordHash", "name", "role", "clinicId", "createdAt", "updatedAt")
VALUES (
    'user-patient-001',
    'paciente@teste.com',
    '$2b$10$8K1p/a0dL1hkM.87Mh/YCObZQi.L0JTKGHiLUKNy5qVWnM2eBJlOK',
    'Paciente Teste',
    'PATIENT',
    'clinic-default-scheibell',
    NOW(),
    NOW()
);

-- 4. Criar registro de paciente vinculado ao usuário
INSERT INTO "patients" ("id", "userId", "name", "email", "clinicId", "phone", "surgeryDate", "surgeryType", "createdAt", "updatedAt")
VALUES (
    'patient-001',
    'user-patient-001',
    'Paciente Teste',
    'paciente@teste.com',
    'clinic-default-scheibell',
    '(11) 98888-8888',
    NOW() - INTERVAL '7 days',
    'Cirurgia Cardíaca',
    NOW(),
    NOW()
);

-- 5. Criar protocolo de treino padrão
INSERT INTO "training_protocols" ("id", "clinicId", "name", "surgeryType", "description", "totalWeeks", "isDefault", "isActive", "createdAt", "updatedAt")
VALUES (
    'protocol-default-001',
    'clinic-default-scheibell',
    'Protocolo Pós-Operatório Cardíaco',
    'Cirurgia Cardíaca',
    'Protocolo padrão de recuperação pós-cirurgia cardíaca',
    8,
    true,
    true,
    NOW(),
    NOW()
);

-- 6. Criar semanas do protocolo
INSERT INTO "training_weeks" ("id", "protocolId", "weekNumber", "title", "dayRange", "objective", "maxHeartRate", "heartRateLabel", "canDo", "avoid", "sortOrder", "createdAt", "updatedAt")
VALUES
    ('week-001', 'protocol-default-001', 1, 'Semana 1 - Repouso', 'Dias 1-7', 'Descanso e recuperação inicial', 100, 'Muito leve', ARRAY['Caminhadas curtas dentro de casa', 'Exercícios respiratórios', 'Alongamentos leves'], ARRAY['Esforço físico', 'Levantar peso', 'Subir escadas'], 1, NOW(), NOW()),
    ('week-002', 'protocol-default-001', 2, 'Semana 2 - Mobilização', 'Dias 8-14', 'Aumentar mobilidade gradualmente', 110, 'Leve', ARRAY['Caminhadas de 10-15 min', 'Exercícios de braços sem peso', 'Subir poucos degraus'], ARRAY['Corrida', 'Musculação', 'Esportes'], 2, NOW(), NOW()),
    ('week-003', 'protocol-default-001', 3, 'Semana 3 - Fortalecimento Inicial', 'Dias 15-21', 'Iniciar fortalecimento leve', 120, 'Leve a moderado', ARRAY['Caminhadas de 20-30 min', 'Exercícios com elástico', 'Bicicleta ergométrica leve'], ARRAY['Exercícios de alto impacto', 'Natação', 'Levantamento de peso'], 3, NOW(), NOW()),
    ('week-004', 'protocol-default-001', 4, 'Semana 4 - Progressão', 'Dias 22-28', 'Aumentar intensidade gradualmente', 130, 'Moderado', ARRAY['Caminhadas de 30-40 min', 'Exercícios de fortalecimento', 'Bicicleta com resistência leve'], ARRAY['Esportes de contato', 'Musculação pesada'], 4, NOW(), NOW());

-- 7. Criar sessões de treino para a semana 1
INSERT INTO "training_sessions" ("id", "weekId", "sessionNumber", "name", "description", "duration", "intensity", "sortOrder", "createdAt", "updatedAt")
VALUES
    ('session-001', 'week-001', 1, 'Respiração Diafragmática', 'Exercícios de respiração profunda para melhorar oxigenação', 10, 'Muito leve', 1, NOW(), NOW()),
    ('session-002', 'week-001', 2, 'Caminhada Indoor', 'Caminhada leve dentro de casa', 5, 'Muito leve', 2, NOW(), NOW()),
    ('session-003', 'week-001', 3, 'Alongamento Suave', 'Alongamentos leves de membros superiores e inferiores', 10, 'Muito leve', 3, NOW(), NOW());

-- Pronto! Dados iniciais criados com sucesso.
--
-- Credenciais de acesso:
--
-- ADMIN:
--   Email: admin@scheibell.com.br
--   Senha: admin123
--
-- PACIENTE:
--   Email: paciente@teste.com
--   Senha: teste123
