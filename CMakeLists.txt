project(HelloWorld)
cmake_minimum_required(VERSION 2.8)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_PREFIX_PATH "/Users/user/workspace/github/protobuf/_install/lib/cmake")
find_package(protobuf CONFIG REQUIRED)

set(CMAKE_INCLUDE_CURRENT_DIR TRUE)

add_library(lib_protobuftest
    src/lib/list_people.cc
    src/lib/addressbook.proto
)
target_include_directories(lib_protobuftest PUBLIC src/include)

target_link_libraries(lib_protobuftest protobuf::libprotobuf)
protobuf_generate(TARGET lib_protobuftest)

add_executable(test_protobuf test/test_protobuf.cpp)
target_link_libraries(test_protobuf lib_protobuftest)
install(TARGETS lib_protobuftest test_protobuf OPTIONAL
        ARCHIVE DESTINATION lib
        RUNTIME DESTINATION bin
)

add_library(lib_helloworld src/lib/helloworld.c)
target_include_directories(lib_helloworld PUBLIC src/include)
set_target_properties(lib_helloworld PROPERTIES OUTPUT_NAME helloworld)

add_executable(helloworld test/main.c)
target_link_libraries(helloworld lib_helloworld)

install(TARGETS lib_helloworld helloworld OPTIONAL
        ARCHIVE DESTINATION lib
        RUNTIME DESTINATION bin
)

enable_testing()
add_test(NAME test_helloworld
        COMMAND helloworld
)

set_tests_properties(test_helloworld PROPERTIES LABELS "UnitTest;")