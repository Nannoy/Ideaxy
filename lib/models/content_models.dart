class UserProfile {
  final String id;
  final String name;
  final String handle;
  final String niche;
  final List<String> preferredPlatforms;

  UserProfile({
    required this.id,
    required this.name,
    required this.handle,
    required this.niche,
    required this.preferredPlatforms,
  });
}

enum ContentScheduleType { instant, fourDays, sevenDays }

class ContentItem {
  final DateTime scheduledAt;
  final String platform; // e.g., LinkedIn, X, Instagram, TikTok, YouTube
  final String title;
  final String description;
  final String script;
  final List<String> hashtags;
  final String tips;

  ContentItem({
    required this.scheduledAt,
    required this.platform,
    required this.title,
    required this.description,
    required this.script,
    required this.hashtags,
    required this.tips,
  });
}

class ContentPlan {
  final ContentScheduleType scheduleType;
  final List<ContentItem> items;

  ContentPlan({required this.scheduleType, required this.items});
}

