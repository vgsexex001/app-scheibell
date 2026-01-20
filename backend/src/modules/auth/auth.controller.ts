import {
  Controller,
  Post,
  Get,
  Put,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
  Req,
  Headers,
} from '@nestjs/common';
import { Request } from 'express';
import { AuthService, AuthResponse } from './auth.service';
import { LoginDto, RegisterDto, UpdateProfileDto, ChangePasswordDto, RefreshTokenDto, ForgotPasswordDto, ResetPasswordDto } from './dto';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { CurrentUser, JwtPayload } from '../../common/decorators/current-user.decorator';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  async register(@Body() dto: RegisterDto): Promise<AuthResponse> {
    return this.authService.register(dto);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(
    @Body() dto: LoginDto,
    @Req() req: Request,
    @Headers('user-agent') userAgent?: string,
  ): Promise<AuthResponse> {
    const ipAddress = req.ip || req.headers['x-forwarded-for'] as string || 'unknown';
    return this.authService.login(dto, ipAddress, userAgent);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getProfile(@CurrentUser() user: JwtPayload) {
    return this.authService.getProfile(user.sub);
  }

  @Put('me')
  @UseGuards(JwtAuthGuard)
  async updateProfile(
    @CurrentUser() user: JwtPayload,
    @Body() dto: UpdateProfileDto,
  ) {
    return this.authService.updateProfile(user.sub, dto);
  }

  @Post('change-password')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async changePassword(
    @CurrentUser() user: JwtPayload,
    @Body() dto: ChangePasswordDto,
  ) {
    return this.authService.changePassword(user.sub, dto);
  }

  @Get('validate')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async validateToken(@CurrentUser() user: JwtPayload) {
    return {
      valid: true,
      user: await this.authService.validateUser(user.sub),
    };
  }

  /**
   * Renova access token usando refresh token
   * POST /api/auth/refresh
   */
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  async refreshTokens(@Body() dto: RefreshTokenDto): Promise<AuthResponse> {
    return this.authService.refreshTokens(dto.refreshToken);
  }

  /**
   * Logout - revoga todos os refresh tokens do usuário
   * POST /api/auth/logout
   */
  @Post('logout')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async logout(@CurrentUser() user: JwtPayload) {
    return this.authService.revokeAllRefreshTokens(user.sub);
  }

  // ==================== PASSWORD RESET ====================

  /**
   * Solicita reset de senha (esqueci minha senha)
   * POST /api/auth/forgot-password
   */
  @Post('forgot-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Solicitar reset de senha' })
  @ApiResponse({ status: 200, description: 'Instruções enviadas (se email existir)' })
  async forgotPassword(@Body() dto: ForgotPasswordDto) {
    return this.authService.forgotPassword(dto);
  }

  /**
   * Valida se o token de reset ainda é válido
   * POST /api/auth/validate-reset-token
   */
  @Post('validate-reset-token')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Validar token de reset de senha' })
  @ApiResponse({ status: 200, description: 'Status do token' })
  async validateResetToken(@Body('token') token: string) {
    return this.authService.validateResetToken(token);
  }

  /**
   * Redefine a senha usando o token
   * POST /api/auth/reset-password
   */
  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Redefinir senha com token' })
  @ApiResponse({ status: 200, description: 'Senha redefinida com sucesso' })
  @ApiResponse({ status: 400, description: 'Token inválido ou expirado' })
  async resetPassword(@Body() dto: ResetPasswordDto) {
    return this.authService.resetPassword(dto);
  }

  // ==================== MAGIC LINK SYNC ====================

  /**
   * Sincroniza usuário que acessou via Magic Link do Supabase
   * Cria o usuário na tabela users se não existir e vincula ao Patient pré-cadastrado
   * POST /api/auth/sync-magic-link
   */
  @Post('sync-magic-link')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Sincronizar usuário do Magic Link' })
  @ApiResponse({ status: 200, description: 'Usuário sincronizado' })
  async syncMagicLink(
    @Body() dto: { authId: string; email: string; name?: string; clinicId?: string },
  ) {
    return this.authService.syncMagicLinkUser(dto);
  }
}
