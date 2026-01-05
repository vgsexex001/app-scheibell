export class PendingAppointmentDto {
  id: string;
  patientId: string;
  patientName: string;
  procedureType: string;
  startsAt: string;
  displayDate: string;
  displayTime: string;
}

export class PendingAppointmentsResponseDto {
  items: PendingAppointmentDto[];
  page: number;
  limit: number;
  total: number;
}
