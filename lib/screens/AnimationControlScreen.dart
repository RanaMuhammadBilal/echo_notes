import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../provider_notes.dart';

class AnimationControlScreen extends StatelessWidget {
  const AnimationControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Animation Control Center',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Master Animation Switch Card
          Card(
            elevation: 0,
            color: notesProvider.enableAnimations
                ? colorScheme.primaryContainer.withAlpha(120)
                : colorScheme.surfaceContainerHighest.withAlpha(80),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: SwitchListTile.adaptive(
                secondary: AnimatedRotation(
                  turns: notesProvider.enableAnimations ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: notesProvider.enableAnimations
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: 28,
                  ),
                ),
                value: notesProvider.enableAnimations,
                onChanged: (_) {
                  HapticFeedback.mediumImpact();
                  notesProvider.toggleAnimations();
                },
                title: const Text(
                  'Master Animations Switch',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  notesProvider.enableAnimations
                      ? 'All micro-interactions & transitions enabled'
                      : 'All app animations paused for max performance',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'FINE-GRAINED ANIMATION CONTROLS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),

          // Individual Animation Switches Container
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withAlpha(80),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildAnimationToggleTile(
                  context,
                  title: 'Card Entrance Animations',
                  subtitle: 'Staggered slide & spring entry for note cards',
                  icon: Icons.view_stream_rounded,
                  value: notesProvider.enableCardAnimations,
                  enabled: notesProvider.enableAnimations,
                  onChanged: (_) => notesProvider.toggleCardAnimations(),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildAnimationToggleTile(
                  context,
                  title: 'Category Chip Scaling & Spring',
                  subtitle: 'Elastic tactile scaling on active category chips',
                  icon: Icons.label_rounded,
                  value: notesProvider.enableChipAnimations,
                  enabled: notesProvider.enableAnimations,
                  onChanged: (_) => notesProvider.toggleChipAnimations(),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildAnimationToggleTile(
                  context,
                  title: 'Hero & Page Transitions',
                  subtitle: 'Fluid hero expansion and page slide transitions',
                  icon: Icons.transform_rounded,
                  value: notesProvider.enableHeroTransitions,
                  enabled: notesProvider.enableAnimations,
                  onChanged: (_) => notesProvider.toggleHeroTransitions(),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildAnimationToggleTile(
                  context,
                  title: 'Grid / List Layout Motion',
                  subtitle:
                      'Smooth layout morphing when toggling Grid & List view',
                  icon: Icons.grid_view_rounded,
                  value: notesProvider.enableGridAnimations,
                  enabled: notesProvider.enableAnimations,
                  onChanged: (_) => notesProvider.toggleGridAnimations(),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildAnimationToggleTile(
                  context,
                  title: 'Tactile Button Spring Bounce',
                  subtitle:
                      'Duolingo-style spring press feedback on buttons & cards',
                  icon: Icons.touch_app_rounded,
                  value: notesProvider.enableButtonBounce,
                  enabled: notesProvider.enableAnimations,
                  onChanged: (_) => notesProvider.toggleButtonBounce(),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildAnimationToggleTile(
                  context,
                  title: 'Floating FAB Pulse',
                  subtitle: 'Animated floating pulse effect on Create FAB',
                  icon: Icons.add_circle_outline_rounded,
                  value: notesProvider.enableFabPulse,
                  enabled: notesProvider.enableAnimations,
                  onChanged: (_) => notesProvider.toggleFabPulse(),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildAnimationToggleTile(
                  context,
                  title: 'Glassmorphic Blur Effects',
                  subtitle: 'Frosted glass backdrop on AppBars & toolbars',
                  icon: Icons.blur_on_rounded,
                  value: notesProvider.enableGlassmorphism,
                  enabled: true, // Always allowed independently
                  onChanged: (_) => notesProvider.toggleGlassmorphism(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimationToggleTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: SwitchListTile.adaptive(
        secondary: Icon(
          icon,
          color: value && enabled
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
        value: value && enabled,
        onChanged: enabled ? onChanged : null,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
