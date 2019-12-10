project(HelloWorld)
cmake_minimum_required(VERSION 2.8)

add_library(lib_helloworld src/lib/helloworld.c)
target_include_directories(lib_helloworld PUBLIC src/include)
set_target_properties(lib_helloworld PROPERTIES OUTPUT_NAME helloworld)

add_executable(helloworld test/main.c)
target_link_libraries(helloworld lib_helloworld)

install(TARGETS lib_helloworld helloworld
        ARCHIVE DESTINATION lib
        RUNTIME DESTINATION bin
)

enable_testing()
add_test(NAME test_helloworld
        COMMAND helloworld
)

set_tests_properties(test_helloworld PROPERTIES LABELS "UnitTest;")