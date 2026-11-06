import 'package:flutter/material.dart';

/// Palette sobre et professionnelle pour une application SaaS de comptabilité.
class AppColors {
  AppColors._();

  // Marque
  static const Color primary = Color(0xFF2454FF);
  static const Color primaryDark = Color(0xFF1839C4);
  static const Color primarySoft = Color(0xFFEAF0FF);

  // Neutres
  static const Color background = Color(0xFFF6F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF1F3F8);
  static const Color border = Color(0xFFE3E6EE);
  static const Color textPrimary = Color(0xFF14162B);
  static const Color textSecondary = Color(0xFF676B85);
  static const Color textMuted = Color(0xFF9297AD);

  // Sémantique comptable
  static const Color debit = Color(0xFF2454FF);
  static const Color credit = Color(0xFF9333EA);
  static const Color success = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFE7F8ED);
  static const Color warning = Color(0xFFE58A00);
  static const Color warningSoft = Color(0xFFFFF3DF);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFCE8E8);
  static const Color info = Color(0xFF0891B2);
  static const Color infoSoft = Color(0xFFE3F6FA);

  // Dashboard
  static const Color revenue = Color(0xFF16A34A);
  static const Color expense = Color(0xFFDC2626);
  static const Color cash = Color(0xFF2454FF);

  // Dark mode
  static const Color backgroundDark = Color(0xFF0D0F1A);
  static const Color surfaceDark = Color(0xFF161927);
  static const Color surfaceAltDark = Color(0xFF1F2333);
  static const Color borderDark = Color(0xFF2A2E42);
  static const Color textPrimaryDark = Color(0xFFF3F4FA);
  static const Color textSecondaryDark = Color(0xFFA6AAC1);
}

/// Statuts génériques utilisés dans toute l'app (transactions, écritures, périodes...).
enum AppStatusTone { neutral, success, warning, danger, info }

extension AppStatusToneColors on AppStatusTone {
  Color get fg {
    switch (this) {
      case AppStatusTone.success:
        return AppColors.success;
      case AppStatusTone.warning:
        return AppColors.warning;
      case AppStatusTone.danger:
        return AppColors.danger;
      case AppStatusTone.info:
        return AppColors.info;
      case AppStatusTone.neutral:
        return AppColors.textSecondary;
    }
  }

  Color get bg {
    switch (this) {
      case AppStatusTone.success:
        return AppColors.successSoft;
      case AppStatusTone.warning:
        return AppColors.warningSoft;
      case AppStatusTone.danger:
        return AppColors.dangerSoft;
      case AppStatusTone.info:
        return AppColors.infoSoft;
      case AppStatusTone.neutral:
        return AppColors.surfaceAlt;
    }
  }
}
