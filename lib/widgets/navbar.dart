import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class Navbar extends StatelessWidget implements PreferredSizeWidget {
  final Function(int) onNavItemTap;
  final VoidCallback? onReserveTap;
  final int activeIndex;

  const Navbar({
    super.key,
    required this.onNavItemTap,
    this.onReserveTap,
    required this.activeIndex,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80.0);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 1000;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          height: 80,
          width: double.infinity,
          decoration: BoxDecoration(
            color: HotelColors.white.withOpacity(0.8),
            border: const Border(
              bottom: BorderSide(
                color: Color(0x221B3B22),
                width: 1.0,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo/Branding
              GestureDetector(
                onTap: () => onNavItemTap(0),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: HotelColors.primaryGreen,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: const Icon(
                          Icons.nature_people_rounded,
                          color: HotelColors.accentGold,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'HOTEL FAZENDA',
                            style: HotelTypography.cardSubtitle.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: HotelColors.accentGold,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            'Raposo',
                            style: HotelTypography.cardTitle.copyWith(
                              fontSize: 24,
                              color: HotelColors.primaryGreen,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Navigation Links (Desktop)
              if (!isMobile)
                Row(
                  children: [
                    _NavbarItem(
                      label: 'O Hotel',
                      isActive: activeIndex == 1,
                      onTap: () => onNavItemTap(1),
                    ),
                    _NavbarItem(
                      label: 'Acomodações',
                      isActive: activeIndex == 2,
                      onTap: () => onNavItemTap(2),
                    ),
                    _NavbarItem(
                      label: 'Água Mineral',
                      isActive: activeIndex == 3,
                      onTap: () => onNavItemTap(3),
                    ),
                    _NavbarItem(
                      label: 'Lazer',
                      isActive: activeIndex == 4,
                      onTap: () => onNavItemTap(4),
                    ),
                    _NavbarItem(
                      label: 'Galeria',
                      isActive: activeIndex == 5,
                      onTap: () => onNavItemTap(5),
                    ),
                    _NavbarItem(
                      label: 'Eventos',
                      isActive: activeIndex == 6,
                      onTap: () => onNavItemTap(6),
                    ),
                    _NavbarItem(
                      label: 'Contato',
                      isActive: activeIndex == 7,
                      onTap: () => onNavItemTap(7),
                    ),
                  ],
                ),

              // CTA / Reserva Button
              Row(
                children: [
                  if (!isMobile)
                    ElevatedButton(
                      onPressed: onReserveTap ?? () => onNavItemTap(2),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HotelColors.primaryGreen,
                        foregroundColor: HotelColors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: Text(
                        'Reserve Agora',
                        style: HotelTypography.buttonText.copyWith(
                          color: HotelColors.white,
                        ),
                      ),
                    ),
                  if (isMobile) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: HotelColors.primaryGreen,
                        size: 28,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavbarItem extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavbarItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavbarItem> createState() => _NavbarItemState();
}

class _NavbarItemState extends State<_NavbarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: HotelTypography.navItem.copyWith(
                  color: widget.isActive || _isHovered
                      ? HotelColors.accentGold
                      : HotelColors.primaryGreen,
                  fontWeight: widget.isActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              // Underline animado
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2.0,
                width: widget.isActive ? 20.0 : (_isHovered ? 12.0 : 0.0),
                decoration: BoxDecoration(
                  color: HotelColors.accentGold,
                  borderRadius: BorderRadius.circular(1.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
