import 'package:flutter/material.dart';
import 'package:line_icons/line_icon.dart';
import 'package:line_icons/line_icons.dart';
import 'package:sylvest_flutter/chat/chat_api.dart';
import 'package:sylvest_flutter/chat/chat_create_group_page.dart';
import 'package:sylvest_flutter/chat/chat_page.dart';
import 'package:intl/intl.dart';
import 'package:sylvest_flutter/chat/chat_util.dart';
import 'dart:convert';

import 'package:sylvest_flutter/services/api.dart';

import '../services/image_service.dart';

class ChatsPage extends StatefulWidget {
  final String? target;
  final void Function(int page)? setPage;

  const ChatsPage({this.target, required this.setPage});

  @override
  State<ChatsPage> createState() => ChatsPageState();
}

class ChatsPageState extends State<ChatsPage> {
  final _materialColor = const Color(0xFF733CE6);
  final _api = ChatAPI();

  List<Room> _rooms = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    if (await API().getLoginCred() == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You must login to access chat!")));
      Navigator.pop(context);
      if (widget.setPage != null) widget.setPage!(3);
      return;
    }
    _getRooms();
    _startSocket();
  }

  Future<void> _getRooms() async {
    setState(() {
      _loading = true;
    });
    final rooms = await _api.getLobbyRooms(context, _getRooms);
    if (widget.target != null) {
      final room = rooms
          .where((element) => element.data.roomDetails.title == widget.target)
          .first;
      room.getChat(context);
    }

    rooms.sort();
    if (mounted)
      setState(() {
        _rooms = rooms;
        _loading = false;
      });
  }

  Future<void> _startSocket() async {
    await _api.startSocket();
  }

  List<Widget> _chatsWithDividers(List<Widget>? chats) {
    if (chats == null) return [];
    chats = List.from(chats.reversed);
    List<Widget> _items = [];
    chats.forEach((chat) {
      _items.add(chat);
      //_items.add(Divider());
    });
    return _items;
  }

  void onNewMessage(Map content) {
    final data = MessageData.fromJson(content);
    for (int i = 0; i < _rooms.length; i++) {
      final room = _rooms[i];
      if (room.data.id == data.roomId) {
        final unread = room.data.messageDetails.unreadCount;
        _rooms[i] = room.copyWith(
            newData: room.data.copyWith(
                newMessage: data,
                unreadCount: data.author != _api.username ? unread + 1 : 0));
        _rooms.sort();
        break;
      }
    }
  }

  void onMessageSeen(Map content) {
    final roomId = content['room_id'];
    final messageId = content['message_id'];
    for (int i = 0; i < _rooms.length; i++) {
      final room = _rooms[i];
      if (room.data.id == roomId) {
        final lastMessage = room.data.messageDetails.lastMessage;
        if (lastMessage != null && lastMessage.id == messageId) {
          _rooms[i] = room.copyWith(
              newData: room.data.copyWith(
            newMessage: lastMessage.copyWith(isSeen: true),
          ));
        }
      }
    }
  }

  Widget _chatsStream() {
    return StreamBuilder(
      stream: _api.chatStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error while connecting to server!"),
            backgroundColor: Colors.red,
          ));
          print(snapshot.error);
        } else {
          if (snapshot.connectionState == ConnectionState.active) {
            _loading = false;
            final data = json.decode(snapshot.data as String);
            final command = data['command'];
            final content = data['content'];
            print(snapshot.data);
            switch (command) {
              case 'new_message':
                onNewMessage(content);
                break;
              case 'message_seen':
                onMessageSeen(content);
                break;
            }
          }
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            ListView(
              physics: AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(15),
              children: _chatsWithDividers(_rooms),
            ),
            if (_loading) _loadingWidget()
          ],
        );
      },
    );
  }

  Widget _loadingWidget() {
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
  Widget build(context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CreateGroupPage(
                      refresh: _getRooms,
                    ))),
        child: Icon(Icons.add, color: _materialColor),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          "Chats",
          style: TextStyle(color: _materialColor, fontFamily: 'Quicksand'),
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_left, color: _materialColor),
          onPressed: () {
            _api.closeChannel();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.more_horiz,
                color: _materialColor,
              ))
        ],
      ),
      body: _chatsStream(),
    );
  }
}

class Room extends StatefulWidget implements Comparable<Room> {
  final api = ChatAPI();
  final void Function() refresh;

  final RoomData data;
  ChatPage? chat;

  Room({
    required this.data,
    required this.refresh,
  });

  int compareTo(Room b) {
    if (this.data.messageDetails.lastMessage == null &&
        b.data.messageDetails.lastMessage == null)
      return 0;
    else if (this.data.messageDetails.lastMessage == null)
      return -1;
    else if (b.data.messageDetails.lastMessage == null) return 1;
    if (this.data.messageDetails.lastMessage!.datePosted ==
        b.data.messageDetails.lastMessage!.datePosted) return 0;

    return this
        .data
        .messageDetails
        .lastMessage!
        .datePosted
        .compareTo(b.data.messageDetails.lastMessage!.datePosted);
  }

  Room copyWith({RoomData? newData}) {
    return Room(data: newData ?? data, refresh: refresh);
  }

  @override
  State<Room> createState() => RoomState();

  Future<void> getChat(context) async {
    if (chat == null) {
      chat = _getChatPage();
    }
    // api.readMessagesCommand(room);
    this.unseenNum = 0;
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return chat!;
    }));
    refresh();
  }

  ChatPage _getChatPage() {
    return ChatPage(
      roomData: data,
      refresh: refresh,
    );
  }

  late int unseenNum = data.messageDetails.unreadCount;
}

