import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/profile_service.dart';
import '../../widgets/full_screen_loader.dart';

class SelectNicheScreen extends StatefulWidget {
  const SelectNicheScreen({super.key, this.isEdit = false});
  final bool isEdit;

  @override
  State<SelectNicheScreen> createState() => _SelectNicheScreenState();
}

class _SelectNicheScreenState extends State<SelectNicheScreen> {
  static const _allNiches = [
    ['💻', 'Tech'],
    ['🏋️', 'Fitness'],
    ['👗', 'Fashion'],
    ['🎬', 'Entertainment'],
    ['📚', 'Education'],
    ['🍳', 'Food'],
    ['✈️', 'Travel'],
    ['💼', 'Business'],
    ['🎨', 'Design'],
    ['📈', 'Marketing'],
    ['🧠', 'Self-Improvement'],
    ['🧪', 'Science'],
  ];
  final Set<String> _selected = {};
  bool _saving = false;
  final _service = ProfileService();

  Future<void> _saveAndContinue() async {
    if (_selected.isEmpty) return;
    setState(() => _saving = true);
    AppLoaderOverlay.show(context);
    try {
      await _service.upsertNiches(_selected.toList());
      if (!mounted) return;
      if (widget.isEdit) {
        context.pop(true);
      } else {
        context.go('/onboarding/platforms');
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
      final niches = (profile?['niches'] as List?)?.cast<dynamic>() ?? const [];
      setState(() => _selected.addAll(niches.map((e) => e.toString())));
    } catch (_) {}
  }

  // Removed local overlay loader in favor of global AppLoaderOverlay

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Niches' : 'Step 1 of 2'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Select Your Niche', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Choose up to 6 topics you want to create content for.', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${_selected.length}/6 selected', style: const TextStyle(color: Colors.white60)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: _allNiches.length,
                itemBuilder: (context, index) {
                  final emoji = _allNiches[index][0];
                  final label = _allNiches[index][1];
                  final selected = _selected.contains(label);
                  return _NicheCard(
                    emoji: emoji,
                    label: label,
                    selected: selected,
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selected.remove(label);
                        } else if (_selected.length < 6) {
                          _selected.add(label);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _GradientButton(
              onPressed: _saving || _selected.isEmpty ? null : _saveAndContinue,
              child: Text(widget.isEdit ? 'Update' : 'Continue'),
            )
          ],
        ),
      ),
    );
  }
}

class _NicheCard extends StatefulWidget {
  const _NicheCard({required this.emoji, required this.label, required this.selected, required this.onTap});
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NicheCard> createState() => _NicheCardState();
}

class _NicheCardState extends State<_NicheCard> {
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
          decoration: BoxDecoration(
            color: const Color(0xFF18181F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? const Color(0xFF7C4DFF) : const Color(0xFF2A2A35),
              width: selected ? 1.4 : 1.0,
            ),
            boxShadow: [
              if (selected) const BoxShadow(color: Color(0x407C4DFF), blurRadius: 18, spreadRadius: 1),
              if (_hovered) const BoxShadow(color: Color(0x20000000), blurRadius: 12),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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


