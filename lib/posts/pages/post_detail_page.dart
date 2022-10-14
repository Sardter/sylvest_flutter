import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:sylvest_flutter/services/mangers.dart';
import 'package:sylvest_flutter/posts/components/post_components.dart';
import 'package:sylvest_flutter/posts/post_types.dart';
import 'package:sylvest_flutter/posts/post_util.dart';
import 'package:sylvest_flutter/subjects/user/user_page.dart';

import '../../services/image_service.dart';

class PostDetailPage extends StatefulWidget {
  PostDetailPage(this.pk);
  final int pk;
  final GlobalKey<PostDetailPageState> _key = GlobalKey();

  @override
  State<PostDetailPage> createState() => PostDetailPageState();
}

class PostDetailPageState extends State<PostDetailPage> {
  late final _commentManager = CommentManager(widget.pk);
  bool _isRefreshing = false;
  bool _isLoading = false;
  bool _appbarVisible = false;

  void refresh() async {
    if (!_isRefreshing) {
      _commentManager.reset();

      setState(() {
        _isRefreshing = true;
        _comments = [];
      });

      final newComments = await _commentManager.getComments(
          context, _onCommentSelected);

      if (mounted)
      setState(() {
        _comments = newComments;
        _selectedCommentId = null;
        _selectedCommentAuthor = null;
        _isRefreshing = false;
      });
    }
  }

  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      refresh();
    });
  }

  List<Comment> _comments = [];
  int? _selectedCommentId;
  String? _selectedCommentAuthor;

  void _onCommentSelected(int? commentId, String? author) {
    setState(() {
      _selectedCommentAuthor = author;
      _selectedCommentId = commentId;
    });
  }

  void _onLoad() async {
    if (!_isLoading && _commentManager.next()) {
      setState(() {
        _isLoading = true;
        _comments;
      });
      final newComments = await _commentManager.getComments(
          context, _onCommentSelected);
      await Future.delayed(Duration(seconds: 1));
      setState(() {
        _comments.removeLast();
        _comments += newComments;
        _isLoading = false;
      });
    }
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

  Widget _loadingWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Colors.black12,
      ),
    );
  }

  String _titleShortner(String title) {
    if (title.length < 20) return title;
    return title.substring(0, 17) + "...";
  }

  Widget _sliver() {
    return FutureBuilder(
        future: API().getPostDetail(context, widget.pk),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return LoadingDetailPage();
          }
          final post = snapshot.data as MasterPost;
          post.isDetail = true;
          post.onCommentSelected = _onCommentSelected;
          final colors =
              API.colors[post.data.postType]!;
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
                  color: colors['secondary'],
                  onPressed: () => Navigator.pop(context),
                ),
                backgroundColor: colors['background'],
                actions: [
                  if (_appbarVisible)
                    MoreMenu(
                        buttonColor: colors['secondary']!,
                        actions: post.data.requestData.allowedActions!,
                        postId: post.data.postId,
                        postTypes: PostType.Post,
                        communityId: post.data.communityDetails == null
                            ? null
                            : post.data.communityDetails!.id)
                ],
                title: !_appbarVisible
                    ? null
                    : InkWell(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    UserPage(post.data.authorDetails.id))),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SylvestImageProvider(
                              url: post.data.authorDetails.profileImage,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post.data.authorDetails.username,
                                    style: TextStyle(
                                        color: colors['secondary'],
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                                Text(
                                  _titleShortner(post.data.title),
                                  style: TextStyle(color: colors['secondary']),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
              ),
              SliverList(
                  delegate: SliverChildListDelegate([
                post,
                Padding(
                  padding: const EdgeInsets.only(
                      left: 5, right: 5, top: 5, bottom: 60),
                  child: Column(
                    children: [
                      ..._comments,
                      if (_isLoading) _loadingWidget()
                    ],
                  ),
                )
              ]))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: widget._key,
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
            _sliver(),
            if (_isRefreshing) _refreshingWidget(),
            CommentNav(
              postId: widget.pk,
              onPostRefresh: refresh,
              selectedCommentAuthor: _selectedCommentAuthor,
              selectedCommentId: _selectedCommentId,
            )
          ],
        ),
      ),
    );
  }
}

class CommentNav extends StatefulWidget {
  CommentNav(
      {Key? key,
      required this.postId,
      this.selectedCommentId,
      this.selectedCommentAuthor,
      required this.onPostRefresh})
      : super(key: key);
  final int postId;
  int? selectedCommentId;
  String? selectedCommentAuthor;
  final void Function() onPostRefresh;

  @override
  State<CommentNav> createState() => _CommentNavState();
}

class _CommentNavState extends State<CommentNav> {
  final _textController = TextEditingController();

  Future<void> _publish(context, text) async {
    if (await API().getLoginCred() == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You must login to comment"), backgroundColor: Colors.red,));
      return;
    }
    Map comment = {
      'content': {
        'building_blocks': [
          {
            'type': 'paragraph',
            'data': text
          }
        ]
      },
      'post': widget.postId,
      'related_comment': widget.selectedCommentId
    };

    if (text.isNotEmpty) {
      print(comment);
      await API().publishComment(comment, widget.postId, context);
      setState(() {
        _textController.text = "";
      });
      widget.onPostRefresh();
      FocusManager.instance.primaryFocus?.unfocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Comment can not be empty!')));
    }
  }

  Widget _field(context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.grey.shade300, borderRadius: BorderRadius.circular(30)),
      child: TextFormField(
        controller: _textController,
        onChanged: (text) => setState(() {}),
        decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            hintText: "Share your thoughts",
            border: InputBorder.none),
        minLines: 1,
        keyboardType: TextInputType.multiline,
        maxLines: null,
      ),
    );
  }

  Widget _selectedCommentIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(
        children: [
          const Text(
            "Replying to: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            "@" + widget.selectedCommentAuthor!,
            style: TextStyle(
                fontFamily: 'Quicksand', color: const Color(0xFF733CE6)),
          ),
          Expanded(
              child: IconButton(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.zero,
            icon: Icon(LineIcons.times),
            iconSize: 17,
            onPressed: () {
              setState(() {
                widget.selectedCommentId = null;
                widget.selectedCommentAuthor = null;
              });
            },
          ))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
        bottom: 0,
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(color: Colors.black12, spreadRadius: 2, blurRadius: 5)
              ]),
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              if (widget.selectedCommentId != null) _selectedCommentIndicator(),
              Row(
                children: [
                  Expanded(child: _field(context)),
                  if (_textController.text.isNotEmpty)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          primary: const Color(0xFF733CE6),
                          padding: const EdgeInsets.all(10),
                          shape: CircleBorder()),
                      child: Icon(LineIcons.share),
                      onPressed: _textController.text.isEmpty
                          ? null
                          : () async =>
                              await _publish(context, _textController.text),
                    ),
                ],
              )
            ],
          ),
        ));
  }
}
