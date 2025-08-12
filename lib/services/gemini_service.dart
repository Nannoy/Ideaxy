import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/content_models.dart';

class GeminiService {
  GenerativeModel _model() {
    const defineKey = String.fromEnvironment('GEMINI_API_KEY');
    final envKey = dotenv.env['GEMINI_API_KEY'];
    final apiKey = defineKey.isNotEmpty ? defineKey : envKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('GEMINI_API_KEY not set');
    }
    return GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  }

  Future<ContentPlan> generatePlan({
    required String niche,
    required List<String> platforms,
    required ContentScheduleType scheduleType,
  }) async {
    final days = switch (scheduleType) {
      ContentScheduleType.instant => 1,
      ContentScheduleType.fourDays => 4,
      ContentScheduleType.sevenDays => 7,
    };

    final prompt = '''
You are a professional social media content strategist AI that produces fully complete, ready-to-publish content so the user does not need to add or research anything.
Niche: "$niche".
Platforms: ${platforms.join(', ')}.
Plan length: $days day(s).

STRICT OUTPUT REQUIREMENTS:
- Respond with ONLY minified JSON. No prose, no Markdown, no code fences, no comments.
- JSON schema:
  {
    "items": [
      {
        "platform": "LinkedIn | X | Instagram | TikTok | YouTube | Facebook",
        "title": "string",
        "description": "string",
        "script": "string",
        "hashtags": ["#tag1", "#tag2", "#tag3"],
        "tips": "string",
        "scheduledAt": "YYYY-MM-DDTHH:MM:SSZ"
      }
    ]
  }

CONTENT CREATION RULES (NON-NEGOTIABLE):
- All text must be complete, clear, and require zero external research before posting.
- Avoid generic or vague content — include concrete details, context, and calls-to-action.
- Hashtags must be relevant, high-quality, and platform-specific (3–10 tags depending on platform norms).
- Tips must be immediately useful and actionable without extra reading.
- "scheduledAt" must use real UTC dates/times starting from today's date, covering the requested number of days in order, using optimal posting hours per platform:
  LinkedIn: 13:00 UTC
  X: 12:00 UTC
  Instagram: 15:00 UTC
  TikTok: 18:00 UTC
  YouTube: 17:00 UTC
  Facebook: 14:00 UTC
- Create exactly one unique post per platform per day.

PLATFORM-SPECIFIC STYLE & EXAMPLES:
1. LinkedIn → Long-form professional post
   - Title: Compelling headline
   - Description: 3–6 paragraphs with valuable insights, data points, and actionable advice.
   - Script: Structured talking points for video version.
   Example:
     title: "5 Strategies to Boost Remote Team Productivity"
     description: "In the past year, remote teams have transformed how we work... (continues with practical steps, examples, and CTA)"
     script: "Intro greeting, define problem, list strategies with examples, wrap up with key takeaway."

2. X (Twitter) → Short, viral, hook-based
   - Title: Short hook or main message
   - Description: 1–2 punchy sentences with value
   - Script: Optional for short clips
   Example:
     title: "Your daily dose of coding wisdom"
     description: "Write code as if the next person to maintain it is a violent psychopath who knows where you live. #coding #devtips"
     script: ""

3. Instagram → Visual-first with emotional hook
   - Title: Catchy, playful, or curiosity-driven
   - Description: 2–4 short lines with emojis and CTA
   - Script: Shot-by-shot or visual scene ideas for Reels/carousels
   Example:
     title: "The Breakfast Bowl That Changed My Mornings"
     description: "🥑+🍳 = ❤️ Perfect for busy mornings! Save this for tomorrow's breakfast."
     script: "Clip 1: Show ingredients... Clip 2: Cooking... Clip 3: Serving and taste reaction."

4. TikTok → Script-led viral content
   - Title: Short and curiosity-driven
   - Description: Quick context in 1 sentence
   - Script: Scene-by-scene, including actions, dialogue, and camera cues
   Example:
     title: "This 3-ingredient pasta will blow your mind"
     description: "No fancy skills needed — just delicious results."
     script: "Scene 1: Close-up of ingredients with text overlay... Scene 2: Cooking steps... Scene 3: Final reveal + smile."

5. YouTube → SEO-optimized & structured
   - Title: Search-friendly with strong hook
   - Description: 2–4 paragraphs including keywords, timestamps, and CTA to subscribe
   - Script: Fully camera-ready with intro, value-packed middle, and CTA outro
   Example:
     title: "How to Build a Personal Brand in 2025 (Step-by-Step)"
     description: "Building your personal brand can open doors to opportunities... (full detail + keywords + timestamps)"
     script: "Intro hook, introduce self, outline steps, give examples, summarize, CTA."

6. Facebook → Conversational but informative
   - Title: Relatable headline
   - Description: 2–3 paragraphs that are friendly and easy to share
   - Script: Optional unless video-based
   Example:
     title: "Meal Prepping for Busy Parents"
     description: "Struggling to put dinner on the table every night? Try this 30-minute Sunday prep... (continues with details)"
     script: ""

Make sure every field is complete, relevant, and optimized for immediate posting.
''';



    final response = await _model().generateContent([Content.text(prompt)]);
    final text = response.text ?? '';

    // Log prompt and response to terminal for debugging/inspection
    debugPrint('----- Gemini Prompt Start -----');
    debugPrint(prompt);
    debugPrint('----- Gemini Prompt End -----');
    debugPrint('----- Gemini Response Start -----');
    debugPrint(text);
    debugPrint('----- Gemini Response End -----');

    // Try JSON parsing first
    final parsedPlan = _tryParseJsonPlan(text);
    if (parsedPlan != null) {
      debugPrint('Gemini returned ${parsedPlan.items.length} items for platforms: ${parsedPlan.items.map((i) => i.platform).toList()}');
      debugPrint('Requested platforms: $platforms');
      
      // Filter items to only include requested platforms
      final filteredItems = parsedPlan.items.where((item) => platforms.contains(item.platform)).toList();
      debugPrint('After filtering: ${filteredItems.length} items for platforms: ${filteredItems.map((i) => i.platform).toList()}');
      
      // Ensure 'Instant' uses the current date/time regardless of model output
      if (scheduleType == ContentScheduleType.instant) {
        final now = DateTime.now();
        final adjusted = filteredItems
            .map((i) => ContentItem(
                  scheduledAt: now,
                  platform: i.platform,
                  title: i.title,
                  description: i.description,
                  script: i.script,
                  hashtags: i.hashtags,
                  tips: i.tips,
                ))
            .toList();
        return ContentPlan(scheduleType: scheduleType, items: adjusted);
      }
      return ContentPlan(scheduleType: scheduleType, items: filteredItems);
    }

    // Fallback to heuristic parsing for robustness
    debugPrint('Using fallback parsing for platforms: $platforms');
    final now = DateTime.now();
    DateTime scheduledDate = _parseFirstIsoDate(text) ?? now.toUtc();
    if (scheduleType == ContentScheduleType.instant) {
      scheduledDate = now;
    }
    final items = <ContentItem>[];
    // For instant schedule, ensure only one item per platform
    final uniquePlatforms = platforms.toSet().toList();
    debugPrint('Processing unique platforms: $uniquePlatforms');
    for (final platform in uniquePlatforms) {
      final section = _extractPlatformSection(text, platform);
      final title = _extractField(section, r"(?i)\bTitle\s*:\s*(.+)") ?? 'Idea for $platform in $niche';
      final description = _extractField(section, r"(?i)\bShort\s*Description\s*:\s*(.+)") ??
          'Auto-generated description based on your niche.';
      final script = _extractField(section, r"(?i)\bScript\s*:\s*(.+)") ??
          (section.isNotEmpty ? section.substring(0, section.length.clamp(0, 600)) : 'Script generated by Gemini.');
      final hashtagsLine = _extractField(section, r"(?i)\bHashtags\s*:\s*(.+)") ?? '';
      final hashtags = _splitHashtags(hashtagsLine);
      final tips = _extractField(section, r"(?i)\bPosting\s*Tips\s*:\s*(.+)") ??
          'Post at prime time; use a strong hook and clear CTA.';

      items.add(
        ContentItem(
          scheduledAt: scheduledDate,
          platform: platform,
          title: title.trim(),
          description: description.trim(),
          script: script.trim(),
          hashtags: hashtags,
          tips: tips.trim(),
        ),
      );
    }

    return ContentPlan(scheduleType: scheduleType, items: items);
  }

  // Helpers
  DateTime? _parseFirstIsoDate(String text) {
    final match = RegExp(r"(20\d{2}-\d{2}-\d{2})").firstMatch(text);
    if (match != null) {
      final parsed = DateTime.tryParse(match.group(1)!);
      if (parsed != null) return parsed;
    }
    return null;
  }

  String _extractPlatformSection(String text, String platform) {
    // Normalize platform variations, especially X/Twitter
    final variants = <String>{platform};
    if (platform.toLowerCase() == 'x') {
      variants.add('X (formerly Twitter)');
      variants.add('Twitter');
    }
    // Build a regex that matches a header line containing the platform name, often with **markdown**
    final variantsPattern = variants.map(RegExp.escape).join('|');
    final headerPattern = RegExp(
      '(?:^|[\\r\\n])\\s*(?:\\*\\*\\s*)?(?:$variantsPattern)(?:\\s*\\*\\*)?\\s*(?:[\\r\\n])',
      caseSensitive: false,
    );
    final matches = headerPattern.allMatches(text).toList();
    if (matches.isEmpty) return '';
    final start = matches.first.end;
    // End at next header of any known platform or end of text
    final anyPlatform = RegExp(
      '(?:^|[\\r\\n])\\s*(?:\\*\\*\\s*)?(?:LinkedIn|X|Twitter|Instagram|TikTok|YouTube)(?:\\s*\\*\\*)?\\s*(?:[\\r\\n])',
      caseSensitive: false,
    );
    final next = anyPlatform.allMatches(text).skipWhile((m) => m.start <= start).firstOrNull;
    final end = next?.start ?? text.length;
    return text.substring(start, end);
  }

  String? _extractField(String section, String pattern) {
    if (section.isEmpty) return null;
    final regex = RegExp(pattern, dotAll: true);
    final match = regex.firstMatch(section);
    if (match == null) return null;
    return match.group(1);
  }

  List<String> _splitHashtags(String line) {
    if (line.isEmpty) return const [];
    // Accept formats like: #tag1 #tag2 or tag1, tag2, tag3
    final hashMatches = RegExp(r"#\w+").allMatches(line).map((m) => m.group(0)!).toList();
    if (hashMatches.isNotEmpty) return hashMatches;
    return line
        .split(RegExp(r"[;,\s]+"))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.startsWith('#') ? s : '#${s.trim()}')
        .toList();
  }

  ContentPlan? _tryParseJsonPlan(String raw) {
    try {
      // Strip code fences if present
      var text = raw.trim();
      if (text.startsWith('```')) {
        final fenceIdx = text.indexOf('\n');
        if (fenceIdx != -1) {
          text = text.substring(fenceIdx + 1);
        }
        if (text.endsWith('```')) {
          text = text.substring(0, text.length - 3);
        }
        text = text.trim();
      }

      final data = jsonDecode(text) as Map<String, dynamic>;
      final itemsData = (data['items'] as List).cast<Map<String, dynamic>>();
      final items = <ContentItem>[];
      for (var i = 0; i < itemsData.length; i++) {
        final m = itemsData[i];
        final scheduledAtStr = (m['scheduledAt'] as String?) ?? '';
        final scheduledAt = DateTime.tryParse(scheduledAtStr)?.toUtc() ?? DateTime.now().toUtc().add(Duration(hours: i));
        final hashtagsRaw = (m['hashtags'] as List?)?.cast<String>() ?? _splitHashtags(m['hashtags']?.toString() ?? '');
        items.add(
          ContentItem(
            scheduledAt: scheduledAt,
            platform: (m['platform'] as String? ?? 'Unknown').trim(),
            title: (m['title'] as String? ?? '').trim(),
            description: (m['description'] as String? ?? '').trim(),
            script: (m['script'] as String? ?? '').trim(),
            hashtags: hashtagsRaw,
            tips: (m['tips'] as String? ?? '').trim(),
          ),
        );
      }
      return ContentPlan(scheduleType: ContentScheduleType.instant, items: items);
    } catch (e) {
      debugPrint('JSON parse failed: $e');
      return null;
    }
  }
}

