import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PrismaService } from '../../../prisma/prisma.service';
import { JwtPayload } from '../../../common/decorators/current-user.decorator';

/**
 * Decorator key para marcar endpoints que requerem contexto de clínica
 */
export const CLINIC_CONTEXT_KEY = 'requiresClinicContext';

/**
 * Decorator key para especificar que o endpoint usa clinicId do parâmetro
 */
export const CLINIC_FROM_PARAM_KEY = 'clinicFromParam';

/**
 * ClinicContextGuard - Valida que o usuário tem acesso à clínica no contexto atual
 *
 * Este guard verifica:
 * 1. Se o usuário tem uma clínica no contexto (clinicId no JWT)
 * 2. Se o usuário está associado a essa clínica (via patient_clinic_associations ou user_clinic_assignments)
 * 3. Se a clínica está ativa
 *
 * Para pacientes: verifica patient_clinic_associations
 * Para staff/admin: verifica user_clinic_assignments
 */
@Injectable()
export class ClinicContextGuard implements CanActivate {
  private readonly logger = new Logger(ClinicContextGuard.name);

  constructor(
    private reflector: Reflector,
    private prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    // Verificar se o endpoint requer contexto de clínica
    const requiresClinicContext = this.reflector.getAllAndOverride<boolean>(
      CLINIC_CONTEXT_KEY,
      [context.getHandler(), context.getClass()],
    );

    // Se não requer contexto de clínica, permite acesso
    if (!requiresClinicContext) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const user = request.user as JwtPayload;

    if (!user) {
      this.logger.warn('ClinicContextGuard: Usuário não autenticado');
      throw new ForbiddenException('Usuário não autenticado');
    }

    // Verificar se deve usar clinicId do parâmetro
    const clinicFromParam = this.reflector.getAllAndOverride<string>(
      CLINIC_FROM_PARAM_KEY,
      [context.getHandler(), context.getClass()],
    );

    let targetClinicId: string | undefined;

    if (clinicFromParam) {
      // Usa clinicId do parâmetro da rota
      targetClinicId = request.params[clinicFromParam] || request.query[clinicFromParam];
    } else {
      // Usa clinicId do JWT
      targetClinicId = user.clinicId;
    }

    if (!targetClinicId) {
      this.logger.warn(`ClinicContextGuard: Sem clínica no contexto para user ${user.id}`);
      throw new ForbiddenException('Nenhuma clínica selecionada no contexto');
    }

    // Verificar se a clínica existe e está ativa
    const clinic = await this.prisma.clinic.findUnique({
      where: { id: targetClinicId },
      select: { id: true, isActive: true, name: true },
    });

    if (!clinic) {
      this.logger.warn(`ClinicContextGuard: Clínica ${targetClinicId} não encontrada`);
      throw new ForbiddenException('Clínica não encontrada');
    }

    if (!clinic.isActive) {
      this.logger.warn(`ClinicContextGuard: Clínica ${targetClinicId} inativa`);
      throw new ForbiddenException('Clínica não está ativa');
    }

    // Validar associação do usuário com a clínica
    const hasAccess = await this.validateUserClinicAccess(user, targetClinicId);

    if (!hasAccess) {
      this.logger.warn(
        `ClinicContextGuard: User ${user.id} sem acesso à clínica ${targetClinicId}`,
      );
      throw new ForbiddenException('Você não tem acesso a esta clínica');
    }

    // Adicionar informação da clínica ao request para uso posterior
    request.clinicContext = {
      clinicId: targetClinicId,
      clinicName: clinic.name,
    };

    return true;
  }

  /**
   * Valida se o usuário tem acesso à clínica especificada
   */
  private async validateUserClinicAccess(
    user: JwtPayload,
    clinicId: string,
  ): Promise<boolean> {
    // PACIENTES: verificar clinicId direto no patient
    if (user.role === 'PATIENT') {
      const patient = await this.prisma.patient.findFirst({
        where: {
          userId: user.id,
          clinicId: clinicId,
          deletedAt: null,
        },
      });

      return !!patient;
    }

    // STAFF/ADMIN/THIRD_PARTY: verificar clinicId direto no user
    const userRecord = await this.prisma.user.findFirst({
      where: {
        id: user.id,
        clinicId: clinicId,
        deletedAt: null,
      },
    });

    return !!userRecord;
  }
}
