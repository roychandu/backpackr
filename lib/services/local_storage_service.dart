import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/blog.dart';

class LocalStorageService {
  static const String profilesBoxName = 'user_profiles';
  static const String conversationsBoxName = 'conversations';
  static const String messagesBoxName = 'chat_messages';
  static const String blogsBoxName = 'blogs';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(DestinationAdapter());
    Hive.registerAdapter(ChatMessageAdapter());
    Hive.registerAdapter(MessageTypeAdapter());
    Hive.registerAdapter(ConversationAdapter());
    Hive.registerAdapter(BlogAdapter());

    // Open Boxes
    await Hive.openBox<UserProfile>(profilesBoxName);
    await Hive.openBox<Conversation>(conversationsBoxName);
    await Hive.openBox<ChatMessage>(messagesBoxName);
    await Hive.openBox<Blog>(blogsBoxName);
  }

  // User Profile Methods
  static Future<void> saveProfile(UserProfile profile) async {
    final box = Hive.box<UserProfile>(profilesBoxName);
    await box.put(profile.displayName, profile);
  }

  static List<UserProfile> getAllProfiles() {
    final box = Hive.box<UserProfile>(profilesBoxName);
    return box.values.toList();
  }

  static Future<void> saveAllProfiles(List<UserProfile> profiles) async {
    final box = Hive.box<UserProfile>(profilesBoxName);
    final Map<String, UserProfile> profileMap = {
      for (var p in profiles) p.displayName: p
    };
    await box.putAll(profileMap);
  }

  // Conversation Methods
  static Future<void> saveConversation(Conversation conversation) async {
    final box = Hive.box<Conversation>(conversationsBoxName);
    await box.put(conversation.id, conversation);
  }

  static List<Conversation> getAllConversations() {
    final box = Hive.box<Conversation>(conversationsBoxName);
    return box.values.toList();
  }

  static Future<void> saveAllConversations(List<Conversation> conversations) async {
    final box = Hive.box<Conversation>(conversationsBoxName);
    final Map<String, Conversation> conversationMap = {
      for (var c in conversations) c.id: c
    };
    await box.putAll(conversationMap);
  }

  // Message Methods
  static Future<void> saveMessage(ChatMessage message) async {
    final box = Hive.box<ChatMessage>(messagesBoxName);
    await box.put(message.id, message);
  }

  static List<ChatMessage> getMessagesForConversation(String conversationId) {
    final box = Hive.box<ChatMessage>(messagesBoxName);
    return box.values.where((m) => m.conversationId == conversationId).toList();
  }

  static Future<void> saveAllMessages(List<ChatMessage> messages) async {
    final box = Hive.box<ChatMessage>(messagesBoxName);
    final Map<String, ChatMessage> messageMap = {
      for (var m in messages) m.id: m
    };
    await box.putAll(messageMap);
  }

  // Blog Methods
  static Future<void> saveBlog(Blog blog) async {
    final box = Hive.box<Blog>(blogsBoxName);
    await box.put(blog.id, blog);
  }

  static List<Blog> getAllBlogs() {
    final box = Hive.box<Blog>(blogsBoxName);
    return box.values.toList();
  }

  static Future<void> saveAllBlogs(List<Blog> blogs) async {
    final box = Hive.box<Blog>(blogsBoxName);
    final Map<String, Blog> blogMap = {for (var b in blogs) b.id: b};
    await box.putAll(blogMap);
  }

  static Future<void> deleteBlog(String blogId) async {
    final box = Hive.box<Blog>(blogsBoxName);
    await box.delete(blogId);
  }

  static Future<void> clearAll() async {
    await Hive.box<UserProfile>(profilesBoxName).clear();
    await Hive.box<Conversation>(conversationsBoxName).clear();
    await Hive.box<ChatMessage>(messagesBoxName).clear();
    await Hive.box<Blog>(blogsBoxName).clear();
  }
}
