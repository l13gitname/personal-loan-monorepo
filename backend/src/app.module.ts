import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { DatabaseModule } from './infrastructure/database/database.module';
import { HealthController } from './health.controller';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { QuotationsModule } from './modules/quotations/quotations.module';
import { CatalogModule } from './modules/catalog/catalog.module';
import { DocumentsModule } from './modules/documents/documents.module';
import { StorageModule } from './infrastructure/storage/storage.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    JwtModule.register({ global: true }),
    DatabaseModule,
    StorageModule,
    AuthModule,
    UsersModule,
    CatalogModule,
    DocumentsModule,
    QuotationsModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
