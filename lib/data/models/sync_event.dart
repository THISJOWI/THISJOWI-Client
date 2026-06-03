/// Represents a synchronization event received from the SSE stream.
/// Contains enough metadata for the UI to react, but NOT sensitive content.
class SyncEvent {
  final String eventId;
  final String userId;
  final String serviceName;  // password | note | otp | message | profile | account
  final String action;       // created | updated | deleted
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  const SyncEvent({
    required this.eventId,
    required this.userId,
    required this.serviceName,
    required this.action,
    required this.payload,
    required this.timestamp,
  });

  factory SyncEvent.fromJson(Map<String, dynamic> json) {
    return SyncEvent(
      eventId: json['eventId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      serviceName: json['serviceName']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      payload: json['payload'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : <String, dynamic>{},
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'userId': userId,
      'serviceName': serviceName,
      'action': action,
      'payload': payload,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() {
    return 'SyncEvent(serviceName: $serviceName, action: $action, eventId: $eventId)';
  }
}
