import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clipboard/clipboard.dart';
import '../models/quote_model.dart';
import '../providers/auth_provider.dart';
import '../providers/quote_provider.dart';

class QuoteCard extends StatelessWidget {
  final QuoteModel quote;
  final bool showActions;
  final bool isCompact;
  final VoidCallback? onTap;

  const QuoteCard({
    super.key,
    required this.quote,
    this.showActions = true,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quote Text
              Text(
                '"${quote.text}"',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
                maxLines: isCompact ? 3 : null,
                overflow: isCompact ? TextOverflow.ellipsis : null,
              ),
              
              const SizedBox(height: 16),
              
              // Author and Actions Row
              Row(
                children: [
                  // Author
                  Expanded(
                    child: Text(
                      '— ${quote.author}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  
                  // Actions
                  if (showActions) ...[
                    // Copy Button
                    IconButton(
                      onPressed: () => _copyQuote(context),
                      icon: Icon(
                        Icons.copy_outlined,
                        size: 20,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      tooltip: 'Copy quote',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    
                    // Favorite Button
                    IconButton(
                      onPressed: () => _toggleFavorite(context),
                      icon: Icon(
                        quote.isFavorite 
                            ? Icons.favorite 
                            : Icons.favorite_border,
                        size: 20,
                        color: quote.isFavorite 
                            ? Colors.red 
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      tooltip: quote.isFavorite 
                          ? 'Remove from favorites' 
                          : 'Add to favorites',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ],
              ),
              
              // Category Tag (if available)
              if (quote.category != null && !isCompact) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    quote.category!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _copyQuote(BuildContext context) {
    FlutterClipboard.copy(quote.text);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Quote copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _toggleFavorite(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
    
    if (authProvider.currentUser == null) return;
    
    quoteProvider.toggleQuoteFavorite(
      authProvider.currentUser!.uid,
      quote,
    );
    
    // Show feedback
    final message = quote.isFavorite 
        ? 'Quote removed from favorites'
        : 'Quote added to favorites';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
