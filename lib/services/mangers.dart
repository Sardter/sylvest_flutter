import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sylvest_flutter/discover/components/discover_components.dart';
import 'package:sylvest_flutter/notifications/notifications_page.dart';
import 'package:sylvest_flutter/posts/post_util.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:sylvest_flutter/subjects/communities/communities.dart';
import 'package:sylvest_flutter/config/env.dart';
import 'package:sylvest_flutter/posts/post_types.dart';
import 'package:sylvest_flutter/subjects/subject_util.dart';
import 'package:sylvest_flutter/chain/transfers_page.dart';

import '../posts/pages/events_map_page.dart';

class Manager {
  final _api = API();
  int _pageIndex = 1;
  bool _hasNext = false;
  bool _canCallNext = false;

  bool next() {
    if (_canCallNext && _hasNext) {
      _pageIndex++;
      _canCallNext = false;
      return true;
    }
    return false;
  }

  void reset() {
    _pageIndex = 1;
    _hasNext = false;
    _canCallNext = false;
  }
}

class TransferManager extends Manager {
  final String _url = Env.BASE_URL_PREFIX + "/transferrequests";

  Future<List<TransferRequest>> getTransfers(
      context,
      void Function(int) onDismiss,
      List<GlobalKey<TransferRequestState>> keys,
      int verificationRights,
      void Function() refresh) async {
    _canCallNext = true;
    final url = '$_url/?page=$_pageIndex';

    final transferData = await _api.getResponseItems(context, url);
    _hasNext = transferData["has_next"];

    return (transferData["results"] as List).map<TransferRequest>((transfer) {
      final key = GlobalKey<TransferRequestState>();
      keys.add(key);
      return TransferRequest(
        key: key,
        onDismiss: onDismiss,
        data: TransferRequestData.fromJson(transfer),
        verificationRight: verificationRights,
        refresh: refresh,
      );
    }).toList();
  }

  Future<TransferRequest> verifyTransfer(
      context,
      int transferId,
      void Function(int) onDismiss,
      int verificationRights,
      void Function() refresh) async {
    final url = "$_url/$transferId/verify_transfer/";
    final loginCred = await API().getLoginCred();
    final response = await API().patchItems(context, url, loginCred, null);
    return TransferRequest(
      data: TransferRequestData.fromJson(response),
      onDismiss: onDismiss,
      verificationRight: verificationRights,
      refresh: refresh,
    );
  }
}

class PostManager extends Manager {
  final String _url = Env.BASE_URL_PREFIX + '/masterposts/?page=';

  Future<List<MasterPost>> getPosts(context) async {
    _canCallNext = true;
    final url = '$_url$_pageIndex';

    final postData = await _api.getResponseItems(context, url);
    _hasNext = postData['has_next'];

    return (postData['results'] as List)
        .map<MasterPost>((post) => MasterPost.fromJson(post))
        .toList();
  }

  Future<List<MasterPost>> getPostsOfTag(context, int tagId) async {
    _canCallNext = true;
    final url = Env.BASE_URL_PREFIX + "/tags/$tagId/posts/?page=$_pageIndex";

    final postData = await _api.getResponseItems(context, url);
    _hasNext = postData['has_next'];

    return (postData['results'] as List)
        .map<MasterPost>((post) => MasterPost.fromJson(post))
        .toList();
  }

  Future<List<MasterPost>> getPostsOfUser(int userId, context) async {
    _canCallNext = true;
    final url = '$_url$_pageIndex&author=$userId&sort=date';

    final postData = await _api.getResponseItems(context, url);
    _hasNext = postData['has_next'];

    return (postData['results'] as List)
        .map<MasterPost>((post) => MasterPost.fromJson(post))
        .toList();
  }

  Future<List<MasterPost>> getPostsOfCommunity(int communityId, context) async {
    _canCallNext = true;
    final url = '$_url$_pageIndex&community=$communityId&sort=date';

    final postData = await _api.getResponseItems(context, url);
    _hasNext = postData['has_next'];

    return (postData['results'] as List)
        .map<MasterPost>((post) => MasterPost.fromJson(post))
        .toList();
  }
}

