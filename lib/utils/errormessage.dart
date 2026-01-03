class SnowCoolErrorResponse {
  final int status;
  final String message;
  final int timeStamp;

  SnowCoolErrorResponse({
    required this.status,
    required this.message,
    required this.timeStamp,
  });

  factory SnowCoolErrorResponse.fromJson(Map<String, dynamic> json) {
    return SnowCoolErrorResponse(
      status: json['status'] as int,
      message: json['message'] as String,
      timeStamp: json['timeStamp'] as int,
    );
  }

  @override
  String toString() {
    return 'SnowCoolErrorResponse(status: $status, message: $message, timeStamp: $timeStamp)';
  }
}