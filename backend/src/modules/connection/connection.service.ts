import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ConnectionStatus, Prisma } from '@prisma/client';
import { ConnectionListQueryDto, ConnectionStatsDto } from './dto';

@Injectable()
export class ConnectionService {
  constructor(private prisma: PrismaService) {}

  /**
   * Gera código único de 6 caracteres alfanuméricos
   * Exclui caracteres confusos: 0, O, 1, I, L
   */
  private generateCode(): string {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    let code = '';
    for (let i = 0; i < 6; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
  }

  /**
   * Admin gera código de conexão para um paciente
   */
  async generateConnectionCode(
    patientId: string,
    clinicId: string,
    generatedById: string,
  ) {
    // Verifica se paciente existe e pertence à clínica
    const patient = await this.prisma.patient.findFirst({
      where: { id: patientId, clinicId },
      include: {
        user: { select: { name: true, email: true } },
      },
    });

    if (!patient) {
      throw new NotFoundException('Paciente não encontrado nesta clínica');
    }

    // Invalida códigos pendentes anteriores do mesmo paciente
    await this.prisma.patientConnection.updateMany({
      where: {
        patientId,
        status: ConnectionStatus.PENDING,
      },
      data: {
        status: ConnectionStatus.EXPIRED,
      },
    });

    // Gera código único
    let code: string;
    let isUnique = false;
    let attempts = 0;
    const maxAttempts = 10;

    while (!isUnique && attempts < maxAttempts) {
      code = this.generateCode();
      const existing = await this.prisma.patientConnection.findUnique({
        where: { connectionCode: code },
      });
      isUnique = !existing;
      attempts++;
    }

    if (!isUnique) {
      throw new ConflictException(
        'Não foi possível gerar código único. Tente novamente.',
      );
    }

    // Código expira em 24 horas
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 24);

    const connection = await this.prisma.patientConnection.create({
      data: {
        patientId,
        clinicId,
        connectionCode: code!,
        status: ConnectionStatus.PENDING,
        codeExpiresAt: expiresAt,
        generatedById,
      },
    });

    return {
      connectionCode: connection.connectionCode,
      expiresAt: connection.codeExpiresAt,
      patientId: patient.id,
      patientName: patient.user?.name || patient.name || 'Paciente',
    };
  }

  /**
   * Paciente usa código para conectar sua conta ao registro de Patient
   */
  async connectWithCode(connectionCode: string, userId: string) {
    const code = connectionCode.toUpperCase().trim();

    // Busca conexão pelo código
    const connection = await this.prisma.patientConnection.findUnique({
      where: { connectionCode: code },
      include: {
        patient: {
          include: {
            user: { select: { id: true, name: true, email: true } },
          },
        },
        clinic: { select: { id: true, name: true } },
      },
    });

    if (!connection) {
      throw new NotFoundException('Código de conexão inválido');
    }

    // Valida status
    if (connection.status !== ConnectionStatus.PENDING) {
      if (connection.status === ConnectionStatus.ACTIVE) {
        throw new BadRequestException('Este código já foi utilizado');
      }
      if (connection.status === ConnectionStatus.EXPIRED) {
        throw new BadRequestException('Este código expirou');
      }
      if (connection.status === ConnectionStatus.REVOKED) {
        throw new BadRequestException('Este código foi revogado');
      }
      throw new BadRequestException('Código não está disponível para uso');
    }

    // Valida expiração
    if (new Date() > connection.codeExpiresAt) {
      await this.prisma.patientConnection.update({
        where: { id: connection.id },
        data: { status: ConnectionStatus.EXPIRED },
      });
      throw new BadRequestException('Este código expirou');
    }

    // Verifica se o Patient já está vinculado a outro User
    if (connection.patient.user && connection.patient.user.id !== userId) {
      throw new ConflictException(
        'Este paciente já está vinculado a outra conta',
      );
    }

    // Verifica se o User já está vinculado a outro Patient
    const existingPatient = await this.prisma.patient.findUnique({
      where: { userId },
    });

    if (existingPatient && existingPatient.id !== connection.patientId) {
      throw new ConflictException(
        'Sua conta já está conectada a outro paciente',
      );
    }

    // Transação: vincula User ao Patient e marca conexão como ativa
    await this.prisma.$transaction(async (tx) => {
      // Atualiza Patient com userId (se ainda não estiver vinculado)
      await tx.patient.update({
        where: { id: connection.patientId },
        data: { userId },
      });

      // Atualiza User com clinicId e role PATIENT
      await tx.user.update({
        where: { id: userId },
        data: {
          clinicId: connection.clinicId,
          role: 'PATIENT',
        },
      });

      // Marca conexão como ativa
      await tx.patientConnection.update({
        where: { id: connection.id },
        data: {
          status: ConnectionStatus.ACTIVE,
          connectedAt: new Date(),
        },
      });
    });

    return {
      success: true,
      clinicId: connection.clinic.id,
      clinicName: connection.clinic.name,
      patientId: connection.patientId,
    };
  }

