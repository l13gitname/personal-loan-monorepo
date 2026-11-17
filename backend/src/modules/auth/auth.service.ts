import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService, JwtSignOptions } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { createHash, randomUUID } from 'crypto';
import { PrismaService } from '../../infrastructure/database/prisma.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  async register(dto: RegisterDto) {
    const email = dto.email.trim().toLowerCase();
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) throw new ConflictException('Email is already registered');

    const passwordHash = await bcrypt.hash(dto.password, 12);
    const user = await this.prisma.user.create({
      data: {
        email,
        passwordHash,
        firstName: dto.firstName.trim(),
        lastName: dto.lastName.trim(),
      },
      select: { id: true, email: true, firstName: true, lastName: true },
    });

    return { user };
  }

  async login(dto: LoginDto, ipAddress?: string, userAgent?: string) {
    const email = dto.email.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({ where: { email } });

    if (
      !user ||
      user.status !== 'ACTIVE' ||
      !(await bcrypt.compare(dto.password, user.passwordHash))
    ) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const sessionId = randomUUID();
    const refreshSecret = randomUUID() + randomUUID();
    const refreshToken = `${sessionId}.${refreshSecret}`;
    const refreshTokenHash = createHash('sha256').update(refreshToken).digest('hex');
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    await this.prisma.session.create({
      data: {
        id: sessionId,
        userId: user.id,
        refreshTokenHash,
        expiresAt,
        ipAddress,
        userAgent,
      },
    });

    const accessToken = await this.jwt.signAsync(
      { sub: user.id, sid: sessionId },
      {
        secret: this.config.getOrThrow<string>('JWT_ACCESS_SECRET'),
        expiresIn: (this.config.get<string>('JWT_ACCESS_TTL') ?? '15m') as JwtSignOptions['expiresIn'],
      },
    );

    return {
      user: {
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
      },
      accessToken,
      refreshToken,
      tokenType: 'Bearer',
      expiresIn: this.config.get<string>('JWT_ACCESS_TTL') ?? '15m',
    };
  }

  async refresh(refreshToken: string) {
    const [sessionId, ...secretParts] = refreshToken.split('.');
    const secret = secretParts.join('.');
    if (!sessionId || !secret) throw new UnauthorizedException('Invalid refresh token');

    const oldHash = createHash('sha256').update(refreshToken).digest('hex');
    const session = await this.prisma.session.findFirst({
      where: { id: sessionId, refreshTokenHash: oldHash, revokedAt: null, expiresAt: { gt: new Date() } },
      include: { user: true },
    });
    if (!session || session.user.status !== 'ACTIVE') {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    const nextToken = `${session.id}.${randomUUID()}${randomUUID()}`;
    const nextHash = createHash('sha256').update(nextToken).digest('hex');
    const rotated = await this.prisma.session.updateMany({
      where: { id: session.id, refreshTokenHash: oldHash, revokedAt: null, expiresAt: { gt: new Date() } },
      data: { refreshTokenHash: nextHash },
    });
    if (rotated.count !== 1) throw new UnauthorizedException('Refresh token has already been used');

    const accessToken = await this.jwt.signAsync(
      { sub: session.userId, sid: session.id },
      {
        secret: this.config.getOrThrow<string>('JWT_ACCESS_SECRET'),
        expiresIn: (this.config.get<string>('JWT_ACCESS_TTL') ?? '15m') as JwtSignOptions['expiresIn'],
      },
    );
    return {
      accessToken,
      refreshToken: nextToken,
      tokenType: 'Bearer',
      expiresIn: this.config.get<string>('JWT_ACCESS_TTL') ?? '15m',
    };
  }

  async validateAccessToken(token: string) {
    try {
      const payload = await this.jwt.verifyAsync<{ sub: string; sid: string }>(
        token,
        { secret: this.config.getOrThrow<string>('JWT_ACCESS_SECRET') },
      );

      const session = await this.prisma.session.findFirst({
        where: {
          id: payload.sid,
          userId: payload.sub,
          revokedAt: null,
          expiresAt: { gt: new Date() },
        },
        select: { id: true },
      });

      if (!session) throw new UnauthorizedException();
      return { userId: payload.sub, sessionId: payload.sid };
    } catch {
      throw new UnauthorizedException('Invalid or expired access token');
    }
  }

  async logout(sessionId: string, userId: string) {
    await this.prisma.session.updateMany({
      where: { id: sessionId, userId, revokedAt: null },
      data: { revokedAt: new Date(), refreshTokenHash: null },
    });
    return { success: true };
  }
}
