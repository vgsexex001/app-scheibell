import { Injectable, UnauthorizedException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { passportJwtSecret } from 'jwks-rsa';
import { PrismaService } from '../../../prisma/prisma.service';
import { JwtPayload, ClinicAssociation } from '../../../common/decorators/current-user.decorator';

// Interface para o payload do Supabase JWT
interface SupabaseJwtPayload {
  sub: string; // User ID do auth.users
  email?: string;
  phone?: string;
  app_metadata?: {
    provider?: string;
    providers?: string[];
  };
  user_metadata?: {
    name?: string;
    role?: string;
    clinicId?: string;
  };
  role?: string; // role do Supabase (anon, authenticated, etc)
  aal?: string;
  amr?: Array<{ method: string; timestamp: number }>;
  session_id?: string;
  iat?: number;
  exp?: number;
  iss?: string;
  aud?: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  private readonly logger = new Logger(JwtStrategy.name);

  constructor(
    configService: ConfigService,
    private prisma: PrismaService,
  ) {
    const supabaseUrl = configService.get<string>('SUPABASE_URL');
    const supabaseJwtSecret = configService.get<string>('SUPABASE_JWT_SECRET');
    const jwtSecret = configService.get<string>('JWT_SECRET');

    // Configuração para suportar tanto ES256 (JWKS) quanto HS256
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      // Usa JWKS do Supabase para tokens ES256, ou secret para HS256
      secretOrKeyProvider: (request: any, rawJwtToken: string, done: (err: any, secret?: string | Buffer) => void) => {
        // Decodifica o header para verificar o algoritmo
        try {
          const [headerB64] = rawJwtToken.split('.');
          const header = JSON.parse(Buffer.from(headerB64, 'base64').toString());

          if (header.alg === 'ES256' && supabaseUrl) {
            // Token ES256 - usa JWKS do Supabase
            const jwksClient = passportJwtSecret({
              cache: true,
              rateLimit: true,
              jwksRequestsPerMinute: 5,
              jwksUri: `${supabaseUrl}/auth/v1/.well-known/jwks.json`,
            });
            jwksClient(request, rawJwtToken, done);
          } else {
            // Token HS256 - usa secret tradicional
            done(null, supabaseJwtSecret || jwtSecret);
          }
        } catch (err) {
          // Fallback para secret tradicional
          done(null, supabaseJwtSecret || jwtSecret);
        }
      },
      algorithms: ['ES256', 'HS256'],
    });
  }

  async validate(payload: SupabaseJwtPayload | JwtPayload): Promise<JwtPayload> {
    this.logger.debug(`Validando token JWT - sub: ${payload.sub}`);

    // Detecta se é token do Supabase (tem campos específicos como iss, aud, session_id)
    const isSupabaseToken = 'iss' in payload &&
      (payload.iss?.includes('supabase') || payload.aud === 'authenticated');

    if (isSupabaseToken) {
      this.logger.debug('Token do Supabase detectado');
      return this.validateSupabaseToken(payload as SupabaseJwtPayload);
    }

    // Token do backend próprio (legado)
    this.logger.debug('Token do backend detectado');
    return this.validateBackendToken(payload as JwtPayload);
  }

  /**
   * Valida token JWT do Supabase
   * O sub do token é o ID do auth.users, que está vinculado à tabela users via authId
   */
  private async validateSupabaseToken(payload: SupabaseJwtPayload): Promise<JwtPayload> {
    const authId = payload.sub;
    const email = payload.email;

    this.logger.debug(`Buscando usuário por authId: ${authId}`);

    // Primeiro tenta buscar pelo authId (campo que vincula ao auth.users do Supabase)
    let user = await this.prisma.user.findFirst({
      where: { authId },
      include: { patient: true },
    });

    // Se não encontrou pelo authId, tenta pelo email e vincula automaticamente
    if (!user && email) {
      this.logger.debug(`Usuário não encontrado por authId, tentando por email: ${email}`);
      user = await this.prisma.user.findUnique({
        where: { email },
        include: { patient: true },
      });

      // Se encontrou pelo email, vincula o authId para futuras requisições
      if (user) {
        this.logger.debug(`Vinculando authId ${authId} ao usuário ${user.id}`);
        await this.prisma.user.update({
          where: { id: user.id },
          data: { authId },
        });
      }
    }

    if (!user) {
      this.logger.warn(`Usuário não encontrado - authId: ${authId}, email: ${email}`);
      throw new UnauthorizedException('Usuário não encontrado no sistema');
    }

    this.logger.debug(`Usuário encontrado: ${user.email}, role: ${user.role}`);

    // Se o usuário é PATIENT mas não tem registro na tabela patients, criar automaticamente
    // Usar UPSERT para evitar race condition em requests simultâneos
    let patientId = user.patient?.id;
    if (user.role === 'PATIENT' && !user.patient && user.clinicId) {
      // Validar se clínica está ativa antes de criar Patient
      const clinic = await this.prisma.clinic.findUnique({
        where: { id: user.clinicId },
        select: { isActive: true },
      });

      if (!clinic?.isActive) {
        this.logger.warn(`Clínica ${user.clinicId} inativa ou não encontrada para user ${user.id}`);
        throw new UnauthorizedException('Clínica não está ativa');
      }

      this.logger.debug(`Criando registro Patient para usuário ${user.id}`);
      try {
        // UPSERT evita race condition: se já existe, retorna o existente
        const patient = await this.prisma.patient.upsert({
          where: { userId: user.id },
          update: {}, // Não atualiza nada se já existe
          create: {
            userId: user.id,
            clinicId: user.clinicId,
            name: user.name,
            email: user.email,
          },
        });
        patientId = patient.id;
        this.logger.debug(`Patient criado/encontrado com ID: ${patientId}`);
      } catch (error: any) {
        // Se unique constraint violado, buscar o patient existente
        if (error.code === 'P2002') {
          this.logger.debug(`Patient já existe para user ${user.id}, buscando...`);
          const existingPatient = await this.prisma.patient.findUnique({
            where: { userId: user.id },
          });
          patientId = existingPatient?.id;
        } else {
          throw error;
        }
      }
    }

    // Carregar associações multi-clínica
    const clinicAssociations = await this.loadClinicAssociations(user.id, user.role, patientId);

    return {
      sub: user.id, // Usa o ID da tabela users (não do auth.users)
      id: user.id,
      email: user.email,
      role: user.role,
      clinicId: user.clinicId || undefined,
      patientId,
      clinicAssociations,
    };
  }

  /**
   * Valida token JWT do backend próprio (legado)
   */
  private async validateBackendToken(payload: JwtPayload): Promise<JwtPayload> {
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      include: { patient: true },
    });

    if (!user) {
      throw new UnauthorizedException('Usuário não encontrado');
    }

    // Se o usuário é PATIENT mas não tem registro na tabela patients, criar automaticamente
    // Usar UPSERT para evitar race condition em requests simultâneos
    let patientId = user.patient?.id;
    if (user.role === 'PATIENT' && !user.patient && user.clinicId) {
      // Validar se clínica está ativa antes de criar Patient
      const clinic = await this.prisma.clinic.findUnique({
        where: { id: user.clinicId },
        select: { isActive: true },
      });

      if (!clinic?.isActive) {
        this.logger.warn(`Clínica ${user.clinicId} inativa ou não encontrada para user ${user.id}`);
        throw new UnauthorizedException('Clínica não está ativa');
      }

      this.logger.debug(`Criando registro Patient para usuário ${user.id}`);
      try {
        // UPSERT evita race condition: se já existe, retorna o existente
        const patient = await this.prisma.patient.upsert({
          where: { userId: user.id },
          update: {}, // Não atualiza nada se já existe
          create: {
            userId: user.id,
            clinicId: user.clinicId,
            name: user.name,
            email: user.email,
          },
        });
        patientId = patient.id;
        this.logger.debug(`Patient criado/encontrado com ID: ${patientId}`);
      } catch (error: any) {
        // Se unique constraint violado, buscar o patient existente
        if (error.code === 'P2002') {
          this.logger.debug(`Patient já existe para user ${user.id}, buscando...`);
          const existingPatient = await this.prisma.patient.findUnique({
            where: { userId: user.id },
          });
          patientId = existingPatient?.id;
        } else {
          throw error;
        }
      }
    }

    // Carregar associações multi-clínica
    const clinicAssociations = await this.loadClinicAssociations(payload.sub, payload.role, patientId);

    return {
      sub: payload.sub,
      id: payload.sub,
      email: payload.email,
      role: payload.role,
      clinicId: payload.clinicId,
      patientId,
      clinicAssociations,
    };
  }

  /**
   * Carrega as associações de clínicas do usuário
   * Para pacientes: busca em patient_clinic_associations
   * Para staff/admin: busca em user_clinic_assignments
   *
   * NOTA: Este método usa $queryRaw para compatibilidade com migrações pendentes.
   * Após executar as migrações e regenerar o Prisma Client, pode-se usar os métodos tipados.
   */
  private async loadClinicAssociations(
    userId: string,
    role: string,
    patientId?: string,
  ): Promise<ClinicAssociation[]> {
    const associations: ClinicAssociation[] = [];

    try {
      if (role === 'PATIENT' && patientId) {
        // Tentar buscar na nova tabela de associações via raw query
        try {
          const patientAssociations = await this.prisma.$queryRaw<Array<{
            clinic_id: string;
            clinic_name: string;
            is_primary: boolean;
            is_active: boolean;
          }>>`
            SELECT pca.clinic_id, c.name as clinic_name, pca.is_primary, c."isActive" as is_active
            FROM patient_clinic_associations pca
            JOIN clinics c ON c.id = pca.clinic_id
            WHERE pca.patient_id = ${patientId}
              AND pca.status = 'ACTIVE'
              AND c."isActive" = true
          `;

          for (const assoc of patientAssociations) {
            associations.push({
              clinicId: assoc.clinic_id,
              clinicName: assoc.clinic_name,
              role: 'PATIENT',
              isPrimary: assoc.is_primary,
              isDefault: assoc.is_primary,
            });
          }
        } catch {
          // Tabela não existe ainda, ignorar
        }

        // Fallback: se não tem associações na nova tabela, usar clinicId do patient
        if (associations.length === 0) {
          const patient = await this.prisma.patient.findUnique({
            where: { id: patientId },
            include: {
              clinic: {
                select: { id: true, name: true, isActive: true },
              },
            },
          });

          if (patient?.clinic?.isActive) {
            associations.push({
              clinicId: patient.clinicId,
              clinicName: patient.clinic.name,
              role: 'PATIENT',
              isPrimary: true,
              isDefault: true,
            });
          }
        }
      } else if (role === 'CLINIC_ADMIN' || role === 'CLINIC_STAFF') {
        // Tentar buscar na nova tabela de assignments via raw query
        try {
          const userAssignments = await this.prisma.$queryRaw<Array<{
            clinic_id: string;
            clinic_name: string;
            role: string;
            is_default: boolean;
            is_active: boolean;
          }>>`
            SELECT uca.clinic_id, c.name as clinic_name, uca.role, uca.is_default, c."isActive" as is_active
            FROM user_clinic_assignments uca
            JOIN clinics c ON c.id = uca.clinic_id
            WHERE uca.user_id = ${userId}
              AND uca.is_active = true
              AND c."isActive" = true
          `;

          for (const assignment of userAssignments) {
            associations.push({
              clinicId: assignment.clinic_id,
              clinicName: assignment.clinic_name,
              role: assignment.role,
              isPrimary: false,
              isDefault: assignment.is_default,
            });
          }
        } catch {
          // Tabela não existe ainda, ignorar
        }

        // Fallback: se não tem assignments na nova tabela, usar clinicId do user
        if (associations.length === 0) {
          const user = await this.prisma.user.findUnique({
            where: { id: userId },
            include: {
              clinic: {
                select: { id: true, name: true, isActive: true },
              },
            },
          });

          if (user?.clinic?.isActive) {
            associations.push({
              clinicId: user.clinicId!,
              clinicName: user.clinic.name,
              role: user.role,
              isPrimary: true,
              isDefault: true,
            });
          }
        }
      }
    } catch (error) {
      // Se ocorrer erro, retorna array vazio para manter compatibilidade
      this.logger.debug(`Erro ao carregar associações de clínica: ${error}`);
    }

    return associations;
  }
}
