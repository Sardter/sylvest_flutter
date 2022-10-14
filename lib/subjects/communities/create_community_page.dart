import 'dart:convert';
import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_icons/line_icons.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:sylvest_flutter/services/pick_image_service.dart';
import 'package:sylvest_flutter/services/mangers.dart';
import 'package:sylvest_flutter/subjects/communities/communities.dart';
import 'package:sylvest_flutter/post_builder/post_builder_components.dart';
import 'package:sylvest_flutter/subjects/subject_util.dart';

import '../../post_builder/post_builder_util.dart';

class CreateCommunityPage extends StatefulWidget {
  final Color backgroundColor = Colors.white,
      matterialColor = const Color(0xFF733CE6),
      secondaryColor = Colors.black;
  final Community? communityCard;
  final void Function() backToLastPage;

  CreateCommunityPage(
      {required this.communityCard, required this.backToLastPage});

  @override
  State<CreateCommunityPage> createState() => CreateCommunityPageState();
}

class CreateCommunityPageState extends State<CreateCommunityPage> {
  late final _settingsController = CommunitySettingsController(communities: []);
  bool _publishing = false;

  bool validate(Map community) {
    List<String> errors = [];
    if ((community['title'] as String).isEmpty) {
      errors.add('Title cannot be empty!');
    }
    if ((community['short_description'] as String).isEmpty) {
      errors.add('Short description cannot be empty!');
    }
    if ((community['about'] as String).isEmpty) {
      errors.add('bio cannot be empty!');
    }
    if (community['image'] == null) {
      errors.add('An image must be selected!');
    }
    if (community['banner'] == null) {
      errors.add('A banner must be selected!');
    }
    String message = '';
    errors.forEach((element) {
      message += '$element\n';
    });
    if (errors.isNotEmpty) {
      Flushbar(
        flushbarStyle: FlushbarStyle.GROUNDED,
        isDismissible: true,
        backgroundColor: Colors.red,
        messageText: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        icon: const Icon(Icons.info),
      ).show(context);
      return false;
    }
    return true;
  }

  void onPublish() async {
    setState(() {
      _publishing = true;
    });
    final Map community = {
      "info": null,
    };
    community.addAll(await communityMainCard.getData());
    if (_settingsController.data != null)
      community.addAll(_settingsController.data!);

    if (validate(community)) {
      final response = await API().createCommunity(community, context);
      print(response);
      if (response['id'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Community published successfully!'),
        ));
        await Navigator.push(context,
            MaterialPageRoute<void>(builder: (BuildContext context) {
          return CommunityPage(id: response['id']);
        }));
        widget.backToLastPage();
      } else {
        (response as Map).forEach((key, value) {
          value.forEach((error) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.red,
              content: Text('Error: $error'),
            ));
          });
        });

      }
    }
    setState(() {
      _publishing = false;
    });
  }

  Widget publishButton() {
    return Padding(
        padding: const EdgeInsets.all(5),
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                primary: const Color(0xFF733CE6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            onPressed: _publishing ? null : () => onPublish(),
            child: _publishing
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Create Community',
                    style: TextStyle(color: Colors.white),
                  )));
  }

  late final CommunityMainCard communityMainCard =
      CommunityMainCard(widget.communityCard);

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.keyboard_arrow_left,
            color: widget.matterialColor,
          ),
          onPressed: () {
            widget.backToLastPage();
          },
        ),
        backgroundColor: widget.backgroundColor,
        centerTitle: true,
        title: Text('Create Community',
            style: TextStyle(
              color: widget.matterialColor,
              fontFamily: 'Quicksand',
            )),
      ),
      body: ListView(
        physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(5),
        children: [
          communityMainCard,
          CommunitySettings(
            controller: _settingsController,
            backToLastPage: widget.backToLastPage,
          ),
          publishButton()
        ],
      ),
    );
  }
}

class CommunityMainCard extends StatefulWidget {
  final Community? communityCard;
  CommunityMainCard(this.communityCard);

  final discriptionController = TextEditingController();
  final bioController = TextEditingController();

  Future<Map> getData() async {
    print(discriptionController.text);
    Map data = {
      "short_description": discriptionController.text,
      "about": bioController.text,
      "image": await getImageFile(),
    };
    data.addAll(await communityTitle.getData());
    return data;
  }

  XFile? imagefile;

  late final communityTitle = CommunityNameAndBannerUpdateable(null, null);

  Future<String?> getImageFile() async {
    if (imagefile == null) return null;
    final compressed = await FlutterImageCompress.compressWithFile(
        imagefile!.path,
        quality: 85,
        minWidth: 300,
        minHeight: 300);
    return imagefile == null || compressed == null
        ? null
        : base64Encode(compressed);
  }

  @override
  State<CommunityMainCard> createState() => CommunityMainCardState();
}

class CommunityMainCardState extends State<CommunityMainCard> {
  late ImageProvider profileImage = widget.communityCard == null
      ? const AssetImage('assets/images/defaultP.png')
      : NetworkImage(widget.communityCard!.data.image!) as ImageProvider;

  final _service = ImageService();

