import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../application/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _phoneVisible = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save(String uid) async {
    final l10n = AppLocalizations.of(context);
    await ref.read(profileEditorProvider.notifier).updateProfile(
          uid,
          nickname: _nicknameController.text.trim(),
          bio: _bioController.text.trim(),
          phone: _phoneController.text.trim(),
          phoneVisibility:
              _phoneVisible ? 'sameHomeMembers' : 'hidden',
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
    final auth = ref.watch(authProvider);
    final uid = auth.whenOrNull(authenticated: (u) => u.uid) ?? '';
    final profileAsync = ref.watch(userProfileProvider(uid));
    final editorState = ref.watch(profileEditorProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile_edit),
        actions: [
          if (editorState is AsyncLoading)
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
              onPressed: () => _save(uid),
              child: Text(l10n.save),
            ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const LoadingWidget(),
        error: (_, __) => Center(child: Text(l10n.error_generic)),
        data: (profile) {
          if (!_initialized) {
            _nicknameController.text = profile.nickname;
            _bioController.text = profile.bio ?? '';
            _phoneController.text = profile.phone ?? '';
            _phoneVisible = profile.phoneVisibility == 'sameHomeMembers';
            _initialized = true;
          }
          return ListView(
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
                value: _phoneVisible,
                onChanged: (v) => setState(() => _phoneVisible = v),
              ),
            ],
          );
        },
      ),
    );
  }
}
