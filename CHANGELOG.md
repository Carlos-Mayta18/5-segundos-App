# Changelog

Todos los cambios notables en el proyecto **Reto 5 Segundos** se documentan en este archivo.

## [1.0.0] - 2026-10-28

### Añadido
- **Interfaz Neón / Fiesta Nocturna (`AppTheme`)** con inicio directo sin fricción (sin cuentas ni login).
- **Banco inicial 100% Offline de +220 cartas** distribuidas en 4 mazos temáticos:
  - *Clásico / Familiar* (55 cartas)
  - *Geek / Cultura Pop* (55 cartas)
  - *Noche de Copas / Fiesta* (55 cartas)
  - *Picante / Confesiones (+18)* (55 cartas)
- **Motor `ContinuousDeckShuffler`** con algoritmo Fisher-Yates para garantizar cero preguntas repetidas durante toda la sesión.
- **Presión sensorial de 5.0 segundos (`GameplayScreen` + `SoundService`):**
  - Síntesis de audio PCM (`.wav`) en memoria RAM con *tic-tac* acelerado, campana de fin de tiempo y efectos de acierto/fallo.
  - Barra de progreso con cambio dinámico de color y opción de *Carta Oculta*.
- **Dos modos de juego:**
  - *Modo Competitivo (Por puntos):* de 2 a 12 jugadores, metas de 3/5/7/10 puntos, rachas y pantalla de Podio (`VictoryScreen`).
  - *Modo Rápido / Casual (Sin fin):* ronda continua sin registro de nombres.
- **Ruleta Neón de Castigos / Retos (`PunishmentWheelDialog`):**
  - Ruleta interactiva de 8 categorías con más de 60 retos divididos en modo *Familiar / Sano* y *Fiesta / Tragos (+18)*.
- **Capa de Monetización No Intrusiva (`MonetizationService`):**
  - Integración lista para Google AdMob (Banners discretos, Interstitial al cerrar partida y Rewarded Video para desbloquear mazos) y Google Play Billing (*Versión PRO* de pago único).
