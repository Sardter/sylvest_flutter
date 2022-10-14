import 'package:flutter/material.dart';
import 'package:flutter_placeholder_textlines/placeholder_lines.dart';
import 'package:shimmer/shimmer.dart';

import '../posts/pages/events_map_page.dart';
import '../posts/pages/projects_page.dart';
import '../posts/post_types.dart';
import '../services/mangers.dart';
import '../subjects/communities/communities.dart';
import 'home.dart';

class LoadableListState {
  Manager get manager => throw UnimplementedError();

  List<Widget> get items => throw UnimplementedError();
  bool get loading => throw UnimplementedError();
  bool get refreshing => throw UnimplementedError();

  Future<void> refresh() async {
    throw UnimplementedError();
  }

  Future<void> loadMore() async {
    throw UnimplementedError();
  }
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Colors.black12,
      ),
    );
  }
}

class PostFilter {}

class PostTagFilter extends PostFilter {
  final int tagId;
  final String tagTitle;

  PostTagFilter({required this.tagId, required this.tagTitle});
}

class PostsPage extends StatefulWidget {
  const PostsPage({Key? key, this.filter}) : super(key: key);
  final PostFilter? filter;

  @override
  State<PostsPage> createState() => PostsPageState();
}

class PostsPageState extends State<PostsPage> implements LoadableListState {
  final manager = PostManager();

  List<MasterPost> items = [];
  bool loading = false;
  bool refreshing = false;

  Future<List<MasterPost>> _getPosts() async {
    final _manager = manager as PostManager;
    switch (widget.filter.runtimeType) {
      case PostTagFilter:
        final _filter = widget.filter as PostTagFilter;
        return await _manager.getPostsOfTag(context, _filter.tagId);
      default:
        return await _manager.getPosts(context);
    }
  }

  Future<void> refresh() async {
    if (refreshing) return;
    setState(() {
      refreshing = true;
    });
    manager.reset();
    final posts = await _getPosts();
    if (mounted)
      setState(() {
        items = posts;
        refreshing = false;
      });
  }

  Future<void> loadMore() async {
    if (loading || !manager.next()) return;
    setState(() {
      loading = true;
    });
    final posts = await _getPosts();
    setState(() {
      items += posts;
      loading = false;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      refresh();
    });
    super.initState();
  }

  @override
  Widget build(context) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        child: refreshing
            ? LoadingPosts()
            : Column(
                children: [
                  if (items.isNotEmpty)
                    ...items.map<Widget>((e) {
                      e.isDetail = false;
                      return e;
                    }).toList()
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("No posts just yet!",
                            style: TextStyle(color: Colors.grey))
                      ],
                    ),
                  if (loading) LoadingWidget()
                ],
              ));
  }
}

class EventsPage extends StatefulWidget {
  const EventsPage({Key? key}) : super(key: key);

  @override
  State<EventsPage> createState() => EventsPageState();
}

class EventsPageState extends State<EventsPage> implements LoadableListState {
  final manager = EventsManager();

  List<MasterPost> items = [];
  List<EventSmallCard> _eventsWithLocation = [];
  bool loading = false;
  bool refreshing = false;

  Future<void> refresh() async {
    if (refreshing) return;
    setState(() {
      refreshing = true;
    });
    manager.reset();
    final posts = await (manager as EventsManager).getEvents(context);
    final locations =
        await (manager as EventsManager).getEventsWithLocations(context);
    setState(() {
      items = posts;
      _eventsWithLocation = locations;
      refreshing = false;
    });
  }

  Future<void> loadMore() async {
    if (loading || !manager.next()) return;
    setState(() {
      loading = true;
    });
    final posts = await (manager as PostManager).getPosts(context);
    setState(() {
      items += posts;
      loading = false;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      refresh();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: refreshing
          ? LoadingPosts()
          : Column(children: <Widget>[
              EventsSmallMap(eventsWithLocation: _eventsWithLocation),
              const SizedBox(height: 10),
              if (items.isNotEmpty)
                ...items
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("No events just yet!",
                        style: TextStyle(color: Colors.grey))
                  ],
                ),
              if (loading) LoadingWidget()
            ]),
    );
  }
}

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({Key? key}) : super(key: key);

  @override
  State<ProjectsPage> createState() => ProjectsPageState();
}

