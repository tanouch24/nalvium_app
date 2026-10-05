import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'motion.dart';

/// Transition de page sobre : fondu + léger glissement vertical (aucune si « Réduire les animations »).
CustomTransitionPage<void> nalviumPage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondary, child) {
        if (reduceMotion(context)) return child;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
