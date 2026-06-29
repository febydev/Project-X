/// A daily wellbeing check-in for the parent (not the baby).
class MomCheckin {
  MomCheckin({
    required this.date, // yyyy-mm-dd
    required this.sleep,
    required this.mood,
    required this.body,
  });

  final String date;
  final int sleep; // 1..5
  final int mood; // 1..5
  final int body; // 1..5

  double get score => (sleep + mood + body) / 3.0;

  Map<String, dynamic> toJson() =>
      {'date': date, 'sleep': sleep, 'mood': mood, 'body': body};

  factory MomCheckin.fromJson(Map<String, dynamic> j) => MomCheckin(
        date: j['date'] as String,
        sleep: j['sleep'] as int,
        mood: j['mood'] as int,
        body: j['body'] as int,
      );
}
