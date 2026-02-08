import 'package:thisjowi/data/models/user.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String? recipientId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final bool isEncrypted;
  final String? ephemeralPublicKey;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.recipientId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.isEncrypted = false,
    this.ephemeralPublicKey,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? json['_id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      recipientId: json['recipientId'],
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      isEncrypted: json['isEncrypted'] ?? false,
      ephemeralPublicKey: json['ephemeralPublicKey'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'recipientId': recipientId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'isEncrypted': isEncrypted,
      'ephemeralPublicKey': ephemeralPublicKey,
    };
  }
}

class Conversation {
  final String id;
  final List<User> participants;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    var participantsList = <User>[];
    if (json['participants'] != null) {
      participantsList =
          (json['participants'] as List).map((p) => User.fromJson(p)).toList();
    }

    return Conversation(
      id: json['id'] ?? json['_id'] ?? '',
      participants: participantsList,
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  String getTitle(String currentUserId) {
    // Return the name of the other participant
    final other = participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => User(email: 'Unknown'),
    );
    return other.fullName ?? other.email;
  }
}
