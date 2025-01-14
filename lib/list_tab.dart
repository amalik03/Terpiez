import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:terpiez/detailed_view.dart';
import 'package:provider/provider.dart';
import 'package:terpiez/user_state_model.dart';

class ListTab extends StatefulWidget {
  const ListTab({super.key});

  @override
  State<ListTab> createState() => _ListTabState();
}

class _ListTabState extends State<ListTab> {
  @override
  Widget build(BuildContext context) {
    Map<String, Terpiez> ct = Provider.of<UserState>(context).caughtTerps;
    final terps = ct.values.toList();
    return ListView.builder(
      itemCount: terps.length,
      itemBuilder: (context, index) {
        return ListImages(terps: terps[index]);
      },
    );
  }
}

class ListImages extends StatefulWidget {
  const ListImages({
    super.key,
    required this.terps,
  });

  final Terpiez terps;

  @override
  State<ListImages> createState() => _ListImagesState();
}

class _ListImagesState extends State<ListImages> {
  File? fl;
  @override
  Widget build(BuildContext context) {
    getTNail(widget.terps.thumbnail);
    return ListTile(
      title: Text(widget.terps.name),
      leading: SizedBox(
        width: 40,
        height: 40,
        child: Hero(
          tag: widget.terps.id,
          child: fl != null ? Image.file(fl!) : Icon(Icons.abc_sharp),
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailedView(widget.terps.name, widget.terps),
          ),
        );
      },
    );
  }

  Future<void> getTNail(String thumbnail) async {
    var dir = await getApplicationDocumentsDirectory();
    setState(() {
      fl = File('${dir.path}/${thumbnail}_thumb.png');
    });
  }
}
