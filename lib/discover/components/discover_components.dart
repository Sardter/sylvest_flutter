import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:sylvest_flutter/discover/pages/communities_page.dart';
import 'package:sylvest_flutter/discover/pages/tag_posts_page.dart';
import 'package:sylvest_flutter/home/home.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:sylvest_flutter/home/pages.dart';
import 'package:sylvest_flutter/posts/pages/events_map_page.dart';
import 'package:sylvest_flutter/posts/pages/projects_page.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:sylvest_flutter/services/mangers.dart';
import 'package:sylvest_flutter/subjects/communities/communities.dart';
import 'package:sylvest_flutter/subjects/user/user_page.dart';

import '../../services/image_service.dart';
import '../../subjects/subject_util.dart';

class DiscoverSection extends StatelessWidget {
  const DiscoverSection({Key? key, required this.title, required this.child})
      : super(key: key);
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
                color: Color(0xFF733CE6),
                borderRadius:
                    BorderRadius.horizontal(right: Radius.circular(30))),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Quicksand',
                    fontSize: 22)),
          ),
          child
        ],
      ),
    );
  }
}

class RecommendedUsers extends StatefulWidget {
  const RecommendedUsers({Key? key}) : super(key: key);

  @override
  State<RecommendedUsers> createState() => _RecommendedUsersState();
}

class _RecommendedUsersState extends State<RecommendedUsers> {
  List<RecommendedProfile> _profiles = [];
  bool _loading = false;

  Future<void> _getProfiles() async {
    setState(() {
      _loading = true;
    });
    final recommended = await API().getRecommendedProfiles(context);
    if (mounted)
      setState(() {
        _profiles = recommended
            .map<RecommendedProfile>((e) => RecommendedProfile(
                  data: e,
                ))
            .toList();
        _loading = false;
      });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _getProfiles();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DiscoverSection(
      title: "Users",
      child: _loading
          ? LoadingIndicator()
          : _profiles.isEmpty
              ? SizedBox(
                  height: 100,
                  child: Center(
                      child: Text(
                    "No profiles yet!",
                    style: TextStyle(color: Colors.grey),
                  )),
                )
              : CarouselSlider(
                  items: _profiles,
                  options: CarouselOptions(
                      aspectRatio: 16 / 12,
                      viewportFraction: 0.8,
                      enlargeCenterPage: true),
                ),
    );
  }
}

class RecommendedProfile extends StatelessWidget {
  const RecommendedProfile({Key? key, required this.data}) : super(key: key);

  final ProfileData data;

  factory RecommendedProfile.fromJson(Map json) {
    return RecommendedProfile(data: ProfileData.fromJson(json));
  }

  String _limiter(String text) {
    if (text.length < 15) return text;
    return text.substring(0, 12) + "...";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => UserPage(data.id))),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2)
            ]),
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SylvestImageProvider(
                  radius: 40,
                  url: data.image,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _limiter(data.generalAttributes.username),
                      style: TextStyle(fontSize: 20, fontFamily: 'Quicksand'),
                    ),
                    if (data.title != null && data.title!.isNotEmpty)
                      Text(
                        _limiter(data.title!),
                        style: TextStyle(color: Colors.black54),
                      ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10,horizontal: 0),
                      height: 30,
                      child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              primary: const Color(0xFF733CE6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30))),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => UserPage(data.id))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(LineIcons.userPlus),
                              SizedBox(
                                width: 10,
                              ),
                              Text("Follow")
                            ],
                          )),
                    )
                  ],
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Icon(LineIcons.userFriends),
                    Text(
                      "${data.followers} Followers",
                      style: TextStyle(fontSize: 11),
                    )
                  ],
                ),
                Column(
                  children: [
                    Icon(LineIcons.userFriends),
                    Text(
                      "${data.following} Following",
                      style: TextStyle(fontSize: 11),
                    )
                  ],
                ),
                Column(
                  children: [
                    Icon(LineIcons.plusCircle),
                    Text(
                      "${data.contributing} Contributions",
                      style: TextStyle(fontSize: 11),
                    )
                  ],
                ),
                Column(
                  children: [
                    Icon(LineIcons.shareSquare),
                    Text(
                      "${data.posts} Posts",
                      style: TextStyle(fontSize: 11),
                    )
                  ],
                ),
              ],
            ),
            if (data.about != null && data.about!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  data.about!,
                  style: TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (data.interests != null && data.interests!.isNotEmpty)
              Container(
                constraints: BoxConstraints(maxHeight: 30),
                child: ListView(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  children: data.interests!
                      .take(5)
                      .map<Chip>((e) => Chip(
                            labelPadding: const EdgeInsets.symmetric(
                                vertical: -4, horizontal: 10),
                            label: Text(
                              e['title'],
                              style: TextStyle(fontSize: 11),
                            ),
                          ))
                      .toList(),
                ),
              )
            //SizedBox(height: 10,)
          ],
        ),
      ),
    );
  }
}

