#include <gtk/gtk.h>
#include <gio/gio.h>
#include <glib.h>
#include <json-glib/json-glib.h>

#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

#include <atomic>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>
#include <optional>
#include <mutex>

extern "C" {
#include "waybar_cffi_module.h"
}

// ABI v2 requires a VARIABLE symbol
extern "C" const size_t wbcffi_version = 2;

// ---------- helpers ----------
static std::string getenv_str(const char* k) {
  const char* v = std::getenv(k);
  return v ? std::string(v) : std::string();
}
static std::string run_cmd_capture(const char* cmd) {
  std::string out;
  FILE* fp = popen(cmd, "r");
  if (!fp) return out;
  char buf[4096];
  while (true) {
    size_t n = fread(buf, 1, sizeof(buf), fp);
    if (n == 0) break;
    out.append(buf, buf + n);
  }
  pclose(fp);
  return out;
}
static std::string trim(std::string s) {
  while (!s.empty() && (s.back()=='\n' || s.back()=='\r' || s.back()==' ' || s.back()=='\t')) s.pop_back();
  size_t i=0;
  while (i<s.size() && (s[i]==' ' || s[i]=='\t' || s[i]=='\n' || s[i]=='\r')) i++;
  if (i) s.erase(0, i);
  return s;
}
static bool starts_with(std::string_view s, std::string_view p) {
  return s.size() >= p.size() && s.substr(0, p.size()) == p;
}
static std::string lower_ascii(std::string s) {
  for (char& c : s) c = (char)g_ascii_tolower(c);
  return s;
}

// ---------- icon resolver (unchanged logic, shortened here if you want) ----------
struct DesktopEntry {
  std::string path, icon, startup_wmclass, name;
};

static DesktopEntry parse_desktop_file(const std::string& path) {
  DesktopEntry e; e.path = path;
  gchar* content = nullptr; gsize len = 0;
  if (!g_file_get_contents(path.c_str(), &content, &len, nullptr) || !content) return e;

  bool in_desktop = false;
  for (char* line = content; line && *line; ) {
    char* next = strchr(line, '\n'); if (next) *next = '\0';
    std::string_view sv(line);
    if (!sv.empty() && sv.back() == '\r') sv = sv.substr(0, sv.size()-1);

    if (sv == "[Desktop Entry]") in_desktop = true;
    else if (starts_with(sv, "[")) in_desktop = false;
    else if (in_desktop) {
      auto eq = sv.find('=');
      if (eq != std::string_view::npos) {
        auto key = sv.substr(0, eq);
        auto val = sv.substr(eq+1);
        if (key == "Icon") e.icon = std::string(val);
        else if (key == "StartupWMClass") e.startup_wmclass = std::string(val);
        else if (key == "Name") e.name = std::string(val);
      }
    }
    if (!next) break;
    line = next + 1;
  }
  g_free(content);
  return e;
}

static std::vector<std::string> list_desktop_files() {
  std::vector<std::string> files;

  std::string xdg_data_home = getenv_str("XDG_DATA_HOME");
  if (xdg_data_home.empty()) xdg_data_home = getenv_str("HOME") + "/.local/share";

  std::vector<std::string> dirs{xdg_data_home};

  std::string xdg_data_dirs = getenv_str("XDG_DATA_DIRS");
  if (xdg_data_dirs.empty()) xdg_data_dirs = "/usr/local/share:/usr/share";
  size_t start = 0;
  while (start <= xdg_data_dirs.size()) {
    size_t pos = xdg_data_dirs.find(':', start);
    std::string part = (pos == std::string::npos) ? xdg_data_dirs.substr(start)
                                                  : xdg_data_dirs.substr(start, pos - start);
    if (!part.empty()) dirs.push_back(part);
    if (pos == std::string::npos) break;
    start = pos + 1;
  }

  for (auto& d : dirs) {
    std::string appdir = d + "/applications";
    GDir* gd = g_dir_open(appdir.c_str(), 0, nullptr);
    if (!gd) continue;
    while (const char* name = g_dir_read_name(gd)) {
      if (g_str_has_suffix(name, ".desktop")) files.push_back(appdir + "/" + name);
    }
    g_dir_close(gd);
  }
  return files;
}

static std::string stem_of_desktop(const std::string& path) {
  auto slash = path.find_last_of('/');
  auto base = (slash == std::string::npos) ? path : path.substr(slash + 1);
  if (g_str_has_suffix(base.c_str(), ".desktop")) base.resize(base.size() - 8);
  return base;
}

