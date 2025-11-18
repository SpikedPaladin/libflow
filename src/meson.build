lib_deps = [
    dependency('gtk4')
]

lib_sources = files(
    'main.vala',
    'node.vala',
    'node-view.vala',
    'node-view-child.vala',
    'rubberband.vala',
    'sink.vala',
    'socket.vala',
    'source.vala',
    'title-style.vala',
)

subdir('node-view')

install_data(
    'deps.in',

    rename: lib_name + '.deps',
    install_dir: get_option('datadir') / 'vala' / 'vapi'
)

lib = library(
    lib_name,

    lib_resources,
    lib_sources,
    dependencies: lib_deps,
    vala_gir: gir_name + '.gir',
    install: true,
    install_dir: [ true, true, true, true ]
)

pkg.generate(
    name: name,
    description: 'Flow Graph library for Gtk4',

    libraries: lib,
    version: version,
    subdirs: lib_name,
    filebase: lib_name,
    requires: [ 'gtk4' ]
)

custom_target(
    'typelib',

    command: [
        find_program('g-ir-compiler'),

        '--shared-library=' + lib.full_path().split('/')[-1],
        '--output=@OUTPUT@',
        meson.current_build_dir() / (gir_name + '.gir')
    ],
    output: gir_name + '.typelib',
    depends: lib,
    install: true,
    install_dir: get_option('libdir') / 'girepository-1.0'
)

lib_dependency = declare_dependency(
    link_with: lib,
    include_directories: include_directories('.')
)
