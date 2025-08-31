import 'package:flutter/material.dart';
import '../models/quote_model.dart';
import '../services/quote_service.dart';

class QuoteProvider extends ChangeNotifier {
  final QuoteService _quoteService = QuoteService();
  
  List<QuoteModel> _quotes = [];
  List<QuoteModel> _favoriteQuotes = [];
  QuoteModel? _dailyQuote;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<QuoteModel> get quotes => _quotes;
  List<QuoteModel> get favoriteQuotes => _favoriteQuotes;
  QuoteModel? get dailyQuote => _dailyQuote;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load random quotes
  Future<void> loadRandomQuotes({int count = 5}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _quotes = await _quoteService.fetchRandomQuotes(count: count);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      
      // Add fallback quotes if the API fails
      if (_quotes.isEmpty) {
        _quotes = _getFallbackQuotes(count);
      }
      
      notifyListeners();
    }
  }

  // Get fallback quotes for offline mode
  List<QuoteModel> _getFallbackQuotes(int count) {
    final fallbackQuotes = [
      QuoteModel(
        id: 'fallback_1',
        text: 'The only way to do great work is to love what you do.',
        author: 'Steve Jobs',
        category: 'Motivation',
        isFavorite: false,
      ),
      QuoteModel(
        id: 'fallback_2',
        text: 'Success is not final, failure is not fatal: it is the courage to continue that counts.',
        author: 'Winston Churchill',
        category: 'Success',
        isFavorite: false,
      ),
      QuoteModel(
        id: 'fallback_3',
        text: 'The future belongs to those who believe in the beauty of their dreams.',
        author: 'Eleanor Roosevelt',
        category: 'Dreams',
        isFavorite: false,
      ),
      QuoteModel(
        id: 'fallback_4',
        text: 'Don\'t watch the clock; do what it does. Keep going.',
        author: 'Sam Levenson',
        category: 'Persistence',
        isFavorite: false,
      ),
      QuoteModel(
        id: 'fallback_5',
        text: 'The only limit to our realization of tomorrow will be our doubts of today.',
        author: 'Franklin D. Roosevelt',
        category: 'Belief',
        isFavorite: false,
      ),
    ];
    
    return fallbackQuotes.take(count).toList();
  }

  // Load user's favorite quotes
  void loadFavoriteQuotes(String userId) {
    _quoteService.getUserFavoriteQuotes(userId).listen(
      (favoriteQuotes) {
        _favoriteQuotes = favoriteQuotes;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Load daily quote
  Future<void> loadDailyQuote(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _dailyQuote = await _quoteService.getDailyQuote(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Add quote to favorites
  Future<bool> addQuoteToFavorites(String userId, QuoteModel quote) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _quoteService.addQuoteToFavorites(userId, quote);

      // Update local quote if it exists
      final index = _quotes.indexWhere((q) => q.id == quote.id);
      if (index != -1) {
        _quotes[index] = quote.copyWith(isFavorite: true);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Remove quote from favorites
  Future<bool> removeQuoteFromFavorites(String userId, String quoteId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _quoteService.removeQuoteFromFavorites(userId, quoteId);

      // Remove from local favorite quotes
      _favoriteQuotes.removeWhere((quote) => quote.id == quoteId);

      // Update local quote if it exists
      final index = _quotes.indexWhere((q) => q.id == quoteId);
      if (index != -1) {
        _quotes[index] = _quotes[index].copyWith(isFavorite: false);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Toggle quote favorite status
  Future<bool> toggleQuoteFavorite(String userId, QuoteModel quote) async {
    try {
      if (quote.isFavorite) {
        return await removeQuoteFromFavorites(userId, quote.id);
      } else {
        return await addQuoteToFavorites(userId, quote);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Load quotes by category
  Future<void> loadQuotesByCategory(String category, {int count = 3}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _quotes = await _quoteService.getQuotesByCategory(category, count: count);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Refresh quotes (pull to refresh)
  Future<void> refreshQuotes({int count = 5}) async {
    await loadRandomQuotes(count: count);
  }

  // Refresh favorite quotes
  Future<void> refreshFavoriteQuotes(String userId) async {
    // The stream will automatically update the UI
    // This method is mainly for explicit refresh calls
  }

  // Get quote by ID
  QuoteModel? getQuoteById(String quoteId) {
    try {
      return _quotes.firstWhere((quote) => quote.id == quoteId);
    } catch (e) {
      return null;
    }
  }

  // Get favorite quote by ID
  QuoteModel? getFavoriteQuoteById(String quoteId) {
    try {
      return _favoriteQuotes.firstWhere((quote) => quote.id == quoteId);
    } catch (e) {
      return null;
    }
  }

  // Check if a quote is in favorites
  bool isQuoteInFavorites(String quoteId) {
    return _favoriteQuotes.any((quote) => quote.id == quoteId);
  }

  // Get quotes by author
  List<QuoteModel> getQuotesByAuthor(String author) {
    return _quotes.where((quote) => 
        quote.author.toLowerCase().contains(author.toLowerCase())).toList();
  }

  // Get favorite quotes by author
  List<QuoteModel> getFavoriteQuotesByAuthor(String author) {
    return _favoriteQuotes.where((quote) => 
        quote.author.toLowerCase().contains(author.toLowerCase())).toList();
  }

  // Search quotes by text
  List<QuoteModel> searchQuotes(String query) {
    if (query.isEmpty) return _quotes;
    
    final lowercaseQuery = query.toLowerCase();
    return _quotes.where((quote) => 
        quote.text.toLowerCase().contains(lowercaseQuery) ||
        quote.author.toLowerCase().contains(lowercaseQuery)).toList();
  }

  // Search favorite quotes by text
  List<QuoteModel> searchFavoriteQuotes(String query) {
    if (query.isEmpty) return _favoriteQuotes;
    
    final lowercaseQuery = query.toLowerCase();
    return _favoriteQuotes.where((quote) => 
        quote.text.toLowerCase().contains(lowercaseQuery) ||
        quote.author.toLowerCase().contains(lowercaseQuery)).toList();
  }

  // Get random quote from current quotes
  QuoteModel? getRandomQuote() {
    if (_quotes.isEmpty) return null;
    
    final random = DateTime.now().millisecondsSinceEpoch;
    final index = random % _quotes.length;
    return _quotes[index];
  }

  // Get random favorite quote
  QuoteModel? getRandomFavoriteQuote() {
    if (_favoriteQuotes.isEmpty) return null;
    
    final random = DateTime.now().millisecondsSinceEpoch;
    final index = random % _favoriteQuotes.length;
    return _favoriteQuotes[index];
  }

  // Get quotes statistics
  Map<String, dynamic> getQuotesStats() {
    final totalQuotes = _quotes.length;
    final totalFavorites = _favoriteQuotes.length;
    final uniqueAuthors = _quotes.map((q) => q.author).toSet().length;
    final favoriteAuthors = _favoriteQuotes.map((q) => q.author).toSet().length;

    return {
      'totalQuotes': totalQuotes,
      'totalFavorites': totalFavorites,
      'uniqueAuthors': uniqueAuthors,
      'favoriteAuthors': favoriteAuthors,
      'favoritePercentage': totalQuotes > 0 ? (totalFavorites / totalQuotes) * 100 : 0.0,
    };
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all quotes (useful for logout)
  void clearQuotes() {
    _quotes.clear();
    _favoriteQuotes.clear();
    _dailyQuote = null;
    _error = null;
    notifyListeners();
  }
}
