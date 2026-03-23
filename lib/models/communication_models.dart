class Announcement {
  final String id;
  final String title;
  final String content;
  final String author;
  final String date;
  final String priority;
  final String targetAudience;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.date,
    required this.priority,
    required this.targetAudience,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? json['description'] ?? '',
      author: json['author'] ?? json['createdBy'] ?? 'System',
      date: json['date'] ?? json['createdAt'] ?? DateTime.now().toIso8601String(),
      priority: json['priority'] ?? 'Medium',
      targetAudience: json['targetAudience'] ?? 'All',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'content': content,
      'author': author,
      'date': date,
      'priority': priority,
      'targetAudience': targetAudience,
    };
  }
}

class Message {
  final String id;
  final String subject;
  final String content;
  final String sender;
  final String recipient;
  final String date;
  final bool isRead;
  final String type;

  Message({
    required this.id,
    required this.subject,
    required this.content,
    required this.sender,
    required this.recipient,
    required this.date,
    required this.isRead,
    required this.type,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      subject: json['subject'] ?? '',
      content: json['content'] ?? '',
      sender: json['sender'] ?? '',
      recipient: json['recipient'] ?? '',
      date: json['date'] ?? '',
      isRead: json['isRead'] ?? false,
      type: json['type'] ?? 'message',
    );
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String content;
  final String date;
  final bool isRead;
  final String type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.isRead,
    required this.type,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      date: json['date'] ?? '',
      isRead: json['isRead'] ?? false,
      type: json['type'] ?? 'notification',
    );
  }
}

