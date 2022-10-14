import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:sylvest_flutter/notifications/notifications_service.dart';
import 'package:sylvest_flutter/notifications/requests_page.dart';
import 'package:sylvest_flutter/services/mangers.dart';

import '../services/image_service.dart';

class NotificationsPage extends StatefulWidget {
  final void Function(int value) setPage;
  final int? launchId;

  const NotificationsPage({required this.setPage, this.launchId});

  @override
  State<NotificationsPage> createState() => NotificationsPageState();
}

class NotificationsPageState extends State<NotificationsPage> {
  final _manager = NotificationManager();

  List<Widget> _notifications = [];
  int _requestNum = 0;
  bool _refreshing = false;
  bool _loading = false;

  void _onNewNotification(Map data) {
    final notification = NotificationWidget.fromMap(data);
    if (notification.type == 'follow_request') {
      _requestNum++;
    }
    _notifications.insert(0, notification);
  }

  Future<void> _refresh() async {
    if (await API().loginCred == null) {
      widget.setPage(3);
      return;
    }
    setState(() {
      _refreshing = true;
    });
    _manager.reset();
    final initialNotifications = await _manager.getNotifications(context);
    final initialRequestNum = await API().getFollowRequestCount(context);

    if (mounted)
      setState(() {
        _notifications = initialNotifications;
        _requestNum = initialRequestNum;
        _refreshing = false;
      });

    if (widget.launchId != null) {
      _launchNotification(widget.launchId!);
    }
  }

  Future<void> _load() async {
    if (!_loading && _manager.next()) {
      setState(() {
        _loading = true;
        _notifications = _notifications.cast<Widget>();
        _notifications += [LoadingIndicator()];
      });

      final newNotifications = await _manager.getNotifications(context);

      if (mounted)
        setState(() {
          _notifications.removeLast();
          _notifications += newNotifications;
          _loading = false;
        });

      if (widget.launchId != null) {
        _launchNotification(widget.launchId!);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _refresh();
    });
  }

  List<Widget> _builder(List<Widget> notifications) {
    if (notifications.isEmpty) {
      notifications = [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 250,
              ),
              Icon(
                LineIcons.heart,
                color: Colors.black54,
                size: 50,
              ),
              Text(
                "Your notifications will be presented here",
                style: TextStyle(color: Colors.black54, fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
      ];
    }
    return notifications;
  }

  void _launchNotification(int notificationId) {
    try {
      final launched = _notifications.firstWhere((element) {
        if (element is NotificationWidget) {
          return element.id == notificationId;
        }
        return false;
      }) as NotificationWidget;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  PushNotificationsService.routeFromNotification(
                      launched.itemId!, launched.type, context)));
    } catch (e) {
      print(e);
    }
  }

  Widget _requests() {
    return RequestsWidget(requestNum: _requestNum);
  }

  Widget _notificationsWidget(context) {
    return _refreshing
        ? LoadingIndicator()
        : StreamBuilder(
            stream: FirebaseMessaging.onMessage,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Something went wrong"),
                  backgroundColor: Colors.red,
                ));
              } else {
                if (snapshot.connectionState == ConnectionState.active) {
                  final message = snapshot.data as RemoteMessage;
                  _onNewNotification(message.data);
                }
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: CustomScrollView(
                  physics: AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  slivers: [
                    SliverList(
                        delegate: SliverChildListDelegate([
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: [if (_requestNum != 0) _requests()] +
                              List.from(_builder(_notifications))
                                  .cast<Widget>(),
                        ),
                      )
                    ]))
                  ],
                ),
              );
            },
          );
  }

  Widget _refreshingWidget() {
    return Positioned(
        top: 100,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          padding: EdgeInsets.all(5),
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color.fromARGB(255, 154, 121, 226),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          centerTitle: true,
          title: Text('Notifications',
              style: TextStyle(
                color: const Color(0xFF733CE6),
                fontFamily: 'Quicksand',
              ))),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels <
              notification.metrics.minScrollExtent - 50) {
            _refresh();
          } else if (notification.metrics.pixels >
              notification.metrics.maxScrollExtent) {
            _load();
          }
          return false;
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            _notificationsWidget(context),
            if (_refreshing) _refreshingWidget()
          ],
        ),
      ),
    );
  }
}

class NotificationWidget extends StatelessWidget {
  final _notificationFromUserTypes = const [
    'like',
    'comment',
    'like_comment',
    'follow',
    'follow_request',
    'join',
    'contribute',
    'attend',
    'token'
  ];
  final _chainNottificationTypes = const ['level_up', 'reward'];

  factory NotificationWidget.fromMap(Map data) {
    final pushData = data['data'] != null
        ? PushNotificationData.fromJson(data['data'])
        : PushNotificationData.fromJson(data);

    return NotificationWidget(
        id: pushData.content.id,
        itemId: pushData.itemId,
        imageUrl: pushData.content.largeIcon,
        title: pushData.content.body,
        time: pushData.time,
        type: pushData.type);
  }

