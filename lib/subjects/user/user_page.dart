import 'package:flutter/material.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:sylvest_flutter/services/mangers.dart';
import 'package:sylvest_flutter/subjects/user/profile_components.dart';

import '../../services/image_service.dart';

class UserPage extends StatefulWidget {
  final int user;
  const UserPage(this.user);

  @override
  UserPageState createState() => UserPageState();
}

class UserPageState extends State<UserPage> {
  final Color backgroundColor = Colors.white,
      materialColor = const Color(0xFF733CE6),
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
        print("refreshing user");
        _isRefreshing = true;
      });

      final newPosts = await _postManager.getPostsOfUser(widget.user, context);

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
      final newPosts = await _postManager.getPostsOfUser(widget.user, context);
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
    return FutureBuilder<ProfileCard>(
      future: API().getUser(widget.user, context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return LoadingDetailPage();
        }
        final userProfile = snapshot.data!;
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
                color: materialColor,
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
                            url: userProfile.data.image,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userProfile.data.generalAttributes.username,
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
              userProfile,
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >
              120 + notification.metrics.minScrollExtent) {
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
