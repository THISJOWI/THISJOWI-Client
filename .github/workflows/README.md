# 🔒 Security Workflows - Guía de Uso

Este directorio contiene workflows automatizados de GitHub Actions para detectar vulnerabilidades y problemas de seguridad en la aplicación THISJOWI.

## 📋 Workflows Disponibles

### 1. 🔒 `security-scan.yml` - Análisis Completo de Vulnerabilidades

**Se ejecuta:**
- En cada push a `main` o `develop`
- En cada Pull Request
- Todos los lunes a las 9:00 AM (automático)
- Manualmente desde GitHub Actions

**Escanea:**
- ✅ **Dependencias vulnerables** (usando `flutter pub outdated`)
- ✅ **Análisis estático del código** (usando `flutter analyze`)
- ✅ **Métricas de calidad de código**
- ✅ **Secretos y credenciales expuestas** (TruffleHog + Gitleaks)
- ✅ **Seguridad de Android** (Android Lint)

**Artefactos generados:**
- Reportes de Android Lint (disponibles por 30 días)
- Métricas de código
- Resumen de vulnerabilidades

---

### 2. 🔑 `credentials-check.yml` - Detección de Credenciales

**Se ejecuta:**
- En cada push a `main` o `develop`
- En cada Pull Request
- Manualmente desde GitHub Actions

**Verifica:**
- ❌ Archivos `.env` no deben estar en el repositorio
- ❌ IPs hardcodeadas en el código
- ❌ Patrones de API keys y tokens
- ❌ Archivos `.keystore` o `.jks` (Android)
- ❌ `local.properties` de Android
- ⚠️ Archivos de configuración de Firebase

**Falla si detecta:**
- Archivo `.env` en el repositorio
- API keys o tokens hardcodeados
- Keystores de Android
- Archivo `local.properties`

---

## 🚀 Cómo Usar los Workflows

### Opción 1: Ejecución Automática (Recomendado)

Una vez subas el código a GitHub, los workflows se ejecutarán automáticamente:

1. **Push al repositorio:**
   ```bash
   git add .
   git commit -m "feat: add security workflows"
   git push origin main
   ```

2. **Ver resultados:**
   - Ve a tu repositorio en GitHub
   - Click en la pestaña **"Actions"**
   - Verás los workflows ejecutándose

### Opción 2: Ejecución Manual

1. Ve a **GitHub → Tu repositorio → Actions**
2. Selecciona el workflow que quieras ejecutar
3. Click en **"Run workflow"**
4. Selecciona la rama
5. Click en **"Run workflow"** (botón verde)

---

## 📊 Interpretar los Resultados

### ✅ Todo correcto (Verde)
```
✓ dependency-scan - Passed
✓ code-analysis - Passed
✓ secret-scan - Passed
✓ android-security - Passed
```
**Acción:** Ninguna. Tu código está seguro.

---

### ⚠️ Advertencias (Amarillo)
```
! code-analysis - Warning
  → 3 lint issues found
```
**Acción:** Revisa los warnings pero no bloquean el merge.

---

### ❌ Errores críticos (Rojo)
```
✗ secret-scan - Failed
  → .env file found in repository!
```
**Acción:** **URGENTE** - Corrige antes de hacer merge.

---

## 🔧 Configuración Avanzada

### Modificar frecuencia del escaneo programado

Edita `security-scan.yml`:

```yaml
schedule:
  # Formato: minuto hora día-mes mes día-semana
  - cron: '0 9 * * 1'  # Lunes 9:00 AM
  - cron: '0 9 * * 3'  # Añadir: Miércoles 9:00 AM
```

### Cambiar versión de Flutter

En ambos workflows, busca:

```yaml
- name: 🔧 Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.24.0'  # ← Cambia aquí
```

### Añadir notificaciones de Slack

Añade al final de cualquier workflow:

```yaml
- name: 📢 Notify Slack
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
    payload: |
      {
        "text": "🔒 Security scan failed!"
      }
```

---

## 🛠️ Solucionar Problemas Comunes

### Error: "TruffleHog failed"
**Causa:** Se detectaron secretos en el historial de Git.

**Solución:**
```bash
# Ver qué archivo tiene secretos
git log --all --full-history -- "*secret*"

# Si es histórico, considera usar git-filter-repo
# O simplemente asegúrate de que los secretos estén en .gitignore
```

### Error: "Gitleaks needs license"
**Causa:** Gitleaks requiere licencia para repos privados.

**Solución:** Elimina el job `secret-scan` del workflow o usa solo TruffleHog.

### Warning: "Dependency X is outdated"
**Causa:** Hay paquetes con versiones nuevas disponibles.

**Solución:**
```bash
# Ver paquetes desactualizados
flutter pub outdated

# Actualizar a versiones compatibles
flutter pub upgrade

# Actualizar a últimas versiones (con cuidado)
flutter pub upgrade --major-versions
```

---

## 📈 Buenas Prácticas

### ✅ DO
- ✅ Ejecuta los workflows ANTES de hacer merge a `main`
- ✅ Revisa el Security Summary después de cada push
- ✅ Actualiza dependencias regularmente
- ✅ Añade el badge de status al README:

```markdown
![Security Scan](https://github.com/TU_USUARIO/TU_REPO/actions/workflows/security-scan.yml/badge.svg)
```

### ❌ DON'T
- ❌ No ignores los warnings de seguridad
- ❌ No desactives los workflows sin motivo
- ❌ No subas archivos `.env` al repositorio
- ❌ No uses `continue-on-error: true` en checks críticos

---

## 🔐 Configurar Secrets de GitHub

Para funcionalidades avanzadas, añade estos secretos:

1. Ve a **Settings → Secrets and variables → Actions**
2. Click en **"New repository secret"**
3. Añade:

| Secret | Uso | Opcional |
|--------|-----|----------|
| `SLACK_WEBHOOK` | Notificaciones a Slack | ✅ |
| `GITLEAKS_LICENSE` | Licencia de Gitleaks Pro | ✅ |
| `CODECOV_TOKEN` | Reportes de cobertura | ✅ |

---

## 📞 Soporte

Si tienes problemas con los workflows:

1. **Revisa los logs:** Click en el workflow fallido → Ver logs detallados
2. **Busca el error específico:** Los workflows tienen mensajes descriptivos
3. **Verifica permisos:** Algunos workflows requieren permisos especiales

---

## 🔄 Actualizaciones

Estos workflows se actualizan regularmente. Para obtener la última versión:

```bash
# Sincronizar con el template (si aplica)
git pull upstream main

# O actualizar manualmente las versiones de las actions
# Busca nuevas versiones en: https://github.com/marketplace?type=actions
```

---

## 📚 Recursos Adicionales

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter Security Best Practices](https://flutter.dev/security)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Dart Security](https://dart.dev/guides/security)

---

**Última actualización:** Noviembre 2025  
**Versión:** 1.0.0
