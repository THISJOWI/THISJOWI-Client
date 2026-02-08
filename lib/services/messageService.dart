import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/services/authService.dart';
import 'package:thisjowi/services/cryptoService.dart';
import 'package:thisjowi/data/models/message.dart';

class MessageService {
  final AuthService _authService = AuthService();
  final CryptoService _cryptoService = CryptoService();

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

        if (body is Map) {
          final data = body['data'] ?? [];
          if (data is List && body['success'] == true) {
            final conversations = <Conversation>[];
            for (var json in data) {
              final conv = Conversation.fromJson(json);
              // Decrypt last message if needed
              if (conv.lastMessage != null && conv.lastMessage!.isEncrypted) {
                final decrypted = await _cryptoService.decryptMessage(
                  conv.lastMessage!.content,
                  conv.lastMessage!.ephemeralPublicKey ?? '',
                );
                if (decrypted != null) {
                  // We need to create a new message with decrypted content since Message is immutable
                  final decryptedMsg = Message(
                    id: conv.lastMessage!.id,
                    conversationId: conv.lastMessage!.conversationId,
                    senderId: conv.lastMessage!.senderId,
                    content: decrypted,
                    timestamp: conv.lastMessage!.timestamp,
                    isRead: conv.lastMessage!.isRead,
                    isEncrypted: true,
                    ephemeralPublicKey: conv.lastMessage!.ephemeralPublicKey,
                  );
                  conversations.add(Conversation(
                    id: conv.id,
                    participants: conv.participants,
                    lastMessage: decryptedMsg,
                    unreadCount: conv.unreadCount,
                    updatedAt: conv.updatedAt,
                  ));
                  continue;
                }
              }
              conversations.add(conv);
            }
            return {'success': true, 'data': conversations};
          }
        }
      }

      return {'success': false, 'message': 'Failed to load conversations'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getMessages(String conversationId,
      {String? recipientId}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final url = (conversationId == 'new' && recipientId != null)
          ? '$baseUrl/between/$recipientId'
          : '$baseUrl/$conversationId';
      final uri = Uri.parse(url);
      final res = await http
          .get(
            uri,
            headers: ApiConfig.authHeaders(token),
          )
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> data = (body is List) ? body : (body['data'] ?? []);

        final currentUser = await _authService.getCurrentUser();
        final currentUserId = currentUser?.id;

        // Pre-fetch recipient public key if needed (for decrypting our OWN sent messages)
        String? recipientPubKey;
        if (data.isNotEmpty && recipientId != null) {
          recipientPubKey =
              await _cryptoService.fetchRecipientPublicKey(recipientId);
        }

        final messages = <Message>[];
        for (var json in data) {
          final msg = Message.fromJson(json);
          if (msg.isEncrypted) {
            String? decrypted;

            // Try decrypting. If we are the sender, we need the RECIPIENT'S public key.
            // If we are the recipient, we need the SENDER'S public key (which is msg.ephemeralPublicKey).
            final isMeSender = msg.senderId == currentUserId;
            final keyToUse =
                isMeSender ? recipientPubKey : msg.ephemeralPublicKey;

            if (keyToUse != null) {
              decrypted =
                  await _cryptoService.decryptMessage(msg.content, keyToUse);
            }

            if (decrypted != null) {
              messages.add(Message(
                id: msg.id,
                conversationId: msg.conversationId,
                senderId: msg.senderId,
                content: decrypted,
                timestamp: msg.timestamp,
                isRead: msg.isRead,
                isEncrypted: true,
                ephemeralPublicKey: msg.ephemeralPublicKey,
              ));
              continue;
            }
          }
          messages.add(msg);
        }
        return {'success': true, 'data': messages};
      }

      return {'success': false, 'message': 'Failed to load messages'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getLdapUsers(String domain) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated', 'data': []};
      }

      final uri = Uri.parse('$baseUrl/ldap-users/$domain');
      final res = await http
          .get(
            uri,
            headers: ApiConfig.authHeaders(token),
          )
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map) {
          final data = body['data'] ?? [];
          if (body['success'] == true && data is List) {
            return {'success': true, 'data': data};
          }
        }
      }
      return {
        'success': false,
        'message': 'Failed to load LDAP users',
        'data': []
      };
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'data': []};
    }
  }

  Future<Map<String, dynamic>> sendMessage(
      String conversationId, String content,
      {String? recipientId}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final user = await _authService.getCurrentUser();
      if (user?.id == null) {
        return {'success': false, 'message': 'User ID not found'};
      }

      final payload = {
        'senderId': user!.id,
        'conversationId': conversationId,
        'content': content,
        'isEncrypted': false,
      };

      if (recipientId != null) {
        payload['recipientId'] = recipientId;

        // Try E2EE
        print('🔍 Attempting E2EE for recipient: $recipientId');
        final recipientPubKey =
            await _cryptoService.fetchRecipientPublicKey(recipientId);

        if (recipientPubKey != null && recipientPubKey.isNotEmpty) {
          print('✅ Public key found, encrypting...');
          final encryptedData =
              await _cryptoService.encryptMessage(content, recipientPubKey);
          if (encryptedData != null) {
            payload['content'] = encryptedData['encryptedContent']!;
            payload['ephemeralPublicKey'] =
                encryptedData['ephemeralPublicKey']!;
            payload['isEncrypted'] = true;
            print('🔐 MESSAGE ENCRYPTED SUCCESSFULLY');
          } else {
            print('❌ Encryption algorithm failed, sending cleartext');
          }
        } else {
          print(
              '⚠️ No public key found for $recipientId on server. Sending cleartext.');
          print(
              '💡 Tip: Recipient needs to log in with the updated app to upload their key.');
        }
      }

      final res = await http
          .post(
            Uri.parse(baseUrl),
            headers: ApiConfig.authHeaders(token),
            body: jsonEncode(payload),
          )
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        final msgData =
            (body is Map && body.containsKey('data')) ? body['data'] : body;
        final message = Message.fromJson(msgData);

        // If we sent it encrypted, we know the content we sent was 'content' (decrypted)
        // The backend returns the encrypted version. Let's return the decrypted version to UI.
        if (message.isEncrypted) {
          return {
            'success': true,
            'data': Message(
              id: message.id,
              conversationId: message.conversationId,
              senderId: message.senderId,
              content: content, // Use original plain text
              timestamp: message.timestamp,
              isRead: message.isRead,
              isEncrypted: true,
              ephemeralPublicKey: message.ephemeralPublicKey,
            )
          };
        }

        return {'success': true, 'data': message};
      }

      return {'success': false, 'message': 'Failed to send message'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> markAsRead(String conversationId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return {'success': false};

      final res = await http.put(
        Uri.parse('$baseUrl/$conversationId/read'),
        headers: ApiConfig.authHeaders(token),
      );

      return {'success': res.statusCode == 200};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteMessage(String messageId,
      {bool forEveryone = true}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return {'success': false};

      final res = await http.delete(
        Uri.parse(
            '$baseUrl/$messageId?type=${forEveryone ? 'everyone' : 'me'}'),
        headers: ApiConfig.authHeaders(token),
      );

      return {'success': res.statusCode == 200};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
