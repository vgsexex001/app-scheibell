import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';
import { v4 as uuidv4 } from 'uuid';
import { PrismaService } from '../../prisma/prisma.service';
import { LoginDto, RegisterDto, UpdateProfileDto, ChangePasswordDto } from './dto';
import { UserRole } from '@prisma/client';

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

    // Para pacientes, usar a clínica padrão se não informada
    const defaultClinicId = 'clinic-default-scheibell';
    const clinicId = dto.clinicId || (role === UserRole.PATIENT ? defaultClinicId : null);

    // Criar apenas o usuário (Patient será vinculado via código de conexão ou criado pelo admin)
    const result = await this.prisma.user.create({
      data: {
        name: dto.name,
        email: dto.email,
        passwordHash: hashedPassword,
        role: role,
        clinicId: clinicId,
      },
    });

    return await this.generateAuthResponse(result);
  }

  async login(dto: LoginDto): Promise<AuthResponse> {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (!user) {
      throw new UnauthorizedException('Credenciais inválidas');
    }

    const isPasswordValid = await bcrypt.compare(dto.password, user.passwordHash);

    if (!isPasswordValid) {
      throw new UnauthorizedException('Credenciais inválidas');
    }

    return await this.generateAuthResponse(user);
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
      },
    });

    if (!user) {
      throw new NotFoundException('Usuário não encontrado');
    }

    return user;
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

    return user;
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
}
