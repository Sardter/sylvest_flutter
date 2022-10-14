import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:sylvest_flutter/chat/chat_rooms_page.dart';
import 'package:sylvest_flutter/subjects/communities/community_members.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:sylvest_flutter/services/mangers.dart';
import 'package:sylvest_flutter/modals/modals.dart';
import 'package:sylvest_flutter/post_builder/post_builder.dart';

import '../../chat/chat_api.dart';
import '../../chat/chat_page.dart';
import '../../services/image_service.dart';
import '../subject_util.dart';

class Community extends StatelessWidget {
  final CommunityData data;
  final void Function() onRefresh;
  final bool isDetail;

  const Community(
      {required this.data, required this.onRefresh, required this.isDetail});

  factory Community.fromJson(json, void Function() onRefresh, bool isDetail) {
    return Community(
      onRefresh: onRefresh,
      data: CommunityData.fromJson(json),
      isDetail: isDetail,
    );
  }

  Widget _community() {
    return Container(
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                spreadRadius: 1,
                offset: Offset.fromDirection(0.75))
          ],
          color: Colors.white,
          borderRadius: isDetail
              ? BorderRadius.vertical(bottom: Radius.circular(30))
              : BorderRadius.circular(10)),
      margin: isDetail
          ? const EdgeInsets.only(bottom: 10)
          : const EdgeInsets.only(bottom: 10, left: 4, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CommunityNameAndBanner(data.title!, data.banner, isDetail),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 80,
                  child: Center(
                    child: SylvestImageProvider(
                      radius: 40,
                      url: data.image,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    data.shortDescription,
                    style: const TextStyle(fontFamily: 'Quicksand'),
                  ),
                ),
                const SizedBox(
                  height: 7.5,
                ),
                if (data.masterCommunity != null)
                  ParrentCommunityTag(
                      title: data.masterCommunity!.title,
                      image: data.masterCommunity!.image,
                      id: data.masterCommunity!.id,
                      color: const Color(0xFF733CE6)),
                const SizedBox(
                  height: 7.5,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      CommunityStats(
                          data.members, data.posts, data.subCommunities),
                      const SizedBox(
                        height: 15,
                      ),
                      CommunityBio(data.about!),
                      const SizedBox(
                        height: 10,
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: CommunityButtons(
                            data.id, data.title!, data.isJoined),
                      )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(context) {
    return Column(
      children: [
        GestureDetector(
            onTap: () => {
                  if (!isDetail)
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommunityPage(
                            id: data.id,
                          ),
                        ))
                },
            child: _community()),
        if (isDetail)
          CommunityMembers(communityId: data.id, onRefresh: onRefresh),
        if (isDetail && data.subCommunities != 0) SubCommunities([]), // TODO
      ],
    );
  }
}

class CommunityMembers extends StatefulWidget {
  const CommunityMembers(
      {Key? key, required this.communityId, required this.onRefresh})
      : super(key: key);
  final int communityId;
  final void Function() onRefresh;

  @override
  State<CommunityMembers> createState() => _CommunityMembersState();
}

class _CommunityMembersState extends State<CommunityMembers> {
  final _manager = RolledUserManager();

  List<RolledUser> _members = [];
  bool _loading = false;

  Future<void> _getMembers() async {
    setState(() {
      _loading = true;
    });
    final members =
        await _manager.getMembers(context, widget.communityId, false);
    setState(() {
      _members = members;
      _loading = false;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _getMembers();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        launchModal(
            context,
            CommunityMembersModal(
              communityId: widget.communityId,
              onRefresh: widget.onRefresh,
            ));
      },
      child: Container(
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)
        ], color: Colors.white, borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(15),
        child: _loading
            ? LoadingIndicator()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Members", style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 5),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 40),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _members
                          .map((e) => Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: SylvestImageProvider(
                                  url: e.profileImage,
                                ),
                              ))
                          .toList(),
                    ),
                  )
                ],
              ),
      ),
    );
  }
}

