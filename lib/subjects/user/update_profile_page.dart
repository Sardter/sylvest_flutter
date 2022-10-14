import 'dart:convert';
import 'dart:io';

import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_icons/line_icons.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:sylvest_flutter/services/pick_image_service.dart';
import 'package:sylvest_flutter/subjects/subject_util.dart';

class ProfileUpdatePage extends StatefulWidget {
  final ProfileData data;
  final void Function(int page) setPage;
  ProfileUpdatePage({required this.data, required this.setPage});

  @override
  State<ProfileUpdatePage> createState() => ProfileUpdatePageState();
}

class ProfileUpdatePageState extends State<ProfileUpdatePage> {
  List<DragAndDropListWithId> contents = [];
  late Interests interestsWidget = Interests(widget.data.interests);

  late UpdateableProfileCard updatedProfileCard =
      UpdateableProfileCard(widget.data);

  late UpdatableInformationCard informationCard = UpdatableInformationCard(
    info: widget.data.info,
    interests: widget.data.interests,
    interestsWidget: interestsWidget,
    contents: contents,
  );

  late PrivacySettings privacyWidget =
      PrivacySettings(isPrivate: widget.data.generalAttributes.isPrivate);

  late ProfileSettingsCard profileSettingsCard = ProfileSettingsCard(
    privacyWidget: privacyWidget,
  );

  Color backgroundColor = Colors.white,
      matterialColor = const Color(0xFF733CE6),
      secondaryColor = Colors.black;

  bool _updating = false;

  void _displayError(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(errorMessage),
      backgroundColor: Colors.red,
    ));
  }

  bool _verifyFields(Map fields) {
    if (fields["about"].length > 500) {
      _displayError("About cannot be longer than 500 characters");
      return false;
    }
    if (fields["title"].length > 100) {
      _displayError("Title cannot be longer than 100 characters");
      return false;
    }
    if (fields["gender"].length > 50) {
      _displayError("Gender cannot be longer than 50 characters");
      return false;
    }
    if (fields["address"].length > 500) {
      _displayError("Address cannot be longer than 500 characters");
      return false;
    }
    if (fields["username"] != null && fields["username"].length > 150) {
      _displayError("Title cannot be longer than 150 characters");
      return false;
    }
    if (fields["user_first_name"].length > 150) {
      _displayError("Title cannot be longer than 150 characters");
      return false;
    }
    if (fields["user_last_name"].length > 150) {
      _displayError("Title cannot be longer than 150 characters");
      return false;
    }
    return true;
  }

  void _updateProfile() async {
    setState(() {
      _updating = true;
    });
    final Map fields = await updatedProfileCard.getData();

    final infoFields = informationCard.getData();
    fields.addAll(infoFields);

    final settingsFields = profileSettingsCard.getData();
    fields.addAll(settingsFields);

    if (!_verifyFields(fields)) {
      setState(() {
        _updating = false;
      });
      return;
    }
    if (fields['interests'].isNotEmpty)
      await API()
          .addProfileInterests(context, widget.setPage, fields['interests']!);
    await API().updateProfile(context, widget.data.id, fields);
    setState(() {
      _updating = false;
    });
    Navigator.pop(context);
    widget.setPage(0);
    widget.setPage(3);
  }

  Widget _publishButton() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                primary: matterialColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            onPressed: _updating ? null : () => _updateProfile(),
            child: _updating
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text("Update Profile")));
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(
            Icons.keyboard_arrow_left,
            color: matterialColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: backgroundColor,
        centerTitle: true,
        title: Text('Update Profile',
            style: TextStyle(
              color: matterialColor,
              fontFamily: 'Quicksand',
            )),
      ),
      body: ListView(
        physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        children: <Widget>[
          const SizedBox(
            height: 5,
          ),
          updatedProfileCard,
          const SizedBox(
            height: 10,
          ),
          informationCard,
          const SizedBox(
            height: 10,
          ),
          profileSettingsCard,
          const SizedBox(
            height: 10,
          ),
          _publishButton(),
        ],
      ),
    );
  }
}

class UpdatableProfileCardController {}

class UpdateableProfileCard extends StatefulWidget {
  final ProfileData profileCard;
  UpdateableProfileCard(this.profileCard);

