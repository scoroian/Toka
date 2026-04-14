import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../application/edit_profile_view_model.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();

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

  Future<void> _save(EditProfileViewModel vm) async {
    final l10n = AppLocalizations.of(context);
    await vm.save(
      nickname: _nicknameController.text.trim(),
      bio: _bioController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    if (!mounted) return;
    // Leer del notifier directamente para obtener el estado actualizado.
    final saved = ref
        .read(editProfileViewModelNotifierProvider.notifier)
        .savedSuccessfully;
    if (saved) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(editProfileViewModelProvider);

    ref.watch(editProfileViewModelNotifierProvider);

    // Sync controllers when profile is first loaded.
    // We listen on the notifier provider (freezed state → value equality)
    // because editProfileViewModelProvider always returns the same object
    // reference, which Riverpod's == check would never see as changed.
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
      }
    });

    if (!vm.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.profile_edit)),
        body: const LoadingWidget(),
      );
    }

    // Determine avatar image source
    ImageProvider? avatarImage;
    if (vm.selectedPhotoPath != null) {
      avatarImage = FileImage(File(vm.selectedPhotoPath!));
    } else if (vm.initialPhotoUrl != null) {
      avatarImage = CachedNetworkImageProvider(vm.initialPhotoUrl!);
    }

    final hasPhoto = avatarImage != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile_edit),
        actions: [
          if (vm.isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              key: const Key('save_profile_btn'),
              onPressed: () => _save(vm),
              child: Text(l10n.save),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Avatar ────────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                GestureDetector(
                  key: const Key('avatar_picker'),
                  onTap: _pickPhoto,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: avatarImage,
                    child: hasPhoto
                        ? null
                        : Text(
                            _nicknameController.text.isNotEmpty
                                ? _nicknameController.text[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 32),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: Text(
                    hasPhoto
                        ? l10n.onboarding_change_photo
                        : l10n.onboarding_add_photo,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Nombre ────────────────────────────────────────────────
          TextField(
            key: const Key('nickname_field'),
            controller: _nicknameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.profile_nickname_label,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),

          // ── Bio ───────────────────────────────────────────────────
          TextField(
            key: const Key('bio_field'),
            controller: _bioController,
            maxLines: 3,
            maxLength: 160,
            decoration: InputDecoration(
              labelText: l10n.profile_bio_label,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.info_outline),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),

          // ── Teléfono ──────────────────────────────────────────────
          TextField(
            key: const Key('phone_field'),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.profile_phone_label,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            key: const Key('phone_visibility_switch'),
            title: Text(l10n.profile_phone_visibility_label),
            value: vm.phoneVisible,
            onChanged: (v) => ref
                .read(editProfileViewModelNotifierProvider.notifier)
                .setPhoneVisible(v),
          ),
        ],
      ),
    );
  }
}
