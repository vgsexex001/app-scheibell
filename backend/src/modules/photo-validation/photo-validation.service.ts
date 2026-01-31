import { Injectable, Logger } from '@nestjs/common';
import {
  PHOTO_VALIDATION_SYSTEM_PROMPT,
  PHOTO_VALIDATION_FALLBACK,
  buildPhotoValidationUserPrompt,
  validatePhotoResponse,
  PhotoValidationResult,
} from '../../ai/prompts/photo-validation.prompt';

@Injectable()
export class PhotoValidationService {
  private readonly logger = new Logger(PhotoValidationService.name);

  /**
   * Valida qualidade de uma foto de pré-consulta usando OpenAI Vision
   */
  async validatePhoto(
    fileBuffer: Buffer,
    mimeType: string,
    photoType: 'frontal' | 'perfil_direito' | 'perfil_esquerdo',
  ): Promise<PhotoValidationResult> {
    try {
      const rawResponse = await this.analyzeWithOpenAI(fileBuffer, mimeType, photoType);
      const validated = validatePhotoResponse(rawResponse);

      this.logger.log(
        `Photo validation result: approved=${validated.approved}, confidence=${validated.confidence}, ` +
        `issues=[${validated.issues.join(', ')}], photoType=${photoType}`,
      );

      return validated;
    } catch (error) {
      this.logger.error(`Photo validation failed: ${error.message}`, error.stack);
      // Fail-open: se a IA falhar, aprova a foto (médico revisa depois)
      return PHOTO_VALIDATION_FALLBACK;
    }
  }

  /**
   * Chama OpenAI Vision para analisar a foto
   */
  private async analyzeWithOpenAI(
    fileBuffer: Buffer,
    mimeType: string,
    photoType: 'frontal' | 'perfil_direito' | 'perfil_esquerdo',
  ): Promise<unknown> {
    const OpenAI = require('openai');
    const openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY,
    });

    const base64Image = fileBuffer.toString('base64');
    const imageUrl = `data:${mimeType};base64,${base64Image}`;

    const response = await openai.chat.completions.create({
      model: 'gpt-4o',
      messages: [
        {
          role: 'system',
          content: PHOTO_VALIDATION_SYSTEM_PROMPT,
        },
        {
          role: 'user',
          content: [
            {
              type: 'text',
              text: buildPhotoValidationUserPrompt(photoType),
            },
            {
              type: 'image_url',
              image_url: {
                url: imageUrl,
                detail: 'high', // Alta resolução para detectar fundo sujo, acessórios, etc.
              },
            },
          ],
        },
      ],
      max_tokens: 600,
      response_format: { type: 'json_object' },
    });

    const content = response.choices[0]?.message?.content;
    if (!content) {
      this.logger.warn('OpenAI returned empty content, using fallback');
      return PHOTO_VALIDATION_FALLBACK;
    }

    try {
      return JSON.parse(content);
    } catch {
      this.logger.warn('Failed to parse OpenAI response as JSON, using fallback');
      return PHOTO_VALIDATION_FALLBACK;
    }
  }
}
