import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class TodayEmptyState extends StatelessWidget {
  const TodayEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            l10n.today_empty_title,
            style: Theme.of(context).textTheme.titleLarge,
            key: const Key('today_empty_title'),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.today_empty_body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
            key: const Key('today_empty_body'),
          ),
        ],
      ),
    );
  }
}