class RoomState extends State<Room> {
  final materialColor = const Color(0xFF733CE6);

  String date() {
    if (widget.data.messageDetails.lastMessage == null) return '';
    final now = DateTime.now();
    final date = widget.data.messageDetails.lastMessage!.datePosted.toLocal();
    if (date.day == now.day) {
      return " | " + DateFormat.jm().format(date);
    } else if (now.day - date.day < 7) {
      return " | " + DateFormat('EEEEE', 'en_US').format(date);
    }
    return " | " + DateFormat.MMMMd('en_US').format(date);
  }

  void initState() {
    unseen();
    super.initState();
    //widget._getChatPage(widget.user).then((chat) => widget.chat = chat);
  }

  Widget _lastMessage(MessageData data) {
    String _messageShortner(String message) {
      if (message.length <= 15) return message;
      return message.substring(0, 13) + '...';
    }

    switch (data.type) {
      case MessageType.Image:
        return Row(
          children: [
            Icon(
              Icons.photo_camera_outlined,
              color: Colors.grey.shade500,
              size: 16,
            ),
            const SizedBox(width: 5),
            Text("Photo",
                style: TextStyle(
                    color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
            Text(
              date(),
              style: TextStyle(color: Colors.black45, fontSize: 12),
            )
          ],
        );
      case MessageType.File:
        return Row(
          children: [
            Icon(
              Icons.photo_camera_outlined,
              color: Colors.grey.shade500,
              size: 16,
            ),
            const SizedBox(width: 5),
            Text("File",
                style: TextStyle(
                    color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
            Text(
              date(),
              style: TextStyle(color: Colors.black45, fontSize: 12),
            )
          ],
        );
      case MessageType.Text:
        return Row(
          children: [
            Text(
                '${widget.data.messageDetails.lastMessage!.author}: ' +
                    _messageShortner(
                        widget.data.messageDetails.lastMessage!.content!),
                style: TextStyle(color: Colors.grey.shade700)),
            Text(
              date(),
              style: TextStyle(color: Colors.black45, fontSize: 12),
            )
          ],
        );
      case MessageType.Post:
        return Row(
          children: [
            Icon(
              Icons.post_add,
              color: Colors.grey.shade500,
              size: 16,
            ),
            const SizedBox(width: 5),
            Text("Post",
                style: TextStyle(
                    color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
            Text(
              date(),
              style: TextStyle(color: Colors.black45, fontSize: 12),
            )
          ],
        );
      case MessageType.Community:
        return Row(children: [
          Icon(
            Icons.people_alt,
            color: Colors.grey.shade500,
            size: 16,
          ),
          const SizedBox(width: 5),
          Text("Community",
              style: TextStyle(
                  color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
          Text(
            date(),
            style: TextStyle(color: Colors.black45),
          )
        ]);
    }
  }

  Widget? _lastStatus() {
    final message = widget.data.messageDetails.lastMessage;
    if (message == null) return null;
    if (message.author == widget.api.username) {
      if (message.seen) {
        return LineIcon(
          LineIcons.doubleCheck,
          color: const Color(0xFF8d61ea),
          size: 12,
        );
      } else {
        return Column(
          children: [
            const SizedBox(height: 5),
            LineIcon(
              LineIcons.check,
              color: const Color(0xFF8d61ea),
              size: 12,
            )
          ],
        );
      }
    }
    return null;
  }

  Widget _streakIndicator(int multiplier) {
    if (multiplier == 0)
      return const SizedBox(
        width: 20,
      );
    return Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xffe1d8f5),
                  blurRadius: 5,
                  spreadRadius: 1)
            ],
            color: const Color(0xFF8d61ea)),
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(left: 10),
        child: Center(
          child: RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: 'x',
                  style: TextStyle(fontSize: 10, color: Colors.white)),
              TextSpan(
                  text: multiplier.toString(),
                  style:
                      TextStyle(color: Colors.white, fontFamily: 'Quicksand'))
            ]),
          ),
        ));
  }

  Widget _newBadge(int unseen) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: const Color(0xFF8d61ea)),
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      child: Text(unseen.toString(),
          style: TextStyle(color: Colors.white, fontSize: 10)),
    );
  }

  void unseen() {
    // widget.messages.forEach((message) {
    //   if (message.authorId != widget.api.username &&
    //       !message.seenBy.contains(widget.api.username)) {
    //     count++;
    //   }
    // });
    // setState(() {
    //   widget.unseenNum = count;
    // });
  }

  @override
  Widget build(context) {
    return GestureDetector(
      onTap: () async {
        setState(() {
          widget.unseenNum = 0;
        });
        await widget.getChat(context);
        widget.refresh();
      },
      child: Container(
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2)
        ], color: Colors.white, borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.only(top: 10, bottom: 10, left: 10),
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SylvestImageProvider(
              url: widget.data.roomDetails.image,
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.data.roomDetails.title,
                    style: TextStyle(
                        fontSize: 18,
                        color: materialColor,
                        fontFamily: 'Quicksand')),
                Row(
                  children: [
                    if (_lastStatus() != null) _lastStatus()!,
                    if (_lastStatus() != null)
                      const SizedBox(
                        width: 5,
                      ),
                    if (widget.data.messageDetails.lastMessage != null)
                      _lastMessage(widget.data.messageDetails.lastMessage!)
                  ],
                ),
              ],
            )),
            if (widget.unseenNum != 0) _newBadge(widget.unseenNum),
            _streakIndicator(widget.data.streakDetails.multiplier),
          ],
        ),
      ),
    );
  }
}
