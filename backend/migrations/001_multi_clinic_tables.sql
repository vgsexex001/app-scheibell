-- =====================================================
-- MIGRAÇÃO MULTI-CLÍNICA - FASE 1: CRIAR TABELAS
-- Execute este script no Supabase SQL Editor
-- =====================================================

-- 1. Tabela de Associação Paciente ↔ Clínica
-- Permite que um paciente esteja vinculado a múltiplas clínicas
CREATE TABLE IF NOT EXISTS patient_clinic_associations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Relacionamentos
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,

  -- Dados específicos desta associação (cirurgia nesta clínica)
  surgery_date TIMESTAMP,
  surgery_type VARCHAR(255),
  surgeon VARCHAR(255),

  -- Controle de status
  status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'TRANSFERRED')),
  is_primary BOOLEAN DEFAULT false,  -- Clínica principal atual

  -- Histórico de transferência
  transferred_from_clinic_id UUID REFERENCES clinics(id),
  transfer_reason TEXT,
  transferred_at TIMESTAMP,

  -- Auditoria
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  created_by UUID REFERENCES users(id),

  -- Constraints
  UNIQUE(patient_id, clinic_id)
);

-- Índices para performance
CREATE INDEX idx_pca_patient ON patient_clinic_associations(patient_id);
CREATE INDEX idx_pca_clinic ON patient_clinic_associations(clinic_id);
CREATE INDEX idx_pca_status ON patient_clinic_associations(status);
CREATE INDEX idx_pca_primary ON patient_clinic_associations(patient_id, is_primary) WHERE is_primary = true;

-- 2. Tabela de Associação Usuário ↔ Clínica (para staff multi-clínica)
CREATE TABLE IF NOT EXISTS user_clinic_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Relacionamentos
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,

  -- Role específica nesta clínica
  role VARCHAR(20) NOT NULL CHECK (role IN ('CLINIC_ADMIN', 'CLINIC_STAFF', 'VIEWER')),

  -- Permissões granulares (JSON array de strings)
  permissions JSONB DEFAULT '[]'::jsonb,

  -- Controle de status
  is_active BOOLEAN DEFAULT true,
  is_default BOOLEAN DEFAULT false,  -- Clínica default ao fazer login

  -- Auditoria
  started_at TIMESTAMP DEFAULT NOW(),
  ended_at TIMESTAMP,  -- NULL = ainda ativo
  created_by UUID REFERENCES users(id),

  -- Constraints
  UNIQUE(user_id, clinic_id)
);

-- Índices para performance
CREATE INDEX idx_uca_user ON user_clinic_assignments(user_id);
CREATE INDEX idx_uca_clinic ON user_clinic_assignments(clinic_id);
CREATE INDEX idx_uca_active ON user_clinic_assignments(user_id, is_active) WHERE is_active = true;
CREATE INDEX idx_uca_default ON user_clinic_assignments(user_id, is_default) WHERE is_default = true;

-- 3. Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_pca_updated_at
  BEFORE UPDATE ON patient_clinic_associations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- 4. Função para garantir apenas uma clínica primária por paciente
CREATE OR REPLACE FUNCTION ensure_single_primary_clinic()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_primary = true THEN
    -- Remover is_primary de outras associações do mesmo paciente
    UPDATE patient_clinic_associations
    SET is_primary = false
    WHERE patient_id = NEW.patient_id
      AND id != NEW.id
      AND is_primary = true;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ensure_single_primary
  BEFORE INSERT OR UPDATE ON patient_clinic_associations
  FOR EACH ROW
  WHEN (NEW.is_primary = true)
  EXECUTE FUNCTION ensure_single_primary_clinic();

-- 5. Função para garantir apenas uma clínica default por usuário
CREATE OR REPLACE FUNCTION ensure_single_default_clinic()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_default = true THEN
    UPDATE user_clinic_assignments
    SET is_default = false
    WHERE user_id = NEW.user_id
      AND id != NEW.id
      AND is_default = true;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ensure_single_default
  BEFORE INSERT OR UPDATE ON user_clinic_assignments
  FOR EACH ROW
  WHEN (NEW.is_default = true)
  EXECUTE FUNCTION ensure_single_default_clinic();

-- =====================================================
-- COMENTÁRIOS EXPLICATIVOS
-- =====================================================
COMMENT ON TABLE patient_clinic_associations IS 'Associação N:N entre pacientes e clínicas. Permite paciente em múltiplas clínicas com dados específicos por clínica.';
COMMENT ON COLUMN patient_clinic_associations.is_primary IS 'Indica a clínica principal/atual do paciente. Apenas uma pode ser true por paciente.';
COMMENT ON COLUMN patient_clinic_associations.status IS 'ACTIVE=ativo, INACTIVE=inativo, TRANSFERRED=transferido para outra clínica';

COMMENT ON TABLE user_clinic_assignments IS 'Associação N:N entre usuários staff e clínicas. Permite médicos/admins em múltiplas clínicas.';
COMMENT ON COLUMN user_clinic_assignments.is_default IS 'Clínica selecionada automaticamente ao fazer login. Apenas uma pode ser true por usuário.';
COMMENT ON COLUMN user_clinic_assignments.permissions IS 'Array JSON de permissões granulares: ["VIEW_PATIENTS", "EDIT_PATIENTS", "VIEW_APPOINTMENTS", etc]';
