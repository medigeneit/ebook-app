import 'package:ebook_project/components/app_layout.dart';
import 'package:ebook_project/models/device_verification_model/device_verification_model.dart';
import 'package:ebook_project/services/device_info_util.dart';
import 'package:ebook_project/services/device_verification_service/device_verification_service.dart';
import 'package:ebook_project/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'device_verification_dialog.dart';

class DeviceVerificationScreen extends StatefulWidget {
  const DeviceVerificationScreen({super.key});

  @override
  State<DeviceVerificationScreen> createState() =>
      _DeviceVerificationScreenState();
}

class _DeviceVerificationScreenState extends State<DeviceVerificationScreen> {
  bool _loading = true;
  String? _error;
  DeviceVerificationModel? _data;

  @override
  void initState() {
    super.initState();
    DeviceInfoUtil.saveDeviceInfo().then((_) => _fetchDeviceData());
  }

  Future<void> _fetchDeviceData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await DeviceVerificationService().fetchDeviceVerification();
    if (response.isSuccess) {
      setState(() {
        _data = response.responseData as DeviceVerificationModel;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = false;
      _error = response.errorMessage ?? 'Failed to load data';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Device Verification',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDeviceData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) ...[
                    Text(_error!,
                        style: const TextStyle(color: AppColors.danger)),
                    const SizedBox(height: 12),
                  ],
                  if (_data == null)
                    const Text('No device verification data found.')
                  else
                    _buildContent(context, _data!),
                ],
              ),
            ),
    );
  }

  Widget _buildContent(BuildContext context, DeviceVerificationModel data) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(context, 'Verified Devices (Device / Browser)'),
            const Divider(),
            if (data.activeDevices.isNotEmpty)
              ...data.activeDevices.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _deviceCard(d, verified: true),
                ),
              )
            else
              const Text('No verified device found',
                  style: TextStyle(color: Colors.red)),
            const SizedBox(height: 24),
            _sectionTitle(context, 'Current Device'),
            const Divider(),
            if (data.currentDevice != null)
              _deviceCard(data.currentDevice!, isCurrent: true),
            const SizedBox(height: 12),
            if (data.currentDevice != null)
              (data.currentDevice!.isActive
                  ? _statusCard('Your current device has been verified',
                      Colors.green.shade300)
                  : Html(
                      data: data.deviceWarning.isNotEmpty
                          ? data.deviceWarning
                          : '<p>No warning available</p>',
                      style: {
                        '*': Style(
                          color: Colors.red,
                          fontSize: FontSize.medium,
                          alignment: Alignment.center,
                          textAlign: TextAlign.center,
                        ),
                      },
                    )),
            const SizedBox(height: 16),
            if (data.currentDevice != null)
              (data.currentDevice!.isActive
                  ? _actionButton(
                      context,
                      'Go to My Ebooks',
                      Colors.green.shade700,
                      () => Navigator.pushNamed(context, '/my-ebooks'),
                    )
                  : _actionButton(
                      context,
                      'Request to Verify',
                      AppColors.primary,
                      () {
                        if (data.currentStep == 'STEP1' ||
                            data.currentStep == 'STEP2') {
                          showDeviceVerificationDialog(context, data);
                        } else {
                          Navigator.pushNamed(
                              context, '/device-verification-reason');
                        }
                      },
                    )),
          ],
        ),
      ),
    );
  }

  Widget _deviceCard(Device device,
      {bool verified = false, bool isCurrent = false}) {
    final isPhone = device.isSmartPhone;
    final icon = isPhone ? Icons.smartphone : Icons.computer;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(device.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (isCurrent)
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: device.isActive ? Colors.green : Colors.red,
                ),
              )
            else if (verified)
              const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue),
    );
  }

  Widget _statusCard(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black87),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _actionButton(
      BuildContext context, String text, Color color, VoidCallback onPressed) {
    return Center(
      child: SizedBox(
        width: 220,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: color),
          icon: const Icon(Icons.arrow_forward, color: Colors.white),
          label: Text(text, style: const TextStyle(color: Colors.white)),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
