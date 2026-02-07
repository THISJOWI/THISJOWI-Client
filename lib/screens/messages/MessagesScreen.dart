import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thisjowi/core/appColors.dart';
import 'package:thisjowi/i18n/translationService.dart';
import 'package:thisjowi/services/authService.dart';
import 'package:thisjowi/services/messageService.dart';
import 'package:thisjowi/services/ldapAuthService.dart';
import 'package:thisjowi/data/models/message.dart';
import 'package:thisjowi/data/models/user.dart';
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
  final LdapAuthService _ldapAuthService = LdapAuthService();

  List<Conversation> _conversations = [];
  List<Map<String, dynamic>> _ldapUsers = [];
  bool _isLoading = true;
  bool _isLdapUser = false;
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

    // Check if user is LDAP and load LDAP users
    final domain = await _ldapAuthService.getCurrentUserDomain();
    if (domain != null) {
      final ldapResult = await _ldapAuthService.getLdapUsersByDomain(domain);
      if (mounted && ldapResult['success'] == true) {
        setState(() {
          _isLdapUser = true;
          _ldapUsers = List<Map<String, dynamic>>.from(ldapResult['users'] ?? []);
          // Remove current user from the list
          _ldapUsers.removeWhere((u) => u['id'].toString() == _currentUserId);
        });
      }
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

  List<Map<String, dynamic>> get _filteredLdapUsers {
    if (_searchQuery.isEmpty) return _ldapUsers;
    return _ldapUsers.where((u) {
      final name = (u['fullName'] ?? u['email'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase());
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
                            child: _isLdapUser
                                ? _buildLdapContent()
                                : _filteredConversations.isEmpty
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

            // FAB positioned consistent with Home/OTP (only for non-LDAP users)
            if (!_isLdapUser)
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

  /// Build content for LDAP users - WhatsApp style combined list
  Widget _buildLdapContent() {
    // Combine LDAP users with their conversations (if any)
    // Users with messages go to the top, sorted by last message time
    final List<Map<String, dynamic>> combinedList = [];
    
    // First, add all LDAP users with their conversation info
    for (final ldapUser in _filteredLdapUsers) {
      final userId = ldapUser['id']?.toString() ?? '';
      
      // Find if this user has a conversation
      final conversation = _conversations.firstWhere(
        (c) => c.participants.any((p) => p.id == userId),
        orElse: () => Conversation(
          id: '',
          participants: [],
          lastMessage: null,
          updatedAt: DateTime.now(),
        ),
      );
      
      combinedList.add({
        'ldapUser': ldapUser,
        'conversation': conversation.id.isNotEmpty ? conversation : null,
        'hasMessages': conversation.id.isNotEmpty && conversation.lastMessage != null,
        'lastMessageTime': conversation.lastMessage?.timestamp ?? DateTime(1970),
      });
    }
    
    // Sort: users with messages first (by time), then others alphabetically
    combinedList.sort((a, b) {
      final aHasMsg = a['hasMessages'] as bool;
      final bHasMsg = b['hasMessages'] as bool;
      
      if (aHasMsg && !bHasMsg) return -1;
      if (!aHasMsg && bHasMsg) return 1;
      
      if (aHasMsg && bHasMsg) {
        // Both have messages, sort by time descending
        final aTime = a['lastMessageTime'] as DateTime;
        final bTime = b['lastMessageTime'] as DateTime;
        return bTime.compareTo(aTime);
      }
      
      // Neither has messages, sort alphabetically
      final aName = (a['ldapUser']['fullName'] ?? a['ldapUser']['email'] ?? '').toString();
      final bName = (b['ldapUser']['fullName'] ?? b['ldapUser']['email'] ?? '').toString();
      return aName.compareTo(bName);
    });
    
    if (combinedList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline,
                  size: 60, color: AppColors.text.withOpacity(0.2)),
              const SizedBox(height: 12),
              Text(
                'No contacts found'.tr(context),
                style: TextStyle(
                    color: AppColors.text.withOpacity(0.5), fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 150, top: 8),
      itemCount: combinedList.length,
      itemBuilder: (context, index) {
        final item = combinedList[index];
        return _buildCombinedUserItem(
          item['ldapUser'] as Map<String, dynamic>,
          item['conversation'] as Conversation?,
        );
      },
    );
  }

  /// Build a combined user item (WhatsApp style)
  Widget _buildCombinedUserItem(Map<String, dynamic> ldapUser, Conversation? conversation) {
    final fullName = ldapUser['fullName'] ?? ldapUser['ldapUsername'] ?? 'User';
    final email = ldapUser['email'] ?? '';
    final hasMessages = conversation != null && conversation.lastMessage != null;
    
    // Get last message info
    final lastMsg = hasMessages ? conversation!.lastMessage!.content : email.toString();
    final time = hasMessages ? _formatTime(conversation!.lastMessage!.timestamp) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
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
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    fullName.toString().isNotEmpty
                        ? fullName.toString().substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  fullName.toString(),
                  style: const TextStyle(
                      color: AppColors.text, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  lastMsg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasMessages 
                        ? AppColors.text.withOpacity(0.7)
                        : AppColors.text.withOpacity(0.5),
                  ),
                ),
                trailing: hasMessages
                    ? Text(
                        time,
                        style: TextStyle(
                            color: AppColors.text.withOpacity(0.4), fontSize: 12),
                      )
                    : Icon(Icons.chat_bubble_outline,
                        color: AppColors.primary.withOpacity(0.5), size: 20),
                onTap: () => _startChatWithUser(ldapUser),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build a single LDAP user item (legacy, kept for compatibility)
  Widget _buildLdapUserItem(Map<String, dynamic> user) {
    final fullName = user['fullName'] ?? user['ldapUsername'] ?? 'User';
    final email = user['email'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
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
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    fullName.toString().isNotEmpty
                        ? fullName.toString().substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  fullName.toString(),
                  style: const TextStyle(
                      color: AppColors.text, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  email.toString(),
                  style: TextStyle(color: AppColors.text.withOpacity(0.6)),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.chat, color: AppColors.primary),
                  onPressed: () => _startChatWithUser(user),
                ),
                onTap: () => _startChatWithUser(user),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Start a chat with an LDAP user
  Future<void> _startChatWithUser(Map<String, dynamic> user) async {
    // Create User object from LDAP data
    final otherUser = User(
      id: user['id']?.toString() ?? '',
      email: user['email'] ?? '',
      fullName: user['fullName'] ?? user['ldapUsername'] ?? user['email'],
      ldapUsername: user['ldapUsername'],
      ldapDomain: user['ldapDomain'],
      isLdapUser: true,
    );
    
    // Get current user
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) return;
    
    // Check if conversation already exists
    final existingConversation = _conversations.firstWhere(
      (c) => c.participants.any((p) => p.id == user['id'].toString()),
      orElse: () => Conversation(
        id: '',
        participants: [],
        lastMessage: null,
        updatedAt: DateTime.now(),
      ),
    );

    if (existingConversation.id.isNotEmpty) {
      // Update participants with full user info and navigate
      final updatedConversation = Conversation(
        id: existingConversation.id,
        participants: [currentUser, otherUser],
        lastMessage: existingConversation.lastMessage,
        unreadCount: existingConversation.unreadCount,
        updatedAt: existingConversation.updatedAt,
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(conversation: updatedConversation),
        ),
      ).then((_) => _loadData());
    } else {
      // Create new conversation with proper participants
      final result = await _messageService.createConversation(user['id'].toString());
      
      if (mounted) {
        if (result['success'] == true) {
          final serverConversation = result['data'] as Conversation;
          
          // Create conversation with full user data
          final newConversation = Conversation(
            id: serverConversation.id,
            participants: [currentUser, otherUser],
            lastMessage: null,
            updatedAt: DateTime.now(),
          );
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(conversation: newConversation),
            ),
          ).then((_) => _loadData());
        } else {
          ErrorSnackBar.show(context, result['message'] ?? 'Error creating chat');
        }
      }
    }
  }

  Widget _buildConversationItem(Conversation conversation) {
    // Determine the "other" participant
    final otherUser = conversation.participants.firstWhere(
      (u) => u.id != _currentUserId,
      orElse: () => conversation.participants.first,
    );

    // Try to find the user in LDAP users list to get their full name
    final ldapUser = _ldapUsers.firstWhere(
      (u) => u['id']?.toString() == otherUser.id,
      orElse: () => <String, dynamic>{},
    );
    
    final displayName = ldapUser['fullName']?.toString() ?? 
                        ldapUser['ldapUsername']?.toString() ??
                        otherUser.fullName ?? 
                        otherUser.email;
    
    final displayInitial = displayName.isNotEmpty ? displayName.substring(0, 1) : '?';

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
                    displayInitial.toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  displayName.isNotEmpty ? displayName : 'User ${otherUser.id}',
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
                  // Update conversation participants with LDAP info before navigating
                  final updatedConversation = Conversation(
                    id: conversation.id,
                    participants: conversation.participants.map((p) {
                      if (p.id == otherUser.id && displayName.isNotEmpty) {
                        return User(
                          id: p.id,
                          email: ldapUser['email']?.toString() ?? p.email,
                          fullName: displayName,
                        );
                      }
                      return p;
                    }).toList(),
                    lastMessage: conversation.lastMessage,
                    unreadCount: conversation.unreadCount,
                    updatedAt: conversation.updatedAt,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChatScreen(conversation: updatedConversation),
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
