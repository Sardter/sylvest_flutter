import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:line_icons/line_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:sylvest_flutter/config/env.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:sylvest_flutter/chat/chat_api.dart';
import 'package:sylvest_flutter/chat/chat_util.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:sylvest_flutter/posts/post_util.dart';
import 'package:sylvest_flutter/services/mangers.dart';
import 'package:sylvest_flutter/subjects/user/user_page.dart';

import '../services/image_service.dart';

Future<dynamic> launchModal(BuildContext context, Widget modal) async {
  return await showMaterialModalBottomSheet(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      context: context,
      builder: (context) => modal);
}

enum UserListBehaviour { Push, Pop }

class UserListModal extends StatefulWidget {
  final UserManagerType type;
  final String title;
  final UserListBehaviour behaviour;
  final int? id;

  const UserListModal(
      {required this.title,
      required this.type,
      this.behaviour = UserListBehaviour.Push,
      required this.id});

  @override
  State<UserListModal> createState() => _UserListModalState();
}

class _UserListModalState extends State<UserListModal> {
  late final _manager = UserManager(type: widget.type);
  List<UserData> _users = [];
  bool _loading = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _getUsers();
    });
    super.initState();
  }

  Future<void> _getUsers() async {
    setState(() {
      _loading = true;
    });
    final newUsers = await _manager.getUser(context, widget.id);
    setState(() {
      _users = newUsers;
      _loading = false;
    });
  }

  Future<void> _moreUsers() async {
    if (_loading || !_manager.next()) return;
    setState(() {
      _loading = true;
    });
    final newUsers = await _manager.getUser(context, widget.id);
    setState(() {
      _users.addAll(newUsers);
      _loading = false;
    });
  }

  Widget _user(context, String? image, String name, int id) {
    return GestureDetector(
      onTap: () {
        if (widget.behaviour == UserListBehaviour.Push) {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return UserPage(id);
          }));
        } else {
          Navigator.pop(context, id);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Row(
          children: [
            SylvestImageProvider(
              url: image,),
            const SizedBox(
              width: 10,
            ),
            Text(name)
          ],
        ),
      ),
    );
  }

  List<Widget> _usersWidget(context) {
    return _users
        .map<Widget>((UserData user) =>
            _user(context, user.profileImage, user.username, user.id))
        .toList();
  }

  @override
  Widget build(context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >
            notification.metrics.maxScrollExtent) {
          _moreUsers();
        }
        return false;
      },
      child: ListView(
          padding: const EdgeInsets.all(10),
          physics:
              AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          controller: ModalScrollController.of(context),
          shrinkWrap: true,
          children: <Widget>[
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Quicksand', fontSize: 18),
            ),
            ..._usersWidget(context),
            if (_loading) LoadingIndicator()
          ]),
    );
  }
}



class ChatSharableData {
  final int id;
  final String title;
  final String? image;
  final RoomType type;

  const ChatSharableData({required this.id, required this.image, required this.title, required this.type});

  factory ChatSharableData.fromJson(Map json) {
    return ChatSharableData(id: json['id'], image: json['image'], title: json['title'], type: roomTypeFromString[json['room_type']]!);
  }
}

class ShareableUsers extends StatefulWidget {
  const ShareableUsers(
      {Key? key,
      required this.users,
      required this.username,
      required this.shareableId,
      required this.shareable})
      : super(key: key);
  final List<ChatSharableData> users;
  final String username;
  final int shareableId;
  final Shareable shareable;

  @override
  State<ShareableUsers> createState() => _ShareableUsersState();
}

class _ShareableUsersState extends State<ShareableUsers> {
  late final List<bool> _selected;
  bool _isSharing = false;

  Future<void> _share() async {
    setState(() {
      _isSharing = true;
    });
    final chatApi = ChatAPI();

    bool _sharedAnyPost = false;
    for (var i = 0; i < widget.users.length; i++) {
      if (_selected[i]) {
        final room = await chatApi.getRoom(widget.users[i].id, context, () { });
        await chatApi.startSocket();
        if (widget.shareable == Shareable.post)
          chatApi.createMessage(
              MessageCreateData(
                  type: MessageType.Post,
                  room: room.data.id,
                  post: widget.shareableId),
              context);
        else
          chatApi.createMessage(
              MessageCreateData(
                  type: MessageType.Community,
                  room: room.data.id,
                  community: widget.shareableId),
              context);
        _sharedAnyPost = true;
      }
    }
    setState(() {
      _isSharing = false;
    });
    if (_sharedAnyPost) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: widget.shareable == Shareable.post
            ? Text("Post sent successfully!")
            : Text("Community sent successfully!"),
        backgroundColor: Colors.green,
      ));
    }
  }

  Widget _shareable(ChatSharableData data, int index) {
    return Container(
      decoration: BoxDecoration(
        border: _selected[index]
            ? Border(
                right: BorderSide(color: const Color(0xFF733CE6), width: 4))
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          setState(() {
            _selected[index] = !_selected[index];
          });
        },
        child: Row(
          children: [
            Container(
              //padding: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: _selected[index]
                      ? Border.all(color: const Color(0xFF733CE6))
                      : null),
              padding: const EdgeInsets.all(1),
              child: SylvestImageProvider(
                url: data.image,),
            ),
            const SizedBox(
              width: 10,
            ),
            Text(
              data.title,
              style: TextStyle(
                  color: _selected[index]
                      ? const Color(0xFF733CE6)
                      : Colors.black),
            )
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _selected = List.generate(widget.users.length, (index) => false);
  }

  @override
  Widget build(BuildContext context) {
    int _count = 0;
    return Column(
      children: [
        if (_selected.contains(true))
          ElevatedButton(
            onPressed: _share,
            child: _isSharing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text("Share Post"),
            style: ElevatedButton.styleFrom(
                primary: const Color(0xFF733CE6),
                fixedSize: Size(double.maxFinite, 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30))),
          ),
        ...widget.users.map<Widget>((data) {
          return _shareable(data, _count++);
        }),
      ],
    );
  }
}

