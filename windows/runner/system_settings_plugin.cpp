#include "system_settings_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <string>
#include <windows.h>
#include <shellapi.h>

class SystemSettingsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar* registrar) {
    auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        registrar->messenger(), "com.thisjowi/system",
        &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<SystemSettingsPlugin>();

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto& call, auto result) {
          plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    registrar->AddPlugin(std::move(plugin));
  }

  SystemSettingsPlugin() {}

  virtual ~SystemSettingsPlugin() {}

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    const auto& method = method_call.method_name();

    if (method == "openAppSettings") {
      ShellExecuteW(nullptr, L"open", L"ms-settings:appsfeatures-app", nullptr, nullptr, SW_SHOW);
      result->Success();
    } else if (method == "openNotificationSettings") {
      ShellExecuteW(nullptr, L"open", L"ms-settings:notifications", nullptr, nullptr, SW_SHOW);
      result->Success();
    } else if (method == "getNotificationPermission") {
      result->Success(2); // unknown
    } else if (method == "isBiometricAvailable") {
      // Check Windows Hello availability
      BOOL available = FALSE;
      // Simple check: Windows 10+ supports Windows Hello
      OSVERSIONINFOEXW osvi = {sizeof(osvi), 0, 0, 0, 0, {0}, 0, 0};
      DWORDLONG conditionMask = 0;
      VER_SET_CONDITION(conditionMask, VER_MAJORVERSION, VER_GREATER_EQUAL);
      VER_SET_CONDITION(conditionMask, VER_BUILDNUMBER, VER_GREATER_EQUAL);
      osvi.dwMajorVersion = 10;
      osvi.dwBuildNumber = 0;
      available = VerifyVersionInfoW(&osvi, VER_MAJORVERSION | VER_BUILDNUMBER, conditionMask);
      result->Success(available ? true : false);
    } else if (method == "getOsVersion") {
      OSVERSIONINFOEXW osvi = {sizeof(osvi)};
      // Use RtlGetVersion to get actual version
      typedef LONG(WINAPI* RtlGetVersionPtr)(PRTL_OSVERSIONINFOW);
      auto RtlGetVersion = (RtlGetVersionPtr)GetProcAddress(
          GetModuleHandleW(L"ntdll.dll"), "RtlGetVersion");
      if (RtlGetVersion) {
        RtlGetVersion((PRTL_OSVERSIONINFOW)&osvi);
        std::wstring version = std::to_wstring(osvi.dwMajorVersion) + L"." +
                               std::to_wstring(osvi.dwMinorVersion) + L"." +
                               std::to_wstring(osvi.dwBuildNumber);
        result->Success(flutter::EncodableValue(
            std::string(version.begin(), version.end())));
      } else {
        result->Success(flutter::EncodableValue("10.0"));
      }
    } else if (method == "isAutofillServiceEnabled") {
      result->Success(false); // Can't check programmatically on Windows
    } else {
      result->NotImplemented();
    }
  }
};

void SystemSettingsPluginRegisterWithRegistrar(
    flutter::PluginRegistrar* registrar) {
  SystemSettingsPlugin::RegisterWithRegistrar(registrar);
}
