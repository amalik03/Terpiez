import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:redis/redis.dart';
import 'package:path_provider/path_provider.dart';
import 'main.dart';

class Terpiez {
  final String id;
  final String name;
  final String description;
  final String thumbnail;
  final String image;
  final Map<String, int> stats;
  final List<LatLng> locations;

  Terpiez.fromJson(String id, Map<String, dynamic> m)
      : id = id,
        name = m['name'] as String,
        description = m['description'] as String,
        thumbnail = m['thumbnail'] as String,
        image = m['image'] as String,
        stats = Map<String, int>.from(m['stats']),
        locations = (m['locations'] != null)
            ? (m['locations'] as List)
                .map((i) => LatLng((i['lat'] as double), (i['lon'] as double)))
                .toList()
            : [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'thumbnail': thumbnail,
        'image': image,
        'stats': stats,
        'locations': locations
            .map((loc) => {'lat': loc.latitude, 'lon': loc.longitude})
            .toList(),
      };
  void addLoc(LatLng loc) {
    locations.add(loc);
  }

  @override
  String toString() {
    return 'name: $name, description: $description, '
        'thumbnail: $thumbnail, image: $image, stats: $stats, '
        'locations: $locations';
  }
}

class TerpiezLoc {
  final String id;
  final double lat;
  final double lon;

  TerpiezLoc({required this.id, required this.lat, required this.lon});

  TerpiezLoc.fromJson(Map<String, dynamic> m)
      : id = m['id'] as String,
        lat = (m['lat'] as num).toDouble(),
        lon = (m['lon'] as num).toDouble();

  Map<String, dynamic> toJson() => {'id': id, 'lat': lat, 'lon': lon};
  LatLng get latLng => LatLng(lat, lon);
  @override
  String toString() {
    return '{id: $id, lat: $lat, lon: $lon}';
  }
}

class UserState extends ChangeNotifier {
  final storage = FlutterSecureStorage();
  SharedPreferences? prefs;
  int _terpiezCount = 0;
  String? _userId;
  DateTime? _startD;
  List<TerpiezLoc> unCaughtTerps = [];
  Map<String, Terpiez> caughtTerps = {};
  String? username;
  String? password;
  Timer? timer;
  bool prevStatus = false;
  bool currStatus = false;
  bool isFirst = true; // should not pop a snackbar on the first app launch
  LatLng? currPos;
  TerpiezLoc? closest;
  double? distance;
  bool soundSet = true;

  void connCheck() {
    checkConnection();
    timer = Timer.periodic(Duration(seconds: 10), (_) async {
      await checkConnection();
    });
  }

