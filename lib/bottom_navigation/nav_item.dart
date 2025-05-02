import 'package:flutter/material.dart';

import '../constants/AppSvgs.dart';
import '../features/AboutScreen.dart';
import '../features/HistoryScreen.dart';
import '../features/HomeScreen.dart';

enum NavItem {
  home(
    AppSvgs.homeSelected,
    'home',
    HomeScreen(),
    inActiveIcon: AppSvgs.homeUnSelected,
  ),
  history(
    AppSvgs.historySelected,
    'stores',
    HistoryScreen(),
    inActiveIcon: AppSvgs.historyUnSelected,
  ),
  about(
    AppSvgs.aboutSelected,
    'more',
    AboutScreen(),
    inActiveIcon: AppSvgs.aboutUnSelected,
  );

  final String activeIcon;
  final String inActiveIcon;
  final String tabName;
  final Widget firstPage;

  const NavItem(
    this.activeIcon,
    this.tabName,
    this.firstPage, {
    String? inActiveIcon,
  }) : inActiveIcon = inActiveIcon ?? activeIcon;

  BottomNavigationBarItem toNavigationBarItem(
    BuildContext context, {
    required bool isActivated,
  }) {
    return BottomNavigationBarItem(
      icon: DynamicContainer(
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isActivated ? context.appColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: isActivated ? 20 : 29,
                width: isActivated ? 20 : 29,
                child: SvgPicture.asset(
                  isActivated ? activeIcon : inActiveIcon,
                  key: ValueKey(tabName),
                  colorFilter: ColorFilter.mode(
                    isActivated
                        ? Colors.white
                        : context.appColors.text.withOpacity(0.4),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              DynamicContainer(
                showChild: isActivated,
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    Text(
                      context.tr(tabName),
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      label: '',
    );
  }
}
