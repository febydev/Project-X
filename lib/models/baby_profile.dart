/// The child Mira is helping with. Stored on-device.
class BabyProfile {
  BabyProfile({
    required this.name,
    required this.birthDate,
  });

  final String name;
  final DateTime birthDate;

  /// Age in whole months (used to tailor advice and tips).
  int get ageInMonths {
    final now = DateTime.now();
    var months = (now.year - birthDate.year) * 12 + (now.month - birthDate.month);
    if (now.day < birthDate.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  /// A friendly age label like "3 months" or "2 years 1 month".
  String get ageLabel {
    final m = ageInMonths;
    if (m < 1) {
      final days = DateTime.now().difference(birthDate).inDays;
      return '$days day${days == 1 ? '' : 's'} old';
    }
    if (m < 24) return '$m month${m == 1 ? '' : 's'}';
    final years = m ~/ 12;
    final rem = m % 12;
    if (rem == 0) return '$years year${years == 1 ? '' : 's'}';
    return '$years yr ${rem}mo';
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'birthDate': birthDate.toIso8601String(),
      };

  factory BabyProfile.fromJson(Map<String, dynamic> json) => BabyProfile(
        name: json['name'] as String,
        birthDate: DateTime.parse(json['birthDate'] as String),
      );

  BabyProfile copyWith({String? name, DateTime? birthDate}) => BabyProfile(
        name: name ?? this.name,
        birthDate: birthDate ?? this.birthDate,
      );
}
