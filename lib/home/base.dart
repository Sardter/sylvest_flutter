import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:sylvest_flutter/subjects/communities/create_community_page.dart';
import 'package:sylvest_flutter/discover/discover.dart';
import 'package:sylvest_flutter/home/home.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:sylvest_flutter/notifications/notifications_page.dart';
import 'package:badges/badges.dart';
import 'package:sylvest_flutter/notifications/notifications_service.dart';
import 'package:sylvest_flutter/post_builder/post_builder.dart';
import 'package:sylvest_flutter/subjects/user/profile_page.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';
import 'package:circular_menu/circular_menu.dart';

class BasePage extends StatefulWidget {
  @override
  State<BasePage> createState() => BasePageState();
}

class BasePageState extends State<BasePage>
    with SingleTickerProviderStateMixin {
  final _key = GlobalKey();
  bool _newNotifications = false;
  int _lastId = PushNotificationsService().socialLastId;
  int _index = 0;
  List<int> _traversedList = [0];
  final _circleMenuKey = GlobalKey<CircularMenuState>();
  bool _loading = false;

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
    });
    await Future.delayed(Duration(milliseconds: 360));
    await API().getLoginCred();
    PushNotificationsService().notificationStream();
    PushNotificationsService().actionStream(context, setPage);
    final newNotifications = await API().getUnreadNotifications(context);
    print("hereeeeee");
    _newNotifications = newNotifications['user'] ?? false;
    setState(() {
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _initialize();
    });
  }

  Widget router(int index, void Function() openDrawer) {
    switch (index) {
      case 0:
        return HomePage(() => openDrawer(), setPage);
      case 1:
        return DiscoverPage();
      case 2:
        return NotificationsPage(
          setPage: setPage,
        );
      case 3:
        return ProfilePage(
          Colors.white,
          const Color(0xFF733CE6),
          const Color(0xFF733CE6),
          setPage: setPage,
          popAgain: false,
        );
      case 4:
        return PostBuilderPage(backToLastPage: backToLast, setPage: setPage,);
      case 5:
        return CreateCommunityPage(
          communityCard: null,
          backToLastPage: backToLast,
        );
      default:
        throw UnimplementedError("Page doest not exist: $index");
    }
  }

  bool backToLast() {
    if (_traversedList.length > 1) {
      setState(() {
        final _last = _traversedList.removeLast();
        if (![4, 5, 6].contains(_last)) {
          _index = _last;
        } else {
          _index = 0;
        }
      });
      return false;
    }
    return true;
  }

  void setPage(int value) {
    if (value == _index) return;
    setState(() {
      _traversedList.add(_index);
      _index = value;
      if (_index == 2) {
        _newNotifications = false;
      }
    });
  }

  Widget _getProfilePicture(Color color) {
    return FutureBuilder<SmallProfileImage>(
      future: API().getProfilePicture(color),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Icon(
            LineIcons.user,
            color: color,
            size: 24,
          );
        }
        SmallProfileImage data = snapshot.data!;

        if (snapshot.data == null) {
          return Icon(
            LineIcons.user,
            color: color,
            size: 24,
          );
        }
        return data;
      },
    );
  }

  Widget _createButton() {
    return CircularMenu(
      key: _circleMenuKey,
      radius: 100,
      alignment: Alignment.bottomRight,
      toggleButtonBoxShadow: [
        BoxShadow(color: Colors.black12, spreadRadius: 2, blurRadius: 2)
      ],
      toggleButtonColor: Colors.white,
      toggleButtonIconColor: const Color(0xFF7F52DE),
      toggleButtonSize: 30,
      items: [
        CircularMenuItem(
            icon: LineIcons.edit,
            onTap: () =>
                {setPage(4), _circleMenuKey.currentState!.reverseAnimation()},
            color: Colors.white,
            iconColor: const Color(0xFF7F52DE),
            boxShadow: [
              BoxShadow(color: Colors.black12, spreadRadius: 2, blurRadius: 2)
            ]),
        CircularMenuItem(
            icon: LineIcons.users,
            onTap: () =>
                {setPage(5), _circleMenuKey.currentState!.reverseAnimation()},
            color: Colors.white,
            iconColor: const Color(0xFF7F52DE),
            boxShadow: [
              BoxShadow(color: Colors.black12, spreadRadius: 2, blurRadius: 2)
            ]),
      ],
    );
  }

  Future<bool> _willPop() async {
    return backToLast();
  }

  Widget _bottomNav() {
    return StreamBuilder<PushNotificationEvent>(
      stream: PushNotificationsService().eventStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // TODO
        } else {
          if (snapshot.connectionState == ConnectionState.active) {
            final event = snapshot.data!;
            if (event.lastSocialId != _lastId)
              _newNotifications = event.newSocialNotification;
          }
        }
        return SnakeNavigationBar.color(
          backgroundColor: Colors.white,
          behaviour: SnakeBarBehaviour.floating,
          elevation: 10,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          snakeShape: SnakeShape.rectangle,
          snakeViewColor: const Color(0xFF7F52DE),
          selectedItemColor: Colors.white,
          onTap: (index) => setPage(index),
          unselectedItemColor: Colors.blueGrey,
          currentIndex: _index,
          showUnselectedLabels: true,
          items: [
            BottomNavigationBarItem(icon: Icon(LineIcons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(LineIcons.search), label: 'Discover'),
            BottomNavigationBarItem(
                icon: Badge(
                  badgeColor: Color.fromARGB(255, 174, 142, 243),
                  position: BadgePosition(top: 0, end: 0),
                  showBadge: _newNotifications,
                  child: Icon(
                    LineIcons.heart,
                    color: _index == 2 ? Colors.white : Colors.black54,
                  ),
                ),
                label: 'Notices'),
            BottomNavigationBarItem(
                icon: _getProfilePicture(
                    _index == 3 ? Colors.white : Colors.black54),
                label: 'Profile'),
          ],
        );
      },
    );
  }

  @override
  Widget build(context) {
    return _loading
        ? InitialLoadingScreen()
        : WillPopScope(
            onWillPop: _willPop,
            child: SafeArea(
              top: false,
                child: Scaffold(
              key: _key,
              drawer: LevelDrawer(Color(0xFF733CE6), setPage),
              body: Stack(
                children: [
                  router(_index, () {
                    (_key.currentState as ScaffoldState).openDrawer();
                  }),
                  if (!const [4, 5].contains(_index))
                    Positioned.fill(
                      child: _bottomNav(),
                      bottom: 0,
                    ),
                  if (!const [4, 5].contains(_index))
                    Positioned.fill(child: _createButton(), bottom: 60)
                ],
              ),
            )));
  }
}


class InitialLoadingScreen extends StatelessWidget {
  const InitialLoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          colors: const [
            Color(0xFF733CE6),
            Color.fromARGB(255, 152, 120, 222)
          ]
        )
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                  "assets/images/sylvest_icon_no_background.png",
                  width: 70,
                  height: 70,
                ),
                const Text(
                  'sylvest',
                  style: TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 40,
                      color: Colors.white),
                )
            ]
          ),
        ),
      ),
    );
  }
}