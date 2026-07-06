import 'package:flutter/material.dart';

class CategoryStyle {
  final String emoji;
  final Color bgColor;
  final Color textColor;
  final String displayName;

  const CategoryStyle({
    required this.emoji,
    required this.bgColor,
    required this.textColor,
    required this.displayName,
  });
}

class CategoryUtils {
  CategoryUtils._();

  static const List<String> filterTags = [
    'All',
    'Environment',
    'Education',
    'Community',
    'Healthcare',
    'Animals',
  ];

  static const _styles = {
    'environment': CategoryStyle(
      emoji: '🌱',
      bgColor: Color(0xFFDCFCE7),
      textColor: Color(0xFF15803D),
      displayName: 'Environment',
    ),
    'education': CategoryStyle(
      emoji: '📚',
      bgColor: Color(0xFFDBEAFE),
      textColor: Color(0xFF1D4ED8),
      displayName: 'Education',
    ),
    'community': CategoryStyle(
      emoji: '🤝',
      bgColor: Color(0xFFF3E8FF),
      textColor: Color(0xFF7E22CE),
      displayName: 'Community',
    ),
    'animals': CategoryStyle(
      emoji: '🐾',
      bgColor: Color(0xFFFEF9C3),
      textColor: Color(0xFFA16207),
      displayName: 'Animals',
    ),
    'healthcare': CategoryStyle(
      emoji: '❤️',
      bgColor: Color(0xFFFEE2E2),
      textColor: Color(0xFFB91C1C),
      displayName: 'Healthcare',
    ),
  };

  static const _defaultStyle = CategoryStyle(
    emoji: '✨',
    bgColor: Color(0xFFF1F5F9),
    textColor: Color(0xFF475569),
    displayName: 'Other',
  );

  static CategoryStyle getStyle(String category) {
    return _styles[category.toLowerCase()] ?? _defaultStyle;
  }

  static CategoryStyle getStyleFromList(List<String> categories) {
    if (categories.isEmpty) return _defaultStyle;
    return getStyle(categories.first);
  }
}
