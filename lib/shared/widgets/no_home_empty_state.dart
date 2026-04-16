import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/homes/presentation/home_selector_widget.dart';
import '../../l10n/app_localizations.dart';

class NoHomeEmptyState extends ConsumerWidget {
  const NoHomeEmptyState({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              key: const Key('no_home_create_button'),
              onPressed: () => showCreateHomeSheet(context, ref, 0),
              icon: const Icon(Icons.add),
              label: Text(l10n.onboarding_create_home_button),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('no_home_join_button'),
              onPressed: () => showJoinHomeSheet(context, ref, 0),
              icon: const Icon(Icons.group_add_outlined),
              label: Text(l10n.onboarding_join_home),
            ),
          ],
        ),
      ),
    );
  }
}
