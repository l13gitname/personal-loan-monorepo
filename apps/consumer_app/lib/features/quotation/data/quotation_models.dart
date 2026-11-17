import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/json/json_helpers.dart';
import '../../catalog/data/catalog_models.dart';

part 'quotation_models.freezed.dart';
part 'quotation_models.g.dart';

// ── Sections (same shape for request and response) ──────────────────────────

@freezed
abstract class ApplicantData with _$ApplicantData {
  const factory ApplicantData({
    String? titleName,
    required String firstName,
    required String lastName,
    String? nickname,
    @JsonKey(fromJson: dateOnlyFromJson) String? birthDate,
    required String phoneNumber,
    String? idCardNumber,
    String? maritalStatus,
  }) = _ApplicantData;

  factory ApplicantData.fromJson(Map<String, dynamic> json) =>
      _$ApplicantDataFromJson(json);
}

/// `kind` is ID_CARD, LIVING, CONTACT or WORKING.
@freezed
abstract class AddressEntry with _$AddressEntry {
  const factory AddressEntry({
    required String kind,
    String? houseNo,
    String? moo,
    String? soi,
    String? road,
    String? subDistrict,
    String? district,
    String? provinceName,
    String? postalCode,
  }) = _AddressEntry;

  factory AddressEntry.fromJson(Map<String, dynamic> json) =>
      _$AddressEntryFromJson(json);
}

/// `kind` is MAIN or SUB.
@freezed
abstract class OccupationData with _$OccupationData {
  const factory OccupationData({
    required String kind,
    String? careerName,
    String? workplaceName,
    String? position,
    @JsonKey(fromJson: doubleFromJson) double? salaryPerMonth,
    String? workplacePhone1,
  }) = _OccupationData;

  factory OccupationData.fromJson(Map<String, dynamic> json) =>
      _$OccupationDataFromJson(json);
}

@freezed
abstract class LoanRequestData with _$LoanRequestData {
  const factory LoanRequestData({
    @JsonKey(fromJson: doubleRequiredFromJson) required double loanAmount,
    required int termMonths,
    @JsonKey(fromJson: doubleFromJson) double? productValue,
    @JsonKey(fromJson: doubleFromJson) double? downPayment,
    @JsonKey(fromJson: doubleFromJson) double? installmentAmount,
    @JsonKey(fromJson: doubleFromJson) double? interestRate,
    String? purposeName,
  }) = _LoanRequestData;

  factory LoanRequestData.fromJson(Map<String, dynamic> json) =>
      _$LoanRequestDataFromJson(json);
}

/// Motorcycle loan only.
@freezed
abstract class VehicleData with _$VehicleData {
  const factory VehicleData({
    String? brandCode,
    String? brandName,
    String? modelCode,
    String? modelName,
    int? modelYear,
    String? colorName,
    int? engineCc,
  }) = _VehicleData;

  factory VehicleData.fromJson(Map<String, dynamic> json) =>
      _$VehicleDataFromJson(json);
}

@freezed
abstract class ConsentData with _$ConsentData {
  const factory ConsentData({
    required String consentCode,
    @JsonKey(name: 'version', readValue: _readConsentVersion) required String version,
    required bool accepted,
  }) = _ConsentData;

  factory ConsentData.fromJson(Map<String, dynamic> json) =>
      _$ConsentDataFromJson(json);
}

/// Requests send `version`, responses return `consentVersion`.
Object? _readConsentVersion(Map<dynamic, dynamic> map, String key) =>
    map['version'] ?? map['consentVersion'];

// ── Request ─────────────────────────────────────────────────────────────────

/// Any subset of sections; the server merges them into the draft.
@freezed
abstract class SaveQuotationRequest with _$SaveQuotationRequest {
  const factory SaveQuotationRequest({
    ApplicantData? applicant,
    List<AddressEntry>? addresses,
    List<OccupationData>? occupations,
    LoanRequestData? loanRequest,
    VehicleData? vehicle,
    List<ConsentData>? consents,
  }) = _SaveQuotationRequest;

  factory SaveQuotationRequest.fromJson(Map<String, dynamic> json) =>
      _$SaveQuotationRequestFromJson(json);
}

// ── Response ────────────────────────────────────────────────────────────────

class QuotationSummary {
  const QuotationSummary({
    required this.id,
    required this.quotationNo,
    required this.status,
    required this.productName,
    required this.productType,
    this.loanAmount,
    this.termMonths,
    this.applicantName,
  });

  final String id;
  final int quotationNo;
  final String status;
  final String productName;
  final String productType;
  final double? loanAmount;
  final int? termMonths;
  final String? applicantName;

  bool get isDraft => status == 'DRAFT';

  factory QuotationSummary.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? const {};
    final loan = json['loanRequest'] as Map<String, dynamic>?;
    final applicant = json['applicant'] as Map<String, dynamic>?;
    return QuotationSummary(
      id: json['id'] as String,
      quotationNo: json['quotationNo'] as int,
      status: json['status'] as String,
      productName: product['name'] as String? ?? '',
      productType: product['type'] as String? ?? '',
      loanAmount: doubleFromJson(loan?['loanAmount']),
      termMonths: loan?['termMonths'] as int?,
      applicantName: applicant == null
          ? null
          : '${applicant['firstName']} ${applicant['lastName']}',
    );
  }
}

class QuotationDetail {
  const QuotationDetail({
    required this.id,
    required this.quotationNo,
    required this.status,
    required this.product,
    this.applicant,
    this.addresses = const [],
    this.occupations = const [],
    this.loanRequest,
    this.vehicle,
    this.consents = const [],
  });

  final String id;
  final int quotationNo;
  final String status;
  final Product product;
  final ApplicantData? applicant;
  final List<AddressEntry> addresses;
  final List<OccupationData> occupations;
  final LoanRequestData? loanRequest;
  final VehicleData? vehicle;
  final List<ConsentData> consents;

  bool get isDraft => status == 'DRAFT';

  AddressEntry? address(String kind) {
    for (final a in addresses) {
      if (a.kind == kind) return a;
    }
    return null;
  }

  OccupationData? occupation(String kind) {
    for (final o in occupations) {
      if (o.kind == kind) return o;
    }
    return null;
  }

  bool consentAccepted(String code) =>
      consents.any((c) => c.consentCode == code && c.accepted);

  factory QuotationDetail.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) map) =>
        ((json[key] as List<dynamic>?) ?? const [])
            .map((e) => map(e as Map<String, dynamic>))
            .toList();

    return QuotationDetail(
      id: json['id'] as String,
      quotationNo: json['quotationNo'] as int,
      status: json['status'] as String,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      applicant: json['applicant'] == null
          ? null
          : ApplicantData.fromJson(json['applicant'] as Map<String, dynamic>),
      // API returns [{kind, address: {...}}]; flatten to AddressEntry.
      addresses: list('addresses', (e) {
        final address = (e['address'] as Map<String, dynamic>?) ?? const {};
        return AddressEntry.fromJson({...address, 'kind': e['kind']});
      }),
      occupations: list('occupations', OccupationData.fromJson),
      loanRequest: json['loanRequest'] == null
          ? null
          : LoanRequestData.fromJson(json['loanRequest'] as Map<String, dynamic>),
      vehicle: json['vehicle'] == null
          ? null
          : VehicleData.fromJson(json['vehicle'] as Map<String, dynamic>),
      consents: list('consents', ConsentData.fromJson),
    );
  }
}