struct IconResolver {
  std::mutex mu;
  std::vector<std::string> desktop_files{list_desktop_files()};
  std::unordered_map<std::string, std::string> class_to_icon;

  std::optional<std::string> resolve_icon_for_class(const std::string& cls) {
    if (cls.empty()) return std::nullopt;
    std::string key = lower_ascii(cls);

    {
      std::lock_guard<std::mutex> lk(mu);
      auto it = class_to_icon.find(key);
      if (it != class_to_icon.end()) {
        if (it->second.empty()) return std::nullopt;
        return it->second;
      }
    }

    std::optional<std::string> found;

    for (const auto& f : desktop_files) {
      if (lower_ascii(stem_of_desktop(f)) == key) {
        auto e = parse_desktop_file(f);
        if (!e.icon.empty()) { found = e.icon; break; }
      }
    }
    if (!found) {
      for (const auto& f : desktop_files) {
        auto e = parse_desktop_file(f);
        if (!e.startup_wmclass.empty() && lower_ascii(e.startup_wmclass) == key) {
          if (!e.icon.empty()) { found = e.icon; break; }
        }
      }
    }

    {
      std::lock_guard<std::mutex> lk(mu);
      class_to_icon[key] = found.value_or("");
    }
    return found;
  }
};

// ---------- hypr clients ----------
struct ClientInfo { std::string cls, title; };

static std::vector<ClientInfo> clients_in_workspace(const std::string& workspace_id_or_name) {
  std::vector<ClientInfo> out;
  std::string json = trim(run_cmd_capture("hyprctl -j clients"));
  if (json.empty()) return out;

  JsonParser* parser = json_parser_new();
  GError* err = nullptr;
  if (!json_parser_load_from_data(parser, json.c_str(), (gssize)json.size(), &err)) {
    if (err) g_error_free(err);
    g_object_unref(parser);
    return out;
  }

  JsonNode* root = json_parser_get_root(parser);
  if (!JSON_NODE_HOLDS_ARRAY(root)) { g_object_unref(parser); return out; }

  JsonArray* arr = json_node_get_array(root);
  guint n = json_array_get_length(arr);

  for (guint i = 0; i < n; i++) {
    JsonObject* obj = json_array_get_object_element(arr, i);
    if (!obj) continue;

    JsonObject* ws = json_object_get_object_member(obj, "workspace");
    if (!ws) continue;

    int ws_id = json_object_get_int_member(ws, "id");
    const char* ws_name = json_object_get_string_member(ws, "name");

    bool match = false;
    char buf[32]; snprintf(buf, sizeof(buf), "%d", ws_id);
    if (workspace_id_or_name == buf) match = true;
    if (ws_name && workspace_id_or_name == ws_name) match = true;
    if (!match) continue;

    const char* cls = json_object_get_string_member(obj, "class");
    const char* title = json_object_get_string_member(obj, "title");

    ClientInfo ci;
    if (cls) ci.cls = cls;
    if (title) ci.title = title;
    out.push_back(std::move(ci));
  }

  g_object_unref(parser);
  return out;
}

// ---------- config parsing from entries ----------
static std::optional<std::string> config_get_json_string(const wbcffi_config_entry* entries,
                                                        size_t len,
                                                        const char* key) {
  for (size_t i = 0; i < len; i++) {
    if (entries[i].key && strcmp(entries[i].key, key) == 0) {
      if (entries[i].value) return std::string(entries[i].value);
      return std::nullopt;
    }
  }
  return std::nullopt;
}

static std::string strip_jsonc_comment(std::string s) {
  // Remove // comments (simple, works for your shown values)
  auto pos = s.find("//");
  if (pos != std::string::npos) s = s.substr(0, pos);
  return trim(std::move(s));
}

static std::string unquote(std::string s) {
  s = trim(std::move(s));
  if (s.size() >= 2 && ((s.front() == '"' && s.back() == '"') || (s.front() == '\'' && s.back() == '\''))) {
    s = s.substr(1, s.size() - 2);
  }
  return s;
}

static std::optional<int> parse_int_loose(const std::string& raw) {
  std::string s = unquote(strip_jsonc_comment(raw));
  if (s.empty()) return std::nullopt;

  // Accept leading integer in the string
  char* end = nullptr;
  long v = std::strtol(s.c_str(), &end, 10);
  if (end == s.c_str()) return std::nullopt;
  return (int)v;
}

static std::optional<bool> parse_bool_loose(const std::string& raw) {
  std::string s = lower_ascii(unquote(strip_jsonc_comment(raw)));
  if (s == "true" || s == "1") return true;
  if (s == "false" || s == "0") return false;
  return std::nullopt;
}

