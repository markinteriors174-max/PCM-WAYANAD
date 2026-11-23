import 'package:flutter/material.dart';

Offset getControlPoint(Offset p0, Offset p1, double h) {
  final Offset mid = (p0 + p1) / 2;
  final Offset dir = p1 - p0;
  final double len = dir.distance;
  if (len == 0) return mid;
  final Offset norm = Offset(-dir.dy, dir.dx) / len;
  return mid + norm * (2 * h);
}

List<Offset> sampleBezier(Offset p0, Offset p1, Offset pc, int segments) {
  final List<Offset> pts = [];
  for (int i = 0; i <= segments; i++) {
    final double t = i / segments;
    final double mt = 1 - t;
    final Offset pt = p0 * (mt * mt) + pc * (2 * mt * t) + p1 * (t * t);
    pts.add(pt);
  }
  return pts;
}