  @override
  State<UpdateableProfileCard> createState() => UpdateableProfileCardState();

  final titleController = TextEditingController();
  final usernameController = TextEditingController();
  final bioController = TextEditingController();
  final genderController = TextEditingController();
  final addressController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  late final _imageAndBannerController = ImageAndBannerController(
      initialImage: profileCard.image, initialBanner: profileCard.banner);

  Future<Map> getData() async {
    final image = await _imageAndBannerController.getImageFile();
    final banner = await _imageAndBannerController.getBannerFile();
    return {
      if (profileCard.generalAttributes.username != usernameController.text)
        "username": usernameController.text,
      "title": titleController.text,
      "about": bioController.text,
      "gender": genderController.text,
      "address": addressController.text,
      "user_first_name": firstNameController.text,
      "user_last_name": lastNameController.text,
      if (image != null) "image": image,
      if (banner != null) "banner": banner
    };
  }
}

class UpdateableProfileCardState extends State<UpdateableProfileCard> {
  @override
  void initState() {
    if (widget.profileCard.title != null) {
      widget.titleController.text = widget.profileCard.title!;
    }
    widget.usernameController.text =
        widget.profileCard.generalAttributes.username;
    if (widget.profileCard.about != null) {
      widget.bioController.text = widget.profileCard.about!;
    }
    if (widget.profileCard.address != null)
      widget.addressController.text = widget.profileCard.address!;
    if (widget.profileCard.gender != null)
      widget.genderController.text = widget.profileCard.gender!;
    widget.lastNameController.text = widget.profileCard.lastName;
    widget.firstNameController.text = widget.profileCard.firstName;
    super.initState();
  }