class CommunityNameAndBanner extends StatelessWidget {
  final String? banner;
  final String title;
  final bool isDetail;
  const CommunityNameAndBanner(this.title, this.banner, this.isDetail);

  @override
  Widget build(context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        ClipRRect(
          borderRadius: isDetail
              ? BorderRadius.zero
              : const BorderRadius.only(
                  topLeft: Radius.circular(10), topRight: Radius.circular(10)),
          child: SylvestImage(
            url: banner,
            height: 120,
            width: double.infinity,
            useDefault: true,
          ),
        ),
        Container(
          decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: isDetail
                  ? BorderRadius.zero
                  : BorderRadius.vertical(top: Radius.circular(10))),
          height: 120,
          width: double.infinity,
        ),
        Positioned(
            bottom: 0,
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Quicksand',
                    fontSize: 20))),
      ],
    );
  }
}

class CommunityStats extends StatelessWidget {
  final int posts, subCommunities, members;
  const CommunityStats(this.members, this.posts, this.subCommunities);

  @override
  Widget build(context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              const Icon(LineIcons.user),
              Text(
                "$members Members",
                style: TextStyle(fontFamily: 'Quciksand', fontSize: 12),
              )
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              const Icon(LineIcons.shareSquare),
              Text(
                "$posts Posts",
                style: TextStyle(fontFamily: 'Quciksand', fontSize: 12),
              )
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              const Icon(LineIcons.users),
              Text(
                "$subCommunities Subs",
                style: TextStyle(fontFamily: 'Quciksand', fontSize: 12),
              )
            ],
          ),
        )
      ],
    );
  }
}

class CommunityFounder extends StatelessWidget {
  final String founder, founderImage;
  const CommunityFounder(this.founder, this.founderImage);

  @override
  Widget build(context) {
    return Expanded(
        child: Container(
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [
            BoxShadow(blurRadius: 5, spreadRadius: 1, color: Colors.black38)
          ],
          borderRadius: BorderRadius.circular(5)),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Founder",
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(
            height: 5,
          ),
          Row(
            children: [
              SylvestImageProvider(
                url: founderImage,
              ),
              const SizedBox(
                width: 10,
              ),
              Text(
                founder,
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            ],
          )
        ],
      ),
    ));
  }
}

class CommunityBio extends StatelessWidget {
  final String bio;
  const CommunityBio(this.bio);

  @override
  Widget build(context) {
    return Text(
      bio,
      textAlign: TextAlign.justify,
    );
  }
}

class CommunityButtons extends StatefulWidget {
  final int pk;
  final String title;
  bool isJoined;
  CommunityButtons(this.pk, this.title, this.isJoined);

  @override
  State<CommunityButtons> createState() => CommunityButtonsState();
}

