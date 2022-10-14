import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sylvest_flutter/posts/pages/post_detail_page.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:sylvest_flutter/config/env.dart';
import 'package:sylvest_flutter/services/mangers.dart';
import 'package:sylvest_flutter/posts/components/post_components.dart';
import '../../services/image_service.dart';
import '../post_util.dart';

class EventsMapPage extends StatelessWidget {
  final Color backgroundColor, matterialColor, secondaryColor;
  EventsMapPage(this.backgroundColor, this.matterialColor, this.secondaryColor);

  final CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();
  final _defaultPos = const CameraPosition(
    target: LatLng(31, 31),
    zoom: 2,
  );
  final _eventManager = EventsManager();

  /* BitmapDescriptor customIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange); */

  Widget map(context) {
    /* BitmapDescriptor.fromAssetImage(
            ImageConfiguration.empty, 'assets/images/event_marker3.png')
        .then((value) => {customIcon = value}); */
    return FutureBuilder<List<EventSmallCard>>(
      future: _eventManager.getEventsWithLocations(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: SizedBox(
            height: 50,
            width: 50,
            child: CircularProgressIndicator(
              color: Color(0xFF733CE6),
            ),
          ));
        }
        final eventsWithLocation = snapshot.data!;
        return Stack(
          children: <Widget>[
            GoogleMap(
              mapToolbarEnabled: false,
              compassEnabled: false,
              zoomControlsEnabled: false,
              onTap: (position) {
                _customInfoWindowController.hideInfoWindow!();
              },
              onCameraMove: (position) {
                _customInfoWindowController.onCameraMove!();
              },
              onMapCreated: (GoogleMapController controller) async {
                controller.setMapStyle(Env.MAP_STYLE);
                _customInfoWindowController.googleMapController = controller;
              },
              markers: eventsWithLocation.map<Marker>((event) {
                final postion = API.postionFromString(event.location);
                return Marker(
                    markerId: MarkerId(event.id.toString()),
                    position: postion,
                    onTap: () {
                      _customInfoWindowController.addInfoWindow!(
                          event, postion);
                    });
              }).toSet(),
              mapType: MapType.normal,
              initialCameraPosition: _defaultPos,
            ),
            CustomInfoWindow(
              controller: _customInfoWindowController,
              height: 275,
              width: 270,
              offset: 50,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_left,
              color: Color(0xFF733CE6),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          backgroundColor: backgroundColor,
          centerTitle: true,
          title: Text('Events',
              style: TextStyle(
                color: matterialColor,
                fontFamily: 'Quicksand',
              )),
        ),
        body: map(context));
  }
}

class EventSmallCard extends StatelessWidget {
  final String title, location;
  final UserData authorDetails;
  final List<UserData> attendies;
  final int id;
  final bool isAttending;
  final DateTime date;

  const EventSmallCard(
      {required this.attendies,
        required this.authorDetails,
        required this.title,
        required this.isAttending,
        required this.id,
        required this.date,
        required this.location});

  factory EventSmallCard.fromJson(Map json) {
    return EventSmallCard(
        attendies: json['attendies']
            .map<UserData>((attendie) => UserData.fromJson(attendie))
            .toList(),
        authorDetails: UserData.fromJson(json['author_details']),
        title: json['title'],
        isAttending: json['is_attending'],
        location: json['location'],
        id: json['id'],
        date: DateTime.parse(json['date']));
  }

  String shortenTitle(String title) {
    if (title.length >= 14) {
      return title.substring(0, 14) + "...";
    } else {
      return title;
    }
  }

  @override
  Widget build(context) {
    return GestureDetector(
      onTap: () => {
        Navigator.push(context,
            MaterialPageRoute<void>(builder: (BuildContext context) {
              return PostDetailPage(id);
            }))
      },
      child: Container(
        decoration: BoxDecoration(
            boxShadow: const [
              BoxShadow(color: Colors.white, spreadRadius: 3, blurRadius: 10)
            ],
            gradient: LinearGradient(
                begin: Alignment.bottomRight,
                end: Alignment.topLeft,
                colors: [
                  const Color(0xFFe6733c),
                  const Color(0xFFe6733c).withOpacity(0.75)
                ]),
            borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    SylvestImageProvider(
                      url: authorDetails.profileImage,
                      radius: 15),
                    const SizedBox(width: 10),
                    Text(
                      authorDetails.username,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    )
                  ],
                )),
            const SizedBox(height: 9),
            PostTitle(shortenTitle(title), Colors.white, 1, Colors.white,
                Colors.white),
            EventTime(
                date: date,
                duration: null,
                small: true,
                backgroundColor: const Color(0xFFf57d43)),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Contributors(
                    target: null,
                    fundedSoFar: null,
                    minimumAmountToFund: null,
                    amountAvailible: null,
                    formData: null,
                    isAuthor: false,
                    canContribute: false,
                    userData: null,
                    title: "Attendees",
                    postType: PostType.Event,
                    address: null,
                    backgroundColor: const Color(0xFFf57d43),
                    textColor: Colors.white,
                    activatedColor: const Color(0xFFe98c5e),
                    buttonText: "Attend", //change this shit man
                    isContributing: isAttending,
                    postId: id)),
          ],
        ),
      ),
    );
  }
}
