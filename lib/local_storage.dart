import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'chat_model.dart';

class LocalStorage {
  static Future<void> saveUniqueChatList(List<Chat> chatList) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, Chat> uniqueChatMap = {
      for (var chat in chatList)
        if (chat.name.isNotEmpty) chat.name: chat
    };
    List<String> chatJsonList =
        uniqueChatMap.values.map((chat) => jsonEncode(chat.toJson())).toList();
    await prefs.setStringList('chatList', chatJsonList);
  }

  static Future<List<Chat>> getChatList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? chatJsonList = prefs.getStringList('chatList');
    if (chatJsonList != null) {
      return chatJsonList
          .map((chatJson) => Chat.fromJson(jsonDecode(chatJson)))
          .toList();
    }
    return [];
  }

  static Future<void> updateLastMessage({
    required String chatName,
    required String lastMessage,
    required String lastMessageTime,
    String lastMessageType = 'text',
  }) async {
    List<Chat> chatList = await getChatList();
    for (var chat in chatList) {
      if (chat.name == chatName) {
        chat.lastMessage = lastMessage.isNotEmpty ? lastMessage : 'No messages';
        chat.lastMessageTime = lastMessageTime.isNotEmpty
            ? lastMessageTime
            : DateTime.now().toString();
        chat.lastMessageType =
            lastMessageType.isNotEmpty ? lastMessageType : 'text';
        break;
      }
    }
    await saveUniqueChatList(chatList);
  }
}
