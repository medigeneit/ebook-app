class DeviceVerificationReasonSubmitModel {
  final String message;
  final bool success;
  final String nextStep;

  DeviceVerificationReasonSubmitModel({
    required this.message,
    required this.success,
    required this.nextStep,
  });

  factory DeviceVerificationReasonSubmitModel.fromJson(
      Map<String, dynamic> json) {
    return DeviceVerificationReasonSubmitModel(
      message: json['message'] ?? '',
      success: json['success'] ?? false,
      nextStep: json['next_step'] ?? '',
    );
  }
}
