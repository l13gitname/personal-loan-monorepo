import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { AuthUser, CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import {
  CancelQuotationDto,
  CreateQuotationDto,
  SaveQuotationDto,
} from './dto/quotation.dto';
import { QuotationsService } from './quotations.service';

@ApiTags('quotations')
@ApiBearerAuth()
@Controller('quotations')
@UseGuards(JwtAuthGuard)
export class QuotationsController {
  constructor(private readonly quotations: QuotationsService) {}

  /** Create a draft for a product (PERSONAL_LOAN, MOTORCYCLE_LOAN, ...). Sections optional. */
  @Post()
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateQuotationDto, @Req() req: Request) {
    return this.quotations.createDraft({ userId: user.userId, ip: req.ip }, dto);
  }

  @Get()
  findMine(@CurrentUser() user: AuthUser) {
    return this.quotations.findMine(user.userId);
  }

  @Get(':id')
  findOne(@CurrentUser() user: AuthUser, @Param('id', ParseUUIDPipe) id: string) {
    return this.quotations.findOne(user.userId, id);
  }

  /** Save one or more sections of a draft (auto-save friendly). */
  @Patch(':id')
  save(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveQuotationDto,
    @Req() req: Request,
  ) {
    return this.quotations.saveDraft({ userId: user.userId, ip: req.ip }, id, dto);
  }

  @Post(':id/submit')
  submit(@CurrentUser() user: AuthUser, @Param('id', ParseUUIDPipe) id: string, @Req() req: Request) {
    return this.quotations.submit({ userId: user.userId, ip: req.ip }, id);
  }

  @Post(':id/cancel')
  cancel(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CancelQuotationDto,
  ) {
    return this.quotations.cancel({ userId: user.userId }, id, dto.reason);
  }
}
