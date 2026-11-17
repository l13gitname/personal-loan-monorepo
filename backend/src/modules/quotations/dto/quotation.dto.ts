import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsDateString,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import {
  AddressKind,
  IdentityType,
  OccupationKind,
  PersonRole,
  SourceChannel,
} from '@prisma/client';

const str = (max: number) => [IsOptional(), IsString(), MaxLength(max)];
function Opt(max: number): PropertyDecorator {
  return (target, key) => str(max).forEach((d) => d(target, key));
}

export class AddressDto {
  @Opt(50) houseNo?: string;
  @Opt(20) moo?: string;
  @Opt(200) buildingName?: string;
  @Opt(30) roomNo?: string;
  @Opt(30) floor?: string;
  @Opt(100) soi?: string;
  @Opt(100) road?: string;
  @Opt(100) subDistrict?: string;
  @Opt(100) district?: string;
  @Opt(3) provinceCode?: string;
  @Opt(100) provinceName?: string;
  @Opt(5) postalCode?: string;
  @Opt(20) locationCode?: string;
}

export class AddressInputDto extends AddressDto {
  @IsEnum(AddressKind) kind!: AddressKind;
}

export class ApplicantDto {
  @Opt(10) titleCode?: string;
  @Opt(50) titleName?: string;
  @IsString() @MaxLength(100) firstName!: string;
  @IsString() @MaxLength(100) lastName!: string;
  @Opt(50) nickname?: string;
  @IsOptional() @IsDateString() birthDate?: string;
  @IsString() @MaxLength(30) phoneNumber!: string;
  @Opt(20) maritalStatus?: string;
  @Opt(10) nationalityCode?: string;
  @IsOptional() @IsEnum(IdentityType) identityType?: IdentityType;
  @Opt(10) identityCode?: string;
  @Opt(30) idCardNumber?: string;
  @Opt(50) passportNo?: string;
  @IsOptional() @IsDateString() idCardIssuedAt?: string;
  @IsOptional() @IsDateString() idCardExpiresAt?: string;
  @Opt(20) houseType?: string;
  @Opt(20) houseOwnerType?: string;
  @IsOptional() @IsInt() @Min(0) stayedYears?: number;
  @IsOptional() @IsInt() @Min(0) stayedMonths?: number;
}

export class OccupationDto {
  @IsEnum(OccupationKind) kind!: OccupationKind;
  @Opt(20) careerCode?: string;
  @Opt(200) careerName?: string;
  @Opt(200) workplaceName?: string;
  @Opt(150) position?: string;
  @Opt(200) department?: string;
  @IsOptional() @IsInt() @Min(0) experienceYears?: number;
  @IsOptional() @IsInt() @Min(0) experienceMonths?: number;
  @IsOptional() @IsNumber() @Min(0) salaryPerMonth?: number;
  @IsOptional() @IsNumber() @Min(0) salaryPerDay?: number;
  @Opt(200) leaderName?: string;
  @IsOptional() @IsInt() @Min(0) workDaysPerWeek?: number;
  @Opt(30) workplacePhone1?: string;
  @Opt(30) workplacePhone2?: string;
}

export class BankAccountDto {
  @Opt(10) bankCode?: string;
  @Opt(100) bankName?: string;
  @Opt(100) branchName?: string;
  @Opt(30) accountNo?: string;
}

export class LoanRequestDto {
  @IsOptional() @IsNumber() @Min(0) productValue?: number;
  @IsOptional() @IsNumber() @Min(0) downPayment?: number;
  @IsNumber() @Min(1) loanAmount!: number;
  @IsInt() @Min(1) termMonths!: number;
  @IsOptional() @IsNumber() @Min(0) interestRate?: number;
  @IsOptional() @IsNumber() @Min(0) installmentAmount?: number;
  @Opt(10) purposeCode?: string;
  @Opt(1000) purposeName?: string;
  @Opt(200) purposeOther?: string;
  @Opt(10) reasonCode?: string;
  @Opt(1000) reasonName?: string;
}

