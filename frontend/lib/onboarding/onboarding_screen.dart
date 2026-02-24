import 'package:flutter/material.dart';
import 'responsive_layout.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileLayout: _OnboardingMobile(),
      webLayout: _OnboardingWeb(),
    );
  }
}

class _OnboardingMobile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Onboarding Mobile View'),
          ],
        ),
      ),
    );
  }
}

class _OnboardingWeb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Onboarding Web View'),
          ],
        ),
      ),
    );
  }
}