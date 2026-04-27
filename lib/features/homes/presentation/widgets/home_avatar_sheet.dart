// lib/features/homes/presentation/widgets/home_avatar_sheet.dart
//
// Sheet para gestionar el avatar del hogar. Tres acciones:
//   1. Elegir de galería  → ImagePicker → upload → Firestore.photoUrl
//   2. Hacer foto         → ImagePicker.camera → idem
//   3. Quitar foto        → borra blob de Storage + photoUrl en Firestore
//
// Reusa el `HomeSettingsViewModel` (que conoce el `homeId` y delega al
// `HomesRepositoryImpl.updateHomePhoto`/`removeHomePhoto`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/bottom_sheet_padding.dart';
import '../../application/home_settings_view_model.dart';

Future<void> showHomeAvatarSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _HomeAvatarSheet(),
  );
}

class _HomeAvatarSheet extends ConsumerWidget {
  const _HomeAvatarSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final vm = ref.watch(homeSettingsViewModelProvider(l10n));
    final hasPhoto = vm.viewData.valueOrNull?.photoUrl != null;
    final bottomPad = bottomSheetSafeBottom(context, ref, hasNavBar: true);

    return Padding(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 16,
        bottom: bottomPad + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              l10n.homes_avatar_sheet_title,
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            key: const Key('home_avatar_pick_gallery'),
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.homes_avatar_pick_gallery),
            onTap: () => _pick(context, ref, ImageSource.gallery),
          ),
          ListTile(
            key: const Key('home_avatar_pick_camera'),
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.homes_avatar_pick_camera),
            onTap: () => _pick(context, ref, ImageSource.camera),
          ),
          if (hasPhoto)
            ListTile(
              key: const Key('home_avatar_remove'),
              leading: Icon(Icons.delete_outline, color: cs.error),
              title: Text(
                l10n.homes_avatar_remove,
                style: TextStyle(color: cs.error),
              ),
              onTap: () => _remove(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // Limites idénticos a `EditProfileScreenFuturista._pickPhoto` para
    // no colar a Storage imágenes pesadas. ImagePicker hace el resize
    // antes de devolvernos el path.
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null || !context.mounted) return;
    navigator.maybePop();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.homes_avatar_uploading)),
    );
    try {
      await ref
          .read(homeSettingsViewModelProvider(l10n))
          .updateHomePhoto(picked.path);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.homes_avatar_updated)),
        );
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.error_generic)));
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    navigator.maybePop();
    try {
      await ref.read(homeSettingsViewModelProvider(l10n)).removeHomePhoto();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.homes_avatar_updated)),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.error_generic)));
    }
  }
}