  final int id;
  final String title, type;
  final String? imageUrl;
  final DateTime? time;
  final int? itemId;

  const NotificationWidget(
      {Key? key,
      required this.title,
      required this.type,
      this.imageUrl,
      required this.id,
      required this.time,
      required this.itemId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (_notificationFromUserTypes.contains(type)) {
      return NotificationFromUserWidget(
        imageUrl: imageUrl,
        title: title,
        type: type,
        time: time!,
        itemId: itemId!,
      );
    } else if (_chainNottificationTypes.contains(type)) {
      return ChainNottification(title: title, type: type);
    } else if (type == "message" || type == "follower_post") {
      return SizedBox();
    }
    throw UnimplementedError('Type is not implemented: $type');
  }
}

class ChainNottification extends StatelessWidget {
  final String title, type;

  const ChainNottification({Key? key, required this.title, required this.type})
      : super(key: key);

  Widget _content() {
    switch (type) {
      case 'level_up':
        return Column(
          children: [
            const Text("Leveled up!",
                style: TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 5),
            Text(title, style: TextStyle(color: Colors.white))
          ],
        );
      case 'reward':
        return Column(children: [
          const Text("Token Reward!",
              style: TextStyle(color: Colors.white, fontSize: 20)),
          const SizedBox(height: 5),
          Text(title, style: TextStyle(color: Colors.white))
        ]);
      default:
        throw UnimplementedError('Type is not implemented: $type');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            const Color(0xFF733CE6),
            Color.fromARGB(255, 143, 104, 226)
          ]),
          borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(10),
      width: double.maxFinite,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: _content(),
    );
  }
}

class NotificationFromUserWidget extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final String type;
  final DateTime time;
  final int itemId;
  const NotificationFromUserWidget(
      {required this.imageUrl,
      required this.title,
      required this.type,
      required this.time,
      required this.itemId});

  factory NotificationFromUserWidget.fromMap(Map data) {
    final content = jsonDecode(data['data']['content']);
    return NotificationFromUserWidget(
        imageUrl: content['largeIcon'],
        title: content['body'],
        time: DateTime.parse(data['time']),
        itemId: data['item_id'],
        type: data['data']['type']);
  }

  Icon _icon() {
    final color = _theme()['material_color'];
    switch (type) {
      case 'like':
        return Icon(
          LineIcons.heartAlt,
          color: color,
        );
      case 'like_comment':
        return Icon(
          LineIcons.heartAlt,
          color: color,
        );
      case 'follow':
        return Icon(
          LineIcons.userPlus,
          color: color,
        );
      case 'follow_request':
        return Icon(
          LineIcons.userPlus,
          color: color,
        );
      case 'contribute':
        return Icon(
          LineIcons.handshake,
          color: color,
        );
      case 'attend':
        return Icon(LineIcons.calendar, color: color);
      case 'token':
        return Icon(
          LineIcons.coins,
          color: color,
        );
      case 'comment':
        return Icon(
          LineIcons.comment,
          color: color,
        );
      case 'join':
        return Icon(
          LineIcons.users,
          color: color,
        );
      default:
        throw Exception("Type is not expected: $type");
    }
  }

  Map<String, Color> _theme() {
    switch (type) {
      case 'contribute':
        return {
          'text_color': Colors.white,
          'background_color': const Color(0xFF733CE6),
          'material_color': Colors.white,
        };
      case 'attend':
        return {
          'text_color': Colors.white,
          'background_color': const Color(0xFFe6733c),
          'material_color': Colors.white,
        };
      default:
        return {
          'text_color': Colors.black,
          'background_color': Colors.white,
          'material_color': const Color(0xFF733CE6),
        };
    }
  }

  final modalPages = const [RequestsPage];

  @override
  Widget build(context) {
    return InkWell(
      onTap: () {
        final page = PushNotificationsService.routeFromNotification(
            itemId, type, context);
        if (modalPages.contains(page.runtimeType)) {
          showMaterialModalBottomSheet(
              context: context,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(30))),
              builder: (context) => page);
        } else {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => page));
        }
      },
      child: Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _theme()['background_color']!,
                _theme()['background_color']!.withOpacity(0.75)
              ]),
              //color: _theme()['background_color'],
              borderRadius: BorderRadius.circular(30)),
          child: IntrinsicHeight(
            child: Row(
              children: [
                SylvestImageProvider(
                  url: imageUrl,
                ),
                const SizedBox(width: 15),
                _icon(),
                VerticalDivider(
                  width: 15,
                  color: _theme()['material_color']!.withOpacity(0.2),
                  thickness: 1,
                  indent: 8,
                  endIndent: 8,
                ),
                Flexible(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                        child: Text(title,
                            style: TextStyle(
                                fontSize: 14, color: _theme()['text_color']))),
                    Text(DateFormat('d MMM y | k:m').format(time),
                        style: TextStyle(
                            fontSize: 8,
                            color: _theme()['text_color']!.withOpacity(0.35),
                            fontWeight: FontWeight.bold))
                  ],
                )),
              ],
            ),
          )),
    );
  }
}
