import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/profile_image_service.dart';
import '../state/app_settings.dart';
import '../widgets/profile_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.settings,
    required this.imageService,
    this.choosePhotoOnOpen = false,
  });
  final AppSettings settings;
  final ProfileImageService imageService;
  final bool choosePhotoOnOpen;
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.settings.name,
  );
  late final TextEditingController _email = TextEditingController(
    text: widget.settings.email,
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.settings.phone,
  );
  late Uint8List? _photo = widget.settings.photo;
  bool _picking = false;
  String? _imageError;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _chooseImage(recover: !widget.choosePhotoOnOpen);
    });
  }

  Future<void> _chooseImage({bool recover = false}) async {
    if (_picking) return;
    setState(() {
      _picking = true;
      _imageError = null;
    });
    try {
      final photo = await (recover
          ? widget.imageService.recoverImage()
          : widget.imageService.selectImage());
      if (photo != null && mounted) setState(() => _photo = photo);
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _imageError =
              error.code.contains('access') || error.code.contains('denied')
              ? 'Photo access was denied. Allow photo access in your device settings and try again.'
              : 'The photo picker could not open. Please try again.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _imageError = error is FormatException
              ? error.message
              : 'That image could not be opened. Try another photo.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Edit Profile', style: TextStyle(fontSize: 18)),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Center(child: ProfileAvatar(photo: _photo, size: 108)),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _picking ? null : () => _chooseImage(),
                    icon: _picking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo_library_outlined, size: 19),
                    label: Text(
                      _picking ? 'Opening photos...' : 'Change profile picture',
                    ),
                  ),
                  if (_photo != null)
                    TextButton(
                      onPressed: _picking
                          ? null
                          : () => setState(() => _photo = null),
                      child: const Text('Remove photo'),
                    ),
                  if (_imageError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        _imageError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    'Your details stay in application memory for this session. They are not synced to a server and do not create an account.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    maxLength: 100,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) =>
                        value != null &&
                            value.trim().isNotEmpty &&
                            !RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(value.trim())
                        ? 'Enter a valid email address'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) =>
                        value != null &&
                            value.trim().isNotEmpty &&
                            (!RegExp(
                                  r'^\+?[\d\s().-]{5,25}$',
                                ).hasMatch(value.trim()) ||
                                value.replaceAll(RegExp(r'\D'), '').length < 5)
                        ? 'Enter a valid phone number'
                        : null,
                  ),
                  const SizedBox(height: 30),
                  FilledButton.icon(
                    onPressed: _picking
                        ? null
                        : () {
                            if (!_form.currentState!.validate()) return;
                            widget.settings.updateProfile(
                              name: _name.text,
                              email: _email.text,
                              phone: _phone.text,
                              photo: _photo,
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Profile updated for this session only.',
                                ),
                              ),
                            );
                          },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 17),
                    ),
                    icon: const Icon(Icons.check, size: 19),
                    label: const Text('Save Changes'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
