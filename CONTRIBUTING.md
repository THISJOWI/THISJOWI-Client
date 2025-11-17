# 🤝 Contributing to THISJOWI Frontend

First off, thank you for considering contributing to THISJOWI Frontend! It's people like you that make this project better for everyone.

## 📋 Table of Contents

- [Code of Conduct](#-code-of-conduct)
- [Getting Started](#-getting-started)
- [Development Process](#-development-process)
- [Pull Request Process](#-pull-request-process)
- [Coding Standards](#-coding-standards)
- [Commit Guidelines](#-commit-guidelines)
- [Testing Guidelines](#-testing-guidelines)
- [Documentation](#-documentation)
- [Community](#-community)

---

## 📜 Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

### Our Standards

**Positive behaviors include:**
- ✅ Using welcoming and inclusive language
- ✅ Being respectful of differing viewpoints
- ✅ Gracefully accepting constructive criticism
- ✅ Focusing on what is best for the community
- ✅ Showing empathy towards others

**Unacceptable behaviors include:**
- ❌ Harassment or discriminatory language
- ❌ Trolling, insulting/derogatory comments
- ❌ Public or private harassment
- ❌ Publishing others' private information
- ❌ Other unprofessional conduct

---

## 🚀 Getting Started

### Prerequisites

Before you start contributing, make sure you have:

- [ ] Flutter SDK (3.9.0+)
- [ ] Git
- [ ] A code editor (VS Code, Android Studio, etc.)
- [ ] Basic understanding of Dart and Flutter
- [ ] GitHub account

### Setting Up Your Development Environment

1. **Fork the repository**

   Click the "Fork" button at the top right of the repository page.

2. **Clone your fork**

   ```bash
   git clone https://github.com/YOUR-USERNAME/THISJOWI-Frontend.git
   cd THISJOWI-Frontend
   ```

3. **Add upstream remote**

   ```bash
   git remote add upstream https://github.com/THISJowi/THISJOWI.git
   ```

4. **Install dependencies**

   ```bash
   flutter pub get
   ```

5. **Set up environment**

   ```bash
   cp .env.example .env
   # Edit .env with your local configuration
   ```

6. **Verify setup**

   ```bash
   flutter doctor -v
   flutter test
   flutter analyze
   ```

---

## 💻 Development Process

### 1. Create a Branch

Always create a new branch for your work:

```bash
# Update your fork
git checkout main
git pull upstream main

# Create a new branch
git checkout -b feature/your-feature-name
# or
git checkout -b fix/bug-description
# or
git checkout -b docs/documentation-update
```

**Branch naming conventions:**
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Adding or updating tests
- `chore/` - Maintenance tasks

### 2. Make Your Changes

- Write clean, readable code
- Follow the [coding standards](#-coding-standards)
- Add tests for new features
- Update documentation as needed
- Keep commits atomic and focused

### 3. Test Your Changes

```bash
# Run tests
flutter test

# Run code analysis
flutter analyze

# Format code
flutter format .

# Check for outdated packages
flutter pub outdated
```

### 4. Commit Your Changes

Follow our [commit guidelines](#-commit-guidelines).

```bash
git add .
git commit -m "feat: add user profile screen"
```

### 5. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

### 6. Create a Pull Request

Go to your fork on GitHub and click "New Pull Request".

---

## 🔀 Pull Request Process

### Before Submitting

- [ ] Code follows the project's coding standards
- [ ] Tests pass (`flutter test`)
- [ ] Code analysis passes (`flutter analyze`)
- [ ] Code is formatted (`flutter format .`)
- [ ] Documentation is updated
- [ ] Commit messages follow conventions
- [ ] No merge conflicts with main branch

### Pull Request Template

When creating a PR, include:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
How did you test this?

## Screenshots (if applicable)
Add screenshots for UI changes

## Checklist
- [ ] Tests pass
- [ ] Code analyzed
- [ ] Documentation updated
```

### Review Process

1. **Automated Checks**: GitHub Actions will run tests and security scans
2. **Code Review**: At least one maintainer will review your code
3. **Feedback**: Address any requested changes
4. **Approval**: Once approved, a maintainer will merge your PR

### After Your PR is Merged

1. Delete your branch:
   ```bash
   git branch -d feature/your-feature-name
   git push origin --delete feature/your-feature-name
   ```

2. Update your local main:
   ```bash
   git checkout main
   git pull upstream main
   ```

---

## 📝 Coding Standards

### Dart/Flutter Style Guide

Follow the official [Flutter Style Guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo).

### Key Principles

#### 1. **Code Organization**

```dart
// ✅ Good: Organized imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import '../core/api_config.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

// ❌ Bad: Random import order
import '../services/auth_service.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
```

#### 2. **Naming Conventions**

```dart
// Classes: PascalCase
class UserProfile extends StatelessWidget { }

// Variables & functions: camelCase
String userName;
void fetchUserData() { }

// Constants: lowerCamelCase
const apiTimeout = 30;

// Private members: prefix with _
String _privateVariable;
void _privateMethod() { }
```

#### 3. **Widget Structure**

```dart
// ✅ Good: Clean widget structure
class MyWidget extends StatelessWidget {
  const MyWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(title: const Text('Title'));
  }

  Widget _buildBody() {
    return const Center(child: Text('Content'));
  }
}
```

#### 4. **Error Handling**

```dart
// ✅ Good: Proper error handling
Future<User> fetchUser() async {
  try {
    final response = await api.get('/user');
    return User.fromJson(response.data);
  } on NetworkException catch (e) {
    throw UserFetchException('Failed to fetch user: ${e.message}');
  } catch (e) {
    throw UserFetchException('Unexpected error: $e');
  }
}

// ❌ Bad: Silent failures
Future<User?> fetchUser() async {
  try {
    final response = await api.get('/user');
    return User.fromJson(response.data);
  } catch (e) {
    return null; // Lost error context!
  }
}
```

#### 5. **Constants and Configuration**

```dart
// ✅ Good: Use configuration classes
class AppConstants {
  static const int maxRetries = 3;
  static const Duration timeout = Duration(seconds: 30);
}

// ❌ Bad: Magic numbers
await http.get(url).timeout(Duration(seconds: 30));
```

### Code Formatting

Use `dart format`:

```bash
# Format all Dart files
flutter format .

# Check formatting without modifying files
flutter format --set-exit-if-changed .
```

### Linting

This project uses strict linting rules defined in `analysis_options.yaml`:

```bash
# Run the analyzer
flutter analyze

# Fix auto-fixable issues
dart fix --apply
```

---

## 📝 Commit Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Code style changes (formatting, missing semicolons, etc.)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Changes to build process or auxiliary tools

### Examples

```bash
# Simple feature
git commit -m "feat: add user profile screen"

# Bug fix with scope
git commit -m "fix(auth): resolve token refresh issue"

# Breaking change
git commit -m "feat!: redesign navigation structure

BREAKING CHANGE: Navigation now uses bottom navigation instead of drawer"

# With body
git commit -m "refactor(services): improve error handling

- Add custom exception classes
- Implement retry logic
- Improve error messages"
```

### Commit Message Rules

- ✅ Use present tense ("add feature" not "added feature")
- ✅ Use imperative mood ("move cursor to..." not "moves cursor to...")
- ✅ First line should be 50 characters or less
- ✅ Reference issues and pull requests when relevant
- ❌ Don't end the subject line with a period
- ❌ Don't use generic messages like "fix bug" or "update code"

---

## 🧪 Testing Guidelines

### Test Coverage

We aim for **80%+ code coverage**. All new features should include tests.

### Types of Tests

#### 1. **Unit Tests**

Test individual functions and classes:

```dart
// test/services/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/auth_service.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    test('should login successfully with valid credentials', () async {
      final result = await authService.login('user@example.com', 'password');
      
      expect(result.success, true);
      expect(result.token, isNotNull);
    });

    test('should throw exception with invalid credentials', () async {
      expect(
        () => authService.login('user@example.com', 'wrong'),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
```

#### 2. **Widget Tests**

Test UI components:

```dart
// test/widgets/login_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/components/button.dart';

void main() {
  testWidgets('LoginButton should display text', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Login',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('LoginButton should call onPressed', (WidgetTester tester) async {
    bool wasPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Login',
            onPressed: () => wasPressed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(CustomButton));
    expect(wasPressed, true);
  });
}
```

#### 3. **Integration Tests**

Test complete user flows:

```bash
# Run integration tests
flutter test integration_test/
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/auth_service_test.dart

# Run tests with coverage
flutter test --coverage

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
```

### Test Best Practices

- ✅ Write descriptive test names
- ✅ Follow AAA pattern (Arrange, Act, Assert)
- ✅ Mock external dependencies
- ✅ Test edge cases and error scenarios
- ✅ Keep tests focused and independent
- ❌ Don't test Flutter framework code
- ❌ Don't make tests dependent on each other

---

## 📚 Documentation

### Code Documentation

Use Dart doc comments for public APIs:

```dart
/// Authenticates a user with email and password.
///
/// Returns a [User] object if authentication is successful.
/// Throws [AuthException] if credentials are invalid.
///
/// Example:
/// ```dart
/// final user = await authService.login('user@example.com', 'password123');
/// print(user.name);
/// ```
Future<User> login(String email, String password) async {
  // Implementation
}
```

### README Updates

When adding new features, update:
- Features list
- Configuration section (if adding new env vars)
- API documentation
- Examples

### Creating Documentation

```bash
# Generate API documentation
flutter pub global activate dartdoc
dartdoc

# View documentation
open doc/api/index.html
```

---

## 🌟 Best Practices for Contributors

### Performance

- Avoid rebuilding widgets unnecessarily
- Use `const` constructors where possible
- Implement lazy loading for lists
- Optimize images and assets
- Profile before optimizing

### Accessibility

- Provide semantic labels for widgets
- Ensure sufficient color contrast
- Support screen readers
- Test with accessibility tools

### Security

- Never commit `.env` files
- Don't hardcode secrets or API keys
- Validate all user inputs
- Use HTTPS for all network requests
- Follow [SECURITY.md](SECURITY.md) guidelines

### UI/UX

- Follow Material Design guidelines
- Maintain consistent spacing and sizing
- Provide user feedback (loading states, errors)
- Support dark mode
- Test on different screen sizes

---

## 💬 Community

### Getting Help

- 📖 Read the [README](README.md) and [documentation](docs/)
- 🔍 Search [existing issues](https://github.com/THISJowi/THISJOWI/issues)
- 💬 Join [GitHub Discussions](https://github.com/THISJowi/THISJOWI/discussions)
- 📧 Email: support@thisjowi.uk

### Reporting Bugs

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md):

**Include:**
- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Screenshots (if applicable)
- Environment details (OS, Flutter version, etc.)

### Suggesting Features

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md):

**Include:**
- Clear description of the feature
- Use case and benefits
- Possible implementation approach
- Mockups or examples (if applicable)

---

## 🎉 Recognition

Contributors will be recognized in:
- README contributors section
- Release notes
- GitHub contributors page

---

## 📄 License

By contributing, you agree that your contributions will be licensed under the same [MIT License](../LICENSE) that covers this project.

---

## ✨ Thank You!

Your contributions make this project better. Whether it's:
- 🐛 Fixing a bug
- ✨ Adding a feature
- 📝 Improving documentation
- 🧪 Writing tests
- 💡 Sharing ideas

**Every contribution matters!**

---

<div align="center">

### Questions?

Feel free to reach out through [GitHub Discussions](https://github.com/THISJowi/THISJOWI/discussions)

Made with ❤️ by the THISJOWI community

</div>