static std::optional<std::string> parse_string_loose(const std::string& raw) {
  std::string s = unquote(strip_jsonc_comment(raw));
  if (s.empty()) return std::nullopt;
  return s;
}

// ---------- module state ----------
struct ModuleState {
  GtkContainer* root = nullptr;
  GtkWidget* box = nullptr;
  GtkWidget* wrapper = nullptr;
  GtkWidget* icons = nullptr;

  std::string workspace = "1";
  int icon_size = 18;
  int spacing = 6;
  int max_icons = 0;
  bool show_empty = false;
  bool tooltip = true;
  std::string css_class;
  std::string active_workspace;         // from workspace>> (normal workspaces)
  std::string active_special_workspace; // from activespecial>> (special workspaces)

  std::atomic<bool> stop{false};
  GThread* thread = nullptr;

  IconResolver resolver;
  std::vector<std::string> last_classes;

  // simple coalescing: avoid queuing thousands of invokes
  std::atomic<bool> update_pending{false};
};

static void render_icons(ModuleState* st) {
  auto clients = clients_in_workspace(st->workspace);

  std::vector<std::string> classes;
  std::vector<std::string> tooltip_lines;
  std::unordered_map<std::string, bool> seen;

  for (auto& c : clients) {
    if (c.cls.empty()) continue;
    if (seen[c.cls]) continue;
    seen[c.cls] = true;

    classes.push_back(c.cls);
    if (st->tooltip) {
      tooltip_lines.push_back(c.title.empty() ? c.cls : (c.cls + " — " + c.title));
    }
    if (st->max_icons > 0 && (int)classes.size() >= st->max_icons) break;
  }

  const bool is_empty = classes.empty();

  if (is_empty && !st->show_empty) gtk_widget_hide(st->wrapper);
  else gtk_widget_show(st->wrapper);

  GtkStyleContext* wrapper_ctx = gtk_widget_get_style_context(st->wrapper);
  gtk_style_context_remove_class(wrapper_ctx, "empty");
  gtk_style_context_remove_class(wrapper_ctx, "nonempty");
  gtk_style_context_add_class(wrapper_ctx, is_empty ? "empty" : "nonempty");

  GtkStyleContext* row_ctx = gtk_widget_get_style_context(st->box);
  gtk_style_context_remove_class(row_ctx, "empty");
  gtk_style_context_remove_class(row_ctx, "nonempty");
  gtk_style_context_add_class(row_ctx, is_empty ? "empty" : "nonempty");

  const bool is_special_target = starts_with(st->workspace, "special:");
  const bool is_active =
    is_special_target
      ? (!st->active_special_workspace.empty() && st->active_special_workspace == st->workspace)
      : (!st->active_workspace.empty() && st->active_workspace == st->workspace);

  auto apply_active_classes = [&](GtkWidget* w) {
    GtkStyleContext* ctx = gtk_widget_get_style_context(w);
    gtk_style_context_remove_class(ctx, "active");
    gtk_style_context_remove_class(ctx, "inactive");
    gtk_style_context_add_class(ctx, is_active ? "active" : "inactive");
  };

  apply_active_classes(st->wrapper);
  apply_active_classes(st->box);


  if (classes == st->last_classes) return;
  st->last_classes = classes;

  GList* children = gtk_container_get_children(GTK_CONTAINER(st->icons));
  for (GList* l = children; l != nullptr; l = l->next) gtk_widget_destroy(GTK_WIDGET(l->data));
  g_list_free(children);


  GtkIconTheme* theme = gtk_icon_theme_get_default();

  for (size_t idx = 0; idx < classes.size(); idx++) {
    const auto& cls = classes[idx];

    auto icon = st->resolver.resolve_icon_for_class(cls);
    GtkWidget* img = nullptr;

    if (icon && !icon->empty()) {
      if ((*icon)[0] == '/' || starts_with(*icon, "file://")) {
        std::string p = *icon;
        if (starts_with(p, "file://")) p = p.substr(7);
        GdkPixbuf* pb = gdk_pixbuf_new_from_file_at_scale(p.c_str(), st->icon_size, st->icon_size, TRUE, nullptr);
        if (pb) { img = gtk_image_new_from_pixbuf(pb); g_object_unref(pb); }
      } else if (gtk_icon_theme_has_icon(theme, icon->c_str())) {
        img = gtk_image_new_from_icon_name(icon->c_str(), GTK_ICON_SIZE_MENU);
        gtk_image_set_pixel_size(GTK_IMAGE(img), st->icon_size);
      }
    }

    if (!img) {
      img = gtk_image_new_from_icon_name("application-x-executable", GTK_ICON_SIZE_MENU);
      gtk_image_set_pixel_size(GTK_IMAGE(img), st->icon_size);
    }

    gtk_widget_set_margin_end(img, (idx + 1 < classes.size()) ? st->spacing : 0);
    gtk_box_pack_start(GTK_BOX(st->icons), img, FALSE, FALSE, 0);
    gtk_widget_show(img);

    GtkStyleContext* img_ctx = gtk_widget_get_style_context(img);
    gtk_style_context_add_class(img_ctx, "hypr-ws-apps-icon");
  }

  if (st->tooltip) {
    std::string tip;
    for (size_t i = 0; i < tooltip_lines.size(); i++) {
      tip += tooltip_lines[i];
      if (i + 1 < tooltip_lines.size()) tip += "\n";
    }
    gtk_widget_set_tooltip_text(GTK_WIDGET(st->root), tip.empty() ? nullptr : tip.c_str());
  } else {
    gtk_widget_set_has_tooltip(GTK_WIDGET(st->root), FALSE);
  }
}

