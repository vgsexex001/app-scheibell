-- App Scheibell - Database Schema
-- Execute este SQL no Supabase SQL Editor

-- CreateEnum
CREATE TYPE "ContentType" AS ENUM ('SYMPTOMS', 'DIET', 'ACTIVITIES', 'CARE', 'TRAINING', 'EXAMS', 'DOCUMENTS', 'MEDICATIONS', 'DIARY');

-- CreateEnum
CREATE TYPE "ContentCategory" AS ENUM ('NORMAL', 'WARNING', 'EMERGENCY', 'ALLOWED', 'RESTRICTED', 'PROHIBITED', 'INFO');

-- CreateEnum
CREATE TYPE "AdjustmentType" AS ENUM ('ADD', 'DISABLE', 'MODIFY');

-- CreateEnum
CREATE TYPE "OverrideAction" AS ENUM ('ADD', 'DISABLE', 'MODIFY');

-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('PATIENT', 'CLINIC_ADMIN', 'CLINIC_STAFF', 'THIRD_PARTY');

-- CreateEnum
CREATE TYPE "AppointmentType" AS ENUM ('CONSULTATION', 'RETURN_VISIT', 'EVALUATION', 'PHYSIOTHERAPY', 'EXAM', 'OTHER');

-- CreateEnum
CREATE TYPE "AppointmentStatus" AS ENUM ('PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED');

-- CreateEnum
CREATE TYPE "ExamStatus" AS ENUM ('PENDING', 'AVAILABLE', 'VIEWED');

-- CreateEnum
CREATE TYPE "AlertType" AS ENUM ('HIGH_PAIN', 'FEVER', 'LOW_ADHERENCE', 'MISSED_APPOINTMENT', 'URGENT_SYMPTOM', 'HUMAN_HANDOFF', 'OTHER');

-- CreateEnum
CREATE TYPE "AlertStatus" AS ENUM ('ACTIVE', 'RESOLVED', 'DISMISSED');

-- CreateEnum
CREATE TYPE "NotificationType" AS ENUM ('NEW_APPOINTMENT', 'APPOINTMENT_APPROVED', 'APPOINTMENT_REJECTED', 'ALERT_CREATED', 'REMINDER', 'OTHER');

-- CreateEnum
CREATE TYPE "NotificationStatus" AS ENUM ('PENDING', 'SENT', 'READ', 'FAILED');

-- CreateEnum
CREATE TYPE "ConnectionStatus" AS ENUM ('PENDING', 'ACTIVE', 'REVOKED', 'EXPIRED');

-- CreateEnum
CREATE TYPE "ChatAttachmentType" AS ENUM ('IMAGE');

-- CreateEnum
CREATE TYPE "ChatAttachmentStatus" AS ENUM ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED');

-- CreateEnum
CREATE TYPE "ChatMode" AS ENUM ('AI', 'HUMAN', 'CLOSED');

