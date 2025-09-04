class AttendanceData {
  final String date;
  final String type;
  final String id;

  AttendanceData({required this.date, required this.type, required this.id});

  factory AttendanceData.fromJson(Map<String, dynamic> json) {
    return AttendanceData(
      date: json['date'] ?? '',
      type: json['type'] ?? '',
      id: json['id'] ?? '',
    );
  }
}