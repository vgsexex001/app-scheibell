import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as fs from 'fs';
import * as path from 'path';
import { v4 as uuidv4 } from 'uuid';

export interface StorageResult {
  storagePath: string;
  originalName: string;
  mimeType: string;
  sizeBytes: number;
}

@Injectable()
export class StorageService {
  private readonly uploadDir: string;

  constructor(private readonly configService: ConfigService) {
    this.uploadDir =
      this.configService.get<string>('UPLOAD_DIR') ||
      path.join(process.cwd(), 'uploads');

    // Ensure base upload directory exists
    if (!fs.existsSync(this.uploadDir)) {
      fs.mkdirSync(this.uploadDir, { recursive: true });
    }
  }

  /**
   * Save a file to local storage
   * Path structure: clinicId/patientId/conversationId/uuid.ext
   */
  async saveFile(
    clinicId: string,
    patientId: string,
    conversationId: string,
    file: Express.Multer.File,
  ): Promise<StorageResult> {
    // Build directory path
    const dirPath = path.join(
      this.uploadDir,
      clinicId,
      patientId,
      conversationId,
    );

    // Create directory if it doesn't exist
    if (!fs.existsSync(dirPath)) {
      fs.mkdirSync(dirPath, { recursive: true });
    }

    // Generate unique filename
    const ext = this.getExtensionFromMimeType(file.mimetype);
    const filename = `${uuidv4()}${ext}`;
    const fullPath = path.join(dirPath, filename);

    // Write file to disk
    await fs.promises.writeFile(fullPath, file.buffer);

    // Return relative storage path (for database)
    const storagePath = path.join(clinicId, patientId, conversationId, filename);

    return {
      storagePath: storagePath.replace(/\\/g, '/'), // Normalize path separators
      originalName: file.originalname,
      mimeType: file.mimetype,
      sizeBytes: file.size,
    };
  }

  /**
   * Read a file as base64 string (for OpenAI Vision API)
   * Validates file size before loading into memory
   */
  async readAsBase64(storagePath: string): Promise<string> {
    const fullPath = path.join(this.uploadDir, storagePath);

    if (!fs.existsSync(fullPath)) {
      throw new Error(`File not found: ${storagePath}`);
    }

    // Validar tamanho antes de carregar na memória (proteção contra OOM)
    const stats = await fs.promises.stat(fullPath);
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (stats.size > maxSize) {
      throw new Error(
        `File too large for processing: ${(stats.size / 1024 / 1024).toFixed(2)}MB (max: 10MB)`,
      );
    }

    console.log(`[StorageService] Reading file: ${storagePath} (${(stats.size / 1024).toFixed(1)}KB)`);
    const buffer = await fs.promises.readFile(fullPath);
    return buffer.toString('base64');
  }

  /**
   * Delete a file from storage
   */
  async deleteFile(storagePath: string): Promise<void> {
    const fullPath = path.join(this.uploadDir, storagePath);

    if (fs.existsSync(fullPath)) {
      await fs.promises.unlink(fullPath);
    }
  }

  /**
   * Get the full filesystem path for a stored file
   */
  getFullPath(storagePath: string): string {
    return path.join(this.uploadDir, storagePath);
  }

  /**
   * Validate file mime type for images
   */
  isValidImageMimeType(mimeType: string): boolean {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/heic', 'image/heif'];
    return allowedTypes.includes(mimeType.toLowerCase());
  }

  /**
   * Get file extension from mime type
   */
  private getExtensionFromMimeType(mimeType: string): string {
    const mimeToExt: Record<string, string> = {
      'image/jpeg': '.jpg',
      'image/png': '.png',
      'image/heic': '.heic',
      'image/heif': '.heif',
    };
    return mimeToExt[mimeType.toLowerCase()] || '.bin';
  }
}
