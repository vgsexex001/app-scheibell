import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Query,
  Body,
  UseGuards,
  ParseIntPipe,
  DefaultValuePipe,
} from '@nestjs/common';
import { PatientsService } from './patients.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { CreateAllergyDto, CreateMedicalNoteDto, UpdatePatientDto, InvitePatientDto } from './dto';

@Controller('patients')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
export class PatientsController {
  constructor(private patientsService: PatientsService) {}

  /**
   * Convida um paciente (pré-cadastro + agendamento cirurgia)
   * POST /api/patients/invite
   */
  @Post('invite')
  async invitePatient(
    @CurrentUser('clinicId') clinicId: string,
    @Body() dto: InvitePatientDto,
  ) {
    return this.patientsService.invitePatient(clinicId, dto);
  }

  /**
   * Lista pacientes da clínica
   * GET /api/patients
   */
  @Get()
  async getPatients(
    @CurrentUser('clinicId') clinicId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('search') search?: string,
    @Query('status') status?: string,
  ) {
    return this.patientsService.getPatients(clinicId, page, limit, search, status);
  }

  /**
   * Busca detalhes de um paciente
   * GET /api/patients/:id
   */
  @Get(':id')
  async getPatientById(
    @Param('id') patientId: string,
    @CurrentUser('clinicId') clinicId: string,
  ) {
    return this.patientsService.getPatientById(patientId, clinicId);
  }

  /**
   * Atualiza dados do paciente
   * PATCH /api/patients/:id
   */
  @Patch(':id')
  async updatePatient(
    @Param('id') patientId: string,
    @CurrentUser('clinicId') clinicId: string,
    @Body() dto: UpdatePatientDto,
  ) {
    return this.patientsService.updatePatient(patientId, clinicId, dto);
  }

  /**
   * Lista consultas de um paciente
   * GET /api/patients/:id/appointments
   */
  @Get(':id/appointments')
  async getPatientAppointments(
    @Param('id') patientId: string,
    @CurrentUser('clinicId') clinicId: string,
    @Query('status') status?: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page?: number,
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit?: number,
  ) {
    return this.patientsService.getPatientAppointments(
      patientId,
      clinicId,
      status,
      page,
      limit,
    );
  }

  /**
   * Busca histórico completo do paciente
   * GET /api/patients/:id/history
   */
  @Get(':id/history')
  async getPatientHistory(
    @Param('id') patientId: string,
    @CurrentUser('clinicId') clinicId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.patientsService.getPatientHistory(patientId, clinicId, page, limit);
  }

  // ==================== ALERGIAS ====================

  /**
   * Lista alergias de um paciente
   * GET /api/patients/:id/allergies
   */
  @Get(':id/allergies')
  async getAllergies(
    @Param('id') patientId: string,
    @CurrentUser('clinicId') clinicId: string,
  ) {
    return this.patientsService.getAllergies(patientId, clinicId);
  }

  /**
   * Adiciona uma alergia ao paciente
   * POST /api/patients/:id/allergies
   */
  @Post(':id/allergies')
  async addAllergy(
    @Param('id') patientId: string,
    @CurrentUser('clinicId') clinicId: string,
    @Body() dto: CreateAllergyDto,
  ) {
    return this.patientsService.addAllergy(patientId, clinicId, dto);
  }

  /**
   * Remove uma alergia do paciente
   * DELETE /api/patients/:id/allergies/:allergyId
   */
  @Delete(':id/allergies/:allergyId')
  async removeAllergy(
    @Param('id') patientId: string,
    @Param('allergyId') allergyId: string,
    @CurrentUser('clinicId') clinicId: string,
  ) {
    return this.patientsService.removeAllergy(patientId, allergyId, clinicId);
  }

  // ==================== NOTAS MÉDICAS ====================

  /**
   * Lista notas médicas de um paciente
   * GET /api/patients/:id/medical-notes
   */
  @Get(':id/medical-notes')
  async getMedicalNotes(
    @Param('id') patientId: string,
    @CurrentUser('clinicId') clinicId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.patientsService.getMedicalNotes(patientId, clinicId, page, limit);
  }

  /**
   * Adiciona uma nota médica ao paciente
   * POST /api/patients/:id/medical-notes
   */
  @Post(':id/medical-notes')
  async addMedicalNote(
    @Param('id') patientId: string,
    @CurrentUser('clinicId') clinicId: string,
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateMedicalNoteDto,
  ) {
    return this.patientsService.addMedicalNote(patientId, clinicId, dto, userId);
  }

  /**
   * Remove uma nota médica do paciente
   * DELETE /api/patients/:id/medical-notes/:noteId
   */
  @Delete(':id/medical-notes/:noteId')
  async removeMedicalNote(
    @Param('id') patientId: string,
    @Param('noteId') noteId: string,
    @CurrentUser('clinicId') clinicId: string,
  ) {
    return this.patientsService.removeMedicalNote(patientId, noteId, clinicId);
  }
}
