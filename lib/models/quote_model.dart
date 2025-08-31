class QuoteModel {
  final String id;
  final String text;
  final String author;
  final String? category;
  final bool isFavorite;
  final DateTime? addedToFavorites;

  QuoteModel({
    required this.id,
    required this.text,
    required this.author,
    this.category,
    this.isFavorite = false,
    this.addedToFavorites,
  });

  factory QuoteModel.fromMap(Map<String, dynamic> map, String id) {
    return QuoteModel(
      id: id,
      text: map['text'] ?? '',
      author: map['author'] ?? 'Unknown',
      category: map['category'],
      isFavorite: map['isFavorite'] ?? false,
      addedToFavorites: map['addedToFavorites'] != null 
          ? DateTime.parse(map['addedToFavorites']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'author': author,
      'category': category,
      'isFavorite': isFavorite,
      'addedToFavorites': addedToFavorites?.toIso8601String(),
    };
  }

  QuoteModel copyWith({
    String? text,
    String? author,
    String? category,
    bool? isFavorite,
    DateTime? addedToFavorites,
  }) {
    return QuoteModel(
      id: id,
      text: text ?? this.text,
      author: author ?? this.author,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      addedToFavorites: addedToFavorites ?? this.addedToFavorites,
    );
  }

  QuoteModel toggleFavorite() {
    return copyWith(
      isFavorite: !isFavorite,
      addedToFavorites: !isFavorite ? DateTime.now() : null,
    );
  }
}
