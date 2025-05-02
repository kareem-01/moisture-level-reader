import 'package:flutter/material.dart';

import 'nav_item.dart';

class NavNavigator extends StatelessWidget {
  const NavNavigator({
    super.key,
    required this.tabItem,
    required this.navigatorKey,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final NavItem tabItem;

  @override
  Widget build(BuildContext context) {
    return Navigator(
        key: navigatorKey,
        onGenerateRoute: (routeSettings) {
          return MaterialPageRoute(
            builder: (context) => tabItem.firstPage,
          );
        });
  }
}
