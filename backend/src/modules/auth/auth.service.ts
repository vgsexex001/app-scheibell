import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
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
  };
  accessToken: string;
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

    // Usar transação para criar usuário e paciente atomicamente
    const result = await this.prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          name: dto.name,
          email: dto.email,
          passwordHash: hashedPassword,
          role: role,
          clinicId: clinicId,
        },
      });

      // Se for paciente, criar registro de Patient
      if (role === UserRole.PATIENT && clinicId) {
        await tx.patient.create({
          data: {
            userId: user.id,
            clinicId: clinicId,
            surgeryDate: new Date(), // Data de cirurgia padrão = hoje (pode ser alterada depois)
          },
        });
      }

      return user;
    });

    return this.generateAuthResponse(result);
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

    return this.generateAuthResponse(user);
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

  private generateAuthResponse(user: {
    id: string;
    name: string;
    email: string;
    role: UserRole;
    clinicId: string | null;
  }): AuthResponse {
    const payload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      clinicId: user.clinicId,
    };

    const expiresIn = this.configService.get<string>('JWT_EXPIRATION') || '24h';
    const expiresInSeconds = this.parseExpirationToSeconds(expiresIn);

    const accessToken = this.jwtService.sign(payload);

    return {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        clinicId: user.clinicId || undefined,
      },
      accessToken,
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
