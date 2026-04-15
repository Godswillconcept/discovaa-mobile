import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UploadStatus { idle, uploading, success, error }

class ImageUploadState {
  final String? frontImagePath;
  final String? backImagePath;
  final UploadStatus frontUploadStatus;
  final UploadStatus backUploadStatus;
  final String? error;

  const ImageUploadState({
    this.frontImagePath,
    this.backImagePath,
    this.frontUploadStatus = UploadStatus.idle,
    this.backUploadStatus = UploadStatus.idle,
    this.error,
  });

  ImageUploadState copyWith({
    String? frontImagePath,
    String? backImagePath,
    UploadStatus? frontUploadStatus,
    UploadStatus? backUploadStatus,
    String? error,
  }) {
    return ImageUploadState(
      frontImagePath: frontImagePath ?? this.frontImagePath,
      backImagePath: backImagePath ?? this.backImagePath,
      frontUploadStatus: frontUploadStatus ?? this.frontUploadStatus,
      backUploadStatus: backUploadStatus ?? this.backUploadStatus,
      error: error ?? this.error,
    );
  }
}

class ImageUploadNotifier extends StateNotifier<ImageUploadState> {
  ImageUploadNotifier() : super(const ImageUploadState());

  Future<void> pickImage(ImageSource source, {bool isFront = true}) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image == null) {
        return;
      }

      final fileSize = await image.length();
      const maxSizeBytes = 3 * 1024 * 1024; // 3MB

      if (fileSize > maxSizeBytes) {
        state = state.copyWith(
          error: 'File size exceeds 3MB limit',
          frontUploadStatus: isFront
              ? UploadStatus.error
              : state.frontUploadStatus,
          backUploadStatus: !isFront
              ? UploadStatus.error
              : state.backUploadStatus,
        );
        return;
      }

      // Validate file type
      final extension = image.path.toLowerCase().split('.').last;
      if (!['png', 'jpg', 'jpeg'].contains(extension)) {
        state = state.copyWith(
          error: 'Invalid file format. Please upload PNG, JPEG, or PDF',
          frontUploadStatus: isFront
              ? UploadStatus.error
              : state.frontUploadStatus,
          backUploadStatus: !isFront
              ? UploadStatus.error
              : state.backUploadStatus,
        );
        return;
      }

      // Validate image dimensions (minimum 300x300 for ID cards)
      final decodedImage = await decodeImageFromList(image);
      if (decodedImage == null) {
        state = state.copyWith(
          error: 'Invalid image file',
          frontUploadStatus: isFront
              ? UploadStatus.error
              : state.frontUploadStatus,
          backUploadStatus: !isFront
              ? UploadStatus.error
              : state.backUploadStatus,
        );
        return;
      }

      if (decodedImage.width < 300 || decodedImage.height < 300) {
        state = state.copyWith(
          error: 'Image must be at least 300x300 pixels',
          frontUploadStatus: isFront
              ? UploadStatus.error
              : state.frontUploadStatus,
          backUploadStatus: !isFront
              ? UploadStatus.error
              : state.backUploadStatus,
        );
        return;
      }

      // Update state with image path and uploading status
      state = state.copyWith(
        frontImagePath: isFront ? image.path : state.frontImagePath,
        backImagePath: !isFront ? image.path : state.backImagePath,
        frontUploadStatus: isFront
            ? UploadStatus.uploading
            : state.frontUploadStatus,
        backUploadStatus: !isFront
            ? UploadStatus.uploading
            : state.backUploadStatus,
        error: null,
      );

      // Here you would upload to Firebase Storage
      // For now, just simulate successful upload
      await Future.delayed(const Duration(seconds: 2));

      state = state.copyWith(
        frontUploadStatus: isFront
            ? UploadStatus.success
            : state.frontUploadStatus,
        backUploadStatus: !isFront
            ? UploadStatus.success
            : state.backUploadStatus,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to pick image: ${e.toString()}',
        frontUploadStatus: isFront
            ? UploadStatus.error
            : state.frontUploadStatus,
        backUploadStatus: !isFront
            ? UploadStatus.error
            : state.backUploadStatus,
      );
    }
  }

  void reset() {
    state = const ImageUploadState();
  }
}

// Helper function to decode image and validate dimensions
Future<ui.Image?> decodeImageFromList(XFile image) async {
  try {
    final bytes = await image.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  } catch (e) {
    return null;
  }
}

final imageUploadProvider =
    StateNotifierProvider<ImageUploadNotifier, ImageUploadState>(
      (ref) => ImageUploadNotifier(),
    );
