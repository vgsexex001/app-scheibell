import { Global, Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { LoggerService } from './services/logger.service';
import { AzureStorageService } from './services/azure-storage.service';

@Global()
@Module({
  imports: [ConfigModule],
  providers: [LoggerService, AzureStorageService],
  exports: [LoggerService, AzureStorageService],
})
export class CommonModule {}
