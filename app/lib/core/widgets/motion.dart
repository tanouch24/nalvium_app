import 'package:flutter/widgets.dart';

/// Respecte « Réduire les animations » du système.
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

Duration motionDuration(
  BuildContext context, [
  Duration normal = const Duration(milliseconds: 240),
]) => reduceMotion(context) ? Duration.zero : normal;
