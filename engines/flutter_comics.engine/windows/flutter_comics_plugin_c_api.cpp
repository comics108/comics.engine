#include "include/flutter_comics/flutter_comics_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_comics_plugin.h"

void FlutterComicsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_comics::FlutterComicsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
