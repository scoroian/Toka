import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../../../../shared/widgets/futurista/tocka_btn.dart';

/// Pantalla Profile de la skin futurista. Mantiene la misma firma que
/// [ProfileStepV2] para compartir VM/state desde el wrapper.
class ProfileStepFuturista extends StatefulWidget {
  const ProfileStepFuturista({
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
  State<ProfileStepFuturista> createState() => _ProfileStepFuturistaState();
}

class _ProfileStepFuturistaState extends State<ProfileStepFuturista> {
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final primary = cs.primary;
    final muted = cs.onSurfaceVariant;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar con halo + botón de edición.
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            primary.withValues(alpha: 0.19),
                            primary.withValues(alpha: 0.04),
                          ],
                        ),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.33),
                          width: 1,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.55),
                            blurRadius: 60,
                            offset: const Offset(0, 30),
                            spreadRadius: -20,
                          ),
                        ],
                      ),
                      child: widget.photoLocalPath != null
                          ? ClipOval(
                              child: Image.file(
                                File(widget.photoLocalPath!),
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.add_a_photo,
                                size: 32,
                                color: primary,
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        key: const Key('avatar_picker'),
                        onTap: _pickPhoto,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary,
                            border: Border.all(
                              color: cs.surface,
                              width: 2.5,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.edit,
                              size: 16,
                              color: cs.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _pickPhoto,
                  child: Text(
                    widget.photoLocalPath == null
                        ? l10n.onboarding_add_photo
                        : l10n.onboarding_change_photo,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Display title.
              Text(
                l10n.onboarding_profile_title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              // Nickname field (futurista label + bare input).
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.onboarding_nickname_label.toUpperCase(),
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
                      key: const Key('nickname_field'),
                      controller: _nicknameCtrl,
                      maxLength: 30,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(30),
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
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Phone field.
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.onboarding_phone_label.toUpperCase(),
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
                      key: const Key('phone_field'),
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                      onChanged: (v) =>
                          widget.onPhoneChanged(v.isEmpty ? null : v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Phone-visible toggle.
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.onboarding_phone_visible_label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch(
                      key: const Key('phone_visible_toggle'),
                      value: widget.phoneVisible,
                      onChanged: widget.onPhoneVisibleChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Botones navegación.
              Row(
                children: [
                  OutlinedButton(
                    key: const Key('prev_button'),
                    onPressed: widget.isLoading ? null : widget.onPrev,
                    child: Text(l10n.back),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TockaBtn(
                      key: const Key('next_button'),
                      variant: TockaBtnVariant.glow,
                      size: TockaBtnSize.lg,
                      fullWidth: true,
                      onPressed: widget.isLoading
                          ? null
                          : () {
                              if (_formKey.currentState?.validate() ??
                                  false) {
                                widget.onNext();
                              }
                            },
                      child: widget.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
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
