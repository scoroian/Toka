import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../features/i18n/application/language_provider.dart';
import '../../../../../features/i18n/domain/language.dart';
import '../../../../../features/i18n/domain/languages_result.dart';
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

    // Con solo 3 idiomas no hace falta confirmar: seleccionar avanza al
    // siguiente paso. El botón "Siguiente" se mantiene para quien ya tenía
    // idioma elegido (p. ej. al volver atrás) y no quiere re-tocar la lista.
    void selectAndAdvance(String code) {
      onLocaleSelected(code);
      onNext();
    }

    Widget buildList(LanguagesResult result) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (result.isFallback)
            _OfflineLanguagesBanner(
              message: l10n.language_offline_notice,
              retryLabel: l10n.retry,
              onRetry: () => ref.invalidate(availableLanguagesProvider),
            ),
          Expanded(
            child: RadioGroup<String>(
              groupValue: selectedLocale ?? '',
              onChanged: (v) {
                if (v != null) selectAndAdvance(v);
              },
              child: ListView.builder(
                key: const Key('language_list'),
                itemCount: result.languages.length,
                itemBuilder: (context, i) {
                  final lang = result.languages[i];
                  return RadioListTile<String>(
                    key: Key('lang_${lang.code}'),
                    value: lang.code,
                    title: Text('${lang.flag}  ${lang.name}'),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

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
                // El repositorio nunca lanza por fallo de red (devuelve los
                // idiomas básicos como fallback), pero por robustez ante un
                // error inesperado mostramos igualmente los defaults + retry,
                // para que el onboarding nunca quede sin salida.
                error: (_, __) => buildList(const LanguagesResult(
                  languages: Language.defaults,
                  isFallback: true,
                )),
                data: buildList,
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

/// Aviso mostrado cuando la lista remota de idiomas no se pudo cargar (sin red)
/// y se están usando los idiomas básicos. Ofrece "Reintentar" para recargar la
/// lista completa cuando vuelva la conexión.
class _OfflineLanguagesBanner extends StatelessWidget {
  const _OfflineLanguagesBanner({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('language_offline_notice'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            key: const Key('retry_languages'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}
