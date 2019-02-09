add_project_arguments([
    '--vapidir', join_paths(meson.current_source_dir(), 'vapi'),
    '--pkg', 'shady-gl',     # those are handled extra, because they
    '--pkg', 'shady-epoxy',  # are in the custom vapi directory of
    '--pkg', 'shady-glslang' # the project
  ],
  language: 'vala'
)

add_global_arguments('-std=c++11', language: 'cpp')

glib_dep = dependency('glib-2.0')
gtk_dep = dependency('gtk+-3.0')
gobject_dep = dependency('gobject-2.0')
gtksourceview_dep = dependency('gtksourceview-4')
libsoup_dep = dependency('libsoup-2.4')
json_glib_dep = dependency('json-glib-1.0')
libxml2_dep = dependency('libxml-2.0')

app_sources = files(
  'core/glslang_validator.vala',
  'core/glsl_minifier.vala',
  'core/glsl_reference_parser.vala',
  'core/source_generator.vala',
  'core/texture_manager.vala',
  'core/render_resources.vala',
  'core/compile_resources.vala',
  'core/shader_compiler.vala',
  'core/shy_file.vala',
  'main.vala',
  'io_sugar.vala',
  'app.vala',
  'app_window.vala',
  'app_preferences.vala',
  'shader.vala',
  'shadertoy_resource_manager.vala',
  'shader_area.vala',
  'shadertoy_area.vala',
  'channel_area.vala',
  'shader_source_buffer.vala',
  'shader_source_view.vala',
  'lang_doc_popover.vala',
  'shader_source_buffer_add_popover.vala',
  'shader_channel.vala',
  'shader_channel_type_popover.vala',
  'shader_channel_buffer_popover.vala',
  'shader_channel_soundcloud_popover.vala',
  'shader_channel_input_popover.vala',
  'shader_channel_input_item.vala',
  'notebook_tab_label.vala',
  'notebook_action_widget.vala',
  'shader_editor.vala',
  'shader_scene.vala',
  'shadertoy_search.vala',
  'shadertoy_search_dialog.vala',
  'shadertoy_shader_item.vala',
  'glslang/glslang_bindings.cpp'
)

sources = [
  app_resources,
  app_sources
]

cc = meson.get_compiler('c')
lib_epoxy = cc.find_library('epoxy')

cxx = meson.get_compiler('cpp')
lib_hlsl = cxx.find_library('HLSL')
lib_ogl_compiler = cxx.find_library('OGLCompiler')
lib_os_dependent = cxx.find_library('OSDependent')
lib_spirv = cxx.find_library('SPIRV')
lib_spv_remapper = cxx.find_library('SPVRemapper')
lib_glslang = cxx.find_library('glslang')
lib_pthread = cxx.find_library('pthread')

executable('shady',
  sources,
  dependencies: [
    glib_dep,
    gtk_dep,
    gobject_dep,
    gtksourceview_dep,
    libsoup_dep,
    json_glib_dep,
    libxml2_dep,
    lib_epoxy,
    lib_hlsl,
    lib_ogl_compiler,
    lib_os_dependent,
    lib_spirv,
    lib_spv_remapper,
    lib_glslang,
    lib_pthread
  ],
  install: true,
)
