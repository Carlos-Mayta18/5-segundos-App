import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'deck_model.dart';

enum GameMode {
  competitive, // Por puntos, registro de participantes y meta para ganar
  quick,       // Modo Rápido / Casual sin fin, sin nombres ni puntajes
}

class Player {
  final String id;
  final String name;
  int score;
  int roundsPlayed;
  int streak;
  final Color color;

  Player({
    required this.id,
    required this.name,
    required this.color,
    this.score = 0,
    this.roundsPlayed = 0,
    this.streak = 0,
  });

  static const List<Color> avatarPalette = [
    AppTheme.neonPink,
    AppTheme.neonCyan,
    AppTheme.neonYellow,
    AppTheme.neonGreen,
    AppTheme.neonPurple,
    AppTheme.neonOrange,
  ];
}

/// Sistema de barajado continuo sin repetición (Offline-First).
/// Garantiza que ninguna pregunta se repita durante una sesión
/// hasta agotar el 100% del repertorio de los mazos seleccionados.
class ContinuousDeckShuffler {
  final List<DeckQuestion> _fullPool = [];
  final List<DeckQuestion> _remainingQueue = [];
  final Random _random = Random();
  int _cyclesCompleted = 0;

  ContinuousDeckShuffler(List<GameDeck> activeDecks) {
    for (final deck in activeDecks) {
      for (final q in deck.questions) {
        _fullPool.add(
          DeckQuestion(
            deckId: deck.id,
            deckTitle: deck.title,
            deckColor: deck.primaryColor,
            deckIcon: deck.icon,
            prompt: q,
          ),
        );
      }
    }
    _refillAndShuffle();
  }

  void _refillAndShuffle() {
    _remainingQueue.clear();
    _remainingQueue.addAll(_fullPool);
    // Algoritmo Fisher-Yates para barajado uniforme
    for (int i = _remainingQueue.length - 1; i > 0; i--) {
      final int j = _random.nextInt(i + 1);
      final temp = _remainingQueue[i];
      _remainingQueue[i] = _remainingQueue[j];
      _remainingQueue[j] = temp;
    }
  }

  DeckQuestion nextQuestion() {
    if (_remainingQueue.isEmpty) {
      _cyclesCompleted++;
      _refillAndShuffle();
    }
    return _remainingQueue.removeLast();
  }

  int get remainingCount => _remainingQueue.length;
  int get totalPoolCount => _fullPool.length;
  int get cyclesCompleted => _cyclesCompleted;
}
