cmake_minimum_required(VERSION 3.21)

project(PyBroma LANGUAGES CXX)
find_package(Python COMPONENTS Interpreter Development.Module REQUIRED)

set(CYTHON_SRC ${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.cpp)
set(PYX_SRC ${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.pyx)
add_custom_command(
    OUTPUT ${CYTHON_SRC}
    COMMAND Python::Interpreter -m cython -3 --cplus ${PYX_SRC} --output-file "${CYTHON_SRC}"
    DEPENDS ${PYX_SRC}
    VERBATIM
)

python_add_library(${PROJECT_NAME} MODULE WITH_SOABI ${CYTHON_SRC})
target_link_libraries(${PROJECT_NAME} PRIVATE Broma)

install(TARGETS ${PROJECT_NAME} LIBRARY DESTINATION .)
