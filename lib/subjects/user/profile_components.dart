import 'package:flutter/material.dart';
import 'package:expandable/expandable.dart';
import 'package:line_icons/line_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:sylvest_flutter/chain/transfer_service.dart';
import 'package:sylvest_flutter/chat/chat_page.dart';
import 'package:sylvest_flutter/posts/post_util.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:sylvest_flutter/chat/chat_api.dart';
import 'package:sylvest_flutter/chat/chat_rooms_page.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:sylvest_flutter/modals/modals.dart';
import 'package:sylvest_flutter/posts/pages/post_detail_page.dart';
import 'package:sylvest_flutter/services/mangers.dart';
import 'package:sylvest_flutter/subjects/subject_util.dart';
import 'package:sylvest_flutter/subjects/user/update_profile_page.dart';

import '../../services/image_service.dart';

class ProfileCard extends StatelessWidget {
  final Color backgroundColor = Colors.white,
      matterialColor = const Color(0xFF733CE6),
      secondaryColor = Colors.black;

  final ProfileData data;
  final void Function(int page) setPage;

  ProfileCard({required this.data, required this.setPage});

  factory ProfileCard.fromJson(Map json, void Function(int page) setPage) {
    return ProfileCard(data: ProfileData.fromJson(json), setPage: setPage);
  }

  @override
  Widget build(BuildContext context) {
    final bannerImage = SylvestImage(
      url: data.banner,
      useDefault: true,
      width: double.maxFinite,
      height: 120,
    );

    return Column(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    spreadRadius: 1,
                    offset: Offset.fromDirection(0.75))
              ],
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
          padding: const EdgeInsets.only(bottom: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: <Widget>[
                  ClipRRect(child: bannerImage),
                  Positioned(
                    child: SizedBox(
                      height: 100,
                      width: 100,
                      child: SylvestImageProvider(
                        url: data.image,
                      ),
                    ),
                    bottom: -30,
                  ),
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              ProfileCardInfo(
                  name: data.generalAttributes.username,
                  title: data.title,
                  bio: data.about,
                  followers: data.followers,
                  following: data.following,
                  contributions: data.contributing,
                  posts: data.posts,
                  id: data.id,
                  secondaryColor: secondaryColor),
              ProfileCardButtons(
                  data.generalAttributes.isOwner,
                  data.id,
                  data.generalAttributes.isFollowed,
                  this,
                  matterialColor,
                  setPage),
            ],
          ),
        ),
        ProfileInformationCard(data.info, data.interests, backgroundColor,
            matterialColor, secondaryColor),
        // if (data.attending) TODO: implement
        //   Contributing(
        //     backgroundColor: const Color(0xFFe6733c),
        //     contributing: data.attending,
        //     title: 'Attending to',
        //   ),
        // if (data.contributing.isNotEmpty)
        //   Contributing(
        //       title: 'Contributing to',
        //       contributing: data.contributing,
        //       backgroundColor: const Color(0xFF733CE6)),
      ],
    );
  }
}

class Contributing extends StatelessWidget {
  final String title;
  final List<ProfilePost> contributing;
  final Color backgroundColor;

  Contributing(
      {required this.title,
      required this.contributing,
      required this.backgroundColor});

  Widget contributingToPost(context, e) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => PostDetailPage(e['id'])));
      },
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30), color: Colors.black12),
        padding: const EdgeInsets.all(5),
        margin: const EdgeInsets.only(bottom: 5),
        child: Row(
          children: [
            SylvestImageProvider(
              url: e['image'],
            ),
            const SizedBox(
              width: 5,
            ),
            Text(
              e['tile'],
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }

  List<Widget> contributingTo = [];

  @override
  Widget build(context) {
    contributingTo = contributing
        .take(5)
        .map<Widget>((e) => contributingToPost(context, e))
        .toList();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [backgroundColor, backgroundColor.withOpacity(0.65)]),
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              spreadRadius: 1,
              offset: Offset.fromDirection(0.75))
        ],
      ),
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(
                height: 10,
              ),
            ] +
            contributingTo,
      ),
    );
  }
}

class ProfileCardInfo extends StatelessWidget {
  final Color secondaryColor;
  final String name;
  final String? title, bio;
  final int followers, following;
  final int contributions;
  final int posts;
  final int id;
  const ProfileCardInfo(
      {required this.name,
      required this.title,
      required this.bio,
      required this.followers,
      required this.following,
      required this.contributions,
      required this.posts,
      required this.secondaryColor,
      required this.id});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(name,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
          if (title != null)
            Text(
              title!,
              style: const TextStyle(color: Colors.black54),
            ),
          const SizedBox(
            height: 10,
          ),
          if (bio != null)
            Text(
              bio!,
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.justify,
            ),
          ProfileCardStatus(
              secondaryColor: secondaryColor,
              followers: followers,
              following: following,
              contributions: contributions,
              posts: posts,
              id: id)
        ],
      ),
    );
  }
}

