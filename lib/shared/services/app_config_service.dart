class AppConfigService {
  static final AppConfigService _instance = AppConfigService._internal();
  factory AppConfigService() => _instance;
  AppConfigService._internal();

  // ==================== MUTUAL CONNECTION CHAT LIMITS ====================
  static const int freePlanMutualChatLimit = 10;
  static const int freePlanMutualChatLimitDisplay = 10;
  static const bool premiumPlanUnlimitedChats = true;

  // ==================== MEETUP CREATION LIMITS ====================
  static const int freePlanCreateMeetupLimit = 5;
  static const int freePlanCreateMeetupLimitDisplay = 5;
  static const bool premiumPlanUnlimitedMeetupCreation = true;

  // ==================== JOIN PUBLIC MEETUP LIMITS ====================
  static const int freePlanJoinMeetupLimit = 10;
  static const int freePlanJoinMeetupLimitDisplay = 10;
  static const bool premiumPlanUnlimitedMeetupJoining = true;

  // ==================== BLOG CREATION LIMITS ====================
  static const int freePlanBlogLimit = 10;
  static const int freePlanBlogLimitDisplay = 10;
  static const bool premiumPlanUnlimitedBlogs = true;

  // ==================== PREMIUM FEATURES ====================
  static const bool premiumAllowsAdvancedFeatures = true;

  // ==================== MUTUAL CONNECTION CHAT METHODS ====================

  /// Get the actual chat limit for free users
  int get freeUserChatLimit => freePlanMutualChatLimit;

  /// Get the displayed chat limit for free users
  int get freeUserChatLimitDisplay => freePlanMutualChatLimitDisplay;

  /// Check if premium users have unlimited chats
  bool get premiumHasUnlimitedChats => premiumPlanUnlimitedChats;

  /// Get chat limit description for UI display
  String getFreePlanChatDescription() {
    return '$freePlanMutualChatLimitDisplay mutual connection chats';
  }

  /// Get premium plan chat description for UI display
  String getPremiumPlanChatDescription() {
    return premiumHasUnlimitedChats
        ? 'Unlimited mutual connection chats'
        : 'Extended chat limits';
  }

  /// Check if a user has reached their chat limit
  bool hasReachedChatLimit(int userChatCount, bool isPremium) {
    if (isPremium && premiumHasUnlimitedChats) {
      return false;
    }
    return userChatCount >= freeUserChatLimit;
  }

  /// Get the remaining chat count for free users
  int getRemainingChats(int userChatCount, bool isPremium) {
    if (isPremium && premiumHasUnlimitedChats) {
      return -1; // Unlimited
    }
    final remaining = freeUserChatLimit - userChatCount;
    return remaining > 0 ? remaining : 0;
  }

  // ==================== MEETUP CREATION METHODS ====================

  /// Get the actual meetup creation limit for free users
  int get freeUserCreateMeetupLimit => freePlanCreateMeetupLimit;

  /// Get the displayed meetup creation limit for free users
  int get freeUserCreateMeetupLimitDisplay => freePlanCreateMeetupLimitDisplay;

  /// Check if premium users have unlimited meetup creation
  bool get premiumHasUnlimitedMeetupCreation =>
      premiumPlanUnlimitedMeetupCreation;

  /// Get meetup creation limit description for UI display
  String getFreePlanCreateMeetupDescription() {
    return 'Create $freePlanCreateMeetupLimitDisplay meetups';
  }

  /// Get premium plan meetup creation description for UI display
  String getPremiumPlanCreateMeetupDescription() {
    return premiumHasUnlimitedMeetupCreation
        ? 'Create unlimited meetups'
        : 'Extended meetup creation limits';
  }

  /// Check if a user has reached their meetup creation limit
  bool hasReachedCreateMeetupLimit(int userMeetupCount, bool isPremium) {
    if (isPremium && premiumHasUnlimitedMeetupCreation) {
      return false;
    }
    return userMeetupCount >= freeUserCreateMeetupLimit;
  }

  /// Get the remaining meetup creation count for free users
  int getRemainingCreateMeetups(int userMeetupCount, bool isPremium) {
    if (isPremium && premiumHasUnlimitedMeetupCreation) {
      return -1; // Unlimited
    }
    final remaining = freeUserCreateMeetupLimit - userMeetupCount;
    return remaining > 0 ? remaining : 0;
  }

  // ==================== JOIN PUBLIC MEETUP METHODS ====================

  /// Get the actual join meetup limit for free users
  int get freeUserJoinMeetupLimit => freePlanJoinMeetupLimit;

  /// Get the displayed join meetup limit for free users
  int get freeUserJoinMeetupLimitDisplay => freePlanJoinMeetupLimitDisplay;

  /// Check if premium users have unlimited meetup joining
  bool get premiumHasUnlimitedMeetupJoining =>
      premiumPlanUnlimitedMeetupJoining;

  /// Get join meetup limit description for UI display
  String getFreePlanJoinMeetupDescription() {
    return 'Join $freePlanJoinMeetupLimitDisplay public meetups';
  }

  /// Get premium plan join meetup description for UI display
  String getPremiumPlanJoinMeetupDescription() {
    return premiumHasUnlimitedMeetupJoining
        ? 'Join unlimited public meetups'
        : 'Extended meetup joining limits';
  }

  /// Check if a user has reached their join meetup limit
  bool hasReachedJoinMeetupLimit(int userJoinCount, bool isPremium) {
    if (isPremium && premiumHasUnlimitedMeetupJoining) {
      return false;
    }
    return userJoinCount >= freeUserJoinMeetupLimit;
  }

  /// Get the remaining join meetup count for free users
  int getRemainingJoinMeetups(int userJoinCount, bool isPremium) {
    if (isPremium && premiumHasUnlimitedMeetupJoining) {
      return -1; // Unlimited
    }
    final remaining = freeUserJoinMeetupLimit - userJoinCount;
    return remaining > 0 ? remaining : 0;
  }

  // ==================== BLOG CREATION METHODS ====================

  /// Get the actual blog limit for free users
  int get freeUserBlogLimit => freePlanBlogLimit;

  /// Get the displayed blog limit for free users
  int get freeUserBlogLimitDisplay => freePlanBlogLimitDisplay;

  /// Check if premium users have unlimited blogs
  bool get premiumHasUnlimitedBlogs => premiumPlanUnlimitedBlogs;

  /// Get blog limit description for UI display
  String getFreePlanBlogDescription() {
    return 'Create $freePlanBlogLimitDisplay blogs';
  }

  /// Get premium plan blog description for UI display
  String getPremiumPlanBlogDescription() {
    return premiumHasUnlimitedBlogs
        ? 'Create unlimited blogs'
        : 'Extended blog limits';
  }

  /// Check if a user has reached their blog limit
  bool hasReachedBlogLimit(int userBlogCount, bool isPremium) {
    if (isPremium && premiumHasUnlimitedBlogs) {
      return false;
    }
    return userBlogCount >= freeUserBlogLimit;
  }

  /// Get the remaining blog count for free users
  int getRemainingBlogs(int userBlogCount, bool isPremium) {
    if (isPremium && premiumHasUnlimitedBlogs) {
      return -1; // Unlimited
    }
    final remaining = freeUserBlogLimit - userBlogCount;
    return remaining > 0 ? remaining : 0;
  }

  // ==================== GENERAL UTILITY METHODS ====================

  /// Get all free plan features as a list
  List<String> getAllFreePlanFeatures() {
    return [
      getFreePlanChatDescription(),
      getFreePlanCreateMeetupDescription(),
      getFreePlanJoinMeetupDescription(),
      getFreePlanBlogDescription(),
    ];
  }

  /// Get all premium plan features as a list
  List<String> getAllPremiumPlanFeatures() {
    return [
      getPremiumPlanChatDescription(),
      getPremiumPlanCreateMeetupDescription(),
      getPremiumPlanJoinMeetupDescription(),
      getPremiumPlanBlogDescription(),
    ];
  }

  /// Check if any feature has reached its limit for free users
  bool hasReachedAnyLimit({
    required int chatCount,
    required int createMeetupCount,
    required int joinMeetupCount,
    required int blogCount,
    required bool isPremium,
  }) {
    if (isPremium) return false;

    return hasReachedChatLimit(chatCount, isPremium) ||
        hasReachedCreateMeetupLimit(createMeetupCount, isPremium) ||
        hasReachedJoinMeetupLimit(joinMeetupCount, isPremium) ||
        hasReachedBlogLimit(blogCount, isPremium);
  }

  /// Get a summary of all limits and current usage
  Map<String, dynamic> getLimitsSummary({
    required int chatCount,
    required int createMeetupCount,
    required int joinMeetupCount,
    required int blogCount,
    required bool isPremium,
  }) {
    return {
      'chats': {
        'current': chatCount,
        'limit': isPremium ? 'Unlimited' : freeUserChatLimit,
        'remaining': getRemainingChats(chatCount, isPremium),
        'reached': hasReachedChatLimit(chatCount, isPremium),
      },
      'createMeetups': {
        'current': createMeetupCount,
        'limit': isPremium ? 'Unlimited' : freeUserCreateMeetupLimit,
        'remaining': getRemainingCreateMeetups(createMeetupCount, isPremium),
        'reached': hasReachedCreateMeetupLimit(createMeetupCount, isPremium),
      },
      'joinMeetups': {
        'current': joinMeetupCount,
        'limit': isPremium ? 'Unlimited' : freeUserJoinMeetupLimit,
        'remaining': getRemainingJoinMeetups(joinMeetupCount, isPremium),
        'reached': hasReachedJoinMeetupLimit(joinMeetupCount, isPremium),
      },
      'blogs': {
        'current': blogCount,
        'limit': isPremium ? 'Unlimited' : freeUserBlogLimit,
        'remaining': getRemainingBlogs(blogCount, isPremium),
        'reached': hasReachedBlogLimit(blogCount, isPremium),
      },
    };
  }
}
