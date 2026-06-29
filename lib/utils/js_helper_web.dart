// ignore_for_file: unused_field, unused_element, deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures, unused_local_variable, sort_child_properties_last, avoid_print, non_constant_identifier_names, avoid_web_libraries_in_flutter
import 'dart:js' as js;

void removeSplashFromWeb() {
  try {
    js.context.callMethod('removeSplashFromWeb');
  } catch (e) {
    // ignore
  }
}
