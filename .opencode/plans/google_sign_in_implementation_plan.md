# Google Sign In Implementation Plan

## Overview
This plan details the steps to integrate Google Sign In functionality into the thisjowi Flutter application. The implementation will leverage the existing `auth_service 2.dart` file which already contains a complete Google Sign In implementation.

## Prerequisites
1. Google Sign In dependency added to pubspec.yaml (completed)
2. Backend endpoint `/v1/auth/google` already implemented and functional
3. Google Cloud Console project configured with OAuth credentials

## Implementation Steps

### 1. Update Dependencies (Completed)
- Added `google_sign_in: ^6.2.1` to pubspec.yaml
- Dependency is already present in the file

### 2. Verify Service Implementation (Completed)
- Confirmed `lib/services/auth_service 2.dart` contains:
  - GoogleSignIn instance initialization
  - Platform-specific client ID configuration
  - `_initGoogleSignIn()` method for initialization
  - `loginWithGoogle()` method for authentication flow
  - `_sendGoogleTokenToBackend()` method for communicating with backend
  - Proper error handling and token management

### 3. Modify Login Screen Import
**File:** `lib/screens/auth/login.dart`
**Change:** Replace the auth service import
```diff
- import 'package:thisjowi/services/auth_service.dart';
+ import 'package:thisjowi/services/auth_service 2.dart';
```
**Note:** Due to the space in the filename, we may need to create an alias or rename the file. Better approach is to create a new file without spaces.

### 4. Create Clean Service File (Recommended)
Instead of using the file with spaces, create a clean service file:
1. Copy `auth_service 2.dart` to `google_auth_service.dart`
2. Update import in login.dart to use the clean name
3. This avoids issues with spaces in import paths

### 5. Add Google Login Handler
**File:** `lib/screens/auth/login.dart`
Add method to `_LoginScreenState` class:
```dart
final AuthService _authService = AuthService(); // Updated import

Future<void> _handleGoogleLogin() async {
  setState(() => _isLoading = true);
  
  try {
    final authUser = await _authService.loginWithGoogle();
    
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MyBottomNavigation()),
        (route) => false,
      );
    }
  } on AuthException catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      ErrorSnackBar.show(context, e.message);
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      ErrorSnackBar.show(context, errorMsg);
    }
  }
}
```

### 6. Add Google Sign In Button to UI
**File:** `lib/screens/auth/login.dart`
In the social login section (around line 599), add:
```dart
// Google
_buildSocialButton(
  asset: 'assets/google_logo.png',
  useWhiteLogoBackground: false,
  onTap: _handleGoogleLogin,
  isIcon: false,
),
```

### 7. Platform Configuration
Ensure platform-specific configurations are in place:
- Android: SHA-1 fingerprint configured in Google Cloud Console
- iOS: Reverse URL scheme in Info.plist
- Web: Client ID configured in index.html
- macOS: Already configured based on file findings

### 8. Testing Procedure
1. Run `flutter pub get` to install dependencies
2. Test on each platform:
   - Android: Verify Google Sign In works with test accounts
   - iOS: Verify Google Sign In works with test accounts
   - Web: Verify popup flow works correctly
   - macOS: Verify native flow works correctly
3. Verify user data (email, name) is correctly received from Google
4. Verify JWT token is properly stored and used for subsequent API calls
5. Verify error handling works correctly (cancelled sign-in, network errors, etc.)

## Files to Modify
1. `pubspec.yaml` - Already completed
2. Create `lib/services/google_auth_service.dart` (copy from auth_service 2.dart)
3. `lib/screens/auth/login.dart` - Update import, add handler, add button

## UI/UX Considerations
- Google button should follow same design as GitHub button
- Use existing `_buildSocialButton` helper function
- Maintain consistent sizing (60x60) and styling
- Show loading state appropriately
- Handle platform-specific UI differences if needed

## Error Handling
- Handle cancelled sign-ins gracefully
- Handle network errors with appropriate user feedback
- Handle invalid/expired tokens from Google
- Handle backend errors appropriately
- Ensure loading state is properly reset in all scenarios

## Security Considerations
- Ensure Google credentials are not exposed in client code
- Use secure storage for tokens
- Validate tokens with backend before trusting
- Follow principle of least privilege for requested scopes

## Dependencies
- google_sign_in: ^6.2.1
- Already uses flutter_web_auth_2 for GitHub (similar pattern)
- Uses existing http client and token management

## Estimated Effort
- Implementation: 2-3 hours
- Testing: 1-2 hours per platform
- Total: Approximately 6-8 hours

## Rollback Plan
1. Revert pubspec.yaml change
2. Revert login.dart changes
3. Remove google_auth_service.dart if created
4. No database or backend changes required