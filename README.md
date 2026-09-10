# BrainFood

Aplicación Flutter para organizar la cocina cotidiana de una persona: despensa, recetas, compras y planificación semanal en una experiencia clara y minimalista.

Creado y dirigido por **Joseph Ivan Cachay Vargas**, fundador de **RETH**. BrainFood es un proyecto independiente de RETH desarrollado como producto de portafolio.

© 2026 Joseph Ivan Cachay Vargas / RETH. Todos los derechos reservados. Consulta [NOTICE.md](NOTICE.md) para la atribución y condiciones de uso.

## Abrir y probar en Android Studio

Abre **esta carpeta raíz**, no solo `android/`. Usa Flutter y Dart, selecciona `lib/main.dart` y tu dispositivo o emulador. Las dependencias ya se resolvieron con el SDK local `C:\src\flutter`.

Si había una sesión anterior ejecutándose, detenla e inicia una nueva: se añadieron una fuente local, recursos Android y el plugin de almacenamiento seguro. Hot reload no aplica todos esos cambios.

No se construyó un APK ni un AAB durante este trabajo. La comprobación fue con análisis estático, pruebas de dominio y de widgets. Queda por verificar en un dispositivo Android el arranque nativo, el icono adaptativo y el almacenamiento cifrado real.

## Experiencia

- **Hoy:** una propuesta basada en tu despensa, disponibilidad real de ingredientes, alimentos marcados para usar pronto y acceso al plan.
- **Despensa:** búsqueda, categorías, edición de cantidad, prioridad manual, básicos opcionales y eliminación con deshacer. Una instalación nueva empieza vacía y puede cargar una selección editable de básicos peruanos, despensa express, semana económica o base vegetariana.
- **Recetas:** 120 recetas locales; búsqueda por nombre, descripción o ingrediente; filtros de disponibilidad, tiempo, faltantes, utensilios, guardadas, categoría y cocina peruana. Las preferencias influyen en el orden y las exclusiones.
- **Semana:** semanas con fechas independientes; elegir, cambiar, quitar o saltar comidas. El generador completa únicamente espacios futuros vacíos y respeta comidas ya elegidas, días fuera y tiempo máximo.
- **Compras:** faltantes agrupados por alimento, cantidades editables, marcado de comprados, copia o envío mediante el menú nativo de Android y traslado a despensa. El texto compartido contiene solo pendientes, ordenados por categoría. Repetir una acción no desmarca compras ni crea duplicados.
- **Cocina:** modo dedicado a pantalla completa, un paso grande por pantalla, progreso persistente, acceso rápido a cantidades y varios temporizadores simultáneos. La pantalla se mantiene despierta mientras se cocina. Al terminar se pregunta qué alimentos se agotaron, en lugar de eliminar automáticamente todo lo usado.
- **Preferencias:** tiempo disponible, alimentos a evitar y proveedor opcional del asistente.

## Diseño y movimiento

Crema, verde bosque y lima, fuente Manrope incluida con su licencia OFL, componentes Material personalizados y arte vectorial dibujado en Flutter. No hacen falta descargas para mostrar fuentes ni platos. Las ilustraciones son orientativas, no fotografías de las recetas.

La navegación conserva el desplazamiento y el estado de cada pestaña. Transiciones cortas de entrada, respuesta táctil y controles animados respetan la opción de reducir animaciones del sistema. Se verificó navegación a 360 px y texto al 150 %, además de desplazamiento hasta las partes inferiores de las pantallas.

Capturas reales del motor de Flutter en `design_review/`. Los alimentos de las capturas son datos de prueba; no se insertan en la aplicación del usuario.

## Datos y compatibilidad

Se conservaron las claves de despensa, compras, recetas personalizadas y básicos. El calendario anterior, que no tenía fecha de semana, se migra a la semana actual en su primera lectura y se conserva el origen. Los nuevos planes se guardan por fecha de lunes.

Las coincidencias usan normalización de acentos y alias explícitos, evitando errores como confundir “sal” con “salmón”. Arroz crudo y cocido se distinguen.

Las claves de API se almacenan mediante `flutter_secure_storage`, separadas por proveedor. Una clave antigua del prototipo se migra a OpenRouter al leer claves de proveedor, pues ese era el único endpoint que usaba la versión anterior. No se envía esa clave a OpenCode. La copia de seguridad Android está desactivada para evitar restaurar claves cifradas sin sus claves de dispositivo.

## IA opcional

El modo inicial es **recetario local**, claramente identificado como búsqueda de recetas incluidas, sin generación de IA. No inventa un salteado con cualquier combinación ni disimula errores remotos.

En Preferencias se puede elegir OpenCode Zen u OpenRouter, indicar un modelo compatible con Chat Completions y su clave. Antes de guardar una receta remota se valida la estructura, ingredientes, pasos, tiempo y porciones. Los errores de autenticación, límites y conexión se muestran.

No se realizaron llamadas reales con claves de usuario. Los contratos HTTP y sus errores se comprobaron con respuestas simuladas. Los límites, condiciones y disponibilidad de modelos gratuitos deben revisarse con el proveedor; no hay promesa de IA gratuita permanente.

Referencias: [OpenCode Zen](https://opencode.ai/docs/zen/), [almacenamiento seguro](https://pub.dev/packages/flutter_secure_storage).

## Validación reproducible

```powershell
C:\src\flutter\bin\flutter.bat analyze
C:\src\flutter\bin\flutter.bat test
```

Para regenerar las capturas de revisión mediante tests, sin empaquetar una aplicación:

```powershell
C:\src\flutter\bin\flutter.bat test --dart-define=CAPTURE_UI=true
```

Las pruebas cubren coincidencias, inicialización vacía, paquetes de despensa sin sobrescribir cantidades, agotamiento selectivo y deshacer, duplicados, texto compartido, traslado de compras, semanas persistidas por separado, generación que respeta decisiones, preferencias, respuestas de IA inválidas, errores HTTP, claves separadas por proveedor, navegación, texto ampliado, alta de alimentos, compra completa, reanudación y cierre del modo cocina. El catálogo se valida para impedir IDs o títulos repetidos, campos esenciales vacíos, categorías desconocidas, ingredientes duplicados y recetas sin cantidades o pasos suficientes.

## Límites que siguen siendo explícitos

- El inventario conserva cantidades aproximadas como texto. No calcula existencias en gramos ni garantiza que alcancen para varias recetas.
- Las compras semanales agrupan ingredientes, pero las cantidades deben revisarse; no se calcula un presupuesto ni ahorro monetario ficticio.
- Las 120 recetas locales superan una revisión estructural automática. Antes de una publicación pública todavía corresponde una revisión culinaria humana de sabor, seguridad, cantidades y lenguaje regional. Fuente de temperaturas: [FoodSafety.gov](https://www.foodsafety.gov/food-safety-charts/safe-minimum-internal-temperatures).
- “Usar pronto” es una marca del usuario, no un cálculo de caducidad. Las exclusiones son preferencias por ingrediente, no un sistema certificado de alérgenos.
- Los temporizadores y el paso actual se recuperan al volver al modo cocina, pero no programan alarmas ni notificaciones del sistema si Android termina la aplicación.
- Los datos son locales. No hay cuentas, sincronización ni recuperación en otro teléfono. Eliminar la aplicación puede borrar los datos.
- No se preparó publicación en Play Store ni firma de producción.

