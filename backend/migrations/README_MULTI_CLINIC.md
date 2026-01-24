# Multi-Clinic Migration Guide

## Overview

This migration adds support for patients and staff to be associated with multiple clinics, enabling true multi-tenant SaaS architecture while maintaining backwards compatibility with the existing single-clinic model.

## New Tables

### patient_clinic_associations
- Links patients to clinics (N:N relationship)
- Stores clinic-specific surgery data (date, type, surgeon)
- Tracks transfer history between clinics
- Fields: `patient_id`, `clinic_id`, `surgery_date`, `surgery_type`, `surgeon`, `status`, `is_primary`

### user_clinic_assignments
- Links staff/admin users to clinics (N:N relationship)
- Stores clinic-specific role and permissions
- Fields: `user_id`, `clinic_id`, `role`, `permissions`, `is_active`, `is_default`

## Migration Steps

### 1. Execute SQL Migrations in Supabase

Run these scripts in order in the Supabase SQL Editor:

```bash
# First: Create the new tables
backend/migrations/001_multi_clinic_tables.sql

# Second: Migrate existing data
backend/migrations/002_migrate_existing_data.sql
```

### 2. Regenerate Prisma Client

After the SQL migrations are applied:

```bash
cd backend
npx prisma generate
```

### 3. Deploy Backend

The backend code already includes:
- Updated `schema.prisma` with new models
- `ClinicContextGuard` for validating clinic access
- `@RequiresClinicContext()` decorator for endpoints
- `switch-clinic` endpoint for changing clinic context
- `my-clinics` endpoint for listing user's clinics
- Updated JWT Strategy to load clinic associations

## New API Endpoints

### POST /api/auth/switch-clinic
Switch the active clinic context for multi-clinic users.

**Request:**
```json
{
  "clinicId": "uuid-of-target-clinic"
}
```

**Response:**
```json
{
  "user": { ... },
  "accessToken": "new-jwt-token",
  "refreshToken": "new-refresh-token",
  "expiresIn": 900,
  "clinicAssociations": [
    {
      "clinicId": "uuid",
      "clinicName": "Clinic Name",
      "role": "PATIENT",
      "isPrimary": true,
      "isDefault": true
    }
  ]
}
```

### GET /api/auth/my-clinics
List all clinics the user has access to.

**Response:**
```json
{
  "currentClinicId": "uuid-of-current-clinic",
  "clinics": [
    {
      "clinicId": "uuid",
      "clinicName": "Clinic Name",
      "role": "PATIENT",
      "isPrimary": true,
      "isDefault": true
    }
  ]
}
```

## Backend Changes Summary

### Files Created
- `backend/migrations/001_multi_clinic_tables.sql`
- `backend/migrations/002_migrate_existing_data.sql`
- `backend/src/modules/auth/guards/clinic-context.guard.ts`
- `backend/src/modules/auth/decorators/clinic-context.decorator.ts`
- `backend/src/modules/auth/dto/switch-clinic.dto.ts`

### Files Modified
- `backend/prisma/schema.prisma` - Added new models and relationships
- `backend/src/common/decorators/current-user.decorator.ts` - Extended JwtPayload
- `backend/src/modules/auth/strategies/jwt.strategy.ts` - Load clinic associations
- `backend/src/modules/auth/auth.service.ts` - Added switch-clinic methods
- `backend/src/modules/auth/auth.controller.ts` - Added new endpoints
- `backend/src/modules/auth/dto/index.ts` - Export new DTO
- `backend/src/common/services/logger.service.ts` - Added switch_clinic event

## Backwards Compatibility

The migration maintains full backwards compatibility:

1. **Existing `clinicId` fields preserved**: The `User.clinicId` and `Patient.clinicId` fields are kept as the "primary" or "legacy" clinic
2. **Fallback queries**: If the new association tables are empty, the system falls back to the direct clinicId fields
3. **No frontend changes required initially**: The API responses include the same data structure as before
4. **Gradual migration**: Users can continue using single-clinic mode while the multi-clinic features are optional

## Using the ClinicContextGuard

To protect endpoints that require validated clinic context:

```typescript
import { RequiresClinicContext, ClinicContext, ClinicContextData } from '../auth/decorators/clinic-context.decorator';

@Controller('my-resource')
export class MyController {

  @Get()
  @RequiresClinicContext()  // Validates user has access to clinic in JWT
  async getData(@ClinicContext() clinic: ClinicContextData) {
    console.log(clinic.clinicId, clinic.clinicName);
  }
}
```

## Future Enhancements

After this migration is stable, consider:

1. Admin panel to manage patient/user clinic associations
2. Ability to share patient data between clinics (with consent)
3. Clinic-specific branding/theming per association
4. Transfer workflow between clinics
5. Multi-clinic analytics dashboard
