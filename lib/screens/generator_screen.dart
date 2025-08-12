import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/content_models.dart';
import '../services/gemini_service.dart';

import '../widgets/full_screen_loader.dart';
import '../services/profile_service.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  final _nicheController = TextEditingController(text: 'Tech');
  final Set<String> _platforms = {'LinkedIn', 'X', 'Instagram'};
  final _profileService = ProfileService();
  List<String> _availableNiches = [];
  List<String> _availablePlatforms = [];
  String? _selectedNiche;
  bool _loadingProfile = true;
  final ContentScheduleType _type = ContentScheduleType.instant;
  ContentPlan? _plan;
  bool _isLoading = false;
  String? _error;

  final _gemini = GeminiService();

  @override
  void initState() {
    super.initState();
    _loadProfileSelections();
  }

  Future<void> _loadProfileSelections() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await _profileService.fetchProfile(user.id);
        final nichesDyn = (profile?['niches'] as List?)?.cast<dynamic>() ?? const [];
        final platformsDyn = (profile?['platforms'] as List?)?.cast<dynamic>() ?? const [];
        _availableNiches = nichesDyn.map((e) => e.toString()).toList();
        _availablePlatforms = platformsDyn.map((e) => e.toString()).toList();
        if (_availableNiches.isNotEmpty) {
          _selectedNiche = _availableNiches.first;
          _nicheController.text = _selectedNiche!;
        }
        if (_availablePlatforms.isNotEmpty) {
          // Only set platforms if they haven't been manually selected yet
          if (_platforms.isEmpty || _platforms.length == 3 && _platforms.containsAll({'LinkedIn', 'X', 'Instagram'})) {
            _platforms
              ..clear()
              ..addAll(_availablePlatforms);
          }
        }
      }
    } catch (_) {
      // keep defaults on failure
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
      // No overlay here to avoid double loaders right after login
    }
  }

  Future<void> _generate() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _plan = null;
    });
    AppLoaderOverlay.show(context);
    try {
      final selectedPlatforms = _platforms.toList();
      debugPrint('Generating content for platforms: $selectedPlatforms');
      final plan = await _gemini.generatePlan(
        niche: (_selectedNiche ?? _nicheController.text.trim()),
        platforms: selectedPlatforms,
        scheduleType: _type,
      );
      setState(() => _plan = plan);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
      AppLoaderOverlay.hide();
    }
  }



  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFF7C4DFF), Color(0xFF00D4FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Generate content', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        actions: [
          _GlowingAvatar(
            onTap: () async {
              await context.push('/profile');
              // Don't reload profile selections to preserve user's current platform selection
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Loading indicator handled by FullScreenLoader overlay
            if (_loadingProfile) const SizedBox.shrink(),

            const SizedBox(height: 8),
            _FilterPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FilterSection(
                    title: 'Niche',
                    child: _HorizontalFilterRow(
                      options: (_availableNiches.isNotEmpty
                          ? _availableNiches
                          : const ['Tech', 'Fitness', 'Fashion', 'Entertainment', 'Education', 'Business']),
                      itemBuilder: (label) => _PillButton(
                        label: label,
                        icon: _nicheIcon(label),
                        selected: _selectedNiche == label,
                        onTap: () => setState(() {
                          _selectedNiche = label;
                          _nicheController.text = label;
                        }),
                      ),
                    ),
                  ),
                  SizedBox(height: 10,),
                  _FilterSection(
                    title: 'Platforms',
                    child: _HorizontalFilterRow(
                      options: (_availablePlatforms.isNotEmpty
                          ? _availablePlatforms
                          : const ['LinkedIn', 'X', 'Instagram', 'TikTok', 'YouTube']),
                      itemBuilder: (p) => _PillButton(
                        label: p,
                        icon: _platformLogo(p),
                        accent: _platformBrandColor(p),
                        selected: _platforms.contains(p),
                        onTap: () {
                          setState(() {
                            if (_platforms.contains(p)) {
                              _platforms.remove(p);
                              debugPrint('Removed platform: $p. Current platforms: $_platforms');
                            } else {
                              _platforms.add(p);
                              debugPrint('Added platform: $p. Current platforms: $_platforms');
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // Actions
            _GradientButton(
              gradient: gradient,
              onPressed: _isLoading ? null : _generate,
              child: const Text('Generate'),
            ),
            const SizedBox(height: 16),
            if (_error != null) _ErrorNotice(message: _error!),
            const SizedBox(height: 8),
            Expanded(
              child: _plan == null
                  ? Center(
                      child: Text(
                        'No content yet',
                        style: TextStyle(color: Colors.white.withValues(alpha: .5), fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _plan!.items.length,
                      itemBuilder: (context, index) {
                        final item = _plan!.items[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, (1 - value) * 12),
                                child: child,
                              ),
                            );
                          },
                          child: _Stagger(
                            index: index,
                            child: _GlassCard(
                              item: item,
                              onTap: () => context.push('/content/details', extra: item),
                              compact: true,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// UI Widgets and helpers

class _GlowingAvatar extends StatefulWidget {
  const _GlowingAvatar({required this.onTap});
  final VoidCallback onTap;
  @override
  State<_GlowingAvatar> createState() => _GlowingAvatarState();
}

class _GlowingAvatarState extends State<_GlowingAvatar> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            if (_pressed)
              BoxShadow(color: const Color(0xFF7C4DFF).withValues(alpha: .35), blurRadius: 22, spreadRadius: 1),
          ],
        ),
        child: const CircleAvatar(
          radius: 16,
          backgroundImage: AssetImage('assets/img/profile.jpeg'),
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}

// Legacy field retained earlier is no longer used; removed for clarity.

// (Deprecated segmented control kept here as reference; replaced by _DaysChips)

class _SegmentButton extends StatefulWidget {
  const _SegmentButton({required this.selected, required this.label, required this.onTap});
  final bool selected;
  final String label;
  final VoidCallback onTap;
  @override
  State<_SegmentButton> createState() => _SegmentButtonState();
}

class _SegmentButtonState extends State<_SegmentButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: selected ? const Color(0xFF1E1E26) : Colors.transparent,
            boxShadow: [
              if (selected) BoxShadow(color: const Color(0xFF7C4DFF).withValues(alpha: .25), blurRadius: 16, spreadRadius: 1),
              if (_hovered) const BoxShadow(color: Color(0x1FFFFFFF), blurRadius: 6),
            ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

// Legacy days control no longer used; replaced by pill buttons.

// Legacy single-select chips replaced by pill buttons row.

class _SingleChip extends StatefulWidget {
  const _SingleChip({required this.text, required this.selected, required this.onTap});
  final String text;
  final bool selected;
  final VoidCallback onTap;
  @override
  State<_SingleChip> createState() => _SingleChipState();
}

class _SingleChipState extends State<_SingleChip> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF14141A),
            border: Border.all(color: selected ? const Color(0xFF7C4DFF) : Colors.white24),
            boxShadow: [
              if (selected) const BoxShadow(color: Color(0x407C4DFF), blurRadius: 16, spreadRadius: 1),
              if (_hovered) const BoxShadow(color: Color(0x1FFFFFFF), blurRadius: 6),
            ],
          ),
          child: Text(widget.text, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
        ),
      ),
    );
  }
}

class _PlatformChip extends StatefulWidget {
  const _PlatformChip({required this.platform, required this.selected, required this.onSelected});
  final String platform;
  final bool selected;
  final ValueChanged<bool> onSelected;
  @override
  State<_PlatformChip> createState() => _PlatformChipState();
}

class _PlatformChipState extends State<_PlatformChip> {
  static const Map<String, Color> brand = {
    'LinkedIn': Color(0xFF0077B5),
    'X': Color(0xFF1DA1F2),
    'Instagram': Color(0xFFE1306C),
    'TikTok': Color(0xFF69C9D0),
    'YouTube': Color(0xFFFF0000),
  };
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final base = brand[widget.platform] ?? const Color(0xFF7C4DFF);
    final bg = const Color(0xFF14141A);
    final selected = widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.onSelected(!selected),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: base.withValues(alpha: selected ? .55 : .25)),
            boxShadow: [
              if (selected) BoxShadow(color: base.withValues(alpha: .25), blurRadius: 16, spreadRadius: 1),
              if (_hovered) BoxShadow(color: base.withValues(alpha: .15), blurRadius: 12, spreadRadius: 1),
            ],
          ),
          child: Text(
            widget.platform,
            style: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatefulWidget {
  const _GradientButton({required this.onPressed, required this.child, required this.gradient});
  final VoidCallback? onPressed;
  final Widget child;
  final Gradient gradient;

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
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
            gradient: enabled ? widget.gradient : null,
            color: enabled ? null : Colors.white12,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (_hovered) const BoxShadow(color: Color(0x8027272F), blurRadius: 18, offset: Offset(0, 8)),
              if (_pressed) const BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          transform: Matrix4.identity()..translate(0.0, _pressed ? 2.0 : 0.0),
          child: DefaultTextStyle.merge(
            style: const TextStyle(fontWeight: FontWeight.w600),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _OutlinedSoftButton extends StatefulWidget {
  const _OutlinedSoftButton({required this.onPressed, required this.child});
  final VoidCallback? onPressed;
  final Widget child;
  @override
  State<_OutlinedSoftButton> createState() => _OutlinedSoftButtonState();
}

class _OutlinedSoftButtonState extends State<_OutlinedSoftButton> {
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: enabled ? Colors.white24 : Colors.white12),
            color: _hovered ? Colors.white.withValues(alpha: 0.02) : Colors.transparent,
            boxShadow: [
              if (_pressed) const BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          transform: Matrix4.identity()..translate(0.0, _pressed ? 2.0 : 0.0),
          child: DefaultTextStyle.merge(
            style: const TextStyle(fontWeight: FontWeight.w600),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.item, this.onTap, this.compact = false});
  final ContentItem item;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF7C4DFF);
    final date = DateFormat.yMMMd().add_Hm().format(item.scheduledAt);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${item.platform.toUpperCase()}  •  $date',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.2,
            color: accent.withValues(alpha: .85),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        if (compact)
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70),
          )
        else
          Text(item.description, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final tag in item.hashtags.take(compact ? 4 : item.hashtags.length))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(tag, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            if (compact && item.hashtags.length > 4)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text('+${item.hashtags.length - 4}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
          ],
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x14FFFFFF)),
            boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 16, offset: Offset(0, 10))],
          ),
          child: Padding(padding: const EdgeInsets.all(14.0), child: content),
        ),
      ),
    );
  }
}

