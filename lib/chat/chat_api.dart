import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sylvest_flutter/_extra_libs/chat_library/chat_types/flutter_chat_types.dart'
    as messageTypes;
import 'package:sylvest_flutter/chat/chat_util.dart';
import 'package:sylvest_flutter/chat/chat_rooms_page.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:sylvest_flutter/config/env.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

class ChatAPI {
  static final ChatAPI _chatAPI = ChatAPI._internal();
  factory ChatAPI() {
    return _chatAPI;
  }
  ChatAPI._internal();

  final String chatAddress = 'ws://${Env.BASE_WITH_PORT}/ws/chat/';
  final _mainAPI = API();
  IOWebSocketChannel? channel;
  Stream<dynamic>? chatStream;

  String? username;

  Future<void> startSocket() async {
    final data = await _mainAPI.getCurrentUsernameAndImage();
    if (data != null) {
      this.username = data['username'];
      channel = IOWebSocketChannel.connect(chatAddress,
          headers: {'username': username});
      chatStream = channel!.stream.asBroadcastStream();
    }
  }

  Future<List<Room>> getLobbyRooms(BuildContext context, void Function() refresh) async {
    await _mainAPI.getLoginCred();
    final url = '${Env.BASE_URL_PREFIX}/rooms';

    final rooms = await _mainAPI.getResponseItems(context, url);

    return rooms
        .map<Room>((room) => Room(data: RoomData.fromJson(room), refresh: refresh,))
        .toList();
  }

  Future<Room> getRoom(int id, context, void Function() refresh) async {
    final url = '${Env.URL_PREFIX}/rooms/$id';

    final response =
        await _mainAPI.getResponseItems(context, url);

    return Room(data: RoomData.fromJson(response), refresh: refresh,);
  }

  Future<Room> getProfileRoom(int profileId, context) async {
    final url = '${Env.URL_PREFIX}/profiles/$profileId/chat';

    final response =
    await _mainAPI.getResponseItems(context, url);

    return Room(data: RoomData.fromJson(response), refresh: () {});
  }

  Future<Room> getCommunityRoom(int communityId, context) async {
    final url = '${Env.URL_PREFIX}/communities/$communityId/chat';

    final response =
    await _mainAPI.getResponseItems(context, url);

    return Room(data: RoomData.fromJson(response), refresh: () {});
  }

  Future<Room> getOrCreateRoom(String targetName, context, void Function() refresh) async {
    final loginCred = await _mainAPI.getLoginCred();
    final body = {'target': targetName};
    final url = '${Env.URL_PREFIX}/rooms/get_or_create_p2p/';
    final response =
        await _mainAPI.postAndGetResponseItems(context, url, loginCred, body);
    return Room(data: RoomData.fromJson(response), refresh: refresh,);
  }

  Future<Room> getOrCreateGroup(CreateRoomData data, context, void Function() refresh) async {
    final loginCred = await _mainAPI.getLoginCred();
    final url = '${Env.URL_PREFIX}/rooms/get_or_create_group/';
    final response = await _mainAPI.postAndGetResponseItems(
        context, url, loginCred, data.toJson());
    print(response);
    return Room(data: RoomData.fromJson(response), refresh: refresh,);
  }

  Future<Room?> roomActions(RoomActionData data, int id, context, void Function() refresh) async {
    final loginCred = await _mainAPI.getLoginCred();
    final url = '${Env.URL_PREFIX}/rooms/$id/';
    final response =
        await _mainAPI.patchItems(context, url, loginCred, data.toJson());
    try {
      return Room(data: RoomData.fromJson(response), refresh: refresh,);
    } catch (e) {
      return null;
    }
  }

  Future<List<RoomParticipantData>> roomParticipants(int id, context) async {
    await _mainAPI.getLoginCred();
    final url = '${Env.URL_PREFIX}/rooms/$id/participants';
    final response = await _mainAPI.getResponseItems(context, url);
    return response
        .map<RoomParticipantData>(
            (participant) => RoomParticipantData.fromJson(participant))
        .toList();
  }

  Future<Room> collectXpFromRoom(int roomId, context, void Function() refresh) async {
    final loginCred = await _mainAPI.getLoginCred();
    final url = '${Env.URL_PREFIX}/rooms/$roomId/collect_reward';
    final response =
        await _mainAPI.postAndGetResponseItems(context, url, loginCred, null);
    return Room(data: RoomData.fromJson(response), refresh: refresh,);
  }

  Future<Room> updateRoom(int roomId, RoomUpdateData data, context, void Function() refresh) async {
    final loginCred = await _mainAPI.getLoginCred();
    final url = '${Env.URL_PREFIX}/rooms/$roomId/';

    final response =
        await _mainAPI.patchItems(context, url, loginCred, data.toJson());
    return Room(data: RoomData.fromJson(response), refresh: refresh,);
  }

  Future<List<messageTypes.Message>> getMessages(context,
      {MessageQuery query = MessageQuery.Unread,
      required int room,
      int index = 0}) async {
    await _mainAPI.getLoginCred();
    final url = '${Env.URL_PREFIX}/messages/?room=$room'
        '&index=$index&action=${query.toString().toLowerCase().split('.').last}';
    final response = await _mainAPI.getResponseItems(context, url);
    return response
        .map<messageTypes.Message>((message) =>
            messageTypes.Message.fromData(MessageData.fromJson(message)))
        .toList();
  }

  Future<messageTypes.Message> messageAction(
      int messageId, MessageAction action, context) async {
    Map<MessageAction, String> _actionToStr =
        messageActionFromString.map((key, value) => MapEntry(value, key));

    final loginCred = await _mainAPI.getLoginCred();
    final url = '${Env.URL_PREFIX}/messages/$messageId/';
    final body = {'action': _actionToStr[action]};
    final response = await _mainAPI.patchItems(context, url, loginCred, body);
    return messageTypes.Message.fromData(MessageData.fromJson(response));
  }

  Future<messageTypes.Message> createMessage(
      MessageCreateData data, context) async {
    final loginCred = await _mainAPI.getLoginCred();
    final url = '${Env.URL_PREFIX}/messages/';
    final response = await _mainAPI.postAndGetResponseItems(
        context, url, loginCred, data.toJson());
    print(response);
    return messageTypes.Message.fromData(MessageData.fromJson(response));
  }

  messageTypes.Message fromNewMessage(Map data) {
    return messageTypes.Message.fromData(MessageData.fromJson(data));
  }

  void onMessageSeen(int seenId, List<messageTypes.Message> messages) {
    final seenIdStr = seenId.toString();
    for (int i = 0; i < messages.length; i++) {
      final curr = messages[i];
      if (curr.id != seenIdStr) continue;
      messages[i] = curr.copyWith(status: messageTypes.Status.read);
    }
  }

  void onMessageSaved(int savedId, List<messageTypes.Message> messages) {
    final seenIdStr = savedId.toString();
    for (int i = 0; i < messages.length; i++) {
      final curr = messages[i];
      if (curr.id != seenIdStr) continue;
      messages[i] = curr.copyWith(saved: true);
    }
  }

  void closeChannel() {
    channel!.sink.close(status.goingAway);
    channel = null;
    chatStream = null;
  }
}

class MessageQueryManager {
  final _api = ChatAPI();
  int _index = 0;
  bool _hasNext = true;

  Future<List<messageTypes.Message>> getSavedMessages(
      int roomId, context) async {
    if (!_hasNext) return [];
    final messages = await _api.getMessages(context,
        room: roomId, query: MessageQuery.Saved, index: _index);
    _index++;
    if (messages.isEmpty) _hasNext = false;
    return messages;
  }
}
