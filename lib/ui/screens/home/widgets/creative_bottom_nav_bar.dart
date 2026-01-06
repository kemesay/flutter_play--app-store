import 'package:flutter/material.dart';

/// A creative, compact bottom navigation bar with smooth animations
/// and overflow-safe design
class CreativeBottomNavBar extends StatelessWidget {
  const CreativeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 0),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NavItem(
                icon: Icons.event_available_outlined,
                selectedIcon: Icons.event_available_rounded,
                label: 'Book',
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
                color: colorScheme.primary,
              ),
              _NavItem(
                icon: Icons.route_outlined,
                selectedIcon: Icons.route_rounded,
                label: 'Trips',
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
                color: colorScheme.primary,
              ),
              _NavItem(
                icon: Icons.support_agent_outlined,
                selectedIcon: Icons.support_agent,
                label: 'Support',
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
                color: colorScheme.primary,
              ),
              _NavItem(
                icon: Icons.account_circle_outlined,
                selectedIcon: Icons.account_circle_rounded,
                label: 'Account',
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.all(isSelected ? 5 : 3),
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isSelected ? selectedIcon : icon,
                      key: ValueKey(isSelected),
                      color: isSelected
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                      size: isSelected ? 21 : 20,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: isSelected ? color : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 9.5,
                    height: 1.1,
                    letterSpacing: 0.2,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
