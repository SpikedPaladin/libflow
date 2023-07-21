example_deps = [
    dependency('gtk4'),
    lib_dependency
]

example_sources = [
    'main.vala',
]

executable(
    'libflow-sample',
    
    example_sources,
    vala_args: '--target-glib=2.58',
    dependencies: example_deps
)
