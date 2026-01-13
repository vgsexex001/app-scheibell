/**
 * DTO para agendamentos do calendário
 * GET /api/admin/calendar
 */
export class CalendarAppointmentDto {
  id: string;
  patientId: string;
  patientName: string;
  procedureType: string;
  consultationType: string;
  date: string; // ISO date string
  time: string;
  status: string;
  notes: string;
}

export class CalendarResponseDto {
  items: CalendarAppointmentDto[];
  month: number;
  year: number;
  total: number;
}
