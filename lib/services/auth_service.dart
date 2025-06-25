// lib/services/auth_service.dart

// Nécessaire si vous utilisez Firebase.initializeApp() ici ou ailleurs
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_sign_in/google_sign_in.dart'; // Décommentez si vous implémentez Google Sign-In

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // final GoogleSignIn _googleSignIn = GoogleSignIn(); // Décommentez si vous implémentez Google Sign-In

  // Flux pour l'état d'authentification de l'utilisateur
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Ou, si vous voulez seulement savoir si un utilisateur est connecté ou non, et obtenir l'utilisateur actuel :
  // Stream<User?> get user => _auth.userChanges(); // Ou _auth.idTokenChanges();

  User? get currentUser => _auth.currentUser;

  // Méthode pour créer le document utilisateur dans Firestore
  Future<void> _createUserDocumentInFirestore(User firebaseUser,
      {String? displayNameFromProvider}) async {
    // Utiliser le displayName de l'utilisateur Firebase Auth s'il existe,
    // sinon celui fourni (utile pour email/password où on le demande séparément),
    // sinon une chaîne vide ou une logique par défaut.
    final String displayName = displayNameFromProvider ??
        firebaseUser.displayName ?? firebaseUser.email
        ?.split('@')
        .first ?? 'Utilisateur';

    try {
      // Vérifier d'abord si le document existe pour éviter d'écraser des données importantes
      // lors de connexions répétées avec des fournisseurs OAuth (comme Google)
      // Bien que pour l'inscription email/password, ce set va créer ou écraser (si set est utilisé).
      // Pour une logique "créer si n'existe pas", on peut faire un get() puis un set() conditionnel.
      // Mais pour la création initiale après inscription, .set() est généralement ce qu'on veut.

      final userDocRef = _firestore.collection('users').doc(firebaseUser.uid);
      final docSnapshot = await userDocRef.get();

      if (!docSnapshot.exists) { // Crée le document seulement s'il n'existe pas
        await userDocRef.set({
          'uid': firebaseUser.uid,
          'email': firebaseUser.email ?? '',
          'nomAffiche': displayName,
          'creeLe': FieldValue.serverTimestamp(),
          'soldePretAPlacerGlobal': 0.0,
          // Ajoutez ici d'autres champs initiaux que vous souhaitez pour un nouvel utilisateur
        });
        print("Document utilisateur créé pour ${firebaseUser.uid}");
      } else {
        // Optionnel: Mettre à jour certains champs si l'utilisateur se reconnecte, par exemple, le nom d'affichage s'il a changé
        // await userDocRef.update({'nomAffiche': displayName, 'derniereConnexion': FieldValue.serverTimestamp()});
        print("Document utilisateur existant pour ${firebaseUser
            .uid}. Connexion normale.");
      }
    } catch (e) {
      print(
          "Erreur lors de la création/vérification du document utilisateur Firestore: $e");
      // Gérer l'erreur comme il se doit (par exemple, logger, notifier l'utilisateur)
      // Il est crucial que l'application puisse fonctionner même si cette étape échoue temporairement,
      // ou qu'elle informe l'utilisateur d'un problème de configuration de compte.
    }
  }

  // Inscription avec Email et Mot de passe
  Future<User?> signUpWithEmailPassword(String email, String password,
      String displayName) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Mettre à jour le profil displayName dans Firebase Auth (important pour firebaseUser.displayName)
        await firebaseUser.updateDisplayName(displayName);
        // Recharger l'utilisateur pour que les changements (comme displayName) soient immédiatement disponibles
        await firebaseUser.reload();
        firebaseUser = _auth
            .currentUser; // Récupérer l'utilisateur mis à jour de FirebaseAuth

        // Créer le document utilisateur dans Firestore
        if (firebaseUser != null) { // Double vérification après reload
          await _createUserDocumentInFirestore(
              firebaseUser, displayNameFromProvider: displayName);
        }
      }
      return firebaseUser;
    } on FirebaseAuthException catch (e) {
      // Gérer les erreurs spécifiques à FirebaseAuth (e.g., email-already-in-use, weak-password)
      print("Erreur d'inscription FirebaseAuth: ${e.code} - ${e.message}");
      // Vous pouvez retourner e.code ou un message personnalisé pour l'afficher à l'utilisateur
      rethrow; // Propagez l'exception pour la gérer dans l'interface utilisateur
    } catch (e) {
      print("Erreur générale lors de l'inscription: $e");
      throw Exception(
          "Une erreur inconnue est survenue lors de l'inscription."); // Message générique
    }
  }

  // Connexion avec Email et Mot de passe
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      User? firebaseUser = userCredential.user;

      // Optionnel: vous pourriez appeler _createUserDocumentInFirestore ici aussi
      // si vous voulez vous assurer que le document existe ou le mettre à jour à chaque connexion.
      // Habituellement, il est créé à l'inscription.
      // Si vous le faites, assurez-vous que la logique dans _createUserDocumentInFirestore gère bien
      // le cas où le document existe déjà (par ex., en utilisant .update() ou en ne faisant rien).
      if (firebaseUser != null) {
        // Pour s'assurer que le doc est là si l'inscription a eu un souci ou pour les anciens utilisateurs
        await _createUserDocumentInFirestore(firebaseUser);
      }

      return firebaseUser;
    } on FirebaseAuthException catch (e) {
      print("Erreur de connexion FirebaseAuth: ${e.code} - ${e.message}");
      rethrow; // Propagez l'exception
    } catch (e) {
      print("Erreur générale lors de la connexion: $e");
      throw Exception("Une erreur inconnue est survenue lors de la connexion.");
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      // Si vous utilisez Google Sign-In, déconnectez-vous aussi de Google
      // if (await _googleSignIn.isSignedIn()) {
      //   await _googleSignIn.signOut();
      // }
      await _auth.signOut();
      print("Utilisateur déconnecté");
    } catch (e) {
      print("Erreur lors de la déconnexion: $e");
      // Gérer l'erreur si nécessaire
    }
  }

/* // --- Exemple pour Google Sign-In (à décommenter et adapter) ---
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // L'utilisateur a annulé la connexion
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Créer/Mettre à jour le document utilisateur dans Firestore
        // Le displayName vient directement de firebaseUser.displayName qui est peuplé par Google
        await _createUserDocumentInFirestore(firebaseUser);
      }
      return firebaseUser;
    } on FirebaseAuthException catch (e) {
      print("Erreur de connexion Google (FirebaseAuth): ${e.code} - ${e.message}");
      throw e;
    } catch (e) {
      print("Erreur générale lors de la connexion Google: $e");
      throw Exception("Une erreur inconnue est survenue lors de la connexion avec Google.");
    }
  }
  */
}