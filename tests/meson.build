unit_tests = {
    'NodeView': files(
        'node-view-test.vala'
    )
}

unit_tests_deps = [
    dependency('gtk4'),
    lib_dependency
]

foreach name, test_sources : unit_tests
    test(name, executable(name, sources: test_sources, dependencies: unit_tests_deps))
endforeach
