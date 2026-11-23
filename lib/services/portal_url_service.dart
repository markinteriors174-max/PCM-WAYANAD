class PortalUrlService {
  static final PortalUrlService instance = PortalUrlService._();
  PortalUrlService._();

  String baseUrl = 'https://pcm-wayanad.web.app';

  Future<void> init() async {}
}
