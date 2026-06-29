import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../utils/snap_utils.dart';

double perpendicularDistance(Offset p, Offset start, Offset end) {
  final double dy = end.dy - start.dy;
  final double dx = end.dx - start.dx;
  final double len = math.sqrt(dx * dx + dy * dy);
  if (len == 0) return (p - start).distance;
  return ((dy * p.dx - dx * p.dy + end.dx * start.dy - end.dy * start.dx).abs()) / len;
}

List<Offset> rdpSimplify(List<Offset> points, double epsilon) {
  if (points.length < 3) return points;
  int maxIndex = -1;
  double maxDist = 0.0;
  final Offset start = points.first;
  final Offset end = points.last;
  for (int i = 1; i < points.length - 1; i++) {
    final double dist = perpendicularDistance(points[i], start, end);
    if (dist > maxDist) {
      maxDist = dist;
      maxIndex = i;
    }
  }
  if (maxDist > epsilon) {
    final List<Offset> firstHalf = rdpSimplify(points.sublist(0, maxIndex + 1), epsilon);
    final List<Offset> secondHalf = rdpSimplify(points.sublist(maxIndex), epsilon);
    return [...firstHalf.sublist(0, firstHalf.length - 1), ...secondHalf];
  } else {
    return [start, end];
  }
}

List<Offset> findVertices(List<Offset> rawPoints, double roomL, double roomW, double gridSpacing) {
  if (rawPoints.length < 2) return [];
  List<Offset> snapped = [];
  for (final pt in rawPoints) {
    final s = snapToGrid(pt, roomL, roomW, gridSpacing);
    if (snapped.isEmpty || (s - snapped.last).distance > 0.01) {
      snapped.add(s);
    }
  }
  if (snapped.length < 2) return snapped;
  return rdpSimplify(snapped, 0.4); // 0.4 feet threshold for corner/L-shape detection
}
