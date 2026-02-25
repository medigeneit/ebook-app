int asInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? fallback;
  return fallback;
}

String asString(dynamic v, {String fallback = ''}) {
  if (v == null) return fallback;
  return v.toString();
}

bool asBool(dynamic v, {bool fallback = false}) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is double) return v.toInt() == 1;
  if (v is String) {
    final s = v.toLowerCase().trim();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  return fallback;
}

Map<String, dynamic>? asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  return null;
}

List<dynamic> asList(dynamic v) {
  if (v is List) return v;
  return const [];
}

class Device {
  final int id;
  final String doctorId;
  final String uuid;
  final String userAgent;
  final String deviceType;
  final String lastUsedAt;
  final String? verifiedAt;
  final String? expiredAt;
  final bool isActive;
  final bool isInactive;
  final bool isExpire;
  final bool isOnline;
  final String name;
  final bool isSmartPhone;
  final bool isApp;
  final bool isAndroid;
  final ReplaceRequest? replaceRequest;

  Device({
    required this.id,
    required this.doctorId,
    required this.uuid,
    required this.userAgent,
    required this.deviceType,
    required this.lastUsedAt,
    this.verifiedAt,
    this.expiredAt,
    required this.isActive,
    required this.isInactive,
    required this.isExpire,
    required this.isOnline,
    required this.name,
    required this.isSmartPhone,
    required this.isApp,
    required this.isAndroid,
    this.replaceRequest,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: asInt(json['id']),
      doctorId: asString(json['doctor_id']),
      uuid: asString(json['uuid']),
      userAgent: asString(json['user_agent']),
      deviceType: asString(json['device_type']),
      lastUsedAt: asString(json['last_used_at']),
      verifiedAt: json['verified_at']?.toString(),
      expiredAt: json['expired_at']?.toString(),
      isActive: asBool(json['is_active']),
      isInactive: asBool(json['is_inactive']),
      isExpire: asBool(json['is_expire']),
      isOnline: asBool(json['is_online']),
      name: asString(json['name']),
      isSmartPhone: asBool(json['is_smart_phone']),
      isApp: asBool(json['is_app']),
      isAndroid: asBool(json['is_android']),
      replaceRequest: asMap(json['replace_request']) != null
          ? ReplaceRequest.fromJson(asMap(json['replace_request'])!)
          : null,
    );
  }
}

class WarningNote {
  final int id;
  final String name;
  final String value;

  WarningNote({
    required this.id,
    required this.name,
    required this.value,
  });

  factory WarningNote.fromJson(Map<String, dynamic> json) {
    return WarningNote(
      id: asInt(json['id']),
      name: asString(json['name']),
      value: asString(json['value']),
    );
  }
}

class ReplaceRequest {
  final int id;
  final String doctorDeviceId;
  final String doctorId;
  final String reason;
  final String type;
  final String? note;
  final String? acceptAt;
  final String? acceptBy;
  final String createdAt;
  final String updatedAt;
  final bool isPending;

  ReplaceRequest({
    required this.id,
    required this.doctorDeviceId,
    required this.doctorId,
    required this.reason,
    required this.type,
    this.note,
    this.acceptAt,
    this.acceptBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isPending,
  });

  factory ReplaceRequest.fromJson(Map<String, dynamic> json) {
    return ReplaceRequest(
      id: asInt(json['id']),
      doctorDeviceId: asString(json['doctor_device_id']),
      doctorId: asString(json['doctor_id']),
      reason: asString(json['reason']),
      type: asString(json['type']),
      note: json['note']?.toString(),
      acceptAt: json['accept_at']?.toString(),
      acceptBy: json['accept_by']?.toString(),
      createdAt: asString(json['created_at']),
      updatedAt: asString(json['updated_at']),
      isPending: asBool(json['is_pending']),
    );
  }
}

class DeviceVerificationModel {
  final Device? currentDevice;
  final List<Device> activeDevices;
  final int countExpiredDoctorDevices;
  final String currentStep;
  final String termsAndConditions;
  final String deviceWarning;
  final int otpExpireTimeInSecond;
  final String reasonSubmissionMessage;
  final String otpSmsMessage;
  final String showOtpLimitExpireMessage;

  final WarningNote? appFirstTimeAddSmsWarning;
  final WarningNote? appFirstTimeReplaceSmsWarning;
  final WarningNote? appNoMoreOtpNote;
  final WarningNote? appDeviceReplaceRequestToAdminNote;

  final String gnsDdt;

  DeviceVerificationModel({
    this.currentDevice,
    required this.activeDevices,
    required this.countExpiredDoctorDevices,
    required this.currentStep,
    required this.termsAndConditions,
    required this.deviceWarning,
    required this.otpExpireTimeInSecond,
    required this.reasonSubmissionMessage,
    required this.otpSmsMessage,
    required this.showOtpLimitExpireMessage,
    this.appFirstTimeAddSmsWarning,
    this.appFirstTimeReplaceSmsWarning,
    this.appNoMoreOtpNote,
    this.appDeviceReplaceRequestToAdminNote,
    required this.gnsDdt,
  });

  factory DeviceVerificationModel.fromJson(Map<String, dynamic> json) {
    final currentDeviceMap = asMap(json['current_device']);

    final activeList = asList(json['active_devices'])
        .whereType<Map>()
        .map((e) => Device.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return DeviceVerificationModel(
      currentDevice:
          currentDeviceMap != null ? Device.fromJson(currentDeviceMap) : null,
      activeDevices: activeList,
      countExpiredDoctorDevices: asInt(json['count_expired_doctor_devices']),
      currentStep: asString(json['current_step']),
      termsAndConditions: asString(json['terms_and_conditions']),
      deviceWarning: asString(json['device_warning']),
      otpExpireTimeInSecond: asInt(json['otp_expire_time_in_second']),
      reasonSubmissionMessage: asString(json['reason_submission_message']),
      otpSmsMessage: asString(json['otp_sms_message']),
      showOtpLimitExpireMessage: asString(json['show_otp_limit_expire_message']),

      appFirstTimeAddSmsWarning:
          asMap(json['first_time_add_sms_warning']) != null
              ? WarningNote.fromJson(asMap(json['first_time_add_sms_warning'])!)
              : null,

      appFirstTimeReplaceSmsWarning:
          asMap(json['first_time_replace_sms_warning']) != null
              ? WarningNote.fromJson(
                  asMap(json['first_time_replace_sms_warning'])!)
              : null,

      appNoMoreOtpNote: asMap(json['no_more_otp_note']) != null
          ? WarningNote.fromJson(asMap(json['no_more_otp_note'])!)
          : null,

      appDeviceReplaceRequestToAdminNote:
          asMap(json['device_replace_request_to_admin_note']) != null
              ? WarningNote.fromJson(
                  asMap(json['device_replace_request_to_admin_note'])!)
              : null,

      gnsDdt: asString(json['gns_ddt']),
    );
  }
}
