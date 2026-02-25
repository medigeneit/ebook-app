import 'package:ebook_project/components/app_layout.dart';
import 'package:ebook_project/models/device_verification_model/device_verification_model.dart';
import 'package:ebook_project/models/device_verification_model/device_verification_reason_submit_model.dart';
import 'package:ebook_project/services/device_verification_service/device_verification_reason_submit_service.dart';
import 'package:ebook_project/services/device_verification_service/device_verification_service.dart';
import 'package:ebook_project/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';

class DeviceVerificationReasonSubmitScreen extends StatefulWidget {
  const DeviceVerificationReasonSubmitScreen({super.key});

  @override
  State<DeviceVerificationReasonSubmitScreen> createState() =>
      _DeviceVerificationReasonSubmitScreenState();
}

class _DeviceVerificationReasonSubmitScreenState
    extends State<DeviceVerificationReasonSubmitScreen> {
  bool isLoading = true;
  bool isEditable = false;
  bool showEditButton = false;
  bool showCancelButton = false;

  DeviceVerificationModel? data;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDeviceVerification();
  }

  Future<void> _fetchDeviceVerification() async {
    setState(() => isLoading = true);
    final response = await DeviceVerificationService().fetchDeviceVerification();
    if (response.isSuccess) {
      setState(() {
        data = response.responseData as DeviceVerificationModel;
        isLoading = false;

        if (data?.currentDevice?.replaceRequest != null) {
          _reasonController.text =
              data!.currentDevice!.replaceRequest!.reason;
          isEditable = false;
          showEditButton = true;
          showCancelButton = false;
        } else {
          _reasonController.clear();
          isEditable = true;
          showEditButton = false;
          showCancelButton = false;
        }
      });
    } else {
      setState(() => isLoading = false);
      Get.snackbar('Error', 'Failed to load data',
          backgroundColor: AppColors.danger, colorText: Colors.white);
    }
  }

  void _enableEdit() {
    setState(() {
      isEditable = true;
      showEditButton = false;
      showCancelButton = true;
    });
  }

  void _cancelEdit() {
    setState(() {
      _reasonController.text =
          data?.currentDevice?.replaceRequest?.reason ?? '';
      isEditable = false;
      showEditButton = true;
      showCancelButton = false;
    });
  }

  void _submitReason() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      Get.snackbar('Validation Error', 'Please enter your reason',
          backgroundColor: AppColors.danger, colorText: Colors.white);
      return;
    }

    setState(() => isLoading = true);

    final response =
        await DeviceVerificationReasonSubmitService().submitReason(reason: reason);

    if (response.isSuccess &&
        response.responseData is DeviceVerificationReasonSubmitModel) {
      final model = response.responseData as DeviceVerificationReasonSubmitModel;

      if (model.success) {
        Get.snackbar('Success', 'Your reason has been submitted successfully',
            backgroundColor: AppColors.success, colorText: Colors.white);
        _fetchDeviceVerification();
      } else {
        Get.snackbar('Failed', model.message,
            backgroundColor: AppColors.danger, colorText: Colors.white);
        setState(() => isLoading = false);
      }
    } else {
      Get.snackbar('Error', response.errorMessage ?? 'Server Error',
          backgroundColor: AppColors.danger, colorText: Colors.white);
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Device Reason Submit',
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
                        _deviceInfoCard(),
                        const SizedBox(height: 24),
                        _reasonTextBox(),
                        const SizedBox(height: 16),
                        if ((data?.showOtpLimitExpireMessage ?? '').isNotEmpty)
                          Html(
                            data: data!.showOtpLimitExpireMessage,
                            style: {
                              '*': Style(
                                fontSize: FontSize.medium,
                                color: Colors.red,
                                alignment: Alignment.center,
                                textAlign: TextAlign.center,
                              )
                            },
                          ),
                        const SizedBox(height: 8),
                        if ((data?.reasonSubmissionMessage ?? '').isNotEmpty)
                          Html(
                            data: data!.reasonSubmissionMessage,
                            style: {
                              '*': Style(
                                fontSize: FontSize.medium,
                                color: Colors.green,
                                alignment: Alignment.center,
                                textAlign: TextAlign.center,
                              )
                            },
                          ),
                        const SizedBox(height: 16),
                        _buildButtonRow(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _deviceInfoCard() {
    final device = data?.currentDevice;
    if (device == null) {
      return const SizedBox.shrink();
    }

    final icon = device.isSmartPhone ? Icons.smartphone : Icons.computer;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(device.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _reasonTextBox() {
    return TextField(
      controller: _reasonController,
      enabled: isEditable,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Enter reason here...',
        filled: !isEditable,
        fillColor: isEditable ? Colors.white : Colors.grey.shade200,
      ),
    );
  }

  Widget _buildButtonRow() {
    final buttons = <Widget>[];

    if (showEditButton) {
      buttons.add(_actionButton(
        color: AppColors.primary,
        icon: Icons.edit_rounded,
        label: 'Edit',
        onPressed: _enableEdit,
      ));
    }

    if (showCancelButton) {
      buttons.add(_actionButton(
        color: AppColors.danger,
        icon: Icons.cancel_outlined,
        label: 'Cancel',
        onPressed: _cancelEdit,
      ));
    }

    if (isEditable) {
      buttons.add(_actionButton(
        color: Colors.green,
        icon: Icons.send_rounded,
        label: 'Submit',
        onPressed: _submitReason,
      ));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    if (buttons.length == 1) {
      return Align(
        alignment: Alignment.center,
        child: SizedBox(width: 200, child: buttons.first),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          Expanded(child: buttons[i]),
          if (i != buttons.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _actionButton({
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}
