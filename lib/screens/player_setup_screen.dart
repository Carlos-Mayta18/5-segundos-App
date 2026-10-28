import 'package:flutter/material.dart';
import '../data/punishments_data.dart';
import '../models/deck_model.dart';
import '../models/game_session.dart';
import '../services/monetization_service.dart';
import '../theme/app_theme.dart';
import 'gameplay_screen.dart';

class PlayerSetupScreen extends StatefulWidget {
  final List<GameDeck> selectedDecks;

  const PlayerSetupScreen({
    super.key,
    required this.selectedDecks,
  });

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<String> _playerNames = ['Jugador 1', 'Jugador 2'];
  int _targetScore = 5;
  late PunishmentMode _punishmentMode;

  @override
  void initState() {
    super.initState();
    final hasAdultDeck = widget.selectedDecks.any(
      (d) => d.id == 'noche_copas' || d.id == 'picante_confesiones',
    );
    _punishmentMode = hasAdultDeck ? PunishmentMode.party : PunishmentMode.family;
  }

  void _addPlayer() {
    final text = _nameController.text.trim();
    if (text.isEmpty) return;
    if (_playerNames.length >= 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 12 jugadores por partida.')),
      );
      return;
    }
    setState(() {
      _playerNames.add(text);
      _nameController.clear();
    });
  }

  void _removePlayer(int index) {
    if (_playerNames.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se necesitan al menos 2 jugadores para competir.')),
      );
      return;
    }
    setState(() {
      _playerNames.removeAt(index);
    });
  }

  void _startGame() {
    final players = List<Player>.generate(
      _playerNames.length,
      (i) => Player(
        id: 'p_$i',
        name: _playerNames[i],
        color: Player.avatarPalette[i % Player.avatarPalette.length],
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameplayScreen(
          mode: GameMode.competitive,
          activeDecks: widget.selectedDecks,
          players: players,
          targetScore: _targetScore,
          initialPunishmentMode: _punishmentMode,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CONFIGURAR COMPETENCIA'),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainBgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    // Meta de Puntos
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.emoji_events_rounded, color: AppTheme.neonYellow),
                              SizedBox(width: 8),
                              Text(
                                'META PARA GANAR LA PARTIDA',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13.5,
                                  letterSpacing: 1.1,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'El primer jugador en lograr esta cantidad de respuestas válidas en 5 segundos gana:',
                            style: TextStyle(fontSize: 12.5, color: Colors.white60),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [3, 5, 7, 10].map((pts) {
                              final selected = _targetScore == pts;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => setState(() => _targetScore = pts),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppTheme.neonCyan.withValues(alpha: 0.2)
                                            : Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: selected ? AppTheme.neonCyan : Colors.white12,
                                          width: selected ? 2 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            '$pts',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              color: selected ? AppTheme.neonCyan : Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'puntos',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: selected ? AppTheme.neonCyan : Colors.white54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Ruleta de Castigos al Fallar
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.casino_rounded, color: AppTheme.neonPink),
                              SizedBox(width: 8),
                              Text(
                                'RULETA DE CASTIGOS (CUANDO ALGUIEN FALLA)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 0.8,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildPunishmentOption(
                                mode: PunishmentMode.family,
                                label: '🎭 Sano / Familiar',
                                color: AppTheme.neonCyan,
                              ),
                              const SizedBox(width: 8),
                              _buildPunishmentOption(
                                mode: PunishmentMode.party,
                                label: '🍻 Fiesta / Tragos',
                                color: AppTheme.neonYellow,
                              ),
                              const SizedBox(width: 8),
                              _buildPunishmentOption(
                                mode: PunishmentMode.off,
                                label: '🚫 Sin Ruleta',
                                color: Colors.white54,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Agregar Participantes
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.group_add_rounded, color: AppTheme.neonPink),
                                  SizedBox(width: 8),
                                  Text(
                                    'JUGADORES EN LA MESA',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13.5,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${_playerNames.length}/12',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.neonPink,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameController,
                                  textCapitalization: TextCapitalization.words,
                                  onSubmitted: (_) => _addPlayer(),
                                  decoration: InputDecoration(
                                    hintText: 'Nombre del amigo/a...',
                                    hintStyle: const TextStyle(color: Colors.white38),
                                    filled: true,
                                    fillColor: Colors.black26,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Colors.white24),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.neonPink,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _addPlayer,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text(
                                  'Añadir',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ...List.generate(_playerNames.length, (index) {
                            final color =
                                Player.avatarPalette[index % Player.avatarPalette.length];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: color.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: color.withValues(alpha: 0.25),
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _playerNames[index],
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _removePlayer(index),
                                    icon: const Icon(
                                      Icons.remove_circle_outline_rounded,
                                      color: Colors.white54,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Botón Iniciar Partida Competitiva
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 62,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonPink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                    ),
                    onPressed: _startGame,
                    icon: const Icon(Icons.rocket_launch_rounded, size: 26),
                    label: const Text(
                      '¡COMENZAR PARTIDA!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ),

              // Publicidad no intrusiva solo en configuración
              const NonIntrusiveAdBanner(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPunishmentOption({
    required PunishmentMode mode,
    required String label,
    required Color color,
  }) {
    final bool selected = _punishmentMode == mode;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _punishmentMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : Colors.white12,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: selected ? color : Colors.white60,
            ),
          ),
        ),
      ),
    );
  }
}
