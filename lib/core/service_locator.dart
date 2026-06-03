/// Service Locator - Manages singleton instances of repositories
/// This ensures only one instance of each repository exists throughout the app
/// preventing multiple sync operations on the same resources
library;

import 'package:thisjowi/data/repository/passwordsRepository.dart';
import 'package:thisjowi/data/repository/notes_repository.dart';
import 'package:thisjowi/data/repository/otp_repository.dart';
import 'package:thisjowi/data/repository/profile_repository.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  late final PasswordsRepository _passwordsRepository;
  late final NotesRepository _notesRepository;
  late final OtpRepository _otpRepository;
  late final ProfileRepository _profileRepository;

  factory ServiceLocator() {
    return _instance;
  }

  ServiceLocator._internal() {
    _initializeRepositories();
  }

  void _initializeRepositories() {
    _passwordsRepository = PasswordsRepository();
    _notesRepository = NotesRepository();
    _otpRepository = OtpRepository();
    _profileRepository = ProfileRepository();
  }

  /// Get the singleton instance of PasswordsRepository
  PasswordsRepository get passwordsRepository => _passwordsRepository;

  /// Get the singleton instance of NotesRepository
  NotesRepository get notesRepository => _notesRepository;

  /// Get the singleton instance of OtpRepository
  OtpRepository get otpRepository => _otpRepository;

  /// Get the singleton instance of ProfileRepository
  ProfileRepository get profileRepository => _profileRepository;
}
