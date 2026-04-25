import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../i18n/application/language_provider.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../../shared/widgets/futurista/tocka_btn.dart';

/// Pantalla LanguageStep de la skin futurista. Mantiene la misma signatura
/// que [LanguageStepV2] para compartir VM y callbacks.
class LanguageStepFuturista extends ConsumerWidget {
  const LanguageStepFuturista({
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final languagesAsync = ref.watch(availableLanguagesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero icon container.
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cs.primary.withValues(alpha: 0.19),
                      cs.primary.withValues(alpha: 0.04),
                    ],
                  ),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.33),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.55),
                      blurRadius: 60,
                      offset: const Offset(0, 30),
                      spreadRadius: -20,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.language,
                    size: 40,
                    color: cs.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Display title.
            Text(
              l10n.onboarding_language_title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            // Subtitle.
            Text(
              'Podrás cambiarlo desde Ajustes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            // Language list.
            Expanded(
              child: languagesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(child: Text(l10n.error_generic)),
                data: (languages) => RadioGroup<String>(
                  groupValue: selectedLocale ?? '',
                  onChanged: (v) => onLocaleSelected(v ?? ''),
                  child: ListView.separated(
                    key: const Key('language_list'),
                    itemCount: languages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final lang = languages[i];
                      final isSelected = selectedLocale == lang.code;
                      return InkWell(
                        key: Key('lang_${lang.code}'),
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => onLocaleSelected(lang.code),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cs.primary.withValues(alpha: 0.09)
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? cs.primary.withValues(alpha: 0.55)
                                  : theme.dividerColor,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                lang.flag,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    Text(
                                      lang.code.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'JetBrainsMono',
                                        fontSize: 11,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  size: 20,
                                  color: cs.primary,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  key: const Key('prev_button'),
                  onPressed: onPrev,
                  child: Text(l10n.back),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TockaBtn(
                    key: const Key('next_button'),
                    variant: TockaBtnVariant.glow,
                    size: TockaBtnSize.lg,
                    fullWidth: true,
                    onPressed: onNext,
                    child: Text(l10n.next),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
