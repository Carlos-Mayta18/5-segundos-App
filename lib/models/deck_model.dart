import 'package:flutter/material.dart';

class GameDeck {
  final String id;
  final String title;
  final String subtitle;
  final String badgeText;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isPremium;
  final List<String> questions;

  const GameDeck({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isPremium,
    required this.questions,
  });

  LinearGradient get gradient => LinearGradient(
        colors: [primaryColor, secondaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

class DeckQuestion {
  final String deckId;
  final String deckTitle;
  final Color deckColor;
  final IconData deckIcon;
  final String prompt;

  const DeckQuestion({
    required this.deckId,
    required this.deckTitle,
    required this.deckColor,
    required this.deckIcon,
    required this.prompt,
  });
}
