import {
  Controller, Get, Post, Put, Patch, Delete,
  Body, Param, Query, UseGuards,
} from '@nestjs/common';
import { ContentService } from './content.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { ContentType, ContentCategory } from '@prisma/client';

@Controller('content')
@UseGuards(JwtAuthGuard)
export class ContentController {
  constructor(private contentService: ContentService) {}

  // ========== CLÍNICA ==========

  @Get('clinic')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  @UseGuards(RolesGuard)
  async getClinicContents(
    @CurrentUser('clinicId') clinicId: string,
    @Query('type') type: ContentType,
    @Query('category') category?: ContentCategory,
  ) {
    return this.contentService.getClinicContents(clinicId, type, category);
  }

  @Get('clinic/all')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  @UseGuards(RolesGuard)
  async getClinicContentsByType(
    @CurrentUser('clinicId') clinicId: string,
    @Query('type') type: ContentType,
  ) {
    return this.contentService.getClinicContentsByType(clinicId, type);
  }

  @Get('clinic/stats')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  @UseGuards(RolesGuard)
  async getContentStats(@CurrentUser('clinicId') clinicId: string) {
    return this.contentService.getContentStats(clinicId);
  }

  @Post('clinic')
  @Roles('CLINIC_ADMIN')
  @UseGuards(RolesGuard)
  async createClinicContent(
    @CurrentUser('clinicId') clinicId: string,
    @Body() data: {
      type: ContentType;
      category: ContentCategory;
      title: string;
      description?: string;
      validFromDay?: number;
      validUntilDay?: number;
    },
  ) {
    return this.contentService.createClinicContent(clinicId, data);
  }

  @Put('clinic/:id')
  @Roles('CLINIC_ADMIN')
  @UseGuards(RolesGuard)
  async updateClinicContent(
    @Param('id') id: string,
    @CurrentUser('clinicId') clinicId: string,
    @Body() data: {
      title?: string;
      description?: string;
      category?: ContentCategory;
      validFromDay?: number;
      validUntilDay?: number;
    },
  ) {
    return this.contentService.updateClinicContent(id, clinicId, data);
  }

  @Patch('clinic/:id/toggle')
  @Roles('CLINIC_ADMIN')
  @UseGuards(RolesGuard)
  async toggleClinicContent(
    @Param('id') id: string,
    @CurrentUser('clinicId') clinicId: string,
  ) {
    return this.contentService.toggleClinicContent(id, clinicId);
  }

  @Delete('clinic/:id')
  @Roles('CLINIC_ADMIN')
  @UseGuards(RolesGuard)
  async deleteClinicContent(
    @Param('id') id: string,
    @CurrentUser('clinicId') clinicId: string,
  ) {
    return this.contentService.deleteClinicContent(id, clinicId);
  }

  @Post('clinic/reorder')
  @Roles('CLINIC_ADMIN')
  @UseGuards(RolesGuard)
  async reorderContents(
    @CurrentUser('clinicId') clinicId: string,
    @Body('contentIds') contentIds: string[],
  ) {
    return this.contentService.reorderClinicContents(clinicId, contentIds);
  }

  @Post('clinic/sync')
  @Roles('CLINIC_ADMIN')
  @UseGuards(RolesGuard)
  async syncTemplates(@CurrentUser('clinicId') clinicId: string) {
    return this.contentService.syncTemplatesForClinic(clinicId);
  }

  // ========== PACIENTE (visualização) ==========

  @Get('patient/me')
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async getMyContent(
    @CurrentUser('patientId') patientId: string,
    @Query('type') type: ContentType,
    @Query('day') day?: string,
  ) {
    return this.contentService.getPatientContent(
      patientId,
      type,
      day ? parseInt(day) : undefined,
    );
  }

  @Get('patient/clinic')
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async getPatientClinicContent(
    @CurrentUser('patientId') patientId: string,
    @Query('type') type: ContentType,
    @Query('category') category?: ContentCategory,
  ) {
    return this.contentService.getPatientClinicContent(patientId, type, category);
  }

  @Get('patient/clinic/all')
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async getPatientAllClinicContentByType(
    @CurrentUser('patientId') patientId: string,
    @Query('type') type: ContentType,
  ) {
    return this.contentService.getPatientAllClinicContentByType(patientId, type);
  }

  @Post('patient/medication')
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async addPatientMedication(
    @CurrentUser('patientId') patientId: string,
    @Body() data: {
      title: string;
      description?: string;
      dosage?: string;
      frequency?: string;
      times?: string[];
    },
  ) {
    return this.contentService.addPatientMedication(patientId, data);
  }

  @Get('patient/training-protocol')
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async getTrainingProtocol(@CurrentUser('patientId') patientId: string) {
    return this.contentService.getPatientTrainingProtocol(patientId);
  }

  // ========== AJUSTES POR PACIENTE (staff) ==========

  @Get('patients/:patientId/adjustments')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  @UseGuards(RolesGuard)
  async getPatientAdjustments(@Param('patientId') patientId: string) {
    return this.contentService.getPatientAdjustments(patientId);
  }

  @Post('patients/:patientId/adjustments/add')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  @UseGuards(RolesGuard)
  async addPatientContent(
    @Param('patientId') patientId: string,
    @CurrentUser('id') userId: string,
    @Body() data: {
      contentType: ContentType;
      category: ContentCategory;
      title: string;
      description?: string;
      reason?: string;
    },
  ) {
    return this.contentService.addPatientContent(patientId, data, userId);
  }

  @Post('patients/:patientId/adjustments/disable')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  @UseGuards(RolesGuard)
  async disableForPatient(
    @Param('patientId') patientId: string,
    @CurrentUser('id') userId: string,
    @Body() data: { baseContentId: string; reason: string },
  ) {
    return this.contentService.disableContentForPatient(
      patientId, data.baseContentId, data.reason, userId,
    );
  }

  @Post('patients/:patientId/adjustments/modify')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  @UseGuards(RolesGuard)
  async modifyForPatient(
    @Param('patientId') patientId: string,
    @CurrentUser('id') userId: string,
    @Body() data: {
      baseContentId: string;
      title?: string;
      description?: string;
      category?: ContentCategory;
      reason?: string;
    },
  ) {
    return this.contentService.modifyContentForPatient(
      patientId, data.baseContentId, data, userId,
    );
  }

  @Delete('patients/:patientId/adjustments/:adjustmentId')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  @UseGuards(RolesGuard)
  async removeAdjustment(@Param('adjustmentId') adjustmentId: string) {
    return this.contentService.removePatientAdjustment(adjustmentId);
  }
}
