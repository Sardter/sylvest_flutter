import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:sylvest_flutter/discover/components/discover_components.dart';

import '../../services/api.dart';
import '../components/search_components.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  List<Widget> _results = [];

  Widget _header(String title) {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          title,
          style: const TextStyle(color: Colors.black87, fontSize: 18),
        ));
  }

  Future<void> onSearch(String searchItem) async {
    setState(() {
      _results = const [LoadingResults()];
    });

    final _searchResult = await API().discoverSearch(searchItem);
    final posts = _searchResult['posts'] as List<SearchTilePost>;
    final profiles = _searchResult['profiles'] as List<SearchTileProfile>;
    final communities =
        _searchResult['communities'] as List<SearchTileCommunity>;
    final tags = _searchResult['tags'] as List<DiscoverTag>;

    if (posts.isEmpty && communities.isEmpty && profiles.isEmpty && tags.isEmpty) {
      setState(() {
        _results = const [
          Center(
            child: Text(
              "No matching results were found.",
              style: TextStyle(color: Colors.black54),
            ),
          )
        ];
      });
    } else {
      final newResults = <Widget>[];
      if (posts.isNotEmpty) {
        newResults.add(ExpandablePanel(
            header: _header('Posts'),
            collapsed: posts[0],
            expanded: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: posts,
            )));
      }
      if (profiles.isNotEmpty) {
        newResults.add(ExpandablePanel(
            header: _header('Users'),
            collapsed: profiles[0],
            expanded: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: profiles,
            )));
      }
      if (communities.isNotEmpty) {
        newResults.add(ExpandablePanel(
            header: _header('Communities'),
            collapsed: communities[0],
            expanded: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: communities,
            )));
      }
      if (tags.isNotEmpty) {
        newResults.add(Wrap(
          spacing: -10,
          runSpacing: -20,
          children: tags,
        ));
      }
      if (mounted)
      setState(() {
        _results = newResults;
      });
    }
  }

  Widget _body() {
    return ListView(
      physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.all(15),
      children: _results + [SizedBox(height: 50,)],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _body());
  }
}
