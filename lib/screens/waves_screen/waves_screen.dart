// ignore_for_file: unnecessary_to_list_in_spreads, avoid_unnecessary_containers, use_build_context_synchronously, deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../../common_widgets/app_colors.dart';
import '../../common_widgets/app_text_styles.dart';
import '../../common_widgets/app_header.dart';
import '../../common_widgets/sliver_tab_delegate.dart';
import '../../models/wave.dart';
import '../../services/wave_service.dart';
import '../../services/chat_service.dart';
import '../../utils/error_handler.dart';
import '../chat_screens/conversation_screen.dart';
import '../traveling_blogs_screen/other_travelers_blog_screen.dart';

class WavesScreen extends StatefulWidget {
  const WavesScreen({super.key});

  @override
  State<WavesScreen> createState() => _WavesScreenState();
}

class _WavesScreenState extends State<WavesScreen>
    with SingleTickerProviderStateMixin {
  final WaveService _waveService = WaveService();
  final ChatService _chatService = ChatService();
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isOpeningChat = false;

  // Wave data
  List<Wave> _mutualConnections = [];
  List<Wave> _receivedWaves = [];
  List<Wave> _sentWaves = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadWaves();
  }

  Future<void> _loadWaves() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final wavesByType = await _waveService.getWavesByType();

      final receivedWaves = wavesByType[WaveType.received] ?? [];

      // Debug: Check for duplicates
      final receivedIds = receivedWaves.map((w) => w.id).toList();
      final uniqueReceivedIds = receivedIds.toSet();
      if (receivedIds.length != uniqueReceivedIds.length) {
        print('WARNING: Duplicate received wave IDs detected!');
        print(
          'Total waves: ${receivedIds.length}, Unique: ${uniqueReceivedIds.length}',
        );
        print('IDs: $receivedIds');
      } else {
        print('No duplicates in received waves. Count: ${receivedIds.length}');
      }

      setState(() {
        _mutualConnections = wavesByType[WaveType.mutual] ?? [];
        _receivedWaves = receivedWaves;
        _sentWaves = wavesByType[WaveType.sent] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load waves: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _acceptWave(Wave wave) async {
    try {
      await _waveService.acceptWave(wave.id);
      await _loadWaves(); // Refresh the list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Wave accepted! You can now chat with ${wave.senderName}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _ignoreWave(Wave wave) async {
    try {
      await _waveService.ignoreWave(wave.id);
      await _loadWaves(); // Refresh the list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wave ignored'),
            backgroundColor: AppColors.cta1,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _deleteWave(Wave wave) async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.text1.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.text1.withOpacity(0.18)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.text3.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delete Wave',
                    style: TextStyle(
                      color: AppColors.text1,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to delete the wave sent to ${wave.receiverName}?',
                    style: TextStyle(
                      color: AppColors.text1.withOpacity(0.70),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.text1.withOpacity(0.70),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(
                          'Delete',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // If user didn't confirm, return early
    if (confirmed != true) return;

    try {
      await _waveService.deleteWave(wave.id);
      await _loadWaves(); // Refresh the list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wave deleted successfully'),
            backgroundColor: AppColors.info,
          ),
        );

        // Notify parent widget (TravelersScreen) to refresh wave status
        _notifyTravelersScreenRefresh();
      }
    } catch (e) {
      print('Failed to delete wave: ${e.toString()}');
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  /// Notify TravelersScreen to refresh wave status tracking
  void _notifyTravelersScreenRefresh() {
    // Use a callback or event system to notify parent
    // For now, we'll use a simple approach by triggering a rebuild
    // In a more complex app, you might use Provider, Riverpod, or EventBus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This will be handled by the parent widget if needed
    });
  }

  Future<void> _startChat(Wave wave) async {
    if (_isOpeningChat) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Opening chat... Please wait'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }
    _isOpeningChat = true;
    try {
      final conversationId = await _chatService.createConversation(
        otherUserId: wave.receiverId == _waveService.currentUserId
            ? wave.senderId
            : wave.receiverId,
        otherUserName: wave.receiverId == _waveService.currentUserId
            ? wave.senderName
            : wave.receiverName,
      );

      if (!mounted) return;

      // Get the conversation object from the service
      final conversations = await _chatService.getConversations().first;
      final conversation = conversations.firstWhere(
        (c) => c.id == conversationId,
        orElse: () => throw Exception('Conversation not found'),
      );

      // Navigate to conversation screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConversationScreen(conversation: conversation),
        ),
      );
    } catch (e) {
      print('Failed to start chat: ${e.toString()}');
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      _isOpeningChat = false;
    }
  }

  void _openTravelerBlogs({
    required String userId,
    required String userName,
    String? currentLocation,
    String? avatarUrl,
    List<String>? destinations,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherTravelersBlogScreen(
          userId: userId,
          userName: userName,
          currentLocation: currentLocation,
          avatarUrl: avatarUrl,
          destinations: destinations,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverPersistentHeader(
              pinned: true,
              delegate: SliverTabDelegate(
                child: Container(
                  width: double.infinity,
                  color: AppColors.background,
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.center,
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                    unselectedLabelColor: AppColors.text1.withOpacity(0.70),
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    unselectedLabelStyle: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inbox_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text('Received (${_receivedWaves.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.verified_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text('Mutual (${_mutualConnections.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.outbox_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text('Sent (${_sentWaves.length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            RefreshIndicator(
              onRefresh: _loadWaves,
              child: _buildReceivedList(),
            ),
            RefreshIndicator(onRefresh: _loadWaves, child: _buildMutualList()),
            RefreshIndicator(onRefresh: _loadWaves, child: _buildSentList()),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.text1.withOpacity(0.70),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadWaves,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.text1,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }
    if (_receivedWaves.isEmpty) {
      return _buildEmptyState();
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        const SizedBox(height: 12),
        ..._receivedWaves
            .map(
              (wave) => Container(
                key: ValueKey('received_${wave.id}'),
                margin: const EdgeInsets.only(bottom: 12),
                child: _buildReceivedCard(wave),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildMutualList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }
    if (_mutualConnections.isEmpty) {
      return _buildEmptyState();
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        const SizedBox(height: 12),
        ..._mutualConnections
            .map(
              (wave) => Container(
                key: ValueKey('mutual_${wave.id}'),
                margin: const EdgeInsets.only(bottom: 12),
                child: _buildMutualCard(wave),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildSentList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }
    if (_sentWaves.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        const SizedBox(height: 12),
        ..._sentWaves
            .map(
              (wave) => Container(
                key: ValueKey('sent_${wave.id}'),
                margin: const EdgeInsets.only(bottom: 12),
                child: _buildSentCard(wave),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const AppHeader(
      title: 'Your Waves',
      subtitle: 'Connect with fellow travelers',
      fontSize: 32,
    );
  }

  // _sectionTitle helper is intentionally unused after refactor

  Widget _buildMutualCard(Wave wave) {
    final otherUserName = wave.receiverId == _waveService.currentUserId
        ? wave.senderName
        : wave.receiverName;
    final otherUserLocation = wave.receiverId == _waveService.currentUserId
        ? wave.senderLocation
        : wave.receiverLocation;
    // For mutual connections, show the other person's avatar
    // If current user is receiver, show sender's avatar, otherwise show receiver's avatar
    final otherUserAvatar = wave.receiverId == _waveService.currentUserId
        ? wave.avatarUrl
        : wave.receiverAvatarUrl;

    return _cardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(
                _firstLetter(otherUserName),
                wave.isVerified,
                otherUserAvatar,
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
                            otherUserName,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.text3.withOpacity(0.87),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      otherUserLocation,
                      style: TextStyle(
                        color: AppColors.text3.withOpacity(0.45),
                      ),
                    ),
                    if (wave.message != null && wave.message!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        wave.message!,
                        style: TextStyle(
                          color: AppColors.text3.withOpacity(0.45),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (wave.isVerified)
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColors.highlight2,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      wave.timeAgo,
                      style: TextStyle(color: AppColors.highlight2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => _startChat(wave),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.text1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Start Chat'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedCard(Wave wave) {
    return _cardWrapper(
      onTap: () => _openTravelerBlogs(
        userId: wave.senderId,
        userName: wave.senderName,
        currentLocation: wave.senderLocation,
        avatarUrl: wave.avatarUrl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(
                _firstLetter(wave.senderName),
                wave.isVerified,
                wave.avatarUrl,
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
                            wave.senderName,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.text3.withOpacity(0.87),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      wave.senderLocation,
                      style: TextStyle(
                        color: AppColors.text3.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (wave.isVerified)
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColors.highlight2,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      wave.timeAgo,
                      style: TextStyle(color: AppColors.highlight2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _acceptWave(wave),
                  icon: const Icon(Icons.verified_rounded),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.highlight2,
                    foregroundColor: AppColors.text1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _ignoreWave(wave),
                  icon: const Icon(Icons.close),
                  label: const Text('Ignore'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text3.withOpacity(0.54),
                    side: BorderSide(color: AppColors.text3.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSentCard(Wave wave) {
    // Enhanced Sent Wave card with status chip, message preview and actions
    final statusColor = _getStatusColor(wave.status);
    final statusText = _getStatusText(wave.status);

    return _cardWrapper(
      onTap: () => _openTravelerBlogs(
        userId: wave.receiverId,
        userName: wave.receiverName,
        currentLocation: wave.receiverLocation,
        avatarUrl: wave.receiverAvatarUrl,
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _avatar(
                    _firstLetter(wave.receiverName),
                    false,
                    wave.receiverAvatarUrl,
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
                                wave.receiverName,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.text3.withOpacity(0.87),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    wave.status == WaveStatus.pending
                                        ? Icons.schedule
                                        : wave.status == WaveStatus.accepted
                                        ? Icons.verified_rounded
                                        : wave.status == WaveStatus.ignored
                                        ? Icons.block
                                        : Icons.history_toggle_off,
                                    size: 14,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: AppColors.text3.withOpacity(0.38),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                wave.receiverLocation,
                                style: TextStyle(
                                  color: AppColors.text3.withOpacity(0.54),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (wave.message != null && wave.message!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.highlight2.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.highlight2.withOpacity(0.12),
                                ),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.message_rounded,
                                    size: 16,
                                    color: AppColors.highlight2,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      wave.message!,
                                      style: TextStyle(
                                        color: AppColors.text3.withOpacity(
                                          0.54,
                                        ),
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openTravelerBlogs(
                        userId: wave.receiverId,
                        userName: wave.receiverName,
                        currentLocation: wave.receiverLocation,
                        avatarUrl: wave.receiverAvatarUrl,
                      ),
                      icon: const Icon(Icons.person_outline),
                      label: const Text('View Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.text3.withOpacity(0.87),
                        side: BorderSide(
                          color: AppColors.text3.withOpacity(0.15),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (wave.status == WaveStatus.accepted)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _startChat(wave),
                        icon: const Icon(Icons.chat_rounded, size: 18),
                        label: const Text('Message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.text1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            (wave.status == WaveStatus.pending &&
                                !wave.isExpired)
                            ? () => _deleteWave(wave)
                            : null,
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.text1,
                          disabledBackgroundColor: AppColors.error.withOpacity(
                            0.4,
                          ),
                          disabledForegroundColor: AppColors.text1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: AppColors.text3.withOpacity(0.38),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    wave.timeAgo,
                    style: TextStyle(
                      color: AppColors.text3.withOpacity(0.45),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (wave.status == WaveStatus.pending && !wave.isExpired)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _deleteWave(wave),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getStatusText(WaveStatus status) {
    switch (status) {
      case WaveStatus.accepted:
        return 'Accepted';
      case WaveStatus.ignored:
        return 'Ignored';
      case WaveStatus.expired:
        return 'Expired';
      default:
        return 'Pending';
    }
  }

  Color _getStatusColor(WaveStatus status) {
    switch (status) {
      case WaveStatus.accepted:
        return AppColors.success;
      case WaveStatus.ignored:
        return AppColors.cta1;
      case WaveStatus.expired:
        return AppColors.error;
      default:
        return AppColors.highlight;
    }
  }

  String _firstLetter(String? value) {
    try {
      final trimmed = (value ?? '').trim();
      if (trimmed.isEmpty) return '?';
      // Use runes to safely get the first Unicode scalar (handles emojis, etc.)
      return String.fromCharCode(trimmed.runes.first);
    } catch (_) {
      return '?';
    }
  }

  Widget _cardWrapper({required Widget child, VoidCallback? onTap}) {
    final content = Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.text3.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }

  Widget _avatar(String letter, bool isVerified, String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 26,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: AppColors.primary,
        onBackgroundImageError: (exception, stackTrace) {
          // If image fails to load, fall back to letter avatar
          print('Failed to load avatar: $exception');
        },
        child: Container(), // Empty container as placeholder
      );
    }

    // Fallback to letter avatar if no image URL
    return CircleAvatar(
      radius: 26,
      backgroundColor: AppColors.primary,
      child: Text(
        letter.toUpperCase(),
        style: TextStyle(color: AppColors.text1, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final imageSize = math.min(screenWidth, screenHeight) * 0.4;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          SizedBox(
            width: imageSize,
            height: imageSize,
            child: Image.asset('assets/wave-empty.png', fit: BoxFit.contain),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'No waves yet',
              style: AppTextStyles.h4.copyWith(
                color: AppColors.text1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Start connecting with fellow travelers by sending waves!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.text1.withOpacity(0.70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
