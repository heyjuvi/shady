dbus_conf = configuration_data()
dbus_conf.set('bindir', join_paths(get_option('prefix'), get_option('bindir')))
dbus_conf.set('name', app_id)
configure_file(
  input: 'org.hasi.shady.service.in',
  output: '@0@.service'.format(app_id),
  configuration: dbus_conf,
  install: true,
  install_dir: join_paths(get_option('datadir'), 'dbus-1', 'services'),
)

search_conf = configuration_data()
search_conf.set('appid', app_id)
search_conf.set('profile', profile)
configure_file(
  input: 'org.hasi.shady.search-provider.ini.in',
  output: '@0@.search-provider.ini'.format(app_id),
  configuration: search_conf,
  install: true,
  install_dir: join_paths(get_option('datadir'), 'gnome-shell', 'search-providers'),
)

