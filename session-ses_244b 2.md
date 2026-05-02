# Error 401 en autenticación Google Flutter

**Session ID:** ses_244bf932affeCan7wl9z4Y2AxC
**Created:** 4/23/2026, 6:50:54 PM
**Updated:** 4/24/2026, 8:07:41 AM

---

## User

tengo este problema A Dart VM Service on macOS is available at: http://127.0.0.1:64032/R5CAogdobxY=/
The Flutter DevTools debugger and profiler on macOS is available at: http://127.0.0.1:64032/R5CAogdobxY=/devtools/?uri=ws://127.0.0.1:64032/R5CAogdobxY=/ws
flutter: [INFO] AuthService: Starting Google Sign In...
flutter: [INFO] AuthService: Google User signed in: thsjowi@gmail.com
flutter: [WARNING] AuthService: Auth Code is null, trying ID Token...
flutter: [INFO] AuthService: Sending Google token to backend...
flutter: ═══════════════════════════════════════
flutter: 📤 REQUEST: POST https://api.thisjowi.uk/v1/auth/google
flutter: Headers: {Content-Type: application/json, Accept: application/json}
flutter: Body: {"token":"eyJhbGciOiJSUzI1NiIsImtpZCI6IjY0NzAxNGY5YTRhNGNiYmI2ZTlhYTFmOWUzMGVlNmNjNzBkYTc0MmEiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJhenAiOiI4NzQ1MjAzMDM1NDgtNHJnaTh0b3ByYWZ1cW12Nm52am5sNjhoMXZxcWhiNHQuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJhdWQiOiI4NzQ1MjAzMDM1NDgtNHJnaTh0b3ByYWZ1cW12Nm52am5sNjhoMXZxcWhiNHQuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJzdWIiOiIxMTI5NTczODIyNjYxMzU5OTIzOTQiLCJlbWFpbCI6InRoc2pvd2lAZ21haWwuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImF0X2hhc2giOiJWN2JQTG1oSlNMbktlQWFlY3dZSjR3Iiwibm9uY2UiOiI3WTloZjdQMExUOWk5cGhIT0FiQ0dFa3g1T0hLUUpqZjZOMktEYVRqSGo4IiwibmFtZSI6Ikpvd2kiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUNnOG9jTDVxY1lrdDU5VDZVYS1ycDBLWUNIa0RmLWlRWTlXMjBudkIwN1NBamxKRFo3MWlCRT1zOTYtYyIsImdpdmVuX25hbWUiOiJKb3dpIiwiaWF0IjoxNzc2OTYyNjYzLCJleHAiOjE3NzY5NjYyNjN9.pvUk0t7RIyK_FQfniw_vMtmQn4Kj5qP7cQgcUa8O4wJU0PESRapzG3N3O_CvP_B8iFyGb2QiW7V0eeSH376GjdmKUtD_S8lO7hQD3Cetgft4ALRSmEF9iKsCHUeX6G3Ozk0gebk5KLnRoa3DFqrFXAylR-2gdRQOnQAPq5au1lPDVYfmbGTYsQ2fWLegIs_HgXH9ULU9Uf1vn8a9PdzySKkHfnFJQ1Evkr7xgv9iuMQFChp2a4kv1XIzyKndod7QfGh4KpkJrNd6XXVRpCaIOhW86y5UxcMKCVKhNOSIsPHguSkPXxJ9CBhKE-7EKQKLxJyDe2H125lTiJKbPTWmig"}
flutter: ═══════════════════════════════════════
flutter: ═══════════════════════════════════════
flutter: 📥 RESPONSE: POST https://api.thisjowi.uk/v1/auth/google
flutter: Status: 401
flutter: Body: {"success":false,"message":"Google authentication failed: 401 Unauthorized on GET request for \"https://www.googleapis.com/oauth2/v3/userinfo\": \"{<EOL>  \"error\": \"invalid_request\",<EOL>  \"error_description\": \"Invalid Credentials\"<EOL>}\""}...
flutter: ═══════════════════════════════════════ 

---

## Assistant (Build · Kimi K2.5 · 76.2s)

_Thinking:_

 The user is having an issue with Google Sign-In in their Flutter app. The error shows:

1. The user successfully signs in with Google on the client side
2. The app sends the ID token to the backend at `https://api.thisjowi.uk/v1/auth/google`
3. The backend returns a 401 error with message: "Google authentication failed: 401 Unauthorized on GET request for \"https://www.googleapis.com/oauth2/v3/userinfo\": \"Invalid Credentials\""

This suggests the backend is trying to validate the token by calling Google's userinfo endpoint, but it's failing. This is a common issue when the backend tries to use the ID token as an access token.

Let me first understand the project structure and find the relevant authentication code to help diagnose the issue better.

 Veo el problema. El backend está intentando validar el token de Google pero recibe un 401. Esto suele pasar cuando el backend intenta usar el ID token como access token para llamar a la API de Google.

Déjame explorar el código para

---

## User

Quiero que me soluciones este error. Quiero que me soluciones este puto error

---

## Assistant (Build · Kimi K2.5 · 30.0s)

_Thinking:_

 El usuario tiene un problema con la autenticación de Google en su aplicación Flutter. El flujo es:

1. El usuario inicia sesión con Google en el frontend (Flutter)
2. El frontend obtiene un ID Token de Google
3. El frontend envía ese token al backend (`https://api.thisjowi.uk/v1/auth/google`)
4. El backend intenta verificar el token con Google (`https://www.googleapis.com/oauth2/v3/userinfo`)
5. El backend recibe un error 401 "Invalid Credentials"

El problema está en el backend - cuando intenta verificar el ID Token con Google, recibe un error 401. Esto suele pasar porque:

1. El backend está enviando el token incorrectamente a la API de Google
2. El token ha expirado (el `exp` en el payload es `1776966263` que es aproximadamente 2026-04-24 14:24:23 UTC, y el `iat` es `1776962663` aproximadamente 2026-04-24 13:24:23 UTC, así que el token es válido por 1 hora)
3. El backend está usando el endpoint incorrecto de Google para verificar el token

Necesito ver el código del backend para entender cómo está manejando la verificación del token. Déjame buscar archivos relacionados con autentic

 Veo el problema. El backend recibe un 401 de Google al intentar verificar el token. Déjame buscar el código del backend para ver cómo estás manejando la verificación del

---

