/*
  Warnings:

  - You are about to drop the column `clinic_id` on the `clinic_contents` table. All the data in the column will be lost.
  - You are about to drop the column `created_at` on the `clinic_contents` table. All the data in the column will be lost.
  - You are about to drop the column `is_active` on the `clinic_contents` table. All the data in the column will be lost.
  - You are about to drop the column `is_custom` on the `clinic_contents` table. All the data in the column will be lost.
  - You are about to drop the column `sort_order` on the `clinic_contents` table. All the data in the column will be lost.
  - You are about to drop the column `template_id` on the `clinic_contents` table. All the data in the column will be lost.
  - You are about to drop the column `updated_at` on the `clinic_contents` table. All the data in the column will be lost.
  - You are about to drop the column `valid_from_day` on the `clinic_contents` table. All the data in the column will be lost.
  - You are about to drop the column `valid_until_day` on the `clinic_contents` table. All the data in the column will be lost.
  - You are about to drop the column `created_at` on the `clinics` table. All the data in the column will be lost.
  - You are about to drop the column `is_active` on the `clinics` table. All the data in the column will be lost.
  - You are about to drop the column `logo_url` on the `clinics` table. All the data in the column will be lost.
  - You are about to drop the column `primary_color` on the `clinics` table. All the data in the column will be lost.
  - You are about to drop the column `secondary_color` on the `clinics` table. All the data in the column will be lost.
  - You are about to drop the column `updated_at` on the `clinics` table. All the data in the column will be lost.
  - You are about to drop the column `adjustment_type` on the `patient_content_adjustments` table. All the data in the column will be lost.
  - You are about to drop the column `base_content_id` on the `patient_content_adjustments` table. All the data in the column will be lost.
  - You are about to drop the column `content_type` on the `patient_content_adjustments` table. All the data in the column will be lost.
  - You are about to drop the column `created_at` on the `patient_content_adjustments` table. All the data in the column will be lost.
  - You are about to drop the column `created_by` on the `patient_content_adjustments` table. All the data in the column will be lost.
  - You are about to drop the column `is_active` on the `patient_content_adjustments` table. All the data in the column will be lost.
  - You are about to drop the column `patient_id` on the `patient_content_adjustments` table. All the data in the column will be lost.
  - You are about to drop the column `valid_from_day` on the `patient_content_adjustments` table. All the data in the column will be lost.
  - You are about to drop the column `valid_until_day` on the `patient_content_adjustments` table. All the data in the column will be lost.
  - You are about to drop the column `birth_date` on the `patients` table. All the data in the column will be lost.
  - You are about to drop the column `clinic_id` on the `patients` table. All the data in the column will be lost.
  - You are about to drop the column `created_at` on the `patients` table. All the data in the column will be lost.
  - You are about to drop the column `surgery_date` on the `patients` table. All the data in the column will be lost.
  - You are about to drop the column `surgery_type` on the `patients` table. All the data in the column will be lost.
  - You are about to drop the column `updated_at` on the `patients` table. All the data in the column will be lost.
  - You are about to drop the column `user_id` on the `patients` table. All the data in the column will be lost.
  - You are about to drop the column `created_at` on the `system_content_templates` table. All the data in the column will be lost.
  - You are about to drop the column `is_active` on the `system_content_templates` table. All the data in the column will be lost.
  - You are about to drop the column `sort_order` on the `system_content_templates` table. All the data in the column will be lost.
  - You are about to drop the column `updated_at` on the `system_content_templates` table. All the data in the column will be lost.
  - You are about to drop the column `valid_from_day` on the `system_content_templates` table. All the data in the column will be lost.
  - You are about to drop the column `valid_until_day` on the `system_content_templates` table. All the data in the column will be lost.
  - You are about to drop the column `clinic_id` on the `users` table. All the data in the column will be lost.
  - You are about to drop the column `created_at` on the `users` table. All the data in the column will be lost.
  - You are about to drop the column `password` on the `users` table. All the data in the column will be lost.
  - You are about to drop the column `updated_at` on the `users` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[userId]` on the table `patients` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `clinicId` to the `clinic_contents` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updatedAt` to the `clinic_contents` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updatedAt` to the `clinics` table without a default value. This is not possible if the table is not empty.
  - Added the required column `adjustmentType` to the `patient_content_adjustments` table without a default value. This is not possible if the table is not empty.
  - Added the required column `patientId` to the `patient_content_adjustments` table without a default value. This is not possible if the table is not empty.
  - Added the required column `clinicId` to the `patients` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updatedAt` to the `patients` table without a default value. This is not possible if the table is not empty.
  - Added the required column `userId` to the `patients` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updatedAt` to the `system_content_templates` table without a default value. This is not possible if the table is not empty.
  - Added the required column `passwordHash` to the `users` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updatedAt` to the `users` table without a default value. This is not possible if the table is not empty.

*/
-- DropForeignKey
ALTER TABLE "clinic_contents" DROP CONSTRAINT "clinic_contents_clinic_id_fkey";

-- DropForeignKey
ALTER TABLE "patient_content_adjustments" DROP CONSTRAINT "patient_content_adjustments_base_content_id_fkey";

-- DropForeignKey
ALTER TABLE "patient_content_adjustments" DROP CONSTRAINT "patient_content_adjustments_patient_id_fkey";

