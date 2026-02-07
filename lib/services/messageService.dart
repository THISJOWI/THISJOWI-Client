import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/core/encryptionHelper.dart';
import 'package:thisjowi/services/authService.dart';
import 'package:thisjowi/data/models/message.dart';

class MessageService {
  final AuthService _authService = AuthService();

  String get baseUrl => ApiConfig.messagesUrl;

  Future<Map<String, dynamic>> getConversations() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

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
        // Decrypt lastMessage content in conversations
        final conversations = data.map((json) {
          final conv = Conversation.fromJson(json);
          if (conv.lastMessage != null) {
            return Conversation(
              id: conv.id,
              participants: conv.participants,
              lastMessage: Message(
                id: conv.lastMessage!.id,
                conversationId: conv.lastMessage!.conversationId,
                senderId: conv.lastMessage!.senderId,
                content: EncryptionHelper.decrypt(conv.lastMessage!.content),
                timestamp: conv.lastMessage!.timestamp,
                isRead: conv.lastMessage!.isRead,
              ),
              unreadCount: conv.unreadCount,
              updatedAt: conv.updatedAt,
            );
          }
          return conv;
        }).toList();
        return {'success': true, 'data': conversations};
      }

      return {'success': false, 'message': 'Failed to load conversations'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getMessages(String conversationId, {String? recipientId}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      // Use between endpoint if recipientId is provided, otherwise use conversationId
      final uri = recipientId != null 
          ? Uri.parse('$baseUrl/between/$recipientId')
          : Uri.parse('$baseUrl/$conversationId');
          
      final res = await http
          .get(
            uri,
            headers: ApiConfig.authHeaders(token),
          )
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> data = (body is List) ? body : (body['data'] ?? []);
        // Decrypt messages on receive
        final messages = data.map((json) {
          final msg = Message.fromJson(json);
          // Decrypt content
          return Message(
            id: msg.id,
            conversationId: msg.conversationId,
            senderId: msg.senderId,
            content: EncryptionHelper.decrypt(msg.content),
            timestamp: msg.timestamp,
            isRead: msg.isRead,
          );
        }).toList();
        return {'success': true, 'data': messages};
      }

      return {'success': false, 'message': 'Failed to load messages'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendMessage(
      String conversationId, String content, {String? recipientId}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final user = await _authService.getCurrentUser();
      if (user?.id == null) {
        return {'success': false, 'message': 'User ID not found'};
      }

      // Backend route: POST /api/v1/messages
      final uri = Uri.parse(baseUrl);

      // Encrypt message content before sending (E2E encryption)
      final encryptedContent = EncryptionHelper.encrypt(content);

      final payload = {
        'senderId': user!.id,
        'conversationId': conversationId,
        'content': encryptedContent,
        if (recipientId != null) 'recipientId': recipientId,
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
        final msg = Message.fromJson(msgData);
        // Return with decrypted content (what user sees)
        final message = Message(
          id: msg.id,
          conversationId: msg.conversationId,
          senderId: msg.senderId,
          content: content, // Use original unencrypted content
          timestamp: msg.timestamp,
          isRead: msg.isRead,
        );
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

  /// Create a new conversation with another user
  Future<Map<String, dynamic>> createConversation(String otherUserId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final user = await _authService.getCurrentUser();
      if (user?.id == null) {
        return {'success': false, 'message': 'User ID not found'};
      }

      final uri = Uri.parse('$baseUrl/conversations');

      final payload = {
        'participantIds': [user!.id, otherUserId],
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
        final convData =
            (body is Map && body.containsKey('data')) ? body['data'] : body;
        final conversation = Conversation.fromJson(convData);
        return {'success': true, 'data': conversation};
      }

      return {
        'success': false,
        'message': 'Failed to create conversation: ${res.statusCode}'
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
