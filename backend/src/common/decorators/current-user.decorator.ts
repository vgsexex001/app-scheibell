import { createParamDecorator, ExecutionContext } from '@nestjs/common';

// Informação de associação com clínica
export interface ClinicAssociation {
  clinicId: string;
  clinicName?: string;
  role?: string;
  isPrimary?: boolean;
  isDefault?: boolean;
}

export interface JwtPayload {
  sub: string;
  id: string;
  email: string;
  role: string;
  clinicId?: string;      // Clínica ativa no contexto atual
  patientId?: string;

  // Multi-clínica: lista de clínicas associadas
  clinicAssociations?: ClinicAssociation[];

  // Contexto da clínica atual (para validação)
  currentClinicContext?: {
    clinicId: string;
    role: string;
    permissions?: string[];
  };
}

export const CurrentUser = createParamDecorator(
  (data: keyof JwtPayload | undefined, ctx: ExecutionContext): JwtPayload[keyof JwtPayload] | JwtPayload | undefined => {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user as JwtPayload;

    if (!user) {
      return undefined;
    }

    if (data) {
      return user[data];
    }

    return user;
  },
);
