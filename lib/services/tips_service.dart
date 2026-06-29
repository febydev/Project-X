/// A small on-device library of age-based developmental notes.
/// This powers the FREE "note from Mira" daily tip. The premium AI chat goes
/// far beyond this — but a tired parent always gets something real for free.
class TipsService {
  TipsService._();
  static final TipsService instance = TipsService._();

  /// Returns a tip tailored to the baby's age in months, rotating daily.
  String tipForAge(int ageMonths) {
    final pool = _poolForAge(ageMonths);
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return pool[dayOfYear % pool.length];
  }

  List<String> _poolForAge(int m) {
    if (m < 3) {
      return [
        'Newborns can\u2019t be "spoiled" by holding. Responding quickly to cries builds security and a calmer baby over time.',
        'Frequent feeds are normal now — tiny tummies empty fast. Watch for early hunger cues like rooting and hands to mouth.',
        'Skin-to-skin time helps regulate your baby\u2019s temperature, heart rate and stress. It soothes you too.',
      ];
    }
    if (m < 6) {
      return [
        'Around now babies discover their hands. Offer high-contrast toys within reach to build hand-eye coordination.',
        'Short, frequent naps can signal overtiredness. Watching wake windows often leads to deeper, longer sleep.',
        'Talking and narrating your day wires language early — your voice is your baby\u2019s favourite sound.',
      ];
    }
    if (m < 12) {
      return [
        'Separation anxiety often appears now. It\u2019s a sign of healthy attachment, not a setback — a short goodbye ritual helps.',
        'Letting your baby explore safe textures and finger foods supports motor skills and a healthy relationship with eating.',
        'Repetition is learning. Reading the same book again and again is exactly how little brains build understanding.',
      ];
    }
    if (m < 24) {
      return [
        'Tantrums aren\u2019t manipulation — the brain\u2019s "brakes" aren\u2019t built yet. Naming the feeling ("you\u2019re frustrated") actually helps wire it.',
        'Toddlers crave control. Offering two okay choices ("red cup or blue cup?") prevents many power struggles.',
        'Big feelings need a calm anchor. Your steady presence teaches them their emotions are safe and survivable.',
      ];
    }
    return [
      'Connection before correction: a calm, brief acknowledgment of feelings makes limits land better than a lecture.',
      'Play is how children process their world. Ten minutes of child-led play can reduce attention-seeking behaviour.',
      'Predictable routines lower anxiety for young children — they feel safest when they know what comes next.',
    ];
  }

  /// Generic, research-informed Calm Mode steps used as an offline fallback
  /// and as the structure the AI personalises.
  List<CalmStep> calmSteps() => const [
        CalmStep(
          title: 'First, steady yourself',
          body:
              'Take one slow breath in for 4, out for 6. A calm adult is the fastest way to calm a child — your nervous system leads theirs.',
          seconds: 12,
        ),
        CalmStep(
          title: 'Get low and close',
          body:
              'Come down to their eye level. Soften your face and voice. Safety and presence first, words second.',
          seconds: 0,
        ),
        CalmStep(
          title: 'Name the feeling',
          body:
              'Try: "You really wanted that. You\u2019re so upset." Feeling understood lowers the intensity faster than reasoning.',
          seconds: 0,
        ),
        CalmStep(
          title: 'Hold the limit, kindly',
          body:
              'You can accept the feeling and still keep the boundary: "I won\u2019t let you hit. I\u2019m right here while you\u2019re mad."',
          seconds: 0,
        ),
        CalmStep(
          title: 'Wait it through',
          body:
              'Most tantrums pass in a few minutes. Stay near, stay quiet, let the wave crest and fall. Reconnect after.',
          seconds: 0,
        ),
      ];
}

class CalmStep {
  const CalmStep({required this.title, required this.body, this.seconds = 0});
  final String title;
  final String body;
  final int seconds;
}