  List<Widget> _field(String tile, TextEditingController controller,
      [bool multiLine = false]) {
    return [
      Text(tile),
      const SizedBox(
        height: 5,
      ),
      Container(
        decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(5)),
        child: TextFormField(
            maxLines: multiLine ? null : 1,
            controller: controller,
            decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                isDense: true),
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18)),
      ),
      const SizedBox(
        height: 10,
      ),
    ];
  }

  @override
  Widget build(context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UpdatableImageAndBanner(controller: widget._imageAndBannerController),
          const SizedBox(
            height: 30,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ..._field("Username", widget.usernameController),
                ..._field("Title", widget.titleController),
                ..._field("Bio", widget.bioController, true),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Invisible Fields",
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
                Divider(),
                ..._field("Gender", widget.genderController),
                ..._field("Address", widget.addressController, true),
                ..._field("First Name", widget.firstNameController),
                ..._field("Last Name", widget.lastNameController)
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ImageAndBannerController {
  final String? initialImage;
  final String? initialBanner;

  XFile? imageFile, bannerFile;

  ImageAndBannerController(
      {required this.initialImage, required this.initialBanner});

  Future<String?> getImageFile() async {
    //print(imagefile);
    if (imageFile == null) return null;
    final compressed = await FlutterImageCompress.compressWithFile(
        imageFile!.path,
        quality: 85,
        minWidth: 300,
        minHeight: 300);
    return imageFile == null || compressed == null
        ? null
        : base64Encode(compressed);
  }

  Future<String?> getBannerFile() async {
    if (bannerFile == null) return null;
    final compressed = await FlutterImageCompress.compressWithFile(
        bannerFile!.path,
        quality: 85,
        minHeight: 500);
    return bannerFile == null || compressed == null
        ? null
        : base64Encode(compressed);
  }
}

class UpdatableImageAndBanner extends StatefulWidget {
  final ImageAndBannerController controller;

  UpdatableImageAndBanner({required this.controller});

  @override
  State<UpdatableImageAndBanner> createState() =>
      UpdatableImageAndBannerState();
}

class UpdatableImageAndBannerState extends State<UpdatableImageAndBanner> {
  final _imageService = ImageService();

  Image _previewBanner() {
    if (widget.controller.bannerFile != null)
      return Image.file(File(widget.controller.bannerFile!.path),
          height: 120, width: double.maxFinite, fit: BoxFit.cover);
    else if (widget.controller.initialBanner != null)
      return Image.network(
        widget.controller.initialBanner!,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    else
      return Image.asset(
        "assets/images/defaultB.jpg",
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
      );
  }

  ImageProvider _previewImage() {
    if (widget.controller.imageFile != null)
      return FileImage(File(widget.controller.imageFile!.path));
    else if (widget.controller.initialImage != null)
      return NetworkImage(widget.controller.initialImage!);
    else
      return AssetImage("assets/images/defaultP.png");
  }

  @override
  Widget build(context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: <Widget>[
        ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            child: _previewBanner()),
        GestureDetector(
          //onTap: () => onTap(widget.bannerFile, true),
          onTap: () async {
            final banner = await _imageService.getImage(context);
            setState(() {
              widget.controller.bannerFile = banner;
            });
          },
          child: Container(
            decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.vertical(top: Radius.circular(10))),
            width: double.infinity,
            height: 120,
            alignment: Alignment.center,
            child: const Text(
              "Update banner",
              style: TextStyle(
                  color: Colors.white, fontFamily: 'Quicksand', fontSize: 20),
            ),
          ),
        ),
        Positioned(
          child: CircleAvatar(
            radius: 45,
            foregroundImage: _previewImage(),
          ),
          bottom: -30,
          left: 10,
        ),
        Positioned(
          child: CircleAvatar(
            radius: 45,
            backgroundColor: Colors.black54,
            child: GestureDetector(
              //onTap: () => onTap(widget.imageFile, false),
              onTap: () async {
                final image = await _imageService.getImage(context);
                setState(() {
                  widget.controller.imageFile = image;
                });
              },
              child: const Text(
                "Update Image",
                style: TextStyle(
                    color: Colors.white, fontFamily: 'Quicksand', fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          bottom: -30,
          left: 10,
        ),
      ],
    );
  }
}

class UpdatableInformationCard extends StatefulWidget {
  final Map? info;
  final List? interests;
  final List<DragAndDropListWithId> contents;
  final Interests interestsWidget;

  UpdatableInformationCard(
      {required this.info,
      required this.interests,
      required this.contents,
      required this.interestsWidget});

  @override
  State<UpdatableInformationCard> createState() =>
      UpdatableInformationCardState();

  Map getData() {
    Map data = {};
    print(contents);

    Map info = {};
    contents.forEach((dropList) {
      Map temp = {};
      dropList.children.forEach((dropWidget) {
        temp[(dropWidget.child as InfoCategory).title] =
            (dropWidget.child as InfoCategory).getData();
      });
      info[((dropList.header as Row).children[0] as Text).data] = temp;
    });
    print(data);
    data['info'] = info;
    data['interests'] = interestsWidget.getInterests();
    return data;
  }
}

class UpdatableInformationCardState extends State<UpdatableInformationCard> {
  void _onItemReorder(
      int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
    setState(() {
      var movedItem =
          widget.contents[oldListIndex].children.removeAt(oldItemIndex);
      widget.contents[newListIndex].children.insert(newItemIndex, movedItem);
    });
  }

  void _onListReorder(int oldListIndex, int newListIndex) {
    setState(() {
      var movedList = widget.contents.removeAt(oldListIndex);
      widget.contents.insert(newListIndex, movedList);
    });
  }

  void onDismiss(int index) {
    for (var i = 0; i < widget.contents.length; i++) {
      print(index);
      if (index == widget.contents[i].id) {
        setState(() {
          widget.contents.removeAt(i);
        });
        return;
      }
    }
  }

  int id = 0;
  @override
  void initState() {
    if (widget.info != null) {
      widget.info!.forEach((key, value) {
        print(value);
        final itemId = id;
        widget.contents.add(DragAndDropListWithId(
            id: itemId,
            header: Row(
              children: [
                Text('${(key as String)[0]}${key.substring(1)}'),
                Expanded(
                    child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                      onPressed: () => onDismiss(itemId),
                      icon: const Icon(Icons.remove)),
                ))
              ],
            ),
            children: (value as Map)
                .map((k, v) {
                  return MapEntry(
                      k,
                      DragAndDropItem(
                          child: InfoCategory(v, k, (id) => {}),
                          canDrag: false));
                })
                .values
                .toList()));
        id++;
      });
    }
    super.initState();
  }

  void addBackground() {
    setState(() {
      final itemId = id;
      widget.contents.add(DragAndDropListWithId(
          id: itemId,
          header: Row(
            children: [
              const Text('Background'),
              Expanded(
                  child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                    onPressed: () => onDismiss(itemId),
                    icon: const Icon(Icons.remove)),
              ))
            ],
          ),
          children: [
            DragAndDropItem(
                child: InfoCategory(
                    const {'title': '', 'sector': '', 'company': ''},
                    'job',
                    onDismiss),
                canDrag: false),
            DragAndDropItem(
                child: InfoCategory(const {'higher': '', 'high-school': ''},
                    'education', onDismiss),
                canDrag: false),
            DragAndDropItem(
                child: InfoCategory(
                    const {'birth': '', 'living': ''}, 'residence', onDismiss),
                canDrag: false)
          ]));
      id++;
    });
  }

  void addHobies() {
    final itemId = id;
    setState(() {
      widget.contents.add(DragAndDropListWithId(
          id: itemId,
          header: Row(
            children: [
              const Text('Hobies'),
              Expanded(
                  child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                    onPressed: () => onDismiss(itemId),
                    icon: const Icon(Icons.remove)),
              ))
            ],
          ),
          children: [
            DragAndDropItem(
                child: InfoCategory(const {'Favorite': '', 'Last Read': ''},
                    'books', onDismiss),
                canDrag: false),
            DragAndDropItem(
                child: InfoCategory(const {'Favorite': '', 'Last Watched': ''},
                    'movies', onDismiss),
                canDrag: false),
          ]));
      id++;
    });
  }

  late Map<String, void Function()> categories = {
    'Hobies': addHobies,
    'Background': addBackground
  };

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            "Information",
            style: TextStyle(fontSize: 20),
          ),
          DragAndDropLists(
            disableScrolling: true,
            contentsWhenEmpty: const SizedBox(),
            itemDivider: const SizedBox(
              height: 5,
            ),
            listPadding: const EdgeInsets.symmetric(horizontal: 10),
            children: widget.contents,
            onItemReorder: _onItemReorder,
            onListReorder: _onListReorder,
            listDividerOnLastChild: false,
            lastListTargetSize: 0,
          ),
          AddCategory(categories: categories),
          widget.interestsWidget
        ],
      ),
    );
  }
}

