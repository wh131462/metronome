import 'package:web/web.dart' as web;

void removeWebSplash() {
  try {
    web.document.getElementById('splash')?.remove();
    web.document.getElementById('splash-branding')?.remove();
    web.document.body?.style.background = 'transparent';
  } catch (_) {}
}
