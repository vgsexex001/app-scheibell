import {
  Controller,
  Post,
  Body,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { PhotoValidationService } from './photo-validation.service';
import { ValidatePhotoDto } from './dto/validate-photo.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

@Controller('photo-validation')
@UseGuards(JwtAuthGuard, RolesGuard)
export class PhotoValidationController {
  constructor(private readonly service: PhotoValidationService) {}

  @Post('validate')
  @Roles('PATIENT')
  @UseInterceptors(FileInterceptor('photo'))
  async validate(
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: ValidatePhotoDto,
  ) {
    if (!file) {
      throw new BadRequestException('Foto é obrigatória');
    }

    const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp'];
    if (!allowedMimeTypes.includes(file.mimetype)) {
      throw new BadRequestException('Formato de imagem não suportado. Use JPEG, PNG ou WebP.');
    }

    // Limite de 10MB
    if (file.size > 10 * 1024 * 1024) {
      throw new BadRequestException('Arquivo muito grande. Máximo 10MB.');
    }

    return this.service.validatePhoto(
      file.buffer,
      file.mimetype,
      dto.photoType,
    );
  }
}
