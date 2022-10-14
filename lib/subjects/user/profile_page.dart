import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:sylvest_flutter/services/mangers.dart';
import 'package:sylvest_flutter/posts/post_types.dart';
import 'package:sylvest_flutter/subjects/user/profile_components.dart';
import 'package:sylvest_flutter/settings/settings_page.dart';

class ProfilePage extends StatefulWidget {
  final Color backgroundColor, matterialColor, secondaryColor;
  final void Function(int page) setPage;
  final bool popAgain;
  const ProfilePage(
      this.backgroundColor, this.matterialColor, this.secondaryColor,
      {required this.setPage, required this.popAgain});

  @override
  ProfilePageState createState() =>
      ProfilePageState(backgroundColor, matterialColor, secondaryColor);
}

class ProfilePageState extends State<ProfilePage> {
  final Color backgroundColor, matterialColor, secondaryColor;

  ProfilePageState(
      this.backgroundColor, this.matterialColor, this.secondaryColor);

  final _postManager = PostManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _onRefresh();
    });
  }

  bool _isRefreshing = false;
  bool _isLoading = false;
  ProfileCard? _profileCard;

  List<Widget> _posts = [];

  void _onRefresh() async {
    if (!_isRefreshing) {
      _postManager.reset();
      setState(() {
        _isRefreshing = true;
      });

      _profileCard =
          await API().getProfile(context, widget.setPage, widget.popAgain);
      if (_profileCard == null) {
        widget.setPage(0);
        return;
      }
      _profileCard!.data.generalAttributes.isOwner = true;
      final newPosts =
          await _postManager.getPostsOfUser(_profileCard!.data.id, context);

      Future.delayed(Duration(seconds: 1), () {
        if (mounted)
          setState(() {
            _posts = newPosts.cast<Widget>();
            _isRefreshing = false;
          });
      });
    }
  }

  void _onLoad() async {
    if (_profileCard != null && !_isLoading && _postManager.next()) {
      setState(() {
        _isLoading = true;
        _posts.cast<Widget>();
        _posts += [_loadingWidget()];
      });
      final newPosts =
          await _postManager.getPostsOfUser(_profileCard!.data.id, context);

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
        top: 50,
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
    return _profileCard == null ? LoadingIndicator() : CustomScrollView(
      physics:
      AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        SliverList(
            delegate: SliverChildListDelegate([
              _profileCard!,
              Container(
                padding: const EdgeInsets.all(5),
                child: FutureBuilder<List<MasterPost>>(
                  future:
                  _postManager.getPostsOfUser(_profileCard!.data.id, context),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      //return LoadingDetailPage();
                      return LoadingIndicator();
                    }
                    final posts = snapshot.data!;
                    if (_posts.isEmpty) _posts = posts.cast<Widget>();
                    return Column(
                      children: _posts +
                          [
                            SizedBox(
                              height: 50,
                            )
                          ],
                    );
                  },
                ),
              )
            ]))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /* bottomNavigationBar:
          BottomNav(backgroundColor, matterialColor, secondaryColor), */
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: backgroundColor,
        centerTitle: true,
        title: Text('Profile',
            style: TextStyle(
              color: matterialColor,
              fontFamily: 'Quicksand',
            )),
        actions: <Widget>[
          IconButton(
              onPressed: () => {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SettingsPage(
                                  setPage: widget.setPage,
                                )))
                  },
              icon: const Icon(LineIcons.userCog, color: Color(0xFF733CE6))),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
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
