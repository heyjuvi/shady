project('Shady', 'c', 'cpp', 'vala',
        version: '0.0',
        license: 'GPLv3+')

add_project_arguments(['--target-glib=2.38'],
                      language: 'vala')

gnome = import('gnome')

app_resources = gnome.compile_resources(
  'shady-resources', 'shady.gresource.xml',
  source_dir : '.',
  c_name : 'shady_resources')

subdir('src')
subdir('data')

meson.add_install_script('meson_post_install.py')