  Future<void> checkConnection() async {
    bool prevStatus = currStatus;
    try {
      final conn = RedisConnection();
      final connection = await conn
          .connect('cmsc436-0101-redis.cs.umd.edu', 6380)
          .timeout(Duration(seconds: 1));
      await connection.send_object(['AUTH', username, password]).timeout(
          Duration(seconds: 1));

      currStatus = true;
    } catch (e) {
      currStatus = false;
    }
    if ((!prevStatus && currStatus) && isFirst == false) {
      scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
        content: Text("Connection to server restored"),
        backgroundColor: Colors.green,
      ));
    } else if ((prevStatus && !currStatus) && isFirst == false) {
      scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
        content: Text("Connection to server lost"),
        backgroundColor: Colors.red,
      ));
    }
    isFirst = false;
    prevStatus = currStatus;
    notifyListeners();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> loadUserData() async {
    prefs = await SharedPreferences.getInstance();
    await getUserId();
    await getStartDate();
    _terpiezCount = prefs?.getInt('terpiezCount') ?? 0;
    soundSet = prefs?.getBool('soundSet') ?? true;
    username = await storage.read(key: "username");
    password = await storage.read(key: "password");
    if (username != null && password != null) {
      connCheck();
      await getLocation();
      notifyListeners();
    }
    notifyListeners();
  }

  Future<void> clearData() async {
    await prefs?.clear();
    _userId = null;
    _terpiezCount = 0;
    caughtTerps.clear();
    _startD = null;
    await getUserId();
    await getStartDate();
    notifyListeners();
  }

  void toggleSound(bool value) async {
    print("VALUE: $value");
    soundSet = value;
    prefs?.setBool('soundSet', value);
    print(prefs?.getBool('soundSet'));
    notifyListeners();
  }

  Future<Command> connectRedis() async {
    username = await storage.read(key: 'username');
    password = await storage.read(key: 'password');

    final conn = RedisConnection();
    final connection =
        await conn.connect('cmsc436-0101-redis.cs.umd.edu', 6380);
    await connection.send_object(['AUTH', username, password]);
    return connection;
  }

  Future<void> getLocation() async {
    /* Moved this code to the top so we can fetch caught terps for the
       list tab when we are not connected to GlobalProtect VPN. Otherwise
       it will not fetch it because it does not reach it after trying
       to connect if the VPN is not connected, and we get an empty list */
    final String? caughtTerpsString = prefs?.getString('caughtTerps');
    if (caughtTerpsString != null) {
      final Map<String, dynamic> decoded = jsonDecode(caughtTerpsString);
      caughtTerps = decoded.map((key, value) => MapEntry(
          key, Terpiez.fromJson(key, Map<String, dynamic>.from(value))));
    } else {
      caughtTerps = {};
    }
    // print(caughtTerps);

    final con = await connectRedis();
    final terps = await con.send_object(['JSON.GET', 'locations', "."]);
    List<dynamic> decoded = jsonDecode(terps);

    unCaughtTerps = decoded.map((i) => TerpiezLoc.fromJson(i)).toList();
    // print("UNCAUGHT BEFORE: $unCaughtTerps");
    for (var t in caughtTerps.values) {
      for (var l in t.locations) {
        unCaughtTerps
            .removeWhere((i) => l.latitude == i.lat && l.longitude == i.lon);
      }
    }
    // print(caughtTerps.length);
    notifyListeners();
  }

  Future<void> catchTerpiez(TerpiezLoc t) async {
    final con = await connectRedis();
    final terps = await con.send_object(['JSON.GET', 'terpiez', '.${t.id}']);
    Map<String, dynamic> decoded = jsonDecode(terps);
    // print("JSON ENCODE ${jsonEncode(t.id)}");

    if (caughtTerps[t.id] == null) {
      // if we haven't caught this terpiez before
      caughtTerps[t.id] = Terpiez.fromJson(t.id, decoded);
    }
    // add the location of the terpiez we caught to its information
    caughtTerps[t.id]?.addLoc(LatLng(t.lat, t.lon));

    unCaughtTerps
        .removeWhere((i) => i.id == t.id && i.lat == t.lat && i.lon == t.lon);

    final ter = await con.send_object(['JSON.GET', username]) as String;
    final ters = jsonDecode(ter) as Map<String, dynamic>;

    /* If the user is a new user and has not caught a Terpiez yet, add an empty
    *  array so that we can use JSON.ARRAPPEND, because it won't let us if the value
    *  is empty and not an empty array*/
    if (!ters.containsKey(_userId)) {
      await con.send_object(['JSON.SET', username, '.$_userId', '[]']);
    }
    await setImage(caughtTerps[t.id]!);
    await setThumb(caughtTerps[t.id]!);
    await setData(t.id, caughtTerps[t.id]!);
    /* Append the caught terpiez information to the list of the user's caught
    *  Terpiez list in Redis */
    await con.send_object([
      'JSON.ARRAPPEND',
      username,
      '.$_userId',
      jsonEncode(caughtTerps[t.id])
    ]);

    final Map<String, dynamic> jsonMap =
        caughtTerps.map((key, value) => MapEntry(key, value.toJson()));
    final String jsonString = jsonEncode(jsonMap);
    await prefs?.setString('caughtTerps', jsonString);
    await incCount();
    notifyListeners();
  }

  Future<void> setImage(Terpiez t) async {
    var dir = await getApplicationDocumentsDirectory();

    File f = File('${dir.path}/${t.image}.png');
    print("FILE NAME: $f");
    if (await f.exists()) {
      print("${f.path} exists");
      return;
    }

    final con = await connectRedis();
    final terps = await con.send_object(['JSON.GET', 'images', '.${t.image}']);
    final decoded = terps as String;
    final imgData = base64.decoder.convert(decoded, 1, decoded.length - 1);

    f.writeAsBytes(imgData);
  }

  Future<void> setThumb(Terpiez t) async {
    var dir = await getApplicationDocumentsDirectory();

    File f = File('${dir.path}/${t.thumbnail}_thumb.png');
    print("FILE NAME: $f");
    if (await f.exists()) {
      print("${f.path} exists");
      return;
    }

    final con = await connectRedis();
    final terps =
        await con.send_object(['JSON.GET', 'images', '.${t.thumbnail}']);
    final decoded = terps as String;
    final imgData = base64.decoder.convert(decoded, 1, decoded.length - 1);

    f.writeAsBytes(imgData);
  }

  Future<void> setData(String id, Terpiez t) async {
    var dir = await getApplicationDocumentsDirectory();

    File f = File('${dir.path}/${id}.json');
    if (await f.exists()) {
      print("${f.path} exists");
      return;
    }
    final con = await connectRedis();
    final terps = await con.send_object(['JSON.GET', 'terpiez', '.${id}']);
    final decoded = terps as String;
    f.writeAsString(decoded);
  }

  Future<void> getStartDate() async {
    String? _startDate = prefs?.getString("startD");
    if (_startDate == null) {
      _startD = DateTime.now();
      await prefs?.setString('startD', _startD!.toIso8601String());
    } else {
      _startD = DateTime.parse(_startDate);
    }
  }

  Future<void> getUserId() async {
    _userId = prefs?.getString("userId");
    if (_userId == null) {
      _userId = Uuid().v4();
      await prefs?.setString("userId", _userId!);
    }
    notifyListeners();
  }

  Future<void> incCount() async {
    _terpiezCount += 1;
    await prefs?.setInt('terpiezCount', _terpiezCount);
    notifyListeners();
  }

  Future<void> reqLocPerms() async {
    Location location = Location();

    bool _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }
    PermissionStatus _permGranted = await location.hasPermission();
    if (_permGranted == PermissionStatus.denied) {
      _permGranted = await location.requestPermission();
      if (_permGranted != PermissionStatus.granted) {
        return;
      }
    }
    location.onLocationChanged.listen((currLocation) {
      if (currLocation.latitude != null && currLocation.longitude != null) {
        currPos = LatLng(currLocation.latitude!, currLocation.longitude!);
        _calcDistance();
      }
    });
    notifyListeners();
  }

  void _calcDistance() {
    if (currPos == null) {
      distance = double.infinity;
      return;
    }

    final Distance d = Distance();
    TerpiezLoc? closestD;
    final terpiezLocs = unCaughtTerps;
    double minD = double.infinity;

    for (TerpiezLoc i in terpiezLocs) {
      double dist = d.as(LengthUnit.Meter, currPos!, LatLng(i.lat, i.lon));

      if (dist < minD) {
        minD = dist;
        closestD = i;
      }
    }
    distance = minD;
    closest = closestD;
    FlutterBackgroundService().invoke("update", {
      "lat": currPos!.latitude,
      "lon": currPos!.longitude,
      "distance": distance
    });
    notifyListeners();
  }

  int get daysActive {
    if (_startD == null) return 0;
    final now = DateTime.now();
    return now.difference(_startD!).inDays;
  }

  int get terpiezCount => _terpiezCount;
  String? get userId => _userId;
}
