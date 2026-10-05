import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tablescout/session/session_manager.dart';
import 'package:tablescout/pages/login_page.dart';
import 'package:tablescout/pages/signup_page.dart';
import 'package:tablescout/widgets/nav_bar.dart';

class AppRouter {
  final SessionManager sessionManager;

  late final GoRouter router;

  AppRouter(this.sessionManager) {
    router = GoRouter(
      initialLocation: '/login',

      // Re-evaluate routes when the session changes.
      refreshListenable: sessionManager,

      redirect: (context, state) {
        final isLoggedIn = sessionManager.isLoggedIn;
        final location = state.matchedLocation;

        final isLoggingIn = location == '/login';
        final isSigningUp = location == '/signup';

        // Logged-out users can only access login and signup.
        if (!isLoggedIn && !isLoggingIn && !isSigningUp) {
          return '/login';
        }

        // Logged-in users should not return to login/signup.
        if (isLoggedIn && (isLoggingIn || isSigningUp)) {
          return '/app';
        }

        // No redirect needed.
        return null;
      },

      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),

        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupPage(),
        ),

        GoRoute(
          path: '/app',
          builder: (context, state) => const NavBar(),
        ),
      ],

      // Fallback for unknown routes.
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Page not found')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('The requested page could not be found.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(
                  sessionManager.isLoggedIn ? '/app' : '/login',
                ),
                child: const Text('Return to safety'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}