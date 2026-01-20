import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';
import { v4 as uuidv4 } from 'uuid';
import { PrismaService } from '../../prisma/prisma.service';
import { LoginDto, RegisterDto, UpdateProfileDto, ChangePasswordDto, ForgotPasswordDto, ResetPasswordDto } from './dto';
import { UserRole } from '@prisma/client';
import { LoggerService } from '../../common/services/logger.service';

export interface AuthResponse {
  user: {
    id: string;
    name: string;
    email: string;
    role: UserRole;
    clinicId?: string;
    patientId?: string;
  };
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
    private logger: LoggerService,
  ) {}

  async register(dto: RegisterDto): Promise<AuthResponse> {
    const existingUser = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (existingUser) {
      throw new ConflictException('Email já está em uso');
    }

    const hashedPassword = await bcrypt.hash(dto.password, 10);
    const role = dto.role || UserRole.PATIENT;

    // clinicId é obrigatório (validado pelo DTO)
    const result = await this.prisma.user.create({
      data: {
        name: dto.name,
        email: dto.email,
        passwordHash: hashedPassword,
        role: role,
        clinicId: dto.clinicId,
      },
    });

    return await this.generateAuthResponse(result);
  }

  // Configurações de Account Lockout
  private readonly MAX_FAILED_ATTEMPTS = 5;
  private readonly LOCKOUT_DURATION_MINUTES = 15;

  async login(dto: LoginDto, ipAddress?: string, userAgent?: string): Promise<AuthResponse> {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    // Se usuário não existe, registrar tentativa e retornar erro genérico
    if (!user) {
      await this.recordLoginAttempt(null, dto.email, false, 'user_not_found', ipAddress, userAgent);
      throw new UnauthorizedException('Credenciais inválidas');
    }

    // Verificar se a conta está bloqueada
    if (user.lockedUntil && new Date() < user.lockedUntil) {
      const remainingMinutes = Math.ceil((user.lockedUntil.getTime() - Date.now()) / 60000);
      await this.recordLoginAttempt(user.id, dto.email, false, 'account_locked', ipAddress, userAgent);
      throw new UnauthorizedException(
        `Conta bloqueada temporariamente. Tente novamente em ${remainingMinutes} minuto(s).`
      );
    }

    // Verificar senha
    const isPasswordValid = await bcrypt.compare(dto.password, user.passwordHash);

    if (!isPasswordValid) {
      // Incrementar contador de falhas
      const newFailedAttempts = user.failedLoginAttempts + 1;
      const shouldLock = newFailedAttempts >= this.MAX_FAILED_ATTEMPTS;

      await this.prisma.user.update({
        where: { id: user.id },
        data: {
          failedLoginAttempts: newFailedAttempts,
          lockedUntil: shouldLock
            ? new Date(Date.now() + this.LOCKOUT_DURATION_MINUTES * 60 * 1000)
            : null,
        },
      });

      await this.recordLoginAttempt(user.id, dto.email, false, 'invalid_password', ipAddress, userAgent);

      if (shouldLock) {
        throw new UnauthorizedException(
          `Conta bloqueada por ${this.LOCKOUT_DURATION_MINUTES} minutos após múltiplas tentativas incorretas.`
        );
      }

      const attemptsRemaining = this.MAX_FAILED_ATTEMPTS - newFailedAttempts;
      throw new UnauthorizedException(
        `Credenciais inválidas. ${attemptsRemaining} tentativa(s) restante(s).`
      );
    }

    // Login bem-sucedido: resetar contador de falhas
    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        failedLoginAttempts: 0,
        lockedUntil: null,
      },
    });

    await this.recordLoginAttempt(user.id, dto.email, true, null, ipAddress, userAgent);

    return await this.generateAuthResponse(user);
  }

  /**
   * Registra tentativa de login para auditoria
   */
  private async recordLoginAttempt(
    userId: string | null,
    email: string,
    success: boolean,
    failReason: string | null,
    ipAddress?: string,
    userAgent?: string,
  ) {
    await this.prisma.loginAttempt.create({
      data: {
        userId,
        email,
        success,
        failReason,
        ipAddress: ipAddress || null,
        userAgent: userAgent || null,
      },
    });
  }

  /**
   * Desbloqueia uma conta manualmente (para admin)
   */
  async unlockAccount(userId: string): Promise<{ success: boolean }> {
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        failedLoginAttempts: 0,
        lockedUntil: null,
      },
    });
    return { success: true };
  }

  async validateUser(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        clinicId: true,
        clinic: {
          select: {
            name: true,
          },
        },
        patient: {
          select: {
            id: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('Usuário não encontrado');
    }

    // Flatten clinic name and patientId for easier frontend consumption
    return {
      ...user,
      clinicName: user.clinic?.name ?? null,
      patientId: user.patient?.id ?? null,
    };
  }

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        clinicId: true,
        createdAt: true,
        updatedAt: true,
        clinic: {
          select: {
            name: true,
          },
        },
        patient: {
          select: {
            id: true,
            cpf: true,
            phone: true,
            birthDate: true,
            surgeryDate: true,
            surgeryType: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('Usuário não encontrado');
    }

    // Flatten clinic name for easier frontend consumption
    return {
      ...user,
      clinicName: user.clinic?.name ?? null,
    };
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { patient: true },
    });

    if (!user) {
      throw new NotFoundException('Usuário não encontrado');
    }

    // Usar transação para atualizar usuário e paciente
    const result = await this.prisma.$transaction(async (tx) => {
      // Atualizar nome do usuário se informado
      if (dto.name) {
        await tx.user.update({
          where: { id: userId },
          data: { name: dto.name },
        });
      }

      // Atualizar dados do paciente se existir
      if (user.patient) {
        const patientData: any = {};

        if (dto.phone !== undefined) patientData.phone = dto.phone;
        if (dto.cpf !== undefined) patientData.cpf = dto.cpf;
        if (dto.birthDate !== undefined)
          patientData.birthDate = new Date(dto.birthDate);
        if (dto.surgeryDate !== undefined)
          patientData.surgeryDate = new Date(dto.surgeryDate);
        if (dto.surgeryType !== undefined)
          patientData.surgeryType = dto.surgeryType;

        if (Object.keys(patientData).length > 0) {
          await tx.patient.update({
            where: { id: user.patient.id },
            data: patientData,
          });
        }
      }

      // Retornar perfil atualizado
      return tx.user.findUnique({
        where: { id: userId },
        select: {
          id: true,
          name: true,
          email: true,
          role: true,
          clinicId: true,
          patient: {
            select: {
              id: true,
              cpf: true,
              phone: true,
              birthDate: true,
              surgeryDate: true,
              surgeryType: true,
            },
          },
        },
      });
    });

    return result;
  }

  async changePassword(userId: string, dto: ChangePasswordDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('Usuário não encontrado');
    }

    // Verificar senha atual
    const isPasswordValid = await bcrypt.compare(
      dto.currentPassword,
      user.passwordHash,
    );

    if (!isPasswordValid) {
      throw new UnauthorizedException('Senha atual incorreta');
    }

    // Hash da nova senha
    const hashedPassword = await bcrypt.hash(dto.newPassword, 10);

    // Atualizar senha
    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash: hashedPassword },
    });

    return { message: 'Senha alterada com sucesso' };
  }

  /**
   * Renova tokens usando refresh token
   */
  async refreshTokens(refreshToken: string): Promise<AuthResponse> {
    const tokenHash = crypto
      .createHash('sha256')
      .update(refreshToken)
      .digest('hex');

    const storedToken = await this.prisma.refreshToken.findUnique({
      where: { token: tokenHash },
      include: { user: true },
    });

    if (!storedToken) {
      throw new UnauthorizedException('Refresh token inválido');
    }

    if (storedToken.revokedAt) {
      throw new UnauthorizedException('Refresh token foi revogado');
    }

    if (new Date() > storedToken.expiresAt) {
      throw new UnauthorizedException('Refresh token expirou');
    }

    // Rotação: revoga token atual
    await this.prisma.refreshToken.update({
      where: { id: storedToken.id },
      data: { revokedAt: new Date() },
    });

    // Gera novo par de tokens
    const user = storedToken.user;
    return await this.generateAuthResponse({
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      clinicId: user.clinicId,
    });
  }

  /**
   * Revoga todos os refresh tokens de um usuário (logout)
   */
  async revokeAllRefreshTokens(userId: string): Promise<{ success: boolean }> {
    await this.prisma.refreshToken.updateMany({
      where: {
        userId,
        revokedAt: null,
      },
      data: { revokedAt: new Date() },
    });

    return { success: true };
  }

  /**
   * Limpa tokens expirados (pode ser chamado por cron job)
   */
  async cleanupExpiredTokens(): Promise<{ deleted: number }> {
    const result = await this.prisma.refreshToken.deleteMany({
      where: {
        OR: [
          { expiresAt: { lt: new Date() } },
          { revokedAt: { not: null } },
        ],
      },
    });

    return { deleted: result.count };
  }

  // ==================== PASSWORD RESET ====================

  /**
   * Solicita reset de senha - gera token e retorna (em producao, enviaria por email)
   * POST /api/auth/forgot-password
   */
  async forgotPassword(dto: ForgotPasswordDto): Promise<{ message: string; resetToken?: string }> {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    // IMPORTANTE: Sempre retornar sucesso para evitar enumeracao de emails
    if (!user) {
      this.logger.authEvent('password_reset', { email: dto.email, status: 'user_not_found' });
      return {
        message: 'Se o email existir em nossa base, você receberá instruções para redefinir sua senha.',
      };
    }

    // Invalidar tokens anteriores nao usados
    await this.prisma.passwordResetToken.updateMany({
      where: {
        userId: user.id,
        usedAt: null,
      },
      data: {
        usedAt: new Date(), // Marca como usado para invalidar
      },
    });

    // Gerar novo token (6 caracteres alfanumericos para facilitar digitacao)
    const plainToken = this.generateResetCode();
    const tokenHash = crypto.createHash('sha256').update(plainToken).digest('hex');

    // Token expira em 1 hora
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 1);

    // Salvar token hasheado no banco
    await this.prisma.passwordResetToken.create({
      data: {
        userId: user.id,
        token: tokenHash,
        expiresAt,
      },
    });

    this.logger.authEvent('password_reset', { email: user.email, userId: user.id, status: 'token_generated' });

    // Em producao, enviaria o token por email
    // Por enquanto, retornamos o token para teste (REMOVER em producao!)
    return {
      message: 'Se o email existir em nossa base, você receberá instruções para redefinir sua senha.',
      // APENAS PARA DESENVOLVIMENTO - remover em producao
      resetToken: plainToken,
    };
  }

  /**
   * Valida token de reset (util para verificar antes de mostrar form)
   * POST /api/auth/validate-reset-token
   */
  async validateResetToken(token: string): Promise<{ valid: boolean; email?: string }> {
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

    const storedToken = await this.prisma.passwordResetToken.findUnique({
      where: { token: tokenHash },
      include: { user: { select: { email: true } } },
    });

    if (!storedToken) {
      return { valid: false };
    }

    if (storedToken.usedAt) {
      return { valid: false };
    }

    if (new Date() > storedToken.expiresAt) {
      return { valid: false };
    }

    return {
      valid: true,
      email: storedToken.user.email,
    };
  }

  /**
   * Reseta a senha usando o token
   * POST /api/auth/reset-password
   */
  async resetPassword(dto: ResetPasswordDto): Promise<{ message: string }> {
    const tokenHash = crypto.createHash('sha256').update(dto.token).digest('hex');

    const storedToken = await this.prisma.passwordResetToken.findUnique({
      where: { token: tokenHash },
      include: { user: true },
    });

    if (!storedToken) {
      throw new BadRequestException('Token inválido ou expirado');
    }

    if (storedToken.usedAt) {
      throw new BadRequestException('Este token já foi utilizado');
    }

    if (new Date() > storedToken.expiresAt) {
      throw new BadRequestException('Token expirado. Solicite um novo.');
    }

    // Hash da nova senha
    const hashedPassword = await bcrypt.hash(dto.newPassword, 10);

    // Atualizar senha e marcar token como usado
    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: storedToken.userId },
        data: { passwordHash: hashedPassword },
      }),
      this.prisma.passwordResetToken.update({
        where: { id: storedToken.id },
        data: { usedAt: new Date() },
      }),
      // Revogar todos os refresh tokens do usuario (logout de todas sessoes)
      this.prisma.refreshToken.updateMany({
        where: {
          userId: storedToken.userId,
          revokedAt: null,
        },
        data: { revokedAt: new Date() },
      }),
    ]);

    this.logger.authEvent('password_reset', {
      email: storedToken.user.email,
      userId: storedToken.userId,
      status: 'completed'
    });

    return { message: 'Senha redefinida com sucesso. Faça login com sua nova senha.' };
  }

  /**
   * Gera codigo de 6 caracteres alfanumericos (mais facil de digitar que UUID)
   */
  private generateResetCode(): string {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Sem I, O, 0, 1 para evitar confusao
    let code = '';
    for (let i = 0; i < 6; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
  }

  private async generateAuthResponse(user: {
    id: string;
    name: string;
    email: string;
    role: UserRole;
    clinicId: string | null;
  }, deviceInfo?: string): Promise<AuthResponse> {
    // Busca patientId se existir
    const patient = await this.prisma.patient.findUnique({
      where: { userId: user.id },
      select: { id: true },
    });

    const payload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      clinicId: user.clinicId,
      patientId: patient?.id,
    };

    // Access token: 15 minutos
    const accessToken = this.jwtService.sign(payload, { expiresIn: '15m' });
    const expiresInSeconds = 900; // 15 minutos

    // Gera refresh token
    const refreshTokenValue = uuidv4();
    const refreshTokenHash = crypto
      .createHash('sha256')
      .update(refreshTokenValue)
      .digest('hex');

    // Refresh token expira em 7 dias
    const refreshExpiresAt = new Date();
    refreshExpiresAt.setDate(refreshExpiresAt.getDate() + 7);

    // Salva refresh token no banco
    await this.prisma.refreshToken.create({
      data: {
        userId: user.id,
        token: refreshTokenHash,
        deviceInfo: deviceInfo || null,
        expiresAt: refreshExpiresAt,
      },
    });

    return {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        clinicId: user.clinicId || undefined,
        patientId: patient?.id,
      },
      accessToken,
      refreshToken: refreshTokenValue,
      expiresIn: expiresInSeconds,
    };
  }

  private parseExpirationToSeconds(expiration: string): number {
    const match = expiration.match(/^(\d+)([smhd])$/);
    if (!match) {
      return 86400; // Default: 24 hours
    }

    const value = parseInt(match[1], 10);
    const unit = match[2];

    switch (unit) {
      case 's':
        return value;
      case 'm':
        return value * 60;
      case 'h':
        return value * 3600;
      case 'd':
        return value * 86400;
      default:
        return 86400;
    }
  }

  // ==================== MAGIC LINK SYNC ====================

  /**
   * Sincroniza usuário que acessou via Magic Link do Supabase
   * Cria o usuário na tabela users se não existir e vincula ao Patient pré-cadastrado
   */
  async syncMagicLinkUser(dto: {
    authId: string;
    email: string;
    name?: string;
    clinicId?: string;
  }) {
    const { authId, email, name, clinicId } = dto;

    // 1. Verificar se usuário já existe pelo authId
    let user = await this.prisma.user.findFirst({
      where: { authId },
    });

    if (user) {
      this.logger.authEvent('magic_link_sync', { email, status: 'user_exists', userId: user.id });
      return {
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          clinicId: user.clinicId,
        },
        created: false,
      };
    }

    // 2. Verificar se existe usuário pelo email (migração)
    user = await this.prisma.user.findFirst({
      where: { email },
    });

    if (user) {
      // Atualiza o authId
      user = await this.prisma.user.update({
        where: { id: user.id },
        data: { authId },
      });

      this.logger.authEvent('magic_link_sync', { email, status: 'authId_linked', userId: user.id });
      return {
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          clinicId: user.clinicId,
        },
        created: false,
      };
    }

    // 3. Buscar Patient pré-cadastrado pelo email
    const patient = await this.prisma.patient.findFirst({
      where: {
        email,
        userId: null, // Ainda não vinculado
      },
    });

    // Determinar clinicId: do Patient, do parâmetro, ou usar clínica padrão
    let effectiveClinicId = patient?.clinicId || clinicId;

    // Se não tiver clinicId, buscar clínica padrão
    if (!effectiveClinicId) {
      const defaultClinic = await this.prisma.clinic.findFirst({
        where: { isActive: true },
        orderBy: { createdAt: 'asc' },
      });

      if (!defaultClinic) {
        throw new BadRequestException('Nenhuma clínica disponível no sistema');
      }

      effectiveClinicId = defaultClinic.id;
      this.logger.authEvent('magic_link_sync', { email, status: 'using_default_clinic', clinicId: effectiveClinicId });
    }

    // 4. Criar usuário e Patient (se necessário) em uma transação
    const result = await this.prisma.$transaction(async (tx) => {
      // Criar usuário
      const newUser = await tx.user.create({
        data: {
          authId,
          email,
          name: name || patient?.name || email.split('@')[0],
          passwordHash: '', // Magic Link não usa senha
          role: UserRole.PATIENT,
          clinicId: effectiveClinicId,
        },
      });

      // Se existe Patient pré-cadastrado, vincular ao novo usuário
      if (patient) {
        await tx.patient.update({
          where: { id: patient.id },
          data: { userId: newUser.id },
        });
      } else {
        // Criar Patient automaticamente para novos usuários
        await tx.patient.create({
          data: {
            userId: newUser.id,
            clinicId: effectiveClinicId,
            email: email,
            name: name || email.split('@')[0],
          },
        });
        this.logger.authEvent('magic_link_sync', { email, status: 'patient_created', userId: newUser.id });
      }

      return newUser;
    });

    this.logger.authEvent('magic_link_sync', {
      email,
      status: 'user_created',
      userId: result.id,
      patientLinked: !!patient,
    });

    return {
      user: {
        id: result.id,
        name: result.name,
        email: result.email,
        role: result.role,
        clinicId: result.clinicId,
      },
      created: true,
      patientLinked: !!patient,
    };
  }
}
