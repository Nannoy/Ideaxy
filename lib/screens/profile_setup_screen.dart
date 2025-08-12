import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/supabase_auth_service.dart';
import '../services/profile_service.dart';
import '../widgets/full_screen_loader.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  // Name/Handle reserved for future profile fields
  final _profile = ProfileService();
  Map<String, dynamic>? _profileData;
  bool _loading = true;
  String _displayName = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    // Start loading immediately after first frame to ensure Overlay is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  Future<void> _loadInitial() async {
    AppLoaderOverlay.show(context);
    await _load();
    if (!mounted) return;
    AppLoaderOverlay.hide();
  }

  @override
  Widget build(BuildContext context) {
    final auth = SupabaseAuthService();
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Profile setup', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfilePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionHeader(text: 'Profile Info'),
                      const SizedBox(height: 12),
                      _HeaderCard(name: _displayName, email: _email),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _ProfilePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionHeader(text: 'Niches'),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'Niches',
                        subtitle: 'Pick the topics you create for',
                        values: _listFrom(_profileData?['niches']),
                        icon: Icons.category_outlined,
                        onTap: () async {
                          final updated = await context.push<bool>('/onboarding/niche?edit=1');
                          if (updated == true) _refreshProfile();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _ProfilePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionHeader(text: 'Platforms'),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'Platforms',
                        subtitle: 'Select where we’ll generate and schedule',
                        values: _listFrom(_profileData?['platforms']),
                        icon: Icons.apps_rounded,
                        onTap: () async {
                          final updated = await context.push<bool>('/onboarding/platforms?edit=1');
                          if (updated == true) _refreshProfile();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _ProfilePrimaryButton(
                  onPressed: () async {
                    // Use GoRouter for navigation (MaterialApp.router)
                    final router = GoRouter.of(context);
                    AppLoaderOverlay.show(context);
                    try {
                      await auth.signOut();
                    } catch (e) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Logout failed: $e')),
                        );
                      });
                    } finally {
                      router.go('/auth');
                      WidgetsBinding.instance.addPostFrameCallback((_) => AppLoaderOverlay.hide());
                    }
                  },
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
          // Full-screen loader handled by AppLoaderOverlay
        ],
      ),
    );
  }

  Future<void> _load() async {
    if (!_loading) return;
    final auth = SupabaseAuthService();
    final user = auth.currentUser;
    if (user != null) {
      _profileData = await _profile.fetchProfile(user.id);
      _email = user.email ?? '';
      _displayName = (user.userMetadata?['full_name'] as String?) ??
          (user.userMetadata?['name'] as String?) ??
          (_email.isNotEmpty ? _email.split('@').first : 'Creator');
    }
    _loading = false;
    setState(() {});
  }

  Future<void> _refreshProfile() async {
    final auth = SupabaseAuthService();
    final user = auth.currentUser;
    if (user == null) return;
    AppLoaderOverlay.show(context);
    try {
      _profileData = await _profile.fetchProfile(user.id);
      setState(() {});
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) => AppLoaderOverlay.hide());
    }
  }

  List<String> _listFrom(dynamic v) =>
      ((v as List?)?.cast<dynamic>() ?? const []).map((e) => e.toString()).toList();
}

class _SectionCard extends StatefulWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.values,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final List<String> values;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
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
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF14141A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _hovered ? Colors.white24 : const Color(0xFF2A2A35)),
            boxShadow: [
              if (_hovered) const BoxShadow(color: Color(0x1FFFFFFF), blurRadius: 8, offset: Offset(0, 6)),
              if (_pressed) const BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF00D4FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(widget.icon, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(widget.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 10),
              _ValuesWrap(values: widget.values),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValuesWrap extends StatelessWidget {
  const _ValuesWrap({required this.values});
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Text('Not set', style: TextStyle(color: Colors.white70));
    }
    const maxToShow = 8;
    final show = values.take(maxToShow).toList();
    final remaining = values.length - show.length;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in show)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(v, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        if (remaining > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white30),
            ),
            child: Text('+$remaining more', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.name, required this.email});
  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14141A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A35)),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 14, offset: Offset(0, 8))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: const AssetImage('assets/img/profile.jpeg'),
            backgroundColor: Colors.transparent,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hey, $name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
        ),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 12))],
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: .65),
        fontSize: 12,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _ProfilePrimaryButton extends StatefulWidget {
  const _ProfilePrimaryButton({required this.onPressed, required this.child});
  final VoidCallback? onPressed;
  final Widget child;
  @override
  State<_ProfilePrimaryButton> createState() => _ProfilePrimaryButtonState();
}

class _ProfilePrimaryButtonState extends State<_ProfilePrimaryButton> {
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
                ? const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF00D4FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
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

