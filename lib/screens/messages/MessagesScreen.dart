import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thisjowi/core/appColors.dart';
import 'package:thisjowi/i18n/translationService.dart';
import 'package:thisjowi/services/authService.dart';
import 'package:thisjowi/services/messageService.dart';
import 'package:thisjowi/data/models/message.dart';
import 'package:thisjowi/data/models/user.dart';
import 'package:thisjowi/services/cryptoService.dart';
import 'package:thisjowi/screens/messages/ChatScreen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final MessageService _messageService = MessageService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _ldapUsers = [];
  List<Conversation> _conversations = [];
  bool _isLoading = true;
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

    // Get user email to extract domain
    final email = await _authService.getEmail();
    String? domain;
    if (email != null && email.contains('@')) {
      domain = email.split('@').last;
    }

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
                    child: RefreshIndicator(
                      onRefresh: _loadData,
                      child: _buildUnifiedList(),
                    ),
                  ),
                ],
              ),
            ),
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
