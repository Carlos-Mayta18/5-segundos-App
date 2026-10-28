import 'package:flutter/material.dart';
import '../data/decks_data.dart';
import '../models/deck_model.dart';
import '../models/game_session.dart';
import '../services/monetization_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'gameplay_screen.dart';
import 'player_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _selectedDeckIds = {'clasico_familiar'};

  List<GameDeck> get _selectedDecks => DecksRepository.allDecks
      .where((deck) => _selectedDeckIds.contains(deck.id))
      .toList();

  Future<void> _onDeckTap(GameDeck deck) async {
    final bool unlocked = MonetizationService.instance.isDeckUnlocked(deck.id, deck.isPremium);

    if (!unlocked) {
      _showUnlockDeckSheet(deck);
      return;
    }

    setState(() {
      if (_selectedDeckIds.contains(deck.id)) {
        if (_selectedDeckIds.length > 1) {
          _selectedDeckIds.remove(deck.id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Debes mantener al menos 1 mazo seleccionado para jugar.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        _selectedDeckIds.add(deck.id);
      }
    });
  }

  void _showUnlockDeckSheet(GameDeck deck) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: deck.gradient,
                boxShadow: AppTheme.neonGlow(deck.primaryColor),
              ),
              child: Icon(deck.icon, size: 38, color: Colors.black),
            ),
            const SizedBox(height: 14),
            Text(
              'Desbloquear "${deck.title}"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              '${deck.questions.length} cartas intensas: ${deck.subtitle}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13.5),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final ok = await MonetizationService.instance.showRewardedAdToUnlockDeck(
                    context,
                    deckId: deck.id,
                    deckTitle: deck.title,
                  );
                  if (ok && mounted) {
                    setState(() {
                      _selectedDeckIds.add(deck.id);
                    });
                  }
                },
                icon: const Icon(Icons.play_circle_fill_rounded),
                label: const Text(
                  'VER VIDEO CORTO (GRATIS HOY)',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.neonYellow, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final ok = await MonetizationService.instance.purchaseProLifetime(context);
                  if (ok && mounted) {
                    setState(() {
                      _selectedDeckIds.add(deck.id);
                    });
                  }
                },
                icon: const Icon(Icons.workspace_premium_rounded, color: AppTheme.neonYellow),
                label: const Text(
                  'DESBLOQUEAR TODO SIN ANUNCIOS (PRO)',
                  style: TextStyle(
                    color: AppTheme.neonYellow,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHowToPlayDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.neonCyan, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: AppTheme.neonYellow, size: 28),
            SizedBox(width: 8),
            Text('¿Cómo se juega?', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RuleStep(
              num: '1',
              title: 'Un solo teléfono en la mesa',
              desc: 'Pásense el celular o déjenlo al centro. No hace falta internet.',
            ),
            SizedBox(height: 12),
            _RuleStep(
              num: '2',
              title: 'Lee la consigna ("Menciona 3...")',
              desc: 'Al tocar "¡INICIAR 5 SEGUNDOS!", comienza el tic-tac acelerado.',
            ),
            SizedBox(height: 12),
            _RuleStep(
              num: '3',
              title: '¡Responde sin filtro!',
              desc: 'El jugador tiene exactamente 5 segundos antes de que suene la campana.',
            ),
            SizedBox(height: 12),
            _RuleStep(
              num: '4',
              title: 'Veredicto democrático',
              desc: 'El grupo vota si logró decir las 3 cosas a tiempo (+1 pto) o si falló.',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonPink,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('¡Entendido!', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalQuestionsSelected = _selectedDecks.fold<int>(
      0,
      (sum, d) => sum + d.questions.length,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainBgGradient),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: MonetizationService.instance,
            builder: (context, _) {
              final isPro = MonetizationService.instance.isPro;
              return Column(
                children: [
                  // Barra Superior (Reglas, Audio, Botón PRO)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: '¿Cómo se juega?',
                          onPressed: _showHowToPlayDialog,
                          icon: const Icon(Icons.help_outline_rounded, color: Colors.white70),
                        ),
                        IconButton(
                          tooltip: 'Activar/Desactivar sonidos',
                          onPressed: () {
                            setState(() {
                              SoundService.instance.soundEnabled =
                                  !SoundService.instance.soundEnabled;
                            });
                          },
                          icon: Icon(
                            SoundService.instance.soundEnabled
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            color: SoundService.instance.soundEnabled
                                ? AppTheme.neonCyan
                                : Colors.white38,
                          ),
                        ),
                        const Spacer(),
                        if (!isPro)
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => MonetizationService.instance.purchaseProLifetime(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: AppTheme.goldOrangeGradient,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: AppTheme.neonGlow(AppTheme.neonYellow, blur: 12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.workspace_premium_rounded,
                                      size: 17, color: Colors.black),
                                  SizedBox(width: 5),
                                  Text(
                                    'VERSIÓN PRO',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            onLongPress: () =>
                                MonetizationService.instance.resetProForTesting(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.neonGreen.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.neonGreen),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.verified_rounded,
                                      size: 16, color: AppTheme.neonGreen),
                                  SizedBox(width: 5),
                                  Text(
                                    'PRO ACTIVO',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.neonGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Hero Logo: Reto 5 Segundos
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.neonPink.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.6)),
                          ),
                          child: const Text(
                            '⚡ PARTY GAME PRESENCIAL • 100% OFFLINE',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.3,
                              color: AppTheme.neonPink,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'RETO 5 SEGUNDOS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 33,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: AppTheme.neonPink, blurRadius: 22),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Piensa rápido o suelta una locura antes de que suene la campana',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Título de Selección de Mazos
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ELIGE TUS MAZOS TEMÁTICOS',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          '$totalQuestionsSelected cartas listas',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.neonCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Grid de los 4 Mazos Temáticos
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.92,
                      ),
                      itemCount: DecksRepository.allDecks.length,
                      itemBuilder: (context, index) {
                        final deck = DecksRepository.allDecks[index];
                        final isUnlocked =
                            MonetizationService.instance.isDeckUnlocked(deck.id, deck.isPremium);
                        final isSelected = _selectedDeckIds.contains(deck.id) && isUnlocked;

                        return InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => _onDeckTap(deck),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? deck.primaryColor.withValues(alpha: 0.17)
                                  : AppTheme.bgCard,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isSelected ? deck.primaryColor : Colors.white12,
                                width: isSelected ? 2.4 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? AppTheme.neonGlow(deck.primaryColor, blur: 14, spread: 0)
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(
                                        color: deck.primaryColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        deck.icon,
                                        color: deck.primaryColor,
                                        size: 24,
                                      ),
                                    ),
                                    if (!isUnlocked)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.neonYellow.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppTheme.neonYellow),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.lock_rounded,
                                                size: 13, color: AppTheme.neonYellow),
                                            SizedBox(width: 3),
                                            Text(
                                              'PRO / AD',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w900,
                                                color: AppTheme.neonYellow,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle_rounded
                                            : Icons.radio_button_unchecked_rounded,
                                        color: isSelected ? deck.primaryColor : Colors.white30,
                                        size: 24,
                                      ),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${deck.badgeText} • ${deck.questions.length} CARTAS',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      color: deck.primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  deck.title,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  deck.subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.white60,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Botones de Modos de Juego
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
                    child: Column(
                      children: [
                        // Modo Competitivo (Por puntos)
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.neonPink,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 8,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlayerSetupScreen(
                                    selectedDecks: _selectedDecks,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.emoji_events_rounded, size: 24),
                            label: const Text(
                              'MODO COMPETITIVO (POR PUNTOS)',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Modo Rápido / Casual (Sin fin)
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.neonCyan, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GameplayScreen(
                                    mode: GameMode.quick,
                                    activeDecks: _selectedDecks,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.flash_on_rounded,
                              color: AppTheme.neonCyan,
                              size: 22,
                            ),
                            label: const Text(
                              'MODO RÁPIDO / CASUAL (SIN REGISTRO)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.neonCyan,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Banner de publicidad no intrusiva solo en menú principal
                  const NonIntrusiveAdBanner(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RuleStep extends StatelessWidget {
  final String num;
  final String title;
  final String desc;

  const _RuleStep({
    required this.num,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.neonPink,
          ),
          child: Text(
            num,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
