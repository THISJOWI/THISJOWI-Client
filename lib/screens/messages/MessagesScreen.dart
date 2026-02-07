import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thisjowi/core/appColors.dart';
import 'package:thisjowi/i18n/translationService.dart';
import 'package:thisjowi/services/authService.dart';
import 'package:thisjowi/services/messageService.dart';
import 'package:thisjowi/data/models/message.dart';
import 'package:thisjowi/screens/messages/ChatScreen.dart';
import 'package:thisjowi/components/errorBar.dart';
import 'package:thisjowi/components/button.dart';
import 'package:thisjowi/utils/GlobalActions.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final MessageService _messageService = MessageService();
  final AuthService _authService = AuthService();

  List<Conversation> _conversations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUserId = user?.id;
      });
    }

    final result = await _messageService.getConversations();

    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _conversations = result['data'] as List<Conversation>;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ErrorSnackBar.show(
            context, result['message'] ?? 'Error loading messages');
      }
    }
  }

  List<Conversation> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    return _conversations.where((c) {
      final name = c.participants
              .firstWhere((p) => p.id != _currentUserId,
                  orElse: () => c.participants.first)
              .fullName ??
          'User'; // Fallback
      return name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // -- Header --
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        // Using same header style as Home/OTP
                        // If Home used a local asset logo, we replicate or use icon
                        const Icon(Icons.chat_bubble_outline,
                            color: AppColors.primary, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Messages'.tr(context),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // -- Search Bar --
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E).withOpacity(0.6),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          child: TextField(
                            style: const TextStyle(
                                color: AppColors.text, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Search'.tr(context),
                              hintStyle: TextStyle(
                                  color: AppColors.text.withOpacity(0.5),
                                  fontSize: 16),
                              prefixIcon: Icon(Icons.search,
                                  color: AppColors.text.withOpacity(0.6),
                                  size: 22),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.close,
                                          color:
                                              AppColors.text.withOpacity(0.6),
                                          size: 20),
                                      onPressed: () {
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  // -- Content --
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary))
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: AppColors.primary,
                            child: _filteredConversations.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                                    padding: const EdgeInsets.only(bottom: 150),
                                    itemCount: _filteredConversations.length,
                                    itemBuilder: (context, index) {
                                      final conversation =
                                          _filteredConversations[index];
                                      return _buildConversationItem(
                                          conversation);
                                    },
                                  ),
                          ),
                  ),
                ],
              ),
            ),

            // FAB positioned consistent with Home/OTP
            Positioned(
              bottom: 130.0,
              right: 16.0,
              child: ExpandableActionButton(
                onCreatePassword: () => GlobalActions.createPassword(context),
                onCreateNote: () => GlobalActions.createNote(context),
                onCreateOtp: () => GlobalActions.createOtp(context),
                onCreateMessage: () =>
                    GlobalActions.createMessage(context, onSuccess: _loadData),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 80, color: AppColors.text.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'No messages yet'.tr(context),
            style:
                TextStyle(color: AppColors.text.withOpacity(0.5), fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(Conversation conversation) {
    // Determine the "other" participant
    final otherUser = conversation.participants.firstWhere(
      (u) => u.id != _currentUserId,
      orElse: () => conversation.participants.first,
    );

    // Safely get last message content
    final lastMsg = conversation.lastMessage?.content ?? 'No messages';
    final time = conversation.lastMessage != null
        ? _formatTime(conversation.lastMessage!.timestamp)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E).withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    (otherUser.fullName ?? otherUser.email)
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  otherUser.fullName ?? otherUser.email,
                  style: const TextStyle(
                      color: AppColors.text, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  lastMsg,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.text.withOpacity(0.6)),
                ),
                trailing: Text(
                  time,
                  style: TextStyle(
                      color: AppColors.text.withOpacity(0.4), fontSize: 12),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChatScreen(conversation: conversation),
                    ),
                  ).then((_) => _loadData());
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } else if (diff.inDays < 7) {
      return [
        "Mon",
        "Tue",
        "Wed",
        "Thu",
        "Fri",
        "Sat",
        "Sun"
      ][date.weekday - 1];
    } else {
      return "${date.day}/${date.month}";
    }
  }
}
