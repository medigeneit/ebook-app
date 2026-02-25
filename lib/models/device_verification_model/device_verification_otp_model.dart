class SubmitVerificationOtpModel {
  final String? message;
  final bool? success;

  SubmitVerificationOtpModel({this.message, this.success});

  factory SubmitVerificationOtpModel.fromJson(Map<String, dynamic> json) {
    return SubmitVerificationOtpModel(
      message: json['message'] as String?,
      success: json['success'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'success': success,
    };
  }
}
