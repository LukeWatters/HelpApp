import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:testapp/screens/homepage.dart';
import 'helper/authenticate.dart';
import 'helper/helperfunction.dart';
import 'models/pushnotification.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print('Handling a background message ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  runApp(App());
}

class App extends StatefulWidget {
  // Create the initialization Future outside of `build`:
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  bool userisloggedin = false;

  @override
  void initState() {
    // TODO: implement initState

    getloginState();

    super.initState();
  }

  getloginState() async {
    await HelperFunction.getuserLoggedInSharedPreference().then((value) {
      setState(() {
        {
          if (value != null) {
            userisloggedin = value;
          } else {
            userisloggedin = false;
          }
        }
      });
    });
  }

  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return OverlaySupport(
      child: FutureBuilder(
        // Initialize FlutterFire:
        future: _initialization,
        builder: (context, snapshot) {
          // Check for errors
          if (snapshot.hasError) {
            print("error");
          }

          // Once complete, show your application
          if (snapshot.connectionState == ConnectionState.done) {
            return MaterialApp(
                theme: ThemeData(
                  primaryColor: Color(0xfff833AB4),
                  accentColor: Color(0xfff5B51D8),
                ),
                builder: BotToastInit(), //1. call BotToastInit
                navigatorObservers: [BotToastNavigatorObserver()],
                debugShowCheckedModeBanner: false,
                home: userisloggedin ? HomePage() : AuthenticatePage());
          }

          // Otherwise, show something whilst waiting for initialization to complete
          return Container();
        },
      ),
    );
  }
}
