import 'dart:async';
import 'package:flutter/material.dart';

class IysLogo extends StatelessWidget {
  final double size;
  const IysLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/iys_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.auto_stories,
          size: size,
          color: Theme.of(context).colorScheme.primary,
        );
      },
    );
  }
}

class QuoteItem {
  final String imagePath;
  final String badge;
  final String author;
  final String quote;

  const QuoteItem({
    required this.imagePath,
    required this.badge,
    required this.author,
    required this.quote,
  });
}

class QuoteCard extends StatefulWidget {
  final VoidCallback? onTap;
  const QuoteCard({super.key, this.onTap});

  @override
  State<QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<QuoteCard> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  static const List<QuoteItem> _quotes = [
    // 1. Srila Prabhupada quote (Featured first)
    QuoteItem(
      imagePath: 'assets/images/prabhupada_reading.jpg',
      badge: 'FOUNDER-ĀCĀRYA',
      author: 'A.C. Bhaktivedanta Swami Prabhupada',
      quote:
          '“Reading and studying ślokas from scriptures like the Bhagavad-gītā As It Is and Śrīmad-Bhāgavatam is not an academic or a mechanical exercise, but a direct spiritual connection with Krishna.”',
    ),
    // 2. Srila Prabhupada realizations quote
    QuoteItem(
      imagePath: 'assets/images/prabhupada_quote.jpg',
      badge: 'DIVINE PRESENCE',
      author: 'A.C. Bhaktivedanta Swami Prabhupada',
      quote:
          '“When we read Srila Prabhupada’s books, we are sitting in His divine presence, hearing & speaking. When we follow what is in the books—we get realizations.”',
    ),
    // 3. H.H. Radhanath Swami (Reading)
    QuoteItem(
      imagePath: 'assets/images/swami_reading.jpg',
      badge: 'WISDOM & DEVOTION',
      author: 'H.H. Radhanath Swami',
      quote:
          '“Learning sacred verses is not just memorization, but a profound way to adjust our consciousness, internalize spiritual truth, and cultivate a humble, service-oriented heart.”',
    ),
    // 4. H.H. Radhanath Swami (Study)
    QuoteItem(
      imagePath: 'assets/images/swami_study.jpg',
      badge: 'SACRED CHANTING',
      author: 'H.H. Radhanath Swami',
      quote:
          '“Sacred verses are divine spiritual vibrations. When chanted with devotion and sincerity, they awaken our dormant love for Krishna and purify the heart.”',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % _quotes.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onUserInteraction() {
    _startAutoPlay();
  }

  void _showQuoteDialog(QuoteItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 220,
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.author,
                    style: const TextStyle(
                      fontFamily: 'Noto Serif',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.quote,
                    style: const TextStyle(
                      fontFamily: 'Noto Serif',
                      fontSize: 15,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Carousel Slider for quotes
          SizedBox(
            height: 250,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _quotes.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                _onUserInteraction();
              },
              itemBuilder: (context, index) {
                final item = _quotes[index];
                return InkWell(
                  onTap: () {
                    if (widget.onTap != null) {
                      widget.onTap!();
                    } else {
                      _showQuoteDialog(item);
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Thumbnail image with gradient overlay
                      Stack(
                        children: [
                          SizedBox(
                            height: 140,
                            width: double.infinity,
                            child: Image.asset(
                              item.imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.menu_book,
                                    size: 48,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.68),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            left: 14,
                            right: 14,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.badge,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Flexible(
                                  child: Text(
                                    item.author,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      shadows: [
                                        Shadow(
                                            color: Colors.black87,
                                            blurRadius: 4),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                          child: Text(
                            item.quote,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFamily: 'Noto Serif',
                              fontStyle: FontStyle.italic,
                              height: 1.45,
                              fontSize: 13,
                              color: colorScheme.onSurface.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Dot indicator bar at bottom
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, right: 14.0, left: 14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_quotes.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
