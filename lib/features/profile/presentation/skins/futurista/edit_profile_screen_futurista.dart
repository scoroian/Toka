// lib/features/profile/presentation/skins/futurista/edit_profile_screen_futurista.dart
//
// Editor de perfil en skin Futurista. Sin canvas pixel-perfect, mantiene el
// lenguaje futurista del resto de la app:
//   - Header con icon-slot 38x38 (back) + título centrado + TockaBtn primary sm
//     "Guardar".
//   - Hero avatar editable con badge de edición.
//   - Cards `surfaceContainerHighest` radius 14 con label monospaced uppercase
//     letterSpacing 1.4 y `TextField` sin border embebido.
//   - Sección visibilidad teléfono con 3 `TockaChip` (Nadie / Hogar / Todos).
//
// Consume el mismo `editProfileViewModelNotifierProvider` que la versión v2.
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
import '../../../../../shared/widgets/futurista/tocka_avatar.dart';
import '../../../../../shared/widgets/futurista/tocka_btn.dart';
import '../../../../../shared/widgets/futurista/tocka_chip.dart';
import '../../../application/edit_profile_view_model.dart';

/// Visibilidad de teléfono en formato chip — UI-only.
///
/// El VM persiste un booleano (`phoneVisible`): `true == sameHomeMembers`
/// (Hogar) y `false == hidden` (Nadie). El estado "Todos" no existe todavía
/// en el modelo de dominio, por lo que el chip se queda como visual hint sin
/// efecto persistente más allá de marcar `phoneVisible = true`.
enum _PhoneVis { none, home, all }

class EditProfileScreenFuturista extends ConsumerStatefulWidget {
  const EditProfileScreenFuturista({super.key});

  @override
  ConsumerState<EditProfileScreenFuturista> createState() =>
      _EditProfileScreenFuturistaState();
}

