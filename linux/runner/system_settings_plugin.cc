#include "system_settings_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gio/gio.h>

struct _SystemSettingsPlugin {
  GObject parent_instance;
  FlPluginRegistrar* registrar;
  FlMethodChannel* channel;
};

G_DEFINE_TYPE(SystemSettingsPlugin, system_settings_plugin, G_TYPE_OBJECT)

static void system_settings_plugin_dispose(GObject* object) {
  SystemSettingsPlugin* self = SYSTEM_SETTINGS_PLUGIN(object);
  g_clear_object(&self->registrar);
  g_clear_object(&self->channel);
  G_OBJECT_CLASS(system_settings_plugin_parent_class)->dispose(object);
}

static void system_settings_plugin_handle_method_call(
    SystemSettingsPlugin* self,
    FlMethodCall* method_call) {
  const gchar* method = fl_method_call_get_name(method_call);

  if (g_strcmp0(method, "openAppSettings") == 0) {
    // Open GNOME Settings
    g_autoptr(GError) error = nullptr;
    g_app_info_launch_default_for_uri("settings://", nullptr, &error);
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (g_strcmp0(method, "openNotificationSettings") == 0) {
    g_autoptr(GError) error = nullptr;
    g_app_info_launch_default_for_uri("settings://notifications", nullptr, &error);
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (g_strcmp0(method, "getNotificationPermission") == 0) {
    fl_method_call_respond_success(
        method_call, fl_value_new_int(2), nullptr); // unknown
  } else if (g_strcmp0(method, "isBiometricAvailable") == 0) {
    // Linux doesn't have a standard biometric API
    fl_method_call_respond_success(
        method_call, fl_value_new_bool(FALSE), nullptr);
  } else if (g_strcmp0(method, "getOsVersion") == 0) {
    // Get OS version from /etc/os-release or uname
    g_autoptr(GError) error = nullptr;
    g_autofree gchar* version = nullptr;
    g_autoptr(GKeyFile) key_file = g_key_file_new();
    if (g_key_file_load_from_file(key_file, "/etc/os-release",
                                   G_KEY_FILE_NONE, &error)) {
      version = g_key_file_get_string(key_file, "", "PRETTY_NAME", nullptr);
    }
    if (!version) {
      // Fallback: try /etc/lsb-release
      g_key_file_free(g_steal_pointer(&key_file));
      key_file = g_key_file_new();
      if (g_key_file_load_from_file(key_file, "/etc/lsb-release",
                                     G_KEY_FILE_NONE, &error)) {
        version = g_key_file_get_string(key_file, "", "DISTRIB_DESCRIPTION", nullptr);
      }
    }
    if (!version) {
      version = g_strdup("Linux");
    }
    fl_method_call_respond_success(
        method_call, fl_value_new_string(version), nullptr);
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

static void system_settings_plugin_class_init(SystemSettingsPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = system_settings_plugin_dispose;
}

static void system_settings_plugin_init(SystemSettingsPlugin* self) {}

void system_settings_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  SystemSettingsPlugin* plugin = SYSTEM_SETTINGS_PLUGIN(
      g_object_new(system_settings_plugin_get_type(), nullptr));

  plugin->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));

  plugin->channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "com.thisjowi/system",
      FL_METHOD_CODEC(fl_standard_method_codec_new()));

  fl_method_channel_set_method_call_handler(
      plugin->channel,
      (FlMethodChannelMethodCallHandler)system_settings_plugin_handle_method_call,
      plugin,
      nullptr);

  g_object_unref(plugin);
}
