import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import '../providers/image_upload_provider.dart';
import '../providers/home_provider.dart';

class IDVerificationModal extends ConsumerStatefulWidget {
  const IDVerificationModal({super.key});

  @override
  ConsumerState<IDVerificationModal> createState() =>
      _IDVerificationModalState();
}

class _IDVerificationModalState extends ConsumerState<IDVerificationModal> {
  @override
  Widget build(BuildContext context) {
    final imageUploadState = ref.watch(imageUploadProvider);
    final homeProviderState = ref.watch(homeProvider);

    // Calculate current step based on upload status (don't modify state directly)
    int currentStep = 1;
    if (imageUploadState.frontUploadStatus == UploadStatus.success &&
        imageUploadState.backUploadStatus == UploadStatus.success) {
      currentStep = 4; // Both uploaded successfully
    } else if (imageUploadState.frontUploadStatus == UploadStatus.success) {
      currentStep = 2; // Front uploaded successfully
    } else if (imageUploadState.backUploadStatus == UploadStatus.success) {
      currentStep = 3; // Back uploaded successfully
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.9,
        minWidth: 320,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step indicator
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stepCircle(
                1,
                "Upload document front page",
                active: currentStep == 1 || currentStep == 2,
                completed:
                    imageUploadState.frontUploadStatus == UploadStatus.success,
              ),
              Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
              _stepCircle(
                2,
                "Upload document back page",
                active: currentStep == 3 || currentStep == 4,
                completed:
                    imageUploadState.backUploadStatus == UploadStatus.success,
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Show upload area or success message based on current step
          _buildUploadArea(
            context,
            ref,
            imageUploadState,
            currentStep: currentStep,
          ),

          const SizedBox(height: 20),
          CheckboxListTile(
            value: homeProviderState.isConfirmed,
            onChanged: (v) {
              ref.read(homeProvider.notifier).updateIsConfirmed(v ?? false);
            },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              "I confirm document is valid until the expiry date and is in color",
              style: TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea(
    BuildContext context,
    WidgetRef ref,
    ImageUploadState imageUploadState, {
    required int currentStep,
  }) {
    // Determine which page we're currently on based on current step
    bool isFront = currentStep == 1 || currentStep == 2;

    final bool isUploading = isFront
        ? imageUploadState.frontUploadStatus == UploadStatus.uploading
        : imageUploadState.backUploadStatus == UploadStatus.uploading;

    final bool isUploaded = isFront
        ? imageUploadState.frontUploadStatus == UploadStatus.success
        : imageUploadState.backUploadStatus == UploadStatus.success;

    if (isUploaded) {
      return _buildUploadStep(isFront ? 2 : 4);
    }

    return DottedBorder(
      options: RectDottedBorderOptions(
        dashPattern: const [6, 3],
        color: Colors.grey.shade300,
        strokeWidth: 2,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            Image.asset('assets/icons/document.png', width: 50, height: 50),
            const SizedBox(height: 20),
            Text(
              "Please upload a copy of your valid identification in PNG, JPEG or PDF format, no longer than 3mb in size",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () {
                      ref
                          .read(imageUploadProvider.notifier)
                          .pickImage(ImageSource.gallery, isFront: isFront);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(200, 50),
              ),
              child: Text(
                isUploading ? "Uploading..." : "Upload",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _stepCircle(
  int n,
  String label, {
  required bool active,
  required bool completed,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12.0),
    child: Row(
      children: [
        DottedBorder(
          options: CircularDottedBorderOptions(
            dashPattern: const [6, 3],
            color: active ? Colors.blue : Colors.grey.shade300,
            strokeWidth: 2,
          ),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Text(
              n.toString(),
              style: TextStyle(
                color: active ? Colors.black : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: active ? Colors.black : Colors.grey),
          ),
        ),
      ],
    ),
  );
}

Widget _buildUploadStep(int stepNumber) {
  bool isFinal = stepNumber == 4;
  return Consumer(
    builder: (context, ref, child) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Image.asset('assets/icons/document-2.png'),
            const SizedBox(height: 24),
            Text(
              textAlign: TextAlign.center,
              "${stepNumber == 2 ? 'Front' : 'Back'} Page Upload\nSuccessful !",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                if (isFinal) {
                  ref.read(homeProvider.notifier).completeVerification();
                  Navigator.pop(context);
                } else {
                  // Move to next step - the state will be updated by the upload provider
                  // when the next upload completes, so we don't need to manually update step here
                  // The UI will automatically update based on the upload status
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(200, 50),
              ),
              child: Text(
                isFinal ? "Finish" : "Next",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}