class ProfileCardButtons extends StatefulWidget {
  final bool isProfile;
  FollowStatus followStatus;
  final int pk;
  final ProfileCard profileCard;
  final Color matterialColor;
  final void Function(int page) setPage;
  ProfileCardButtons(this.isProfile, this.pk, this.followStatus,
      this.profileCard, this.matterialColor, this.setPage);

  @override
  ProfileCardButtonsState createState() => ProfileCardButtonsState();
}

class ProfileCardButtonsState extends State<ProfileCardButtons> {
  bool _loading = false;

  Widget _interactButton() {
    if (widget.isProfile) {
      return OutlinedButton(
          style: OutlinedButton.styleFrom(
              primary: Color.fromARGB(255, 130, 89, 218),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30))),
          onPressed: () => {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ProfileUpdatePage(
                              data: widget.profileCard.data,
                              setPage: widget.setPage,
                            )))
              },
          child: Row(
            children: const <Widget>[Icon(LineIcons.userEdit), Text("  Edit")],
          ));
    } else {
      return _followButton();
    }
  }

  Widget _followButton() {
    switch (widget.followStatus) {
      case FollowStatus.Following:
        return ElevatedButton(
            style: ElevatedButton.styleFrom(
                primary: Color.fromARGB(255, 130, 89, 218),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30))),
            onPressed: _loading ? null : () => follow(),
            child: Row(
              children: <Widget>[
                const Icon(LineIcons.userMinus),
                if (!_loading)
                  Text("  Following")
                else
                  LoadingIndicator(
                    size: 15,
                  )
              ],
            ));
      case FollowStatus.NotFollowing:
        return OutlinedButton(
            style: OutlinedButton.styleFrom(
                primary: Color.fromARGB(255, 130, 89, 218),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30))),
            onPressed: _loading ? null : () => follow(),
            child: Row(
              children: <Widget>[
                const Icon(LineIcons.userPlus),
                if (!_loading)
                  Text("  Follow")
                else
                  LoadingIndicator(
                    size: 15,
                  )
              ],
            ));
      case FollowStatus.RequestSent:
        return ElevatedButton(
            style: ElevatedButton.styleFrom(
                primary: Color.fromARGB(255, 130, 89, 218),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30))),
            onPressed: _loading ? null : () => follow(),
            child: Row(
              children: <Widget>[
                const Icon(LineIcons.userMinus),
                if (!_loading)
                  Text("  Request Sent")
                else
                  LoadingIndicator(
                    size: 15,
                  )
              ],
            ));
      case FollowStatus.UnFollowed:
        return OutlinedButton(
            style: OutlinedButton.styleFrom(
                primary: Color.fromARGB(255, 130, 89, 218),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30))),
            onPressed: _loading ? null : () => follow(),
            child: Row(
              children: <Widget>[
                const Icon(LineIcons.userPlus),
                if (!_loading)
                  Text("  Unfollowed")
                else
                  LoadingIndicator(
                    size: 15,
                  )
              ],
            ));
    }
  }

  Future<void> follow() async {
    setState(() {
      _loading = true;
    });
    final status = await API().follow(widget.pk, context);
    setState(() {
      widget.followStatus = status;
      _loading = false;
    });
  }

  Widget _chat() {
    return FutureBuilder<Room>(
      future: ChatAPI().getProfileRoom(widget.pk, context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return LoadingDetailPage();
        }
        return ChatPage(roomData: snapshot.data!.data, refresh: () {});
      },
    );
  }

  void _getChat(context) async {
    final loginCred = await API().getLoginCred();
    if (loginCred == null) return;
    ChatAPI().username = loginCred['user']['username'];
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return _chat();
    }));
  }

  late final _transferService = TransferService(
      currentBalance: widget.profileCard.data.chainDetails!.balance);

  void _onTransfer() async {
    _transferService.transferToUserDialog(
        UserData(
            id: widget.profileCard.data.id,
            username: widget.profileCard.data.generalAttributes.username,
            profileImage: widget.profileCard.data.image),
        widget.profileCard.data.chainDetails!.address,
        context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: <Widget>[
          _interactButton(),
          const SizedBox(width: 15),
          if (!widget.isProfile) ...[
            IconButton(
                onPressed: () => _getChat(context),
                icon: Icon(LineIcons.sms, color: widget.matterialColor)),
            Spacer(),
            if (widget.profileCard.data.chainDetails != null)
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      primary: widget.matterialColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  onPressed: _onTransfer,
                  child: Row(
                    children: [
                      Icon(
                        LineIcons.donate,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Text("Send SYVE")
                    ],
                  ))
          ],
        ],
      ),
    );
  }
}

