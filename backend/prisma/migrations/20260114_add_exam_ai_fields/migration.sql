-- Migration: Add AI analysis fields to Exam model
-- Date: 2026-01-14

-- CreateEnum: PatientFileType
CREATE TYPE "PatientFileType" AS ENUM ('EXAM', 'DOCUMENT');

-- CreateEnum: AiAnalysisStatus
CREATE TYPE "AiAnalysisStatus" AS ENUM ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'SKIPPED');

-- AlterTable: exams - Add new columns
ALTER TABLE "exams" ADD COLUMN "fileType" "PatientFileType" NOT NULL DEFAULT 'EXAM';
ALTER TABLE "exams" ADD COLUMN "aiStatus" "AiAnalysisStatus" NOT NULL DEFAULT 'PENDING';
ALTER TABLE "exams" ADD COLUMN "aiSummary" TEXT;
ALTER TABLE "exams" ADD COLUMN "aiJson" JSONB;
ALTER TABLE "exams" ADD COLUMN "createdByRole" TEXT;
ALTER TABLE "exams" ADD COLUMN "createdById" TEXT;

-- CreateIndex: patientId + fileType
CREATE INDEX "exams_patientId_fileType_idx" ON "exams"("patientId", "fileType");

-- CreateIndex: patientId + fileType + createdAt DESC
CREATE INDEX "exams_patientId_fileType_createdAt_idx" ON "exams"("patientId", "fileType", "createdAt" DESC);
