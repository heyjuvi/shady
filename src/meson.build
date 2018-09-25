add_project_arguments([
    '--vapidir', join_paths(meson.current_source_dir(), 'vapi'),
    '--pkg', 'shady-gl',     # those are handled extra, because they
    '--pkg', 'shady-egl',    # are in the custom vapi directory of
    '--pkg', 'shady-epoxy'   # the project
#    '--pkg', 'shady-glslang'
  ],
  language: 'vala'
)

add_global_arguments('-std=c11', language : 'c')

glib_dep = dependency('glib-2.0')
gtk_dep = dependency('gtk+-3.0')
gobject_dep = dependency('gobject-2.0')
gtksourceview_dep = dependency('gtksourceview-4')
libsoup_dep = dependency('libsoup-2.4')
json_glib_dep = dependency('json-glib-1.0')

app_sources = files(
  'core/glsl_compiler.vala',
  'core/glsl_minifier.vala',
  'core/source_generator.vala',
  'core/texture_manager.vala',
  'core/render_resources.vala',
  'main.vala',
  'io_sugar.vala',
  'app.vala',
  'app_window.vala',
  'app_preferences.vala',
  'shader.vala',
  'shadertoy_resource_manager.vala',
  'shader_area.vala',
  'shader_manager.vala',
  'shader_source_buffer.vala',
  'shader_source_view.vala',
  'shader_source_buffer_add_popover.vala',
  'shader_channel.vala',
  'shader_channel_type_popover.vala',
  'shader_channel_soundcloud_popover.vala',
  'shader_channel_input_popover.vala',
  'shader_channel_input_item.vala',
  'notebook_tab_label.vala',
  'notebook_action_widget.vala',
  'shader_editor.vala',
  'shader_scene.vala',
  'shadertoy_search.vala',
  'shadertoy_search_dialog.vala',
  'shadertoy_shader_item.vala'
)

sources = [
  app_resources,
  app_sources
]

cc = meson.get_compiler('c')
lib_epoxy = cc.find_library('epoxy')
lib_glslang = cc.find_library('glslang')

executable('shady',
  sources,
  dependencies: [
    glib_dep,
    gtk_dep,
    gobject_dep,
    gtksourceview_dep,
    libsoup_dep,
    json_glib_dep,
    lib_epoxy,
    lib_glslang
  ],
  install: true,
)

