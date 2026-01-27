import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AppointmentStatus, Appointment } from '@prisma/client';
import { CreateAllergyDto, CreateMedicalNoteDto, UpdatePatientDto, InvitePatientDto } from './dto';

@Injectable()
export class PatientsService {
  constructor(private prisma: PrismaService) {}

  /**
   * Lista pacientes da clínica com filtros e paginação
   */
  async getPatients(
    clinicId: string,
    page: number = 1,
    limit: number = 20,
    search?: string,
    status?: string,
  ) {
    // Validar clinicId
    if (!clinicId) {
      throw new NotFoundException('Clínica não encontrada. Verifique se você está associado a uma clínica.');
    }

    const skip = (page - 1) * limit;
    const now = new Date();

    // Construir filtro base
    const where: any = {
      clinicId,
    };

    // Filtro por busca (nome ou email) - busca nos campos do paciente E do usuário
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
        { user: { name: { contains: search, mode: 'insensitive' } } },
        { user: { email: { contains: search, mode: 'insensitive' } } },
      ];
    }

    // Filtro por status
    if (status) {
      switch (status) {
        case 'RECOVERY':
          // Pacientes com surgeryDate definida e menos de 90 dias pós-op
          where.surgeryDate = { not: null };
          where.surgeryDate = {
            gte: new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000),
          };
          break;
        case 'COMPLETED':
          // Pacientes com surgeryDate há mais de 90 dias
          where.surgeryDate = {
            lt: new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000),
          };
          break;
        case 'ACTIVE':
          // Pacientes ativos (sem filtro adicional)
          break;
      }
    }

    // Buscar pacientes
    const [patients, total] = await Promise.all([
      this.prisma.patient.findMany({
        where,
        skip,
        take: limit,
        orderBy: [{ surgeryDate: 'desc' }, { createdAt: 'desc' }],
        include: {
          user: {
            select: {
              id: true,
              name: true,
              email: true,
            },
          },
          appointments: {
            where: {
              status: {
                in: [AppointmentStatus.CONFIRMED, AppointmentStatus.PENDING],
              },
            },
            orderBy: { date: 'asc' },
            take: 1,
            select: {
              id: true,
              date: true,
              time: true,
              title: true,
              status: true,
            },
          },
        },
      }),
      this.prisma.patient.count({ where }),
    ]);

    // Mapear resposta
    const items = patients.map((patient) => {
      const dayPostOp = patient.surgeryDate
        ? Math.floor(
            (now.getTime() - new Date(patient.surgeryDate).getTime()) /
              (1000 * 60 * 60 * 24),
          )
        : null;

      let patientStatus = 'ACTIVE';
      if (dayPostOp !== null) {
        patientStatus = dayPostOp > 90 ? 'COMPLETED' : 'RECOVERY';
      }

      const nextAppointment = patient.appointments[0];

      return {
        id: patient.id,
        name: patient.user?.name || patient.name || 'Nome não informado',
        email: patient.user?.email || patient.email || '',
        phone: patient.phone,
        surgeryType: patient.surgeryType || 'Não informado',
        surgeryDate: patient.surgeryDate?.toISOString() || null,
        dayPostOp,
        status: patientStatus,
        nextAppointment: nextAppointment
          ? {
              id: nextAppointment.id,
              date: nextAppointment.date.toISOString(),
              time: nextAppointment.time,
              title: nextAppointment.title,
            }
          : null,
      };
    });

    return {
      items,
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    };
  }

  /**
   * Busca detalhes completos de um paciente
   */
  async getPatientById(patientId: string, clinicId: string) {
    const patient = await this.prisma.patient.findFirst({
      where: {
        id: patientId,
        clinicId,
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
        appointments: {
          orderBy: { date: 'desc' },
          take: 10,
          select: {
            id: true,
            title: true,
            description: true,
            date: true,
            time: true,
            type: true,
            status: true,
            location: true,
          },
        },
        allergies: {
          orderBy: { createdAt: 'desc' },
          select: {
            id: true,
            name: true,
            severity: true,
            notes: true,
            createdAt: true,
          },
        },
        medicalNotes: {
          orderBy: { createdAt: 'desc' },
          take: 20,
          select: {
            id: true,
            content: true,
            author: true,
            authorId: true,
            createdAt: true,
          },
        },
        alerts: {
          where: { status: 'ACTIVE' },
          orderBy: { createdAt: 'desc' },
          take: 5,
          select: {
            id: true,
            type: true,
            title: true,
            description: true,
            createdAt: true,
          },
        },
        trainingProgress: {
          orderBy: { createdAt: 'desc' },
          take: 1,
          include: {
            week: {
              select: {
                weekNumber: true,
                sessions: {
                  select: { id: true },
                },
              },
            },
          },
        },
        sessionCompletions: {
          orderBy: { completedAt: 'desc' },
          take: 20,
        },
      },
    });

    if (!patient) {
      throw new NotFoundException('Paciente não encontrado');
    }

    const now = new Date();
    const dayPostOp = patient.surgeryDate
      ? Math.floor(
          (now.getTime() - new Date(patient.surgeryDate).getTime()) /
            (1000 * 60 * 60 * 24),
        )
      : null;

    const weekPostOp =
      dayPostOp !== null ? Math.floor(dayPostOp / 7) + 1 : null;

    // Calcular taxa de adesão (simplificado - baseado em sessões completadas)
    let adherenceRate = 0;
    if (
      patient.trainingProgress &&
      patient.trainingProgress.length > 0 &&
      patient.trainingProgress[0].week
    ) {
      const totalSessions =
        patient.trainingProgress[0].week.sessions?.length || 0;
      const completedSessions = patient.sessionCompletions?.length || 0;
      if (totalSessions > 0) {
        adherenceRate = Math.min(
          100,
          Math.round((completedSessions / totalSessions) * 100),
        );
      }
    }

    // Separar consultas por status
    const upcomingAppointments = patient.appointments.filter(
      (apt: Appointment) =>
        apt.status === AppointmentStatus.CONFIRMED ||
        apt.status === AppointmentStatus.PENDING,
    );

    const pastAppointments = patient.appointments.filter(
      (apt: Appointment) =>
        apt.status === AppointmentStatus.COMPLETED ||
        apt.status === AppointmentStatus.CANCELLED,
    );

    return {
      id: patient.id,
      name: patient.user?.name || patient.name || 'Nome não informado',
      email: patient.user?.email || patient.email || '',
      phone: patient.phone,
      birthDate: patient.birthDate?.toISOString() || null,
      cpf: patient.cpf,
      address: null,
      surgeryType: patient.surgeryType || 'Não informado',
      surgeryDate: patient.surgeryDate?.toISOString() || null,
      surgeon: patient.surgeon || null,
      dayPostOp,
      weekPostOp,
      adherenceRate,
      // Novos campos do schema
      bloodType: patient.bloodType,
      weightKg: patient.weightKg,
      heightCm: patient.heightCm,
      emergencyContact: patient.emergencyContact,
      emergencyPhone: patient.emergencyPhone,
      // Alergias do banco
      allergies: patient.allergies.map((allergy: any) => ({
        id: allergy.id,
        name: allergy.name,
        severity: allergy.severity,
        notes: allergy.notes,
        createdAt: allergy.createdAt.toISOString(),
      })),
      // Notas médicas do banco
      medicalNotes: patient.medicalNotes.map((note: any) => ({
        id: note.id,
        content: note.content,
        author: note.author,
        authorId: note.authorId,
        createdAt: note.createdAt.toISOString(),
      })),
      upcomingAppointments: upcomingAppointments.map((apt: any) => ({
        id: apt.id,
        title: apt.title,
        description: apt.description,
        date: apt.date.toISOString(),
        time: apt.time,
        type: apt.type,
        status: apt.status,
        location: apt.location,
      })),
      pastAppointments: pastAppointments.map((apt: any) => ({
        id: apt.id,
        title: apt.title,
        date: apt.date.toISOString(),
        time: apt.time,
        type: apt.type,
        status: apt.status,
      })),
      recentAlerts: patient.alerts.map((alert: any) => ({
        id: alert.id,
        type: alert.type,
        title: alert.title,
        description: alert.description,
        createdAt: alert.createdAt.toISOString(),
      })),
    };
  }

  /**
   * Busca consultas de um paciente específico
   */
  async getPatientAppointments(
    patientId: string,
    clinicId: string,
    status?: string,
    page: number = 1,
    limit: number = 10,
  ) {
    const skip = (page - 1) * limit;

    // Verificar se paciente pertence à clínica
    const patient = await this.prisma.patient.findFirst({
      where: { id: patientId, clinicId },
    });

    if (!patient) {
      throw new NotFoundException('Paciente não encontrado');
    }

    const where: any = { patientId };

    if (status) {
      where.status = status;
    }

    const [appointments, total] = await Promise.all([
      this.prisma.appointment.findMany({
        where,
        skip,
        take: limit,
        orderBy: { date: 'desc' },
        select: {
          id: true,
          title: true,
          description: true,
          date: true,
          time: true,
          type: true,
          status: true,
          location: true,
          notes: true,
          createdAt: true,
        },
      }),
      this.prisma.appointment.count({ where }),
    ]);

    return {
      items: appointments.map((apt) => ({
        id: apt.id,
        title: apt.title,
        description: apt.description,
        date: apt.date.toISOString(),
        time: apt.time,
        type: apt.type,
        status: apt.status,
        location: apt.location,
        notes: apt.notes,
        displayDate: apt.date.toLocaleDateString('pt-BR'),
        displayTime: apt.time,
      })),
      page,
      limit,
      total,
    };
  }

  // ==================== ALERGIAS ====================

  /**
   * Adiciona uma alergia ao paciente
   */
  async addAllergy(
    patientId: string,
    clinicId: string,
    dto: CreateAllergyDto,
  ) {
    // Verificar se paciente pertence à clínica
    const patient = await this.prisma.patient.findFirst({
      where: { id: patientId, clinicId },
    });

    if (!patient) {
      throw new NotFoundException('Paciente não encontrado');
    }

    const allergy = await this.prisma.patientAllergy.create({
      data: {
        patientId,
        name: dto.name,
        severity: dto.severity,
        notes: dto.notes,
      },
    });

    return {
      id: allergy.id,
      name: allergy.name,
      severity: allergy.severity,
      notes: allergy.notes,
      createdAt: allergy.createdAt.toISOString(),
    };
  }

  /**
   * Remove uma alergia do paciente
   */
  async removeAllergy(
    patientId: string,
    allergyId: string,
    clinicId: string,
  ) {
    // Verificar se paciente pertence à clínica
    const patient = await this.prisma.patient.findFirst({
      where: { id: patientId, clinicId },
    });

    if (!patient) {
      throw new NotFoundException('Paciente não encontrado');
    }

    // Verificar se alergia existe e pertence ao paciente
    const allergy = await this.prisma.patientAllergy.findFirst({
      where: { id: allergyId, patientId },
    });

    if (!allergy) {
      throw new NotFoundException('Alergia não encontrada');
    }

    await this.prisma.patientAllergy.delete({
      where: { id: allergyId },
    });

    return { message: 'Alergia removida com sucesso' };
  }

  /**
   * Lista alergias de um paciente
   */
  async getAllergies(patientId: string, clinicId: string) {
    // Verificar se paciente pertence à clínica
    const patient = await this.prisma.patient.findFirst({
      where: { id: patientId, clinicId },
    });

    if (!patient) {
      throw new NotFoundException('Paciente não encontrado');
    }

    const allergies = await this.prisma.patientAllergy.findMany({
      where: { patientId },
      orderBy: { createdAt: 'desc' },
    });

    return allergies.map((a) => ({
      id: a.id,
      name: a.name,
      severity: a.severity,
      notes: a.notes,
      createdAt: a.createdAt.toISOString(),
    }));
  }

  // ==================== NOTAS MÉDICAS ====================

  /**
   * Adiciona uma nota médica ao paciente
   */
  async addMedicalNote(
    patientId: string,
    clinicId: string,
    dto: CreateMedicalNoteDto,
    authorId?: string,
  ) {
    // Verificar se paciente pertence à clínica
    const patient = await this.prisma.patient.findFirst({
      where: { id: patientId, clinicId },
    });

    if (!patient) {
      throw new NotFoundException('Paciente não encontrado');
    }

    const note = await this.prisma.medicalNote.create({
      data: {
        patientId,
        content: dto.content,
        author: dto.author,
        authorId,
      },
    });

    return {
      id: note.id,
      content: note.content,
      author: note.author,
      authorId: note.authorId,
      createdAt: note.createdAt.toISOString(),
    };
  }

  /**
   * Remove uma nota médica do paciente
   */
  async removeMedicalNote(
    patientId: string,
    noteId: string,
    clinicId: string,
  ) {
    // Verificar se paciente pertence à clínica
    const patient = await this.prisma.patient.findFirst({
      where: { id: patientId, clinicId },
    });

    if (!patient) {
      throw new NotFoundException('Paciente não encontrado');
    }

    // Verificar se nota existe e pertence ao paciente
    const note = await this.prisma.medicalNote.findFirst({
      where: { id: noteId, patientId },
    });

    if (!note) {
      throw new NotFoundException('Nota médica não encontrada');
    }

    await this.prisma.medicalNote.delete({
      where: { id: noteId },
    });

    return { message: 'Nota médica removida com sucesso' };
  }

  /**
   * Lista notas médicas de um paciente
   */
  async getMedicalNotes(
    patientId: string,
    clinicId: string,
    page: number = 1,
    limit: number = 20,
  ) {
    const skip = (page - 1) * limit;

    // Verificar se paciente pertence à clínica
    const patient = await this.prisma.patient.findFirst({
      where: { id: patientId, clinicId },
    });

    if (!patient) {
      throw new NotFoundException('Paciente não encontrado');
    }

    const [notes, total] = await Promise.all([
      this.prisma.medicalNote.findMany({
        where: { patientId },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.medicalNote.count({ where: { patientId } }),
    ]);

    return {
      items: notes.map((n) => ({
        id: n.id,
        content: n.content,
        author: n.author,
        authorId: n.authorId,
        createdAt: n.createdAt.toISOString(),
      })),
      page,
      limit,
      total,
    };
  }

  // ==================== HISTÓRICO ====================

  /**
   * Busca histórico completo do paciente (consultas, notas, alertas)
   */
  async getPatientHistory(
    patientId: string,
    clinicId: string,
    page: number = 1,
    limit: number = 20,
  ) {
    // Verificar se paciente pertence à clínica
    const patient = await this.prisma.patient.findFirst({
      where: { id: patientId, clinicId },
      include: {
        user: {
          select: { name: true },
        },
      },
    });

    if (!patient) {
      throw new NotFoundException('Paciente não encontrado');
    }

    // Buscar todas as consultas
    const appointments = await this.prisma.appointment.findMany({
      where: { patientId },
      orderBy: { date: 'desc' },
      select: {
        id: true,
        title: true,
        description: true,
        date: true,
        time: true,
        type: true,
        status: true,
        location: true,
        notes: true,
        createdAt: true,
      },
    });

    // Buscar todas as notas médicas
    const medicalNotes = await this.prisma.medicalNote.findMany({
      where: { patientId },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        content: true,
        author: true,
        createdAt: true,
      },
    });

    // Buscar alertas (resolvidos também)
    const alerts = await this.prisma.alert.findMany({
      where: { patientId },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        type: true,
        title: true,
        description: true,
        status: true,
        createdAt: true,
        resolvedAt: true,
      },
    });

    // Combinar e ordenar por data
    const historyItems: any[] = [];

    appointments.forEach((apt) => {
      historyItems.push({
        type: 'appointment',
        date: apt.date.toISOString(),
        data: {
          id: apt.id,
          title: apt.title,
          description: apt.description,
          time: apt.time,
          appointmentType: apt.type,
          status: apt.status,
          location: apt.location,
          notes: apt.notes,
        },
      });
    });

    medicalNotes.forEach((note) => {
      historyItems.push({
        type: 'medical_note',
        date: note.createdAt.toISOString(),
        data: {
          id: note.id,
          content: note.content,
          author: note.author,
        },
      });
    });

    alerts.forEach((alert) => {
      historyItems.push({
        type: 'alert',
        date: alert.createdAt.toISOString(),
        data: {
          id: alert.id,
          alertType: alert.type,
          title: alert.title,
          description: alert.description,
          status: alert.status,
          resolvedAt: alert.resolvedAt?.toISOString(),
        },
      });
    });

    // Ordenar por data (mais recente primeiro)
    historyItems.sort(
      (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime(),
    );

    // Paginar
    const skip = (page - 1) * limit;
    const paginatedItems = historyItems.slice(skip, skip + limit);

    return {
      patientName: patient.user?.name || patient.name || 'Nome não informado',
      items: paginatedItems,
      page,
      limit,
      total: historyItems.length,
      totalPages: Math.ceil(historyItems.length / limit),
    };
  }

  // ==================== ATUALIZAR PACIENTE ====================

  /**
   * Atualiza dados do paciente
   */
  async updatePatient(
    patientId: string,
    clinicId: string,
    dto: UpdatePatientDto,
  ) {
    // Verificar se paciente pertence à clínica
    const patient = await this.prisma.patient.findFirst({
      where: { id: patientId, clinicId },
    });

    if (!patient) {
      throw new NotFoundException('Paciente não encontrado');
    }

    const updated = await this.prisma.patient.update({
      where: { id: patientId },
      data: {
        phone: dto.phone,
        bloodType: dto.bloodType,
        weightKg: dto.weightKg,
        heightCm: dto.heightCm,
        emergencyContact: dto.emergencyContact,
        emergencyPhone: dto.emergencyPhone,
        surgeryType: dto.surgeryType,
        surgeryDate: dto.surgeryDate ? new Date(dto.surgeryDate) : undefined,
        surgeon: dto.surgeon,
      },
      include: {
        user: {
          select: { name: true, email: true },
        },
      },
    });

    return {
      id: updated.id,
      name: updated.user?.name || updated.name,
      email: updated.user?.email || updated.email,
      phone: updated.phone,
      bloodType: updated.bloodType,
      weightKg: updated.weightKg,
      heightCm: updated.heightCm,
      emergencyContact: updated.emergencyContact,
      emergencyPhone: updated.emergencyPhone,
      surgeryType: updated.surgeryType,
      surgeryDate: updated.surgeryDate?.toISOString() || null,
      surgeon: updated.surgeon,
    };
  }

  // ==================== CONVITE DE PACIENTE ====================

  /**
   * Cria paciente via convite do admin (pré-cadastro antes do Magic Link)
   * Cria o registro Patient sem userId (será vinculado quando paciente acessar)
   * Se surgeryDate for informada, cria agendamento da cirurgia automaticamente
   */
  async invitePatient(clinicId: string, dto: InvitePatientDto) {
    // Verificar se já existe paciente com este email na clínica
    const existingPatient = await this.prisma.patient.findFirst({
      where: {
        email: dto.email,
        clinicId,
      },
    });

    if (existingPatient) {
      throw new ConflictException('Já existe um paciente com este email nesta clínica');
    }

    // Criar paciente e agendamento em uma transação
    const result = await this.prisma.$transaction(async (tx) => {
      // Criar paciente (sem userId - será vinculado depois)
      const patient = await tx.patient.create({
        data: {
          name: dto.name,
          email: dto.email,
          phone: dto.phone,
          clinicId,
          surgeryDate: dto.surgeryDate ? new Date(dto.surgeryDate) : null,
          surgeryType: dto.surgeryType,
        },
      });

      let surgeryAppointment = null;

      // Se tem data de cirurgia, criar agendamento automaticamente
      if (dto.surgeryDate) {
        const surgeryDate = new Date(dto.surgeryDate);

        surgeryAppointment = await tx.appointment.create({
          data: {
            patientId: patient.id,
            clinicId,
            title: 'Cirurgia',
            description: dto.surgeryType
              ? `Cirurgia: ${dto.surgeryType}`
              : 'Procedimento cirúrgico agendado',
            date: surgeryDate,
            time: '08:00', // Horário padrão para cirurgias
            duration: 120, // 2 horas padrão
            type: 'SURGERY',
            status: AppointmentStatus.CONFIRMED, // Cirurgia já confirmada pelo admin
            notes: 'Agendamento criado automaticamente no cadastro do paciente',
          },
        });
      }

      return { patient, surgeryAppointment };
    });

    return {
      patient: {
        id: result.patient.id,
        name: result.patient.name,
        email: result.patient.email,
        phone: result.patient.phone,
        surgeryDate: result.patient.surgeryDate?.toISOString() || null,
        surgeryType: result.patient.surgeryType,
      },
      surgeryAppointment: result.surgeryAppointment
        ? {
            id: result.surgeryAppointment.id,
            date: result.surgeryAppointment.date.toISOString(),
            time: result.surgeryAppointment.time,
            title: result.surgeryAppointment.title,
            status: result.surgeryAppointment.status,
          }
        : null,
      message: 'Paciente criado com sucesso. Envie o Magic Link para acesso.',
    };
  }

  /**
   * Vincula um paciente existente a um userId (quando paciente acessa via Magic Link)
   */
  async linkPatientToUser(email: string, userId: string, clinicId: string) {
    // Buscar paciente pelo email na clínica
    const patient = await this.prisma.patient.findFirst({
      where: {
        email,
        clinicId,
        userId: null, // Ainda não vinculado
      },
    });

    if (!patient) {
      return null; // Não encontrou paciente pré-cadastrado
    }

    // Vincular ao userId
    const updated = await this.prisma.patient.update({
      where: { id: patient.id },
      data: { userId },
    });

    return {
      id: updated.id,
      name: updated.name,
      email: updated.email,
      surgeryDate: updated.surgeryDate?.toISOString() || null,
    };
  }
}
