class DeviceVerificationSubmitModel {
  final String? actionValue;
  final String? otpSmsMessage;
  final bool? sendOptStatus;
  final int? otpExpireTimeInSeconds;
  final String? termsAndConditions;
  final CurrentDevice? currentDevice;
  final int? sentSmsCount;
  final int? availableSmsCount;
  final String? message;
  final bool? success;
  final String? nextStep;
  final String? method;

  DeviceVerificationSubmitModel({
    this.actionValue,
    this.otpSmsMessage,
    this.sendOptStatus,
    this.otpExpireTimeInSeconds,
    this.termsAndConditions,
    this.currentDevice,
    this.sentSmsCount,
    this.availableSmsCount,
    this.message,
    this.success,
    this.nextStep,
    this.method,
  });

  factory DeviceVerificationSubmitModel.fromJson(Map<String, dynamic> json) {
    return DeviceVerificationSubmitModel(
      actionValue: json['action_value'],
      otpSmsMessage: json['otp_sms_message'],
      sendOptStatus: json['send_opt_status'],
      otpExpireTimeInSeconds: json['otp_expire_time_in_second'],
      termsAndConditions: json['terms_and_conditions'],
      currentDevice: json['current_device'] != null
          ? CurrentDevice.fromJson(json['current_device'])
          : null,
      sentSmsCount: json['sent_sms_count'],
      availableSmsCount: json['available_sms_count'],
      message: json['message'],
      success: json['success'],
      nextStep: json['next_step'],
      method: json['method'],
    );
  }
}

class CurrentDevice {
  final int? id;
  final String? doctorId;
  final String? uuid;
  final String? userAgent;
  final String? lastUsedAt;
  final String? verifiedAt;
  final String? expiredAt;
  final bool? isActive;
  final bool? isInactive;
  final bool? isExpire;
  final bool? isOnline;
  final String? name;
  final bool? isSmartPhone;
  final dynamic replaceRequest;

  CurrentDevice({
    this.id,
    this.doctorId,
    this.uuid,
    this.userAgent,
    this.lastUsedAt,
    this.verifiedAt,
    this.expiredAt,
    this.isActive,
    this.isInactive,
    this.isExpire,
    this.isOnline,
    this.name,
    this.isSmartPhone,
    this.replaceRequest,
  });

  factory CurrentDevice.fromJson(Map<String, dynamic> json) {
    return CurrentDevice(
      id: json['id'],
      doctorId: json['doctor_id'],
      uuid: json['uuid'],
      userAgent: json['user_agent'],
      lastUsedAt: json['last_used_at'],
      verifiedAt: json['verified_at'],
      expiredAt: json['expired_at'],
      isActive: json['is_active'],
      isInactive: json['is_inactive'],
      isExpire: json['is_expire'],
      isOnline: json['is_online'],
      name: json['name'],
      isSmartPhone: json['is_smart_phone'],
      replaceRequest: json['replace_request'],
    );
  }
}
