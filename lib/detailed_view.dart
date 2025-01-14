import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:terpiez/user_state_model.dart';

class ShaderPainter extends CustomPainter {
  ShaderPainter({required this.shader, required this.time});

  FragmentShader shader;
  double time;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time * 3.5 * pi);

    final paint = Paint()..shader = shader;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DetailedView extends StatefulWidget {
  final String tName;
  final Terpiez terp;

  const DetailedView(this.tName, this.terp, {super.key});

  @override
  State<DetailedView> createState() => _DetailedViewState();
}

class _DetailedViewState extends State<DetailedView>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  File? fl;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    getImg(widget.terp.image);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, int> stats = widget.terp.stats;
    return OrientationBuilder(
      builder: (context, orientation) {
        bool isPor = orientation == Orientation.portrait;
        return Scaffold(
          appBar: AppBar(title: Text(widget.tName)),
          body: Stack(children: [
            // Shader Background
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => ShaderBuilder(
                assetKey: 'shaders/my_shader.glsl',
                (context, shader, child) => CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter:
                      ShaderPainter(shader: shader, time: _controller.value),
                  child: child,
                ),
              ),
            ),
            isPor
                ? Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Hero(
                          tag: widget.tName,
                          child: Image.file(fl!, width: 230, height: 250),
                        ),
                      ),
                      Text(widget.tName,
                          style:
                              TextStyle(fontSize: 27.5, color: Colors.white)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 15),
                            child: SizedBox(
                              width: 235.0,
                              height: 175.0,
                              child: FlutterMap(
                                options: widget.terp.locations.length > 1
                                    ? MapOptions(
                                        initialCenter: widget.terp.locations[0],
                                        initialZoom: 15.8,
                                      )
                                    : MapOptions(
                                        initialCenter: widget.terp.locations[0],
                                        initialZoom: 18.5,
                                      ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    // OSMF's Tile Server
                                    userAgentPackageName: 'com.example.app',
                                  ),
                                  MarkerLayer(
                                    markers: widget.terp.locations.map((i) {
                                      return Marker(
                                        point: i,
                                        child: Icon(
                                          Icons.card_giftcard,
                                          size: 40.0,
                                          color: Colors.red,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 10.0),
                          // Stats Section
                          Expanded(
                            child: Column(
                              children: stats.entries.map((i) {
                                return Padding(
                                  padding:
                                      EdgeInsets.fromLTRB(0.0, 10.5, 0.0, 2.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          i.key,
                                          style: TextStyle(
                                            fontSize: 17,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 18.0),
                                        child: Text(
                                          i.value.toString(),
                                          style: TextStyle(
                                            fontSize: 17,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.0),
                      Text(
                        widget.terp.description,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  )
                // ************************* LANDSCAPE MODE *************************
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(15.0, 20.0, 0.0, 0.0),
                            child: Hero(
                              tag: widget.tName,
                              child: Image.file(fl!, width: 220),
                            ),
                          ),
                          Text(
                            widget.tName,
                            style:
                                TextStyle(fontSize: 27.8, color: Colors.white),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(15.0, 20.0, 0.0, 3.0),
                            child: SizedBox(
                              width: 150.0,
                              height: 180.0,
                              child: FlutterMap(
                                options: widget.terp.locations.length > 1
                                    ? MapOptions(
                                        initialCenter: widget.terp.locations[0],
                                        initialZoom: 15.8,
                                      )
                                    : MapOptions(
                                        initialCenter: widget.terp.locations[0],
                                        initialZoom: 18.5,
                                      ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.app',
                                  ),
                                  MarkerLayer(
                                    markers: widget.terp.locations.map((i) {
                                      return Marker(
                                        point: i,
                                        child: Icon(
                                          Icons.card_giftcard,
                                          size: 28.0,
                                          color: Colors.red,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: stats.entries.map((i) {
                                return Row(
                                  children: [
                                    SizedBox(
                                      width: 115.0, // Fixed width for alignment
                                      child: Text(
                                        i.key,
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Text(i.value.toString(),
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          color: Colors.white,
                                        )),
                                  ],
                                );
                              }).toList()),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(10.0, 15.0, 5.0, 0.0),
                          child: Text(
                            widget.terp.description,
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
          ]),
        );
      },
    );
  }

  Future<void> getImg(String image) async {
    var dir = await getApplicationDocumentsDirectory();
    setState(() {
      fl = File('${dir.path}/${image}.png');
    });
  }
}
