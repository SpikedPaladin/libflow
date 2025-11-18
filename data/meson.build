subdir('ui')

lib_resources = gnome.compile_resources(
    'resources',
    'gresource.xml',
    source_dir: meson.current_build_dir(),
    dependencies: custom_target(
        'blueprints',

        input: blueprints,
        output: '.',
        command: [ find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@' ],
    )
)
