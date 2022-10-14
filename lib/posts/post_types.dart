import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:sylvest_flutter/posts/pages/post_detail_page.dart';
import 'package:sylvest_flutter/services/mangers.dart';
import 'package:sylvest_flutter/posts/components/post_components.dart';
import 'package:expandable/expandable.dart';
import 'package:sylvest_flutter/posts/post_util.dart';

class MasterPost extends StatelessWidget {
  final MasterPostData data;
  bool isDetail;
  void Function(int? commendId, String? author) onCommentSelected;

  MasterPost(
      {required this.data,
      required this.isDetail,
      required this.onCommentSelected});

  factory MasterPost.fromJson(Map json) {
    return MasterPost(
      data: MasterPostData.fromJson(json),
      isDetail: false,
      onCommentSelected: (id, author) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (data.postType) {
      case PostType.Post:
        return Post(
          data: data,
          isDetail: isDetail,
          onCommentSelected: onCommentSelected,
        );
      case PostType.Project:
        return Project(
          data: data,
          isDetail: isDetail,
          onCommentSelected: onCommentSelected,
        );
      case PostType.Event:
        return Event(
          data: data,
          isDetail: isDetail,
          onCommentSelected: onCommentSelected,
        );
      default:
        throw Exception('Type not expected: ${data.postType}');
    }
  }
}

class Post extends MasterPost {
  final Color matterialColor = Colors.black87,
      backgroundColor = Colors.white,
      childColor = Colors.black12,
      innerChildColor = Colors.white,
      activatedColor = const Color(0xFF8d61ea);

  Post(
      {required MasterPostData data,
      required bool isDetail,
      required void Function(int? commendId, String? author) onCommentSelected})
      : super(
            data: data,
            isDetail: isDetail,
            onCommentSelected: onCommentSelected);

  Widget postButtons() {
    return Buttons(
        buttonColor: matterialColor,
        activatedColor: activatedColor,
        author: data.authorDetails.username,
        isLiked: data.requestData.isLiked,
        pk: data.postId,
        likes: data.likes,
        postId: data.postId,
        type: ButtonType.Post,
        isDetail: this.isDetail,
        onCommentSelected: onCommentSelected,
        commentId: null,
        comments: data.commentNum,
        likedByFollowing: data.likedByFollowing);
  }

  Widget postContent() {
    return Content(
      childColor: childColor,
      backgroundColor: backgroundColor,
      materialColor: matterialColor,
      innerChildColor: innerChildColor,
      data: data,
    );
  }

  Widget postHeader() {
    return Header(
      data.authorDetails.username,
      data.authorDetails.id,
      data.authorDetails.profileImage,
      matterialColor,
      postType: PostType.Post,
      commentId: null,
      availibleActions: data.requestData.allowedActions,
      postId: data.postId,
      communityId:
          data.communityDetails != null ? data.communityDetails!.id : null,
    );
  }

  Widget? communityTag() {
    if (data.communityDetails == null) return null;
    return CommunityTag(
      title: data.communityDetails!.title,
      image: data.communityDetails!.image,
      id: data.communityDetails!.id,
      color: activatedColor,
      textColor: Colors.white,
    );
  }

  Widget homePost(context, pk) {
    if (!isDetail) {
      return GestureDetector(
        onTap: () => {
          Navigator.push(context,
              MaterialPageRoute<void>(builder: (BuildContext context) {
            return PostDetailPage(pk);
          }))
        },
        child: PostContainer(
          community: communityTag(),
          header: postHeader(),
          isDetail: isDetail,
          content: postContent(),
          footer: postButtons(),
          pk: pk,
          color: backgroundColor,
          matterialColor: matterialColor,
          textColor: matterialColor,
        ),
      );
    }
    return PostContainer(
      community: communityTag(),
      header: postHeader(),
      isDetail: isDetail,
      content: postContent(),
      footer: postButtons(),
      pk: pk,
      color: backgroundColor,
      matterialColor: matterialColor,
      textColor: matterialColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return homePost(context, data.postId);
  }
}

class Project extends Post {
  @override
  final Color matterialColor = Colors.white,
      backgroundColor = const Color(0xFF733CE6),
      childColor = const Color(0xFF8d61ea),
      innerChildColor = const Color(0xFFaa89ef),
      activatedColor = Colors.white;

  @override
  Widget? communityTag() {
    if (data.communityDetails == null) return null;
    return CommunityTag(
      title: data.communityDetails!.title,
      image: data.communityDetails!.image,
      id: data.communityDetails!.id,
      color: childColor,
      textColor: activatedColor,
    );
  }

  Project(
      {required MasterPostData data,
      required bool isDetail,
      required void Function(int? commendId, String? author) onCommentSelected})
      : super(
            data: data,
            isDetail: isDetail,
            onCommentSelected: onCommentSelected);
}

class Event extends Post {
  Event(
      {required MasterPostData data,
      required bool isDetail,
      required void Function(int? commendId, String? author) onCommentSelected})
      : super(
            data: data,
            isDetail: isDetail,
            onCommentSelected: onCommentSelected);

  @override
  final Color matterialColor = Colors.white,
      backgroundColor = const Color(0xFFe6733c),
      childColor = const Color(0xFFf57d43),
      innerChildColor = const Color(0xFFe98c5e),
      activatedColor = Colors.white;

  @override
  Widget? communityTag() {
    if (data.communityDetails == null) return null;
    return CommunityTag(
      title: data.communityDetails!.title,
      image: data.communityDetails!.image,
      id: data.communityDetails!.id,
      color: childColor,
      textColor: activatedColor,
    );
  }

