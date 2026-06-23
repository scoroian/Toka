import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/support_providers.dart';
import '../domain/home_diagnostics.dart';
import '../domain/support_repository.dart';

/// Pantalla interna de diagnóstico de soporte (Hallazgo #17).
///
/// Gateada por el claim `support` (este widget) y por el backend (callable con
/// App Check + claim). Muestra el estado redactado de un hogar: nunca teléfonos
/// en claro, tokens FCM ni notas privadas — solo presencia (candados).
class SupportDiagnosticsScreen extends ConsumerStatefulWidget {
  const SupportDiagnosticsScreen({super.key});

  @override
  ConsumerState<SupportDiagnosticsScreen> createState() =>
      _SupportDiagnosticsScreenState();
}

class _SupportDiagnosticsScreenState
    extends ConsumerState<SupportDiagnosticsScreen> {
  final _controller = TextEditingController();
  String? _queriedHomeId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runDiagnosis() {
    final id = _controller.text.trim();
    if (id.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _queriedHomeId = id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSupport = ref.watch(isSupportAgentProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.support_title),
      ),
      body: isSupport.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _Unauthorized(message: l10n.support_unauthorized),
        data: (allowed) => allowed
            ? _AuthorizedBody(
                controller: _controller,
                queriedHomeId: _queriedHomeId,
                onDiagnose: _runDiagnosis,
              )
            : _Unauthorized(message: l10n.support_unauthorized),
      ),
    );
  }
}

class _Unauthorized extends StatelessWidget {
  const _Unauthorized({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: scheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorizedBody extends ConsumerWidget {
  const _AuthorizedBody({
    required this.controller,
    required this.queriedHomeId,
    required this.onDiagnose,
  });

  final TextEditingController controller;
  final String? queriedHomeId;
  final VoidCallback onDiagnose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        const _PrivacyBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('support_homeid_field'),
                  controller: controller,
                  autocorrect: false,
                  enableSuggestions: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.support_homeid_label,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => onDiagnose(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                key: const Key('support_diagnose_button'),
                onPressed: onDiagnose,
                icon: const Icon(Icons.search),
                label: Text(l10n.support_diagnose_button),
              ),
            ],
          ),
        ),
        Expanded(
          child: queriedHomeId == null
              ? _Hint(text: l10n.support_empty_prompt)
              : _Results(homeId: queriedHomeId!),
        ),
      ],
    );
  }
}

class _PrivacyBanner extends StatelessWidget {
  const _PrivacyBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 18, color: scheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.support_privacy_notice,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(text, textAlign: TextAlign.center),
        ),
      );
}

class _Results extends ConsumerWidget {
  const _Results({required this.homeId});
  final String homeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(homeDiagnosticsProvider(homeId));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, __) => _Hint(text: _errorMessage(l10n, err)),
      data: (d) => ListView(
        key: const Key('support_results_list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _HomeCard(d: d),
          const SizedBox(height: 12),
          _MembersCard(d: d),
          const SizedBox(height: 12),
          _TasksCard(tasks: d.upcomingTasks),
          const SizedBox(height: 12),
          _EventsCard(events: d.recentEvents),
          if (d.generatedAt != null) ...[
            const SizedBox(height: 16),
            Text(
              l10n.support_generated_at(d.generatedAt!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  String _errorMessage(AppLocalizations l10n, Object err) {
    final code = err is SupportException ? err.code : '';
    switch (code) {
      case 'permission-denied':
      case 'unauthenticated':
      case 'unauthorized':
        return l10n.support_error_permission;
      case 'not-found':
        return l10n.support_error_notfound;
      default:
        return l10n.support_error_generic;
    }
  }
}

/// Texto monoespaciado para identificadores (uids, homeId, taskId).
class _Mono extends StatelessWidget {
  const _Mono(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.d});
  final HomeDiagnostics d;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final home = d.home;
    return _SectionCard(
      title: l10n.support_section_home,
      children: [
        _kv(context, 'homeId', null, mono: d.homeId),
        if (home != null) ...[
          if (home.name != null) _kv(context, l10n.support_name, home.name),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _StatusChip(label: home.premiumStatus),
          ),
          if (home.premiumPlan != null)
            _kv(context, l10n.support_plan, home.premiumPlan),
          if (home.premiumEndsAt != null)
            _kv(context, l10n.support_premium_ends, home.premiumEndsAt),
          if (home.ownerUid != null)
            _kv(context, l10n.support_owner, null, mono: home.ownerUid),
          if (home.currentPayerUid != null)
            _kv(context, l10n.support_payer, null, mono: home.currentPayerUid),
          if (home.timezone != null)
            _kv(context, l10n.support_timezone, home.timezone),
        ],
      ],
    );
  }
}

class _MembersCard extends StatelessWidget {
  const _MembersCard({required this.d});
  final HomeDiagnostics d;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      title: l10n.support_section_members(d.memberCount),
      children: d.members.isEmpty
          ? [Text(l10n.support_no_results)]
          : d.members
              .map((m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _MemberRow(m: m),
                  ))
              .toList(),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.m});
  final DiagMember m;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                m.nickname?.isNotEmpty == true ? m.nickname! : m.uid,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            if (m.role != null) _StatusChip(label: m.role!, dense: true),
          ],
        ),
        _Mono(m.uid),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            if (m.status != null) _StatusChip(label: m.status!, dense: true),
            _PresenceChip(
              icon: Icons.phone_outlined,
              label: l10n.support_has_phone,
              present: m.hasPhone,
            ),
            _PresenceChip(
              icon: Icons.notifications_outlined,
              label: l10n.support_has_token,
              present: m.hasFcmToken,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            l10n.support_member_stats(
              m.tasksCompleted,
              m.averageScore.toStringAsFixed(1),
              m.currentStreak,
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _TasksCard extends StatelessWidget {
  const _TasksCard({required this.tasks});
  final List<DiagTask> tasks;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      title: l10n.support_section_tasks,
      children: tasks.isEmpty
          ? [Text(l10n.support_no_results)]
          : tasks
              .map((t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.title ?? t.taskId),
                        if (t.nextDueAt != null)
                          Text(
                            t.nextDueAt!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ))
              .toList(),
    );
  }
}

class _EventsCard extends StatelessWidget {
  const _EventsCard({required this.events});
  final List<DiagEvent> events;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      title: l10n.support_section_events,
      children: events.isEmpty
          ? [Text(l10n.support_no_results)]
          : events
              .map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(e.eventType ?? e.eventId)),
                        if (e.createdAt != null)
                          Text(
                            e.createdAt!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ))
              .toList(),
    );
  }
}

/// Chip de estado neutro (premium status, rol, estado de miembro).
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, this.dense = false});
  final String label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: dense ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Chip de PRESENCIA: indica si el miembro tiene teléfono/token SIN revelarlos.
/// Verde con check si presente, gris con candado si ausente.
class _PresenceChip extends StatelessWidget {
  const _PresenceChip({
    required this.icon,
    required this.label,
    required this.present,
  });
  final IconData icon;
  final String label;
  final bool present;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = present ? scheme.primary : scheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(present ? icon : Icons.lock_outline, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(width: 4),
          Icon(
            present ? Icons.check_circle : Icons.remove_circle_outline,
            size: 13,
            color: color,
          ),
        ],
      ),
    );
  }
}

Widget _kv(BuildContext context, String label, String? value, {String? mono}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: mono != null ? _Mono(mono) : Text(value ?? '—'),
        ),
      ],
    ),
  );
}