// Modern filter UI helpers
class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: .65),
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 12)),
        ],
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: child,
    );
  }
}

class _HorizontalFilterRow extends StatelessWidget {
  const _HorizontalFilterRow({required this.options, required this.itemBuilder});
  final List<String> options;
  final Widget Function(String) itemBuilder;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => itemBuilder(options[index]),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: options.length,
      ),
    );
  }
}

class _PillButton extends StatefulWidget {
  const _PillButton({required this.label, this.icon, required this.selected, required this.onTap, this.accent});
  final String label;
  final Widget? icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? accent;
  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> {
  bool _hovered = false;
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final accent = widget.accent ?? const Color(0xFF7C4DFF);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: selected
                ? const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFF00D4FF)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            color: selected ? null : const Color(0xFF14141A),
            border: Border.all(color: accentedBorderColor(accent, selected)),
            boxShadow: [
              if (_hovered) const BoxShadow(color: Color(0x2827272F), blurRadius: 12, offset: Offset(0, 6)),
              if (_pressed) const BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          transform: Matrix4.identity()..translate(0.0, _pressed ? 1.5 : 0.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                SizedBox(width: 16, height: 16, child: widget.icon!),
                const SizedBox(width: 6),
              ],
              Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Color accentedBorderColor(Color accent, bool selected) => selected ? Colors.transparent : accent.withValues(alpha: .35);
}

Widget _platformLogo(String p, {double size = 16}) {
  String? asset;
  switch (p) {
    case 'LinkedIn':
      asset = 'assets/img/linkedin.png';
      break;
    case 'X':
      asset = 'assets/img/x.png';
      break;
    case 'Instagram':
      asset = 'assets/img/instagram.jpeg';
      break;
    case 'TikTok':
      asset = 'assets/img/tiktok.png';
      break;
    case 'YouTube':
      asset = 'assets/img/youtube.png';
      break;
    case 'Facebook':
      asset = 'assets/img/facebook.png';
      break;
  }
  if (asset == null) return const SizedBox();
  return ClipRRect(
    borderRadius: BorderRadius.circular(size / 6),
    child: Image.asset(asset, width: size, height: size, fit: BoxFit.cover),
  );
}

Icon _nicheIcon(String label) {
  final lower = label.toLowerCase();
  if (lower.contains('tech')) return const Icon(Icons.laptop_mac_rounded, size: 16);
  if (lower.contains('fit')) return const Icon(Icons.sports_gymnastics_rounded, size: 16);
  if (lower.contains('fashion')) return const Icon(Icons.checkroom_outlined, size: 16);
  if (lower.contains('business')) return const Icon(Icons.business_center_outlined, size: 16);
  if (lower.contains('education')) return const Icon(Icons.school_outlined, size: 16);
  if (lower.contains('design')) return const Icon(Icons.brush_outlined, size: 16);
  return const Icon(Icons.category_outlined, size: 16);
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

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x26FF4D4D),
        border: Border.all(color: const Color(0x4DFF4D4D)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x1AFF4D4D), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF7070)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFFFB3B3)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stagger extends StatefulWidget {
  const _Stagger({required this.child, required this.index});
  final Widget child;
  final int index;
  @override
  State<_Stagger> createState() => _StaggerState();
}

class _StaggerState extends State<_Stagger> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1));
    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

