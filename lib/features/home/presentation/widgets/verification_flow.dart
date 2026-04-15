import 'package:discovaa/features/home/presentation/providers/image_upload_provider.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/verification_provider.dart';

class VerificationFlowDialog extends ConsumerStatefulWidget {
  const VerificationFlowDialog({super.key});

  @override
  ConsumerState<VerificationFlowDialog> createState() =>
      _VerificationFlowDialogState();
}

class _VerificationFlowDialogState
    extends ConsumerState<VerificationFlowDialog> {
  @override
  Widget build(BuildContext context) {
    final verificationState = ref.watch(verificationProvider);
    final step = verificationState.currentStep;
    final notifier = ref.read(verificationProvider.notifier);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildStepContent(context, step, notifier),
        ),
      ),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    VerificationStep step,
    VerificationNotifier notifier,
  ) {
    switch (step) {
      case VerificationStep.idFront:
      case VerificationStep.idBack:
        final uploadState = ref.watch(imageUploadProvider);
        final isUploading = step == VerificationStep.idFront
            ? uploadState.frontUploadStatus == UploadStatus.uploading
            : uploadState.backUploadStatus == UploadStatus.uploading;

        return _UploadView(
          isFront: step == VerificationStep.idFront,
          isBusiness: false,
          isUploading: isUploading,
          onUpload: () async {
            await ref
                .read(imageUploadProvider.notifier)
                .pickImage(
                  ImageSource.gallery,
                  isFront: step == VerificationStep.idFront,
                );
            notifier.next();
          },
        );
      case VerificationStep.businessFront:
        final uploadState = ref.watch(imageUploadProvider);
        final isUploading =
            uploadState.frontUploadStatus == UploadStatus.uploading;

        return _UploadView(
          isFront: true,
          isBusiness: true,
          isUploading: isUploading,
          onUpload: () async {
            await ref
                .read(imageUploadProvider.notifier)
                .pickImage(ImageSource.gallery, isFront: true);
            notifier.next();
          },
        );
      case VerificationStep.idFrontSuccess:
      case VerificationStep.idBackSuccess:
      case VerificationStep.businessFrontSuccess:
        String title = "";
        if (step == VerificationStep.idFrontSuccess) {
          title = "Front Page Upload Successful !";
        } else if (step == VerificationStep.idBackSuccess) {
          title = "Back Page Upload Successful !";
        } else {
          title = "Business Doc Upload Successful !";
        }
        return _SuccessView(
          title: title,
          onNext: () {
            if (step == VerificationStep.idBackSuccess ||
                step == VerificationStep.businessFrontSuccess) {
              Navigator.pop(context);
            }
            notifier.next();
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _UploadView extends StatefulWidget {
  final bool isFront;
  final bool isBusiness;
  final bool isUploading;
  final VoidCallback onUpload;

  const _UploadView({
    required this.isFront,
    required this.isBusiness,
    required this.isUploading,
    required this.onUpload,
  });

  @override
  State<_UploadView> createState() => _UploadViewState();
}

class _UploadViewState extends State<_UploadView> {
  bool _isConfirmed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey(widget.isFront.toString() + widget.isBusiness.toString()),
      mainAxisSize: MainAxisSize.min,
      children: [
        // STEP INDICATOR (MATCHING IMAGE 3)
        if (!widget.isBusiness)
          Column(
            children: [
              _indicatorRow(
                1,
                "Upload document front page",
                active: widget.isFront,
                completed: !widget.isFront,
              ),
              const Divider(height: 40),
              _indicatorRow(
                2,
                "Upload document back page",
                active: !widget.isFront,
                completed: false,
              ),
            ],
          )
        else
          _indicatorRow(
            1,
            "Upload business document",
            active: true,
            completed: false,
          ),
        const Divider(height: 40, color: Colors.grey),
        const SizedBox(height: 12),

        // UPLOAD BOX (MATCHING IMAGE 3)
        DottedBorder(
          options: RectDottedBorderOptions(
            dashPattern: const [6, 4],
            color: Colors.grey.shade300,
            strokeWidth: 1.5,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Image.asset(
                  'assets/icons/file_upload.png', // Fallback to icon if asset missing
                  width: 48,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.file_copy_outlined,
                    size: 48,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Please upload a copy of your valid identification in PNG, JPEG or PDF format, no longer than 3mb in size",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isConfirmed && !widget.isUploading
                      ? widget.onUpload
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade300,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    widget.isUploading ? "Uploading..." : "Upload document",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // CONFIRMATION CHECKBOX (MATCHING IMAGE 3)
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _isConfirmed,
                activeColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (v) {
                  setState(() {
                    _isConfirmed = v ?? false;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "I confirm document is valid until the expiry date and is in color",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _indicatorRow(
    int n,
    String text, {
    required bool active,
    required bool completed,
  }) {
    final color = active
        ? Colors.blue
        : (completed ? Colors.grey : Colors.grey.shade300);
    return Row(
      children: [
        DottedBorder(
          options: CircularDottedBorderOptions(
            dashPattern: active ? [4, 2] : [1, 0],
            color: color,
            strokeWidth: 2,
          ),
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Text(
              "$n",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: TextStyle(
            color: active ? Colors.black : Colors.grey,
            fontSize: 14,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String title;
  final VoidCallback onNext;

  const _SuccessView({required this.title, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.file_copy_outlined,
                color: Colors.white,
                size: 40,
              ),
            ),
            // Scattered decorative dots matching Image 3
            _positionedDot(const Offset(-50, -40), 10), // Top Left
            _positionedDot(const Offset(-65, 10), 6), // Mid Left
            _positionedDot(const Offset(-40, 55), 8), // Bottom Left
            _positionedDot(const Offset(55, -45), 12), // Top Right
            _positionedDot(const Offset(65, 20), 8), // Mid Right
            _positionedDot(const Offset(10, 65), 6), // Bottom
          ],
        ),
        const SizedBox(height: 32),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Next",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _positionedDot(Offset offset, double size) {
    return Transform.translate(
      offset: offset,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
