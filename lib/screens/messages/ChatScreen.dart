import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:thisjowi/core/appColors.dart';
import 'package:thisjowi/services/authService.dart';
import 'package:thisjowi/services/messageService.dart';
import 'package:thisjowi/data/models/message.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageService _messageService = MessageService();
  final AuthService _authService = AuthService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = [];
  bool _isLoading = true;
  String? _currentUserId;
  String? _recipientId;
  String _chatTitle = 'Chat';
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null && mounted) {
      // Get recipient from conversation participants
      final recipient = widget.conversation.participants
          .firstWhere((p) => p.id != user.id, orElse: () => widget.conversation.participants.first);
      
      // Get display name from recipient
      final recipientName = recipient.fullName ?? recipient.email;
      
      setState(() {
        _currentUserId = user.id;
        _recipientId = recipient.id;
        _chatTitle = recipientName.isNotEmpty ? recipientName : 'Chat';
      });
      _loadMessages();
      // Start polling for new messages every 3 seconds
      _startPolling();
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollMessages();
    });
  }

  Future<void> _pollMessages() async {
    if (!mounted || _recipientId == null) return;
    
    final result = await _messageService.getMessages(
      widget.conversation.id,
      recipientId: _recipientId,
    );
    
    if (!mounted) return;
    
    if (result['success'] == true) {
      final newMessages = result['data'] as List<Message>;
      // Only update if there are new messages
      if (newMessages.length > _messages.length) {
        setState(() {
          _messages = newMessages;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    final result = await _messageService.getMessages(
      widget.conversation.id,
      recipientId: _recipientId,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _messages = result['data'];
        _isLoading = false;
      });
      _scrollToBottom();
    } else {
      setState(() => _isLoading = false);
      // Ideally show error toast
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    // Get recipient ID from conversation participants
    final recipientId = widget.conversation.participants
        .firstWhere((p) => p.id != _currentUserId, orElse: () => widget.conversation.participants.first)
        .id;

    // Optimistic UI update
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final optimisticMessage = Message(
      id: tempId,
      conversationId: widget.conversation.id,
      senderId: _currentUserId!,
      content: text,
      timestamp: DateTime.now(),
      isRead: false,
    );

    setState(() {
      _messages.add(optimisticMessage);
    });
    _scrollToBottom();

    final result = await _messageService.sendMessage(
      widget.conversation.id, 
      text,
      recipientId: recipientId,
    );

    if (result['success'] == true) {
      final actualMessage = result['data'] as Message;
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          _messages[index] = actualMessage; // Replace optimistic with actual
        }
      });
    } else {
      // Failed, remove optimistic
      setState(() {
        _messages.removeWhere((m) => m.id == tempId);
      });
      // Show error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF1E1E1E).withOpacity(0.9), // Glassmorphism-ish
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const SizedBox.shrink(), // Empty title
        actions: [
          // User name on the right
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                _chatTitle,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Avatar with user initial
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: Text(
                _chatTitle.isNotEmpty ? _chatTitle[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _messages.isEmpty
                    ? Center(
                        child: Text('Start the conversation!',
                            style: TextStyle(
                                color: AppColors.text.withOpacity(0.5))))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.senderId == _currentUserId;
                          final showTail = index == _messages.length - 1 ||
                              _messages[index + 1].senderId != msg.senderId;

                          return _buildMessageBubble(msg, isMe, showTail);
                        },
                      ),
          ),

          // Input Area
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16,
                    24), // account for safe area implicitly or add SafeArea
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E).withOpacity(0.8),
                  border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.1))),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {}, // Attachments
                        icon: const Icon(Icons.add, color: AppColors.primary),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.text.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          child: TextField(
                            controller: _textController,
                            style: const TextStyle(color: AppColors.text),
                            decoration: const InputDecoration(
                              hintText: 'THISMessages',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                            minLines: 1,
                            maxLines: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(Icons.arrow_upward_rounded,
                            color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe, bool showTail) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: showTail ? 12 : 4,
          left: isMe ? 50 : 0,
          right: isMe ? 0 : 50,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
        ),
        child: Text(
          message.content,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
