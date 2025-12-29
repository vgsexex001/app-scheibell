import 'package:flutter/material.dart';
import '../models/branding_model.dart';
import '../models/clinic_model.dart';

class BrandingProvider extends ChangeNotifier {
  BrandingModel _branding = BrandingModel.defaultBranding();
  ClinicModel? _currentClinic;
  bool _isLoading = false;
  String? _errorMessage;

  BrandingModel get branding => _branding;
  ClinicModel? get currentClinic => _currentClinic;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ThemeData get themeData => _branding.toThemeData();
  Color get primaryColor => _branding.primaryColor;
  Color get secondaryColor => _branding.secondaryColor;
  Color get accentColor => _branding.accentColor;
  Color get backgroundColor => _branding.backgroundColor;
  Color get textColor => _branding.textColor;
  Color get textSecondaryColor => _branding.textSecondaryColor;
  String? get logoUrl => _branding.logoUrl ?? _currentClinic?.logoUrl;

  Future<void> loadClinicBranding(String clinicId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Implement actual clinic branding fetch from backend
      await Future.delayed(const Duration(milliseconds: 300));

      // For now, use default branding with mock clinic
      _currentClinic = ClinicModel(
        id: clinicId,
        name: 'Clínica Scheibell',
        description: 'Clínica especializada em procedimentos estéticos',
        branding: BrandingModel.defaultBranding(),
      );
      _branding = _currentClinic!.branding;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao carregar branding: ${e.toString()}';
      notifyListeners();
    }
  }

  void setClinic(ClinicModel clinic) {
    _currentClinic = clinic;
    _branding = clinic.branding;
    notifyListeners();
  }

  void setBranding(BrandingModel branding) {
    _branding = branding;
    notifyListeners();
  }

  void resetToDefault() {
    _branding = BrandingModel.defaultBranding();
    _currentClinic = null;
    notifyListeners();
  }

  Future<void> updateBranding({
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
    Color? backgroundColor,
    Color? textColor,
    Color? textSecondaryColor,
    String? fontFamily,
    String? logoUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement actual branding update with backend
      await Future.delayed(const Duration(milliseconds: 300));

      _branding = _branding.copyWith(
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
        accentColor: accentColor,
        backgroundColor: backgroundColor,
        textColor: textColor,
        textSecondaryColor: textSecondaryColor,
        fontFamily: fontFamily,
        logoUrl: logoUrl,
      );

      if (_currentClinic != null) {
        _currentClinic = _currentClinic!.copyWith(branding: _branding);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao atualizar branding: ${e.toString()}';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