class TrendingCommunities extends StatefulWidget {
  const TrendingCommunities({Key? key}) : super(key: key);

  @override
  State<TrendingCommunities> createState() => _TrendingCommunitiesState();
}

class _TrendingCommunitiesState extends State<TrendingCommunities> {
  final _manager = CommunityManager();

  List<DiscoverCommunity> _communities = [];
  bool _loading = false;

  Future<void> _getCommunities() async {
    if (mounted)
      setState(() {
        _loading = true;
      });
    final communities = await _manager.getDiscoverCommunities(context);
    if (mounted)
      setState(() {
        _communities = communities;
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

  @override
  Widget build(BuildContext context) {
    return DiscoverSection(
      title: "Communities",
      child: _loading
          ? LoadingIndicator()
          : _communities.isEmpty
              ? SizedBox(
                  height: 100,
                  child: Center(
                      child: Text(
                    "No communities yet!",
                    style: TextStyle(color: Colors.grey),
                  )),
                )
              : CarouselSlider(
                  items: [
                    ..._communities,
                    GestureDetector(
                      onTap: () async => await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MoreCommunitiesPage())),
                      child: Container(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              "More",
                              style: TextStyle(
                                  color: const Color(0xFF733CE6),
                                  fontFamily: 'Quicksand'),
                            ),
                            SizedBox(width: 10),
                            Icon(
                              LineIcons.angleRight,
                              size: 20,
                              color: const Color(0xFF733CE6),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                  options: CarouselOptions(
                      enableInfiniteScroll: false,
                      viewportFraction: 0.8,
                      height: 275,
                      enlargeCenterPage: true),
                ),
    );
  }
}

class DiscoverCommunity extends StatelessWidget {
  const DiscoverCommunity({Key? key, required this.data}) : super(key: key);

  final CommunityData data;

  factory DiscoverCommunity.fromJson(Map json) {
    return DiscoverCommunity(data: CommunityData.fromJson(json));
  }

  String _limiter(String text) {
    if (text.length < 20) return text;
    return text.substring(0, 17) + "...";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black12, spreadRadius: 2, blurRadius: 5)
          ]),
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CommunityPage(id: data.id))),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(10)),
                  child: SylvestImage(
                      url: data.banner,
                      useDefault: true,
                      height: 100,
                      width: double.infinity),
                ),
                Positioned.fill(
                    child: Container(
                  decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10))),
                  width: double.maxFinite,
                  height: double.maxFinite,
                )),
                Positioned(
                  bottom: 10,
                  child: Text(
                    _limiter(data.title!),
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Quicksand',
                        fontSize: 22),
                  ),
                ),
              ],
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SylvestImageProvider(
                  radius: 30,
                  url: data.image,
                ),
                Column(
                  children: [
                    Text(_limiter(data.shortDescription),
                        style:
                            TextStyle(fontSize: 16, fontFamily: 'Quicksand')),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Icon(LineIcons.user),
                            Text(
                              "${data.members} Members",
                              style: TextStyle(fontSize: 11),
                            )
                          ],
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Column(
                          children: [
                            Icon(LineIcons.shareSquare),
                            Text(
                              "${data.posts} Posts",
                              style: TextStyle(fontSize: 11),
                            )
                          ],
                        ),
                      ],
                    )
                  ],
                )
              ],
            ),
            //Spacer(),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 15,horizontal: 30),
              height: 30,
              child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      primary: const Color(0xFF733CE6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CommunityPage(id: data.id))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(LineIcons.userPlus),
                      SizedBox(
                        width: 10,
                      ),
                      Text("Join")
                    ],
                  )),
            )
          ],
        ),
      ),
    );
  }
}

class RecommendedEvents extends StatefulWidget {
  const RecommendedEvents({Key? key}) : super(key: key);

