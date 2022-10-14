import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:sylvest_flutter/discover/components/discover_components.dart';
import 'package:sylvest_flutter/discover/discover.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({Key? key}) : super(key: key);

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final _backgroundColor = Colors.white;

  final _searchKey = GlobalKey<SearchPageState>();
  final _searchController = TextEditingController();

  final _items = const [
    //RecommendedEvents(),
    TrendingCommunities(),
    RecommendedUsers(),
    RecommendedTags(),
    //RecommendedProjects(),
  ];

  String? lastSearch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _backgroundColor,
        centerTitle: true,
        title: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: Row(
            children: [
              const Icon(LineIcons.search, color: Color(0xFF733CE6)),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _searchController,
                  onChanged: (value) async {
                    if (value == lastSearch) return;
                    setState(() {
                      lastSearch = value;
                    });
                    await Future.delayed(Duration(milliseconds: 100));
                    if (_searchController.text.isNotEmpty)
                      _searchKey.currentState!.onSearch(_searchController.text);
                  },
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      isCollapsed: true,
                      hintText: "Search"),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() {
                    _searchController.text = "";
                  }),
                  child: const Icon(LineIcons.times, color: Colors.black54),
                )
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            physics:
                AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.only(bottom: 50),
            children: _items,
          ),
          if (_searchController.text.isNotEmpty)
            Positioned.fill(
                child: SearchPage(
              key: _searchKey,
            ))
        ],
      ),
    );
  }
}
