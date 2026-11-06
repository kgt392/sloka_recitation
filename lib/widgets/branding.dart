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
  final String author;
  final String quote;

  const QuoteItem({
    required this.imagePath,
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
    // 1. Srila Prabhupada with Garland (New image uploaded by user)
    QuoteItem(
      imagePath: 'assets/images/prabhupada_garland.jpg',
      author: 'Srila Prabhupada',
      quote:
          'Reading and studying ślokas from scriptures like the Bhagavad-gītā As It Is and Śrīmad-Bhāgavatam is not an academic or a mechanical exercise, but a direct spiritual connection with Krishna.',
    ),
    // 2. Srila Prabhupada Studying under Desk Lamp
    QuoteItem(
      imagePath: 'assets/images/prabhupada_reading.jpg',
      author: 'Srila Prabhupada',
      quote:
          'When we read Srila Prabhupada’s books, we are sitting in His divine presence, hearing & speaking. When we follow what is in the books—we get realizations.',
    ),
    // 3. H.H. Radhanath Swami (Original 1)
    QuoteItem(
      imagePath: 'assets/images/swami_reading.jpg',
      author: 'H.H. Radhanath Swami',
      quote:
          'Reciting shlokas is not merely a mechanical vocal exercise — it is a powerful meditation that draws the heart toward the Divine.',
    ),
    // 4. H.H. Radhanath Swami (Original 2)
    QuoteItem(
      imagePath: 'assets/images/swami_study.jpg',
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
    const primaryColor = Color(0xFFF58220); // Amber / saffron orange

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Banner card
          Container(
            height: 210,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
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
                return GestureDetector(
                  onTap: widget.onTap,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Full background image
                      Image.asset(
                        item.imagePath,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF2C1810),
                            child: const Center(
                              child: Icon(
                                Icons.auto_stories,
                                size: 54,
                                color: Colors.white70,
                              ),
                            ),
                          );
                        },
                      ),

                      // Dark vignette gradient overlay for high contrast text readability
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.35),
                              Colors.black.withOpacity(0.55),
                              Colors.black.withOpacity(0.78),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),

                      // Card Content
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Quotation mark icon at top-left
                            const Text(
                              '“',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 32,
                                height: 1.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'serif',
                              ),
                            ),
                            const Spacer(),

                            // Quote text
                            Text(
                              item.quote,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                                shadows: [
                                  Shadow(
                                    color: Colors.black87,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Author with amber dash
                            Row(
                              children: [
                                Container(
                                  width: 18,
                                  height: 2.5,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.author,
                                  style: const TextStyle(
                                    color: primaryColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black87,
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // 4-dot indicator underneath the card
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_quotes.length, (index) {
              final isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 22 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? primaryColor : const Color(0xFFD4D4D4),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
