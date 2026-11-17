import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tablescout/session/session_manager.dart';
import 'package:tablescout/pages/settings_page.dart';
import 'package:tablescout/pages/dashboard_page.dart';
import 'package:tablescout/pages/floor_planner_page.dart';
import 'package:tablescout/pages/events_page.dart';

import 'package:tablescout/pages/account_page.dart';
import 'package:tablescout/pages/staff_manage.dart';
import 'package:tablescout/pages/privacy_page.dart';
import 'package:tablescout/pages/password_manage_page.dart';
import 'package:tablescout/pages/cloud_page.dart';
import 'package:tablescout/pages/customise_page.dart';
import 'package:tablescout/pages/notifications_page.dart';
import 'package:tablescout/screen_dimensions.dart';
import 'package:tablescout/pages/contact_us_page.dart';
import 'package:tablescout/theme/app_colours.dart';
import 'package:tablescout/widgets/construction_tooltip.dart';
import 'package:tablescout/pages/floor_allocator_page.dart';

final GlobalKey _visibleLogoSectionKey = GlobalKey();

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  static const double _navExpandedWidth = 270;
  static const double _navCollapsedWidth = 55;

  int _selectedIndex = 0;

  bool _navOpen = true;
  bool _navInitialised = false;
  bool _logoHovered = false;

  final GlobalKey _logoSectionKey = GlobalKey();

  double _logoSectionHeight = 0;

  late final List<Widget> _pages = [
    DashboardPage(),
    const FloorAllocatorPage(),
    FloorPlanner(),
    EventsOverviewPage(),
    ContactUsPage(),
    //AccountPage(),
    SettingsPage(
      onNavigate: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    ),

    AccountPage(
      onNavigateToPassword: () {
        setState(() {
          _selectedIndex = 9;
        });
      },
    ),
    const StaffManagementPage(),
    const PrivacyPage(),
    const PasswordManagementPage(),
    const CloudPage(),
    const CustomisePage(),
    const NotificationsPage(),
  ];

  String _getInitials(String? username) {
    if (username == null || username.trim().isEmpty) {
      return '?';
    }

    final parts = username.trim().split(RegExp(r'\s+'));

    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }

    final name = parts.first;

    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_navInitialised) {
      // starts open on desktop
      //starts closed on mobile
      _navOpen = !ScreenDimensions.isMobile(context);

      _navInitialised = true;
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureLogoSection();
    });
  }

  void _measureLogoSection() {
    if (!mounted) return;

    final BuildContext? logoContext = _navOpen
        ? _visibleLogoSectionKey.currentContext
        : _logoSectionKey.currentContext;

    final renderObject = logoContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final newHeight = renderObject.size.height;

    if (newHeight != _logoSectionHeight) {
      setState(() {
        _logoSectionHeight = newHeight;
      });
    }
  }

  void _toggleNav() {
    setState(() {
      _navOpen = !_navOpen;
    });

    if (_navOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _measureLogoSection();
      });
    }
  }

  void _closeNav() {
    if (_navOpen) {
      setState(() {
        _navOpen = false;
      });
    }
  }

  void _signOut() {
    context.read<SessionManager>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenDimensions.isMobile(context)
          ? _buildMobileLayout()
          : _buildDesktopLayout(),
    );
  }

  //desktop specific

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        _buildNavBar(),

        Expanded(child: _buildPageContent()),
      ],
    );
  }

  //mobile specific

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        // page content uses full screen
        Positioned.fill(child: _buildPageContent()),

        //hidden logos so that maths can be done fo rthe hamburger
        Positioned(
          left: -_navExpandedWidth,
          top: 0,
          width: _navExpandedWidth,
          child: _buildLogoSection(key: _logoSectionKey),
        ),

        // tap outside nav to close when nav open
        if (_navOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeNav,
              child: Container(color: Colors.black.withValues(alpha: 0.25)),
            ),
          ),

        Positioned(top: 0, bottom: 0, left: 0, child: _buildNavBar()),
      ],
    );
  }

  // nav bar

  Widget _buildNavBar() {
    final sessionManager = context.watch<SessionManager>();

    return Container(
      width: _navOpen ? _navExpandedWidth : _navCollapsedWidth,
      decoration: const BoxDecoration(
        color: AppColours.primary,
        border: Border(right: BorderSide(color: AppColours.accent, width: 2)),
      ),
      child: Column(
        children: [
          //Logo Section
          if (_navOpen)
            _buildLogoSection(key: _visibleLogoSectionKey)
          else
            SizedBox(height: _logoSectionHeight),

          // Hamburger Menu
          SizedBox(
            height: 45,
            child: Align(
              alignment: _navOpen ? Alignment.centerRight : Alignment.center,
              child: IconButton(
                tooltip: _navOpen ? 'Collapse navigation' : 'Expand navigation',
                icon: const Icon(Icons.menu, color: AppColours.accent),
                onPressed: _toggleNav,
              ),
            ),
          ),

          // Navigation items
          if (_navOpen) ...[
            _buildNavItem(
              index: 0,
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.table_restaurant_outlined,
              label: 'Floor Allocator',
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.grid_view_rounded,
              label: 'Floor Designer',
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.event_outlined,
              label: 'Events',
            ),
            _buildNavItem(
              index: 4,
              icon: Icons.contact_support_outlined,
              label: 'Contact Us',
            ),
          ],

          const Spacer(),

          // Bottom account and settings section
          if (_navOpen)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColours.secondary,
                border: Border(
                  top: BorderSide(color: AppColours.accent, width: 2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        final accountIndex = _pages.indexWhere(
                          (page) => page is AccountPage,
                        );

                        if (accountIndex == -1) {
                          debugPrint('Account page not found in _pages');
                        }

                        setState(() {
                          _selectedIndex = accountIndex;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColours.accent,
                            child: Text(
                              _getInitials(sessionManager.username),
                              style: const TextStyle(
                                color: AppColours.textLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              sessionManager.username?.isNotEmpty == true
                                  ? sessionManager.username!
                                  : 'Account',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColours.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  IconButton(
                    tooltip: 'Settings',
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 5;
                      });
                    },
                    icon: const Icon(Icons.settings, color: AppColours.accent),
                  ),

                  IconButton(
                    tooltip: 'Sign Out',
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout, color: AppColours.accent),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  //logos
  Widget _buildLogoSection({Key? key}) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        // TableScout logo
        MouseRegion(
          onEnter: (_) => setState(() => _logoHovered = true),
          onExit: (_) => setState(() => _logoHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(0, _logoHovered ? -3 : 0, 0),
            decoration: BoxDecoration(
              color: _logoHovered
                  ? AppColours.secondary.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _logoHovered ? AppColours.secondary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: _navOpen ? 10 : 5,
                  horizontal: _navOpen ? 12 : 5,
                ),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColours.accent, width: 2),
                  ),
                ),
                child: SvgPicture.asset(
                  'assets/images/Tablescout_Logo_Flutter.svg',
                  fit: BoxFit.contain,
                  width: _navOpen ? 230 : 45,
                ),
              ),
            ),
          ),
        ),

        // Fake Store Logo / Bindle & Balm
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: _navOpen ? 10 : 5,
            horizontal: _navOpen ? 12 : 5,
          ),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColours.accent, width: 2),
            ),
          ),
          child: Image.asset(
            'assets/images/Bindle_&_Balm.png',
            fit: BoxFit.contain,
            width: _navOpen ? 150 : 35,
          ),
        ),
      ],
    );
  }

  // nav items
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsetsGeometry.symmetric(horizontal: 8, vertical: 3),
      child: Material(
        color: isSelected ? AppColours.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          hoverColor: AppColours.secondary.withValues(alpha: 0.35),
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColours.accent,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColours.textLight : AppColours.accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColours.textLight
                          : AppColours.accent,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //page content

  Widget _buildPageContent() {
    return Container(
      color: AppColours.background,
      child: _pages[_selectedIndex],
    );
  }
}
