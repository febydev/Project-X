/// A single message in a conversation with Mira.
class ChatMessage {
  ChatMessage({
    required this.text,
    required this.fromMira,
    DateTime? time,
  }) : time = time ?? DateTime.now();

  final String text;
  final bool fromMira;
  final DateTime time;

  Map<String, dynamic> toJson() => {
        'text': text,
        'fromMira': fromMira,
        'time': time.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'] as String,
        fromMira: json['fromMira'] as bool,
        time: DateTime.parse(json['time'] as String),
      );
}
