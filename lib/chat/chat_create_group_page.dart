import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:sylvest_flutter/chat/chat_api.dart';
import 'package:sylvest_flutter/chat/chat_util.dart';

import '../services/image_service.dart';
import '../services/mangers.dart';

class CreateGroupPage extends StatelessWidget {
  final materialColor = const Color(0xFF733CE6);
  final backgroundColor = Colors.white;

  final void Function() refresh;

  final infoField = GroupInfoField();
  final usersField = GroupUsersField();

  CreateGroupPage({Key? key, required this.refresh}) : super(key: key);

  _onCreate(context) async {
    final data = infoField.getData();
    data.addAll(usersField.getData());
    print(data);
    final room = await ChatAPI().getOrCreateGroup(
        CreateRoomData(
            title: data['title'],
            community_id: null,
            imageData: data['image'],
            participants: data['participants']),
        context, refresh);
    Navigator.pop(context);
    //Navigator.pop(context);
    room.getChat(context);
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.keyboard_arrow_left,
            color: materialColor,
          ),
        ),
        backgroundColor: backgroundColor,
        centerTitle: true,
        title: Text('Create Group',
            style: TextStyle(
              color: materialColor,
              fontFamily: 'Quicksand',
            )),
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [infoField, usersField],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () => _onCreate(context),
        child: Icon(
          Icons.check,
          color: materialColor,
        ),
      ),
    );
  }
}

class GroupInfoField extends StatefulWidget {
  GroupInfoField({Key? key}) : super(key: key);
  final titleController = TextEditingController();
  XFile? imageFile;

  @override
  State<GroupInfoField> createState() => _GroupInfoFieldState();

  Map getData() {
    return {
      'title': titleController.text,
      if (imageFile != null)
        'image': base64.encode(File(imageFile!.path).readAsBytesSync())
      else
        'image': null
    };
  }
}

class _GroupInfoFieldState extends State<GroupInfoField> {
  final _picker = ImagePicker();

  Widget _noImage() {
    return Center(
      child: Icon(
        Icons.add_a_photo,
        color: Colors.black38,
      ),
    );
  }

  FileImage _image() {
    return FileImage(File(widget.imageFile!.path));
  }

  Future<XFile?> _pickImage() async {
    return await _picker.pickImage(source: ImageSource.gallery);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2)
          ]),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.black12,
            radius: 30,
            foregroundImage: widget.imageFile != null ? _image() : null,
            child: InkWell(
              onTap: () async {
                XFile? newImage = await _pickImage();
                setState(() {
                  if (newImage != null) widget.imageFile = newImage;
                });
              },
              child: widget.imageFile == null ? _noImage() : null,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
              child: Container(
            decoration: BoxDecoration(
                color: Colors.black12, borderRadius: BorderRadius.circular(10)),
            child: TextFormField(
              controller: widget.titleController,
              decoration: InputDecoration(
                  isCollapsed: true,
                  isDense: true,
                  hintText: 'Group title',
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  border: InputBorder.none),
            ),
          ))
        ],
      ),
    );
  }
}

class GroupUser extends StatelessWidget {
  GroupUser(
      {Key? key,
      required this.username,
      required this.imageUrl,
      required this.id,
      required this.index,
      required this.onAddUser,
      this.removable = false,
      required this.onRemoveUser})
      : super(key: key);
  final String username;
  final String? imageUrl;
  final int id, index;
  final void Function(GroupUser user) onAddUser, onRemoveUser;
  bool removable;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (removable)
          onRemoveUser(this);
        else
          onAddUser(this);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SylvestImageProvider(
              url: imageUrl,
            ),
            const SizedBox(
              width: 10,
            ),
            Text(
              username,
              style: TextStyle(fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }
}

class GroupUsersField extends StatefulWidget {
  GroupUsersField({Key? key}) : super(key: key);
  final particepents = <GroupUser>[];

  @override
  State<GroupUsersField> createState() => _GroupUsersFieldState();

  Map getData() {
    return {'participants': particepents.map((e) => e.id).toList()};
  }
}

class _GroupUsersFieldState extends State<GroupUsersField> {
  final _manager = UserManager(type: UserManagerType.Followers);

  List<GroupUser> _addableUsers = [];
  bool _loading = false;

  Future<void> _getUsers() async {
    setState(() {
      _loading = true;
    });
    final users = await _manager.getUser(context, null);
    setState(() {
      int _index = 0;
      _addableUsers = users.map<GroupUser>((user) {
        return GroupUser(
            username: user.username,
            imageUrl: user.profileImage,
            id: user.id,
            onAddUser: _onAddUser,
            onRemoveUser: _onRemoveUser,
            index: _index++);
      }).toList();
      _loading = false;
    });
  }

  void _onAddUser(GroupUser user) {
    setState(() {
      _addableUsers.remove(user);
      user.removable = true;
      widget.particepents.add(user);
    });
  }

  void _onRemoveUser(GroupUser user) {
    setState(() {
      widget.particepents.remove(user);
      user.removable = false;
      _addableUsers.add(user);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: _loading ? LoadingIndicator() :  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 5, spreadRadius: 2)
                  ]),
              width: double.maxFinite,
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Participants',
                    style: TextStyle(fontFamily: 'Quicksand', fontSize: 20),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  if (widget.particepents.isEmpty)
                    SizedBox(
                      height: 50,
                      child: Center(
                        child: Text(
                          "No users were added",
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ),
                  Wrap(
                    children: widget.particepents,
                  ),
                ],
              )),
          const SizedBox(
            height: 10,
          ),
          Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 5, spreadRadius: 2)
                  ]),
              padding: const EdgeInsets.all(10),
              child: Column(
                children: _addableUsers.isNotEmpty
                    ? _addableUsers
                    : [
                        SizedBox(
                          height: 50,
                          child: Center(
                            child: Text(
                              "No users to add",
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        )
                      ],
              )),
        ],
      ),
    );
  }
}