-- CreateEnum
CREATE TYPE "TrainingWeekStatus" AS ENUM ('COMPLETED', 'CURRENT', 'FUTURE');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "role" "UserRole" NOT NULL DEFAULT 'PATIENT',
    "clinicId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "clinics" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "email" TEXT,
    "phone" TEXT,
    "address" TEXT,
    "logoUrl" TEXT,
    "primaryColor" TEXT DEFAULT '#4F4A34',
    "secondaryColor" TEXT DEFAULT '#A49E86',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "clinics_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "patients" (
    "id" TEXT NOT NULL,
    "userId" TEXT,
    "name" TEXT,
    "email" TEXT,
    "clinicId" TEXT NOT NULL,
    "cpf" TEXT,
    "phone" TEXT,
    "birthDate" TIMESTAMP(3),
    "bloodType" TEXT,
    "weightKg" DOUBLE PRECISION,
    "heightCm" DOUBLE PRECISION,
    "emergencyContact" TEXT,
    "emergencyPhone" TEXT,
    "surgeryDate" TIMESTAMP(3),
    "surgeryType" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "patients_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "appointments" (
    "id" TEXT NOT NULL,
    "patientId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "date" TIMESTAMP(3) NOT NULL,
    "time" TEXT NOT NULL,
    "type" "AppointmentType" NOT NULL,
    "status" "AppointmentStatus" NOT NULL DEFAULT 'PENDING',
    "location" TEXT,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "appointments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "medication_logs" (
    "id" TEXT NOT NULL,
    "patientId" TEXT NOT NULL,
    "contentId" TEXT NOT NULL,
    "takenAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scheduledTime" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "medication_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "exams" (
    "id" TEXT NOT NULL,
    "patientId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,
    "status" "ExamStatus" NOT NULL DEFAULT 'PENDING',
    "fileUrl" TEXT,
    "fileName" TEXT,
    "fileSize" INTEGER,
    "mimeType" TEXT,
    "notes" TEXT,
    "result" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "exams_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "system_content_templates" (
    "id" TEXT NOT NULL,
    "type" "ContentType" NOT NULL,
    "category" "ContentCategory" NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "validFromDay" INTEGER,
    "validUntilDay" INTEGER,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "system_content_templates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "clinic_contents" (
    "id" TEXT NOT NULL,
    "clinicId" TEXT NOT NULL,
    "templateId" TEXT,
    "type" "ContentType" NOT NULL,
    "category" "ContentCategory" NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "validFromDay" INTEGER,
    "validUntilDay" INTEGER,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "isCustom" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "clinic_contents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "patient_content_adjustments" (
    "id" TEXT NOT NULL,
    "patientId" TEXT NOT NULL,
    "baseContentId" TEXT,
    "adjustmentType" "AdjustmentType" NOT NULL,
    "contentType" "ContentType",
    "category" "ContentCategory",
    "title" TEXT,
    "description" TEXT,
    "validFromDay" INTEGER,
    "validUntilDay" INTEGER,
    "reason" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "patient_content_adjustments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "training_protocols" (
    "id" TEXT NOT NULL,
    "clinicId" TEXT,
    "name" TEXT NOT NULL,
    "surgeryType" TEXT,
    "description" TEXT,
    "totalWeeks" INTEGER NOT NULL DEFAULT 8,
    "isDefault" BOOLEAN NOT NULL DEFAULT false,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "training_protocols_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "training_weeks" (
    "id" TEXT NOT NULL,
    "protocolId" TEXT NOT NULL,
    "weekNumber" INTEGER NOT NULL,
    "title" TEXT NOT NULL,
    "dayRange" TEXT NOT NULL,
    "objective" TEXT NOT NULL,
    "maxHeartRate" INTEGER,
    "heartRateLabel" TEXT,
    "canDo" TEXT[],
    "avoid" TEXT[],
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "training_weeks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "training_sessions" (
    "id" TEXT NOT NULL,
    "weekId" TEXT NOT NULL,
    "sessionNumber" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "duration" INTEGER,
    "intensity" TEXT,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "training_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "patient_training_progress" (
    "id" TEXT NOT NULL,
    "patientId" TEXT NOT NULL,
    "weekId" TEXT NOT NULL,
    "status" "TrainingWeekStatus" NOT NULL DEFAULT 'FUTURE',
    "startedAt" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "patient_training_progress_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "patient_session_completions" (
    "id" TEXT NOT NULL,
    "patientId" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "completedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "notes" TEXT,

    CONSTRAINT "patient_session_completions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "chat_conversations" (
    "id" TEXT NOT NULL,
    "patientId" TEXT NOT NULL,
    "mode" "ChatMode" NOT NULL DEFAULT 'AI',
    "handoffAt" TIMESTAMP(3),
    "handoffAlertId" TEXT,
    "closedAt" TIMESTAMP(3),
    "closedBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "chat_conversations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "chat_messages" (
    "id" TEXT NOT NULL,
    "conversationId" TEXT NOT NULL,
    "role" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "senderId" TEXT,
    "senderType" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "chat_messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "chat_attachments" (
    "id" TEXT NOT NULL,
    "messageId" TEXT,
    "conversationId" TEXT NOT NULL,
    "type" "ChatAttachmentType" NOT NULL DEFAULT 'IMAGE',
    "originalName" TEXT NOT NULL,
    "storagePath" TEXT NOT NULL,
    "mimeType" TEXT NOT NULL,
    "sizeBytes" INTEGER NOT NULL,
    "status" "ChatAttachmentStatus" NOT NULL DEFAULT 'PENDING',
    "aiAnalysis" TEXT,
    "errorMessage" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "processedAt" TIMESTAMP(3),

    CONSTRAINT "chat_attachments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "alerts" (
    "id" TEXT NOT NULL,
    "clinicId" TEXT NOT NULL,
    "patientId" TEXT,
    "type" "AlertType" NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "status" "AlertStatus" NOT NULL DEFAULT 'ACTIVE',
    "isAutomatic" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resolvedAt" TIMESTAMP(3),
    "resolvedBy" TEXT,

    CONSTRAINT "alerts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" "NotificationType" NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "data" JSONB,
    "status" "NotificationStatus" NOT NULL DEFAULT 'PENDING',
    "sentAt" TIMESTAMP(3),
    "readAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "patient_allergies" (
    "id" TEXT NOT NULL,
    "patientId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "severity" TEXT,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "patient_allergies_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "medical_notes" (
    "id" TEXT NOT NULL,
    "patientId" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "author" TEXT,
    "authorId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "medical_notes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "patient_connections" (
    "id" TEXT NOT NULL,
    "patientId" TEXT NOT NULL,
    "clinicId" TEXT NOT NULL,
    "connectionCode" TEXT NOT NULL,
    "status" "ConnectionStatus" NOT NULL DEFAULT 'PENDING',
    "codeGeneratedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "codeExpiresAt" TIMESTAMP(3) NOT NULL,
    "connectedAt" TIMESTAMP(3),
    "revokedAt" TIMESTAMP(3),
    "generatedById" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "patient_connections_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "content_templates" (
    "id" TEXT NOT NULL,
    "clinicId" TEXT NOT NULL,
    "type" "ContentType" NOT NULL,
    "category" "ContentCategory" NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "validFromDay" INTEGER,
    "validUntilDay" INTEGER,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "createdBy" TEXT,

    CONSTRAINT "content_templates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "patient_content_overrides" (
    "id" TEXT NOT NULL,
    "patientId" TEXT NOT NULL,
    "templateId" TEXT,
    "action" "OverrideAction" NOT NULL,
    "type" "ContentType",
    "category" "ContentCategory",
    "title" TEXT,
    "description" TEXT,
    "validFromDay" INTEGER,
    "validUntilDay" INTEGER,
    "reason" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "createdBy" TEXT,

    CONSTRAINT "patient_content_overrides_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "patient_content_states" (
    "id" TEXT NOT NULL,
    "patientId" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "lastSyncedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "contentHash" TEXT,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "patient_content_states_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "deviceInfo" TEXT,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "revokedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "patients_userId_key" ON "patients"("userId");

-- CreateIndex
CREATE INDEX "appointments_patientId_idx" ON "appointments"("patientId");

-- CreateIndex
CREATE INDEX "appointments_patientId_status_idx" ON "appointments"("patientId", "status");

-- CreateIndex
CREATE INDEX "appointments_patientId_date_idx" ON "appointments"("patientId", "date");

-- CreateIndex
CREATE INDEX "medication_logs_patientId_idx" ON "medication_logs"("patientId");

-- CreateIndex
CREATE INDEX "medication_logs_patientId_takenAt_idx" ON "medication_logs"("patientId", "takenAt");

-- CreateIndex
CREATE INDEX "exams_patientId_idx" ON "exams"("patientId");

-- CreateIndex
CREATE INDEX "exams_patientId_status_idx" ON "exams"("patientId", "status");

-- CreateIndex
CREATE INDEX "exams_patientId_date_idx" ON "exams"("patientId", "date");

-- CreateIndex
CREATE INDEX "system_content_templates_type_idx" ON "system_content_templates"("type");

-- CreateIndex
CREATE INDEX "system_content_templates_type_category_idx" ON "system_content_templates"("type", "category");

-- CreateIndex
CREATE INDEX "clinic_contents_clinicId_idx" ON "clinic_contents"("clinicId");

-- CreateIndex
CREATE INDEX "clinic_contents_clinicId_type_idx" ON "clinic_contents"("clinicId", "type");

-- CreateIndex
CREATE INDEX "clinic_contents_clinicId_type_category_idx" ON "clinic_contents"("clinicId", "type", "category");

-- CreateIndex
CREATE INDEX "clinic_contents_clinicId_type_isActive_idx" ON "clinic_contents"("clinicId", "type", "isActive");

-- CreateIndex
CREATE INDEX "patient_content_adjustments_patientId_idx" ON "patient_content_adjustments"("patientId");

-- CreateIndex
CREATE INDEX "patient_content_adjustments_baseContentId_idx" ON "patient_content_adjustments"("baseContentId");

-- CreateIndex
CREATE INDEX "training_protocols_clinicId_idx" ON "training_protocols"("clinicId");

-- CreateIndex
CREATE INDEX "training_protocols_isDefault_idx" ON "training_protocols"("isDefault");

-- CreateIndex
CREATE INDEX "training_weeks_protocolId_idx" ON "training_weeks"("protocolId");

-- CreateIndex
CREATE UNIQUE INDEX "training_weeks_protocolId_weekNumber_key" ON "training_weeks"("protocolId", "weekNumber");

-- CreateIndex
CREATE INDEX "training_sessions_weekId_idx" ON "training_sessions"("weekId");

-- CreateIndex
CREATE UNIQUE INDEX "training_sessions_weekId_sessionNumber_key" ON "training_sessions"("weekId", "sessionNumber");

-- CreateIndex
CREATE INDEX "patient_training_progress_patientId_idx" ON "patient_training_progress"("patientId");

-- CreateIndex
CREATE INDEX "patient_training_progress_patientId_status_idx" ON "patient_training_progress"("patientId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "patient_training_progress_patientId_weekId_key" ON "patient_training_progress"("patientId", "weekId");

-- CreateIndex
CREATE INDEX "patient_session_completions_patientId_idx" ON "patient_session_completions"("patientId");

-- CreateIndex
CREATE INDEX "patient_session_completions_patientId_completedAt_idx" ON "patient_session_completions"("patientId", "completedAt");

-- CreateIndex
CREATE UNIQUE INDEX "patient_session_completions_patientId_sessionId_key" ON "patient_session_completions"("patientId", "sessionId");

-- CreateIndex
CREATE INDEX "chat_conversations_patientId_idx" ON "chat_conversations"("patientId");

-- CreateIndex
CREATE INDEX "chat_conversations_mode_idx" ON "chat_conversations"("mode");

-- CreateIndex
CREATE INDEX "chat_messages_conversationId_idx" ON "chat_messages"("conversationId");

-- CreateIndex
CREATE INDEX "chat_attachments_messageId_idx" ON "chat_attachments"("messageId");

-- CreateIndex
CREATE INDEX "chat_attachments_conversationId_idx" ON "chat_attachments"("conversationId");

-- CreateIndex
CREATE INDEX "alerts_clinicId_idx" ON "alerts"("clinicId");

-- CreateIndex
CREATE INDEX "alerts_clinicId_status_idx" ON "alerts"("clinicId", "status");

-- CreateIndex
CREATE INDEX "alerts_patientId_idx" ON "alerts"("patientId");

-- CreateIndex
CREATE INDEX "notifications_userId_idx" ON "notifications"("userId");

-- CreateIndex
CREATE INDEX "notifications_userId_status_idx" ON "notifications"("userId", "status");

-- CreateIndex
CREATE INDEX "patient_allergies_patientId_idx" ON "patient_allergies"("patientId");

-- CreateIndex
CREATE INDEX "medical_notes_patientId_idx" ON "medical_notes"("patientId");

-- CreateIndex
CREATE INDEX "medical_notes_patientId_createdAt_idx" ON "medical_notes"("patientId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "patient_connections_connectionCode_key" ON "patient_connections"("connectionCode");

-- CreateIndex
CREATE INDEX "patient_connections_connectionCode_idx" ON "patient_connections"("connectionCode");

-- CreateIndex
CREATE INDEX "patient_connections_patientId_idx" ON "patient_connections"("patientId");

-- CreateIndex
CREATE INDEX "patient_connections_clinicId_idx" ON "patient_connections"("clinicId");

-- CreateIndex
CREATE INDEX "patient_connections_status_idx" ON "patient_connections"("status");

-- CreateIndex
CREATE INDEX "content_templates_clinicId_idx" ON "content_templates"("clinicId");

-- CreateIndex
CREATE INDEX "content_templates_clinicId_type_idx" ON "content_templates"("clinicId", "type");

-- CreateIndex
CREATE INDEX "content_templates_clinicId_type_isActive_idx" ON "content_templates"("clinicId", "type", "isActive");

-- CreateIndex
CREATE INDEX "patient_content_overrides_patientId_idx" ON "patient_content_overrides"("patientId");

-- CreateIndex
CREATE INDEX "patient_content_overrides_patientId_templateId_idx" ON "patient_content_overrides"("patientId", "templateId");

-- CreateIndex
CREATE INDEX "patient_content_overrides_patientId_action_idx" ON "patient_content_overrides"("patientId", "action");

-- CreateIndex
CREATE UNIQUE INDEX "patient_content_states_patientId_key" ON "patient_content_states"("patientId");

-- CreateIndex
CREATE INDEX "patient_content_states_patientId_idx" ON "patient_content_states"("patientId");

-- CreateIndex
CREATE UNIQUE INDEX "refresh_tokens_token_key" ON "refresh_tokens"("token");

-- CreateIndex
CREATE INDEX "refresh_tokens_token_idx" ON "refresh_tokens"("token");

-- CreateIndex
CREATE INDEX "refresh_tokens_userId_idx" ON "refresh_tokens"("userId");

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_clinicId_fkey" FOREIGN KEY ("clinicId") REFERENCES "clinics"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patients" ADD CONSTRAINT "patients_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patients" ADD CONSTRAINT "patients_clinicId_fkey" FOREIGN KEY ("clinicId") REFERENCES "clinics"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "appointments" ADD CONSTRAINT "appointments_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "patients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_logs" ADD CONSTRAINT "medication_logs_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "patients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "exams" ADD CONSTRAINT "exams_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "patients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "clinic_contents" ADD CONSTRAINT "clinic_contents_clinicId_fkey" FOREIGN KEY ("clinicId") REFERENCES "clinics"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_content_adjustments" ADD CONSTRAINT "patient_content_adjustments_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "patients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_content_adjustments" ADD CONSTRAINT "patient_content_adjustments_baseContentId_fkey" FOREIGN KEY ("baseContentId") REFERENCES "clinic_contents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "training_protocols" ADD CONSTRAINT "training_protocols_clinicId_fkey" FOREIGN KEY ("clinicId") REFERENCES "clinics"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "training_weeks" ADD CONSTRAINT "training_weeks_protocolId_fkey" FOREIGN KEY ("protocolId") REFERENCES "training_protocols"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "training_sessions" ADD CONSTRAINT "training_sessions_weekId_fkey" FOREIGN KEY ("weekId") REFERENCES "training_weeks"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_training_progress" ADD CONSTRAINT "patient_training_progress_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "patients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_training_progress" ADD CONSTRAINT "patient_training_progress_weekId_fkey" FOREIGN KEY ("weekId") REFERENCES "training_weeks"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_session_completions" ADD CONSTRAINT "patient_session_completions_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "patients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_session_completions" ADD CONSTRAINT "patient_session_completions_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "training_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chat_conversations" ADD CONSTRAINT "chat_conversations_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "patients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chat_messages" ADD CONSTRAINT "chat_messages_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "chat_conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chat_attachments" ADD CONSTRAINT "chat_attachments_messageId_fkey" FOREIGN KEY ("messageId") REFERENCES "chat_messages"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chat_attachments" ADD CONSTRAINT "chat_attachments_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "chat_conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "alerts" ADD CONSTRAINT "alerts_clinicId_fkey" FOREIGN KEY ("clinicId") REFERENCES "clinics"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "alerts" ADD CONSTRAINT "alerts_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "patients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_allergies" ADD CONSTRAINT "patient_allergies_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "patients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medical_notes" ADD CONSTRAINT "medical_notes_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "patients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_connections" ADD CONSTRAINT "patient_connections_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "patients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_connections" ADD CONSTRAINT "patient_connections_clinicId_fkey" FOREIGN KEY ("clinicId") REFERENCES "clinics"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_connections" ADD CONSTRAINT "patient_connections_generatedById_fkey" FOREIGN KEY ("generatedById") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "content_templates" ADD CONSTRAINT "content_templates_clinicId_fkey" FOREIGN KEY ("clinicId") REFERENCES "clinics"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_content_overrides" ADD CONSTRAINT "patient_content_overrides_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "patients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_content_overrides" ADD CONSTRAINT "patient_content_overrides_templateId_fkey" FOREIGN KEY ("templateId") REFERENCES "content_templates"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_content_states" ADD CONSTRAINT "patient_content_states_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "patients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