  @override
  Widget build(context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2)
          ]),
      margin: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /* if (widget.communityCard != null)
            CommunityNameAndBannerUpdateable(
                widget.communityCard!.title, widget.communityCard!.banner)
          else
            CommunityNameAndBannerUpdateable(null, null), */
          widget.communityTitle,
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () async {
                    final image = await _service.getImage(context);
                    if (image != null) {
                      setState(() {
                        widget.imagefile = image;
                        profileImage = FileImage(File(image.path));
                      });
                    }
                  },
                  child: SizedBox(
                    height: 80,
                    child: Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: profileImage,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle),
                            ),
                            const Text(
                              "Update Image",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white60),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Align(
                    alignment: Alignment.center,
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(5)),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      child: TextFormField(
                          controller: widget.discriptionController,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 3),
                              isDense: true,
                              hintText: 'Community Short Description'),
                          style: const TextStyle(
                              fontFamily: 'Quicksand', fontSize: 15)),
                    )),
                const SizedBox(
                  height: 7.5,
                ),
                const SizedBox(
                  height: 7.5,
                ),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(5)),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextFormField(
                      controller: widget.bioController,
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                          isDense: true,
                          hintText: 'Bio'),
                      maxLines: null,
                      minLines: 1),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class CommunityNameAndBannerUpdateable extends StatefulWidget {
  final String? title, banner;
  CommunityNameAndBannerUpdateable(this.banner, this.title);
  final titleController = TextEditingController();

  Future<Map> getData() async {
    return {"title": titleController.text, "banner": await getBannerFile()};
  }

  XFile? bannerfile;
  Future<String?> getBannerFile() async {
    if (bannerfile == null) return null;
    final compressed = await FlutterImageCompress.compressWithFile(
        bannerfile!.path,
        quality: 85,
        minWidth: 300,
        minHeight: 300);
    return bannerfile == null || compressed == null
        ? null
        : base64Encode(compressed);
  }

  @override
  State<CommunityNameAndBannerUpdateable> createState() =>
      CommunityNameAndBannerUpdateableState();
}

class CommunityNameAndBannerUpdateableState
    extends State<CommunityNameAndBannerUpdateable> {
  late Image bannerImage = widget.banner != null
      ? Image.network(widget.banner!,
          height: 120, width: double.infinity, fit: BoxFit.cover)
      : Image.asset('assets/images/defaultB.jpg',
          height: 120, width: double.infinity, fit: BoxFit.cover);

  final _service = ImageService();

  @override
  Widget build(context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            child: bannerImage),
        GestureDetector(
          onTap: () async {
            final image = await _service.getImage(context);
            if (image != null) {
              setState(() {
                widget.bannerfile = image;
                bannerImage = Image.file(
                  File(image.path),
                  height: 120,
                  width: double.maxFinite,
                  fit: BoxFit.cover,
                );
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.vertical(top: Radius.circular(10))),
            height: 120,
            width: double.infinity,
            alignment: Alignment.center,
            child: const Text(
              "Update Banner",
              style: TextStyle(color: Colors.white54, fontSize: 20),
            ),
          ),
        ),
        Positioned(
            bottom: 5,
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.grey.shade500.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(5)),
              width: 200,
              child: TextFormField(
                  controller: widget.titleController,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      hintText: 'Community Title',
                      hintStyle: TextStyle(color: Colors.white38)),
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Quicksand',
                      fontSize: 20)),
            )),
      ],
    );
  }
}

class CommunitySettingsController {
  List<ProfileCommunity> communities;
  ProfileCommunity? selectedCommunity;

  Map? get data => selectedCommunity == null
      ? null
      : {"master_community": selectedCommunity!.id};

  CommunitySettingsController({required this.communities});
}

class CommunitySettings extends StatefulWidget {
  final CommunitySettingsController controller;
  final void Function() backToLastPage;

  const CommunitySettings(
      {required this.controller, required this.backToLastPage});

  @override
  State<CommunitySettings> createState() => CommunitySettingsState();
}

class CommunitySettingsState extends State<CommunitySettings> {
  List<ProfileCommunity> _communities = [];
  bool _loading = false;

  Future<void> _getCommunities() async {
    if (await API().getLoginCred() == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You must login to create a new community")));
      widget.backToLastPage();
      return;
    }
    setState(() {
      _loading = true;
    });
    final communities =
        await SmallCommunityManager().getCommunities(context, null, true);
    setState(() {
      _communities = communities;
      widget.controller.communities = _communities;
      _masterCommunityController = DropDownController(
          index: 0,
          options: <DropDownData>[
                DropDownData(
                    title: "None", id: 0, value: null, iconData: LineIcons.ban)
              ] +
              widget.controller.communities
                  .map<DropDownData>((community) => DropDownData(
                      title: community.title,
                      id: community.id,
                      value: community,
                      image: community.image,
                      extra: community.master))
                  .toList(),
          onOptionSelected: (community) => setState(() {
                widget.controller.selectedCommunity =
                    community.value == null ? null : community.value;
              }));
      _loading = false;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _getCommunities();
    });
    super.initState();
  }

  late DropDownController _masterCommunityController = DropDownController(
      index: 0,
      options: <DropDownData>[
            DropDownData(
                title: "None", id: 0, value: null, iconData: LineIcons.ban)
          ] +
          widget.controller.communities
              .map<DropDownData>((community) => DropDownData(
                  title: community.title,
                  id: community.id,
                  value: community,
                  image: community.image,
                  extra: community.master))
              .toList(),
      onOptionSelected: (community) => setState(() {
            widget.controller.selectedCommunity =
                community.value == null ? null : community.value;
          }));

  @override
  Widget build(context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2)
          ]),
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.all(5),
      child: _loading
          ? SizedBox(
              height: 50,
              child: LoadingIndicator(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Master community: "),
                DropDown(controller: _masterCommunityController)
              ],
            ),
    );
  }
}
