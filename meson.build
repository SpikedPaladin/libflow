project(
    'libflow',

    [ 'c', 'vala' ],
    version: '1.0.0',
    meson_version: '>= 0.50.0',
)

name = 'flow'
version = meson.project_version()
api_version = '1.0'
lib_name = name + '-' + api_version
gir_name = 'Flow-' + api_version

add_project_arguments('--enable-experimental', language: 'vala')

pkg = import('pkgconfig')
gnome = import('gnome')

subdir('data')
subdir('src')
subdir('tests')
subdir('example')
