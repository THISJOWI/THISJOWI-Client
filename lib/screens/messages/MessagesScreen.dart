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
<<<<<<< HEAD
=======
import 'package:thisjowi/services/cryptoService.dart';
>>>>>>> master
import 'package:thisjowi/screens/messages/ChatScreen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final MessageService _messageService = MessageService();
  final AuthService _authService = AuthService();
  final LdapAuthService _ldapAuthService = LdapAuthService();

  List<Map<String, dynamic>> _ldapUsers = [];
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
    _initializeCrypto();
  }

  Future<void> _initializeCrypto() async {
    final crypto = CryptoService();
    await crypto.initKeys();
    print('🔐 Crypto initialized for messaging');
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final currentUser = await _authService.getCurrentUser();
    _currentUserId = currentUser?.id;

    // Fetch Conversations
    final convResult = await _messageService.getConversations();
    if (mounted && convResult['success'] == true) {
      setState(() {
        _conversations = List<Conversation>.from(convResult['data']);
      });
    }

<<<<<<< HEAD
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
=======
    // Get user email to extract domain
    final email = await _authService.getEmail();
    String? domain;
    if (email != null && email.contains('@')) {
      domain = email.split('@').last;
    }
>>>>>>> master

    if (domain != null) {
      final ldapResult = await _messageService.getLdapUsers(domain);
      if (mounted) {
        if (ldapResult['success'] == true && ldapResult['data'] is List) {
          final allUsers = List<Map<String, dynamic>>.from(ldapResult['data']);
          final filteredUsers = allUsers
              .where((u) => u['id']?.toString() != currentUser?.id?.toString())
              .toList();
          setState(() {
            _ldapUsers = filteredUsers;
            _isLoading = false;
          });
          return;
        }
      }
    }

    setState(() => _isLoading = false);
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

                  // -- Unified WhatsApp-style List --
                  Expanded(
<<<<<<< HEAD
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
=======
                    child: RefreshIndicator(
                      onRefresh: _loadData,
                      child: _buildUnifiedList(),
                    ),
>>>>>>> master
                  ),
                ],
              ),
            ),
<<<<<<< HEAD

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
=======
>>>>>>> master
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedList() {
    // 1. Create a map of LDAP users for easy lookup by ID
    final Map<String, dynamic> userMap = {
      for (var u in _ldapUsers) u['id']?.toString() ?? '': u
    };

    // 2. Filter recent conversations
    final recentConvs = _conversations.where((conv) {
      if (_searchQuery.isEmpty) return true;
      final title = conv.getTitle(_currentUserId ?? '').toLowerCase();

      final otherParticipant = conv.participants.firstWhere(
        (p) => p.id != _currentUserId,
        orElse: () => User(id: '', email: ''),
      );

      final ldap = userMap[otherParticipant.id];
      final ldapName = (ldap?['fullName']?.toString() ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();

      return title.contains(query) || ldapName.contains(query);
    }).toList();

    // Sort recent by date
    recentConvs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // 3. Filter other contacts
    final filteredContacts = _ldapUsers.where((user) {
      final String name = (user['fullName']?.toString() ?? '').toLowerCase();
      final String email = (user['email']?.toString() ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();

    // Sort contacts alphabetically
    filteredContacts.sort((a, b) {
      final String nameA = (a['fullName']?.toString() ?? '').toLowerCase();
      final String nameB = (b['fullName']?.toString() ?? '').toLowerCase();
      return nameA.compareTo(nameB);
    });

    // 4. Build items for the list
    final List<dynamic> listItems = [];

    // Add search-filtered conversations
    if (recentConvs.isNotEmpty) {
      listItems.add('Conversaciones');
      listItems.addAll(recentConvs);
    }

    // Add search-filtered contacts (only those that are NOT in active conversations)
    final Set<String?> activeIds =
        recentConvs.expand((c) => c.participants.map((p) => p.id)).toSet();
    final List<dynamic> otherContacts = filteredContacts
        .where((u) => !activeIds.contains(u['id']?.toString()))
        .toList();

    if (otherContacts.isNotEmpty) {
      listItems.add('Encuentra a alguien');
      listItems.addAll(otherContacts);
    }

    if (!_isLoading && listItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64, color: AppColors.text.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'No encontramos resultados'.tr(context),
              style: TextStyle(color: AppColors.text.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: listItems.length,
      itemBuilder: (context, index) {
        final item = listItems[index];

        if (item is String) {
          // It's a header
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
            child: Text(
              item.toUpperCase().tr(context),
              style: TextStyle(
                color: AppColors.primary.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          );
        }

        if (item is Conversation) {
          final otherId = item.participants
              .firstWhere((p) => p.id != _currentUserId,
                  orElse: () => User(id: '', email: ''))
              .id;
          return _buildConversationItem(
            item,
            _currentUserId ?? '',
            ldapData: userMap[otherId],
          );
        }

        // It's a contact (LDAP User map)
        final contact = item as Map<String, dynamic>;
        final String name = contact['fullName']?.toString() ??
            contact['email']?.toString() ??
            'Unknown';

        return _buildConversationItem(
          Conversation(
            id: 'new',
            participants: [
              User.fromJson({
                'id': contact['id'],
                'email': contact['email'],
                'fullName': name,
              })
            ],
            updatedAt: DateTime.now(),
          ),
          _currentUserId ?? '',
          ldapData: contact,
        );
      },
    );
  }

<<<<<<< HEAD
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
=======
  Widget _buildConversationItem(Conversation conv, String currentUserId,
      {Map<String, dynamic>? ldapData}) {
    // Use LDAP name if available, otherwise fallback to conversation title
    String title = conv.getTitle(currentUserId);
    if (ldapData != null) {
      title = ldapData['fullName']?.toString() ??
          ldapData['ldapUsername']?.toString() ??
          ldapData['email']?.toString() ??
          title;
    }

    final String lastMsg = conv.lastMessage?.content ?? 'No messages';
    final String initial = (title.isNotEmpty ? title[0] : '?').toUpperCase();
    final bool isUnread = conv.unreadCount > 0;
    final bool isEncrypted = conv.lastMessage?.isEncrypted ?? false;
>>>>>>> master

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isUnread
                  ? AppColors.primary.withOpacity(0.15)
                  : const Color(0xFF1E1E1E).withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isUnread
                      ? AppColors.primary.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1)),
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
<<<<<<< HEAD
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
=======
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        conversation: conv,
                        title: title,
                      ),
>>>>>>> master
                    ),
                  );
                  _loadData();
                },
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isEncrypted)
                      Icon(Icons.lock_outline_rounded,
                          size: 14, color: Colors.white.withOpacity(0.3)),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    lastMsg,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isUnread
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ),
                trailing: isUnread
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.white.withOpacity(0.2),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
