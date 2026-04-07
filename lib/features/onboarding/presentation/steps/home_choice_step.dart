import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../widgets/home_join_form.dart';

enum _HomeChoice { none, create, join }

class HomeChoiceStep extends StatefulWidget {
  const HomeChoiceStep({
    super.key,
    required this.isLoading,
    required this.error,
    required this.onCreateHome,
    required this.onJoinHome,
    required this.onPrev,
  });

  final bool isLoading;
  final String? error;
  final Future<void> Function(String name, String? emoji) onCreateHome;
  final Future<void> Function(String code) onJoinHome;
  final VoidCallback onPrev;

  @override
  State<HomeChoiceStep> createState() => _HomeChoiceStepState();
}

class _HomeChoiceStepState extends State<HomeChoiceStep> {
  _HomeChoice _choice = _HomeChoice.none;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              l10n.onboarding_home_choice_title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_choice == _HomeChoice.none) ...[
              _ChoiceCard(
                key: const Key('create_home_card'),
                icon: Icons.home_rounded,
                title: l10n.onboarding_create_home,
                description: l10n.onboarding_create_home_description,
                onTap: () => setState(() => _choice = _HomeChoice.create),
              ),
              const SizedBox(height: 16),
              _ChoiceCard(
                key: const Key('join_home_card'),
                icon: Icons.group_rounded,
                title: l10n.onboarding_join_home,
                description: l10n.onboarding_join_home_description,
                onTap: () => setState(() => _choice = _HomeChoice.join),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                key: const Key('prev_button'),
                onPressed: widget.onPrev,
                child: Text(l10n.back),
              ),
            ] else if (_choice == _HomeChoice.create) ...[
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const Key('home_name_field'),
                      controller: _nameCtrl,
                      maxLength: 40,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(40),
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.onboarding_home_name_label,
                        hintText: l10n.onboarding_home_name_hint,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.onboarding_home_name_required;
                        }
                        if (v.trim().length > 40) {
                          return l10n.onboarding_home_name_max_length;
                        }
                        return null;
                      },
                    ),
                    if (widget.error == 'no_slots')
                      Text(
                        l10n.onboarding_error_no_slots,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton(
                          key: const Key('create_back_button'),
                          onPressed: widget.isLoading
                              ? null
                              : () => setState(
                                  () => _choice = _HomeChoice.none),
                          child: Text(l10n.back),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            key: const Key('create_home_button'),
                            onPressed: widget.isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      widget.onCreateHome(
                                          _nameCtrl.text.trim(), null);
                                    }
                                  },
                            child: widget.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text(l10n.onboarding_create_home_button),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              HomeJoinForm(
                isLoading: widget.isLoading,
                error: widget.error,
                onJoin: widget.onJoinHome,
                onBack: () =>
                    setState(() => _choice = _HomeChoice.none),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(description,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