class DragAndDropListWithId extends DragAndDropList {
  final int id;

  DragAndDropListWithId(
      {required List<DragAndDropItem> children,
      Widget? header,
      required this.id})
      : super(children: children, header: header);
}

class InfoCategory extends StatelessWidget {
  final String title;
  final Map data;
  final void Function(int index) onDismiss;
  Map<String, Icon> cattegoryIcons = {
    'education': const Icon(LineIcons.school),
    'job': const Icon(LineIcons.briefcase),
    'residence': const Icon(LineIcons.city),
    'books': const Icon(LineIcons.book),
    'movies': const Icon(LineIcons.video)
  };

  Icon getIcon(key) {
    try {
      return cattegoryIcons[key]!;
    } catch (e) {
      return const Icon(Icons.miscellaneous_services_outlined);
    }
  }

  InfoCategory(this.data, this.title, this.onDismiss);
  List<Widget> list = [];

  Widget _items() {
    list = [];
    for (int i = 0; i < data.length; i++) {
      list.add(const SizedBox(height: 3));
      list.add(InfoItem(data.keys.elementAt(i), data.values.elementAt(i)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: list);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(width: 80, child: Center(child: cattegoryIcons[title])),
        _items(),
      ],
    );
  }

  Map getData() {
    Map data = {};
    list.forEach((element) {
      if (element is InfoItem) {
        data[element.attribute] = element.controller.text;
      }
    });
    return data;
  }
}

class InfoItem extends StatefulWidget {
  final String attribute, valueOfAttribute;
  InfoItem(this.attribute, this.valueOfAttribute);
  final controller = TextEditingController();

  @override
  State<InfoItem> createState() => InfoItemState();
}

