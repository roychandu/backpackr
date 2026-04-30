// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../common_widgets/app_colors.dart';
import '../../common_widgets/app_text_styles.dart';
import '../../common_widgets/app_text_styles.dart';
import '../../common_widgets/app_header.dart';
import '../../common_widgets/custom_button.dart';
import '../../models/conversation.dart';
import '../../services/chat_service.dart';
import '../../services/user_setup_service.dart';
import 'conversation_screen.dart';
import 'create_group_screen.dart';
import 'suggest_meetup_bottom_sheet.dart';
import 'dart:math' as math;

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.text3.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.text3.withOpacity(0.87),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _actionTile(
                          Icons.send_rounded,
                          'Suggest Meetup',
                          _showSuggestMeetupSheet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionTile(
                          Icons.group_add_rounded,
                          'Create Group',
                          _showCreateGroupSheet,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Recent Chats',
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.text1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_currentUserId == null)
                    _buildNotLoggedInState()
                  else
                    _buildConversationsList(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const AppHeader(
      title: 'Messages',
      subtitle: 'Stay connected with fellow travelers',
      fontSize: 32,
    );
  }

  Widget _buildNotLoggedInState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.highlight, AppColors.cta1],
                ),
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.highlight.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(Icons.message, color: AppColors.text1, size: 50),
            ),
            const SizedBox(height: 24),
            Text(
              'Please log in to start chatting',
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.text1,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sign in to your account to access\nchat features',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.text1.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsList() {
    return StreamBuilder<List<Conversation>>(
      stream: _chatService.getConversations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final conversations = snapshot.data ?? [];

        if (conversations.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: conversations
              .map((c) => _buildConversationCard(c))
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.highlight),
          const SizedBox(height: 24),
          Text(
            'Loading conversations...',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.text1.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.error, AppColors.error],
                ),
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(Icons.error, color: AppColors.text1, size: 50),
            ),
            const SizedBox(height: 24),
            Text(
              'Error loading conversations',
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.text1,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.text1.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Retry',
              backgroundColor: AppColors.highlight,
              textColor: AppColors.text3,
              borderRadius: 25,
              onPressed: () {
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final imageSize = math.min(screenWidth, screenHeight) * 0.4;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: imageSize,
              height: imageSize,
              child: Image.asset('assets/chat-empty.png', fit: BoxFit.contain),
            ),
            Text(
              'No conversations yet!',
              textAlign: TextAlign.center,
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.text1,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Connect with fellow travelers and\ncreate group chats',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.text1.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomButton(
                  text: 'Create Group',
                  backgroundColor: AppColors.primary,
                  icon: Icons.group_add_rounded,
                  borderRadius: 25,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  onPressed: _showCreateGroupSheet,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationCard(Conversation conversation) {
    final displayName = conversation.getDisplayName(_currentUserId!);
    final hasUnread = conversation.hasUnreadMessages(_currentUserId!);
    final unreadCount = conversation.getUnreadCount(_currentUserId!);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.text3.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: () => _navigateToConversation(conversation),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary,
              child: Icon(
                conversation.isGroup ? Icons.group_rounded : Icons.person,
                color: AppColors.text1,
                size: conversation.isGroup ? 24 : 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.text3.withOpacity(0.87),
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(conversation.lastMessageTimestamp),
                        style: TextStyle(
                          color: AppColors.text3.withOpacity(0.45),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (conversation.isGroup) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${conversation.participantCount} participants',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessageContent,
                          style: TextStyle(
                            color: AppColors.text3.withOpacity(0.54),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.highlight2,
                          child: Text(
                            unreadCount.toString(),
                            style: TextStyle(
                              color: AppColors.text1,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dateTime.day}/${dateTime.month}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Now';
    }
  }

  void _navigateToConversation(Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationScreen(conversation: conversation),
      ),
    );
  }

  Future<void> _showSuggestMeetupSheet() async {
    // Check if user has completed profile setup
    if (!await _checkProfileSetup()) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) =>
            const SuggestMeetupBottomSheet(),
      ),
    );
  }

  Future<void> _showCreateGroupSheet() async {
    // Check if user has completed profile setup
    if (!await _checkProfileSetup()) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateGroupScreen(),
    );
  }

  /// Check if user has completed profile setup
  Future<bool> _checkProfileSetup() async {
    final hasCompleted = await UserSetupService.hasCompletedSetup();
    if (!hasCompleted) {
      if (!mounted) return false;

      // Use the existing SetupReminderPopup
      await UserSetupService.showSetupPopup(context);
      return false;
    }
    return true;
  }
}
