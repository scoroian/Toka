import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> _save(EditProfileViewModel vm) async {
    final l10n = AppLocalizations.of(context);
    await vm.save(
      nickname: _nicknameController.text.trim(),
      bio: _bioController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profile_saved)),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(editProfileViewModelProvider);

    // Sync controllers when profile is first loaded
    ref.listen<EditProfileViewModel>(editProfileViewModelProvider,
        (_, next) {
      if (next.isInitialized) {
        if (_nicknameController.text.isEmpty &&
            next.initialNickname != null) {
          _nicknameController.text = next.initialNickname!;
        }
        if (_bioController.text.isEmpty && next.initialBio != null) {
          _bioController.text = next.initialBio!;
        }
        if (_phoneController.text.isEmpty && next.initialPhone != null) {
          _phoneController.text = next.initialPhone!;
        }
      }
    });

    if (!vm.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.profile_edit)),
        body: const LoadingWidget(),
      );
    }

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
          TextField(
            key: const Key('nickname_field'),
            controller: _nicknameController,
            decoration: InputDecoration(
              labelText: l10n.profile_nickname_label,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('bio_field'),
            controller: _bioController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.profile_bio_label,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('phone_field'),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.profile_phone_label,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const Key('phone_visibility_switch'),
            title: Text(l10n.profile_phone_visibility_label),
            value: vm.phoneVisible,
            onChanged: (v) =>
                ref.read(editProfileViewModelNotifierProvider.notifier).setPhoneVisible(v),
          ),
        ],
      ),
    );
  }
}
