// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../common_widgets/app_colors.dart';
import '../../common_widgets/app_text_styles.dart';
import '../../services/chat_service.dart';
import '../../models/conversation.dart';
import '../../utils/error_handler.dart';

class AddParticipantScreen extends StatefulWidget {
  final Conversation conversation;

  const AddParticipantScreen({super.key, required this.conversation});

  @override
  State<AddParticipantScreen> createState() => _AddParticipantScreenState();
}

class _AddParticipantScreenState extends State<AddParticipantScreen> {
  final ChatService _chatService = ChatService();
  final Set<String> _selectedParticipants = {};
  List<Map<String, String>> _availableConnections = [];
  bool _isLoading = true;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableConnections();
  }

  Future<void> _loadAvailableConnections() async {
    setState(() => _isLoading = true);
    try {
      final allConnections = await _chatService.getMutualConnections();

      // Filter out users who are already in the group
      final available = allConnections.where((connection) {
        final userId = connection['id']!;
        return !widget.conversation.participants.containsKey(userId);
      }).toList();

      setState(() {
        _availableConnections = available;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _addSelectedParticipants() async {
    if (_selectedParticipants.isEmpty) {
      ErrorHandler.showWarningSnackBar(
        context,
        'Please select at least one participant',
      );
      return;
    }

    setState(() => _isAdding = true);

    try {
      // Add each selected participant
      for (final participantId in _selectedParticipants) {
        final connection = _availableConnections.firstWhere(
          (c) => c['id'] == participantId,
        );
        final participantName = connection['name']!;

        await _chatService.addParticipantToGroup(
          conversationId: widget.conversation.id,
          participantId: participantId,
          participantName: participantName,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true); // Return true to indicate success
      ErrorHandler.showSuccessSnackBar(
        context,
        'Added ${_selectedParticipants.length} participant(s) to the group',
      );
    } catch (e) {
      setState(() => _isAdding = false);
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border.all(color: AppColors.text1.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.text1.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.person_add_rounded,
                            color: AppColors.text1,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Participants',
                                style: AppTextStyles.h4.copyWith(
                                  color: AppColors.text1,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.conversation.groupName ?? 'Group',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.text1.withOpacity(0.60),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppColors.text1.withOpacity(0.70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selected count
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          'Select from mutual connections',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.text1.withOpacity(0.70),
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
                              color: AppColors.text1,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Available connections list
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                        : _availableConnections.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _availableConnections.length,
                            itemBuilder: (context, index) {
                              final connection = _availableConnections[index];
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

                  // Add button
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      border: Border(
                        top: BorderSide(
                          color: AppColors.text1.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isAdding ? null : _addSelectedParticipants,
                        icon: _isAdding
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.text1,
                                ),
                              )
                            : const Icon(Icons.person_add_rounded),
                        label: Text(_isAdding ? 'Adding...' : 'Add to Group'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.text1,
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
        );
      },
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
        color: AppColors.text1.withOpacity(isSelected ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.text1.withOpacity(0.1),
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
            color: AppColors.text1,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Mutual connection',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.text1.withOpacity(0.60),
          ),
        ),
        secondary: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withOpacity(0.2),
          child: Icon(Icons.person, color: AppColors.primary, size: 20),
        ),
        activeColor: AppColors.primary,
        checkColor: AppColors.text1,
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
                color: AppColors.text1.withOpacity(0.06),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColors.text1.withOpacity(0.15)),
              ),
              child: Icon(
                Icons.person_add_disabled_rounded,
                color: AppColors.text1.withOpacity(0.70),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'All connections already added',
              style: AppTextStyles.h4.copyWith(
                color: AppColors.text1,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All your mutual connections are already in this group',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.text1.withOpacity(0.70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
