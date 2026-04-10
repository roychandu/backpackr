import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../common_widgets/app_colors.dart';
import '../../common_widgets/app_text_styles.dart';
import '../../services/chat_service.dart';
import '../../utils/error_handler.dart';
import 'conversation_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _groupNameController = TextEditingController();
  final Set<String> _selectedParticipants = {};
  List<Map<String, String>> _mutualConnections = [];
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadMutualConnections();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _loadMutualConnections() async {
    setState(() => _isLoading = true);
    try {
      final connections = await _chatService.getMutualConnections();
      setState(() {
        _mutualConnections = connections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Please enter a group name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedParticipants.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Please select at least 2 participants'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Build participant names map
      final participantNames = <String, String>{};
      for (final participantId in _selectedParticipants) {
        final connection = _mutualConnections.firstWhere(
          (c) => c['id'] == participantId,
        );
        participantNames[participantId] = connection['name']!;
      }

      final groupId = await _chatService.createGroupChat(
        groupName: groupName,
        participantIds: _selectedParticipants.toList(),
        participantNames: participantNames,
      );

      if (!mounted) return;

      // Get the created group conversation
      final conversations = await _chatService.getConversations().first;
      final conversation = conversations.firstWhere((c) => c.id == groupId);

      // Navigate to the group chat
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ConversationScreen(conversation: conversation),
        ),
      );
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Create Group Chat',
          style: AppTextStyles.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.95),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),

                // Group name input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: TextField(
                          controller: _groupNameController,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Group name',
                            hintStyle: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.5),
                            ),
                            prefixIcon: Icon(
                              Icons.people_rounded,
                              color: AppColors.primary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Selected count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Select participants',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selectedParticipants.length} selected',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Mutual connections list
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : _mutualConnections.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _mutualConnections.length,
                          itemBuilder: (context, index) {
                            final connection = _mutualConnections[index];
                            final userId = connection['id']!;
                            final userName = connection['name']!;
                            final isSelected = _selectedParticipants.contains(
                              userId,
                            );

                            return _buildConnectionTile(
                              userId: userId,
                              userName: userName,
                              isSelected: isSelected,
                            );
                          },
                        ),
                ),

                // Create button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isCreating ? null : _createGroup,
                      icon: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(_isCreating ? 'Creating...' : 'Create Group'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionTile({
    required String userId,
    required String userName,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isSelected ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedParticipants.add(userId);
            } else {
              _selectedParticipants.remove(userId);
            }
          });
        },
        title: Text(
          userName,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Mutual connection',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white60),
        ),
        secondary: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withOpacity(0.2),
          child: Icon(Icons.person, color: AppColors.primary, size: 20),
        ),
        activeColor: AppColors.primary,
        checkColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Icon(
                Icons.people_outline_rounded,
                color: Colors.white70,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No mutual connections yet',
              style: AppTextStyles.h4.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect with travelers by sending waves first',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