class ProfileCardStatus extends StatelessWidget {
  final Color secondaryColor;
  final int followers, following;
  final int contributions;
  final int posts;
  final int id;

  const ProfileCardStatus(
      {Key? key,
      required this.secondaryColor,
      required this.followers,
      required this.following,
      required this.contributions,
      required this.posts,
      required this.id})
      : super(key: key);

  _usersModal(context, String title, UserManagerType type, int id) {
    showMaterialModalBottomSheet(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        context: context,
        builder: (context) {
          return UserListModal(
            title: title,
            type: type,
            id: id,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // decoration: BoxDecoration(boxShadow: [
      //   BoxShadow(blurRadius: 5, spreadRadius: 2, color: Colors.grey.shade300)
      // ], borderRadius: BorderRadius.circular(5), color: Colors.white),
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              _usersModal(context, 'Followers', UserManagerType.Followers, id);
            },
            child: ProfileCardStatusItem(
                "Followers", followers, LineIcons.userFriends, secondaryColor),
          ),
          GestureDetector(
            onTap: () {
              _usersModal(context, 'Following', UserManagerType.Following, id);
            },
            child: ProfileCardStatusItem(
                "Following", following, LineIcons.userFriends, secondaryColor),
          ),
          ProfileCardStatusItem("Contributions", contributions,
              LineIcons.handshake, secondaryColor),
          ProfileCardStatusItem(
              "Posts", posts, LineIcons.shareSquare, secondaryColor),
        ],
      ),
    );
  }
}

class ProfileCardStatusItem extends StatelessWidget {
  final String attriburte;
  final int stat;
  final Color secondaryColor;
  final IconData icon;

  const ProfileCardStatusItem(
      this.attriburte, this.stat, this.icon, this.secondaryColor);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Icon(
          icon,
          color: secondaryColor,
          size: 18,
        ),
        const SizedBox(
          width: 5,
        ),
        Text(
          "$stat $attriburte",
          style: TextStyle(fontFamily: '', fontWeight: FontWeight.w300),
        ),
      ],
    );
  }
}

class ExperienceBar extends StatelessWidget {
  const ExperienceBar(this.level, this.target, this.current,
      this.secondaryColor, this.backgroundColor,
      {Key? key})
      : super(key: key);
  final int level;
  final double target, current;
  final Color secondaryColor, backgroundColor;

  @override
  Widget build(BuildContext context) {
    double progress = current / target;
    return Container(
        constraints: const BoxConstraints(minHeight: 93),
        margin: const EdgeInsets.only(left: 4, right: 4, bottom: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
              colors: <Color>[
                backgroundColor,
                backgroundColor.withOpacity(0.63)
              ]),
          color: backgroundColor,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                spreadRadius: 1,
                offset: Offset.fromDirection(0.75))
          ],
        ),
        child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("Level " + level.toString(),
                      style: TextStyle(
                          color: secondaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w400)),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    color: Colors.white,
                    backgroundColor: Colors.black12,
                    value: progress,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  RichText(
                    text: TextSpan(
                        style: TextStyle(color: secondaryColor),
                        children: <TextSpan>[
                          TextSpan(
                              text: current.toInt().toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w400)),
                          const TextSpan(
                            text: " of ",
                          ),
                          TextSpan(
                              text: target.toInt().toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w400))
                        ]),
                  ),
                ])));
  }
}

class ProfileInformationCard extends StatelessWidget {
  final Color backgroundColor, matterialColor, secondaryColor;
  final Map? info;
  final List<Map>? interests;
  ProfileInformationCard(this.info, this.interests, this.backgroundColor,
      this.matterialColor, this.secondaryColor);

  List<Map<String, String>> backgroundInfo = [
    {"High-school: ": "Ayseabla", "Higher Education": "Bilkent University"},
    {"Place of birth: ": "Iran", "Residence: ": "Trueky"},
    {"Sector: ": "Technology", "Job Title: ": "CEO", "Company: ": "Sylvest"}
  ];

  Map<String, Icon> cattegoryIcons = {
    'education': const Icon(LineIcons.school),
    'job': const Icon(LineIcons.briefcase),
    'residence': const Icon(LineIcons.city),
    'books': const Icon(LineIcons.book),
    'movies': const Icon(LineIcons.video)
  };

