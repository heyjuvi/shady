gsettings_conf = configuration_data()
configure_file(
  input: 'org.hasi.shady.gschema.xml.in',
  output: '@0@.gschema.xml'.format(app_id),
  configuration: gsettings_conf,
  install: true,
  install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas'),
)

glib_compile_schemas = find_program('glib-compile-schemas', required: false)

# Validata GSchema
if glib_compile_schemas.found()
  test(
    'validate-gschema', glib_compile_schemas,
    args: [
      '--strict', '--dry-run', meson.current_source_dir()
    ]
  )
endif

