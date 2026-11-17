import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Res,
  StreamableFile,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { Response } from 'express';
import { AuthUser, CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { DocumentsService } from './documents.service';

@ApiTags('documents')
@ApiBearerAuth()
@Controller('quotations/:quotationId/documents')
@UseGuards(JwtAuthGuard)
export class DocumentsController {
  constructor(private readonly documents: DocumentsService) {}

  /** multipart/form-data: `file` + `documentTypeCode`. */
  @Post()
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['file', 'documentTypeCode'],
      properties: {
        file: { type: 'string', format: 'binary' },
        documentTypeCode: { type: 'string', example: 'ID_CARD' },
      },
    },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      // Hard ceiling at the HTTP layer; the service enforces MAX_UPLOAD_MB.
      limits: { fileSize: 25 * 1024 * 1024, files: 1 },
    }),
  )
  upload(
    @CurrentUser() user: AuthUser,
    @Param('quotationId', ParseUUIDPipe) quotationId: string,
    @Body('documentTypeCode') documentTypeCode: string,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!documentTypeCode) throw new BadRequestException('documentTypeCode is required');
    return this.documents.upload(user.userId, quotationId, documentTypeCode, file);
  }

  @Get()
  list(
    @CurrentUser() user: AuthUser,
    @Param('quotationId', ParseUUIDPipe) quotationId: string,
  ) {
    return this.documents.list(user.userId, quotationId);
  }

  @Get(':documentId/download')
  async download(
    @CurrentUser() user: AuthUser,
    @Param('quotationId', ParseUUIDPipe) quotationId: string,
    @Param('documentId', ParseUUIDPipe) documentId: string,
    @Res({ passthrough: true }) res: Response,
  ) {
    const { doc, stream } = await this.documents.openForDownload(user.userId, quotationId, documentId);
    res.set({
      'Content-Type': doc.contentType,
      'Content-Length': String(doc.sizeBytes),
      'Content-Disposition': `attachment; filename*=UTF-8''${encodeURIComponent(doc.originalName)}`,
      'X-Content-Type-Options': 'nosniff',
      'Cache-Control': 'private, no-store',
    });
    return new StreamableFile(stream);
  }

  @Delete(':documentId')
  cancel(
    @CurrentUser() user: AuthUser,
    @Param('quotationId', ParseUUIDPipe) quotationId: string,
    @Param('documentId', ParseUUIDPipe) documentId: string,
  ) {
    return this.documents.cancel(user.userId, quotationId, documentId);
  }
}
