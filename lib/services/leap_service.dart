/// Classic "wonder weeks" developmental leap windows, computed from birthdate.
/// General developmental information — not medical advice.
class LeapInfo {
  LeapInfo({
    required this.inLeap,
    this.leapNumber,
    this.upcomingInDays,
    this.title = '',
    this.description = '',
  });

  final bool inLeap;
  final int? leapNumber;
  final int? upcomingInDays; // days until next leap starts (if soon)
  final String title;
  final String description;

  bool get hasUpcoming => upcomingInDays != null;
}

class LeapService {
  LeapService._();
  static final LeapService instance = LeapService._();

  // Leap "fussy period" centre weeks from birth.
  static const _leapWeeks = [5, 8, 12, 19, 26, 37, 46, 55, 64, 75];

  static const _titles = {
    5: 'Changing Sensations',
    8: 'Patterns',
    12: 'Smooth Transitions',
    19: 'Events',
    26: 'Relationships',
    37: 'Categories',
    46: 'Sequences',
    55: 'Programs',
    64: 'Principles',
    75: 'Systems',
  };

  static const _desc = {
    5: 'Senses sharpen — your baby may be more alert and more easily overwhelmed.',
    8: 'Baby starts noticing patterns and shapes. Expect more fussiness and clinginess.',
    12: 'Movements get smoother. Lots of change can mean lots of feelings.',
    19: 'Baby grasps short sequences of events — the world is busy and tiring.',
    26: 'Understanding distance and relationships — separation anxiety often spikes.',
    37: 'Sorting the world into categories. Big brain work = big feelings.',
    46: 'Following sequences and steps. Routines feel extra reassuring now.',
    55: 'Carrying out "programs" (little plans). Independence and frustration grow.',
    64: 'Weighing options and testing limits — toddler push-and-pull.',
    75: 'Understanding systems and rules. Identity and big emotions emerge.',
  };

  int ageInWeeks(DateTime birthDate) =>
      DateTime.now().difference(birthDate).inDays ~/ 7;

  LeapInfo current(DateTime birthDate) {
    final weeks = ageInWeeks(birthDate);
    // In a leap if within ±1 week of a leap centre.
    for (final lw in _leapWeeks) {
      if ((weeks - lw).abs() <= 1) {
        final n = _leapWeeks.indexOf(lw) + 1;
        return LeapInfo(
          inLeap: true,
          leapNumber: n,
          title: _titles[lw] ?? '',
          description: _desc[lw] ?? '',
        );
      }
    }
    // Upcoming within ~3 days (i.e. leap centre is ~next week)?
    for (final lw in _leapWeeks) {
      final daysUntil = (lw * 7) - DateTime.now().difference(birthDate).inDays;
      if (daysUntil > 0 && daysUntil <= 3) {
        final n = _leapWeeks.indexOf(lw) + 1;
        return LeapInfo(
          inLeap: false,
          leapNumber: n,
          upcomingInDays: daysUntil,
          title: _titles[lw] ?? '',
          description: _desc[lw] ?? '',
        );
      }
    }
    return LeapInfo(inLeap: false);
  }
}
