import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';

class MockFirebasePlatform extends FirebasePlatform {
  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return FirebaseAppPlatform(name ?? '[DEFAULT]', options ?? const FirebaseOptions(
      apiKey: '123',
      appId: '123',
      messagingSenderId: '123',
      projectId: '123',
    ));
  }

  @override
  List<FirebaseAppPlatform> get apps => [
    FirebaseAppPlatform('[DEFAULT]', const FirebaseOptions(
      apiKey: '123',
      appId: '123',
      messagingSenderId: '123',
      projectId: '123',
    ))
  ];

  @override
  FirebaseAppPlatform app([String name = '[DEFAULT]']) {
    return apps.first;
  }
}

void setupFirebaseMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FirebasePlatform.instance = MockFirebasePlatform();

  // Mock AssetManifest.json to prevent GoogleFonts from crashing
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (ByteData? message) async {
    // Return empty json object for AssetManifest.json
    final Uint8List encoded = Uint8List.fromList('{}'.codeUnits);
    return encoded.buffer.asByteData();
  });
}

Future<void> initializeMockFirebase() async {
  setupFirebaseMocks();
  await Firebase.initializeApp();
}

MockFirebaseAuth setupMockAuth({bool signedIn = false}) {
  final user = MockUser(
    isAnonymous: false,
    uid: 'test_uid',
    email: 'test@example.com',
    displayName: 'Test User',
  );
  return MockFirebaseAuth(mockUser: user, signedIn: signedIn);
}

MockGoogleSignIn setupMockGoogleSignIn() {
  return MockGoogleSignIn();
}
