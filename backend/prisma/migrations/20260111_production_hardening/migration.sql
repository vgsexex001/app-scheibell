-- Migration: Production Hardening
-- Adds: ExternalEvent, Job models, soft delete columns, missing indexes

-- ==================== ENUMS ====================

-- JobStatus enum
DO $$ BEGIN
    CREATE TYPE "JobStatus" AS ENUM ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- JobType enum
DO $$ BEGIN
    CREATE TYPE "JobType" AS ENUM ('CHAT_AI_REPLY', 'IMAGE_ANALYZE', 'NOTIFY_ADMIN', 'SEND_NOTIFICATION');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ==================== SOFT DELETE COLUMNS ====================

-- Users
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "deletedAt" TIMESTAMP(3);

-- Clinics
ALTER TABLE "clinics" ADD COLUMN IF NOT EXISTS "deletedAt" TIMESTAMP(3);

-- Patients
ALTER TABLE "patients" ADD COLUMN IF NOT EXISTS "deletedAt" TIMESTAMP(3);

-- Appointments
ALTER TABLE "appointments" ADD COLUMN IF NOT EXISTS "deletedAt" TIMESTAMP(3);

-- ==================== MISSING TIMESTAMPS ====================

-- PatientContentAdjustment.updatedAt
ALTER TABLE "patient_content_adjustments" ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP;

-- PatientContentState.createdAt
ALTER TABLE "patient_content_states" ADD COLUMN IF NOT EXISTS "createdAt" TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP;

-- ==================== NEW INDEXES ====================

-- Users indexes
CREATE INDEX IF NOT EXISTS "users_clinicId_idx" ON "users"("clinicId");
CREATE INDEX IF NOT EXISTS "users_role_idx" ON "users"("role");

-- Clinics indexes
CREATE INDEX IF NOT EXISTS "clinics_isActive_idx" ON "clinics"("isActive");

-- Patients indexes
CREATE INDEX IF NOT EXISTS "patients_clinicId_idx" ON "patients"("clinicId");
CREATE INDEX IF NOT EXISTS "patients_clinicId_surgeryType_idx" ON "patients"("clinicId", "surgeryType");

-- Appointments indexes
CREATE INDEX IF NOT EXISTS "appointments_status_idx" ON "appointments"("status");

-- Alerts indexes
CREATE INDEX IF NOT EXISTS "alerts_type_idx" ON "alerts"("type");
CREATE INDEX IF NOT EXISTS "alerts_createdAt_idx" ON "alerts"("createdAt");

-- Notifications indexes
CREATE INDEX IF NOT EXISTS "notifications_status_idx" ON "notifications"("status");
CREATE INDEX IF NOT EXISTS "notifications_createdAt_idx" ON "notifications"("createdAt");

-- ChatAttachments indexes
CREATE INDEX IF NOT EXISTS "chat_attachments_conversationId_status_idx" ON "chat_attachments"("conversationId", "status");

-- ==================== EXTERNAL EVENTS TABLE ====================

CREATE TABLE IF NOT EXISTS "external_events" (
    "id" TEXT NOT NULL,
    "patientId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,
    "time" TEXT NOT NULL,
    "location" TEXT,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "external_events_pkey" PRIMARY KEY ("id")
);

-- External Events indexes
CREATE INDEX IF NOT EXISTS "external_events_patientId_idx" ON "external_events"("patientId");
CREATE INDEX IF NOT EXISTS "external_events_patientId_date_idx" ON "external_events"("patientId", "date");

-- External Events foreign key
DO $$ BEGIN
    ALTER TABLE "external_events" ADD CONSTRAINT "external_events_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "patients"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ==================== JOBS TABLE ====================

CREATE TABLE IF NOT EXISTS "jobs" (
    "id" TEXT NOT NULL,
    "type" "JobType" NOT NULL,
    "status" "JobStatus" NOT NULL DEFAULT 'PENDING',
    "payload" JSONB NOT NULL,
    "result" JSONB,
    "error" TEXT,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "maxAttempts" INTEGER NOT NULL DEFAULT 3,
    "scheduledAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "startedAt" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "jobs_pkey" PRIMARY KEY ("id")
);

-- Jobs indexes
CREATE INDEX IF NOT EXISTS "jobs_status_idx" ON "jobs"("status");
CREATE INDEX IF NOT EXISTS "jobs_type_status_idx" ON "jobs"("type", "status");
CREATE INDEX IF NOT EXISTS "jobs_scheduledAt_idx" ON "jobs"("scheduledAt");
