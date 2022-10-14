import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:localstorage/localstorage.dart';
import 'package:sylvest_flutter/modals/modals.dart';
import 'package:sylvest_flutter/subjects/communities/communities.dart';
import 'package:sylvest_flutter/discover/components/search_components.dart';
import 'package:sylvest_flutter/chain/expreince_detail_page.dart';
import 'package:sylvest_flutter/config/firebase_options.dart';
import 'package:sylvest_flutter/forms/form_responses.dart';
import 'package:sylvest_flutter/auth/login_page.dart';
import 'package:sylvest_flutter/notifications/notifications_page.dart';
import 'package:sylvest_flutter/posts/post_util.dart';
import 'package:sylvest_flutter/notifications/requests_page.dart';
import 'package:sylvest_flutter/subjects/subject_util.dart';
import 'dart:async';
import 'dart:io';
import 'package:sylvest_flutter/config/env.dart';
import 'package:sylvest_flutter/posts/post_types.dart';
import 'package:sylvest_flutter/subjects/user/profile_components.dart';
import 'dart:collection';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sylvest_flutter/subjects/user/profile_page.dart';

import '../discover/components/discover_components.dart';
import '../home/main_components.dart';

class API {
  static final API _api = API._internal();
  factory API() {
    return _api;
  }
  API._internal();

  static final Map<PostType, Map<String, Color>> colors = {
    PostType.Post: {
      'background': Colors.white,
      'matterial': const Color(0xFF733CE6),
      'secondary': Colors.black87,
      'child': Colors.grey.shade300,
      'inner': Colors.white
    },
    PostType.Event: {
      'background': const Color(0xFFe6733c),
      'matterial': Colors.white,
      'secondary': Colors.white,
      'child': const Color(0xFFf57d43),
      'inner': const Color(0xFFf59c42)
    },
    PostType.Project: {
      'background': const Color(0xFF733CE6),
      'matterial': Colors.white,
      'secondary': Colors.white,
      'child': const Color(0xFF8d61ea),
      'inner': const Color(0xFFaa89ef)
    },
  };

  static PostType postTypeFromString(String type) {
    switch (type) {
      case 'PO':
        return PostType.Post;
      case 'PR':
        return PostType.Project;
      case 'EV':
        return PostType.Event;
      default:
        throw Exception('Type not expected: $type');
    }
  }

  static List<int> safeStatus = const [200, 201];

  final LocalStorage storage = LocalStorage('temp');
  Map? loginCred;

  Future<Map?> getLoginCred() async {
    if (this.loginCred != null) {
      return this.loginCred;
    }
    final stored = await storage.getItem('login_cred');
    if (stored == null) return null;
    this.loginCred = json.decode(stored);
    return this.loginCred;
  }

  String? getAccessIfLoggedIn(loginCred) {
    if (loginCred == null) return null;
    return loginCred['access'];
  }

  Future<String> refreshToken(Map loginCred) async {
    final token = loginCred['refresh'];
    final response = await http.post(
        Uri.parse('${Env.URL_PREFIX}/auth/token/refresh/'),
        body: {'refresh': token!});
    final items = json.decode(utf8.decode(response.bodyBytes));
    //print(response.statusCode);
    if (response.statusCode == 401) {
      // refresh failed
      return loginCred['access'];
    }
    loginCred['refresh'] = items['refresh'];
    loginCred['access'] = items['access'];
    return items['access'];
  }

  Future<http.Response> getWithToken(String url, String token) async {
    return await http.get(Uri.parse(url), headers: {
      HttpHeaders.authorizationHeader: 'Bearer ${token}',
    });
  }

