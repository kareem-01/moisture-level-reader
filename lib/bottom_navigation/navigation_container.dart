import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nav/nav.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../common/util/system_bars_util.dart';
import '../common/constants/dimensions.dart';
import '../common/theme/color/AppColors.dart';
import 'nav_item.dart';
import 'nav_navigator.dart';

class NavigationContainer extends StatefulWidget {
  const NavigationContainer({super.key});

  @override
  State<NavigationContainer> createState() => NavigationContainerState();
}

class NavigationContainerState extends State<NavigationContainer>
    with SingleTickerProviderStateMixin {
  NavItem _currentTab = NavItem.home;
  final tabs = [NavItem.home, NavItem.history, NavItem.about];
  final List<GlobalKey<NavigatorState>> navigatorKeys = [];

  int get _currentIndex => tabs.indexOf(_currentTab);

  GlobalKey<NavigatorState> get _currentTabNavigationKey =>
      navigatorKeys[_currentIndex];

  bool get extendBody => true;

  static const double bottomNavigationBarBorderRadius = 12;

  @override
  void initState() {
    super.initState();
    initNavigatorKeys();
  }

  @override
  void didChangeDependencies() {
    _setSystemBarColors(0);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: isRootPage,
      onPopInvoked: _handleBackPressed,
      child: Scaffold(
        extendBody: extendBody,
        body: Stack(
          children: [
            Container(
              color: AppColors.background,
              margin: EdgeInsets.only(
                bottom: kBottomNavigationBarHeight + 14.h,
              ),
              child: pages,
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNavigationBar(context),
            ),
          ],
        ),
      ),
    );
  }

  bool get isRootPage =>
      _currentTab == NavItem.home &&
      _currentTabNavigationKey.currentState?.canPop() == false;

  IndexedStack get pages => IndexedStack(
    index: _currentIndex,
    children:
        tabs
            .mapIndexed(
              (tab, index) => Offstage(
                offstage: _currentTab != tab,
                child: NavNavigator(
                  navigatorKey: navigatorKeys[index],
                  tabItem: tab,
                ),
              ),
            )
            .toList(),
  );

  void _handleBackPressed(bool didPop) {
    if (!didPop) {
      if (_currentTabNavigationKey.currentState?.canPop() == true) {
        Nav.pop(_currentTabNavigationKey.currentContext!);
        return;
      }

      if (_currentTab != NavItem.home) {
        _changeTab(tabs.indexOf(NavItem.home));
      }
    }
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.navigationBorder, width: 1.0),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(bottomNavigationBarBorderRadius),
          topRight: Radius.circular(bottomNavigationBarBorderRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            spreadRadius: AppDimensions.shadowSpreadRadius,
            blurRadius: AppDimensions.shadowBlurRadius * 2,
          ),
        ],
      ),
      child: SizedBox(
        // height: kBottomNavigationBarHeight * 1.8,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(bottomNavigationBarBorderRadius),
            topRight: Radius.circular(bottomNavigationBarBorderRadius),
          ),
          child: BottomNavigationBar(
            items: navigationBarItems(context),
            currentIndex: _currentIndex,
            backgroundColor: AppColors.onBackground,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.text.withOpacity(0.4),
            onTap: _handleOnTapNavigationBarItem,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> navigationBarItems(BuildContext context) {
    return tabs
        .mapIndexed(
          (tab, index) => tab.toNavigationBarItem(
            context,
            isActivated: _currentIndex == index,
          ),
        )
        .toList();
  }

  void _changeTab(int index) {
    setState(() {
      _currentTab = tabs[index];
    });
  }

  void _handleOnTapNavigationBarItem(int index) {
    _setSystemBarColors(index);
    final oldTab = _currentTab;
    final targetTab = tabs[index];
    if (oldTab == targetTab) {
      final navigationKey = _currentTabNavigationKey;
      popAllHistory(navigationKey);
    }
    _changeTab(index);
  }

  void popAllHistory(GlobalKey<NavigatorState> navigationKey) {
    final bool canPop = navigationKey.currentState?.canPop() == true;
    if (canPop) {
      while (navigationKey.currentState?.canPop() == true) {
        navigationKey.currentState!.pop();
      }
    }
  }

  void initNavigatorKeys() {
    for (final _ in tabs) {
      navigatorKeys.add(GlobalKey<NavigatorState>());
    }
  }

  void _setSystemBarColors(int index) {
    if (index < 2) {
      SystemBarsUtil.changeStatusAndNavigationBars(
        statusBarColor: AppColors.seedColor,
        navBarColor: AppColors.seedColor,
        isBlackIcons: context.isDarkMode ? false : true,
      );
    } else if (index == 2) {
      SystemBarsUtil.changeStatusAndNavigationBars(
        statusBarColor: AppColors.transparent,
        navBarColor: AppColors.seedColor,
        isBlackIcons: !context.isDarkMode,
      );
    } else {
      SystemBarsUtil.changeStatusAndNavigationBars(
        statusBarColor: AppColors.transparent,
        navBarColor: AppColors.seedColor,
        isBlackIcons: context.isDarkMode ? false : true,
      );
    }
  }
}
