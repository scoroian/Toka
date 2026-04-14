import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_provider.dart';
import '../application/current_home_provider.dart';
import '../application/home_slot_provider.dart';
import '../application/homes_provider.dart';
import '../domain/home_membership.dart';

@visibleForTesting
List<HomeMembership> sortMembershipsForSelector(
  List<HomeMembership> memberships, {
  required String currentHomeId,
}) {
  final result = [...memberships];
  result.sort((a, b) {
    if (a.homeId == currentHomeId) return -1;
    if (b.homeId == currentHomeId) return 1;
    return a.homeNameSnapshot.compareTo(b.homeNameSnapshot);
  });
  return result;
}

class HomeSelectorWidget extends ConsumerWidget {
  const HomeSelectorWidget({super.key});

  String _roleLabel(MemberRole role, AppLocalizations l10n) {
    switch (role) {
      case MemberRole.owner:
        return l10n.homes_role_owner;
      case MemberRole.admin:
        return l10n.homes_role_admin;
      case MemberRole.member:
      case MemberRole.frozen:
        return l10n.homes_role_member;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentHomeAsync = ref.watch(currentHomeProvider);
    final auth = ref.watch(authProvider);
    final uid = auth.whenOrNull(authenticated: (u) => u.uid);

    final currentHome = currentHomeAsync.valueOrNull;
    final currentHomeId = currentHome?.id ?? '';

    final membershipsAsync =
        uid != null ? ref.watch(userMembershipsProvider(uid)) : null;
    final memberships = membershipsAsync?.valueOrNull ?? [];

    void openSelector() {
      final sorted = sortMembershipsForSelector(
        memberships,
        currentHomeId: currentHomeId,
      );
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => _HomeSelectorSheet(
          sorted: sorted,
          currentHomeId: currentHomeId,
          roleLabel: (role) => _roleLabel(role, l10n),
          uid: uid,
          ref: ref,
        ),
      );
    }

    return GestureDetector(
      key: const Key('home_selector'),
      onTap: openSelector,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentHome?.name ?? l10n.loading,
            style: Theme.of(context).appBarTheme.titleTextStyle ??
                Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_drop_down,
            key: Key('selector_arrow'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet: lista de hogares + botón +
// ---------------------------------------------------------------------------
class _HomeSelectorSheet extends ConsumerWidget {
  const _HomeSelectorSheet({
    required this.sorted,
    required this.currentHomeId,
    required this.roleLabel,
    required this.uid,
    required this.ref,
  });

  final List<HomeMembership> sorted;
  final String currentHomeId;
  final String Function(MemberRole) roleLabel;
  final String? uid;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.homes_selector_title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              key: const Key('home_selector_list'),
              shrinkWrap: true,
              itemCount: sorted.length,
              itemBuilder: (ctx, index) {
                final membership = sorted[index];
                final isActive = membership.homeId == currentHomeId;
                return ListTile(
                  key: Key('home_tile_${membership.homeId}'),
                  title: Text(membership.homeNameSnapshot),
                  subtitle: Text(roleLabel(membership.role)),
                  trailing: isActive
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ref
                        .read(currentHomeProvider.notifier)
                        .switchHome(membership.homeId);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            key: const Key('btn_add_home'),
            leading: const CircleAvatar(
              child: Icon(Icons.add),
            ),
            title: Text(l10n.homes_add_home),
            onTap: () {
              Navigator.of(context).pop();
              _onAddHomeTapped(context, widgetRef, l10n, sorted.length);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _onAddHomeTapped(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    int currentCount,
  ) {
    // Check slots — we use the cached memberships count + availableSlots provider
    final slotsAsync = ref.read(availableSlotsProvider);
    slotsAsync.when(
      loading: () => _showAddOptions(context, ref, l10n),
      error: (_, __) => _showAddOptions(context, ref, l10n),
      data: (available) {
        if (currentCount >= 5) {
          _showMaxReachedBanner(context, l10n);
        } else if (available <= 0) {
          _showUpgradeBanner(context, l10n);
        } else {
          _showAddOptions(context, ref, l10n);
        }
      },
    );
  }

  void _showMaxReachedBanner(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.homes_max_reached_title),
        content: Text(l10n.homes_max_reached_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.done),
          ),
        ],
      ),
    );
  }

  void _showUpgradeBanner(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.homes_upgrade_title),
        content: Text(l10n.homes_upgrade_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('btn_upgrade_see_plans'),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push(AppRoutes.paywall);
            },
            child: Text(l10n.homes_upgrade_button),
          ),
        ],
      ),
    );
  }

  void _showAddOptions(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddHomeSheet(ref: ref),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet: Crear hogar | Unirse a un hogar
// ---------------------------------------------------------------------------
class _AddHomeSheet extends ConsumerStatefulWidget {
  const _AddHomeSheet({required this.ref});

  final WidgetRef ref;

  @override
  ConsumerState<_AddHomeSheet> createState() => _AddHomeSheetState();
}

enum _AddHomeMode { menu, create, joinCode, joinQr }

class _AddHomeSheetState extends ConsumerState<_AddHomeSheet> {
  _AddHomeMode _mode = _AddHomeMode.menu;
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;
  MobileScannerController? _scannerCtrl;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _scannerCtrl?.dispose();
    super.dispose();
  }

  void _openQrMode() {
    _scannerCtrl = MobileScannerController();
    setState(() {
      _mode = _AddHomeMode.joinQr;
      _error = null;
    });
  }

  void _onQrDetect(BarcodeCapture capture) {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;
    final cleaned = code.trim().toUpperCase();
    if (RegExp(r'^[A-Z0-9]{6}$').hasMatch(cleaned)) {
      _scannerCtrl?.dispose();
      _scannerCtrl = null;
      _codeCtrl.text = cleaned;
      setState(() => _mode = _AddHomeMode.joinCode);
      _submitJoin(cleaned);
    }
  }

  Future<void> _submitCreate() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(homesRepositoryProvider);
      final uid = ref.read(authProvider).whenOrNull(authenticated: (u) => u.uid);
      final homeId = await repo.createHome(name);
      if (uid != null) {
        await repo.updateLastSelectedHome(uid, homeId);
        ref.read(currentHomeProvider.notifier).switchHome(homeId);
      }
      if (mounted) Navigator.of(context).pop();
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().contains('slots')
            ? AppLocalizations.of(context).homes_error_no_slots
            : AppLocalizations.of(context).error_generic;
      });
    }
  }

  Future<void> _submitJoin(String code) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(homesRepositoryProvider);
      await repo.joinHome(code);
      if (mounted) Navigator.of(context).pop();
    } on Exception catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _isLoading = false;
        _error = e.toString().contains('invalid')
            ? l10n.homes_error_invalid_code
            : e.toString().contains('expired')
                ? l10n.homes_error_expired_code
                : l10n.error_generic;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: switch (_mode) {
        _AddHomeMode.menu => _buildMenu(context, l10n),
        _AddHomeMode.create => _buildCreate(context, l10n),
        _AddHomeMode.joinCode => _buildJoinCode(context, l10n),
        _AddHomeMode.joinQr => _buildJoinQr(context, l10n),
      },
    );
  }

  Widget _buildMenu(BuildContext context, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.homes_add_home,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ListTile(
          key: const Key('btn_create_home'),
          leading: const Icon(Icons.add_home_outlined),
          title: Text(l10n.homes_add_create),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          onTap: () => setState(() => _mode = _AddHomeMode.create),
        ),
        const SizedBox(height: 12),
        ListTile(
          key: const Key('btn_join_home'),
          leading: const Icon(Icons.group_add_outlined),
          title: Text(l10n.homes_add_join),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          onTap: () => setState(() {
            _mode = _AddHomeMode.joinCode;
            _error = null;
          }),
        ),
      ],
    );
  }

  Widget _buildCreate(BuildContext context, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _mode = _AddHomeMode.menu),
            ),
            const SizedBox(width: 8),
            Text(l10n.homes_add_create,
                style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('create_home_name_field'),
          controller: _nameCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.homes_create_name_hint,
            border: const OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('btn_create_home_submit'),
          onPressed: _isLoading ? null : _submitCreate,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.homes_create_button),
        ),
      ],
    );
  }

  Widget _buildJoinCode(BuildContext context, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() {
                _mode = _AddHomeMode.menu;
                _error = null;
              }),
            ),
            const SizedBox(width: 8),
            Text(l10n.homes_join_code_title,
                style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('join_code_field'),
          controller: _codeCtrl,
          autofocus: true,
          maxLength: 6,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            LengthLimitingTextInputFormatter(6),
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
          ],
          decoration: InputDecoration(
            labelText: l10n.onboarding_invite_code_label,
            hintText: l10n.onboarding_invite_code_hint,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              key: const Key('btn_scan_qr_join'),
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: l10n.invite_sheet_scan_qr,
              onPressed: _openQrMode,
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('btn_join_submit'),
          onPressed: _isLoading
              ? null
              : () {
                  final code = _codeCtrl.text.trim().toUpperCase();
                  if (code.length == 6) _submitJoin(code);
                },
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.homes_join_button),
        ),
      ],
    );
  }

  Widget _buildJoinQr(BuildContext context, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                _scannerCtrl?.dispose();
                _scannerCtrl = null;
                setState(() => _mode = _AddHomeMode.joinCode);
              },
            ),
            const SizedBox(width: 8),
            Text(l10n.invite_sheet_scan_qr,
                style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 220,
            child: MobileScanner(
              key: const Key('qr_scanner_join'),
              controller: _scannerCtrl,
              onDetect: _onQrDetect,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.invite_sheet_qr_hint,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
