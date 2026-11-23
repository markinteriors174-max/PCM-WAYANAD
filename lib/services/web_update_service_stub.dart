import 'package:flutter/material.dart';
import 'web_update_service.dart';

class WebUpdateServiceImpl extends WebUpdateService {
  @override
  void init(BuildContext context) {
    // No-op for non-web platforms
  }

  @override
  void dispose() {
    // No-op
  }
}
