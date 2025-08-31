import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/quote_model.dart';

class QuoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Free quotes API endpoints
  static const String _quotableApi = 'https://api.quotable.io/random';
  static const String _zenQuotesApi = 'https://zenquotes.io/api/random';

  // Fetch random quotes from external API
  Future<List<QuoteModel>> fetchRandomQuotes({int count = 5}) async {
    try {
      final List<QuoteModel> quotes = [];
      
      // Try Quotable API first
      try {
        for (int i = 0; i < count; i++) {
          final response = await http.get(Uri.parse(_quotableApi));
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final quote = QuoteModel(
              id: _generateQuoteId(data['content']),
              text: data['content'],
              author: data['author'] ?? 'Unknown',
              category: data['tags']?.isNotEmpty == true ? data['tags'][0] : null,
            );
            quotes.add(quote);
          }
        }
      } catch (e) {
        // Fallback to ZenQuotes if Quotable fails
        for (int i = 0; i < count; i++) {
          final response = await http.get(Uri.parse(_zenQuotesApi));
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data.isNotEmpty) {
              final quote = QuoteModel(
                id: _generateQuoteId(data[0]['q']),
                text: data[0]['q'],
                author: data[0]['a'] ?? 'Unknown',
              );
              quotes.add(quote);
            }
          }
        }
      }
      
      return quotes;
    } catch (e) {
      throw Exception('Failed to fetch quotes: $e');
    }
  }

  // Generate a unique ID for quotes
  String _generateQuoteId(String text) {
    return text.hashCode.toString();
  }

  // Get user's favorite quotes
  Stream<List<QuoteModel>> getUserFavoriteQuotes(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc('quotes')
        .collection('quotes')
        .orderBy('addedToFavorites', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuoteModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Add quote to favorites
  Future<void> addQuoteToFavorites(String userId, QuoteModel quote) async {
    try {
      final favoriteQuote = quote.copyWith(
        isFavorite: true,
        addedToFavorites: DateTime.now(),
      );
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc('quotes')
          .collection('quotes')
          .doc(quote.id)
          .set(favoriteQuote.toMap());
    } catch (e) {
      throw Exception('Failed to add quote to favorites: $e');
    }
  }

  // Remove quote from favorites
  Future<void> removeQuoteFromFavorites(String userId, String quoteId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc('quotes')
          .collection('quotes')
          .doc(quoteId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove quote from favorites: $e');
    }
  }

  // Check if a quote is in user's favorites
  Future<bool> isQuoteInFavorites(String userId, String quoteId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc('quotes')
          .collection('quotes')
          .doc(quoteId)
          .get();
      
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Toggle quote favorite status
  Future<void> toggleQuoteFavorite(String userId, QuoteModel quote) async {
    try {
      if (quote.isFavorite) {
        await removeQuoteFromFavorites(userId, quote.id);
      } else {
        await addQuoteToFavorites(userId, quote);
      }
    } catch (e) {
      throw Exception('Failed to toggle quote favorite: $e');
    }
  }

  // Get inspirational quotes by category
  Future<List<QuoteModel>> getQuotesByCategory(String category, {int count = 3}) async {
    try {
      final List<QuoteModel> quotes = [];
      
      // Try to get category-specific quotes from Quotable API
      try {
        final response = await http.get(
          Uri.parse('https://api.quotable.io/quotes?tags=$category&limit=$count'),
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          for (final quoteData in data['results']) {
            final quote = QuoteModel(
              id: _generateQuoteId(quoteData['content']),
              text: quoteData['content'],
              author: quoteData['author'] ?? 'Unknown',
              category: category,
            );
            quotes.add(quote);
          }
        }
      } catch (e) {
        // Fallback to random quotes if category-specific fails
        return await fetchRandomQuotes(count: count);
      }
      
      return quotes;
    } catch (e) {
      throw Exception('Failed to fetch category quotes: $e');
    }
  }

  // Get daily quote (cached for the day)
  Future<QuoteModel?> getDailyQuote(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_quotes')
          .doc(today.toIso8601String().split('T')[0])
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        return QuoteModel.fromMap(data, doc.id);
      }
      
      // If no daily quote exists, fetch a new one
      final quotes = await fetchRandomQuotes(count: 1);
      if (quotes.isNotEmpty) {
        final dailyQuote = quotes.first;
        
        // Save as daily quote
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('daily_quotes')
            .doc(today.toIso8601String().split('T')[0])
            .set(dailyQuote.toMap());
        
        return dailyQuote;
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to get daily quote: $e');
    }
  }
}
