import 'package:flutter/material.dart';
import '../models/deck_model.dart';
import '../models/game_session.dart';
import '../services/monetization_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'gameplay_screen.dart';

class VictoryScreen extends StatefulWidget {
  final List<Player> players;
  final List<GameDeck> activeDecks;
  final int targetScore;

  const VictoryScreen({
    super.key,
    required this.players,
    required this.activeDecks,
    required this.targetScore,
  });

  @override
  State<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<VictoryScreen> {
  @override
  void initState() {
    super.initState();
    SoundService.instance.playSuccess();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MonetizationService.instance.onMatchCompleted(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = [...widget.players]..sort((a, b) => b.score.compareTo(a.score));
    final winner = sortedPlayers.first;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainBgGradient),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Trofeo Neón
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.goldOrangeGradient,
                  boxShadow: AppTheme.neonGlow(AppTheme.neonYellow, blur: 32, spread: 4),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 58,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¡TENEMOS CAMPEÓN!',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  color: AppTheme.neonYellow,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                winner.name.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: winner.color.withValues(alpha: 0.8),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: winner.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: winner.color, width: 1.5),
                ),
                child: Text(
                  '${winner.score} Respuestas Válidas en 5 Segundos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: winner.color,
                    fontSize: 13.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'TABLA DE POSICIONES',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: Colors.white60,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: sortedPlayers.length,
                  itemBuilder: (context, index) {
                    final player = sortedPlayers[index];
                    final isFirst = index == 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isFirst ? player.color.withValues(alpha: 0.16) : AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isFirst ? player.color : Colors.white12,
                          width: isFirst ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFirst ? AppTheme.neonYellow : Colors.white10,
                            ),
                            child: Text(
                              '#${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: isFirst ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  player.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Turnos jugados: ${player.roundsPlayed}',
                                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: player.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '${player.score} pts',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: player.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.white30, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        icon: const Icon(Icons.home_rounded, color: Colors.white),
                        label: const Text(
                          'Menú',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonPink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                        ),
                        onPressed: () {
                          // Reiniciar puntajes manteniendo jugadores
                          final resetPlayers = widget.players
                              .map((p) => Player(id: p.id, name: p.name, color: p.color))
                              .toList();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GameplayScreen(
                                mode: GameMode.competitive,
                                activeDecks: widget.activeDecks,
                                players: resetPlayers,
                                targetScore: widget.targetScore,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text(
                          '¡JUGAR REVANCHA!',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const NonIntrusiveAdBanner(),
            ],
          ),
        ),
      ),
    );
  }
}