class ProjectsPageState extends State<ProjectsPage>
    implements LoadableListState {
  final manager = ProjectManager();

  List<MasterPost> items = [];
  bool loading = false;
  bool refreshing = false;

  double _max = 100;

  Future<void> refresh() async {
    if (refreshing) return;
    setState(() {
      refreshing = true;
    });
    manager.reset();
    final posts = await (manager as ProjectManager).getProjects(context);
    setState(() {
      items = posts;
      refreshing = false;
    });
  }

  Future<void> loadMore() async {
    if (loading || !manager.next()) return;
    setState(() {
      loading = true;
    });
    final posts = await (manager as ProjectManager).getProjects(context);
    setState(() {
      items += posts;
      loading = false;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      refresh();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: refreshing
          ? LoadingPosts()
          : Column(
              children: <Widget>[
                if (items.isNotEmpty) ...[
                  MostFundedProjects(
                    mostFunded: items.take(5).map((e) {
                      final fund = e.data.projectFields!.totalFunded;
                      if (fund > _max) _max = fund;
                      return MostFundedData(
                          title: e.data.title,
                          authorImage: e.data.authorDetails.profileImage,
                          currentFund: fund,
                          id: e.data.postId);
                    }).toList(),
                    max: _max,
                  ),
                  ...items
                ] else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("No projects just yet!",
                          style: TextStyle(color: Colors.grey))
                    ],
                  ),
                if (loading) LoadingWidget()
              ],
            ),
    );
  }
}

class CommunitiesPage extends StatefulWidget {
  const CommunitiesPage({Key? key}) : super(key: key);

  @override
  State<CommunitiesPage> createState() => CommunitiesPageState();
}

class CommunitiesPageState extends State<CommunitiesPage>
    implements LoadableListState {
  final manager = CommunityManager();

  List<Community> items = [];
  bool loading = false;
  bool refreshing = false;

  Future<void> refresh() async {
    if (refreshing) return;
    setState(() {
      refreshing = true;
    });
    manager.reset();
    final posts = await (manager as CommunityManager).getCommunities(context);
    setState(() {
      items = posts;
      refreshing = false;
    });
  }

  Future<void> loadMore() async {
    if (loading || !manager.next()) return;
    setState(() {
      loading = true;
    });
    final posts = await (manager as CommunityManager).getCommunities(context);
    setState(() {
      items += posts;
      loading = false;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      refresh();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        child: refreshing
            ? LoadingPosts()
            : Column(
                children: [
                  if (items.isNotEmpty)
                    ...items
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("No communities just yet!",
                            style: TextStyle(color: Colors.grey))
                      ],
                    ),
                  if (loading) LoadingWidget()
                ],
              ));
  }
}

class LoadingPosts extends StatelessWidget {
  const LoadingPosts();

  Widget emptyContent() {
    return const PlaceholderLines(count: 4);
  }

  Widget emptyHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.grey.shade300,
        ),
        const SizedBox(
          width: 10,
        ),
        Container(
          decoration: BoxDecoration(
              //borderRadius: BorderRadius.circular(5),
              color: Colors.grey.shade200),
          height: 15,
          width: 70,
        )
      ],
    );
  }

  Widget emptyCard() {
    return Container(
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                spreadRadius: 1,
                offset: Offset.fromDirection(0.75))
          ],
          gradient: LinearGradient(
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
            colors: <Color>[Colors.white, Colors.grey.shade100],
          ),
          borderRadius: BorderRadius.circular(10)),
      width: double.maxFinite,
      margin: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
      padding: const EdgeInsets.all(15),
      child: Shimmer.fromColors(
        child: Column(
          children: [
            emptyHeader(),
            const SizedBox(
              height: 10,
            ),
            emptyContent()
          ],
        ),
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
      ),
    );
  }

  @override
  Widget build(context) {
    final List<Widget> posts = List.generate(20, (index) => emptyCard());

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(5),
      children: posts,
    );
  }
}
