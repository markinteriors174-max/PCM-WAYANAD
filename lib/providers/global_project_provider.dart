import 'package:flutter/material.dart';
import '../models/quotation.dart';

class GlobalProjectProvider extends ChangeNotifier {
  String? activeProjectId;
  Quotation? activeProject;

  void setActiveProject(String? id, {Quotation? project}) {
    activeProjectId = id;
    activeProject = project;
    notifyListeners();
  }

  void lookupProject(String value, {String? field}) {}
}
