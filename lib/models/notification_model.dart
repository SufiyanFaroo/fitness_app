class NotificationModel {
  final String id;
  final String title;
  final String time;
  final String image;
  final String day;

  NotificationModel({
    required this.id,
    required this.title,
    required this.time,
    required this.image,
    required this.day,
  });

  // Firestore se data map karne ke liye
  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      time: map['time'] ?? '',
      image: map['image'] ?? '',
      day: map['day'] ?? 'Today',
    );
  }
}
