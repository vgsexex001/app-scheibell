-- AlterTable: Add authId column to users table
-- This links the users table to Supabase auth.users

ALTER TABLE "users" ADD COLUMN "authId" UUID UNIQUE;

-- Create index for faster lookups by authId
CREATE INDEX "users_authId_idx" ON "users"("authId");
