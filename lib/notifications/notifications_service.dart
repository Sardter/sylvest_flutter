import 'dart:async';
import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:sylvest_flutter/chat/chat_rooms_page.dart';
import 'package:sylvest_flutter/notifications/notifications_page.dart';
import 'package:sylvest_flutter/posts/pages/post_detail_page.dart';
import 'package:sylvest_flutter/notifications/requests_page.dart';
import 'package:sylvest_flutter/subjects/user/user_page.dart';

import 'package:sylvest_flutter/subjects/communities/communities.dart';

class PushNotificationData {
  final String type;
  final PushNotificationContent content;
  final int? itemId;
  final DateTime time;

  const PushNotificationData(
      {required this.type,
      required this.content,
      required this.time,
      required this.itemId});

  factory PushNotificationData.fromJson(Map data) {
    return PushNotificationData(
        type: data['type'],
        content: PushNotificationContent.fromJson(json.decode(data['content'])),
        time: DateTime.parse(data['time']),
        itemId: data['item_id'] != null ? int.parse(data['item_id']) : null);
  }
}

class PushNotificationContent {
  final String? largeIcon;
  final String title;
  final int id;
  final String body;
  final String channelKey;
  final String groupKey;
  final NotificationCategory category;

  const PushNotificationContent(
      {required this.largeIcon,
      required this.title,
      required this.id,
      required this.groupKey,
      required this.category,
      required this.body,
      required this.channelKey});

  factory PushNotificationContent.fromJson(Map json) {
    NotificationCategory _categoryFromString(String category) {
      switch (category) {
        case 'social':
          return NotificationCategory.Social;
        case 'message':
          return NotificationCategory.Message;
        default:
          throw Exception("Category not expected $category");
      }
    }

    return PushNotificationContent(
        largeIcon: json['largeIcon'],
        title: json['title'],
        id: json['id'],
        body: json['body'],
        category: _categoryFromString(json['category']),
        groupKey: json['groupKey'],
        channelKey: json['channelKey']);
  }
}

class PushNotificationEvent {
  final bool newSocialNotification;
  final bool newMessageNotification;
  final int lastMessageId;
  final int lastSocialId;

  const PushNotificationEvent(
      {this.newMessageNotification = false,
      this.newSocialNotification = false,
      this.lastMessageId = -1,
      this.lastSocialId = -1});
}

class PushNotificationsService {
  final _notifications = AwesomeNotifications();
  final _stream = FirebaseMessaging.onMessage;
  int _messageLastId = -1;
  int _socialLastId = -1;

  int get messageLastId => _messageLastId;
  int get socialLastId => _socialLastId;

  String? chatRoomName = null;
  final _eventController = StreamController<PushNotificationEvent>();
  late final Stream<PushNotificationEvent> eventStream =
      _eventController.stream.asBroadcastStream();

  static final PushNotificationsService _service =
      PushNotificationsService._internal();

  factory PushNotificationsService() {
    return _service;
  }

  PushNotificationsService._internal();

  final foregroundNotifications = const ['message', 'reward', 'level_up'];

  Future initialise() async {
    await FirebaseMessaging.instance.getInitialMessage();
  }

  void _onMessageNotification(PushNotificationData data) {
    if (data.content.id == _messageLastId) return;
    _messageLastId = data.content.id;
    final room = data.content.body.split(':')[0];
    if (chatRoomName == room) return;
    createNotificationFromData(data);
    _eventController.add(PushNotificationEvent(
        newMessageNotification: true, lastMessageId: messageLastId));
  }

  void _onSocialNotification(PushNotificationData data) {
    if (data.content.id == _socialLastId) return;
    _socialLastId = data.content.id;
    createNotificationFromData(data);
    _eventController.add(PushNotificationEvent(
        newSocialNotification: true, lastSocialId: socialLastId));
  }

  void notificationStream() {
    _stream.listen((message) {
      final data = PushNotificationData.fromJson(message.data);
      if (foregroundNotifications.contains(data.type)) {
        if (data.type == "message") {
          _onMessageNotification(data);
        } else {
          _onSocialNotification(data);
        }
      }
    });
  }

  Future<bool> initializeAwesomeNotifications() async {
    return await _notifications.initialize(
        'resource://drawable/ic_launcher',
        [
          NotificationChannel(
              channelGroupKey: 'social_group',
              channelKey: 'social_channel',
              channelName: 'Social notifications',
              channelDescription: 'Notification channel for social activities',
              defaultColor: Color(0xFF9D50DD),
              ledColor: Colors.white),
          NotificationChannel(
              channelGroupKey: 'message_group',
              channelKey: 'message_channel',
              channelName: 'Message notifications',
              channelDescription: 'Message channel for messages',
              defaultColor: Color(0xFF9D50DD),
              ledColor: Colors.purple)
        ],
        // Channel groups are only visual and are not required
        channelGroups: [
          NotificationChannelGroup(
              channelGroupkey: 'social_group',
              channelGroupName: 'Social group'),
          NotificationChannelGroup(
              channelGroupkey: 'message_group',
              channelGroupName: 'Message group')
        ],
        debug: true);
  }

  void actionStream(BuildContext context, void Function(int) setPage) {
    _notifications.actionStream.listen((event) {
      if (event.channelKey == 'message_channel') {
        final target = event.body!.split(':')[0];
        event.payload;
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return ChatsPage(
            target: target,
            setPage: null,
          );
        }));
      } else {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                NotificationsPage(setPage: setPage, launchId: event.id)));
      }
    });
  }

  static Widget routeFromNotification(
      int itemId, String notificationType, BuildContext context) {
    switch (notificationType) {
      case 'like':
        return PostDetailPage(itemId);
      case 'like_comment':
        return PostDetailPage(itemId);
      case 'attend':
        return PostDetailPage(itemId);
      case 'contribute':
        return PostDetailPage(itemId);
      case 'comment':
        return PostDetailPage(itemId);
      case 'follow':
        return UserPage(itemId);
      case 'follow_request':
        return RequestsPage();
      case 'join':
        return CommunityPage(id: itemId);
      case 'token':
        return UserPage(itemId);
      default:
        throw Exception("Type not expected: $notificationType");
    }
  }

  Future<bool> createNotificationFromData(PushNotificationData data) async {
    final critical = data.type == 'message';

    return await _notifications.createNotification(
        content: NotificationContent(
            id: data.content.id,
            displayOnBackground: true,
            displayOnForeground: true,
            autoDismissible: true,
            criticalAlert: critical,
            wakeUpScreen: critical,
            showWhen: critical,
            fullScreenIntent: critical,
            // notificationLayout: critical
            //     ? NotificationLayout.Messaging
            //     : NotificationLayout.BigPicture,
            body: data.content.body,
            largeIcon: data.content.largeIcon,
            roundedLargeIcon: true,
            title: 'Sylvest',

            groupKey: data.content.groupKey,
            channelKey: data.content.channelKey));
  }

  Future<bool> createNotification(RemoteMessage message) async {
    final data = PushNotificationData.fromJson(message.data);

    return await createNotificationFromData(data);
  }
}