class CommunityButtonsState extends State<CommunityButtons> {
  Widget _joinButton() {
    if (!widget.isJoined) {
      return OutlinedButton(
          style: OutlinedButton.styleFrom(
              primary: Color.fromARGB(255, 130, 89, 218),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30))),
          onPressed: () => join(),
          child: Row(
            children: const <Widget>[Icon(LineIcons.userPlus), Text("  Join")],
          ));
    } else {
      return ElevatedButton(
          style: ElevatedButton.styleFrom(
              primary: Color.fromARGB(255, 130, 89, 218),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30))),
          onPressed: () => join(),
          child: Row(
            children: const <Widget>[
              Icon(LineIcons.userMinus),
              Text("  Joined")
            ],
          ));
    }
  }

  void join() {
    if (!widget.isJoined) {
      setState(() {
        widget.isJoined = true;
      });
    } else {
      setState(() {
        widget.isJoined = false;
      });
    }
    API().join(widget.pk, context);
  }

  void _addPost() {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return FutureBuilder<Map>(
          future: API().getPostBuilderData(context),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return LoadingIndicator();
            }
            return PostBuilderPage(
                backToLastPage: () => Navigator.pop(context),
                preferedSettings: {
                  'community': {'id': widget.pk}
                },
                setPage: (page) {});
          });
    }));
  }

  Widget _chat() {
    return FutureBuilder<Room>(
      future: ChatAPI().getCommunityRoom(widget.pk, context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return LoadingDetailPage();
        }
        return ChatPage(roomData: snapshot.data!.data, refresh: () {});
      },
    );
  }

  void _toCommunityChat() async {
    final loginCred = await API().getLoginCred();
    if (loginCred == null) return;
    ChatAPI().username = loginCred['user']['username'];
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return _chat();
    }));
  }

  @override
  Widget build(context) {
    return Row(
      children: [
        _joinButton(),
        if (widget.isJoined)
          IconButton(
              onPressed: () => _addPost(),
              icon: const Icon(LineIcons.shareSquareAlt)),
        if (widget.isJoined)
          IconButton(
              onPressed: () => _toCommunityChat(),
              icon: const Icon(LineIcons.sms)),
        IconButton(
            onPressed: () => showMaterialModalBottomSheet(
                context: context,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(30))),
                builder: (context) {
                  return FutureBuilder(
                      future: API().getLoginCred(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return LoadingIndicator();
                        }
                        final data = snapshot.data! as Map;
                        return ShareOptionsModal(
                            shareableId: widget.pk,
                            shareable: Shareable.community,
                            userName: data['user']['username']);
                      });
                }),
            icon: const Icon(LineIcons.paperPlane)),
      ],
    );
  }
}

class CommunityPage extends StatefulWidget {
  CommunityPage({required this.id});
  final int id;

  @override
  State<CommunityPage> createState() => CommunityPageState();
}

class CommunityPageState extends State<CommunityPage> {
  final Color backgroundColor = Colors.white,
      matterialColor = const Color(0xFF733CE6),
      secondaryColor = Colors.black;
  final _postManager = PostManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _onRefresh();
    });
  }

  bool _appbarVisible = false;
  bool _isRefreshing = false;
  bool _isLoading = false;

  List<Widget> _posts = [];

  void _onRefresh() async {
    if (!_isRefreshing) {
      _postManager.reset();
      setState(() {
        print("refreshing community");
        _isRefreshing = true;
      });

      final newPosts =
          await _postManager.getPostsOfCommunity(widget.id, context);

      Future.delayed(Duration(seconds: 1), () {
        setState(() {
          _posts = newPosts.cast<Widget>();
          _isRefreshing = false;
        });
      });
    }
  }

  void _onLoad() async {
    if (!_isLoading && _postManager.next()) {
      setState(() {
        _isLoading = true;
        _posts += [_loadingWidget()];
      });

      final newPosts =
          await _postManager.getPostsOfCommunity(widget.id, context);
      await Future.delayed(Duration(seconds: 1));
      setState(() {
        _posts.removeLast();
        _posts += newPosts;
        _isLoading = false;
      });
    }
  }

  Widget _loadingWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Colors.black12,
      ),
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

  Widget _sliver() {
    return FutureBuilder<Community>(
      future: API().getCommunityDetail(context, widget.id, _onRefresh),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return LoadingDetailPage();
        }
        final community = snapshot.data!;
        return CustomScrollView(
          physics:
              AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverAppBar(
              snap: true,
              floating: true,
              pinned: true,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: Icon(Icons.keyboard_arrow_left),
                color: matterialColor,
                onPressed: () => Navigator.pop(context),
              ),
              backgroundColor: backgroundColor,
              actions: [],
              title: !_appbarVisible
                  ? null
                  : InkWell(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SylvestImageProvider(
                            url: community.data.image,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(community.data.title!,
                                  style: TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.bold))
                            ],
                          )
                        ],
                      ),
                    ),
            ),
            SliverList(
                delegate: SliverChildListDelegate([
              community,
              Container(
                padding: const EdgeInsets.all(5),
                child: Column(
                  children: _posts,
                ),
              )
            ]))
          ],
        );
      },
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >
              200 + notification.metrics.minScrollExtent) {
            if (!_appbarVisible)
              setState(() {
                _appbarVisible = true;
              });
          } else {
            if (_appbarVisible)
              setState(() {
                _appbarVisible = false;
              });
          }
          if (notification.metrics.pixels <
              notification.metrics.minScrollExtent - 50) {
            _onRefresh();
          } else if (notification.metrics.pixels >
              notification.metrics.maxScrollExtent) {
            _onLoad();
          }
          return false;
        },
        child: Stack(
          alignment: Alignment.center,
          children: [_sliver(), if (_isRefreshing) _refreshingWidget()],
        ),
      ),
    );
  }
}

