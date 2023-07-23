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

if get_option('buildtype') == 'debug'
    # Don't do it in debug mode to make VLS works
    compiler_dependency = []
else
    # Creates empty vala file to fix build order issue with blueprints
    compiler_dependency = custom_target(
        'compiler_dependency',
        
        depends: lib_resources,
        output: 'dependency.vala',
        command: [ find_program('touch'), '@OUTPUT@' ]
    )
endif