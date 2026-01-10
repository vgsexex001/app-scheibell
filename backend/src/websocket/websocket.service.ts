import { Injectable } from '@nestjs/common';
import { WebsocketGateway } from './websocket.gateway';

@Injectable()
export class WebsocketService {
  constructor(private gateway: WebsocketGateway) {}

  // === EVENTOS DE CHAT ===

  notifyNewMessage(conversationId: string, message: any) {
    this.gateway.emitNewMessage(conversationId, {
      type: 'NEW_MESSAGE',
      conversationId,
      message,
      timestamp: new Date().toISOString(),
    });
  }

  notifyHandoff(clinicId: string, conversationId: string, patientName: string) {
    this.gateway.emitToClinic(clinicId, 'chat:handoff', {
      type: 'HANDOFF_REQUESTED',
      conversationId,
      patientName,
      timestamp: new Date().toISOString(),
    });
  }

  notifyConversationClosed(conversationId: string, patientId: string) {
    this.gateway.emitToPatient(patientId, 'chat:closed', {
      type: 'CONVERSATION_CLOSED',
      conversationId,
      timestamp: new Date().toISOString(),
    });
  }

  notifyAdminJoined(conversationId: string, patientId: string, adminName: string) {
    this.gateway.emitToPatient(patientId, 'chat:admin_joined', {
      type: 'ADMIN_JOINED',
      conversationId,
      adminName,
      timestamp: new Date().toISOString(),
    });
  }

  // === EVENTOS DE AGENDAMENTO ===

  notifyNewAppointment(clinicId: string, appointment: any) {
    this.gateway.emitToClinic(clinicId, 'appointment:new', {
      type: 'NEW_APPOINTMENT',
      appointment,
      timestamp: new Date().toISOString(),
    });
  }

  notifyAppointmentStatusChanged(patientId: string, clinicId: string, appointment: any) {
    // Notificar paciente
    this.gateway.emitToPatient(patientId, 'appointment:status', {
      type: 'APPOINTMENT_STATUS_CHANGED',
      appointment,
      timestamp: new Date().toISOString(),
    });

    // Notificar clínica
    this.gateway.emitToClinic(clinicId, 'appointment:status', {
      type: 'APPOINTMENT_STATUS_CHANGED',
      appointment,
      timestamp: new Date().toISOString(),
    });
  }

  notifyAppointmentCancelled(patientId: string, clinicId: string, appointmentId: string) {
    this.gateway.emitToPatient(patientId, 'appointment:cancelled', {
      type: 'APPOINTMENT_CANCELLED',
      appointmentId,
      timestamp: new Date().toISOString(),
    });

    this.gateway.emitToClinic(clinicId, 'appointment:cancelled', {
      type: 'APPOINTMENT_CANCELLED',
      appointmentId,
      timestamp: new Date().toISOString(),
    });
  }

  // === EVENTOS DE NOTIFICAÇÃO ===

  notifyUser(userId: string, notification: any) {
    this.gateway.emitToUser(userId, 'notification:new', {
      type: 'NEW_NOTIFICATION',
      notification,
      timestamp: new Date().toISOString(),
    });
  }

  // === EVENTOS DE CONTEÚDO ===

  notifyContentUpdated(patientId: string, contentType: string) {
    this.gateway.emitToPatient(patientId, 'content:updated', {
      type: 'CONTENT_UPDATED',
      contentType,
      timestamp: new Date().toISOString(),
    });
  }

  notifyClinicContentUpdated(clinicId: string, contentType: string) {
    this.gateway.emitToClinic(clinicId, 'content:updated', {
      type: 'CLINIC_CONTENT_UPDATED',
      contentType,
      timestamp: new Date().toISOString(),
    });
  }

  // === EVENTOS DE PACIENTE ===

  notifyPatientUpdated(patientId: string, clinicId: string, updateType: string) {
    this.gateway.emitToClinic(clinicId, 'patient:updated', {
      type: 'PATIENT_UPDATED',
      patientId,
      updateType,
      timestamp: new Date().toISOString(),
    });
  }

  // === STATUS ONLINE ===

  isUserOnline(userId: string): boolean {
    return this.gateway.isUserOnline(userId);
  }

  getOnlineUsersCount(): number {
    return this.gateway.getOnlineUsersCount();
  }
}