  Future<http.Response> postAndGetWithToken(
      String url, String token, body) async {
    return await http.post(Uri.parse(url),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer ${token}',
          HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        },
        body: jsonEncode(body));
  }

  Future<http.Response> postAndGetWithoutToken(String url, body) async {
    return await http.post(Uri.parse(url),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        },
        body: jsonEncode(body));
  }

  Future<http.Response> getWithoutToken(String url) async {
    return await http.get(Uri.parse(url));
  }

  Future<http.Response> patchTo(String url, String token, body) async {
    return await http.patch(Uri.parse(url),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
          HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        },
        body: jsonEncode(body));
  }

  Future<http.Response> delete(String url, String token, int pk) async {
    return await http.delete(Uri.parse(url), headers: {
      HttpHeaders.authorizationHeader: 'Bearer $token',
      HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
    });
  }

  void displayError(String errorMessage, context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(errorMessage)));
  }

  void displaySuccess(String successMessage, context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(successMessage),
      backgroundColor: Colors.green,
    ));
  }

  Future<void> deleteLoginCred() async {
    try {
      this.loginCred = null;
      await storage.deleteItem('login_cred');
    } catch (e) {}
  }

  Future getResponseWithToken(context, url, loginCred) async {
    var response;

    if (loginCred != null) {
      response = await getWithToken(url, getAccessIfLoggedIn(loginCred)!);
      if (response.statusCode == 401) {
        response = await getWithToken(url, await refreshToken(loginCred));
        if (response.statusCode == 401) {
          displayError("Logged out", context);
          deleteLoginCred();
        }
      }

      try {
        return json.decode(utf8.decode(response.bodyBytes));
      } catch (e) {
        displayError("Something went wrong", context);
        return {};
      }
    }
  }

  Future getResponseItems(context, url) async {
    var response;

    final loginCred = await getLoginCred();

    if (loginCred != null) {
      response = await getWithToken(url, getAccessIfLoggedIn(loginCred)!);
    } else {
      try {
        response = await getWithoutToken(url);
      } catch (e) {
        print(e);
        displayError("Cannot connect to server.", context);
        return;
      }
    }
    if (loginCred != null) {
      if (response.statusCode == 401) {
        response = await getWithToken(url, await refreshToken(loginCred));
        if (response.statusCode == 401) {
          response = await getWithoutToken(url);
          if (context != null) displayError("Logged out", context);
          deleteLoginCred();
        }
      }
    } else {
      response = await getWithoutToken(url);
    }

    if (response == null) {
      if (context != null) displayError("Something went wrong", context);
    }
    try {
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      if (context != null) displayError("Something went wrong", context);
      return {};
    }
  }

  Future postAndGetResponseItems(context, url, loginCred, body,
      {String? successMessage}) async {
    var response;

    if (loginCred != null) {
      response =
          await postAndGetWithToken(url, getAccessIfLoggedIn(loginCred)!, body);
    } else {
      try {
        response = await postAndGetWithoutToken(url, body);
      } catch (e) {
        displayError("Logged out", context);
        return;
      }
    }

    if (response.statusCode == 401) {
      response =
          await postAndGetWithToken(url, await refreshToken(loginCred), body);
      if (response.statusCode == 401) {
        //response = await getWithoutToken(url);
        displayError("Logged out", context);
        deleteLoginCred();
      }
    }

    if (safeStatus.contains(response.statusCode) && successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.green,
        content: Text(successMessage),
      ));
    }
    print(response.body);
    try {
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      print(e);
      displayError("Something went wrong", context);
      return {};
    }
  }

  Future patchItems(context, url, loginCred, body) async {
    var response;
    print(url);
    if (loginCred != null) {
      response = await patchTo(url, getAccessIfLoggedIn(loginCred)!, body);
      if (response.statusCode == 401) {
        response = await patchTo(url, await refreshToken(loginCred), body);
        print(url);
        if (response.statusCode == 401) {
          await deleteLoginCred();
          displayError("You need to login first!", context);
          Navigator.popAndPushNamed(context, '/user');
        }
      }
      try {
        return json.decode(utf8.decode(response.bodyBytes));
      } catch (e) {
        displayError("Something went wrong", context);
        return {};
      }
    }
  }

  Future deleteItem(context, url, pk, loginCred) async {
    var response;
    if (loginCred != null) {
      response = await delete(url, getAccessIfLoggedIn(loginCred)!, pk);
      if (response.statusCode == 401) {
        response = await delete(url, await refreshToken(loginCred), pk);
        if (response.statusCode == 401) {
          await deleteLoginCred();
          displayError("You need to login first!", context);
          //Navigator.popAndPushNamed(context, '/user');
          return false;
        }
      }
      return true;
    }
    return false;
  }

  Future<ExpreincePageData> verifyChainPage(
      context, String frontImage, String backImage) async {
    final url = "${Env.BASE_URL_PREFIX}/chainpages/verify_account/";
    final loginCred = await getLoginCred();

    final response = await patchItems(
        context, url, loginCred, {'front': frontImage, 'back': backImage});
    return ExpreincePageData.fromJson(response);
  }

  Future<int?> stakeLevels(context) async {
    final url = '${Env.URL_PREFIX}/chainpages/stake_levels/';
    final loginCred = await getLoginCred();

    final items = await postAndGetResponseItems(context, url, loginCred, null);
    try {
      //print(items);
      return items['staked_levels'];
    } catch (e) {
      //return await getWalletAddress(context);
      displayError("Something went wrong", context);
      return null;
    }
  }

  Future<List<MasterPost>> getMasterPostsList(context) async {
    final url = '${Env.URL_PREFIX}/masterposts';
    //print(loginCred);
    final items = await getResponseItems(context, url);
    List<MasterPost> posts = items['results'].map<MasterPost>((json) {
      return MasterPost.fromJson(json);
    }).toList();
    return posts;
  }

  Future<List> getTransfarables(context) async {
    final url = '${Env.URL_PREFIX}/chainpages/transferable_users';

    final response = await getResponseItems(context, url);
    return response;
  }

  Future<List<Community>> getCommunitiesList(context) async {
    final url = '${Env.URL_PREFIX}/communities';

    final items = await getResponseItems(context, url);
    List<Community> communities = items.map<Community>((json) {
      return Community.fromJson(json, () {}, false);
    }).toList();
    return communities;
  }

  static LatLng postionFromString(String str) {
    final cordsStr = str.split(',');
    //print(cordsStr);
    final lat = double.parse(cordsStr[0]);
    final lng = double.parse(cordsStr[1]);
    return LatLng(lat, lng);
  }

  Future<Map> sendTokenToUser(int id, double amount, context) async {
    final loginCred = await getLoginCred();
    if (loginCred != null) {
      final user_id = loginCred['user']['pk'];
      final url = '${Env.URL_PREFIX}/chainpages/$user_id/send_token_to_user/';
      final data = {'to': id, 'amount': amount};

      final items =
          await postAndGetResponseItems(context, url, loginCred, data);
      return items;
    }
    return {};
  }

  Future<Map> sendTokenToAddress(String address, double amount, context) async {
    final loginCred = await getLoginCred();
    if (loginCred != null) {
      final url = '${Env.URL_PREFIX}/chainpages/send_token_to_address/';
      final data = {'address': address, 'amount': amount};

      final items =
          await postAndGetResponseItems(context, url, loginCred, data);
      return items;
    }
    return {};
  }

  Future registerDevice(context) async {
    final url = '${Env.URL_PREFIX}/device';
    final loginCred = await getLoginCred();
    final deviceInfo = DeviceInfoPlugin();
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    final regToken = await messaging.getToken();

    Map body = {};

    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;

        body = {
          'device_id': androidInfo.androidId,
          'type': 'android',
          'name': androidInfo.model,
          'active': true,
          'registeration_token': regToken
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        body = {
          'device_id': iosInfo.identifierForVendor,
          'type': 'ios',
          'name': iosInfo.name,
          'active': true,
          'registeration_token': regToken
        };
      } else {
        final webInfo = await deviceInfo.webBrowserInfo;
        body = {
          'device_id': webInfo.appCodeName,
          'type': 'web',
          'name': webInfo.appName,
          'active': true,
          'registeration_token': regToken
        };
      }
      print(body);
      final items =
          await postAndGetResponseItems(context, url, loginCred, body);
      return items;
    } catch (e) {
      print(e);
    }
  }

  Future<List<RetreivablePost>> getRetrievableProjects(context) async {
    final url = '${Env.URL_PREFIX}/projects/retrievable_projects';

    final items = await getResponseItems(context, url);
    return items
        .map<RetreivablePost>((json) => RetreivablePost.fromJson(json))
        .toList();
  }

  Future<Map> fundProject(context, int id, double amount) async {
    final loginCred = await getLoginCred();
    final url = '${Env.URL_PREFIX}/projects/$id/fund/';
    final data = {'amount': amount};

    return await postAndGetResponseItems(context, url, loginCred, data);
  }

  Future<Map> retrieveFromProject(context, int id) async {
    final loginCred = await getLoginCred();
    final url = '${Env.URL_PREFIX}/projects/$id/retrieve_token/';

    return await postAndGetResponseItems(context, url, loginCred, null);
  }

  Future<List<MasterPost>> getEventsList(context) async {
    final url = '${Env.URL_PREFIX}/events';

    final items = await getResponseItems(context, url);
    List<MasterPost> posts = items.map<MasterPost>((json) {
      return MasterPost.fromJson(json);
    }).toList();
    return posts;
  }

  Future<List<FollowRequest>> getFollowRequests(context) async {
    if (loginCred != null) {
      final url = '${Env.URL_PREFIX}/profiles/requests';

      final response = await getResponseItems(context, url);
      return response
          .map<FollowRequest>(
              (request) => FollowRequest(userData: UserData.fromJson(request)))
          .toList();
    }
    return [];
  }

  Future<int> getFollowRequestCount(context) async {
    if (loginCred != null) {
      final url = '${Env.URL_PREFIX}/profiles/request_count';

      final response = await getResponseItems(context, url);
      return response['count'];
    }
    return 0;
  }

  Future<ExpreincePageData?> getChainPage(
      context, void Function(int page) setPage) async {
    final loginCred = await getLoginCred();
    if (loginCred != null) {
      String url = '${Env.URL_PREFIX}/chainpages/${loginCred['user']['pk']}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 401) {
        await deleteLoginCred();
        Navigator.pushNamed(context, 'login');
        return null;
      }
      final items = json.decode(utf8.decode(response.bodyBytes));
      return ExpreincePageData.fromJson(items);
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProfilePage(
                    Colors.white,
                    const Color(0xFF733CE6),
                    const Color(0xFF733CE6),
                    setPage: setPage,
                    popAgain: true,
                  )));
      return null;
    }
  }

  Future<FirebaseApp> initializeFirebase() async {
    return await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }

  Future<List<MasterPost>> getProjectsList(context) async {
    final url = '${Env.URL_PREFIX}/projects';

    final items = await getResponseItems(context, url);
    List<MasterPost> posts = items['results'].map<MasterPost>((json) {
      return MasterPost.fromJson(json);
    }).toList();
    return posts;
  }

  Future<ProfileCard?> getProfile(
      context, void Function(int page) setPage, bool popAgain) async {
    final Color backgroundColor = Colors.white,
        matterialColor = const Color(0xFF733CE6),
        secondaryColor = Colors.black;

    Map? loginCred = await getLoginCred();
    if (loginCred == null) {
      await Future.delayed(Duration.zero, () async {
        try {
          loginCred = await Navigator.push(
              context,
              MaterialPageRoute<Map>(
                  builder: (context) => LoginPage(
                        backgroundColor,
                        matterialColor,
                        secondaryColor,
                        popAgain: popAgain,
                        setPage: setPage,
                      )));
        } catch (e) {
          print(e);
          displayError("Something went wrong", context);
        }
      });
    }
    if (loginCred == null) {
      //displayError("Login failed", context);
      return null;
    }

    final access = loginCred!['access'];
    final refresh = loginCred!['refresh'];
    print(loginCred);
    final Map user = loginCred!['user'];

    final response =
        await http.get(Uri.parse('${Env.URL_PREFIX}/profiles/${user['pk']}/'));

    if (!safeStatus.contains(response.statusCode)) {
      await storage.deleteItem('login_cred');
      return null;
    }
    print(response.body);
    final items = json.decode(utf8.decode(response.bodyBytes));
    ProfileCard profile = ProfileCard.fromJson(items, setPage);
    items['refresh'] = refresh;
    items['access'] = access;
    items['user'] = user;

    try {
      await storage.setItem('login_cred', json.encode(items));
      await registerDevice(context);
    } catch (e) {
      print(e);
    }

    return profile;
  }

  Future<Map> getPostBuilderData(context) async {
    final loginCred = await getLoginCred();
    print("here");
    print(loginCred);

    return {'communities': loginCred == null ? [] : loginCred['communities']};
  }

  Future<List<UserData>> getRecommendedUsers(context) async {
    if (loginCred != null) {
      final url =
          Env.BASE_URL_PREFIX + "/profiles/recommended_users/?detailed=0";

      final items = await getResponseItems(context, url);
      return items
          .map<UserData>((user) => UserData(
              id: user['id'],
              username: user['username'],
              profileImage: user['image']))
          .toList();
    }
    return [];
  }

  Future<List<ChatSharableData>> getRecommendedChatRooms(context) async {
    if (loginCred != null) {
      final url = Env.BASE_URL_PREFIX + "/rooms/recommended_chats";

      final items = await getResponseItems(context, url);
      return items
          .map<ChatSharableData>((chat) => ChatSharableData.fromJson(chat))
          .toList();
    }
    return [];
  }

  Future<List<ProfileData>> getRecommendedProfiles(context) async {
    if (loginCred != null) {
      final url =
          Env.BASE_URL_PREFIX + "/profiles/recommended_users/?detailed=1";

      final items = await getResponseItems(context, url);
      return items
          .map<ProfileData>((user) => ProfileData.fromJson(user))
          .toList();
    }
    return [];
  }

  Future<List<NotificationWidget>> getNotifications(
      context, void Function(int value) setPage) async {
    if (loginCred == null) {
      setPage(3);
      return [];
    }
    final url = '${Env.URL_PREFIX}/profiles/notifications';

    final response = await getResponseItems(context, url);

    return (response as List)
        .map((data) => NotificationWidget.fromMap(data))
        .toList();
  }

  Future<Map> getUnreadNotifications(context) async {
    final url = "${Env.BASE_URL_PREFIX}/profiles/unread_notifications";
    print(url);

    final response = await getResponseItems(context, url);
    return response;
  }

  Future<List<DiscoverTag>> getTags(context) async {
    final url = "${Env.BASE_URL_PREFIX}/tags/recommended";

    final response = await getResponseItems(context, url);
    return response
        .map<DiscoverTag>((tag) => DiscoverTag.fromJson(tag))
        .toList();
  }

  Future deletePost(context, int id) async {
    final url = '${Env.URL_PREFIX}/masterposts/$id/';
    final loginCred = await getLoginCred();

    final bool response = await deleteItem(context, url, id, loginCred);
    if (response)
      displaySuccess('Post deleted successfuly', context);
    else
      displayError('Something went wrong', context);
  }

  Future deleteComment(context, int id) async {
    final url = '${Env.URL_PREFIX}/comments/$id/';
    final loginCred = await getLoginCred();

    final bool response = await deleteItem(context, url, id, loginCred);
    if (response)
      displaySuccess('Comment deleted successfuly', context);
    else
      displayError('Something went wrong', context);
  }

  Future updateProfile(BuildContext context, int pk, profile) async {
    final profileUrl = '${Env.URL_PREFIX}/profiles/$pk/';
    final userProfile = '${Env.URL_PREFIX}/auth/user/';
    final loginCred = await getLoginCred();

    final newUsername = profile.remove('username');
    final newFirstName = profile.remove('user_first_name');
    final newLastName = profile.remove('user_last_name');

    await patchItems(context, profileUrl, loginCred, profile);
    await patchItems(context, userProfile, loginCred, {
      if (newUsername != null) "username": newUsername,
      "first_name": newFirstName,
      "last_name": newLastName
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      backgroundColor: Colors.green,
      content: Text('Profile updated successfully!'),
    ));
  }

  Future<SmallProfileImage> getProfilePicture(Color color) async {
    if (this.loginCred != null) {
      return SmallProfileImage.fromJson(this.loginCred!, color);
    }
    return SmallProfileImage(null, color);
  }

  Future<ProfileCard> getUser(int pk, context) async {
    final url = '${Env.URL_PREFIX}/profiles/$pk/';

    final items = await getResponseItems(context, url);
    if (!items.keys.contains("id")) {
      //Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Not Found")));
    }
    return ProfileCard.fromJson(items, (int) {});
  }

  Future<Map<String, dynamic>?> getLoginResponse(
      username, email, password, context) async {
    final response = await http.post(Uri.parse('${Env.URL_PREFIX}/auth/login/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          "username": username,
          "email": email,
          "password": password
        }));
    print(response.statusCode);
    if (response.statusCode == 400) {
      displayError('Unable to login with the provided credencials', context);
      return null;
    }
    final items = await json.decode(response.body);
    items['refresh'] = items['refresh_token'];
    items['access'] = items['access_token'];
    return items;
  }

  Future getRegisterResponse(
      context, username, email, password, password2) async {
    if (password != password2) {
      displayError('Passwords do not match!', context);
      return null;
    }

    var response =
        await http.post(Uri.parse('${Env.URL_PREFIX}/auth/register/'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, String>{
              "username": username,
              "email": email,
              "password1": password,
              "password2": password2
            }));

    LinkedHashMap<String, dynamic> items =
        json.decode(utf8.decode(response.bodyBytes));
    print(items);
    if (!safeStatus.contains(response.statusCode)) {
      items.forEach((key, value) {
        (value as List).forEach((error) {
          displayError(error, context);
        });
      });
    }
    //print(items);
    return response.statusCode;
  }

  Future<Map> forgotPassword(context, String email) async {
    final url = Env.BASE_URL_PREFIX + "/auth/password-reset/";
    final loginCred = await getLoginCred();

    final response = await postAndGetResponseItems(
        context, url, loginCred, {'email': email});
    return response;
  }

  Future<Map> confirmNewPassword(context, String newPass, String newPass2,
      String uid, String token) async {
    final url = Env.BASE_URL_PREFIX + "auth/password/reset/confirm";
    final loginCred = await getLoginCred();

    final response = await postAndGetResponseItems(context, url, loginCred, {
      'new_password1': newPass,
      'new_password2': newPass2,
      'uid': uid,
      'token': token
    });
    return response;
  }

  Future<MasterPost> getPostDetail(context, int pk) async {
    final url = '${Env.URL_PREFIX}/masterposts/$pk';

    final items = await getResponseItems(context, url);
    if (!items.keys.contains("id")) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Not Found")));
    }
    return MasterPost.fromJson(items);
  }

  Future<Community> getCommunityDetail(
      context, int pk, void Function() onRefresh) async {
    final url = '${Env.URL_PREFIX}/communities/$pk';

    final Map items = await getResponseItems(context, url);
    if (!items.keys.contains("id")) {
      //Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Not Found")));
    }
    return Community.fromJson(items, onRefresh, true);
  }

  Future<List<FormResponse>> getFormResponses(context, int postId) async {
    final url = '${Env.URL_PREFIX}/formresponses/?post=$postId';

    final items = await getResponseItems(context, url);
    return (items as List)
        .map<FormResponse>((response) => FormResponse.fromJson(response))
        .toList();
  }

  Future<String> getLogoutResponse() async {
    await deleteLoginCred();
    var response = await http.post(Uri.parse('${Env.URL_PREFIX}/auth/logout/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{"name": "Logout"}));
    var items = json.decode(utf8.decode(response.bodyBytes));
    return items['detail'];
  }

  Future likePost(pk, context) async {
    final loginCred = await getLoginCred();
    if (loginCred == null) {
      Navigator.pushNamed(context, '/user');
      return;
    }
    //final url = '${Env.URL_PREFIX}/masterposts/like/$pk';
    final url = '${Env.URL_PREFIX}/masterposts/$pk/like/';
    final body = {'action': 'LIKE', 'pk': pk};

    return await patchItems(context, url, loginCred, body);
  }

  Future contribute(pk, context) async {
    final loginCred = await getLoginCred();
    final url = '${Env.URL_PREFIX}/projects/$pk/contribute/';
    final body = {'action': 'CONTRIBUTE', 'pk': pk};

    return await patchItems(context, url, loginCred, body);
  }

  Future changeCommunityRole(
      int communityId, int otherUser, String updatedRole, context) async {
    final loginCred = await getLoginCred();
    final url = '${Env.URL_PREFIX}/communities/$communityId/';
    final body = {
      'action': 'roles',
      'community_id': communityId,
      'other_user': otherUser,
      'updated_role': updatedRole
    };

    await patchItems(context, url, loginCred, body);
  }

  Future banFromCommunity(int communityId, int otherUser, context) async {
    final loginCred = await getLoginCred();
    final url = '${Env.URL_PREFIX}/communities/$communityId/';
    final body = {
      'action': 'users|ban',
      'community_id': communityId,
      'other_user': otherUser,
    };

    await patchItems(context, url, loginCred, body);
  }

  Future removePostFromCommunity(int communityId, int postId, context) async {
    final loginCred = await getLoginCred();
    final url = '${Env.URL_PREFIX}/communities/$communityId/';
    final body = {
      'action': 'posts|remove',
      'community_id': communityId,
      'post_id': postId,
    };

    await patchItems(context, url, loginCred, body);
  }

  Future postFormResponse(Map formResponse, context) async {
    final loginCred = await getLoginCred();
    final url = '${Env.URL_PREFIX}/formresponses/';

    return await postAndGetResponseItems(context, url, loginCred, formResponse);
  }

  Future publishComment(Map comment, int pk, context) async {
    final loginCred = await getLoginCred();
    final url = '${Env.URL_PREFIX}/comments/';

    return await postAndGetResponseItems(context, url, loginCred, comment,
        successMessage: 'Comment published successfully');
  }

  Future attend(pk, context) async {
    final loginCred = await getLoginCred();
    final url = '${Env.URL_PREFIX}/events/$pk/attend/';
    final body = {'action': 'ATTEND', 'pk': pk};

    final response = await patchItems(context, url, loginCred, body);
    return response;
  }

  Future likeComment(pk, context) async {
    final loginCred = await getLoginCred();
    final url = '${Env.URL_PREFIX}/comments/$pk/like/';
    final body = {'action': 'LIKE_COMMENT', 'pk': pk};

    await patchItems(context, url, loginCred, body);
  }

  Future<FollowStatus> follow(pk, context) async {
    final loginCred = await getLoginCred();
    final url = '${Env.URL_PREFIX}/profiles/$pk/follow/';
    final body = {'action': 'FOLLOW', 'pk': pk};
    final response = await patchItems(context, url, loginCred, body);

    return intToFollowStatus[response['response']]!;
  }

  Future acceptFollow(pk, context) async {
    final loginCred = await getLoginCred();
    final url = '${Env.URL_PREFIX}/profiles/$pk/follow_request_action/';
    final body = {'action': 'ACCEPT_FOLLOW', 'pk': pk};

    await patchItems(context, url, loginCred, body);
  }

  Future declineFollow(pk, context) async {
    final loginCred = await getLoginCred();
    final url = '${Env.URL_PREFIX}/profiles/$pk/follow_request_action/';
    final body = {'action': 'DECLINE_FOLLOW', 'pk': pk};

    await patchItems(context, url, loginCred, body);
  }

  Future join(pk, context) async {
    final loginCred = await getLoginCred();
    final url = '${Env.URL_PREFIX}/communities/$pk/join/';
    final body = {'action': 'JOIN', 'pk': pk};

    await patchItems(context, url, loginCred, body);
  }

  Future<Map> publishPost(Map post, context) async {
    String _url() {
      switch (post['post_type']) {
        case 'EV':
          return '/events';
        case 'PR':
          return '/projects';
        default:
          return '/masterposts';
      }
    }

    final loginCred = await getLoginCred();
    final url = '${Env.URL_PREFIX}${_url()}/';

    final response = await postAndGetResponseItems(
        context, url, loginCred, post,
        successMessage: 'Post published successfully');
    print(response);
    return response;
  }

  Future<Map> postPostImage(context, Map image) async {
    final loginCred = await getLoginCred();
    final url = '${Env.URL_PREFIX}/postimages/';

    final response =
        await postAndGetResponseItems(context, url, loginCred, image);
    return response;
  }

  Future<Map> postPostVideo(context, Map video) async {
    final loginCred = await getLoginCred();
    final url = '${Env.URL_PREFIX}/postvideos/';

    final response =
        await postAndGetResponseItems(context, url, loginCred, video);
    return response;
  }

  Future patchPostMedia(context, int pk, List images, List videos) async {
    final loginCred = await getLoginCred();
    if (loginCred != null) {
      final url = '${Env.URL_PREFIX}/masterposts/$pk/attach_media/';
      final body = {'images': images, 'videos': videos};

      final response = await patchItems(context, url, loginCred, body);
      return MasterPost.fromJson(response);
    }
  }

  Future<MasterPost?> addPostTags(
      context, int postId, List<String> tags) async {
    final loginCred = await getLoginCred();
    if (loginCred != null) {
      final url = '${Env.URL_PREFIX}/masterposts/$postId/add_tags/';
      final body = {'tags': tags};

      final response = await patchItems(context, url, loginCred, body);
      return MasterPost.fromJson(response);
    }
    return null;
  }

  Future<ProfileCard?> addProfileInterests(
      context, void Function(int) setPage, List<String> interests) async {
    final loginCred = await getLoginCred();
    if (loginCred != null) {
      final url = '${Env.URL_PREFIX}/profiles/edit_interests/';
      final body = {'interests': interests};

      final response = await patchItems(context, url, loginCred, body);
      return ProfileCard.fromJson(response, setPage);
    }
    return null;
  }

  Future<List<SearchTilePost>> searchPosts(String searchItem) async {
    var response = await http
        .get(Uri.parse('${Env.URL_PREFIX}/masterposts/?search=$searchItem'));
    var items = json.decode(utf8.decode(response.bodyBytes));

    List<SearchTilePost> posts = items['results'].map<SearchTilePost>((json) {
      return SearchTilePost.fromJson(json);
    }).toList();
    return posts;
  }

  Future<List<SearchTileProfile>> searchProfiles(String searchItem) async {
    var response = await http
        .get(Uri.parse('${Env.URL_PREFIX}/profiles/?search=$searchItem'));
    var items = json.decode(utf8.decode(response.bodyBytes));

    List<SearchTileProfile> posts = items.map<SearchTileProfile>((json) {
      return SearchTileProfile.fromJson(json);
    }).toList();
    return posts;
  }

  Future<List<SearchTileCommunity>> searchCommunities(String searchItem) async {
    var response = await http
        .get(Uri.parse('${Env.URL_PREFIX}/communities/?search=$searchItem'));
    var items = json.decode(utf8.decode(response.bodyBytes));

    List<SearchTileCommunity> posts =
        items['results'].map<SearchTileCommunity>((json) {
      return SearchTileCommunity.fromJson(json);
    }).toList();
    return posts;
  }

  Future<List<DiscoverTag>> searchTag(String searchItem) async {
    var response =
        await http.get(Uri.parse('${Env.URL_PREFIX}/tags/?search=$searchItem'));
    var items = json.decode(utf8.decode(response.bodyBytes));

    List<DiscoverTag> posts = items.map<DiscoverTag>((json) {
      return DiscoverTag.fromJson(json);
    }).toList();
    return posts;
  }

  Future<Map<String, List>> discoverSearch(String searchItem) async {
    return {
      'posts': await searchPosts(searchItem),
      'profiles': await searchProfiles(searchItem),
      'communities': await searchCommunities(searchItem),
      'tags': await searchTag(searchItem)
    };
  }

  Future<Map?> getCurrentUsernameAndImage() async {
    var stored = await storage.getItem('login_cred');
    var loginCred;
    Map result = {};
    if (stored != null) {
      loginCred = json.decode(stored);
      try {
        result['username'] = loginCred['user']!['username']!;
      } catch (e) {
        result['username'] = loginCred['username'];
      }
      result['image'] = loginCred['image'];
      return result;
    }
    return null;
  }

  Future createCommunity(Map community, context) async {
    final loginCred = await getLoginCred();
    final url = '${Env.URL_PREFIX}/communities/';

    final response =
        await postAndGetResponseItems(context, url, loginCred, community);

    return response;
  }
}
