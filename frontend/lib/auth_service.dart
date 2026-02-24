import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream para monitorar estado de autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuário atual
  User? get currentUser => _auth.currentUser;

  // Obter token JWT do usuário atual
  Future<String?> getIdToken() async {
    if (currentUser == null) return null;
    return await currentUser!.getIdToken();
  }

  // Login com Email e Senha
  Future<String?> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Verifica se o email foi validado (opcional, pode ser enforced)
      if (credential.user != null && !credential.user!.emailVerified) {
        // await credential.user!.sendEmailVerification();
        // return 'Por favor, verifique seu email antes de entrar.';
      }
      return null; // Sucesso
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        return 'Usuário ou senha incorretos.';
      } else if (e.code == 'wrong-password') {
        return 'Senha incorreta.';
      } else if (e.code == 'invalid-email') {
        return 'Email inválido.';
      }
      return 'Erro de autenticação: ${e.message}';
    } catch (e) {
      return 'Erro inesperado: $e';
    }
  }

  Future<String?> signUp({required String email, required String password}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      // Temporariamente desativado para evitar travamento no Web
      // await credential.user?.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'A senha é muito fraca.';
      } else if (e.code == 'email-already-in-use') {
        return 'Este email já está cadastrado.';
      }
      return 'Erro no cadastro: ${e.message}';
    } catch (e) {
      return 'Erro inesperado: $e';
    }
  }

  // Login com Google
  Future<String?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Fluxo Web
        final GoogleAuthProvider authProvider = GoogleAuthProvider();
        await _auth.signInWithPopup(authProvider);
      } else {
        // Fluxo Mobile
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return 'Login cancelado pelo usuário.';

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth.signInWithCredential(credential);
      }
      return null;
    } catch (e) {
      return 'Erro no login com Google: $e';
    }
  }

  // Enviar email de redefinição de senha
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } catch (e) {
      return 'Erro ao enviar email: $e';
    }
  }

  // Logout
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
