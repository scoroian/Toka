import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../../../../shared/widgets/futurista/tocka_btn.dart';
import '../../../widgets/home_join_form.dart';

enum _HomeChoice { none, create, join }

/// Pantalla `HomeChoiceStep` de la skin futurista. Replica la máquina de
/// estados del V2 (none / create / join) con lenguaje visual futurista
/// (hero glow, cards con borde, mono caps en labels, TockaBtn `glow`).
///
/// Mantiene la misma signatura que [HomeChoiceStepV2] para compartir VM.
class HomeChoiceStepFuturista extends StatefulWidget {
  const HomeChoiceStepFuturista({
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
  State<HomeChoiceStepFuturista> createState() =>
      _HomeChoiceStepFuturistaState();
}

class _HomeChoiceStepFuturistaState extends State<HomeChoiceStepFuturista> {
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final muted = cs.onSurface.withValues(alpha: 0.6);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_choice == _HomeChoice.none)
              ..._buildNone(context, l10n, cs, muted)
            else if (_choice == _HomeChoice.create)
              ..._buildCreate(context, l10n, cs, muted)
            else
              ..._buildJoin(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNone(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme cs,
    Color muted,
  ) {
    return [
      const SizedBox(height: 8),
      Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
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
            borderRadius: BorderRadius.circular(24),
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
              Icons.home_outlined,
              size: 48,
              color: cs.primary,
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),
      Text(
        l10n.onboarding_home_choice_title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Crea uno nuevo o únete a uno existente',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: muted,
        ),
      ),
      const SizedBox(height: 28),
      _ChoiceCard(
        key: const Key('create_home_card'),
        icon: Icons.add,
        title: l10n.onboarding_create_home,
        description: l10n.onboarding_create_home_description,
        onTap: () => setState(() => _choice = _HomeChoice.create),
      ),
      const SizedBox(height: 12),
      _ChoiceCard(
        key: const Key('join_home_card'),
        icon: Icons.arrow_forward,
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
    ];
  }

  List<Widget> _buildCreate(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme cs,
    Color muted,
  ) {
    return [
      const SizedBox(height: 8),
      Text(
        l10n.onboarding_home_choice_title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 24),
      Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.onboarding_home_name_label.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    key: const Key('home_name_field'),
                    controller: _nameCtrl,
                    maxLength: 40,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(40),
                    ],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      counterText: '',
                    ),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
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
                ],
              ),
            ),
            if (widget.error == 'no_slots')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.onboarding_error_no_slots,
                  style: TextStyle(color: cs.error),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  key: const Key('create_back_button'),
                  onPressed: widget.isLoading
                      ? null
                      : () => setState(() => _choice = _HomeChoice.none),
                  child: Text(l10n.back),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TockaBtn(
                    key: const Key('create_home_button'),
                    variant: TockaBtnVariant.glow,
                    size: TockaBtnSize.lg,
                    fullWidth: true,
                    onPressed: widget.isLoading
                        ? null
                        : () {
                            if (_formKey.currentState?.validate() ?? false) {
                              widget.onCreateHome(
                                _nameCtrl.text.trim(),
                                null,
                              );
                            }
                          },
                    child: widget.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.onboarding_create_home_button),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildJoin() {
    return [
      HomeJoinForm(
        isLoading: widget.isLoading,
        error: widget.error,
        onJoin: widget.onJoinHome,
        onBack: () => setState(() => _choice = _HomeChoice.none),
      ),
    ];
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.6);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(icon, size: 28, color: cs.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: muted),
          ],
        ),
      ),
    );
  }
}
