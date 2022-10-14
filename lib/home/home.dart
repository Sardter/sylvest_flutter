import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:sylvest_flutter/chat/chat_rooms_page.dart';
import 'package:sylvest_flutter/home/pages.dart';
import 'package:sylvest_flutter/notifications/notifications_service.dart';
import 'package:sylvest_flutter/posts/pages/events_map_page.dart';
import 'package:sylvest_flutter/config/env.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:sylvest_flutter/home/draggable_home.dart';
import 'package:tab_indicator_styler/tab_indicator_styler.dart';
import 'package:line_icons/line_icons.dart';

class HomePage extends StatefulWidget {
  final void Function() openDrawer;
  final void Function(int page) setPage;
  const HomePage(this.openDrawer, this.setPage);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  Color backgroundColor = Colors.white,
      materialColor = const Color(0xFF733CE6),
      secondaryColor = Colors.black;

  bool _isRefreshing = false;
  int _tabIndex = 0;
  bool _isLoading = false;
  bool _newMessage = false;
  int _lastNotificationId = PushNotificationsService().messageLastId;

  final _postsKey = GlobalKey<PostsPageState>();
  final _projectsKey = GlobalKey<ProjectsPageState>();
  final _eventsKey = GlobalKey<EventsPageState>();
  final _communitiesKey = GlobalKey<CommunitiesPageState>();

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return PostsPage(key: _postsKey);
      case 1:
        return ProjectsPage(key: _projectsKey);
      case 2:
        return EventsPage(key: _eventsKey);
      case 3:
        return CommunitiesPage(key: _communitiesKey);
      default:
        throw UnimplementedError("Page does not exist: $index");
    }
  }

  void _onRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });
    await Future.delayed(Duration(milliseconds: 100));
    try {
      switch (_tabIndex) {
        case 0:
          _postsKey.currentState!.refresh();
          break;
        case 1:
          _projectsKey.currentState!.refresh();
          break;
        case 2:
          _eventsKey.currentState!.refresh();
          break;
        case 3:
          _communitiesKey.currentState!.refresh();
          break;
      }
    } catch (e) {}
    if (mounted)
      setState(() {
        _isRefreshing = false;
      });
  }

  void _onLoading() async {
    if (_isLoading && _postsKey.currentState == null) return;
    setState(() {
      _isLoading = true;
    });
    switch (_tabIndex) {
      case 0:
        final state = _postsKey.currentState as PostsPageState;
        state.loadMore();
        break;
      case 1:
        final state = _postsKey.currentState as ProjectsPageState;
        state.loadMore();
        break;
      case 2:
        final state = _postsKey.currentState as EventsPageState;
        state.loadMore();
        break;
      case 3:
        final state = _postsKey.currentState as CommunitiesPageState;
        state.loadMore();
        break;
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _onRefresh();
    });
  }

  Widget _chat() {
    return ChatsPage(setPage: widget.setPage,);
  }

  Widget _chatIcon() {
    return StreamBuilder<PushNotificationEvent>(
        stream: PushNotificationsService().eventStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final event = snapshot.data!;
            if (event.lastMessageId != _lastNotificationId)
              _newMessage = event.newMessageNotification;
          }
          return Badge(
            badgeColor: Color.fromARGB(255, 243, 179, 142),
            position: BadgePosition(top: 15, end: 8),
            showBadge: _newMessage,
            child: IconButton(
              icon: const Icon(LineIcons.sms),
              onPressed: () {
                setState(() {
                  _newMessage = false;
                });
                Navigator.push(context, MaterialPageRoute<void>(
                  builder: (BuildContext context) {
                    return _chat();
                  },
                ));
              },
            ),
          );
        });
  }

  Widget _tab(String title, IconData icon) {
    return Tab(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 5),
        Text(
          title,
          style: const TextStyle(fontSize: 11),
          overflow: TextOverflow.fade,
          maxLines: 1,
        )
      ],
    ));
  }

  Widget _tabBar() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: TabBar(
          indicator: MaterialIndicator(color: Colors.white),
          labelPadding: const EdgeInsets.symmetric(horizontal: 2),
          onTap: (index) {
            setState(() {
              _tabIndex = index;
              _onRefresh();
            });
          },
          tabs: [
            _tab("Posts", LineIcons.stream),
            _tab("Projects", LineIcons.barChart),
            _tab("Events", LineIcons.calendar),
          ],
        ));
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
    return DefaultTabController(
      length: 3,
      child: DraggableHome(
        onLoad: () => _onLoading(),
        onRefresh: () => _onRefresh(),
        alwaysShowLeadingAndAction: true,
        actions: [_chatIcon()],
        headerBottomBar: _tabBar(),
        leading: IconButton(
          onPressed: () {
            widget.openDrawer();
          },
          icon: const Icon(LineIcons.wallet),
        ),
        //bottomNavigationBar: _bottomNav(),
        headerWidget: Container(
          decoration: BoxDecoration(
              color: Colors.white,
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [materialColor, const Color(0xFFaa89ef)])),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images/sylvest_icon_no_background.png",
                  width: 70,
                  height: 70,
                ),
                const Text(
                  'sylvest',
                  style: TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 40,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        title: const Text('sylvest',
            style: TextStyle(fontFamily: 'Quicksand', color: Colors.white)),
        body: [
          Stack(
            alignment: Alignment.center,
            children: [
              _getPage(_tabIndex),
              if (_isRefreshing) _refreshingWidget()
            ],
          ),
          const SizedBox(
            height: 50,
          )
        ],
      ),

      //floatingActionButtonAnimator: FloatingActionButtonAnimator,
    );
  }
}

class EventsSmallMap extends StatelessWidget {
  final List<EventSmallCard> eventsWithLocation;

  EventsSmallMap({Key? key, required this.eventsWithLocation})
      : super(key: key);
  final CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();

  final CameraPosition _defaultPos = const CameraPosition(
    target: LatLng(31, 31),
    zoom: 2,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 200,
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2)
        ]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: <Widget>[
              GoogleMap(
                mapToolbarEnabled: false,
                compassEnabled: false,
                zoomControlsEnabled: false,
                onTap: (position) {
                  /* _customInfoWindowController.hideInfoWindow!(); */
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: ((context) => EventsMapPage(
                              Colors.white,
                              const Color(0xFF733CE6),
                              const Color(0xFF733CE6)))));
                },
                onCameraMove: (position) {
                  /* _customInfoWindowController.onCameraMove!(); */
                },
                onMapCreated: (GoogleMapController controller) async {
                  controller.setMapStyle(Env.MAP_STYLE);
                  /* _customInfoWindowController.googleMapController =
                          controller; */
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
                height: 285,
                width: 190,
                offset: 50,
              ),
            ],
          ),
        ));
  }
}
