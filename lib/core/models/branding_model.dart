import 'package:flutter/material.dart';

class BrandingModel {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color textColor;
  final Color textSecondaryColor;
  final String? fontFamily;
  final String? logoUrl;
  final String? faviconUrl;

  const BrandingModel({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.textColor,
    required this.textSecondaryColor,
    this.fontFamily,
    this.logoUrl,
    this.faviconUrl,
  });

  factory BrandingModel.defaultBranding() {
    return const BrandingModel(
      primaryColor: Color(0xFFA49E86),
      secondaryColor: Color(0xFF8B8573),
      accentColor: Color(0xFFD4CEB8),
      backgroundColor: Color(0xFFFAF9F7),
      textColor: Color(0xFF1A1A1A),
      textSecondaryColor: Color(0xFF6B6B6B),
      fontFamily: 'Inter',
    );
  }

  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: backgroundColor,
        onSurface: textColor,
      ),
      fontFamily: fontFamily,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: backgroundColor,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  BrandingModel copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
    Color? backgroundColor,
    Color? textColor,
    Color? textSecondaryColor,
    String? fontFamily,
    String? logoUrl,
    String? faviconUrl,
  }) {
    return BrandingModel(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      textSecondaryColor: textSecondaryColor ?? this.textSecondaryColor,
      fontFamily: fontFamily ?? this.fontFamily,
      logoUrl: logoUrl ?? this.logoUrl,
      faviconUrl: faviconUrl ?? this.faviconUrl,
    );
  }

  factory BrandingModel.fromJson(Map<String, dynamic> json) {
    return BrandingModel(
      primaryColor: _colorFromHex(json['primary_color'] as String? ?? '#A49E86'),
      secondaryColor: _colorFromHex(json['secondary_color'] as String? ?? '#8B8573'),
      accentColor: _colorFromHex(json['accent_color'] as String? ?? '#D4CEB8'),
      backgroundColor: _colorFromHex(json['background_color'] as String? ?? '#FAF9F7'),
      textColor: _colorFromHex(json['text_color'] as String? ?? '#1A1A1A'),
      textSecondaryColor: _colorFromHex(json['text_secondary_color'] as String? ?? '#6B6B6B'),
      fontFamily: json['font_family'] as String?,
      logoUrl: json['logo_url'] as String?,
      faviconUrl: json['favicon_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary_color': _colorToHex(primaryColor),
      'secondary_color': _colorToHex(secondaryColor),
      'accent_color': _colorToHex(accentColor),
      'background_color': _colorToHex(backgroundColor),
      'text_color': _colorToHex(textColor),
      'text_secondary_color': _colorToHex(textSecondaryColor),
      'font_family': fontFamily,
      'logo_url': logoUrl,
      'favicon_url': faviconUrl,
    };
  }

  static Color _colorFromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }
}
