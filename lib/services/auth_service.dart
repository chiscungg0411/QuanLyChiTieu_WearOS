import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // For Wear OS, we need to use minimal scopes
    scopes: ['email'],
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  /// Last error message for debugging
  String? lastError;

  // Sign in with Google - optimized for Wear OS
  Future<UserCredential?> signInWithGoogle() async {
    try {
      lastError = null;
      GoogleSignInAccount? googleUser;
      
      // On Wear OS, try silent sign-in first (uses the watch's already-signed-in Google account)
      // This is the recommended approach for Wear OS devices
      try {
        googleUser = await _googleSignIn.signInSilently();
        debugPrint('Silent sign-in result: ${googleUser?.email}');
      } catch (e) {
        debugPrint('Silent sign-in failed: $e');
      }
      
      // If silent sign-in failed, try interactive sign-in
      if (googleUser == null) {
        try {
          googleUser = await _googleSignIn.signIn();
          debugPrint('Interactive sign-in result: ${googleUser?.email}');
        } catch (e) {
          lastError = 'Interactive sign-in failed: $e';
          debugPrint(lastError);
          return null;
        }
      }
      
      if (googleUser == null) {
        lastError = 'User cancelled sign-in or no account available';
        debugPrint(lastError);
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        lastError = 'Failed to get authentication tokens';
        debugPrint(lastError);
        return null;
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Create user document in Firestore if it doesn't exist
      await _createUserDocument(userCredential.user);
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      lastError = 'Firebase Auth error: ${e.message}';
      debugPrint(lastError);
      return null;
    } catch (e) {
      lastError = 'Sign-in error: $e';
      debugPrint(lastError);
      return null;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User? user) async {
    if (user == null) return;
    
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();
    
    if (!docSnapshot.exists) {
      await userDoc.set({
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      await userDoc.update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Backup data to Firestore
  Future<void> backupData(Map<String, dynamic> data) async {
    final user = currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('backup')
        .doc('expenses')
        .set({
      'data': data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Restore data from Firestore
  Future<Map<String, dynamic>?> restoreData() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('backup')
        .doc('expenses')
        .get();

    if (doc.exists) {
      return doc.data()?['data'] as Map<String, dynamic>?;
    }
    return null;
  }
  
  /// Restore data with timestamp for polling sync comparison
  Future<({Map<String, dynamic>? data, DateTime? updatedAt})> restoreDataWithTimestamp() async {
    final user = currentUser;
    if (user == null) return (data: null, updatedAt: null);

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('backup')
        .doc('expenses')
        .get();

    if (doc.exists) {
      final docData = doc.data();
      final data = docData?['data'] as Map<String, dynamic>?;
      final timestamp = docData?['updatedAt'] as Timestamp?;
      return (data: data, updatedAt: timestamp?.toDate());
    }
    return (data: null, updatedAt: null);
  }
  
  /// Stream of backup data for real-time sync
  /// Listens to changes from other devices and notifies UI to refresh
  Stream<Map<String, dynamic>?> get backupDataStream {
    final user = currentUser;
    if (user == null) return Stream.value(null);
    
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('backup')
        .doc('expenses')
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return doc.data()?['data'] as Map<String, dynamic>?;
          }
          return null;
        });
  }
}

// Global instance
final authService = AuthService();
