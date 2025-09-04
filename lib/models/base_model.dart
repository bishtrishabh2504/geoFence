class BaseModel {
  final bool? success;
  final String? message;
  final String? token;
  final int? userId;

  BaseModel({
    this.success,
    this.message,
    this.token,
    this.userId,
  });

  factory BaseModel.fromJson(Map<String, dynamic> json) {
    return BaseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['data']?['token'] ?? '',
      userId: json['data']?['id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'token': token,
      'userId': userId,
    };
  }
}
