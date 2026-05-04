# Full Liquid Glass Navigation iOS 26 Design

**Date:** 2026-05-04
**Status:** Approved

## Overview

Implementación completa de navegación estilo iOS 26 con Liquid Glass effect y animaciones premium natives. Reemplaza la implementación básicaactual con todas las features de una app nativa iOS.

## Architecture

### Components

1. **LiquidGlassBottomNav** - Widget principal con glass effect completo
2. **SlidingIndicator** - Indicador tipo pill que se desliza suavemente entre tabs
3. **AnimatedTabIcon** - Icono con efectos de press (scale + opacity)
4. **PageTransition** - Transiciones fluidas entre páginas

## Implementation Details

### Glass Effect (Full Liquid Glass)

```dart
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white.withAlpha(25), // tint semitransparente
      border: Border(
        top: BorderSide(color: Colors.white.withAlpha(25), width: 0.5),
      ),
    ),
  ),
)
```

### Sliding Indicator

- Usa `AnimationController` con `vsync`
- Tween con interpolación de posición
- Tipo spring curve
- Ancho dinámico basado en tabs

### AnimatedTabIcon

```dart
onTapDown: Scale(0.9)
onTapDown: Opacity(0.7)
onTapUp: Scale(1.0)
onTapUp: Opacity(1.0)
```

### Page Transitions

- FadeTransition para cambio de tabs
- Duration: 200-300ms
- Curve: easeInOut

### Haptics

- `HapticFeedback.lightImpact()` en tap
- `HapticFeedback.selectionClick()` en drag indicator

## Features

### Animaciones

1. **Sliding Indicator**: Indicador que se desliza suavemente entre tabs seleccionados
2. **Press Animation**: Scale + opacity al presionar icono
3. **Page Fade**: Transición fade entre páginas
4. **Spring Effect**: Animación spring para el indicador
5. **Label Fade**: Las etiquetas appear/disappear con animación

### UX Details

1. **Haptic Feedback**: Light impact en cada tap
2. **Label Visibility**: Labels siempre visibles o con toggle
3. **Icon Size**: Tamaño consistente (24px)
4. **Spacing**: Espaciado uniforme entre tabs

## Files Modified

1. `lib/components/navigation.dart` - Replace IOSNativeBottomNav con LiquidGlassBottomNav

## Dependencies

- `dart:ui` (ya importado)
- Animaciones existentes de Flutter

## Success Criteria

- [ ] Glass effect visible con blur + tint
- [ ] Indicador se desliza suavemente entre tabs
- [ ] Animación de press en iconos (scale + opacity)
- [ ] Transición fade entre páginas
- [ ] Haptic feedback en cada interacción
- [ ] Labels visibles debajo de iconos
- [ ] Spring animation para el indicador
- [ ] Se siente como app nativa iOS