// invoked on GTK main loop
static gboolean invoke_update_cb(gpointer data) {
  auto* st = (ModuleState*)data;
  st->update_pending.store(false);
  render_icons(st);
  return G_SOURCE_REMOVE;
}

static void request_update(ModuleState* st) {
  bool expected = false;
  if (!st->update_pending.compare_exchange_strong(expected, true)) return; // already queued
  g_main_context_invoke(nullptr, [](gpointer data) -> gboolean {
    return invoke_update_cb(data);
  }, st);
}

static std::string first_field(std::string s) {
  s = trim(std::move(s));
  auto pos = s.find(',');
  if (pos != std::string::npos) s = s.substr(0, pos);
  return trim(std::move(s));
}

static std::string normalize_special_name(std::string s) {
  s = first_field(std::move(s));
  if (s.empty()) return s;
  if (starts_with(s, "special:")) return s;   // already fully-qualified
  return "special:" + s;                      // add prefix
}

// thread: listen hypr events
static gpointer hypr_thread_fn(gpointer data) {
  auto* st = (ModuleState*)data;

  std::string runtime = getenv_str("XDG_RUNTIME_DIR");
  std::string sig = getenv_str("HYPRLAND_INSTANCE_SIGNATURE");
  if (runtime.empty() || sig.empty()) return nullptr;

  std::string sock_path = runtime + "/hypr/" + sig + "/.socket2.sock";

  int fd = socket(AF_UNIX, SOCK_STREAM, 0);
  if (fd < 0) return nullptr;

  sockaddr_un addr{};
  addr.sun_family = AF_UNIX;
  strncpy(addr.sun_path, sock_path.c_str(), sizeof(addr.sun_path) - 1);

  if (connect(fd, (sockaddr*)&addr, sizeof(addr)) != 0) {
    close(fd);
    return nullptr;
  }

  request_update(st);

  std::string buf;
  buf.reserve(4096);
  char tmp[1024];

  while (!st->stop.load()) {
    ssize_t n = read(fd, tmp, sizeof(tmp));
    if (n <= 0) break;
    buf.append(tmp, tmp + n);

    size_t pos = 0;
    while (true) {
      size_t nl = buf.find('\n', pos);
      if (nl == std::string::npos) { buf.erase(0, pos); break; }
      std::string line = buf.substr(pos, nl - pos);
      pos = nl + 1;

      if (starts_with(line, "workspace>>")) {
        st->active_workspace = first_field(line.substr(strlen("workspace>>")));
        request_update(st);
        continue;
      }

      if (starts_with(line, "activespecial>>")) {
        st->active_special_workspace = normalize_special_name(
          line.substr(strlen("activespecial>>"))
        );
        request_update(st);
        continue;
      }

      if (starts_with(line, "openwindow>>") ||
          starts_with(line, "closewindow>>") ||
          starts_with(line, "movewindow>>") ||
          starts_with(line, "createworkspace>>") ||
          starts_with(line, "destroyworkspace>>")) {
        request_update(st);
      }
    }
  }

  close(fd);
  return nullptr;
}

