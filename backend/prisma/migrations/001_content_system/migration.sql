-- CreateEnum
CREATE TYPE "ContentType" AS ENUM ('SYMPTOMS', 'DIET', 'ACTIVITIES', 'CARE', 'TRAINING', 'EXAMS', 'DOCUMENTS', 'MEDICATIONS', 'DIARY');

-- CreateEnum
CREATE TYPE "ContentCategory" AS ENUM ('NORMAL', 'WARNING', 'EMERGENCY', 'ALLOWED', 'RESTRICTED', 'PROHIBITED', 'INFO');

-- CreateEnum
CREATE TYPE "AdjustmentType" AS ENUM ('ADD', 'DISABLE', 'MODIFY');

-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('PATIENT', 'CLINIC_ADMIN', 'CLINIC_STAFF', 'THIRD_PARTY');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "role" "UserRole" NOT NULL DEFAULT 'PATIENT',
    "clinic_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "clinics" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "email" TEXT,
    "phone" TEXT,
    "address" TEXT,
    "logo_url" TEXT,
    "primary_color" TEXT DEFAULT '#4F4A34',
    "secondary_color" TEXT DEFAULT '#A49E86',
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "clinics_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "patients" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "clinic_id" TEXT NOT NULL,
    "cpf" TEXT,
    "phone" TEXT,
    "birth_date" TIMESTAMP(3),
    "surgery_date" TIMESTAMP(3),
    "surgery_type" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "patients_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "system_content_templates" (
    "id" TEXT NOT NULL,
    "type" "ContentType" NOT NULL,
    "category" "ContentCategory" NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "valid_from_day" INTEGER,
    "valid_until_day" INTEGER,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "system_content_templates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "clinic_contents" (
    "id" TEXT NOT NULL,
    "clinic_id" TEXT NOT NULL,
    "template_id" TEXT,
    "type" "ContentType" NOT NULL,
    "category" "ContentCategory" NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "valid_from_day" INTEGER,
    "valid_until_day" INTEGER,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "is_custom" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "clinic_contents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "patient_content_adjustments" (
    "id" TEXT NOT NULL,
    "patient_id" TEXT NOT NULL,
    "base_content_id" TEXT,
    "adjustment_type" "AdjustmentType" NOT NULL,
    "content_type" "ContentType",
    "category" "ContentCategory",
    "title" TEXT,
    "description" TEXT,
    "valid_from_day" INTEGER,
    "valid_until_day" INTEGER,
    "reason" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_by" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "patient_content_adjustments_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "patients_user_id_key" ON "patients"("user_id");

-- CreateIndex
CREATE INDEX "system_content_templates_type_idx" ON "system_content_templates"("type");

-- CreateIndex
CREATE INDEX "system_content_templates_type_category_idx" ON "system_content_templates"("type", "category");

-- CreateIndex
CREATE INDEX "clinic_contents_clinic_id_idx" ON "clinic_contents"("clinic_id");

-- CreateIndex
CREATE INDEX "clinic_contents_clinic_id_type_idx" ON "clinic_contents"("clinic_id", "type");

-- CreateIndex
CREATE INDEX "clinic_contents_clinic_id_type_category_idx" ON "clinic_contents"("clinic_id", "type", "category");

-- CreateIndex
CREATE INDEX "clinic_contents_clinic_id_type_is_active_idx" ON "clinic_contents"("clinic_id", "type", "is_active");

-- CreateIndex
CREATE INDEX "patient_content_adjustments_patient_id_idx" ON "patient_content_adjustments"("patient_id");

-- CreateIndex
CREATE INDEX "patient_content_adjustments_base_content_id_idx" ON "patient_content_adjustments"("base_content_id");

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "clinics"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patients" ADD CONSTRAINT "patients_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patients" ADD CONSTRAINT "patients_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "clinics"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "clinic_contents" ADD CONSTRAINT "clinic_contents_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "clinics"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_content_adjustments" ADD CONSTRAINT "patient_content_adjustments_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "patients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_content_adjustments" ADD CONSTRAINT "patient_content_adjustments_base_content_id_fkey" FOREIGN KEY ("base_content_id") REFERENCES "clinic_contents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- ==================== TRIGGER: Copiar templates para nova clínica ====================

-- Função para copiar templates quando nova clínica é criada
CREATE OR REPLACE FUNCTION copy_templates_to_new_clinic()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO clinic_contents (
    id,
    clinic_id,
    template_id,
    type,
    category,
    title,
    description,
    valid_from_day,
    valid_until_day,
    sort_order,
    is_active,
    is_custom,
    created_at,
    updated_at
  )
  SELECT
    gen_random_uuid(),
    NEW.id,
    sct.id,
    sct.type,
    sct.category,
    sct.title,
    sct.description,
    sct.valid_from_day,
    sct.valid_until_day,
    sct.sort_order,
    true,
    false,
    NOW(),
    NOW()
  FROM system_content_templates sct
  WHERE sct.is_active = true;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger que executa a função
DROP TRIGGER IF EXISTS trigger_copy_templates_on_clinic_create ON clinics;
CREATE TRIGGER trigger_copy_templates_on_clinic_create
  AFTER INSERT ON clinics
  FOR EACH ROW
  EXECUTE FUNCTION copy_templates_to_new_clinic();
