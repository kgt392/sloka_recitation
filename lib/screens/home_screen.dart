import 'package:flutter/material.dart';
import '../models/sloka.dart';
import '../services/storage_service.dart';
import '../widgets/branding.dart';
import 'add_edit_sloka_screen.dart';
import 'sloka_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Sloka> _allSlokas = [];
  List<Sloka> _filteredSlokas = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSlokas();
  }

  Future<void> _loadSlokas() async {
    setState(() => _isLoading = true);
    final slokas = await _storage.loadSlokas();
    if (mounted) {
      setState(() {
        _allSlokas = slokas;
        _applySearch();
        _isLoading = false;
      });
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _applySearch();
    });
  }

  void _applySearch() {
    if (_searchQuery.trim().isEmpty) {
      _filteredSlokas = List.from(_allSlokas);
    } else {
      final q = _searchQuery.toLowerCase().trim();
      _filteredSlokas = _allSlokas.where((s) {
        return s.title.toLowerCase().contains(q) ||
            s.text.toLowerCase().contains(q);
      }).toList();
    }
  }

  Future<void> _openDetail(Sloka sloka) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SlokaDetailScreen(slokaId: sloka.id),
      ),
    );
    _loadSlokas();
  }

  Future<void> _goToAddSloka() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditSlokaScreen(),
      ),
    );
    _loadSlokas();
  }

  Future<void> _confirmDelete(Sloka sloka) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sloka'),
        content: Text('Are you sure you want to delete "${sloka.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storage.deleteSloka(sloka.id);
      _loadSlokas();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Sloka Recitation',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDE047),
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/iys_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSlokas,
              child: CustomScrollView(
                slivers: [
                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearch,
                          decoration: InputDecoration(
                            hintText: 'Search your slokas',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 15,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF64748B),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearch('');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Inspirational Quote Banner
                  if (_searchQuery.isEmpty)
                    const SliverToBoxAdapter(
                      child: QuoteCard(),
                    ),

                  // Sloka list header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                      child: Row(
                        children: [
                          Text(
                            'SACRED VERSES (${_filteredSlokas.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.9,
                              color: colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          if (_allSlokas.any((s) => s.hasAudio))
                            Text(
                              '${_allSlokas.where((s) => s.hasAudio).length} with audio',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Slokas or Empty State
                  if (_filteredSlokas.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_searchQuery.isNotEmpty) ...[
                                Icon(
                                  Icons.search_off,
                                  size: 56,
                                  color: colorScheme.outline,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No slokas match your search',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Try checking for typos or searching another verse.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ] else ...[
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE8F0FE),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.menu_book_rounded,
                                    size: 40,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'Begin your practice',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tap “Add Sloka” to add your first verse\nwith its text and audio, then loop...',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final sloka = _filteredSlokas[index];
                          return Dismissible(
                            key: Key(sloka.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              alignment: Alignment.centerRight,
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              await _confirmDelete(sloka);
                              return false; // Handled by dialog & _loadSlokas
                            },
                            child: _SlokaCard(
                              sloka: sloka,
                              onTap: () => _openDetail(sloka),
                            ),
                          );
                        },
                        childCount: _filteredSlokas.length,
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToAddSloka,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Sloka',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2563EB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _SlokaCard extends StatelessWidget {
  final Sloka sloka;
  final VoidCallback onTap;

  const _SlokaCard({
    required this.sloka,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get 2-line preview
    final lines = sloka.text
        .split(RegExp(r'[\r\n]+'))
        .where((l) => l.trim().isNotEmpty)
        .take(2)
        .join('\n');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      sloka.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: 'Noto Serif',
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (sloka.hasAudio)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mic,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Audio',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: colorScheme.outline,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                lines.isNotEmpty ? lines : '(No text added)',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Noto Serif',
                  fontSize: 14,
                  height: 1.5,
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
