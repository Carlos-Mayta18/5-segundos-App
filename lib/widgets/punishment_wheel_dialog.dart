import 'dart:math';
import 'package:flutter/material.dart';
import '../data/punishments_data.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class PunishmentWheelDialog extends StatefulWidget {
  final String? playerName;
  final PunishmentMode initialMode;
  final ValueChanged<PunishmentMode>? onModeChanged;

  const PunishmentWheelDialog({
    super.key,
    this.playerName,
    required this.initialMode,
    this.onModeChanged,
  });

  @override
  State<PunishmentWheelDialog> createState() => _PunishmentWheelDialogState();
}

class _PunishmentWheelDialogState extends State<PunishmentWheelDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _rotationAnim;
  late PunishmentMode _mode;

  final Random _random = Random();
  double _currentAngle = 0.0;
  int? _selectedSliceIndex;
  String? _selectedPunishmentText;
  bool _isSpinning = false;
  int _lastTickSlice = -1;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode == PunishmentMode.off
        ? PunishmentMode.family
        : widget.initialMode;

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2900),
    );

    _rotationAnim = CurvedAnimation(
      parent: _spinController,
      curve: Curves.decelerate,
    );

    _spinController.addListener(_onSpinTick);
    _spinController.addStatusListener(_onSpinStatus);
  }

  void _onSpinTick() {
    if (!_isSpinning) return;
    final int numSlices = PunishmentsRepository.wheelSlices.length;
    final double sliceAngle = (2 * pi) / numSlices;
    final int currentSlice = (_currentAngle / sliceAngle).floor() % numSlices;

    if (currentSlice != _lastTickSlice) {
      _lastTickSlice = currentSlice;
      // Pulso acústico de ruleta conforme desacelera
      SoundService.instance.playCountdownTick(1.0 - _spinController.value * 0.7);
    }
  }

  void _onSpinStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _isSpinning) {
      final int numSlices = PunishmentsRepository.wheelSlices.length;
      final double sliceAngle = (2 * pi) / numSlices;
      // El puntero está arriba (-pi / 2). Calculamos qué gajo quedó bajo el puntero:
      final double normalized = ((-pi / 2) - _currentAngle) % (2 * pi);
      final double positiveAngle = normalized < 0 ? normalized + 2 * pi : normalized;
      final int landedIndex = (positiveAngle / sliceAngle).floor() % numSlices;

      _pickPunishmentForSlice(landedIndex);
      SoundService.instance.playSuccess();

      setState(() {
        _isSpinning = false;
        _selectedSliceIndex = landedIndex;
      });
    }
  }

  void _pickPunishmentForSlice(int sliceIdx) {
    final map = _mode == PunishmentMode.party
        ? PunishmentsRepository.partyPunishmentsBySlice
        : PunishmentsRepository.familyPunishmentsBySlice;
    final list = map[sliceIdx] ?? ['¡Haz 5 sentadillas o toma un trago!'];
    _selectedPunishmentText = list[_random.nextInt(list.length)];
  }

  void _spinWheel() {
    if (_isSpinning) return;

    final double startAngle = _currentAngle % (2 * pi);
    // Entre 5 y 8 vueltas completas + ángulo aleatorio
    final double extraSpins = (5 + _random.nextInt(3)) * 2 * pi;
    final double randomOffset = _random.nextDouble() * 2 * pi;
    final double targetAngle = startAngle + extraSpins + randomOffset;

    setState(() {
      _isSpinning = true;
      _selectedSliceIndex = null;
      _selectedPunishmentText = null;
      _lastTickSlice = -1;
    });

    _rotationAnim = Tween<double>(
      begin: startAngle,
      end: targetAngle,
    ).animate(
      CurvedAnimation(
        parent: _spinController,
        curve: const Cubic(0.12, 0.82, 0.18, 1.0),
      ),
    )..addListener(() {
        _currentAngle = _rotationAnim.value;
        setState(() {});
      });

    _spinController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slice = _selectedSliceIndex != null
        ? PunishmentsRepository.wheelSlices[_selectedSliceIndex!]
        : null;

    return Dialog(
      backgroundColor: AppTheme.bgCard,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: slice?.color ?? AppTheme.neonPink,
          width: 2,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabecera y selector de intensidad (Familiar vs Fiesta +18)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.casino_rounded, color: AppTheme.neonPink, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      widget.playerName != null
                          ? 'CASTIGO: ${widget.playerName!.toUpperCase()}'
                          : 'RULETA DE CASTIGOS',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Saltar castigo',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Interruptor de Modo de Castigos (Familiar vs Fiesta/Tragos)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModeTab(
                      mode: PunishmentMode.family,
                      label: '🎭 Familiar / Sano',
                      activeColor: AppTheme.neonCyan,
                    ),
                  ),
                  Expanded(
                    child: _buildModeTab(
                      mode: PunishmentMode.party,
                      label: '🍻 Fiesta / Tragos +18',
                      activeColor: AppTheme.neonYellow,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // La Ruleta Neón Giratoria
            SizedBox(
              width: 245,
              height: 245,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Sombra de neón exterior
                  Container(
                    width: 232,
                    height: 232,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.neonGlow(
                        slice?.color ?? AppTheme.neonPink,
                        blur: 24,
                        spread: 2,
                      ),
                    ),
                  ),

                  // Disco giratorio con los 8 gajos
                  Transform.rotate(
                    angle: _currentAngle,
                    child: CustomPaint(
                      size: const Size(228, 228),
                      painter: _NeonWheelPainter(
                        slices: PunishmentsRepository.wheelSlices,
                        highlightedIndex: _selectedSliceIndex,
                      ),
                    ),
                  ),

                  // Botón central "GIRAR"
                  GestureDetector(
                    onTap: _spinWheel,
                    child: Container(
                      width: 66,
                      height: 66,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.pinkPurpleGradient,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: AppTheme.neonGlow(AppTheme.neonPink, blur: 14),
                      ),
                      child: Text(
                        _isSpinning ? '...' : 'GIRAR',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Puntero indicador superior
                  Positioned(
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.neonGlow(AppTheme.neonYellow, blur: 10),
                      ),
                      child: const Icon(
                        Icons.arrow_drop_down_circle_rounded,
                        color: AppTheme.neonYellow,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Resultado del Castigo o Instrucción de giro
            if (slice != null && _selectedPunishmentText != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: slice.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: slice.color, width: 1.8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(slice.icon, color: slice.color, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          slice.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1.1,
                            color: slice.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedPunishmentText!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _isSpinning
                      ? '¡Girando la ruleta del destino...!'
                      : '¡Fallaste los 5 segundos! Toca la ruleta para descubrir tu reto o castigo.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                ),
              ),

            const SizedBox(height: 16),

            // Botones de acción inferiores
            if (_selectedPunishmentText == null)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonPink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isSpinning ? null : _spinWheel,
                  icon: const Icon(Icons.casino_rounded),
                  label: Text(
                    _isSpinning ? 'GIRANDO...' : '¡GIRAR RULETA DE CASTIGO!',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.white30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _spinWheel,
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
                      label: const Text(
                        'Girar otra vez',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text(
                        '¡CUMPLIDO! SIGUIENTE',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required PunishmentMode mode,
    required String label,
    required Color activeColor,
  }) {
    final bool selected = _mode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mode = mode;
          if (_selectedSliceIndex != null) {
            _pickPunishmentForSlice(_selectedSliceIndex!);
          }
        });
        widget.onModeChanged?.call(mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: selected ? activeColor : Colors.white60,
          ),
        ),
      ),
    );
  }
}

class _NeonWheelPainter extends CustomPainter {
  final List<PunishmentWheelSlice> slices;
  final int? highlightedIndex;

  _NeonWheelPainter({
    required this.slices,
    required this.highlightedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final double sliceAngle = (2 * pi) / slices.length;

    final Paint fillPaint = Paint()..style = PaintingStyle.fill;
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppTheme.bgDark
      ..strokeWidth = 2.5;

    for (int i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final double startAngle = i * sliceAngle;
      final bool isHighlighted = highlightedIndex == i;

      fillPaint.color = isHighlighted
          ? slice.color
          : slice.color.withValues(alpha: 0.78);

      canvas.drawArc(rect, startAngle, sliceAngle, true, fillPaint);
      canvas.drawArc(rect, startAngle, sliceAngle, true, borderPaint);

      // Dibujar ícono de cada gajo
      final double midAngle = startAngle + sliceAngle / 2;
      final double iconRadius = radius * 0.66;
      final Offset iconOffset = Offset(
        center.dx + iconRadius * cos(midAngle),
        center.dy + iconRadius * sin(midAngle),
      );

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(slice.icon.codePoint),
          style: TextStyle(
            fontSize: 22,
            fontFamily: slice.icon.fontFamily,
            package: slice.icon.fontPackage,
            color: Colors.black87,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(iconOffset.dx - tp.width / 2, iconOffset.dy - tp.height / 2),
      );
    }

    // Borde exterior brillante
    final Paint outerRing = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white70
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, radius - 1.5, outerRing);
  }

  @override
  bool shouldRepaint(covariant _NeonWheelPainter oldDelegate) {
    return oldDelegate.highlightedIndex != highlightedIndex;
  }
}