class ProjectManager extends Manager {
  final String _url = Env.BASE_URL_PREFIX + '/projects/?page=';

  Future<List<MasterPost>> getProjects(context) async {
    _canCallNext = true;
    final url = '$_url$_pageIndex';

    final postData = await _api.getResponseItems(context, url);
    _hasNext = postData['has_next'];

    return (postData['results'] as List)
        .map<MasterPost>((post) => MasterPost.fromJson(post))
        .toList();
  }
}

class EventsManager extends Manager {
  final String _url = Env.BASE_URL_PREFIX + '/events/?page=';
  final String _mapsUrl = Env.BASE_URL_PREFIX + '/events/with_location';

  Future<List<MasterPost>> getEvents(context) async {
    _canCallNext = true;
    final url = '$_url$_pageIndex';

    final postData = await _api.getResponseItems(context, url);
    _hasNext = postData['has_next'];

    return (postData['results'] as List)
        .map<MasterPost>((post) => MasterPost.fromJson(post))
        .toList();
  }

  LatLng postionFromString(String str) {
    final cordsStr = str.split(',');
    //print(cordsStr);
    final lat = double.parse(cordsStr[0]);
    final lng = double.parse(cordsStr[1]);
    return LatLng(lat, lng);
  }

  Future<List<EventSmallCard>> getEventsWithLocations(context) async {
    final postData = await _api.getResponseItems(context, _mapsUrl);

    return (postData as List)
        .map<EventSmallCard>((event) => EventSmallCard.fromJson(event))
        .toList();
  }
}

class CommunityManager extends Manager {
  final String _url = Env.BASE_URL_PREFIX + '/communities/?page=';

  Future<List<Community>> getCommunities(context) async {
    _canCallNext = true;
    final url = '$_url$_pageIndex';

    final postData = await _api.getResponseItems(context, url);
    _hasNext = postData['has_next'];

    return (postData['results'] as List)
        .map<Community>(
            (community) => Community.fromJson(community, () {}, false))
        .toList();
  }

  Future<List<DiscoverCommunity>> getDiscoverCommunities(context) async {
    _canCallNext = true;
    final url = '$_url$_pageIndex';

    final postData = await _api.getResponseItems(context, url);
    _hasNext = postData['has_next'];

    return (postData['results'] as List)
        .map<DiscoverCommunity>(
            (community) => DiscoverCommunity.fromJson(community))
        .toList();
  }
}

class CommentManager extends Manager {
  final int postId;
  final String _url = Env.BASE_URL_PREFIX + '/comments/';
  CommentManager(this.postId);

  Future<List<Comment>> getComments(context,
      void Function(int? commendId, String? author) onCommentSelected) async {
    _canCallNext = true;
    final url = '$_url?page=$_pageIndex&post=$postId';

    final postData = await _api.getResponseItems(context, url);
    _hasNext = postData['has_next'];

    return (postData['results'] as List)
        .map<Comment>((comment) => Comment.fromJson(comment, onCommentSelected))
        .toList();
  }
}

class CommentReplyManager extends Manager {
  final int commentId;
  final String _url = Env.BASE_URL_PREFIX + '/comments';
  CommentReplyManager(this.commentId);

  Future<Comment> getLastComment(context,
      void Function(int? commendId, String? author) onCommentSelected) async {
    final url = '$_url/$commentId/last_reply/';

    final postData = await _api.getResponseItems(context, url);

    return Comment.fromJson(postData, onCommentSelected);
  }

  Future<List<Comment>> getComments(context,
      void Function(int? commendId, String? author) onCommentSelected) async {
    _canCallNext = true;
    final url = '$_url/$commentId/replies/?index=$_pageIndex';

    final postData = await _api.getResponseItems(context, url);
    print(postData);
    _hasNext = postData['has_next'];

    return (postData['results'] as List)
        .map<Comment>((comment) => Comment.fromJson(comment, onCommentSelected))
        .toList();
  }
}

enum UserManagerType {
  Followers,
  Following,
  Likes,
  CommentLikes,
  Contributors,
  Attendees
}

