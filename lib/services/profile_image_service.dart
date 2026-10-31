import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

abstract class ProfileImageService {
  Future<Uint8List?> selectImage();
  Future<Uint8List?> recoverImage() async => null;
}

class GalleryProfileImageService extends ProfileImageService {
  GalleryProfileImageService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;
  Future<Uint8List?> _read(XFile? file) async {
    if (file == null) return null;
    if (await file.length() > 10 * 1024 * 1024)
      throw const FormatException('Choose an image smaller than 10 MB.');
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 512);
    codec.dispose();
    return bytes;
  }

  @override
  Future<Uint8List?> selectImage() async => _read(
    await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
      requestFullMetadata: false,
    ),
  );
  @override
  Future<Uint8List?> recoverImage() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final result = await _picker.retrieveLostData();
    if (result.exception != null) throw result.exception!;
    return _read(result.files?.firstOrNull);
  }
}
