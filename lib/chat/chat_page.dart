import 'dart:convert';
import 'dart:io';

import 'package:expandable/expandable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:open_file/open_file.dart';
import 'package:sylvest_flutter/_extra_libs/chat_library/chat_types/flutter_chat_types.dart'
    as messageTypes;

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import 'package:flowder/flowder.dart';
import 'package:sylvest_flutter/chat/chat_api.dart';
import 'package:sylvest_flutter/_extra_libs/chat_library/chat_ui/flutter_chat_ui.dart';
import 'package:sylvest_flutter/chat/chat_util.dart';
import 'package:sylvest_flutter/chat/chat_rooms_page.dart';
import 'package:sylvest_flutter/services/pick_image_service.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:sylvest_flutter/modals/modals.dart';
import 'package:sylvest_flutter/notifications/notifications_service.dart';
import 'package:sylvest_flutter/services/mangers.dart';
import 'package:sylvest_flutter/subjects/user/user_page.dart';
import 'package:path_provider/path_provider.dart';

import '../services/image_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key, required this.roomData, required this.refresh}) : super(key: key);

  final RoomData roomData;
  final void Function() refresh;

  @override
  _ChatPageState createState() {
    return _ChatPageState();
  }
}

class _ChatPageState extends State<ChatPage> {
  List<messageTypes.Message> _messages = [];
  final _api = ChatAPI();
  final _manager = MessageQueryManager();
  bool _loading = false;
  int _lastId = -1;

  Future<void> _getSavedMessages() async {
    if (_loading) return;
    setState(() {
      _loading = true;
    });

    final newMessages =
        await _manager.getSavedMessages(widget.roomData.id, context);
    setState(() {
      //_messages.addAll(newMessages);
      newMessages.forEach((message) {
        if (_messages.where((element) => element.id == message.id).isEmpty) {
          _messages.add(message);
        }
      });
    });

    setState(() {
      _loading = false;
    });
  }

  late final _user = messageTypes.User(id: _api.username!);
  final _materialColor = const Color(0xFF733CE6);

  @override
  void initState() {
    super.initState();
    _loadMessages();
    PushNotificationsService().chatRoomName = widget.roomData.roomDetails.title;
  }

  void addMessage(messageTypes.Message message) {
    _messages.insert(0, message);
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
                color: _materialColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: SizedBox(
              height: 144,
              child: Column(
                //crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleImageSelection();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.photo_library_outlined, color: Colors.white),
                        SizedBox(width: 10),
                        Text('Photo',
                            style: TextStyle(
                                color: Colors.white, fontFamily: 'Quicksand'))
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleFileSelection();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.file_present_outlined, color: Colors.white),
                        SizedBox(width: 10),
                        Text('File',
                            style: TextStyle(
                                color: Colors.white, fontFamily: 'Quicksand'))
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.close, color: Colors.white),
                        SizedBox(width: 10),
                        Text('Cancel',
                            style: TextStyle(
                                color: Colors.white, fontFamily: 'Quicksand'))
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.any, withData: true, allowMultiple: false);

