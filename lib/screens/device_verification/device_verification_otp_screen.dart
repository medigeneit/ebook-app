import 'dart:async';
import 'package:ebook_project/components/app_layout.dart';
import 'package:ebook_project/models/device_verification_model/device_verification_model.dart';
import 'package:ebook_project/models/device_verification_model/device_verification_otp_model.dart';
import 'package:ebook_project/models/device_verification_model/device_verification_submit_model.dart';
import 'package:ebook_project/services/device_verification_service/device_verification_otp_service.dart';
import 'package:ebook_project/services/device_verification_service/device_verification_request_service.dart';
import 'package:ebook_project/services/device_verification_service/device_verification_service.dart';
import 'package:ebook_project/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';

class DeviceVerificationOtpScreen extends StatefulWidget {
  const DeviceVerificationOtpScreen({super.key});

  @override
  State<DeviceVerificationOtpScreen> createState() =>
      _DeviceVerificationOtpScreenState();
}

class _DeviceVerificationOtpScreenState
    extends State<DeviceVerificationOtpScreen> {
  DeviceVerificationModel? verificationData;
  DeviceVerificationSubmitModel? submitData;
  late String steps;
  bool _argsLoaded = false;
  int countdown = 0;
  Timer? _timer;
  bool showResend = false;
  bool showOtpField = true;
  bool isLoading = true;
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    steps = 'STEP1';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsLoaded) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    steps = args is String && args.isNotEmpty ? args : 'STEP1';
    _argsLoaded = true;
    _loadInitialData();
  }

  void _loadInitialData() async {
    await _fetchDeviceVerification();
    await _fetchRequestDeviceVerification();
  }

  Future<void> _fetchDeviceVerification() async {
    final response = await DeviceVerificationService().fetchDeviceVerification();
    if (response.isSuccess) {
      final model = response.responseData as DeviceVerificationModel;

      if (model.currentStep == 'STEP3') {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/device-verification-reason');
        return;
      }

      setState(() {
        verificationData = model;
      });
    }
  }

  Future<void> _fetchRequestDeviceVerification() async {
    final stepPath = steps == 'STEP1'
        ? '/create'
        : steps == 'STEP2'
            ? '/change'
            : '';

    final response = await DeviceVerificationRequestService()
        .requestAgreementVerification(step: stepPath);

    if (response.isSuccess) {
      final model = response.responseData as DeviceVerificationSubmitModel;

      steps = model.nextStep ?? steps;

      setState(() {
        submitData = model;
        countdown = model.otpExpireTimeInSeconds ?? 0;
        showOtpField = true;
        isLoading = false;
        showResend = false;
      });

      if ((submitData?.availableSmsCount ?? 0) == 0) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/device-verification-reason');
        Get.snackbar(
          'Error',
          'OTP is not available now. Please submit your reason & contact the office to verify your device.',
          backgroundColor: AppColors.danger,
          colorText: Colors.white,
        );
        return;
      }

      if ((submitData?.availableSmsCount ?? 0) > 0 && countdown > 0) {
        _startCountdown();
      }
    } else {
      Get.snackbar(
        'Error',
        'Failed to request verification',
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
      );
      setState(() => isLoading = false);
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (countdown > 0) {
          countdown--;
        } else {
          timer.cancel();
          showOtpField = false;
          showResend = (submitData?.availableSmsCount ?? 0) > 0;
        }
      });
    });
  }

  Future<void> _submitOtp() async {
    final otp = _controllers.map((c) => c.text.trim()).join();

    if (otp.isEmpty) {
      Get.snackbar(
        'Error',
        'Enter OTP',
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => isLoading = true);
    final response =
        await DeviceVerificationOtpService().submitOtp(otpCode: otp, step: '');

    setState(() => isLoading = false);

    if (response.isSuccess) {
      final model = response.responseData as SubmitVerificationOtpModel;
      if (model.success == true) {
        _timer?.cancel();
        Get.snackbar(
          'Success',
          model.message ?? 'OTP Verified',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/device-verification');
      } else {
        Get.snackbar(
          'Failed',
          model.message ?? 'OTP Verification Failed',
          backgroundColor: AppColors.danger,
          colorText: Colors.white,
        );
      }
    } else {
      String errorMessage = response.errorMessage ?? 'Invalid OTP';
      if (response.statusCode == 404) {
        final data = response.responseData;
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          errorMessage = data['message'];
        }
      }
      Get.snackbar('Error', errorMessage,
          backgroundColor: AppColors.danger, colorText: Colors.white);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = verificationData?.currentDevice?.isSmartPhone == true
        ? Icons.smartphone
        : Icons.computer;

    return AppLayout(
      title: 'Device OTP Verification',
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ListTile(
                          leading: Icon(icon, size: 28),
                          title: Text(
                            verificationData?.currentDevice?.name ??
                                'Unknown Device',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Html(
                          data: submitData?.otpSmsMessage ?? '',
                          style: {
                            '*': Style(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            )
                          },
                        ),
                        const SizedBox(height: 12),
                        if (submitData?.message != null)
                          Text(
                            submitData!.message!,
                            style: const TextStyle(color: Colors.black87),
                          ),
                        if (showOtpField)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: SizedBox(
                                  width: 50,
                                  height: 55,
                                  child: TextField(
                                    controller: _controllers[index],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    maxLength: 1,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      if (value.isNotEmpty && index < 3) {
                                        FocusScope.of(context).nextFocus();
                                      }
                                    },
                                  ),
                                ),
                              );
                            }),
                          ),
                        const SizedBox(height: 12),
                        if (countdown > 0)
                          Text('OTP will expire in $countdown seconds',
                              style: const TextStyle(color: Colors.grey)),
                        if (submitData?.availableSmsCount == 0)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'OTP is not available now. Please contact the office to verify your device.',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else if (showResend)
                          TextButton(
                            onPressed: _fetchRequestDeviceVerification,
                            child: const Text('Resend OTP'),
                          ),
                        const SizedBox(height: 16),
                        if (showOtpField)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary),
                            onPressed: _submitOtp,
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text('Submit OTP',
                                style: TextStyle(color: Colors.white)),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
