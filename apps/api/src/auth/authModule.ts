import { Module } from '@nestjs/common';
import { AuthController } from './authController.js';
import { AuthService } from './authService.js';
import { PasswordHasher } from './passwordHasher.js';

@Module({
  controllers: [AuthController],
  providers: [AuthService, PasswordHasher],
  exports: [AuthService],
})
export class AuthModule {}