    if (result != null && result.files.single.path != null) {
      final bytes = result.files.single.bytes;
      final base64 = base64Encode(bytes!);
      final extension = p.extension(result.files.single.path!);

      _api.createMessage(
          MessageCreateData(
              room: widget.roomData.id,
              type: MessageType.File,
              file: {'file': base64, 'extension': extension}),
          context);
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final base64 = base64Encode(bytes);

      _api.createMessage(
          MessageCreateData(
              type: MessageType.Image, room: widget.roomData.id, image: base64),
          context);
    }
  }

  Future<String> _getDownloadPath() async {
    Directory? directory;
    directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  void _handleMessageTap(messageTypes.Message message) async {
    if (message is messageTypes.FileMessage) {
      final pathToStore = await _getDownloadPath();
      await Flowder.download(
          message.uri,
          DownloaderUtils(
              progress: ProgressImplementation(),
              file: File('$pathToStore/${message.fileName}'),
              onDone: () => print('Download done'),
              progressCallback: (current, total) {
                final progress = (current / total) * 100;
                print('Downloading: $progress');
              }));
      final file = File('$pathToStore/${message.fileName}');
      await OpenFile.open(file.path);
    }
  }

  void _handlePreviewDataFetched(
    messageTypes.TextMessage message,
    messageTypes.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = _messages[index].copyWith(previewData: previewData);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages[index] = updatedMessage;
      });
    });
  }

  void _handleSendPressed(messageTypes.PartialText message) async {
    _api.createMessage(
        MessageCreateData(
            type: MessageType.Text,
            room: widget.roomData.id,
            content: message.text),
        context);
  }

  void _loadMessages() async {
    // await _api.startSocket();
    // widget.api.readMessagesCommand(widget.room);
  }

  @override
  void dispose() {
    //widget.api.closeChannel();
    super.dispose();
  }

  void _handleNewData(Map data) {
    print("data: $data");
    final command = data['command'];
    final content = data['content'];
    if (content == null || command == null) return;
    if (content['room_id'] != widget.roomData.id &&
        content['room'] != widget.roomData.id) return;

    print(data);
    switch (command) {
      case 'new_message':
        final message = _api.fromNewMessage(content);
        if (message.id == _lastId.toString()) return;
        addMessage(message);
        _lastId = int.parse(message.id);
        _api.messageAction(int.parse(message.id), MessageAction.Read, context);
        break;
      case 'message_seen':
        final seenId = content['message_id'];
        _api.onMessageSeen(seenId, _messages);
        break;
      case 'message_saved':
        final savedId = content['message_id'];
        _api.onMessageSaved(savedId, _messages);
        break;
    }
  }

  void _handleLongPress(messageTypes.Message message) {
    _api.messageAction(int.parse(message.id), MessageAction.Save, context);
  }

  Widget chat() {
    return FutureBuilder<List<messageTypes.Message>>(
        future: _api.getMessages(context, room: widget.roomData.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return LoadingIndicator();
          }
          if (_messages.isEmpty) {
            _messages = snapshot.data!;
          }
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
                  final data = json.decode(snapshot.data as String);
                  _handleNewData(data);
                }
              }

              return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.pixels >
                        notification.metrics.maxScrollExtent + 50) {
                      //_onRefresh();
                      _getSavedMessages();
                    }
                    return false;
                  },
                  child: Chat(
                    dateLocale: 'en_US',
                    messages: _messages,
                    onAttachmentPressed: _handleAttachmentPressed,
                    onMessageTap: _handleMessageTap,
                    onPreviewDataFetched: _handlePreviewDataFetched,
                    onSendPressed: _handleSendPressed,
                    onMessageLongPress: _handleLongPress,
                    user: _user,
                    theme: DefaultChatTheme(
                        inputBackgroundColor: const Color(0xFF733CE6),
                        backgroundColor: Colors.transparent,
                        body1: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.375),
                        body2: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.428),
                        caption: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.333),
                        subtitle1: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.375),
                        subtitle2: const TextStyle(
                            fontFamily: 'Quicksand',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            height: 1.333),
                        subtitle2Color: _materialColor),
                  ));
            },
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              Scaffold.of(context).openEndDrawer();
            },
            child: Row(
              children: [
                SylvestImageProvider(
                  url: widget.roomData.roomDetails.image,),
                SizedBox(width: 10),
                Text(
                  widget.roomData.roomDetails.title,
                  style:
                      TextStyle(color: _materialColor, fontFamily: 'Quicksand'),
                )
              ],
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_left, color: _materialColor),
          onPressed: () {
            Navigator.pop(context);
            PushNotificationsService().chatRoomName = null;
          },
        ),
        actions: [
          Builder(
              builder: (context) => IconButton(
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                  icon: Icon(
                    Icons.more_horiz,
                    color: _materialColor,
                  )))
        ],
      ),
      endDrawer: FutureBuilder<List<RoomParticipantData>>(
        future: _api.roomParticipants(widget.roomData.id, context),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }
          final data = snapshot.data!;
          return ChatDrawer(
            participants: data,
            roomData: widget.roomData,
            refresh:  widget.refresh,
          );
        },
      ),
      body: SafeArea(
          bottom: false,
          child: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                    Color.fromARGB(255, 235, 233, 233),
                    Color.fromARGB(255, 235, 233, 233)
                  ])),
              child: chat())),
    );
  }
}

class ChatDrawer extends StatefulWidget {
  final RoomData roomData;
  final List<RoomParticipantData> participants;
  final void Function() refresh;

  const ChatDrawer({Key? key, required this.roomData, required this.participants, required this.refresh})
      : super(key: key);

  State<ChatDrawer> createState() => ChatDrawerState();
}

class ChatDrawerState extends State<ChatDrawer> {
  final _api = ChatAPI();
  final _imageService = ImageService();
  bool _collecting = false;