class InfoItemState extends State<InfoItem> {
  @override
  void initState() {
    widget.controller.text = widget.valueOfAttribute;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(widget.attribute,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(
          width: 5,
        ),
        Container(
          decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(5)),
          constraints: const BoxConstraints(maxWidth: 150),
          child: TextFormField(
            controller: widget.controller,
            decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class AddCategory extends StatefulWidget {
  final Map<String, void Function()> categories;
  const AddCategory({required this.categories});

  @override
  State<AddCategory> createState() => AddCategoryState();
}

class AddCategoryState extends State<AddCategory> {
  String dropdownValue = 'Add a Category';

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: DropdownButton<String>(
          value: null,
          icon: const Icon(Icons.keyboard_arrow_down),
          elevation: 16,
          borderRadius: BorderRadius.circular(10),
          underline: const SizedBox(),
          hint: Text("Add a Category"),
          onChanged: (String? newValue) {
            setState(() {
              dropdownValue = newValue!;
            });
          },
          items: widget.categories
              .map((key, value) => MapEntry(
                  key,
                  DropdownMenuItem<String>(
                      value: key, child: Text(key), onTap: value)))
              .values
              .toList()),
    );
  }
}

class Interests extends StatefulWidget {
  final List? initialInterests;
  Interests(this.initialInterests);

  @override
  State<Interests> createState() => InterestsState();
  List<Chip> interests = [];

  List<String> getInterests() {
    print(initialInterests);
    return interests.map((e) => (e.label as Text).data!).toList();
  }
}

class InterestsState extends State<Interests> {
  final TextEditingController controller = TextEditingController();
  void onDelete(int index) {
    setState(() {
      widget.interests.removeAt(index);
    });
  }

  @override
  void initState() {
    print(widget.interests);
    super.initState();
    setState(() {
      if (widget.initialInterests != null) {
        widget.interests += List.generate(
            widget.initialInterests!.length,
            (index) =>
                interest(widget.initialInterests![index]['title'], index));
      }
    });
  }

  Chip interest(String title, int index) {
    return Chip(
        onDeleted: () => setState(() {
              widget.interests.removeAt(index);
            }),
        backgroundColor: Colors.grey.shade300,
        label: Text(title, style: const TextStyle(fontSize: 11)),
        deleteIcon: const Icon(
          Icons.close,
          size: 15,
        ),
        labelPadding: const EdgeInsets.symmetric(vertical: -2, horizontal: 5));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Interests', style: TextStyle(fontSize: 17)),
        const SizedBox(height: 5),
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 0.5),
                  borderRadius: const BorderRadius.all(Radius.circular(50))),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextFormField(
                style: const TextStyle(fontSize: 15),
                onChanged: (String value) => {},
                controller: controller,
                decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 0, vertical: 5),
                    border: InputBorder.none,
                    hintText: 'Add Interest'),
              ),
            ),
            Positioned(
                right: 0,
                top: -8,
                child: IconButton(
                    onPressed: () => {
                          if (controller.text.isNotEmpty)
                            {
                              setState(() => {
                                    widget.interests.add(interest(
                                        controller.text,
                                        widget.interests.length))
                                  }),
                              controller.clear()
                            }
                        },
                    icon: const Icon(
                      Icons.add,
                      size: 20,
                    )))
          ],
        ),
        Wrap(children: widget.interests, runSpacing: -15, spacing: 5)
      ],
    );
  }
}

class ProfileSettingsCard extends StatefulWidget {
  final PrivacySettings privacyWidget;

  ProfileSettingsCard({required this.privacyWidget});

  @override
  State<ProfileSettingsCard> createState() => ProfileSettingsCardState();

  Map getData() {
    Map data = {'is_private': privacyWidget.isPrivate};
    return data;
  }
}

class ProfileSettingsCardState extends State<ProfileSettingsCard> {
  int id = 0;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            "Profile Settings",
            style: TextStyle(fontSize: 20),
          ),
          widget.privacyWidget
        ],
      ),
    );
  }
}

class PrivacySettings extends StatefulWidget {
  bool isPrivate;
  PrivacySettings({required this.isPrivate});

  @override
  State<PrivacySettings> createState() => PrivacySettingsState();
}

class PrivacySettingsState extends State<PrivacySettings> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(LineIcons.userLock, size: 22),
        SizedBox(width: 10),
        Expanded(
          child: Text("Private"),
        ),
        Checkbox(
            shape: CircleBorder(),
            value: widget.isPrivate,
            fillColor: MaterialStateColor.resolveWith(
                (states) => const Color(0xFF733CE6)),
            onChanged: (value) {
              setState(() {
                widget.isPrivate = value!;
              });
            })
      ],
    );
  }
}
