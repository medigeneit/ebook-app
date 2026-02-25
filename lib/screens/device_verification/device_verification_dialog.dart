import 'package:ebook_project/models/device_verification_model/device_verification_model.dart';
import 'package:ebook_project/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

Future<void> showDeviceVerificationDialog(
    BuildContext context, DeviceVerificationModel data) {
  final device = data.currentDevice;
  bool isChecked = false;

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final isPhone = device?.isSmartPhone == true;
          final icon = isPhone ? Icons.smartphone : Icons.computer;

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(icon,
                                size: 28, color: AppColors.primaryDeep),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                device?.name ?? 'Unknown Device',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: device?.isActive == true
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (data.termsAndConditions.isNotEmpty) ...[
                      Html(
                        data: data.termsAndConditions,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (data.otpSmsMessage.isNotEmpty) ...[
                      Html(
                        data: data.otpSmsMessage,
                        style: {
                          '*': Style(
                            color: Colors.red,
                            fontSize: FontSize.medium,
                          ),
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    CheckboxListTile(
                      value: isChecked,
                      onChanged: (val) =>
                          setState(() => isChecked = val ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'I agree with the terms and conditions',
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isChecked ? AppColors.primary : Colors.grey,
                      ),
                      icon: Icon(
                        isChecked ? Icons.arrow_forward : Icons.lock_outline,
                        color: Colors.white,
                      ),
                      label: const Text('Request OTP',
                          style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        if (!isChecked) return;
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          '/device-verification-otp',
                          arguments: data.currentStep,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
