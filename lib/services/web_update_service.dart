import 'package:flutter/material.dart';
import 'web_update_service_stub.dart'
    if (dart.library.html) 'web_update_service_web.dart';

abstract class WebUpdateService {
  static final WebUpdateService instance = WebUpdateServiceImpl();
  
  void init(BuildContext context);
  void dispose();
}