// ---------- REQUIRED exports ----------
extern "C" void* wbcffi_init(const wbcffi_init_info* init_info,
                            const wbcffi_config_entry* config_entries,
                            size_t config_entries_len) {


  for (size_t i = 0; i < config_entries_len; i++) {
  g_message("hypr-ws-apps config: key=%s value=%s",
            config_entries[i].key ? config_entries[i].key : "(null)",
            config_entries[i].value ? config_entries[i].value : "(null)");
  }

  if (!init_info || !init_info->get_root_widget || !init_info->obj) return nullptr;

  auto* st = new ModuleState();

  st->root = init_info->get_root_widget(init_info->obj);
  if (!st->root) { delete st; return nullptr; }

  // config
  if (auto v = config_get_json_string(config_entries, config_entries_len, "workspace")) {
    if (auto s = parse_string_loose(*v)) st->workspace = *s;
  }
  if (auto v = config_get_json_string(config_entries, config_entries_len, "icon_size")) {
    if (auto i = parse_int_loose(*v)) st->icon_size = *i;
  }
  if (auto v = config_get_json_string(config_entries, config_entries_len, "spacing")) {
    if (auto i = parse_int_loose(*v)) st->spacing = *i;
  }
  if (auto v = config_get_json_string(config_entries, config_entries_len, "max_icons")) {
    if (auto i = parse_int_loose(*v)) st->max_icons = *i;
  }
  if (auto v = config_get_json_string(config_entries, config_entries_len, "show_empty")) {
    if (auto b = parse_bool_loose(*v)) st->show_empty = *b;
  }
  if (auto v = config_get_json_string(config_entries, config_entries_len, "tooltip")) {
    if (auto b = parse_bool_loose(*v)) st->tooltip = *b;
  }
  if (auto v = config_get_json_string(config_entries, config_entries_len, "css_class")) {
    if (auto s = parse_string_loose(*v)) st->css_class = *s;
  }

  // UI: wrapper (stylable) -> row (icons)
  st->wrapper = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
  gtk_widget_set_hexpand(st->wrapper, TRUE);

  // This is what you style with #hypr-ws-apps (min-width, background, etc.)
  gtk_widget_set_name(st->wrapper, "hypr-ws-apps");
  GtkStyleContext* wctx = gtk_widget_get_style_context(st->wrapper);
  gtk_style_context_add_class(wctx, "hypr-ws-apps");
  if (!st->css_class.empty()) {
    gtk_style_context_add_class(wctx, st->css_class.c_str());
  }

  // Row that actually holds icons
  st->box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
  // Add CSS hooks for the row container
  gtk_widget_set_name(st->box, "hypr-ws-apps-row");
  GtkStyleContext* row_ctx = gtk_widget_get_style_context(st->box);
  gtk_style_context_add_class(row_ctx, "hypr-ws-apps-row");
  if (!st->css_class.empty()) {
    gtk_style_context_add_class(row_ctx, st->css_class.c_str());
  }

  // NEW: inner container that holds icons
  st->icons = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
  gtk_widget_set_name(st->icons, "hypr-ws-apps-icons");
  GtkStyleContext* icons_ctx = gtk_widget_get_style_context(st->icons);
  gtk_style_context_add_class(icons_ctx, "hypr-ws-apps-icons");
  if (!st->css_class.empty()) {
    gtk_style_context_add_class(icons_ctx, st->css_class.c_str());
  }

  // Center icons container within the row
  gtk_widget_set_halign(st->icons, GTK_ALIGN_CENTER);

  // Put icons container inside the row
  gtk_box_pack_start(GTK_BOX(st->box), st->icons, TRUE, TRUE, 0);
  gtk_widget_show(st->icons);

  // Center the row inside the wrapper
  gtk_widget_set_halign(st->box, GTK_ALIGN_CENTER);

  gtk_box_pack_start(GTK_BOX(st->wrapper), st->box, TRUE, TRUE, 0);
  gtk_container_add(GTK_CONTAINER(st->root), st->wrapper);

  gtk_widget_show(st->box);
  gtk_widget_show(st->wrapper);

  // thread
  st->thread = g_thread_new("hypr-ws-apps", hypr_thread_fn, st);

  // initial render
  request_update(st);

  return st;
}

extern "C" void wbcffi_deinit(void* instance) {
  auto* st = (ModuleState*)instance;
  if (!st) return;

  st->stop.store(true);
  if (st->thread) {
    g_thread_join(st->thread);
    st->thread = nullptr;
  }

  if (st->wrapper) {
    gtk_widget_destroy(st->wrapper);
    st->wrapper = nullptr;
    st->box = nullptr;
  }
  delete st;
}

// optional, safe no-op (Waybar may call it)
extern "C" void wbcffi_update(void* instance) {
  auto* st = (ModuleState*)instance;
  if (!st) return;
  render_icons(st);
}
extern "C" void wbcffi_refresh(void*, int) {}
extern "C" void wbcffi_doaction(void*, const char*) {}