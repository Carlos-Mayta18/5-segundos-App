import 'package:flutter/material.dart';
import '../data/punishments_data.dart';
import '../models/deck_model.dart';
import '../models/game_session.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/punishment_wheel_dialog.dart';
import 'victory_screen.dart';

enum TurnPhase {
  readyToStart, // Mostrando de quién es el turno y la consigna (o lista para revelar)
  running5Sec,  // Cuenta regresiva intensa de 5.0 segundos con tic-tac acelerado
  groupVerdict, // Sonó la campana: el grupo decide si logró decir las 3 cosas a tiempo
}

class GameplayScreen extends StatefulWidget {
  final GameMode mode;
  final List<GameDeck> activeDecks;
  final List<Player> players;
  final int targetScore;
  final PunishmentMode? initialPunishmentMode;

  const GameplayScreen({
    super.key,
    required this.mode,
    required this.activeDecks,
    this.players = const [],
    this.targetScore = 5,
    this.initialPunishmentMode,
  });

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen>
    with SingleTickerProviderStateMixin {
  late final ContinuousDeckShuffler _shuffler;
  late DeckQuestion _currentQuestion;
  late AnimationController _timerController;
  late PunishmentMode _punishmentMode;

  TurnPhase _phase = TurnPhase.readyToStart;
  int _currentPlayerIdx = 0;
  int _quickModeRound = 1;
  int _quickModeSuccessCount = 0;
  int _quickModeFailCount = 0;
  bool _hidePromptUntilStart = false;

  // Controla los pulsos de audio tic-tac acelerados durante los 5 segundos
  int _lastTickMilestone = -1;

  @override
  void initState() {
    super.initState();
    _shuffler = ContinuousDeckShuffler(widget.activeDecks);
    _currentQuestion = _shuffler.nextQuestion();

    // Si hay mazos +18 activos, por defecto activamos castigos de Fiesta; si no, Familiar
    if (widget.initialPunishmentMode != null) {
      _punishmentMode = widget.initialPunishmentMode!;
    } else {
      final hasAdultDeck = widget.activeDecks.any(
        (d) => d.id == 'noche_copas' || d.id == 'picante_confesiones',
      );
      _punishmentMode = hasAdultDeck ? PunishmentMode.party : PunishmentMode.family;
    }

    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..addListener(_onTimerTick)
     ..addStatusListener(_onTimerStatus);
  }

  void _onTimerTick() {
    if (_phase != TurnPhase.running5Sec) return;
    final double elapsed = _timerController.value; // 0.0 -> 1.0 (5 segundos)
    final double remainingRatio = 1.0 - elapsed;

    // Frecuencia de tic-tac acelerada:
    // 0s - 2s transcurridos: cada 500ms (milestones 0..3)
    // 2s - 3.5s transcurridos: cada 300ms (milestones 4..8)
    // 3.5s - 5.0s transcurridos: cada 180ms (milestones 9..17)
    final int msElapsed = (elapsed * 5000).round();
    int milestone;
    if (msElapsed < 2000) {
      milestone = msElapsed ~/ 500;
    } else if (msElapsed < 3500) {
      milestone = 4 + ((msElapsed - 2000) ~/ 300);
    } else {
      milestone = 9 + ((msElapsed - 3500) ~/ 180);
    }

    if (milestone != _lastTickMilestone) {
      _lastTickMilestone = milestone;
      SoundService.instance.playCountdownTick(remainingRatio);
    }
    setState(() {});
  }

  void _onTimerStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _phase == TurnPhase.running5Sec) {
      SoundService.instance.playTimeUpBell();
      setState(() {
        _phase = TurnPhase.groupVerdict;
      });
    }
  }

  void _start5SecondTimer() {
    _lastTickMilestone = -1;
    setState(() {
      _phase = TurnPhase.running5Sec;
    });
    _timerController.forward(from: 0.0);
  }

  void _skipCurrentQuestion() {
    if (_phase == TurnPhase.running5Sec) {
      _timerController.stop();
    }
    setState(() {
      _currentQuestion = _shuffler.nextQuestion();
      _phase = TurnPhase.readyToStart;
    });
  }

  Future<void> _submitVerdict(bool succeeded) async {
    if (succeeded) {
      SoundService.instance.playSuccess();
    } else {
      SoundService.instance.playFail();
      // Si el jugador falló y la Ruleta de Castigos está activa, abrimos la ruleta antes de pasar turno
      if (_punishmentMode != PunishmentMode.off && mounted) {
        final String? currentPlayerName = widget.mode == GameMode.competitive
            ? widget.players[_currentPlayerIdx].name
            : null;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => PunishmentWheelDialog(
            playerName: currentPlayerName,
            initialMode: _punishmentMode,
            onModeChanged: (newMode) {
              setState(() {
                _punishmentMode = newMode;
              });
            },
          ),
        );
      }
    }

    if (!mounted) return;

    if (widget.mode == GameMode.competitive) {
      final player = widget.players[_currentPlayerIdx];
      player.roundsPlayed++;
      if (succeeded) {
        player.score++;
        player.streak++;
      } else {
        player.streak = 0;
      }

      // Verificar si el jugador alcanzó la meta de puntos para ganar la partida
      if (player.score >= widget.targetScore) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VictoryScreen(
              players: widget.players,
              activeDecks: widget.activeDecks,
              targetScore: widget.targetScore,
            ),
          ),
        );
        return;
      }

      // Pasar al siguiente jugador en la mesa
      setState(() {
        _currentPlayerIdx = (_currentPlayerIdx + 1) % widget.players.length;
        _currentQuestion = _shuffler.nextQuestion();
        _phase = TurnPhase.readyToStart;
      });
    } else {
      // Modo Rápido / Casual sin fin
      setState(() {
        _quickModeRound++;
        if (succeeded) {
          _quickModeSuccessCount++;
        } else {
          _quickModeFailCount++;
        }
        _currentQuestion = _shuffler.nextQuestion();
        _phase = TurnPhase.readyToStart;
      });
    }
  }

  void _cyclePunishmentMode() {
    setState(() {
      if (_punishmentMode == PunishmentMode.family) {
        _punishmentMode = PunishmentMode.party;
      } else if (_punishmentMode == PunishmentMode.party) {
        _punishmentMode = PunishmentMode.off;
      } else {
        _punishmentMode = PunishmentMode.family;
      }
    });

    final String label = switch (_punishmentMode) {
      PunishmentMode.family => '🎭 Ruleta de Castigos: Modo Familiar / Sano',
      PunishmentMode.party => '🍻 Ruleta de Castigos: Modo Fiesta +18',
      PunishmentMode.off => '🚫 Ruleta de Castigos desactivada',
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Color _getTimerColor(double remainingRatio) {
    if (remainingRatio > 0.60) return AppTheme.neonCyan;
    if (remainingRatio > 0.35) return AppTheme.neonYellow;
    if (remainingRatio > 0.18) return AppTheme.neonOrange;
    return AppTheme.neonRed;
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double remainingRatio =
        _phase == TurnPhase.running5Sec ? (1.0 - _timerController.value) : 1.0;
    final double remainingSeconds = remainingRatio * 5.0;
    final Color activeTimerColor = _phase == TurnPhase.groupVerdict
        ? AppTheme.neonRed
        : _getTimerColor(remainingRatio);

    final Player? activePlayer = widget.mode == GameMode.competitive
        ? widget.players[_currentPlayerIdx]
        : null;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _phase == TurnPhase.running5Sec
                  ? activeTimerColor.withValues(alpha: 0.22)
                  : (_phase == TurnPhase.groupVerdict
                      ? AppTheme.neonRed.withValues(alpha: 0.25)
                      : AppTheme.bgDark),
              AppTheme.bgDark,
              const Color(0xFF0E0822),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Barra Superior (Salir, Marcador / Ronda, Ruleta Castigos, Audio)
              _buildTopHeader(activePlayer),

              // Marcador horizontal en Modo Competitivo
              if (widget.mode == GameMode.competitive) _buildCompetitiveScoreStrip(),

              // Área Central: Tarjeta de Pregunta + Reloj de 5 Segundos
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Indicador de Turno Actual
                      _buildTurnBanner(activePlayer),

                      // Carta Principal con la Consigna ("Menciona 3...")
                      _buildQuestionCard(activeTimerColor),

                      // Visualizador de Presión Sensorial (5 Segundos)
                      _buildCountdownVisualizer(remainingSeconds, remainingRatio, activeTimerColor),
                    ],
                  ),
                ),
              ),

              // Controles de Acción Inferior (Iniciar 5s / Veredicto del Grupo)
              _buildBottomControls(activeTimerColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(Player? activePlayer) {
    final Color rouletteColor = switch (_punishmentMode) {
      PunishmentMode.family => AppTheme.neonCyan,
      PunishmentMode.party => AppTheme.neonYellow,
      PunishmentMode.off => Colors.white38,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Salir de la partida',
            onPressed: () => _confirmExit(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.mode == GameMode.competitive
                      ? 'META: ${widget.targetScore} PUNTOS'
                      : 'MODO FIESTA SIN FIN • RONDA #$_quickModeRound',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: AppTheme.neonCyan,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cartas sin repetir: ${_shuffler.remainingCount + 1}/${_shuffler.totalPoolCount}',
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ),
          // Botón para cambiar modo de Ruleta de Castigos (Familiar / Fiesta / Off)
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _cyclePunishmentMode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: rouletteColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: rouletteColor.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.casino_rounded, size: 16, color: rouletteColor),
                  const SizedBox(width: 4),
                  Text(
                    switch (_punishmentMode) {
                      PunishmentMode.family => 'Sano',
                      PunishmentMode.party => '+18',
                      PunishmentMode.off => 'Off',
                    },
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: rouletteColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: _hidePromptUntilStart
                ? 'Modo: Revelar pregunta al iniciar 5s'
                : 'Modo: Leer pregunta antes de iniciar',
            onPressed: () {
              setState(() {
                _hidePromptUntilStart = !_hidePromptUntilStart;
              });
            },
            icon: Icon(
              _hidePromptUntilStart ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: _hidePromptUntilStart ? AppTheme.neonYellow : Colors.white60,
            ),
          ),
          IconButton(
            tooltip: 'Sonido Tic-Tac',
            onPressed: () {
              setState(() {
                SoundService.instance.soundEnabled = !SoundService.instance.soundEnabled;
              });
            },
            icon: Icon(
              SoundService.instance.soundEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: SoundService.instance.soundEnabled ? AppTheme.neonCyan : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitiveScoreStrip() {
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.players.length,
        itemBuilder: (context, index) {
          final p = widget.players[index];
          final isCurrent = index == _currentPlayerIdx;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isCurrent ? p.color.withValues(alpha: 0.25) : AppTheme.bgCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isCurrent ? p.color : Colors.white12,
                width: isCurrent ? 2 : 1,
              ),
              boxShadow: isCurrent ? AppTheme.neonGlow(p.color, blur: 10, spread: 0) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCurrent) ...[
                  Icon(Icons.bolt_rounded, color: p.color, size: 18),
                  const SizedBox(width: 4),
                ],
                Text(
                  p.name,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                    color: isCurrent ? Colors.white : Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${p.score}/${widget.targetScore}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: p.color,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTurnBanner(Player? activePlayer) {
    if (widget.mode == GameMode.competitive && activePlayer != null) {
      return Column(
        children: [
          const Text(
            'TURNO EN LA MESA PARA:',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: activePlayer.color,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.neonGlow(activePlayer.color, blur: 8),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  activePlayer.name.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: activePlayer.color.withValues(alpha: 0.7), blurRadius: 14),
                    ],
                  ),
                ),
              ),
              if (activePlayer.streak >= 2) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.neonOrange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.neonOrange),
                  ),
                  child: Text(
                    '🔥 Racha x${activePlayer.streak}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neonYellow,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    // Banner Modo Rápido / Casual
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _statPill(Icons.check_circle_rounded, '$_quickModeSuccessCount Logrados', AppTheme.neonGreen),
        const SizedBox(width: 12),
        _statPill(Icons.local_fire_department_rounded, '$_quickModeFailCount Castigos', AppTheme.neonPink),
      ],
    );
  }

  Widget _statPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Color activeTimerColor) {
    final bool concealText = _hidePromptUntilStart && _phase == TurnPhase.readyToStart;
    final Color borderColor = _phase == TurnPhase.running5Sec
        ? activeTimerColor
        : _currentQuestion.deckColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor, width: 2.2),
        boxShadow: AppTheme.neonGlow(
          borderColor,
          blur: _phase == TurnPhase.running5Sec ? 26 : 16,
          spread: _phase == TurnPhase.running5Sec ? 2 : 0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Etiqueta del Mazo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _currentQuestion.deckColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _currentQuestion.deckColor.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_currentQuestion.deckIcon, size: 15, color: _currentQuestion.deckColor),
                    const SizedBox(width: 6),
                    Text(
                      _currentQuestion.deckTitle.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: _currentQuestion.deckColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (_phase == TurnPhase.readyToStart)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white60,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _skipCurrentQuestion,
                  icon: const Icon(Icons.shuffle_rounded, size: 16),
                  label: const Text('Cambiar carta', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 22),

          // Texto Principal de la Consigna
          if (concealText)
            Column(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 44,
                  color: AppTheme.neonYellow.withValues(alpha: 0.85),
                ),
                const SizedBox(height: 10),
                const Text(
                  'CARTA OCULTA\nSe revelará al tocar "¡INICIAR 5 SEGUNDOS!"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white70,
                  ),
                ),
              ],
            )
          else
            Text(
              _currentQuestion.prompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1.28,
                color: Colors.white,
              ),
            ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildCountdownVisualizer(
    double remainingSeconds,
    double remainingRatio,
    Color activeTimerColor,
  ) {
    if (_phase == TurnPhase.readyToStart) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, color: AppTheme.neonCyan, size: 22),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'Lee la carta en voz alta y presiona iniciar para desatar los 5 segundos',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    if (_phase == TurnPhase.groupVerdict) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.neonRed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.neonRed, width: 2),
              boxShadow: AppTheme.neonGlow(AppTheme.neonRed, blur: 20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_active_rounded, color: AppTheme.neonYellow, size: 28),
                SizedBox(width: 10),
                Text(
                  '¡TIEMPO AGOTADO!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Veredicto del grupo: ¿Logró decir las 3 cosas a tiempo?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
        ],
      );
    }

    // Fase Activa: 5.0 segundos corriendo con barra de color cambiante
    return Column(
      children: [
        Text(
          '${remainingSeconds.toStringAsFixed(1)}s',
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w900,
            color: activeTimerColor,
            shadows: [
              Shadow(color: activeTimerColor, blurRadius: 24),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 20,
            width: double.infinity,
            child: LinearProgressIndicator(
              value: remainingRatio,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(activeTimerColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls(Color activeTimerColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _phase == TurnPhase.readyToStart
            ? SizedBox(
                key: const ValueKey('btn_start'),
                width: double.infinity,
                height: 66,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonPink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    elevation: 10,
                    shadowColor: AppTheme.neonPink,
                  ),
                  onPressed: _start5SecondTimer,
                  icon: const Icon(Icons.play_arrow_rounded, size: 34),
                  label: const Text(
                    '¡INICIAR 5 SEGUNDOS!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              )
            : _phase == TurnPhase.running5Sec
                ? SizedBox(
                    key: const ValueKey('btn_early_done'),
                    width: double.infinity,
                    height: 62,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: activeTimerColor, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        _timerController.stop();
                        SoundService.instance.playTimeUpBell();
                        setState(() {
                          _phase = TurnPhase.groupVerdict;
                        });
                      },
                      icon: Icon(Icons.stop_circle_rounded, color: activeTimerColor, size: 26),
                      label: const Text(
                        '¡TERMINÓ ANTES DE TIEMPO! (EVALUAR)',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  )
                : Row(
                    key: const ValueKey('verdict_row'),
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 66,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.neonRed,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 8,
                            ),
                            onPressed: () => _submitVerdict(false),
                            icon: Icon(
                              _punishmentMode != PunishmentMode.off
                                  ? Icons.casino_rounded
                                  : Icons.cancel_rounded,
                              size: 26,
                            ),
                            label: Text(
                              _punishmentMode != PunishmentMode.off
                                  ? '¡FALLÓ!\n(Girar Castigo)'
                                  : '¡FALLÓ!\n(0 pts)',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SizedBox(
                          height: 66,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.neonGreen,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 8,
                            ),
                            onPressed: () => _submitVerdict(true),
                            icon: const Icon(Icons.check_circle_rounded, size: 28),
                            label: Text(
                              widget.mode == GameMode.competitive
                                  ? '¡LO LOGRÓ!\n(+1 Punto)'
                                  : '¡LO LOGRÓ!\n(Se salva)',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
    _timerController.stop();
    final bool? leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Salir de la partida?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Se perderá el progreso de la ronda actual y volverás al menú principal.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Seguir jugando'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir al menú', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (leave == true && context.mounted) {
      Navigator.pop(context);
    }
  }
}
