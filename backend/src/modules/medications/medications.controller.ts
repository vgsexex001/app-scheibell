import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  BadRequestException,
} from '@nestjs/common';
import { MedicationsService } from './medications.service';
import { LogMedicationDto } from './dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { Request as ExpressRequest } from 'express';

interface AuthenticatedRequest extends ExpressRequest {
  user: {
    sub: string;
    email: string;
    role: string;
    patientId?: string;
    clinicId?: string;
  };
}

@Controller('medications')
@UseGuards(JwtAuthGuard, RolesGuard)
export class MedicationsController {
  constructor(private readonly medicationsService: MedicationsService) {}

  private getPatientId(req: AuthenticatedRequest): string {
    const patientId = req.user.patientId;
    if (!patientId) {
      throw new BadRequestException('Patient ID not found');
    }
    return patientId;
  }

  // POST /api/medications/log - Registrar medicação tomada
  @Post('log')
  @Roles('PATIENT')
  async logMedication(
    @Request() req: AuthenticatedRequest,
    @Body() dto: LogMedicationDto,
  ) {
    const patientId = this.getPatientId(req);
    return this.medicationsService.logMedication(patientId, dto);
  }

  // GET /api/medications/logs - Histórico de medicações
  @Get('logs')
  @Roles('PATIENT')
  async getMedicationLogs(
    @Request() req: AuthenticatedRequest,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('contentId') contentId?: string,
    @Query('limit') limit?: string,
  ) {
    const patientId = this.getPatientId(req);
    return this.medicationsService.getMedicationLogs(patientId, {
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
      contentId,
      limit: limit ? parseInt(limit, 10) : undefined,
    });
  }

  // GET /api/medications/today - Logs de hoje
  @Get('today')
  @Roles('PATIENT')
  async getTodayLogs(@Request() req: AuthenticatedRequest) {
    const patientId = this.getPatientId(req);
    return this.medicationsService.getTodayLogs(patientId);
  }

  // GET /api/medications/adherence - Porcentagem de adesão
  @Get('adherence')
  @Roles('PATIENT')
  async getAdherence(
    @Request() req: AuthenticatedRequest,
    @Query('days') days?: string,
  ) {
    const patientId = this.getPatientId(req);
    return this.medicationsService.getAdherence(patientId, {
      days: days ? parseInt(days, 10) : undefined,
    });
  }

  // GET /api/medications/check/:contentId/:scheduledTime - Verificar se tomou hoje
  @Get('check/:contentId/:scheduledTime')
  @Roles('PATIENT')
  async checkIfTakenToday(
    @Request() req: AuthenticatedRequest,
    @Param('contentId') contentId: string,
    @Param('scheduledTime') scheduledTime: string,
  ) {
    const patientId = this.getPatientId(req);
    const taken = await this.medicationsService.wasTakenToday(
      patientId,
      contentId,
      scheduledTime,
    );
    return { taken };
  }

  // DELETE /api/medications/log/:id - Desfazer registro
  @Delete('log/:id')
  @Roles('PATIENT')
  async undoLog(
    @Request() req: AuthenticatedRequest,
    @Param('id') logId: string,
  ) {
    const patientId = this.getPatientId(req);
    const result = await this.medicationsService.undoLog(patientId, logId);
    if (!result) {
      return { success: false, message: 'Log não encontrado' };
    }
    return { success: true, deleted: result };
  }
}