-- DropForeignKey
ALTER TABLE "patients" DROP CONSTRAINT "patients_clinic_id_fkey";

-- DropForeignKey
ALTER TABLE "patients" DROP CONSTRAINT "patients_user_id_fkey";

-- DropForeignKey
ALTER TABLE "users" DROP CONSTRAINT "users_clinic_id_fkey";

-- DropIndex
DROP INDEX "clinic_contents_clinic_id_idx";

-- DropIndex
DROP INDEX "clinic_contents_clinic_id_type_category_idx";

-- DropIndex
DROP INDEX "clinic_contents_clinic_id_type_idx";

-- DropIndex
DROP INDEX "clinic_contents_clinic_id_type_is_active_idx";

-- DropIndex
DROP INDEX "patient_content_adjustments_base_content_id_idx";

-- DropIndex
DROP INDEX "patient_content_adjustments_patient_id_idx";

-- DropIndex
DROP INDEX "patients_user_id_key";

-- AlterTable
ALTER TABLE "clinic_contents" DROP COLUMN "clinic_id",
DROP COLUMN "created_at",
DROP COLUMN "is_active",
DROP COLUMN "is_custom",
DROP COLUMN "sort_order",
DROP COLUMN "template_id",
DROP COLUMN "updated_at",
DROP COLUMN "valid_from_day",
DROP COLUMN "valid_until_day",
ADD COLUMN     "clinicId" TEXT NOT NULL,
ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "isActive" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "isCustom" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "sortOrder" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "templateId" TEXT,
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "validFromDay" INTEGER,
ADD COLUMN     "validUntilDay" INTEGER;

-- AlterTable
ALTER TABLE "clinics" DROP COLUMN "created_at",
DROP COLUMN "is_active",
DROP COLUMN "logo_url",
DROP COLUMN "primary_color",
DROP COLUMN "secondary_color",
DROP COLUMN "updated_at",
ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "isActive" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "logoUrl" TEXT,
ADD COLUMN     "primaryColor" TEXT DEFAULT '#4F4A34',
ADD COLUMN     "secondaryColor" TEXT DEFAULT '#A49E86',
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL;

-- AlterTable
ALTER TABLE "patient_content_adjustments" DROP COLUMN "adjustment_type",
DROP COLUMN "base_content_id",
DROP COLUMN "content_type",
DROP COLUMN "created_at",
DROP COLUMN "created_by",
DROP COLUMN "is_active",
DROP COLUMN "patient_id",
DROP COLUMN "valid_from_day",
DROP COLUMN "valid_until_day",
ADD COLUMN     "adjustmentType" "AdjustmentType" NOT NULL,
ADD COLUMN     "baseContentId" TEXT,
ADD COLUMN     "contentType" "ContentType",
ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "createdBy" TEXT,
ADD COLUMN     "isActive" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "patientId" TEXT NOT NULL,
ADD COLUMN     "validFromDay" INTEGER,
ADD COLUMN     "validUntilDay" INTEGER;

-- AlterTable
ALTER TABLE "patients" DROP COLUMN "birth_date",
DROP COLUMN "clinic_id",
DROP COLUMN "created_at",
DROP COLUMN "surgery_date",
DROP COLUMN "surgery_type",
DROP COLUMN "updated_at",
DROP COLUMN "user_id",
ADD COLUMN     "birthDate" TIMESTAMP(3),
ADD COLUMN     "clinicId" TEXT NOT NULL,
ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "surgeryDate" TIMESTAMP(3),
ADD COLUMN     "surgeryType" TEXT,
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "userId" TEXT NOT NULL;

-- AlterTable
ALTER TABLE "system_content_templates" DROP COLUMN "created_at",
DROP COLUMN "is_active",
DROP COLUMN "sort_order",
DROP COLUMN "updated_at",
DROP COLUMN "valid_from_day",
DROP COLUMN "valid_until_day",
ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "isActive" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "sortOrder" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "validFromDay" INTEGER,
ADD COLUMN     "validUntilDay" INTEGER;

-- AlterTable
ALTER TABLE "users" DROP COLUMN "clinic_id",
DROP COLUMN "created_at",
DROP COLUMN "password",
DROP COLUMN "updated_at",
ADD COLUMN     "clinicId" TEXT,
ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "passwordHash" TEXT NOT NULL,
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL;

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
CREATE UNIQUE INDEX "patients_userId_key" ON "patients"("userId");

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_clinicId_fkey" FOREIGN KEY ("clinicId") REFERENCES "clinics"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patients" ADD CONSTRAINT "patients_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patients" ADD CONSTRAINT "patients_clinicId_fkey" FOREIGN KEY ("clinicId") REFERENCES "clinics"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "clinic_contents" ADD CONSTRAINT "clinic_contents_clinicId_fkey" FOREIGN KEY ("clinicId") REFERENCES "clinics"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_content_adjustments" ADD CONSTRAINT "patient_content_adjustments_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "patients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_content_adjustments" ADD CONSTRAINT "patient_content_adjustments_baseContentId_fkey" FOREIGN KEY ("baseContentId") REFERENCES "clinic_contents"("id") ON DELETE CASCADE ON UPDATE CASCADE;
