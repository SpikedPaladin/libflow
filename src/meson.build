lib_deps = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gtk4')
]

lib_sources = files(
    'gflow/gflow.vala',
    'gflow/gflow-aggregator.vala',
    'gflow/gflow-dock.vala',
    'gflow/gflow-node.vala',
    'gflow/gflow-simple-node.vala',
    'gflow/gflow-simple-sink.vala',
    'gflow/gflow-simple-source.vala',
    'gflow/gflow-sink.vala',
    'gflow/gflow-source.vala',
    
    'dock.vala',
    'minimap.vala',
    'node.vala',
    'nodeview.vala',
)

install_data(
    'deps.in',
    
    rename: lib_name + '.deps',
    install_dir: get_option('datadir') / 'vala' / 'vapi'
)

lib = library(
    lib_name,
    
    lib_sources,
    dependencies: lib_deps,
    install: true,
    install_dir: [true, true, true]
)

pkg.generate(
    name: 'GtkFlowGraph',
    description: 'Flow Graph library for Gtk4',
    
    libraries: lib,
    version: meson.project_version(),
    subdirs: lib_name,
    filebase: lib_name,
    requires: ['gtk4']
)

lib_dependency = declare_dependency(
    link_with: lib,
    include_directories: include_directories('.')
)
