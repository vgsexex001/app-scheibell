import { Injectable, UnauthorizedException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { passportJwtSecret } from 'jwks-rsa';
import { PrismaService } from '../../../prisma/prisma.service';
import { JwtPayload } from '../../../common/decorators/current-user.decorator';

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

    return {
      sub: user.id, // Usa o ID da tabela users (não do auth.users)
      id: user.id,
      email: user.email,
      role: user.role,
      clinicId: user.clinicId || undefined,
      patientId: user.patient?.id,
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

    return {
      sub: payload.sub,
      id: payload.sub,
      email: payload.email,
      role: payload.role,
      clinicId: payload.clinicId,
      patientId: user.patient?.id,
    };
  }
}
