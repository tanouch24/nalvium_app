import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/nalvium_colors.dart';

/// Première image d'une vidéo LOCALE (immobile, sans son). Repli sobre si la lecture est impossible.
class VideoPoster extends StatefulWidget {
  const VideoPoster({super.key, required this.path});
  final String path;

  @override
  State<VideoPoster> createState() => _VideoPosterState();
}

class _VideoPosterState extends State<VideoPoster> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.file(File(widget.path));
      _controller = c;
      await c.initialize();
      await c.setVolume(0);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (_failed || c == null || !c.value.isInitialized) {
      return const ColoredBox(color: NalviumColors.primarySoft, child: Center(child: Icon(Icons.videocam_outlined, size: 40, color: NalviumColors.primary)));
    }
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c)),
    );
  }
}
