import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/json/json_helpers.dart';

part 'catalog_models.freezed.dart';
part 'catalog_models.g.dart';

@freezed
abstract class Product with _$Product {
  const Product._();

  const factory Product({
    required String id,
    required String code,

    /// `PERSONAL_LOAN` or `MOTORCYCLE_LOAN`.
    required String type,
    required String name,
    @JsonKey(fromJson: doubleFromJson) double? minAmount,
    @JsonKey(fromJson: doubleFromJson) double? maxAmount,
    int? minTermMonths,
    int? maxTermMonths,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);

  bool get isMotorcycle => type == 'MOTORCYCLE_LOAN';
}

@freezed
abstract class DocumentTypeInfo with _$DocumentTypeInfo {
  const factory DocumentTypeInfo({required String code, required String name}) =
      _DocumentTypeInfo;

  factory DocumentTypeInfo.fromJson(Map<String, dynamic> json) =>
      _$DocumentTypeInfoFromJson(json);
}

@freezed
abstract class DocumentRequirement with _$DocumentRequirement {
  const factory DocumentRequirement({
    required String documentTypeCode,
    required bool isRequired,
    @Default(1) int maxFiles,
    required DocumentTypeInfo documentType,
  }) = _DocumentRequirement;

  factory DocumentRequirement.fromJson(Map<String, dynamic> json) =>
      _$DocumentRequirementFromJson(json);
}

@freezed
abstract class ConsentDefinitionInfo with _$ConsentDefinitionInfo {
  const factory ConsentDefinitionInfo({
    required String title,

    /// `PDPA`, `SERVICE` or `STAFF_CHECKLIST`.
    required String category,
  }) = _ConsentDefinitionInfo;

  factory ConsentDefinitionInfo.fromJson(Map<String, dynamic> json) =>
      _$ConsentDefinitionInfoFromJson(json);
}

@freezed
abstract class ConsentRequirement with _$ConsentRequirement {
  const factory ConsentRequirement({
    required String consentCode,
    required String consentVersion,
    required bool isMandatory,
    required ConsentDefinitionInfo definition,
  }) = _ConsentRequirement;

  factory ConsentRequirement.fromJson(Map<String, dynamic> json) =>
      _$ConsentRequirementFromJson(json);
}

@freezed
abstract class ProductDetail with _$ProductDetail {
  const factory ProductDetail({
    required Product product,
    @Default([]) List<DocumentRequirement> documents,
    @Default([]) List<ConsentRequirement> consents,
  }) = _ProductDetail;

  factory ProductDetail.fromJson(Map<String, dynamic> json) =>
      _$ProductDetailFromJson(json);
}
