project(
    'libflow',
    
    ['c', 'vala'],
    version: '1.0.0',
    meson_version: '>= 0.50.0',
)

pkg = import('pkgconfig')

api_version = '1.0'
lib_name = meson.project_name() + '-' + api_version

subdir('data')
subdir('src')

subdir('example')
