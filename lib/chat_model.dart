class Chat {
  final String profilePic;
  final String name;
  String lastMessage;
  String lastMessageTime;
  String lastMessageType;

  Chat({
    required this.profilePic,
    required this.name,
    this.lastMessage = 'No messages',
    this.lastMessageTime = '',
    this.lastMessageType = 'text',
  });

  Map<String, dynamic> toJson() {
    return {
      'profilePic': profilePic,
      'name': name,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'lastMessageType': lastMessageType,
    };
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      profilePic: json['profilePic'] ?? '',
      name: json['name'] ?? 'Unknown',
      lastMessage: json['lastMessage'] ?? 'No messages',
      lastMessageTime: json['lastMessageTime'] ?? '',
      lastMessageType: json['lastMessageType'] ?? 'text',
    );
  }
}
