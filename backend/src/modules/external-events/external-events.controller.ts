import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { ExternalEventsService } from './external-events.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { CreateExternalEventDto, UpdateExternalEventDto } from './dto';

@Controller('external-events')
@UseGuards(JwtAuthGuard)
export class ExternalEventsController {
  constructor(private externalEventsService: ExternalEventsService) {}

  /**
   * Lista todos os eventos externos do paciente
   * GET /api/external-events
   */
  @Get()
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async getEvents(@CurrentUser('patientId') patientId: string) {
    return this.externalEventsService.getPatientEvents(patientId);
  }

  /**
   * Busca um evento específico
   * GET /api/external-events/:id
   */
  @Get(':id')
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async getEvent(
    @Param('id') id: string,
    @CurrentUser('patientId') patientId: string,
  ) {
    return this.externalEventsService.getEventById(id, patientId);
  }

  /**
   * Cria um novo evento externo
   * POST /api/external-events
   */
  @Post()
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async createEvent(
    @CurrentUser('patientId') patientId: string,
    @Body() dto: CreateExternalEventDto,
  ) {
    return this.externalEventsService.createEvent(patientId, dto);
  }

  /**
   * Atualiza um evento existente
   * PUT /api/external-events/:id
   */
  @Put(':id')
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async updateEvent(
    @Param('id') id: string,
    @CurrentUser('patientId') patientId: string,
    @Body() dto: UpdateExternalEventDto,
  ) {
    return this.externalEventsService.updateEvent(id, patientId, dto);
  }

  /**
   * Exclui um evento (soft delete)
   * DELETE /api/external-events/:id
   */
  @Delete(':id')
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async deleteEvent(
    @Param('id') id: string,
    @CurrentUser('patientId') patientId: string,
  ) {
    await this.externalEventsService.deleteEvent(id, patientId);
    return { message: 'Evento excluído com sucesso' };
  }
}