  /**
   * Admin revoga um código de conexão
   */
  async revokeConnectionCode(connectionId: string, clinicId: string) {
    const connection = await this.prisma.patientConnection.findFirst({
      where: { id: connectionId, clinicId },
    });

    if (!connection) {
      throw new NotFoundException('Conexão não encontrada');
    }

    if (connection.status !== ConnectionStatus.PENDING) {
      throw new BadRequestException(
        'Apenas códigos pendentes podem ser revogados',
      );
    }

    await this.prisma.patientConnection.update({
      where: { id: connectionId },
      data: {
        status: ConnectionStatus.REVOKED,
        revokedAt: new Date(),
      },
    });

    return { success: true };
  }

  /**
   * Lista conexões de um paciente
   */
  async getPatientConnections(patientId: string, clinicId: string) {
    return this.prisma.patientConnection.findMany({
      where: { patientId, clinicId },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        connectionCode: true,
        status: true,
        codeGeneratedAt: true,
        codeExpiresAt: true,
        connectedAt: true,
        generatedBy: {
          select: { name: true },
        },
      },
    });
  }

  /**
   * Lista todas as conexões da clínica (admin)
   */
  async getClinicConnections(clinicId: string, query: ConnectionListQueryDto) {
    const { page = 1, limit = 20, status, patientId } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.PatientConnectionWhereInput = {
      clinicId,
      ...(status && { status }),
      ...(patientId && { patientId }),
    };

    const [items, total] = await Promise.all([
      this.prisma.patientConnection.findMany({
        where,
        include: {
          patient: {
            select: {
              id: true,
              name: true,
              user: { select: { name: true } },
            },
          },
          generatedBy: {
            select: { name: true },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.patientConnection.count({ where }),
    ]);

    const mappedItems = items.map((conn) => ({
      id: conn.id,
      connectionCode: conn.connectionCode,
      status: conn.status,
      patientId: conn.patientId,
      patientName: conn.patient.user?.name || conn.patient.name || 'Paciente',
      clinicId: conn.clinicId,
      codeGeneratedAt: conn.codeGeneratedAt,
      codeExpiresAt: conn.codeExpiresAt,
      connectedAt: conn.connectedAt,
      revokedAt: conn.revokedAt,
      generatedByName: conn.generatedBy?.name,
      createdAt: conn.createdAt,
    }));

    return {
      items: mappedItems,
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    };
  }

  /**
   * Estatísticas de conexões da clínica
   */
  async getConnectionStats(clinicId: string): Promise<ConnectionStatsDto> {
    const whereClinic = { clinicId };

    const [
      totalConnections,
      pendingConnections,
      activeConnections,
      expiredConnections,
      revokedConnections,
    ] = await Promise.all([
      this.prisma.patientConnection.count({ where: whereClinic }),
      this.prisma.patientConnection.count({
        where: { ...whereClinic, status: ConnectionStatus.PENDING },
      }),
      this.prisma.patientConnection.count({
        where: { ...whereClinic, status: ConnectionStatus.ACTIVE },
      }),
      this.prisma.patientConnection.count({
        where: { ...whereClinic, status: ConnectionStatus.EXPIRED },
      }),
      this.prisma.patientConnection.count({
        where: { ...whereClinic, status: ConnectionStatus.REVOKED },
      }),
    ]);

    return {
      totalConnections,
      pendingConnections,
      activeConnections,
      expiredConnections,
      revokedConnections,
    };
  }
}
