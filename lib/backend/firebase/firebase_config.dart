import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyCmVMuyAjN1R30KEAuQelK8h-nizJX5PJ0",
            authDomain: "fo-co-co-89gnf5.firebaseapp.com",
            projectId: "fo-co-co-89gnf5",
            storageBucket: "fo-co-co-89gnf5.firebasestorage.app",
            messagingSenderId: "549026925121",
            appId: "1:549026925121:web:852d7afb0e3105222ad4c0"));
  } else {
    await Firebase.initializeApp();
  }
}
