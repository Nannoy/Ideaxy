import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/profile_service.dart';
import '../../widgets/full_screen_loader.dart';

class SelectPlatformsScreen extends StatefulWidget {
  const SelectPlatformsScreen({super.key, this.isEdit = false});
  final bool isEdit;

  @override
  State<SelectPlatformsScreen> createState() => _SelectPlatformsScreenState();
}

class _SelectPlatformsScreenState extends State<SelectPlatformsScreen> {
  static const _platforms = [
    'LinkedIn', 'X', 'Instagram', 'TikTok', 'YouTube', 'Facebook'
  ];
  static const Map<String, Color> _brand = {
    'LinkedIn': Color(0xFF0077B5),
    'X': Color(0xFF1DA1F2),
    'Instagram': Color(0xFFE1306C),
    'TikTok': Color(0xFF69C9D0),
    'YouTube': Color(0xFFFF0000),
    'Facebook': Color(0xFF1877F2),
  };
  final Set<String> _selected = {};
  bool _saving = false;
  final _service = ProfileService();

  Future<void> _finish() async {
    if (_selected.isEmpty) return;
    setState(() => _saving = true);
    AppLoaderOverlay.show(context);
    try {
      await _service.upsertPlatforms(_selected.toList());
      if (!mounted) return;
      if (widget.isEdit) {
        context.pop(true);
      } else {
        context.go('/generate');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => AppLoaderOverlay.hide());
    }
  }

  @override
  void initState() {
    super.initState();
    _prefillIfEditing();
  }

  Future<void> _prefillIfEditing() async {
    if (!widget.isEdit) return;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final profile = await _service.fetchProfile(user.id);
      final platforms = (profile?['platforms'] as List?)?.cast<dynamic>() ?? const [];
      setState(() => _selected.addAll(platforms.map((e) => e.toString())));
    } catch (_) {}
  }

  // Removed local overlay loader in favor of global AppLoaderOverlay

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? 'Edit Platforms' : 'Select Platforms'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Choose the platforms you create for. You can update this anytime.', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final p in _platforms)
                  _PlatformPill(
                    label: p,
                    color: _brand[p]!,
                    selected: _selected.contains(p),
                    onTap: () {
                      setState(() {
                        if (_selected.contains(p)) {
                          _selected.remove(p);
                        } else {
                          _selected.add(p);
                        }
                      });
                    },
                  ),
              ],
            ),
            const Spacer(),
            _GradientButton(
              onPressed: _saving || _selected.isEmpty ? null : _finish,
              child: Text(widget.isEdit ? 'Update' : 'Finish Setup'),
            )
          ],
        ),
      ),
    );
  }
}

class _PlatformPill extends StatefulWidget {
  const _PlatformPill({required this.label, required this.color, required this.selected, required this.onTap});
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PlatformPill> createState() => _PlatformPillState();
}

class _PlatformPillState extends State<_PlatformPill> with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 160));

  @override
  void didUpdateWidget(covariant _PlatformPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      widget.selected ? _controller.forward(from: 0) : _controller.reverse(from: 1);
    }
  }

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: selected ? widget.color.withValues(alpha: 0.08) : const Color(0xFF14141A),
            border: Border.all(color: widget.color.withValues(alpha: selected ? .6 : .25)),
            boxShadow: [
              if (selected) BoxShadow(color: widget.color.withValues(alpha: .25), blurRadius: 16, spreadRadius: 1),
              if (_hovered) BoxShadow(color: widget.color.withValues(alpha: .12), blurRadius: 12, spreadRadius: 1),
            ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(color: Colors.white, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.onPressed, required this.child});
  final VoidCallback? onPressed;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: enabled ? 1 : .6,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: enabled
                ? const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFF00D4FF)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            color: enabled ? null : Colors.white12,
          ),
          child: DefaultTextStyle.merge(style: const TextStyle(fontWeight: FontWeight.w600), child: child),
        ),
      ),
    );
  }
}

// Removed local _OverlayLoader (using FullScreenLoader instead)


