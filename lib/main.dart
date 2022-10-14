import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:sylvest_flutter/home/base.dart';
import 'package:sylvest_flutter/discover/discover.dart';
import 'package:sylvest_flutter/config/firebase_options.dart';
import 'package:sylvest_flutter/auth/login_page.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:sylvest_flutter/notifications/notifications_page.dart';
import 'package:sylvest_flutter/notifications/notifications_service.dart';
import 'package:sylvest_flutter/services/dynamic_link_service.dart';
import 'package:sylvest_flutter/subjects/user/profile_page.dart';
import 'package:sylvest_flutter/auth/register_page.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.data}");

  PushNotificationsService().createNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationsService().initializeAwesomeNotifications();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final PendingDynamicLinkData? initialLink = await FirebaseDynamicLinks.instance.getInitialLink();

  initializeDateFormatting().then((_) => runApp(Sylvest(initialLink: initialLink,)));
}

class Sylvest extends StatefulWidget {
  const Sylvest({Key? key, this.initialLink}) : super(key: key);
  final PendingDynamicLinkData? initialLink;

  @override
  State<Sylvest> createState() => _SylvestState();
}

class _SylvestState extends State<Sylvest> {
  final Color backgroundColor = Colors.white,
      materialColor = const Color(0xFF733CE6),
      secondaryColor = Colors.black;
  bool _loading = false;

  static const String _title = 'sylvest';

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
    });
    await API().initializeFirebase();
    await PushNotificationsService().initialise();
    DynamicLinkService().handleForground(context);

    if (widget.initialLink != null) {
      DynamicLinkService().handleUri(widget.initialLink!.link, context);
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _initialize();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _loading ? LoadingIndicator() : MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _title,
      initialRoute: '/',
      theme: ThemeData(
          primaryColor: const Color(0xFF8d61ea),
          appBarTheme:
          AppBarTheme(backgroundColor: const Color(0xFF8d61ea)),
          scaffoldBackgroundColor: const Color(0xFFf0efef),
          fontFamily: 'Helvetica'),
      routes: {
        '/': (context) => BasePage(),
        '/discover': (context) =>
            DiscoverPage(),
        '/notifications': (context) =>
            NotificationsPage(setPage: (value) {}),
        '/login': (context) => LoginPage(
          backgroundColor,
          materialColor,
          secondaryColor,
          popAgain: false,
          setPage: (page) {},
        ),
        '/register': (context) =>
            RegisterPage(),
        '/user': (context) => ProfilePage(
          Colors.white,
          const Color(0xFF733CE6),
          const Color(0xFF733CE6),
          setPage: (page) {},
          popAgain: false,
        )
        //'/create_post': (context) => PostBuilderPage(),
      },
      //home: SylvestMain(),
    );
  }
}

