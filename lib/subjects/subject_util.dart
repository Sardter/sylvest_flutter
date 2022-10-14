import 'package:sylvest_flutter/posts/post_util.dart';

class SubjectData {
  final int id;
  final String? title;
  final Map? info;
  final String? about;
  final String? image;
  final String? banner;
  final int posts;

  SubjectData(
      {required this.id,
      required this.title,
      required this.info,
      required this.about,
      required this.posts,
      required this.image,
      required this.banner});
}

class ProfilePost {
  final int id;
  final String title;
  final String author;
  final String authorImage;

  ProfilePost(
      {required this.id,
      required this.title,
      required this.author,
      required this.authorImage});

  factory ProfilePost.fromJson(Map json) {
    return ProfilePost(
        id: json['id'],
        title: json['title'],
        author: json['author'],
        authorImage: json['image']);
  }
}

class ProfileCommunity {
  final int id;
  final String title;
  final String? image;
  final String? master;

  ProfileCommunity(
      {required this.id,
      required this.title,
      required this.image,
      required this.master});

  factory ProfileCommunity.fromJson(Map json) {
    return ProfileCommunity(
        id: json['id'],
        title: json['title'],
        image: json['image'],
        master: json['master']);
  }
}

enum FollowStatus { NotFollowing, RequestSent, Following, UnFollowed }

Map<int, FollowStatus> intToFollowStatus = {
  0: FollowStatus.NotFollowing,
  1: FollowStatus.RequestSent,
  2: FollowStatus.Following,
  3: FollowStatus.UnFollowed
};

class ProfileGeneralAttributes {
  final String username;
  final FollowStatus isFollowed;
  final bool isPrivate;
  bool isOwner;

  ProfileGeneralAttributes(
      {required this.username,
      required this.isFollowed,
      required this.isPrivate,
      required this.isOwner});

  factory ProfileGeneralAttributes.fromJson(Map json) {
    return ProfileGeneralAttributes(
        username: json['username'],
        isFollowed: intToFollowStatus[json['follow_status']]!,
        isPrivate: json['is_private'],
        isOwner: json['is_owner']);
  }
}

class ChainDetails {
  final String address;
  final double balance;

  const ChainDetails({required this.address, required this.balance});

  factory ChainDetails.fromJson(Map json) {
    return ChainDetails(
        address: json['address'], balance: double.parse(json['balance']));
  }
}

class ProfileData extends SubjectData {
  final List<Map>? interests;
  final int followers;
  final int following;
  final int contributing;
  final int attending;
  final int communities;
  final String firstName;
  final String lastName;
  final String? gender;
  final String? address;
  final ChainDetails? chainDetails;
  final ProfileGeneralAttributes generalAttributes;

  ProfileData(
      {required this.interests,
      required this.followers,
      required this.following,
      required this.firstName,
      required this.lastName,
      required this.gender,
      required this.address,
      required this.contributing,
      required this.attending,
      required this.communities,
      required this.generalAttributes,
      required this.chainDetails,
      required int id,
      required String? title,
      required String? about,
      required String? image,
      required String? banner,
      required int posts,
      required Map? info})
      : super(
            id: id,
            about: about,
            title: title,
            image: image,
            posts: posts,
            banner: banner,
            info: info);

  factory ProfileData.fromJson(Map json) {
    return ProfileData(
        interests:
            json['interests'] != null ? json['interests'].cast<Map>() : null,
        followers: json['followers'],
        following: json['following'],
        contributing: json['contributing'],
        attending: json['attending'],
        posts: json['posts'],
        communities: json['communities'],
        generalAttributes:
            ProfileGeneralAttributes.fromJson(json['general_attributes']),
        id: json['id'],
        title: json['title'],
        about: json['about'],
        image: json['image'],
        firstName: json['first_name'],
        chainDetails: json['chain_details'] == null
            ? null
            : ChainDetails.fromJson(json['chain_details']),
        lastName: json['last_name'],
        gender: json['gender'],
        address: json['address'],
        banner: json['banner'],
        info: json['info']);
  }
}

enum Roll { Admin, Executive, Moderator, Member, None, NotMember }

enum CommunityAction { Roles, Ban }

Map<String, CommunityAction> strToCommunityAction = {
  "roles": CommunityAction.Roles,
  "users|ban": CommunityAction.Ban
};

Map<String, Roll> strToCommunityRoll = {
  "Not a member": Roll.NotMember,
  "None": Roll.None,
  "Member": Roll.Member,
  "Executive": Roll.Executive,
  "Admin": Roll.Admin,
  "Moderator": Roll.Moderator
};

class RolledUser extends UserData implements Comparable {
  final Map<Roll, int> _rollToInt = const {
    Roll.None: 0,
    Roll.NotMember: -1,
    Roll.Member: 1,
    Roll.Moderator: 2,
    Roll.Executive: 3,
    Roll.Admin: 4
  };

  const RolledUser(
      {required int id,
      required String username,
      required this.allowedActions,
      required this.role,
      required String? profileImage})
      : super(id: id, username: username, profileImage: profileImage);

  final Roll role;
  final List<CommunityAction> allowedActions;

  factory RolledUser.fromJson(Map json) {
    return RolledUser(
        id: json['id'],
        username: json['username'],
        allowedActions: json['allowed_actions']
            .map<CommunityAction>((action) => strToCommunityAction[action]!)
            .toList(),
        role: strToCommunityRoll[json['role']]!,
        profileImage: json['image']);
  }

  @override
  int compareTo(other) {
    return -1 * _rollToInt[this.role]!.compareTo(_rollToInt[other.role]!);
  }
}

class CommunityData extends SubjectData {
  CommunityData(
      {required int id,
      required String title,
      required Map? info,
      required String? about,
      required int posts,
      required String? image,
      required String? banner,
      required this.members,
      required this.subCommunities,
      required this.founder,
      required this.isJoined,
      required this.masterCommunity,
      required this.shortDescription})
      : super(
            id: id,
            title: title,
            info: info,
            about: about,
            posts: posts,
            image: image,
            banner: banner);

  final int subCommunities;
  final ProfileCommunity? masterCommunity;
  final UserData founder;
  final String shortDescription;
  final int members;
  final bool isJoined;

  factory CommunityData.fromJson(Map json) {
    return CommunityData(
        id: json['id'],
        title: json['title'],
        info: json['info'],
        about: json['about'],
        posts: json['posts'],
        image: json['image'],
        banner: json['banner'],
        members: json['members'],
        subCommunities: json['sub_communities'],
        founder: UserData.fromJson(json['founder']),
        masterCommunity: json['master_community_info'] == null
            ? null
            : ProfileCommunity.fromJson(json['master_community_info']),
        shortDescription: json['short_description'],
        isJoined: json['is_joined']);
  }
}