  @override
  Widget build(BuildContext context) {
    return ExpandableNotifier(
        child: Padding(
      padding: const EdgeInsets.all(0),
      child: Container(
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              spreadRadius: 1,
              offset: Offset.fromDirection(0.75))
        ], color: Colors.white, borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Column(
          children: <Widget>[
            ScrollOnExpand(
              scrollOnExpand: true,
              scrollOnCollapse: false,
              child: ExpandablePanel(
                theme: const ExpandableThemeData(
                  headerAlignment: ExpandablePanelHeaderAlignment.center,
                  tapBodyToCollapse: true,
                ),
                header: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: Text(
                      "Information",
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                          color: matterialColor),
                    )),
                collapsed: const Text(
                  "Background and intrests",
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                expanded: InformationInfo(info /* ['background'] */, interests,
                    cattegoryIcons, secondaryColor),
                builder: (_, collapsed, expanded) {
                  return Padding(
                    padding:
                        const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                    child: Expandable(
                      collapsed: collapsed,
                      expanded: expanded,
                      theme: const ExpandableThemeData(crossFadePoint: 0),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

class InformationInfo extends StatelessWidget {
  final Color secondaryColor;
  final Map<String, Icon> cattegoryIcons;
  final Map? info;
  final List<Map>? interests;
  const InformationInfo(
      this.info, this.interests, this.cattegoryIcons, this.secondaryColor);

  Widget _items() {
    List<Widget> items = [];

    if (info != null && info!.isNotEmpty) {
      items.add(const SizedBox(height: 10));

      info!.forEach((key, value) {
        String name = key;
        items.add(Text('${name[0].toUpperCase()}${name.substring(1)}'));
        items.add(const SizedBox(height: 10));
        int count = 0;
        Map category = value;
        category.forEach((key, value) {
          items.add(BackgroundInfoCategory(
              value, cattegoryIcons[key]!, secondaryColor));
          count++;
          if (count != category.length) {
            items.add(const Divider());
          } else {
            items.add(const SizedBox(
              height: 10,
            ));
          }
        });
      });
    }

    if (interests != null && interests!.isNotEmpty) {
      items.add(const SizedBox(height: 10));
      items.add(const Text("Intresets"));
      items.add(const SizedBox(height: 10));
      items.add(Interests(interests!));
    }
    if (items.isEmpty) {
      items.add(SizedBox(
        height: 50,
        child: Center(
          child: Text(
            "No futher information has been shared yet",
            style: TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ),
      ));
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: items);
  }

  @override
  Widget build(BuildContext context) {
    return _items();
  }
}

class Interests extends StatelessWidget {
  final List<Map> interests;
  const Interests(this.interests);

  @override
  Widget build(BuildContext context) {
    print(interests);
    return Wrap(
        children: interests.map<Widget>((e) {
          print(e);
          return Interest(e['title']);
        }).toList(),
        runSpacing: -15);
  }
}

class Interest extends StatelessWidget {
  final String title;
  const Interest(this.title);

  @override
  Widget build(BuildContext context) {
    return Chip(
        backgroundColor: const Color(0xFF733CE6),
        labelStyle: const TextStyle(color: Colors.white),
        label: Text(title, style: const TextStyle(fontSize: 11)),
        labelPadding: const EdgeInsets.symmetric(vertical: -2, horizontal: 5));
  }
}

class BackgroundInfoCategory extends StatelessWidget {
  final Color secondaryColor;
  final Icon cattegoryIcon;
  final Map data;
  const BackgroundInfoCategory(
      this.data, this.cattegoryIcon, this.secondaryColor);

  Widget _items() {
    List<Widget> list = [];
    for (int i = 0; i < data.length; i++) {
      list.add(const SizedBox(height: 3));
      list.add(BackgroundInfoItem(
          data.keys.elementAt(i), data.values.elementAt(i), secondaryColor));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: list);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(width: 80, child: Center(child: cattegoryIcon)),
        Expanded(child: _items()),
      ],
    );
  }
}

class BackgroundInfoItem extends StatelessWidget {
  final Color secondaryColor;
  final String attribute, valueOfAttribute;
  const BackgroundInfoItem(
      this.attribute, this.valueOfAttribute, this.secondaryColor);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(
                attribute[0].toUpperCase() +
                    attribute.substring(1).replaceAll('_', ' '),
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: secondaryColor))),
        const SizedBox(
          width: 10,
        ),
        Text(
          valueOfAttribute,
          style: TextStyle(color: secondaryColor),
        )
      ],
    );
  }
}
