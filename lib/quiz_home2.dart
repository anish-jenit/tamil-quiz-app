import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizHome2 extends StatefulWidget {
  const QuizHome2({super.key});

  @override
  State<QuizHome2> createState() => _QuizHome2State();
}

class _QuizHome2State extends State<QuizHome2> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<Offset> _slideIn;

  String? _userDisplayNameFrom(User? u) => u?.displayName;
  String? _userEmailFrom(User? u) => u?.email;
  String? _userPhotoUrlFrom(User? u) => u?.photoURL;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary.withAlpha((0.90 * 255).round()),
                  cs.primary.withAlpha((0.70 * 255).round()),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SlideTransition(
                          position: _slideIn,
                          child: Text(
                            'தமிழ் வினாடி வினா',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withAlpha((0.25 * 255).round()),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedOpacity(
                          opacity: 1,
                          duration: const Duration(milliseconds: 600),
                          child: Text(
                            'உங்கள் அறிவை சோதிப்போம்!',
                            style: TextStyle(
                              color: Colors.white.withAlpha((0.85 * 255).round()),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 28),

                        AnimatedBuilder(
                          animation: _ac,
                          builder: (context, child) => Transform.scale(
                            scale: 0.98 + 0.02 * _ac.value,
                            child: Card(
                              elevation: 10,
                              shadowColor: Colors.black.withAlpha((0.25 * 255).round()),
                              color: cs.surface.withAlpha((0.96 * 255).round()),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: cs.primary.withAlpha((0.15 * 255).round()),
                                          backgroundImage: _userPhotoUrlFrom(user) != null
                                              ? NetworkImage(_userPhotoUrlFrom(user)!)
                                              : null,
                                          child: _userPhotoUrlFrom(user) == null
                                              ? Icon(Icons.person, color: cs.primary)
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _userDisplayNameFrom(user)?.trim().isNotEmpty == true
                                                    ? _userDisplayNameFrom(user)!
                                                    : (_userEmailFrom(user) ?? 'Guest'),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: cs.onSurface,
                                                ),
                                              ),
                                              Text(
                                                'வரவேற்பு!',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: cs.onSurface.withAlpha((0.7 * 255).round()),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Sign out',
                                          onPressed: _signOut,
                                          icon: Icon(Icons.logout_rounded, color: cs.primary),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 20),

                                    // Kahoot-like primary action buttons
                                    SizedBox(
                                      height: 56,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () => Navigator.of(context).pushNamed('/level-select', arguments: {'mode': 'solo'}),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFFFC107), // bright amber
                                                foregroundColor: Colors.black,
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              child: const Text('Play Solo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () => Navigator.of(context).pushNamed('/create-group'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF4CAF50), // green
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              child: const Text('Create Group', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 48,
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.of(context).pushNamed('/join-group'),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: cs.onSurface.withAlpha((0.12 * 255).round())),
                                          foregroundColor: cs.onSurface,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Text('Join Group', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),
                        Text(
                          'Made with Flutter',
                          style: TextStyle(
                            color: Colors.white.withAlpha((0.75 * 255).round()),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
