import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_message.dart';

/// Result of an AI request.
class AiResult {
  AiResult({this.reply, this.error});
  final String? reply;
  final String? error;
  bool get ok => reply != null;
}

/// Talks to Mira's Cloudflare Worker proxy (which holds the Gemini key).
/// The app never sees an API key.
class AiService {
  AiService._();
  static final AiService instance = AiService._();

  Future<AiResult> send({
    required String proxyUrl,
    required List<ChatMessage> history,
    required String babyName,
    required int ageMonths,
    String mode = 'chat',
  }) async {
    if (proxyUrl.trim().isEmpty) {
      return AiResult(
          error:
              'Mira isn\u2019t connected yet. Add your AI link in Settings to start chatting.');
    }

    try {
      final uri = Uri.parse(proxyUrl);
      final body = jsonEncode({
        'mode': mode,
        'baby': {'name': babyName, 'ageMonths': ageMonths},
        'messages': history
            .map((m) => {
                  'role': m.fromMira ? 'model' : 'user',
                  'text': m.text,
                })
            .toList(),
      });

      final res = await http
          .post(uri,
              headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 429) {
        return AiResult(
            error:
                'Mira is resting for a moment (busy line). Try again shortly.');
      }
      if (res.statusCode != 200) {
        return AiResult(
            error: 'Something went wrong (${res.statusCode}). Try again.');
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final reply = (data['reply'] as String?)?.trim();
      if (reply == null || reply.isEmpty) {
        return AiResult(error: data['error'] as String? ?? 'No reply received.');
      }
      return AiResult(reply: reply);
    } catch (_) {
      return AiResult(
          error:
              'Couldn\u2019t reach Mira. Check your connection and try again.');
    }
  }
}
