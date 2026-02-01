import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/services/authService.dart';
import 'package:thisjowi/data/models/message.dart';

class MessageService {
  final AuthService _authService = AuthService();

  String get baseUrl => ApiConfig.messagesUrl;

  Future<Map<String, dynamic>> getConversations() async {
    try {
      final token = await _authService.getToken();
      if (token == null)
        return {'success': false, 'message': 'Not authenticated'};

      final uri = Uri.parse('$baseUrl/conversations');
      final res = await http
          .get(
            uri,
            headers: ApiConfig.authHeaders(token),
          )
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> data = (body is List) ? body : (body['data'] ?? []);
        final conversations =
            data.map((json) => Conversation.fromJson(json)).toList();
        return {'success': true, 'data': conversations};
      }

      return {'success': false, 'message': 'Failed to load conversations'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getMessages(String conversationId) async {
    try {
      final token = await _authService.getToken();
      if (token == null)
        return {'success': false, 'message': 'Not authenticated'};

      // Backend route: GET /api/v1/messages/:conversationId
      final uri = Uri.parse('$baseUrl/$conversationId');
      final res = await http
          .get(
            uri,
            headers: ApiConfig.authHeaders(token),
          )
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> data = (body is List) ? body : (body['data'] ?? []);
        final messages = data.map((json) => Message.fromJson(json)).toList();
        return {'success': true, 'data': messages};
      }

      return {'success': false, 'message': 'Failed to load messages'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendMessage(
      String conversationId, String content) async {
    try {
      final token = await _authService.getToken();
      if (token == null)
        return {'success': false, 'message': 'Not authenticated'};

      final user = await _authService.getCurrentUser();
      if (user?.id == null) {
        return {'success': false, 'message': 'User ID not found'};
      }

      // Backend route: POST /api/v1/messages
      final uri = Uri.parse('$baseUrl');

      final payload = {
        'senderId': user!.id,
        'conversationId': conversationId,
        'content': content,
      };

      final res = await http
          .post(
            uri,
            headers: ApiConfig.authHeaders(token),
            body: jsonEncode(payload),
          )
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        // Backend creates message and returns it.
        // Check if wrapped in data
        final msgData =
            (body is Map && body.containsKey('data')) ? body['data'] : body;
        final message = Message.fromJson(msgData);
        return {'success': true, 'data': message};
      }

      return {
        'success': false,
        'message': 'Failed to send message: ${res.statusCode}'
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
