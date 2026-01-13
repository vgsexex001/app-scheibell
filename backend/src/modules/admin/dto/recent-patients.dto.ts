/**
 * DTO para pacientes recentes
 * GET /api/admin/patients/recent
 */
export class RecentPatientDto {
  id: string;
  name: string;
  procedureType: string;
  daysAgo: number;
  lastActivity: string; // ISO date string
}

export class RecentPatientsResponseDto {
  items: RecentPatientDto[];
  total: number;
}
