import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soil_moisture_app/bottom_navigation/navigation_container.dart';
import 'package:velocity_x/velocity_x.dart';

import '../common/theme/color/AppColors.dart';
import '../common/util/system_bars_util.dart';
import '../common/widgets/animations/scale.dart';
import '../common/widgets/custom_containers/animated_color_transition.dart';
import '../constants/AppImages.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500)).then((_) {
      _handleSplashDirections();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _changeSystemBarColors();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedColorTransition(
          duration: Duration(milliseconds: 1700),
          height: double.infinity,
          width: double.infinity,
          curve: Curves.linear,
          startColor: AppColors.logoColor,
          endColor: AppColors.logoColor,
        ),
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 26.h),
            child: BounceScaleWidget(
              startScale: 0.7,
              endScale: 1,
              duration: const Duration(milliseconds: 1700),
              bounceDuration: const Duration(milliseconds: 2100),
              child: Image.asset(
                AppImages.appIcon,
                width: MediaQuery.of(context).size.width * 0.45,
                alignment: Alignment.center,
                fit: BoxFit.contain,
              ).scale(scaleValue: 1.7),
            ),
          ),
        ),
      ],
    );
  }

  void _changeSystemBarColors() {
    SystemBarsUtil.changeStatusAndNavigationBars(
      statusBarColor: AppColors.transparent,
      navBarColor: AppColors.background,
      isBlackIcons: context.isDarkMode ? false : true,
    );
  }

  void _handleSplashDirections() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => NavigationContainer()),
    );
  }
}
