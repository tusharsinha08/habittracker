import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quote_provider.dart';
import '../../widgets/quote_card.dart';
import '../../models/quote_model.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    // Defer loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuotes();
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuotes() async {
    final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Load random quotes
    await quoteProvider.loadRandomQuotes(count: 10);
    
    // Load favorite quotes if user is authenticated
    if (authProvider.currentUser != null) {
      quoteProvider.loadFavoriteQuotes(authProvider.currentUser!.uid);
    }
  }

  Future<void> _onRefresh() async {
    final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Refresh random quotes
    await quoteProvider.refreshQuotes(count: 10);
    
    // Reload favorite quotes if user is authenticated
    if (authProvider.currentUser != null) {
      quoteProvider.loadFavoriteQuotes(authProvider.currentUser!.uid);
    }
    
    _refreshController.refreshCompleted();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _toggleFavoritesOnly() {
    setState(() {
      _showFavoritesOnly = !_showFavoritesOnly;
    });
    
    // If switching to favorites view, ensure favorite quotes are loaded
    if (_showFavoritesOnly) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
      
      if (authProvider.currentUser != null) {
        quoteProvider.loadFavoriteQuotes(authProvider.currentUser!.uid);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final quoteProvider = Provider.of<QuoteProvider>(context);

    if (authProvider.currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get quotes and filter them early
    final quotes = _showFavoritesOnly 
        ? quoteProvider.favoriteQuotes.cast<QuoteModel>()
        : quoteProvider.quotes.cast<QuoteModel>();
    
    final filteredQuotes = _filterQuotes(quotes);
    
    // Check if quotes are loading
    if (quoteProvider.isLoading && quoteProvider.quotes.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading quotes...'),
            ],
          ),
        ),
      );
    }

    // Check if there's an error loading quotes
    if (quoteProvider.error != null && quoteProvider.quotes.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Motivational Quotes',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load quotes',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                quoteProvider.error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _loadQuotes(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show quotes even if there was an error (fallback quotes)
    if (quoteProvider.error != null && quoteProvider.quotes.isNotEmpty) {
      // Show error banner but still display quotes
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Motivational Quotes',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              onPressed: _toggleFavoritesOnly,
              icon: Icon(
                _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                color: _showFavoritesOnly ? Colors.red : null,
              ),
              tooltip: _showFavoritesOnly ? 'Show all quotes' : 'Show favorites only',
            ),
          ],
        ),
        body: Column(
          children: [
            // Error banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing offline quotes. Some features may be limited.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _loadQuotes(),
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Continue with normal content
            Expanded(child: _buildQuotesContent(filteredQuotes)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Motivational Quotes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _toggleFavoritesOnly,
            icon: Icon(
              _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: _showFavoritesOnly ? Colors.red : null,
            ),
            tooltip: _showFavoritesOnly ? 'Show all quotes' : 'Show favorites only',
          ),
        ],
      ),
      body: _buildQuotesContent(filteredQuotes),
    );
  }

  Widget _buildQuotesContent(List<QuoteModel> quotes) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search quotes...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          ),
        ),

        // Filter Indicator
        if (_showFavoritesOnly)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Showing favorites only',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Quotes List
        Expanded(
          child: quotes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showFavoritesOnly ? Icons.favorite_border : Icons.format_quote,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _showFavoritesOnly 
                            ? 'No favorite quotes yet'
                            : 'No quotes found',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _showFavoritesOnly
                            ? 'Start adding quotes to your favorites!'
                            : 'Try refreshing or check your search query',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : SmartRefresher(
                  controller: _refreshController,
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: quotes.length,
                    itemBuilder: (context, index) {
                      final quote = quotes[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: QuoteCard(
                          quote: quote,
                          showActions: true,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  List<QuoteModel> _filterQuotes(List<QuoteModel> quotes) {
    if (_searchQuery.isEmpty) return quotes;
    
    return quotes.where((quote) {
      final query = _searchQuery.toLowerCase();
      return quote.text.toLowerCase().contains(query) ||
             quote.author.toLowerCase().contains(query) ||
             (quote.category?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Widget _buildEmptyState() {
    final message = _showFavoritesOnly
        ? 'No favorite quotes yet'
        : 'No quotes available';
    
    final subtitle = _showFavoritesOnly
        ? 'Start adding quotes to your favorites to see them here'
        : 'Pull down to refresh and load new quotes';
    
    final icon = _showFavoritesOnly
        ? Icons.favorite_border
        : Icons.format_quote_outlined;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (!_showFavoritesOnly) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Load Quotes'),
            ),
          ],
        ],
      ),
    );
  }

  void _viewQuoteDetails(BuildContext context, dynamic quote) {
    // Navigate to quote details screen
    // This will be implemented later
  }
}