  @override
  State<RecommendedEvents> createState() => _RecommendedEventsState();
}

class _RecommendedEventsState extends State<RecommendedEvents> {
  final _manager = EventsManager();

  List<EventSmallCard> _events = [];
  bool _loading = false;

  Future<void> _getEvents() async {
    setState(() {
      _loading = true;
    });
    final events = await _manager.getEventsWithLocations(context);
    if (mounted)
      setState(() {
        _events = events;
        _loading = false;
      });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (_events.isEmpty) _getEvents();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DiscoverSection(
        title: "Events",
        child: Container(
          margin: const EdgeInsets.all(10),
          child: _loading
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  height: 100,
                  child: LoadingIndicator(),
                )
              : EventsSmallMap(eventsWithLocation: _events),
        ));
  }
}

class RecommendedProjects extends StatefulWidget {
  const RecommendedProjects({Key? key}) : super(key: key);

  @override
  State<RecommendedProjects> createState() => _RecommendedProjectsState();
}

class _RecommendedProjectsState extends State<RecommendedProjects> {
  final _manager = ProjectManager();

  List<MostFundedData> _mostFunded = [];
  double _max = 100.0;
  bool _loading = false;

  Future<void> _getMostFunded() async {
    setState(() {
      _loading = true;
    });
    final funded = await _manager.getProjects(context);
    if (mounted)
      setState(() {
        _mostFunded = funded
            .take(5)
            .map<MostFundedData>((e) => MostFundedData(
                title: e.data.title,
                authorImage: e.data.authorDetails.profileImage,
                currentFund: e.data.projectFields!.totalFunded,
                id: e.data.postId))
            .toList();
        _loading = false;
      });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (_mostFunded.isEmpty) _getMostFunded();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DiscoverSection(
        title: "Projects",
        child: Container(
          margin: const EdgeInsets.all(10),
          child: _loading
              ? Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  height: 100,
                  child: LoadingIndicator(),
                )
              : _mostFunded.isEmpty
                  ? SizedBox(
                      height: 100,
                      child: Center(
                          child: Text(
                        "No projects yet!",
                        style: TextStyle(color: Colors.grey),
                      )),
                    )
                  : MostFundedProjects(mostFunded: _mostFunded, max: _max),
        ));
  }
}

class RecommendedTags extends StatefulWidget {
  const RecommendedTags({Key? key}) : super(key: key);

  @override
  State<RecommendedTags> createState() => _RecommendedTagsState();
}

class _RecommendedTagsState extends State<RecommendedTags> {
  List<DiscoverTag> _tags = [];
  bool _loading = false;

  Future<void> _getTags() async {
    if (mounted)
      setState(() {
        _loading = true;
      });
    final tags = await API().getTags(context);
    if (mounted)
      setState(() {
        _tags = tags;
        _loading = false;
      });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _getTags();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _tags.isEmpty
        ? SizedBox()
        : DiscoverSection(
            title: "Tags",
            child: _loading
                ? LoadingIndicator()
                : Wrap(
                    spacing: -8,
                    runSpacing: -25,
                    children: _tags,
                  ));
  }
}

class DiscoverTag extends StatelessWidget {
  const DiscoverTag(
      {Key? key,
      required this.id,
      required this.title,
      this.backgroundColor = Colors.red,
      this.materialColor = Colors.white,
      this.icon = LineIcons.hashtag,
      this.launchOnTap = true})
      : super(key: key);
  final int id;
  final String title;
  final Color backgroundColor;
  final Color materialColor;
  final IconData icon;
  final bool launchOnTap;

  factory DiscoverTag.fromJson(Map json) =>
      DiscoverTag(id: json['id'], title: json['title']);

  Future<void> _launchTagPostsPage(context) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => TagPostsPage(
                tagFilter: PostTagFilter(tagId: id, tagTitle: title))));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap:
            launchOnTap ? () async => await _launchTagPostsPage(context) : null,
        child: Chip(
            backgroundColor: backgroundColor,
            onDeleted: launchOnTap
                ? () async => await _launchTagPostsPage(context)
                : null,
            label: Text(title,
                style: TextStyle(color: materialColor, fontSize: 15)),
            deleteIcon: Icon(icon, color: materialColor),
            labelPadding: const EdgeInsets.symmetric(horizontal: 10)),
      ),
    );
  }
}
