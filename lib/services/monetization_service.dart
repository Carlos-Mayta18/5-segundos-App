import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Configuración central de IDs de Google AdMob y Google Play Billing.
///
/// IMPORTANTE PARA PASAR A ANUNCIOS REALES:
/// 1. Crea tu cuenta en https://admob.google.com y registra la app Android.
/// 2. Reemplaza el APPLICATION_ID en `android/app/src/main/AndroidManifest.xml`.
/// 3. Reemplaza los 3 AdUnitIds de abajo por los bloques de anuncios creados en tu AdMob.
/// 4. Agrega el ID de tu teléfono en [testDeviceIds] para que AdMob no suspenda tu cuenta
///    por hacer clic en tus propios anuncios durante tus pruebas.
class MonetizationConfig {
  // Cambia estos 3 IDs por los tuyos de AdMob cuando quieras usar anuncios propios:
  static const String androidBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String androidInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String androidRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  // Agrega aquí el ID de dispositivo de prueba que aparece en la consola Logcat al correr en tu celular
  static const List<String> testDeviceIds = <String>[];

  // ID del producto de compra única en Google Play Console (Productos integrados)
  static const String proLifetimeProductId = 'reto5_pro_sin_anuncios';
  static const String proPriceDisplay = '\$2.99 USD';

  static bool get isAndroidMobile =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}

class MonetizationService extends ChangeNotifier {
  static final MonetizationService instance = MonetizationService._internal();
  MonetizationService._internal();

  static const String _prefProKey = 'is_pro_lifetime_unlocked';

  bool _isPro = false;
  final Set<String> _sessionUnlockedDecks = {};
  int _completedMatchesCount = 0;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool get isPro => _isPro;

  bool isDeckUnlocked(String deckId, bool isPremiumDeck) {
    if (!isPremiumDeck) return true;
    if (_isPro) return true;
    return _sessionUnlockedDecks.contains(deckId);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool(_prefProKey) ?? false;

    if (MonetizationConfig.isAndroidMobile && !_isPro) {
      await MobileAds.instance.initialize();
      if (MonetizationConfig.testDeviceIds.isNotEmpty) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: MonetizationConfig.testDeviceIds),
        );
      }
      _preloadInterstitialAd();
      _preloadRewardedAd();
    }
    notifyListeners();
  }

  void _preloadInterstitialAd() {
    if (!MonetizationConfig.isAndroidMobile || _isPro) return;
    InterstitialAd.load(
      adUnitId: MonetizationConfig.androidInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  void _preloadRewardedAd() {
    if (!MonetizationConfig.isAndroidMobile || _isPro) return;
    RewardedAd.load(
      adUnitId: MonetizationConfig.androidRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
        },
      ),
    );
  }

  /// Desbloquea un mazo temático prémium viendo un video publicitario corto.
  /// En Android usa el SDK real de AdMob (`RewardedAd`); en Web o si aún no cargó usa el fallback interactivo.
  Future<bool> showRewardedAdToUnlockDeck(
    BuildContext context, {
    required String deckId,
    required String deckTitle,
  }) async {
    if (_isPro) return true;

    // 1. Si estamos en Android y el anuncio real de AdMob ya está pre-cargado:
    if (MonetizationConfig.isAndroidMobile && _rewardedAd != null) {
      final Completer<bool> completer = Completer<bool>();
      bool rewardEarned = false;

      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          _preloadRewardedAd();
          if (!completer.isCompleted) completer.complete(rewardEarned);
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          _rewardedAd = null;
          _preloadRewardedAd();
          if (!completer.isCompleted) completer.complete(false);
        },
      );

      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          rewardEarned = true;
          _sessionUnlockedDecks.add(deckId);
          notifyListeners();
        },
      );

      return completer.future;
    }

    // 2. En navegador Web o mientras carga la red en desarrollo:
    if (!context.mounted) return false;
    final bool? watched = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SimulatedRewardedAdDialog(deckTitle: deckTitle),
    );

    if (watched == true) {
      _sessionUnlockedDecks.add(deckId);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Muestra anuncio intersticial discreto únicamente entre partidas completas.
  Future<void> onMatchCompleted(BuildContext context) async {
    if (_isPro) return;
    _completedMatchesCount++;
    if (_completedMatchesCount < 1) return;

    // 1. En Android con AdMob real cargado:
    if (MonetizationConfig.isAndroidMobile && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _preloadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          _interstitialAd = null;
          _preloadInterstitialAd();
        },
      );
      await _interstitialAd!.show();
      return;
    }

    // 2. Fallback en Web / Desarrollo:
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const _SimulatedInterstitialAdDialog(),
      );
    }
  }

  /// Compra única y definitiva para eliminar la publicidad y desbloquear todo el catálogo de por vida.
  Future<bool> purchaseProLifetime(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.neonYellow, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: AppTheme.neonYellow, size: 30),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Reto 5 Segundos PRO',
                style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Desbloquea la experiencia completa para todas tus fiestas con un único pago:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            _benefitRow(Icons.lock_open_rounded, 'Todos los mazos (+220 cartas) desbloqueados de por vida'),
            const SizedBox(height: 10),
            _benefitRow(Icons.block_rounded, 'Cero anuncios publicitarios para siempre'),
            const SizedBox(height: 10),
            _benefitRow(Icons.wifi_off_rounded, '100% disponible sin conexión en cualquier lugar'),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: AppTheme.neonCyan, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Google Play Billing\nSKU: ${MonetizationConfig.proLifetimeProductId}',
                      style: TextStyle(fontSize: 11.5, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonYellow,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.shopping_bag_rounded, size: 18),
            label: const Text(
              'Comprar (${MonetizationConfig.proPriceDisplay})',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefProKey, true);
      _isPro = true;
      _interstitialAd?.dispose();
      _rewardedAd?.dispose();
      _interstitialAd = null;
      _rewardedAd = null;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Permite restaurar a estado gratuito durante pruebas de desarrollo.
  Future<void> resetProForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefProKey, false);
    _isPro = false;
    _sessionUnlockedDecks.clear();
    _preloadInterstitialAd();
    _preloadRewardedAd();
    notifyListeners();
  }

  static Widget _benefitRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.neonGreen, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