class UserManager extends Manager {
  final UserManagerType type;
  final _url = Env.BASE_URL_PREFIX;
  late Map<UserManagerType, Future<List<UserData>> Function(dynamic, int)>
      _mapper = {
    UserManagerType.Attendees: _getAttendees,
    UserManagerType.Contributors: _getContributors,
    UserManagerType.Followers: _getFollowers,
    UserManagerType.Following: _getFollowing,
    UserManagerType.Likes: _getLikes,
    UserManagerType.CommentLikes: _getCommentLikes
  };

  UserManager({required this.type});

  Future<List<UserData>> _getUsers(context, String url) async {
    _canCallNext = true;

    final userData = await _api.getResponseItems(context, url);
    _hasNext = userData['has_next'];

    return (userData['results'] as List)
        .map<UserData>((user) => UserData.fromJson(user))
        .toList();
  }

  Future<List<UserData>> _getFollowers(context, int profileId) async {
    return await _getUsers(
        context, '$_url/profiles/$profileId/followers/?page=$_pageIndex');
  }

  Future<List<UserData>> _getFollowing(context, int profileId) async {
    return await _getUsers(
        context, '$_url/profiles/$profileId/following/?page=$_pageIndex');
  }

  Future<List<UserData>> _getLikes(context, int postId) async {
    return await _getUsers(
        context, '$_url/masterposts/$postId/likes/?page=$_pageIndex');
  }

  Future<List<UserData>> _getCommentLikes(context, int commentId) async {
    return await _getUsers(
        context, '$_url/comments/$commentId/likes/?page=$_pageIndex');
  }

  Future<List<UserData>> _getContributors(context, int postId) async {
    return await _getUsers(
        context, '$_url/projects/$postId/contributors/?page=$_pageIndex');
  }

  Future<List<UserData>> _getAttendees(context, int postId) async {
    return await _getUsers(
        context, '$_url/events/$postId/attendees/?page=$_pageIndex');
  }

  Future<List<UserData>> getUser(context, int? id) async {
    if (id == null) {
      id = (await API().getLoginCred())!['user']['pk'];
    }
    return await _mapper[this.type]!(context, id!);
  }
}

class SmallCommunityManager extends Manager {
  final _url = Env.BASE_URL_PREFIX + "/profiles";

  Future<List<ProfileCommunity>> getCommunities(
      context, int? profileId, bool queryAll) async {
    _canCallNext = true;
    final loginCred = await _api.getLoginCred();
    if (profileId == null && loginCred != null) {
      profileId = loginCred['user']['pk'];
    }
    final _all = queryAll ? 1 : 0;
    final url = "$_url/$profileId/communities/?page=$_pageIndex&all=$_all";

    final communitiesData = await _api.getResponseItems(context, url);
    _hasNext = communitiesData['has_next'];

    return (communitiesData['results'] as List)
        .map<ProfileCommunity>(
            (community) => ProfileCommunity.fromJson(community))
        .toList();
  }
}

class RolledUserManager extends Manager {
  final _url = Env.BASE_URL_PREFIX + "/communities";

  Future<List<RolledUser>> getMembers(
      context, int communityId, bool queryAll) async {
    _canCallNext = true;
    final _all = queryAll ? 1 : 0;
    final url = "$_url/$communityId/members/?page=$_pageIndex&all=$_all";

    final rolledData = await _api.getResponseItems(context, url);
    _hasNext = rolledData['has_next'];

    return (rolledData['results'] as List)
        .map<RolledUser>((member) => RolledUser.fromJson(member))
        .toList();
  }
}

class NotificationManager extends Manager {
  final _url = Env.BASE_URL_PREFIX + "/profiles/notifications";

  Future<List<NotificationWidget>> getNotifications(context) async {
    _canCallNext = true;
    final url = "$_url/?page=$_pageIndex";

    final rolledData = await _api.getResponseItems(context, url);
    _hasNext = rolledData['has_next'];

    return (rolledData['results'] as List)
        .map<NotificationWidget>(
            (notification) => NotificationWidget.fromMap(notification))
        .toList();
  }
}
