import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../features/i18n/application/language_provider.dart';
import '../../../../../l10n/app_localizations.dart';

class LanguageStepV2 extends ConsumerWidget {
  const LanguageStepV2({
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
    final l10n = AppLocalizations.of(context);
    final languagesAsync = ref.watch(availableLanguagesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              l10n.onboarding_language_title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: languagesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(child: Text(l10n.error_generic)),
                data: (languages) => RadioGroup<String>(
                  groupValue: selectedLocale ?? '',
                  onChanged: (v) => onLocaleSelected(v ?? ''),
                  child: ListView.builder(
                    key: const Key('language_list'),
                    itemCount: languages.length,
                    itemBuilder: (context, i) {
                      final lang = languages[i];
                      return RadioListTile<String>(
                        key: Key('lang_${lang.code}'),
                        value: lang.code,
                        title: Text('${lang.flag}  ${lang.name}'),
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
                  child: FilledButton(
                    key: const Key('next_button'),
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