/** Motorcycle-loan only. */
export class VehicleDto {
  @Opt(20) brandCode?: string;
  @Opt(100) brandName?: string;
  @Opt(30) modelCode?: string;
  @Opt(200) modelName?: string;
  @Opt(500) modelDescription?: string;
  @IsOptional() @IsInt() @Min(1900) modelYear?: number;
  @Opt(30) sizeModel?: string;
  @Opt(20) colorCode?: string;
  @Opt(100) colorName?: string;
  @IsOptional() @IsInt() @Min(0) engineCc?: number;
  @Opt(30) fuelType?: string;
  @IsOptional() @IsNumber() @Min(0) factoryPrice?: number;
  @Opt(10) grade?: string;
  @Opt(30) regNo?: string;
  @IsOptional() @IsDateString() regDate?: string;
  @Opt(3) regProvinceCode?: string;
  @Opt(100) regProvinceName?: string;
  @IsOptional() @IsInt() @Min(0) mileage?: number;
  @Opt(30) oldContractRef?: string;
  @Opt(50) motorNumber?: string;
  @Opt(50) motorPower?: string;
  @Opt(50) batteryType?: string;
  @Opt(50) batteryCapacity?: string;
  @IsOptional() @IsBoolean() isOverMaxLtv?: boolean;
  @Opt(500) overMaxLtvReason?: string;
}

export class InsuranceDto {
  @Opt(20) code?: string;
  @Opt(200) name?: string;
  @IsOptional() @IsInt() @Min(0) years?: number;
  @IsOptional() @IsNumber() @Min(0) planPrice?: number;
  @IsOptional() @IsBoolean() includedInLoan?: boolean;
}

export class PersonDto {
  @IsEnum(PersonRole) role!: PersonRole;
  @Opt(300) fullName?: string;
  @Opt(200) relation?: string;
  @Opt(50) phoneNumber?: string;
  @Opt(30) citizenId?: string;
  @Opt(10) userTypeCode?: string;
  @Opt(200) userTypeName?: string;
  @IsOptional() @ValidateNested() @Type(() => AddressDto) address?: AddressDto;
}

export class ConsentInputDto {
  @IsString() @MaxLength(60) consentCode!: string;
  @IsString() @MaxLength(30) version!: string;
  @IsBoolean() accepted!: boolean;
  @Opt(20) value?: string;
}

/** Every section is optional so a draft can be saved step by step. */
export class SaveQuotationDto {
  @IsOptional() @ValidateNested() @Type(() => ApplicantDto) applicant?: ApplicantDto;

  @IsOptional() @IsArray() @ValidateNested({ each: true }) @Type(() => AddressInputDto)
  addresses?: AddressInputDto[];

  @IsOptional() @IsArray() @ValidateNested({ each: true }) @Type(() => OccupationDto)
  occupations?: OccupationDto[];

  @IsOptional() @ValidateNested() @Type(() => BankAccountDto) bankAccount?: BankAccountDto;
  @IsOptional() @ValidateNested() @Type(() => LoanRequestDto) loanRequest?: LoanRequestDto;
  @IsOptional() @ValidateNested() @Type(() => VehicleDto) vehicle?: VehicleDto;
  @IsOptional() @ValidateNested() @Type(() => InsuranceDto) insurance?: InsuranceDto;

  @IsOptional() @IsArray() @ValidateNested({ each: true }) @Type(() => PersonDto)
  persons?: PersonDto[];

  @IsOptional() @IsArray() @ValidateNested({ each: true }) @Type(() => ConsentInputDto)
  consents?: ConsentInputDto[];
}

export class CreateQuotationDto extends SaveQuotationDto {
  @IsString() @MaxLength(50) productCode!: string;
  @IsOptional() @IsEnum(SourceChannel) channel?: SourceChannel;
  @Opt(30) dealerCode?: string;
  @Opt(30) checkerCode?: string;
  @Opt(30) clientVersion?: string;
}

export class CancelQuotationDto {
  @Opt(500) reason?: string;
}
