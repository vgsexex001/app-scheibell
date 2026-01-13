/**
 * DTO para agendamentos de hoje
 * GET /api/admin/appointments/today
 */
export class TodayAppointmentDto {
  id: string;
  patientId: string;
  patientName: string;
  procedureType: string;
  time: string;
  status: string;
}

export class TodayAppointmentsResponseDto {
  items: TodayAppointmentDto[];
  total: number;
}