  Widget _description() {
    if (widget.roomData.type == RoomType.PeerToPeer) return SizedBox();
    return GestureDetector(
      onTap: () {
        if (!widget.roomData.allowedActions.contains(RoomAction.Edit)) return;
        showDialog(
            context: context,
            builder: (context) => CreateTextModal(
                hint: 'New Description',
                title: 'Room Description',
                initialText: widget.roomData.description,
                publishText: 'Update Description',
                onPublish: _updateDescription));
      },
      child: Container(
          margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Description",
                  style: TextStyle(fontSize: 17, fontFamily: 'Quicksand'),
                ),
                Divider(),
                if (widget.roomData.description.isNotEmpty)
                  Text(widget.roomData.description)
                else
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      "No description was provided",
                      style: TextStyle(color: Colors.grey.shade400),
                      textAlign: TextAlign.center,
                    ),
                  )
              ])),
    );
  }

  Widget _streakIndicator(int multiplier) {
    return Container(
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: const Color(0xffe1d8f5),
                  blurRadius: 5,
                  spreadRadius: 1)
            ],
            color: const Color(0xFF8d61ea)),
        padding: const EdgeInsets.all(10),
        child: Center(
          child: RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: 'x',
                  style: TextStyle(fontSize: 12, color: Colors.white)),
              TextSpan(
                  text: multiplier.toString(),
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Quicksand',
                      fontSize: 25))
            ]),
          ),
        ));
  }

  Future<void> _collectReward() async {
    setState(() {
      _collecting = true;
    });
    final room = await _api.collectXpFromRoom(widget.roomData.id, context, widget.refresh);
    setState(() {
      _collecting = false;
    });
    Navigator.pop(context);
    Navigator.pop(context);
    room.getChat(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Reward was successfully added to your wallet!")));
  }

  Widget _streak() {
    return Expanded(
      child: Container(
          margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Streak",
                style: TextStyle(fontSize: 17, fontFamily: 'Quicksand'),
              ),
              Divider(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                        onPressed:
                            widget.roomData.streakDetails.collectedXp == 0 ||
                                    _collecting
                                ? null
                                : () async => await _collectReward(),
                        style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30))),
                        child: _collecting
                            ? LoadingIndicator(
                                size: 20,
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LineIcons.wallet),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Text("Collect Reward: "
                                      "${widget.roomData.streakDetails.collectedXp}xp")
                                ],
                              )),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  _streakIndicator(widget.roomData.streakDetails.multiplier)
                ],
              )
            ],
          )),
    );
  }

  Widget _participant(String title, String? image, int id, bool isAdmin) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SylvestImageProvider(
           url: image,),
          const SizedBox(width: 10),
          Expanded(
              child:
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold))),
          if (isAdmin) Text('Admin', style: TextStyle(color: Colors.black54))
        ],
      ),
    );
  }

  Widget _participantWithOptions(RoomParticipantData participant, int index) {
    final _controller = ExpandableController();
    return ExpandablePanel(
        theme: ExpandableThemeData(hasIcon: false),
        controller: _controller,
        header: _participant(participant.username, participant.profileImage,
            participant.id, participant.isAdmin),
        collapsed: SizedBox(),
        expanded: _options(participant.id, index));
  }

  Widget _options(int userId, int index) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Divider(),
          _option("Profile", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => UserPage(userId)));
          }),
          if (widget.roomData.allowedActions.contains(RoomAction.Remove))
            _option("Remove", () async {
              await _api.roomActions(
                  RoomActionData(
                      action: RoomAction.Remove,
                      newUser: null,
                      removedUser: userId),
                  widget.roomData.id,
                  context, widget.refresh);
              _onRefresh(widget.roomData.roomDetails.title);
            })
        ],
      ),
    );
  }

  Widget _option(String action, void Function() onTap) {
    Map<String, IconData> _icons = {
      'Profile': Icons.person,
      'Remove': Icons.remove,
    };

    return InkWell(
      onTap: () {
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(5),
        child: Row(
          children: [
            Icon(_icons[action], color: const Color(0xFF733CE6)),
            const SizedBox(width: 10),
            Text(action)
          ],
        ),
      ),
    );
  }

  Future<void> _updateImage() async {
    final image = await _imageService.getImage(context);
    if (image == null) return;
    final room = await _api.updateRoom(
        widget.roomData.id,
        RoomUpdateData(
            image: base64Encode(await File(image.path).readAsBytes())),
        context, widget.refresh);
    Navigator.pop(context);
    Navigator.pop(context);
    room.getChat(context);
  }

  Future<void> _updateTitle(context, String newTitle) async {
    final room = await _api.updateRoom(
        widget.roomData.id, RoomUpdateData(title: newTitle), context, widget.refresh);
    Navigator.pop(context);
    Navigator.pop(context);
    Navigator.pop(context);
    room.getChat(context);
  }

  Future<void> _updateDescription(context, String newDescription) async {
    final room = await _api.updateRoom(widget.roomData.id,
        RoomUpdateData(description: newDescription), context, widget.refresh);
    Navigator.pop(context);
    Navigator.pop(context);
    Navigator.pop(context);
    room.getChat(context);
  }

  Widget _chatGeneralInfo() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: !widget.roomData.allowedActions.contains(RoomAction.Edit)
                ? null
                : () async => await _updateImage(),
            borderRadius: BorderRadius.circular(100),
            child: CircleAvatar(
              foregroundImage: widget.roomData.roomDetails.image == null
                  ? null
                  : NetworkImage(widget.roomData.roomDetails.image!),
              backgroundImage: AssetImage("assets/images/defaultP.png"),
              child: Icon(
                LineIcons.camera,
                color: Colors.white54,
                size: 30,
              ),
              radius: 40,
              backgroundColor: Colors.black12,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              if (!widget.roomData.allowedActions.contains(RoomAction.Edit))
                return;
              showDialog(
                  context: context,
                  builder: (context) {
                    return CreateTextModal(
                        hint: "New Title",
                        title: "Change Room Title",
                        initialText: widget.roomData.roomDetails.title,
                        publishText: "Change Title",
                        onPublish: _updateTitle);
                  });
            },
            child: Flexible(
                child: Text(widget.roomData.roomDetails.title,
                    overflow: TextOverflow.fade,
                    textScaleFactor: 2.5,
                    style: TextStyle(
                        color: const Color(0xFF733CE6),
                        fontFamily: 'Quicksand'))),
          ),
        ],
      ),
    );
  }

  Widget _chatParticipants(context) {
    int _index = 0;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
                Text(
                  "Participants",
                  style: TextStyle(fontSize: 17, fontFamily: 'Quicksand'),
                ),
                Divider(),
              ] +
              widget.participants.map<Widget>((participant) {
                print(participant);
                return _participantWithOptions(participant, _index++);
              }).toList()),
    );
  }

  void _onRefresh(target) {
    Navigator.pop(context);
    Navigator.pop(context);
    Navigator.pop(context);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ChatsPage(
                  target: target,
                  setPage: null,
                )));
  }

  Widget _chatActions() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          if (widget.roomData.allowedActions.contains(RoomAction.Add))
            ElevatedButton(
              onPressed: () async {
                // final users = await API().getRecommendedUsers(context);
                final selectedUser = await showMaterialModalBottomSheet(
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(30))),
                    context: context,
                    builder: (context) {
                      return UserListModal(
                        title: 'Add User',
                        id: null,
                        type: UserManagerType.Following,
                        behaviour: UserListBehaviour.Pop,
                      );
                    });
                if (selectedUser != null) {
                  await _api.roomActions(
                      RoomActionData(
                          action: RoomAction.Add,
                          newUser: selectedUser,
                          removedUser: null),
                      widget.roomData.id,
                      context, widget.refresh);
                  _onRefresh(widget.roomData.roomDetails.title);
                }
              },
              child: Text("Add User"),
              style: ElevatedButton.styleFrom(
                  primary: const Color(0xFF733CE6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  fixedSize: Size(double.maxFinite, 25)),
            ),
          if (widget.roomData.allowedActions.contains(RoomAction.Leave))
            OutlinedButton(
              onPressed: () async {
                await _api.roomActions(
                    RoomActionData(
                        action: RoomAction.Leave,
                        newUser: null,
                        removedUser: null),
                    widget.roomData.id,
                    context, widget.refresh);
                ;
                _onRefresh(null);
              },
              child: Text("Leave Group"),
              style: OutlinedButton.styleFrom(
                  primary: const Color(0xFF733CE6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  fixedSize: Size(double.maxFinite, 25)),
            )
        ],
      ),
    );
  }

  @override
  Widget build(context) {
    return Drawer(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(30))),
      child: ListView(
        children: [
          _chatGeneralInfo(),
          _description(),
          _streak(),
          _chatActions(),

          _chatParticipants(context),
        ],
      ),
    );
  }
}
