import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum PunishmentMode {
  off,    // Sin ruleta de castigos (pasa el turno directo)
  family, // Castigos sanos y cómicos para todo público
  party,  // Castigos de fiesta, tragos y confesiones (+18)
}

class PunishmentWheelSlice {
  final String label;
  final IconData icon;
  final Color color;

  const PunishmentWheelSlice({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class PunishmentItem {
  final String categoryLabel;
  final IconData icon;
  final Color color;
  final String description;

  const PunishmentItem({
    required this.categoryLabel,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class PunishmentsRepository {
  static const List<PunishmentWheelSlice> wheelSlices = [
    PunishmentWheelSlice(
      label: 'ACTUACIÓN',
      icon: Icons.theater_comedy_rounded,
      color: AppTheme.neonPink,
    ),
    PunishmentWheelSlice(
      label: 'CONFESIÓN',
      icon: Icons.record_voice_over_rounded,
      color: AppTheme.neonCyan,
    ),
    PunishmentWheelSlice(
      label: 'CELULAR',
      icon: Icons.smartphone_rounded,
      color: AppTheme.neonYellow,
    ),
    PunishmentWheelSlice(
      label: 'RETO FÍSICO',
      icon: Icons.bolt_rounded,
      color: AppTheme.neonGreen,
    ),
    PunishmentWheelSlice(
      label: 'EL GRUPO MANDA',
      icon: Icons.groups_rounded,
      color: AppTheme.neonPurple,
    ),
    PunishmentWheelSlice(
      label: 'IMITACIÓN',
      icon: Icons.face_retouching_natural_rounded,
      color: AppTheme.neonOrange,
    ),
    PunishmentWheelSlice(
      label: 'CASTIGO DOBLE',
      icon: Icons.local_fire_department_rounded,
      color: AppTheme.neonRed,
    ),
    PunishmentWheelSlice(
      label: 'SALVACIÓN',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFF00B4D8),
    ),
  ];

  // ===========================================================================
  // CASTIGOS MODO FAMILIAR / SANO (Por cada gajo de la ruleta)
  // ===========================================================================
  static const Map<int, List<String>> familyPunishmentsBySlice = {
    0: [
      'Actúa como un robot sin batería hasta que te vuelva a tocar tu próximo turno.',
      'Habla como locutor de partido de fútbol narrando lo que hace el siguiente jugador.',
      'Di el abecedario al revés desde la J hasta la A o haz 5 saltos de tijera.',
      'Canta el coro de tu canción favorita con la boca casi cerrada para que el grupo la adivine.',
    ],
    1: [
      'Cuenta la anécdota más graciosa o vergonzosa que te haya pasado en el colegio o trabajo.',
      'Confiesa cuál ha sido la peor comida que has cocinado en tu vida.',
      'Di quién de esta mesa crees que sobreviviría menos tiempo en una isla desierta y por qué.',
      'Confiesa qué es lo más absurdo que te daba miedo cuando eras niño.',
    ],
    2: [
      'Muestra al grupo cuál fue la última foto normal que tomaste con tu celular.',
      'Lee en voz alta la última búsqueda que hiciste en YouTube o Google.',
      'Muestra cuál es tu sticker o emoji más usado en WhatsApp y haz la misma cara.',
      'Déjale ver al jugador de tu derecha el porcentaje de batería y la hora de tu última alarma.',
    ],
    3: [
      'Quédate de pie como estatua durante todo el turno del siguiente jugador.',
      'Haz 8 sentadillas mientras el grupo las cuenta en voz alta.',
      'Intenta tocarte la nariz con la lengua o mantén el equilibrio en un solo pie por 15 segundos.',
      'Gira 5 veces sobre tu propio eje y luego intenta caminar en línea recta.',
    ],
    4: [
      'El jugador de tu derecha elige una palabra prohibida: no puedes decirla hasta tu próximo turno.',
      'El grupo tiene 10 segundos para ponerte un apodo nuevo que usarán toda la partida.',
      'Choca los cinco con todos los jugadores de la mesa en menos de 5 segundos.',
      'El jugador que va ganando decide qué acento extranjero debes usar en tu próxima respuesta.',
    ],
    5: [
      'Imita a otro jugador de esta mesa durante 15 segundos hasta que adivinen quién es.',
      'Imita el sonido y movimiento de 3 animales distintos elegidos por el jugador de tu izquierda.',
      'Imita cómo reacciona alguien de esta mesa cuando pierde en un juego.',
      'Habla con voz de villano de película hasta tu próximo turno.',
    ],
    6: [
      '¡Reto relámpago! Di un trabalenguas sin equivocarte o pierde tu próximo turno sentado en el piso.',
      'Debes hacer reír al jugador más serio de la mesa en menos de 15 segundos.',
      'Responde a todas las preguntas que te hagan diciendo primero "Mi capitán" hasta tu próximo turno.',
      'Hazle un cumplido súper exagerado y dramático a los dos jugadores sentados a tus lados.',
    ],
    7: [
      '¡SUERTE DIVINA! Te salvaste del castigo esta vez, pasa el teléfono con orgullo.',
      '¡COMODÍN DE SALVACIÓN! No tienes castigo y además eliges quién lee la siguiente carta.',
    ],
  };

  // ===========================================================================
  // CASTIGOS MODO FIESTA / NOCHE DE COPAS (+18)
  // ===========================================================================
  static const Map<int, List<String>> partyPunishmentsBySlice = {
    0: [
      'Toma un trago sin usar las manos (o con la mano menos hábil si es vaso grande).',
      'Haz un brindis épico y dramático dedicado a tu ex o toma doble trago.',
      'Baila durante 10 segundos sin música el ritmo que grite el jugador de tu derecha o toma un shot.',
      'Intenta seducir a una silla o botella durante 10 segundos sin reírte o toma un trago.',
    ],
    1: [
      'Confiesa quién fue la última persona de tus redes sociales a la que stalkeaste o toma un trago.',
      'Califica del 1 al 10 tu última cita romántica y explica por qué, o toma medio vaso.',
      'Di quién de esta mesa crees que es el más peligroso en una fiesta y por qué.',
      'Confiesa cuál es la excusa más falsa que has usado para irte con alguien o no ir a trabajar.',
    ],
    2: [
      'Lee en voz alta el último mensaje de WhatsApp que enviaste o toma un buen trago.',
      'Muestra la tercera foto de tu galería sin borrar nada o toma dos tragos.',
      'Abre Instagram y dale "Me gusta" a la primera historia que aparezca o toma un shot.',
      'Muestra el nombre de las últimas 3 personas con las que hablaste por chat hoy.',
    ],
    3: [
      '¡FONDO O CASTIGO! Toma un trago largo de tu vaso ahora mismo.',
      'Juega Piedra, Papel o Tijera con la persona de tu izquierda; el que pierde toma un trago.',
      'Mantén contacto visual sin reírte por 10 segundos con la persona de enfrente; el primero en reír toma.',
      'Toma tantos sorbos como puntos tenga el jugador que va en primer lugar.',
    ],
    4: [
      '¡EL GRUPO MANDA! Entre todos eligen con quién de la mesa debes brindar y tomar al mismo tiempo.',
      'El jugador de tu derecha te hace una pregunta "Sin Filtro": respondes con la verdad o tomas doble.',
      'Elige a un "compañero de castigo": cada vez que tú tomes en esta partida, esa persona también toma.',
      'La mesa vota: ¿te perdonan el castigo o te toca tomar un shot ahora mismo?',
    ],
    5: [
      'Imita cómo se pone alguien de esta mesa cuando ya tiene varias copas encima.',
      'Manda un audio de 5 segundos al grupo de WhatsApp cantando a todo pulmón o toma un trago.',
      'Imita la cara de foto sexy de perfil de alguno de los presentes hasta que adivinen quién es.',
      'Habla susurrando de forma misteriosa hasta que vuelva a ser tu turno o toma cada vez que lo olvides.',
    ],
    6: [
      '¡CASTIGO DOBLE! Toma un trago ahora y además en tu próximo turno tendrás que responder de pie.',
      'Cuenta un secreto que nadie en esta mesa sepa sobre ti o toma dos tragos seguidos.',
      'Elige entre: mostrar tu historial de búsqueda de Instagram o tomar un trago largo.',
      'Reta a alguien de la mesa a decir 3 marcas de licor en 3 segundos; quien pierda toma.',
    ],
    7: [
      '¡INMUNIDAD DE FIESTA! Te salvaste y además puedes mandar a tomar un sorbo a quien tú quieras de la mesa.',
      '¡GOLPE DE SUERTE! No cumples castigo; pasa el teléfono al siguiente valiente.',
    ],
  };
}
