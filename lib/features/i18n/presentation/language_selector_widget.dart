import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/language_provider.dart';
import '../application/locale_provider.dart';
import '../domain/language.dart';

class LanguageSelectorWidget extends ConsumerWidget {
  const LanguageSelectorWidget({
    super.key,
    this.showTitle = true,
    this.onSelected,
  });

  final bool showTitle;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeNotifierProvider);
    final languagesAsync = ref.watch(availableLanguagesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          Text(
            l10n.language_select_title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.language_select_subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
        ],
        languagesAsync.when(
          data: (languages) => _LanguageList(
            languages: languages,
            currentLocale: currentLocale,
            onSelected: onSelected,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(l10n.error_generic)),
        ),
      ],
    );
  }
}

class _LanguageList extends ConsumerWidget {
  const _LanguageList({
    required this.languages,
    required this.currentLocale,
    this.onSelected,
  });

  final List<Language> languages;
  final Locale currentLocale;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: languages.length,
      itemBuilder: (context, index) {
        final lang = languages[index];
        final isSelected = lang.code == currentLocale.languageCode;
        return ListTile(
          leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
          title: Text(lang.name),
          trailing: isSelected
              ? Icon(
                  Icons.radio_button_checked,
                  color: Theme.of(context).colorScheme.primary,
                )
              : const Icon(Icons.radio_button_unchecked),
          onTap: () => _selectLanguage(ref, lang.code),
          selected: isSelected,
        );
      },
    );
  }

  void _selectLanguage(WidgetRef ref, String code) {
    ref.read(localeNotifierProvider.notifier).setLocale(code, null);
    onSelected?.call();
  }
}
