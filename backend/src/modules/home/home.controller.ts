import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
} from '@nestjs/common';
import { HomeService } from './home.service';
import {
  TakeMedicationDto,
  CompleteTaskDto,
  UpdateVideoProgressDto,
  CreateTaskDto,
} from './dto/home.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('patient')
@UseGuards(JwtAuthGuard, RolesGuard)
export class HomeController {
  constructor(private readonly homeService: HomeService) {}

  // ==================== GET HOME DATA ====================

  @Get('home')
  @Roles('PATIENT')
  async getHome(@CurrentUser('patientId') patientId: string) {
    return this.homeService.getHomeData(patientId);
  }

  // ==================== ACTIONS ====================

  @Post('home/medication/take')
  @Roles('PATIENT')
  async takeMedication(
    @CurrentUser('patientId') patientId: string,
    @Body() dto: TakeMedicationDto,
  ) {
    return this.homeService.takeMedication(patientId, dto);
  }

  @Post('home/task/complete')
  @Roles('PATIENT')
  async completeTask(
    @CurrentUser('patientId') patientId: string,
    @Body() dto: CompleteTaskDto,
  ) {
    return this.homeService.completeTask(patientId, dto);
  }

  @Post('home/video/progress')
  @Roles('PATIENT')
  async updateVideoProgress(
    @CurrentUser('patientId') patientId: string,
    @Body() dto: UpdateVideoProgressDto,
  ) {
    return this.homeService.updateVideoProgress(patientId, dto);
  }

  // GET video progress for all training videos
  @Get('videos/progress')
  @Roles('PATIENT')
  async getVideoProgress(@CurrentUser('patientId') patientId: string) {
    return this.homeService.getVideoProgress(patientId);
  }

  @Post('home/task')
  @Roles('PATIENT')
  async createTask(
    @CurrentUser('patientId') patientId: string,
    @CurrentUser('clinicId') clinicId: string,
    @Body() dto: CreateTaskDto,
  ) {
    return this.homeService.createTask(patientId, clinicId, dto);
  }
}
