# Política de Privacidad — Reto 5 Segundos

**Última actualización:** 28 de octubre de 2026

Esta Política de Privacidad describe cómo la aplicación móvil **Reto 5 Segundos** (desarrollada por **Carlos Mayta**) maneja la información de los usuarios cuando utilizan nuestra aplicación distribuida a través de Google Play Store.

---

## 1. Arquitectura Offline-First y Datos Personales

**Reto 5 Segundos** ha sido diseñada bajo una arquitectura **100% sin conexión (Offline-First)** y de cero fricción:
- **No requerimos registro de cuenta ni inicio de sesión.**
- **No recopilamos, almacenamos ni enviamos a servidores externos** nombres reales, correos electrónicos, números de teléfono, ubicación geográfica, contactos ni fotografías.
- Los nombres o apodos de los jugadores ingresados en el *Modo Competitivo* y el estado de desbloqueo de la *Versión PRO* se procesan y guardan **exclusivamente de forma local** en la memoria del dispositivo del usuario (`SharedPreferences`).

---

## 2. Servicios de Terceros (Publicidad y Compras Integradas)

Para mantener la aplicación gratuita y ofrecer opciones de desbloqueo de contenido, la aplicación integra servicios oficiales de Google que pueden recopilar identificadores técnicos anónimos conforme a sus propias políticas de privacidad:

### a) Google AdMob (Publicidad)
En la versión gratuita, mostramos anuncios no intrusivos (banners en pantallas de configuración, anuncios intersticiales al finalizar partidas y videos recompensados opcionales). Google AdMob puede utilizar el **ID de publicidad de Android (Advertising ID)** y datos de diagnóstico básicos para mostrar anuncios relevantes y prevenir el fraude.
- Puedes consultar la política de Google aquí: [Política de Privacidad de Google](https://policies.google.com/privacy).
- El usuario puede restablecer o desactivar la personalización de anuncios en cualquier momento desde *Configuración de Android → Google → Anuncios*.

### b) Google Play Billing (Compras dentro de la aplicación)
Las transacciones para adquirir la **Versión PRO / Sin Anuncios** son procesadas íntegramente por **Google Play Store**. El desarrollador nunca tiene acceso a datos bancarios, números de tarjetas de crédito ni información financiera del usuario.

---

## 3. Permisos del Dispositivo

La aplicación únicamente utiliza permisos técnicos mínimos:
- `com.android.vending.BILLING`: Necesario para procesar y restaurar la compra única de la versión sin anuncios en Google Play.
- `android.permission.VIBRATE`: Utilizado exclusivamente para los efectos hápticos de vibración durante la cuenta regresiva de 5 segundos.

---

## 4. Privacidad de Menores y Clasificación de Contenido

La aplicación incluye mazos aptos para todo público (*Clásico / Familiar* y *Geek / Cultura Pop*) así como mazos claramente etiquetados para adultos (`+18`: *Noche de Copas* y *Picante / Confesiones*). No recopilamos intencionalmente información personal de menores de edad.

---

## 5. Contacto

Si tienes preguntas o inquietudes sobre esta Política de Privacidad, puedes comunicarte a través del repositorio oficial del proyecto:
- **GitHub:** [https://github.com/Carlos-Mayta18/5-segundos-App](https://github.com/Carlos-Mayta18/5-segundos-App)