/// Widget de Banner Publicitario discreto que en Android renderiza el `BannerAd` real de AdMob
/// y en Web muestra el banner simulado de vista previa.
class NonIntrusiveAdBanner extends StatefulWidget {
  const NonIntrusiveAdBanner({super.key});

  @override
  State<NonIntrusiveAdBanner> createState() => _NonIntrusiveAdBannerState();
}

class _NonIntrusiveAdBannerState extends State<NonIntrusiveAdBanner> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRealBannerIfAndroid();
  }

  void _loadRealBannerIfAndroid() {
    if (!MonetizationConfig.isAndroidMobile || MonetizationService.instance.isPro) return;

    _bannerAd = BannerAd(
      adUnitId: MonetizationConfig.androidBannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isBannerLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isBannerLoaded = false;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MonetizationService.instance,
      builder: (context, _) {
        if (MonetizationService.instance.isPro) {
          return const SizedBox.shrink();
        }

        // Si estamos en Android y el Banner real de AdMob ya cargó, lo mostramos nativamente:
        if (MonetizationConfig.isAndroidMobile && _isBannerLoaded && _bannerAd != null) {
          return Container(
            alignment: Alignment.center,
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: AdWidget(ad: _bannerAd!),
          );
        }

        // Fallback en navegador Web o mientras carga el banner en Android:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF120C24),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.neonYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.neonYellow, width: 0.8),
                ),
                child: const Text(
                  'AD',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.neonYellow,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Google AdMob Banner • Pásate a PRO para quitar anuncios',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => MonetizationService.instance.purchaseProLifetime(context),
                child: const Text(
                  'Quitar',
                  style: TextStyle(
                    color: AppTheme.neonCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SimulatedRewardedAdDialog extends StatefulWidget {
  final String deckTitle;
  const _SimulatedRewardedAdDialog({required this.deckTitle});

  @override
  State<_SimulatedRewardedAdDialog> createState() => _SimulatedRewardedAdDialogState();
}

class _SimulatedRewardedAdDialogState extends State<_SimulatedRewardedAdDialog> {
  int _secondsLeft = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppTheme.neonCyan, width: 1.5),
      ),
      title: Row(
        children: [
          const Icon(Icons.play_circle_fill_rounded, color: AppTheme.neonCyan),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _secondsLeft > 0 ? 'Anuncio de Recompensa ($_secondsLeft s)' : '¡Recompensa Lista!',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppTheme.pinkPurpleGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _secondsLeft > 0 ? Icons.ondemand_video_rounded : Icons.lock_open_rounded,
                  size: 46,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  _secondsLeft > 0
                      ? 'Reproduciendo AdMob Rewarded Test...'
                      : 'Mazo "${widget.deckTitle}" desbloqueado',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'En un celular Android se reproduce el video real de Google AdMob.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.white54),
          ),
        ],
      ),
      actions: [
        if (_secondsLeft > 0)
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cerrar sin recompensa', style: TextStyle(color: Colors.white54)),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _secondsLeft == 0 ? AppTheme.neonGreen : Colors.white12,
            foregroundColor: Colors.black,
          ),
          onPressed: _secondsLeft == 0 ? () => Navigator.pop(context, true) : null,
          child: Text(
            _secondsLeft == 0 ? '¡Jugar Mazo Ahora!' : 'Espera $_secondsLeft s...',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _SimulatedInterstitialAdDialog extends StatelessWidget {
  const _SimulatedInterstitialAdDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.white24),
      ),
      title: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Publicidad Fin de Partida', style: TextStyle(fontSize: 15, color: Colors.white70)),
          Icon(Icons.ads_click_rounded, color: AppTheme.neonYellow, size: 20),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Este anuncio solo aparece al terminar una partida completa y nunca interrumpe los turnos de 5 segundos.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              MonetizationService.instance.purchaseProLifetime(context);
            },
            icon: const Icon(Icons.workspace_premium_rounded, color: AppTheme.neonYellow),
            label: const Text('Eliminar anuncios para siempre'),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Continuar al Podio'),
        ),
      ],
    );
  }
}
