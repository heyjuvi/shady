install_data(
  'org.hasi.shady.png',
  install_dir: join_paths(get_option('datadir'), 'pixmaps')
)

desktop_conf = configuration_data()
desktop_conf.set('icon', app_id)
desktop_file = configure_file(
  input: 'org.hasi.shady.desktop.in',
  output: '@0@.desktop'.format(app_id),
  configuration: desktop_conf,
  install: true,
  install_dir: join_paths(get_option('datadir'), 'applications')
)

# Validate Desktop file
desktop_file_validate = find_program('desktop-file-validate', required: false)
if desktop_file_validate.found()
  test(
    'validate-desktop',
    desktop_file_validate,
    args: [
      desktop_file
    ]
  )
endif

