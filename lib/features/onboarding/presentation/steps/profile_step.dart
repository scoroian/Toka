import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../l10n/app_localizations.dart';

class ProfileStep extends StatefulWidget {
  const ProfileStep({
    super.key,
    required this.nickname,
    required this.phoneNumber,
    required this.phoneVisible,
    required this.photoLocalPath,
    required this.isLoading,
    required this.error,
    required this.onNicknameChanged,
    required this.onPhoneChanged,
    required this.onPhoneVisibleChanged,
    required this.onPhotoChanged,
    required this.onNext,
    required this.onPrev,
  });

  final String? nickname;
  final String? phoneNumber;
  final bool phoneVisible;
  final String? photoLocalPath;
  final bool isLoading;
  final String? error;
  final ValueChanged<String> onNicknameChanged;
  final ValueChanged<String?> onPhoneChanged;
  final ValueChanged<bool> onPhoneVisibleChanged;
  final ValueChanged<String?> onPhotoChanged;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  @override
  State<ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<ProfileStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _nicknameCtrl = TextEditingController(text: widget.nickname ?? '');
    _phoneCtrl = TextEditingController(text: widget.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) widget.onPhotoChanged(picked.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                l10n.onboarding_profile_title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  key: const Key('avatar_picker'),
                  onTap: _pickPhoto,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: widget.photoLocalPath != null
                        ? FileImage(File(widget.photoLocalPath!))
                        : null,
                    child: widget.photoLocalPath == null
                        ? const Icon(Icons.add_a_photo, size: 32)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _pickPhoto,
                  child: Text(widget.photoLocalPath == null
                      ? l10n.onboarding_add_photo
                      : l10n.onboarding_change_photo),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('nickname_field'),
                controller: _nicknameCtrl,
                maxLength: 30,
                inputFormatters: [LengthLimitingTextInputFormatter(30)],
                decoration: InputDecoration(
                  labelText: l10n.onboarding_nickname_label,
                  hintText: l10n.onboarding_nickname_hint,
                ),
                onChanged: widget.onNicknameChanged,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return l10n.onboarding_nickname_required;
                  }
                  if (v.trim().length > 30) {
                    return l10n.onboarding_nickname_max_length;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('phone_field'),
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.onboarding_phone_label,
                ),
                onChanged: (v) =>
                    widget.onPhoneChanged(v.isEmpty ? null : v),
              ),
              SwitchListTile(
                key: const Key('phone_visible_toggle'),
                value: widget.phoneVisible,
                onChanged: widget.onPhoneVisibleChanged,
                title: Text(l10n.onboarding_phone_visible_label),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  OutlinedButton(
                    key: const Key('prev_button'),
                    onPressed: widget.isLoading ? null : widget.onPrev,
                    child: Text(l10n.back),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const Key('next_button'),
                      onPressed: widget.isLoading
                          ? null
                          : () {
                              if (_formKey.currentState?.validate() ?? false) {
                                widget.onNext();
                              }
                            },
                      child: widget.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.next),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
