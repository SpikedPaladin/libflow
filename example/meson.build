project_deps = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gtk4'),
    lib_dependency
]

project_sources = [
    'main.vala',
]

executable('gtkflowgraph-sample',
    project_sources,
    vala_args: '--target-glib=2.58',
    dependencies: project_deps,
    install: true,
)
