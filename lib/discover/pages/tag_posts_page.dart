import 'package:flutter/material.dart';
import 'package:sylvest_flutter/discover/components/discover_components.dart';
import 'package:sylvest_flutter/home/pages.dart';

class TagPostsPage extends StatefulWidget {
  final PostTagFilter tagFilter;

  const TagPostsPage({Key? key, required this.tagFilter}) : super(key: key);

  @override
  State<TagPostsPage> createState() => TagPostsPageState();
}

class TagPostsPageState extends State<TagPostsPage> {
  final _postsKey = GlobalKey<PostsPageState>();

  bool _isRefreshing = false;
  bool _isLoading = false;
  bool _appbarVisible = false;

  late final _postsPage = PostsPage(key: _postsKey, filter: widget.tagFilter);

  void refresh() async {
    if (_isRefreshing) return;
    await Future.delayed(Duration(milliseconds: 100));
    setState(() {
      _isRefreshing = true;
    });
    _postsKey.currentState!.refresh();
    setState(() {
      _isRefreshing = false;
    });
  }

  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      refresh();
    });
  }

  void _onLoad() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    _postsKey.currentState!.loadMore();
    setState(() {
      _isLoading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >
              60 + notification.metrics.minScrollExtent) {
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
            refresh();
          } else if (notification.metrics.pixels >
              notification.metrics.maxScrollExtent) {
            _onLoad();
          }
          return false;
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomScrollView(
              physics: AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              slivers: [
                SliverAppBar(
                  snap: true,
                  floating: true,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  leading: IconButton(
                    icon: Icon(Icons.keyboard_arrow_left),
                    color: const Color(0xFF733CE6),
                    onPressed: () => Navigator.pop(context),
                  ),
                  backgroundColor: Colors.white,
                  actions: [],
                  title: DiscoverTag(
                      title: widget.tagFilter.tagTitle,
                      launchOnTap: false,
                      id: widget.tagFilter.tagId),
                ),
                SliverList(delegate: SliverChildListDelegate([_postsPage]))
              ],
            ),
            if (_isRefreshing) _refreshingWidget()
          ],
        ),
      ),
    );
  }
}
