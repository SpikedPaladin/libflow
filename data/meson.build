blueprints = files(
    'ui/node.blp',
    'ui/node-view.blp',
)

blp_target = custom_target(
    'blueprints',
    
    input: blueprints,
    output: '.',
    command: [ find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@' ],
)

lib_resources = gnome.compile_resources(
    'libflow-resources',
    'libflow.gresource.xml',
    dependencies: blp_target
)