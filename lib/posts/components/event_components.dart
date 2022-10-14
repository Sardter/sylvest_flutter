import 'package:duration/duration.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../config/env.dart';
import '../pages/events_map_page.dart';


class EventMap extends StatelessWidget {
  EventMap(this.position, this.zoom, {Key? key}) : super(key: key);

  final LatLng position;
  final double zoom;
  late final _defaultPos = CameraPosition(
    target: position,
    zoom: zoom,
  );

  late final  _defaultMarker = Marker(
    markerId: const MarkerId("default"),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    position: position,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 1, right: 1, bottom: 0),
      child: SizedBox(
        height: 200,
        child: GoogleMap(
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          onMapCreated: (GoogleMapController controller) {
            controller.setMapStyle(Env.MAP_STYLE);
          },
          onTap: (position) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: ((context) => EventsMapPage(Colors.white,
                        const Color(0xFF733CE6), const Color(0xFF733CE6)))));
          },
          markers: {_defaultMarker},
          mapType: MapType.normal,
          initialCameraPosition: _defaultPos,
        ),
      ),
    );
  }
}

class EventTypeWidget extends StatelessWidget {
  const EventTypeWidget(this.eventType, this.backgroundColor, this.textColor,
      {Key? key})
      : super(key: key);
  final String eventType;
  final Color backgroundColor, textColor;

  @override
  Widget build(BuildContext context) {
    String content = eventType == 'f2f' ? 'Face To Face' : 'Online';

    final Size size = (TextPainter(
        text: TextSpan(
            text: content,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: textColor)),
        maxLines: 1,
        textScaleFactor: MediaQuery.of(context).textScaleFactor,
        textDirection: TextDirection.ltr)
      ..layout())
        .size;

    return Container(
      margin: const EdgeInsets.only(left: 1, bottom: 10, top: 10),
      width: size.width + 30,
      decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(10), topRight: Radius.circular(10))),
      alignment: Alignment.centerLeft,
      child: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(content,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: textColor))),
    );
  }
}

class EventTime extends StatelessWidget {
  EventTime(
      {Key? key,
        required this.date,
        required this.duration,
        required this.backgroundColor,
        this.small = false})
      : super(key: key);
  final DateTime date;
  late final Duration? duration;
  final Color backgroundColor;
  final bool small;

  String _getDaySuffix(int day) {
    if (day % 10 == 1) {
      return 'th';
    } else if (day % 10 == 2) {
      return 'nd';
    } else if (day % 10 == 3) {
      return 'rd';
    } else {
      return 'th';
    }
  }

  String _dateTimeToStr() {
    List<String> months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];

    final min =
    '${date.minute}'.length == 1 ? '0${date.minute}' : '${date.minute}';
    final hour = '${date.hour}'.length == 1 ? '0${date.hour}' : '${date.hour}';
    return '${months[date.month - 1]} ${date.day}${_getDaySuffix(date.day)}'
        ' ${date.year}, $hour:$min';
  }

  String _durationToString() {
    return printDuration(duration!, delimiter: ',', conjugation: ' and ');
  }

  @override
  Widget build(BuildContext context) {
    if (small)
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer, color: Colors.white),
          Text(
            _dateTimeToStr(),
            style: TextStyle(color: Colors.white, fontFamily: 'Quicksand'),
          )
        ],
      );
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: backgroundColor, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(Icons.timer, color: Colors.white, size: 40),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(TextSpan(children: [
                TextSpan(
                    text: 'Date ',
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
                TextSpan(
                    text: _dateTimeToStr(),
                    style:
                    TextStyle(color: Colors.white, fontFamily: 'Quicksand'))
              ])),
              if (duration != null)
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: 'Duration ',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                  TextSpan(
                      text: _durationToString(),
                      style: TextStyle(
                          color: Colors.white, fontFamily: 'Quicksand'))
                ])),
            ],
          )
        ],
      ),
    );
  }
}

