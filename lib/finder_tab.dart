import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terpiez/main.dart';
import 'package:terpiez/shaker.dart';
import 'package:terpiez/user_state_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:audioplayers/audioplayers.dart';

/* Might need to request Location Permissions on App Launch instead of when
*  user clicks on Finder Tab, might cause issues with Notification stuff */
class FinderTab extends StatefulWidget {
  const FinderTab({super.key});

  @override
  _FinderTabState createState() => _FinderTabState();
}

class _FinderTabState extends State<FinderTab> {
  File? fl;
  bool dialogVisible = false;
  SharedPreferences? prefs;
  bool? soundSet;
  final double _volume = 100.0;
  final AudioPlayer _player = AudioPlayer();
  final AssetSource _sound = AssetSource('CaughtTerp.mp3');

  @override
  void initState() {
    super.initState();
    shakeListener();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void shakeListener() {
    final shaker = Provider.of<Shaker>(context, listen: false);
    shaker.addListener(() {
      final userState = Provider.of<UserState>(context, listen: false);
      if (shaker.isShaking && inDistance(userState) && dialogVisible == false) {
        catchTerpiez(userState);
      }
    });
  }

  Future<void> catchTerpiez(userState) async {
    if (Provider.of<UserState>(context, listen: false).soundSet) {
      _player.setVolume(_volume);
      _player.play(_sound);
    }
    setState(() {
      dialogVisible = true;
    });

    await userState.catchTerpiez(userState.closest!);
    await getImg(userState.caughtTerps[userState.closest!.id]!.image);
    Terpiez? caughtTerpiez = userState.caughtTerps[userState.closest!.id];
    if (caughtTerpiez != null) {
      _showCaught(caughtTerpiez);
    }
  }

  bool inDistance(UserState userState) {
    return userState.distance! <= 10 && userState.closest != null;
  }

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserState>(context);
    var currPos = userState.currPos;
    var distance = userState.distance;
    var closest = userState.closest;

    return OrientationBuilder(
      builder: (context, orientation) {
        bool isPor = orientation == Orientation.portrait;
        return currPos == null
            ? Container(
                alignment: Alignment.center,
                child: CircularProgressIndicator(
                  color: Colors.blue,
                ))
            : Center(
                child: isPor
                    ? Column(
                        children: [
                          Text(
                            "Terpiez Finder",
                            style: Theme.of(context).textTheme.displaySmall,
                            textAlign: TextAlign.center,
                          ),
                          Center(
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              height: 500.0,
                              child: FlutterMap(
                                  options: MapOptions(
                                    initialCenter: LatLng(
                                        currPos!.latitude, currPos!.longitude),
                                    initialZoom: 20.0,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // OSMF's Tile Server
                                      userAgentPackageName: 'com.example.app',
                                    ),
                                    CurrentLocationLayer(
                                      alignPositionOnUpdate:
                                          AlignOnUpdate.always,
                                    ),
                                    if (closest != null)
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: closest!.latLng,
                                            child: Icon(
                                              Icons.key,
                                              size: 50.0,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ]),
                            ),
                          ),
                          if (inDistance(userState))
                            Column(
                              children: [
                                Text("Closest Terpiez: ",
                                    style: TextStyle(
                                        fontSize: 22, color: Colors.green)),
                                Text("${distance} m",
                                    style: const TextStyle(
                                        fontSize: 20, color: Colors.green)),
                              ],
                            )
                          else
                            Column(
                              children: [
                                Text("Closest Terpiez: ",
                                    style: TextStyle(fontSize: 22)),
                                Text("${distance} m",
                                    style: const TextStyle(fontSize: 20)),
                              ],
                            ),
                        ],
                      )
                    // ************************* LANDSCAPE MODE *************************
                    : currPos == null
                        ? Container(
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                              color: Colors.blue,
                            ))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Terpiez Finder",
                                style: Theme.of(context).textTheme.displaySmall,
                                textAlign: TextAlign.center,
                              ),
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: SizedBox(
                                          width:
                                              MediaQuery.of(context).size.width,
                                          height: 175.0,
                                          child: FlutterMap(
                                              options: MapOptions(
                                                initialCenter: LatLng(
                                                    currPos!.latitude,
                                                    currPos!.longitude),
                                                initialZoom: 18.0,
                                              ),
                                              children: [
                                                TileLayer(
                                                  urlTemplate:
                                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // OSMF's Tile Server
                                                  userAgentPackageName:
                                                      'com.example.app',
                                                ),
                                                CurrentLocationLayer(
                                                  alignPositionOnUpdate:
                                                      AlignOnUpdate.always,
                                                ),
                                                if (closest != null)
                                                  MarkerLayer(
                                                    markers: [
                                                      Marker(
                                                        point: closest!.latLng,
                                                        child: Icon(
                                                          Icons.key,
                                                          size: 30.0,
                                                          color: Colors.green,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ]),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (inDistance(userState))
                                            Column(
                                              children: [
                                                Text("Closest Terpiez: ",
                                                    style: TextStyle(
                                                        fontSize: 22,
                                                        color: Colors.green)),
                                                Text("${distance} m",
                                                    style: const TextStyle(
                                                        fontSize: 20,
                                                        color: Colors.green)),
                                              ],
                                            )
                                          else
                                            Column(
                                              children: [
                                                Text("Closest Terpiez: ",
                                                    style: TextStyle(
                                                        fontSize: 22)),
                                                Text("${distance} m",
                                                    style: const TextStyle(
                                                        fontSize: 20)),
                                              ],
                                            )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
              );
      },
    );
  }

  void _showCaught(Terpiez t) async {
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Text(
              "You caught a ${t.name}!",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            content: Image.file(fl!, fit: BoxFit.fitHeight),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              )
            ],
          );
        });
    setState(() {
      dialogVisible = false;
    });
  }

  Future<void> getImg(String image) async {
    var dir = await getApplicationDocumentsDirectory();
    setState(() {
      fl = File('${dir.path}/${image}.png');
    });
  }
}
