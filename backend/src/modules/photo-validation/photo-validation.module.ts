import { Module } from '@nestjs/common';
import { PhotoValidationController } from './photo-validation.controller';
import { PhotoValidationService } from './photo-validation.service';

@Module({
  controllers: [PhotoValidationController],
  providers: [PhotoValidationService],
  exports: [PhotoValidationService],
})
export class PhotoValidationModule {}
