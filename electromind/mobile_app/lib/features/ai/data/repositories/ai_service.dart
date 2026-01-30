import 'dart:convert';
import 'package:http/http.dart' as http;

class AiResponse {
  final String reply;
  final String? action;
  final Map<String, dynamic>? actionData;

  AiResponse({required this.reply, this.action, this.actionData});

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    return AiResponse(
      reply: json['reply'] ?? '',
      action: json['action'],
      actionData: json['action_data'],
    );
  }
}

class AiService {
  // Use 127.0.0.1 for Web/iOS Simulator, 10.0.2.2 for Android Emulator
  // Since we run on Chrome, localhost or 127.0.0.1 is fine.
  static const String _baseUrl = 'http://127.0.0.1:8000/api/v1';

  Future<AiResponse> sendMessage(String message, {String? context}) async {
    try {
      final url = Uri.parse('$_baseUrl/chat');
      final body = jsonEncode({
        'message': message,
        'context': context,
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AiResponse.fromJson(data);
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
