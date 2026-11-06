import 'package:flutter/material.dart';

List<String> segmentSloka(String text) {
  final rawLines = text.split(RegExp(r'[\r\n]+'));
  final segments = <String>[];
  for (final line in rawLines) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) {
      segments.add(trimmed);
    }
  }
  return segments.isEmpty ? [text] : segments;
}

class HighlightedSlokaText extends StatefulWidget {
  final String text;
  final double progress; // 0.0 to 1.0
  final bool isPlaying;
  final double fontSize;
  final bool isFocusView;
  final ValueChanged<int>? onSegmentTap;

  const HighlightedSlokaText({
    super.key,
    required this.text,
    this.progress = 0.0,
    this.isPlaying = false,
    this.fontSize = 18.0,
    this.isFocusView = false,
    this.onSegmentTap,
  });

  @override
  State<HighlightedSlokaText> createState() => _HighlightedSlokaTextState();
}

class _HighlightedSlokaTextState extends State<HighlightedSlokaText> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _keys = [];
  List<String> _segments = [];
  int _lastActiveIndex = -1;

  @override
  void initState() {
    super.initState();
    _updateSegments();
  }

  @override
  void didUpdateWidget(covariant HighlightedSlokaText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _updateSegments();
    }
    if (widget.isPlaying && _segments.isNotEmpty) {
      final activeIndex = _calculateActiveIndex();
      if (activeIndex != _lastActiveIndex) {
        _lastActiveIndex = activeIndex;
        _scrollToActive(activeIndex);
      }
    }
  }

  void _updateSegments() {
    _segments = segmentSloka(widget.text);
    _keys.clear();
    for (var i = 0; i < _segments.length; i++) {
      _keys.add(GlobalKey());
    }
  }

  int _calculateActiveIndex() {
    if (_segments.isEmpty) return 0;
    final clamped = widget.progress.clamp(0.0, 1.0);
    final idx = (clamped * _segments.length).floor();
    return idx.clamp(0, _segments.length - 1);
  }

  void _scrollToActive(int index) {
    if (index >= 0 && index < _keys.length) {
      final keyContext = _keys[index].currentContext;
      if (keyContext != null) {
        Scrollable.ensureVisible(
          keyContext,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.4,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeIndex = widget.isPlaying ? _calculateActiveIndex() : -1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.isPlaying)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Following along',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ListView.builder(
          controller: _scrollController,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _segments.length,
          itemBuilder: (context, index) {
            final isHighlight = index == activeIndex;
            return Container(
              key: _keys[index],
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isHighlight
                    ? colorScheme.primaryContainer.withOpacity(0.65)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isHighlight
                    ? Border.all(color: colorScheme.primary.withOpacity(0.4), width: 1.2)
                    : null,
              ),
              child: InkWell(
                onTap: () => widget.onSegmentTap?.call(index),
                borderRadius: BorderRadius.circular(10),
                child: Center(
                  child: Text(
                    _segments[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Noto Serif',
                      fontSize: widget.fontSize,
                      fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                      height: 1.6,
                      color: isHighlight
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
