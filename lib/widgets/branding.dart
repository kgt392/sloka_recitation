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
    // 1. Srila Prabhupada (Classic reading photo)
    QuoteItem(
      imagePath: 'assets/images/prabhupada_reading_bw.jpg',
      badge: 'FOUNDER-ĀCĀRYA',
      author: 'A.C. Bhaktivedanta Swami Prabhupada',
      quote:
          'Reading and studying ślokas from scriptures like the Bhagavad-gītā As It Is and Śrīmad-Bhāgavatam is not an academic or a mechanical exercise, but a direct spiritual connection with Krishna.',
    ),
    // 2. Srila Prabhupada (Study under desk lamp)
    QuoteItem(
      imagePath: 'assets/images/prabhupada_reading.jpg',
      badge: 'DIVINE PRESENCE',
      author: 'A.C. Bhaktivedanta Swami Prabhupada',
      quote:
          'When we read Srila Prabhupada’s books, we are sitting in His divine presence, hearing & speaking. When we follow what is in the books—we get realizations.',
    ),
    // 3. H.H. Radhanath Swami (Original 1 - Room)
    QuoteItem(
      imagePath: 'assets/images/swami_reading.jpg',
      badge: 'WISDOM & DEVOTION',
      author: 'H.H. Radhanath Swami',
      quote:
          'Reciting shlokas is not merely a mechanical vocal exercise — it is a powerful meditation that draws the heart toward the Divine.',
    ),
    // 4. H.H. Radhanath Swami (Original 2 - Train)
    QuoteItem(
      imagePath: 'assets/images/swami_study.jpg',
      badge: 'SACRED CHANTING',
      author: 'H.H. Radhanath Swami',
      quote:
          'Learning sacred verses is not just memorization, but a profound way to adjust our consciousness, internalize spiritual truth, and cultivate a humble, service-oriented heart.',
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
    _timer = Timer.periodic(const Duration(seconds: 7), (timer) {
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

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 235,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _quotes.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              _onUserInteraction();
            },
            itemBuilder: (context, index) {
              final item = _quotes[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    item.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF2D1810),
                        child: const Icon(Icons.menu_book, color: Colors.white54, size: 48),
                      );
                    },
                  ),
                  // Dark contrast gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.35),
                          Colors.black.withOpacity(0.80),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '””',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 0.8,
                            fontFamily: 'serif',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            item.quote,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                        Text(
                          '— ${item.author}',
                          style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // 4-Dot indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_quotes.length, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