class _EditProfileScreenFuturistaState
    extends ConsumerState<EditProfileScreenFuturista> {
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();

  // Sólo distinguimos none/home en el dominio; "all" se mapea a home.
  _PhoneVis _vis = _PhoneVis.home;

  static const _monoLabel = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
  );

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked != null && mounted) {
      ref
          .read(editProfileViewModelNotifierProvider.notifier)
          .setPhoto(picked.path);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(editProfileViewModelNotifierProvider.notifier);
    await notifier.save(
      nickname: _nicknameController.text.trim(),
      bio: _bioController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    if (!mounted) return;
    if (notifier.savedSuccessfully) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profile_saved)),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.error_generic)),
      );
    }
  }

  void _setVis(_PhoneVis v) {
    setState(() => _vis = v);
    final notifier = ref.read(editProfileViewModelNotifierProvider.notifier);
    notifier.setPhoneVisible(v != _PhoneVis.none);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final vm = ref.watch(editProfileViewModelProvider);

    ref.watch(editProfileViewModelNotifierProvider);

    // Sync inicial de controllers desde el VM (mismo patrón que v2).
    ref.listen(editProfileViewModelNotifierProvider, (_, __) {
      final notifier =
          ref.read(editProfileViewModelNotifierProvider.notifier);
      if (notifier.isInitialized) {
        if (_nicknameController.text.isEmpty &&
            notifier.initialNickname != null) {
          _nicknameController.text = notifier.initialNickname!;
        }
        if (_bioController.text.isEmpty && notifier.initialBio != null) {
          _bioController.text = notifier.initialBio!;
        }
        if (_phoneController.text.isEmpty &&
            notifier.initialPhone != null) {
          _phoneController.text = notifier.initialPhone!;
        }
        // Inicializar el chip activo según el VM.
        final desired = notifier.phoneVisible ? _PhoneVis.home : _PhoneVis.none;
        if (_vis != desired) {
          // setState seguro dentro de listen (post-frame defensa).
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _vis != desired) {
              setState(() => _vis = desired);
            }
          });
        }
      }
    });

    if (!vm.isInitialized) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Imagen del avatar.
    ImageProvider? avatarImage;
    if (vm.selectedPhotoPath != null) {
      avatarImage = FileImage(File(vm.selectedPhotoPath!));
    } else if (vm.initialPhotoUrl != null) {
      avatarImage = CachedNetworkImageProvider(vm.initialPhotoUrl!);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            0,
            4,
            0,
            adAwareBottomPadding(context, ref, extra: 16),
          ),
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Row(
                children: [
                  _IconSlot(
                    key: const Key('fut_edit_back'),
                    icon: Icons.chevron_left,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  Text(
                    l10n.profile_edit,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  TockaBtn(
                    key: const Key('save_profile_btn'),
                    variant: TockaBtnVariant.primary,
                    size: TockaBtnSize.sm,
                    onPressed: vm.isLoading ? null : _save,
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ),

            // ── Avatar editable ───────────────────────────────────────────
            Center(
              child: InkWell(
                key: const Key('avatar_picker'),
                onTap: _pickPhoto,
                borderRadius: BorderRadius.circular(48),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Avatar (foto si hay; si no, TockaAvatar con iniciales).
                      ClipOval(
                        child: avatarImage != null
                            ? Image(
                                image: avatarImage,
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                              )
                            : TockaAvatar(
                                name: _nicknameController.text.isNotEmpty
                                    ? _nicknameController.text
                                    : '?',
                                color: cs.primary,
                                size: 84,
                              ),
                      ),
                      // Badge edit
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.primary,
                            border:
                                Border.all(color: cs.surface, width: 2.5),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.edit,
                            size: 14,
                            color: cs.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── Nickname ──────────────────────────────────────────────────
            _FieldCard(
              label: l10n.profile_nickname_label.toUpperCase(),
              monoLabel: _monoLabel,
              child: TextField(
                key: const Key('nickname_field'),
                controller: _nicknameController,
                textCapitalization: TextCapitalization.words,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: cs.onSurface,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            // ── Bio ───────────────────────────────────────────────────────
            _FieldCard(
              label: l10n.profile_bio_label.toUpperCase(),
              monoLabel: _monoLabel,
              child: TextField(
                key: const Key('bio_field'),
                controller: _bioController,
                maxLines: 3,
                maxLength: 160,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: cs.onSurface,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  counterText: '',
                ),
              ),
            ),

            // ── Teléfono ──────────────────────────────────────────────────
            _FieldCard(
              label: l10n.profile_phone_label.toUpperCase(),
              monoLabel: _monoLabel,
              child: TextField(
                key: const Key('phone_field'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: cs.onSurface,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            // ── Visibilidad teléfono ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profile_phone_visibility_label.toUpperCase(),
                      maxLines: 2,
                      style: _monoLabel.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.42),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TockaChip(
                          key: const Key('vis_chip_none'),
                          active: _vis == _PhoneVis.none,
                          onTap: () => _setVis(_PhoneVis.none),
                          child: Text(
                              AppLocalizations.of(context).phone_visibility_none),
                        ),
                        const SizedBox(width: 8),
                        TockaChip(
                          key: const Key('vis_chip_home'),
                          active: _vis == _PhoneVis.home,
                          onTap: () => _setVis(_PhoneVis.home),
                          child: Text(
                              AppLocalizations.of(context).phone_visibility_home),
                        ),
                        const SizedBox(width: 8),
                        TockaChip(
                          key: const Key('vis_chip_all'),
                          active: _vis == _PhoneVis.all,
                          onTap: () => _setVis(_PhoneVis.all),
                          child: Text(
                              AppLocalizations.of(context).phone_visibility_all),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Field card común
// -----------------------------------------------------------------------------
class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.label,
    required this.monoLabel,
    required this.child,
  });

  final String label;
  final TextStyle monoLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: monoLabel.copyWith(
                color: cs.onSurface.withValues(alpha: 0.42),
              ),
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Icon slot (mismo patrón que profile_screen_futurista)
// -----------------------------------------------------------------------------
class _IconSlot extends StatelessWidget {
  const _IconSlot({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
      ),
    );
  }
}
