import 'branding_model.dart';

class ClinicModel {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final BrandingModel branding;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ClinicModel({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.address,
    this.phone,
    this.email,
    this.website,
    required this.branding,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  ClinicModel copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? address,
    String? phone,
    String? email,
    String? website,
    BrandingModel? branding,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClinicModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      branding: branding ?? this.branding,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ClinicModel.fromJson(Map<String, dynamic> json) {
    return ClinicModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      branding: json['branding'] != null
          ? BrandingModel.fromJson(json['branding'] as Map<String, dynamic>)
          : BrandingModel.defaultBranding(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'branding': branding.toJson(),
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
