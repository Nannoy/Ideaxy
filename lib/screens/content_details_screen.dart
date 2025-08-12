import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/content_models.dart';

class ContentDetailsScreen extends StatelessWidget {
  const ContentDetailsScreen({super.key, required this.item});
  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    final accent = _platformBrandColor(item.platform);
    final date = DateFormat.yMMMd().add_Hm().format(item.scheduledAt);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('${item.platform} details', style: const TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _HeaderRow(platform: item.platform, accent: accent),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Title',
              accent: accent,
              content: item.title,
              onCopy: () => _copy(context, item.title),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Description',
              accent: accent,
              content: item.description,
              onCopy: () => _copy(context, item.description),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Script',
              accent: accent,
              content: item.script,
              onCopy: () => _copy(context, item.script),
            ),
            const SizedBox(height: 12),
            _HashtagsCard(hashtags: item.hashtags, accent: accent, onCopy: () => _copy(context, item.hashtags.join(' '))),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Tips',
              accent: accent,
              content: item.tips,
              onCopy: () => _copy(context, item.tips),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Scheduled',
              accent: accent,
              content: date,
              onCopy: () => _copy(context, date),
            ),
            const SizedBox(height: 20),
            _PrimaryButton(
              onPressed: () => _copy(context, _formatAll(item)),
              child: const Text('Copy All'),
            ),
          ],
        ),
      ),
    );
  }

  static void _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  static String _formatAll(ContentItem i) =>
      'Platform: ${i.platform}\nTitle: ${i.title}\nDescription: ${i.description}\nScript:\n${i.script}\nHashtags: ${i.hashtags.join(' ')}\nTips: ${i.tips}\nScheduled: ${i.scheduledAt.toIso8601String()}';
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.platform, required this.accent});
  final String platform;
  final Color accent;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(_platformAsset(platform), width: 42, height: 42, fit: BoxFit.cover),
        ),
        const SizedBox(width: 10),
        Text(platform, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.accent, required this.content, required this.onCopy});
  final String title;
  final Color accent;
  final String content;
  final VoidCallback onCopy;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(0, 8))],
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(color: Colors.white.withValues(alpha: .65), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
                ),
                _CopyIconButton(accent: accent, onTap: onCopy),
              ],
            ),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(color: Color(0xFFEAEAEA), height: 1.35)),
          ],
        ),
      ),
    );
  }
}

class _HashtagsCard extends StatelessWidget {
  const _HashtagsCard({required this.hashtags, required this.accent, required this.onCopy});
  final List<String> hashtags;
  final Color accent;
  final VoidCallback onCopy;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(0, 8))],
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Hashtags'.toUpperCase(),
                    style: TextStyle(color: Colors.white.withValues(alpha: .65), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
                ),
                _CopyIconButton(accent: accent, onTap: onCopy),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in hashtags)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent.withValues(alpha: .4)),
                    ),
                    child: Text(tag, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyIconButton extends StatefulWidget {
  const _CopyIconButton({required this.accent, required this.onTap});
  final Color accent;
  final VoidCallback onTap;
  @override
  State<_CopyIconButton> createState() => _CopyIconButtonState();
}

class _CopyIconButtonState extends State<_CopyIconButton> {
  bool _hovered = false;
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              if (_hovered) BoxShadow(color: widget.accent.withValues(alpha: .3), blurRadius: 12, spreadRadius: 1),
              if (_pressed) const BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Icon(Icons.copy_rounded, size: 18, color: Colors.white.withValues(alpha: .9)),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({required this.onPressed, required this.child});
  final VoidCallback? onPressed;
  final Widget child;
  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hovered = false;
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFF00D4FF)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            color: enabled ? null : Colors.white12,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (_hovered) const BoxShadow(color: Color(0x8027272F), blurRadius: 18, offset: Offset(0, 8)),
              if (_pressed) const BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          transform: Matrix4.identity()..translate(0.0, _pressed ? 2.0 : 0.0),
          child: DefaultTextStyle.merge(style: const TextStyle(fontWeight: FontWeight.w600), child: widget.child),
        ),
      ),
    );
  }
}

String _platformAsset(String p) {
  switch (p) {
    case 'LinkedIn':
      return 'assets/img/linkedin.png';
    case 'X':
      return 'assets/img/x.png';
    case 'Instagram':
      return 'assets/img/instagram.jpeg';
    case 'TikTok':
      return 'assets/img/tiktok.png';
    case 'YouTube':
      return 'assets/img/youtube.png';
    case 'Facebook':
      return 'assets/img/facebook.png';
    default:
      return 'assets/img/ideaxy_logo_only.png';
  }
}

Color _platformBrandColor(String p) {
  switch (p) {
    case 'LinkedIn':
      return const Color(0xFF0077B5);
    case 'X':
      return const Color(0xFF1DA1F2);
    case 'Instagram':
      return const Color(0xFFE1306C);
    case 'TikTok':
      return const Color(0xFF69C9D0);
    case 'YouTube':
      return const Color(0xFFFF0000);
    default:
      return const Color(0xFF7C4DFF);
  }
}