class SubCommunities extends StatelessWidget {
  final List communities;
  const SubCommunities(this.communities);

  @override
  Widget build(context) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFF3d91e6),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2)
          ],
          gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                const Color(0xFF733CE6),
                const Color(0xFF733CE6).withOpacity(0.6)
              ])),
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(15),
      child: ExpandablePanel(
          theme: const ExpandableThemeData(iconColor: Colors.white),
          collapsed: const SizedBox(),
          header: Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: const Text(
                "Sub-communities",
                style: TextStyle(color: Colors.white, fontSize: 18),
              )),
          expanded: Column(
            children: communities.map((e) => SubCommunity.fromJson(e)).toList(),
          )),
    );
  }
}

class SubCommunity extends StatelessWidget {
  final CommunityData data;

  const SubCommunity({required this.data});

  factory SubCommunity.fromJson(json) {
    return SubCommunity(
      data: CommunityData.fromJson(json),
    );
  }

  @override
  Widget build(context) {
    return GestureDetector(
        onTap: () => {
              Navigator.push(context,
                  MaterialPageRoute<void>(builder: (BuildContext context) {
                return CommunityPage(
                  id: data.id,
                );
              }))
            },
        child: Container(
            decoration: BoxDecoration(
                //boxShadow: const [BoxShadow(color: Colors.white, blurRadius: 5, spreadRadius: 1)],
                color: Colors.white,
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(3),
            child: Column(
              children: [
                ClipRRect(
                  child: SylvestImage(
                    url: data.banner,
                    height: 100,
                    width: double.infinity,
                    useDefault: true,
                  ),
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10)),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Center(
                          child: SylvestImageProvider(
                            url: data.image,
                          ),
                        ),
                      ),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data.title!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87)),
                          Text(
                            data.shortDescription,
                            style: const TextStyle(
                                fontSize: 17, color: Colors.black87),
                          )
                        ],
                      )),
                      SizedBox(
                        width: 60,
                        child: Center(
                            child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_outline,
                                    color: Colors.black87),
                                const SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  data.members.toString(),
                                  style: const TextStyle(
                                      fontFamily: 'Quicksand',
                                      color: Colors.black87),
                                )
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.post_add_outlined,
                                    color: Colors.black87),
                                const SizedBox(
                                  width: 10,
                                ),
                                Text(data.posts.toString(),
                                    style: const TextStyle(
                                        fontFamily: 'Quicksand',
                                        color: Colors.black87))
                              ],
                            )
                          ],
                        )),
                      )
                    ],
                  ),
                )
              ],
            )));
  }
}

class ParrentCommunityTag extends StatelessWidget {
  final String title;
  final String? image;
  final Color color;
  final int id;

  const ParrentCommunityTag(
      {required this.title,
      required this.image,
      required this.color,
      required this.id});

  @override
  Widget build(context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CommunityPage(
                    id: id,
                  ))),
      child: Container(
        decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20))),
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: SylvestImageProvider(
                url: image,
                radius: 12,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("A sub community of",
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Quicksand',
                        fontSize: 10)),
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Quicksand'))
              ],
            )
          ],
        ),
      ),
    );
  }
}