enum Shareable { post, community }

class ShareOptionsModal extends StatefulWidget {
  const ShareOptionsModal(
      {Key? key,
      required this.userName,
      required this.shareableId,
      required this.shareable})
      : super(key: key);
  final String userName;
  final int shareableId;
  final Shareable shareable;

  @override
  State<ShareOptionsModal> createState() => _ShareOptionsModalState();
}

class _ShareOptionsModalState extends State<ShareOptionsModal> {
  List<ChatSharableData> _shareableUsers = [];
  bool _showLinkCopiedIndicator = false;
  bool _loading = false;

  Future<void> _getUsers() async {
    if (mounted)
      setState(() {
        _loading = true;
      });
    final users = await API().getRecommendedChatRooms(context);
    if (mounted)
      setState(() {
        _shareableUsers = users;
        _loading = false;
      });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _getUsers();
    });
  }

  Widget _option(String title, Icon icon, Future<void> Function() onPress) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        margin: const EdgeInsets.all(10),
        child: Row(
        children: [
          icon,
          const SizedBox(
            width: 10,
          ),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold),),
          Spacer(),
          if (_showLinkCopiedIndicator) Icon(LineIcons.check)
        ],
      ),
      ),
    );
  }

  Widget _sharableUsers(context) {
    return _loading
        ? LoadingIndicator()
        : _shareableUsers.isEmpty
            ? SizedBox()
            : ShareableUsers(
                shareable: widget.shareable,
                users: _shareableUsers,
                username: widget.userName,
                shareableId: widget.shareableId,
              );
  }

  Future<String?> _getLink(context) async {
    final prefix =
        widget.shareable == Shareable.post ? "masterposts" : "communities";
    final url = Env.BASE_URL_PREFIX + "/$prefix/${widget.shareableId}/link";

    final response = await API().getResponseItems(context, url);
    return response['link'];
  }

  @override
  Widget build(context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15),
      controller: ModalScrollController.of(context),
      child: Column(
        children: [
          Text('Share',
              style: TextStyle(fontFamily: 'Quicksand', fontSize: 18)),
          _option('Share URL', const Icon(LineIcons.link, size: 30, color: const Color(0xFF733CE6),), () async {
            Clipboard.setData(ClipboardData(text: await _getLink(context)));
            setState(() {
              _showLinkCopiedIndicator = true;
            });
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Link coppied!')));
            await Future.delayed(Duration(seconds: 2), () {
              if (mounted)
                setState(() {
                  _showLinkCopiedIndicator = false;
                });
            });
          }),
          _sharableUsers(context),
          const SizedBox(
            height: 10,
          )
        ],
      ),
    );
  }
}

class CreateTextModal extends StatefulWidget {
  final String hint;
  final String title;
  final String publishText;
  final String initialText;
  final dynamic Function(BuildContext context, String text) onPublish;

  const CreateTextModal(
      {Key? key,
      required this.hint,
      required this.title,
      required this.publishText,
      this.initialText = "",
      required this.onPublish})
      : super(key: key);

  @override
  State<CreateTextModal> createState() => _CreateTextModalState();
}

class _CreateTextModalState extends State<CreateTextModal> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.text = widget.initialText;
  }

  Widget _field(context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
      child: TextFormField(
        controller: _textController,
        onChanged: (text) => setState(() {}),
        decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.all(10),
            hintText: widget.hint,
            border: InputBorder.none),
        minLines: 1,
        keyboardType: TextInputType.multiline,
        maxLines: null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Align(
        alignment: Alignment.center,
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.title,
                  style: TextStyle(fontFamily: 'Quicksand', fontSize: 18)),
              const SizedBox(
                height: 10,
              ),
              _field(context),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        primary: Colors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Row(
                        children: [
                          Icon(LineIcons.times),
                          SizedBox(
                            width: 10,
                          ),
                          Text("Cancel"),
                        ],
                      )),
                  if (_textController.text.isNotEmpty)
                    SizedBox(
                      width: 10,
                    ),
                  if (_textController.text.isNotEmpty)
                    OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          primary: const Color(0xFF733CE6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () async => await widget.onPublish(
                            context, _textController.text),
                        child: Row(
                          children: [
                            Icon(LineIcons.share),
                            SizedBox(
                              width: 10,
                            ),
                            Text(widget.publishText),
                          ],
                        )),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class CommentFieldModal extends StatefulWidget {
  final int postId;
  final int? relatedCommentId;

  final void Function() onPostRefresh;

  CommentFieldModal(
      {required this.postId,
      required this.relatedCommentId,
      required this.onPostRefresh});

  @override
  State<CommentFieldModal> createState() => CommentFieldModalState();
}

class CommentFieldModalState extends State<CommentFieldModal> {
  Future<void> _publish(context, text) async {
    Map comment = {
      'content': {
        'contentItems': [
          {
            'paragraphs': [text]
          }
        ]
      },
      'post': widget.postId,
      'related_comment': widget.relatedCommentId
    };

    if (text.isNotEmpty) {
      print(comment);
      await API().publishComment(comment, widget.postId, context);
      widget.onPostRefresh();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Comment can not be empty!')));
    }
  }

  @override
  Widget build(context) {
    return CreateTextModal(
        hint: 'Share your thoughts',
        title: "Comment",
        publishText: "Publish Comment",
        onPublish: _publish);
  }
}
