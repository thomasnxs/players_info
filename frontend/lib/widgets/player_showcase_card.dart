import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/member.dart';

class PlayerShowcaseCard extends StatefulWidget {
  const PlayerShowcaseCard({
    super.key,
    required this.player,
    this.onTap,
    this.enableHoverZoom = false,
    this.baseImageScale = 1.56,
    this.hoverImageScale = 1.64,
    this.imageYOffset = -8,
    this.showNickname = true,
  });

  final Member player;
  final VoidCallback? onTap;
  final bool enableHoverZoom;
  final double baseImageScale;
  final double hoverImageScale;
  final double imageYOffset;
  final bool showNickname;

  @override
  State<PlayerShowcaseCard> createState() => _PlayerShowcaseCardState();
}

class _PlayerShowcaseCardState extends State<PlayerShowcaseCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final clickable = widget.onTap != null;
    final url = widget.player.imageUrl;
    final fallbackUrl = url?.split('?').first;

    Widget image = url == null || url.isEmpty
        ? const Center(
            child: Icon(Icons.person, color: Colors.white70, size: 44),
          )
        : Image.network(
            url,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            errorBuilder: (context, error, stackTrace) {
              if (fallbackUrl?.isNotEmpty == true && fallbackUrl != url) {
                return Image.network(
                  fallbackUrl!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.person, color: Colors.white70, size: 44),
                  ),
                );
              }

              return const Center(
                child: Icon(Icons.person, color: Colors.white70, size: 44),
              );
            },
          );

    image = AnimatedScale(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      scale: widget.enableHoverZoom && _hovered
          ? widget.hoverImageScale
          : widget.baseImageScale,
      alignment: Alignment.bottomCenter,
      child: Transform.translate(
        offset: Offset(0, widget.imageYOffset),
        child: image,
      ),
    );

    final content = Container(
      decoration: BoxDecoration(
        color: const Color(0xFF17191E),
        border: Border.all(color: const Color(0xFF262A33)),
      ),
      child: Column(
        children: [
          Expanded(child: ClipRect(child: image)),
          if (widget.showNickname)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF111317),
                border: Border(top: BorderSide(color: Color(0xFF262A33))),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              alignment: Alignment.center,
              child: Text(
                widget.player.nickname,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
            ),
        ],
      ),
    );

    return MouseRegion(
      cursor: clickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        if (widget.enableHoverZoom) {
          setState(() => _hovered = true);
        }
      },
      onExit: (_) {
        if (widget.enableHoverZoom) {
          setState(() => _hovered = false);
        }
      },
      child: clickable ? GestureDetector(onTap: widget.onTap, child: content) : content,
    );
  }
}
