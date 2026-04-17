import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/utils/form_validation.dart';
import '../providers/signup_provider.dart';

class OtpInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final OtpState otpState;
  final Function(String) onChanged;
  final Function(String) onCompleted;

  const OtpInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.otpState,
    required this.onChanged,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: Colors.blue, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    Color getBorderColor() {
      switch (otpState) {
        case OtpState.success:
          return Colors.green;
        case OtpState.error:
          return Colors.red;
        default:
          return Colors.grey.shade300;
      }
    }

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: otpState == OtpState.success
            ? Colors.green.withValues(alpha: 0.1)
            : otpState == OtpState.error
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.grey.shade100,
        border: Border.all(color: getBorderColor(), width: 1.5),
      ),
    );

    return Pinput(
      controller: controller,
      focusNode: focusNode,
      length: 6,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: focusedPinTheme,
      submittedPinTheme: submittedPinTheme,
      validator: (value) => FormValidationRules.validateOtp(value),
      onChanged: onChanged,
      onCompleted: onCompleted,
      keyboardType: TextInputType.text,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z]')),
      ],
      animationDuration: const Duration(milliseconds: 300),
      animationCurve: Curves.easeInOut,
    );
  }
}
