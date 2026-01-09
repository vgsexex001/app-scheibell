import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  UseGuards,
  HttpCode,
  HttpStatus,
  Delete,
} from '@nestjs/common';
import { ConnectionService } from './connection.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { ConnectPatientDto } from './dto';

interface JwtPayload {
  sub: string;
  email: string;
  role: string;
  clinicId?: string;
  patientId?: string;
}

@Controller()
export class ConnectionController {
  constructor(private connectionService: ConnectionService) {}

  /**
   * Admin gera código de conexão para um paciente
   * POST /api/admin/patients/:patientId/connection-code
   */
  @Post('admin/patients/:patientId/connection-code')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  @HttpCode(HttpStatus.CREATED)
  async generateConnectionCode(
    @Param('patientId') patientId: string,
    @CurrentUser() user: JwtPayload,
  ) {
    if (!user.clinicId) {
      throw new Error('Usuário não está associado a uma clínica');
    }

    return this.connectionService.generateConnectionCode(
      patientId,
      user.clinicId,
      user.sub,
    );
  }

  /**
   * Paciente usa código para conectar sua conta
   * POST /api/patient/connect
   */
  @Post('patient/connect')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async connectWithCode(
    @Body() dto: ConnectPatientDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.connectionService.connectWithCode(dto.connectionCode, user.sub);
  }

  /**
   * Admin lista conexões de um paciente
   * GET /api/admin/patients/:patientId/connections
   */
  @Get('admin/patients/:patientId/connections')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  async getPatientConnections(
    @Param('patientId') patientId: string,
    @CurrentUser() user: JwtPayload,
  ) {
    if (!user.clinicId) {
      throw new Error('Usuário não está associado a uma clínica');
    }

    return this.connectionService.getPatientConnections(
      patientId,
      user.clinicId,
    );
  }

  /**
   * Admin revoga um código de conexão
   * DELETE /api/admin/connections/:connectionId
   */
  @Delete('admin/connections/:connectionId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  @HttpCode(HttpStatus.OK)
  async revokeConnectionCode(
    @Param('connectionId') connectionId: string,
    @CurrentUser() user: JwtPayload,
  ) {
    if (!user.clinicId) {
      throw new Error('Usuário não está associado a uma clínica');
    }

    return this.connectionService.revokeConnectionCode(
      connectionId,
      user.clinicId,
    );
  }
}