  Widget postContent() {
    return Content(
      childColor: childColor,
      backgroundColor: backgroundColor,
      materialColor: matterialColor,
      innerChildColor: innerChildColor,
      data: data,
    );
  }
}

class Comment extends StatefulWidget {
  final CommentData data;

  factory Comment.fromJson(Map json,
      void Function(int? commendId, String? author) onCommentSelected) {
    return Comment(
      data: CommentData.fromJson(json),
      onCommentSelected: onCommentSelected,
    );
  }

  void Function(int? commendId, String? author) onCommentSelected;

  Comment({
    required this.data,
    required this.onCommentSelected
  });

  @override
  State<Comment> createState() => CommentState();
}

class CommentState extends State<Comment> {
  late final _manager = CommentReplyManager(widget.data.commentId);
  final _controller = ExpandableController();
  bool _loading = false;
  late bool _canCallReplies = widget.data.hasReplies;
  List<Comment> _replies = [];

  final Color matterialColor = Colors.black87,
      backgroundColor = Colors.white,
      childColor = Colors.black12,
      innerChildColor = Colors.white,
      activatedColor = const Color(0xFF8d61ea);

  Widget postButtons() {
    return Buttons(
        buttonColor: matterialColor,
        activatedColor: activatedColor,
        author: widget.data.authorDetails.username,
        isLiked: widget.data.requestData.isLiked,
        pk: widget.data.commentId,
        likes: widget.data.likes,
        type: ButtonType.Comment,
        comments: widget.data.commentNum,
        isDetail: true,
        onCommentSelected: widget.onCommentSelected,
        likedByFollowing: [],
        commentId: widget.data.commentId,
        postId: widget.data.postId);
  }

  Widget postContent() {
    return Content(
      childColor: childColor,
      backgroundColor: backgroundColor,
      materialColor: matterialColor,
      innerChildColor: innerChildColor,
      data: widget.data,
    );
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _getLastComment() async {
    final reply = await _manager.getLastComment(
        context, widget.onCommentSelected);
    setState(() {
      _replies.add(reply);
    });
  }

  Future<List<Comment>> _getComments() async {
    return await _manager.getComments(
        context, widget.onCommentSelected);
  }

  Future<void> _onMoreReplies() async {
    if (_canCallReplies) {
      _canCallReplies = false;
      setState(() {
        _loading = true;
      });
      final newReplies = await _getComments();
      setState(() {
        _replies = newReplies;
      });
      setState(() {
        _loading = false;
      });
    }
    _controller.toggle();
  }

  Widget postHeader() {
    return Header(
        widget.data.authorDetails.username,
        widget.data.authorDetails.id,
        widget.data.authorDetails.profileImage,
        matterialColor,
        availibleActions: widget.data.requestData.allowedActions,
        postId: widget.data.postId,
        commentId: widget.data.commentId,
        postType: PostType.Comment,
        communityId: null);
  }

  Widget homePost() {
    return PostContainer(
      header: postHeader(),
      content: postContent(),
      footer: postButtons(),
      pk: widget.data.commentId,
      isDetail: false,
      color: backgroundColor,
      matterialColor: matterialColor,
      textColor: matterialColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    print("Has Replies: ${widget.data.hasReplies}");
    return GestureDetector(
      onTap: () async {
        await _onMoreReplies();
      },
      child: Column(
        children: [
          Row(
            children: [
              if (widget.data.relatedCommentId != null)
                SizedBox(
                  width: 20,
                  child: Center(
                      child: Container(
                    color: Colors.grey.shade400,
                    width: 2,
                    height: 150,
                  )),
                ),
              Expanded(
                child: homePost(),
              )
            ],
          ),
          if (_loading)
            LoadingIndicator(
              size: 20,
            ),
          Row(
            children: [
              if (widget.data.relatedCommentId != null)
                SizedBox(
                  width: 20,
                ),
              Expanded(
                  child: CommentReplies(
                      onCommentSelected: widget.onCommentSelected,
                      commentId: widget.data.commentId,
                      hasReplies: widget.data.hasReplies,
                      controller: _controller,
                      comments: _replies))
            ],
          )
        ],
      ),
    );
  }
}

class CommentReplies extends StatelessWidget {
  const CommentReplies(
      {Key? key,
      required this.comments,
      required this.commentId,
      required this.controller,
      required this.hasReplies,
      required this.onCommentSelected})
      : super(key: key);
  final List<Comment> comments;
  final int commentId;
  final void Function(int? id, String? name) onCommentSelected;
  final bool hasReplies;
  final ExpandableController controller;

  Widget _smallDot() {
    return Container(
      decoration:
          const BoxDecoration(shape: BoxShape.circle, color: Colors.black12),
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      height: 10,
      width: 10,
    );
  }

  Widget _showRepliesIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _smallDot(),
        _smallDot(),
        _smallDot(),
        const Text(
          "Show Replies",
          style: TextStyle(color: Colors.black26, fontFamily: 'Quicksand'),
        ),
        _smallDot(),
        _smallDot(),
        _smallDot(),
      ],
    );
  }

  Widget _expandable() {
    print("Has Replies 2: ${hasReplies}");
    return ExpandablePanel(
      controller: controller,
      collapsed: hasReplies ? _showRepliesIndicator() : SizedBox(),
      expanded: Container(
        child: Column(
          children: comments,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!hasReplies) return SizedBox();
    return GestureDetector(child: _expandable());
  }
}
