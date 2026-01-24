import { SetMetadata, applyDecorators, UseGuards } from '@nestjs/common';
import { ClinicContextGuard, CLINIC_CONTEXT_KEY, CLINIC_FROM_PARAM_KEY } from '../guards/clinic-context.guard';

/**
 * Decorator que marca um endpoint como requerendo contexto de clínica válido.
 * O guard irá verificar se o usuário tem acesso à clínica no JWT.
 *
 * Uso:
 * @RequiresClinicContext()
 * @Get('my-data')
 * async getMyData(@CurrentUser() user: JwtPayload) { ... }
 */
export const RequiresClinicContext = () =>
  applyDecorators(
    SetMetadata(CLINIC_CONTEXT_KEY, true),
    UseGuards(ClinicContextGuard),
  );

/**
 * Decorator que marca um endpoint como requerendo validação de clínica,
 * usando o clinicId de um parâmetro da rota ou query.
 *
 * Uso:
 * @RequiresClinicFromParam('clinicId')
 * @Get('clinics/:clinicId/patients')
 * async getPatients(@Param('clinicId') clinicId: string) { ... }
 */
export const RequiresClinicFromParam = (paramName: string) =>
  applyDecorators(
    SetMetadata(CLINIC_CONTEXT_KEY, true),
    SetMetadata(CLINIC_FROM_PARAM_KEY, paramName),
    UseGuards(ClinicContextGuard),
  );

/**
 * Decorator para extrair o contexto da clínica do request.
 * Útil para obter informações da clínica validada pelo guard.
 *
 * Uso:
 * @RequiresClinicContext()
 * @Get('my-data')
 * async getMyData(@ClinicContext() clinic: { clinicId: string; clinicName: string }) { ... }
 */
import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export interface ClinicContextData {
  clinicId: string;
  clinicName: string;
}

export const ClinicContext = createParamDecorator(
  (data: keyof ClinicContextData | undefined, ctx: ExecutionContext): ClinicContextData | string | undefined => {
    const request = ctx.switchToHttp().getRequest();
    const clinicContext = request.clinicContext as ClinicContextData;

    if (!clinicContext) {
      return undefined;
    }

    if (data) {
      return clinicContext[data];
    }

    return clinicContext;
  },
);
