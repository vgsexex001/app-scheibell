export class RecoveryPatientDto {
  patientId: string;
  patientName: string;
  procedureType: string;
  dayPostOp: number;
  progressPercent: number;
  nextAppointmentAt: string | null;
  nextAppointmentLabel: string;
}

export class RecoveryPatientsResponseDto {
  items: RecoveryPatientDto[];
  page: number;
  limit: number;
  total: number;
}
