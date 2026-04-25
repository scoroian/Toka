import 'package:flutter/material.dart';

import '../../../../../core/theme/skin_switcher.dart';
import 'futurista/language_step_futurista.dart';
import 'language_step_v2.dart';

/// Wrapper que selecciona la implementación de [LanguageStep] según el skin
/// activo (v2 / futurista). Mantiene una API estable para el flujo onboarding.
class LanguageStep extends StatelessWidget {
  const LanguageStep({
    super.key,
    required this.selectedLocale,
    required this.onLocaleSelected,
    required this.onNext,
    required this.onPrev,
  });

  final String? selectedLocale;
  final ValueChanged<String> onLocaleSelected;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => LanguageStepV2(
          selectedLocale: selectedLocale,
          onLocaleSelected: onLocaleSelected,
          onNext: onNext,
          onPrev: onPrev,
        ),
        futurista: (_) => LanguageStepFuturista(
          selectedLocale: selectedLocale,
          onLocaleSelected: onLocaleSelected,
          onNext: onNext,
          onPrev: onPrev,
        ),
      );
}
