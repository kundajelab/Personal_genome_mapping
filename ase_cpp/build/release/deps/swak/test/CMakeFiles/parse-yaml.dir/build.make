# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 2.8

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canoncical targets will work.
.SUFFIXES:

# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list

# Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:
.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake

# The command to remove a file.
RM = /usr/bin/cmake -E remove -f

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /media/fusion10/work/chromatinVariation/src/ase_cpp

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /media/fusion10/work/chromatinVariation/src/ase_cpp/build/release

# Include any dependencies generated for this target.
include deps/swak/test/CMakeFiles/parse-yaml.dir/depend.make

# Include the progress variables for this target.
include deps/swak/test/CMakeFiles/parse-yaml.dir/progress.make

# Include the compile flags for this target's objects.
include deps/swak/test/CMakeFiles/parse-yaml.dir/flags.make

deps/swak/test/CMakeFiles/parse-yaml.dir/parse.cpp.o: deps/swak/test/CMakeFiles/parse-yaml.dir/flags.make
deps/swak/test/CMakeFiles/parse-yaml.dir/parse.cpp.o: ../../deps/swak/test/parse.cpp
	$(CMAKE_COMMAND) -E cmake_progress_report /media/fusion10/work/chromatinVariation/src/ase_cpp/build/release/CMakeFiles $(CMAKE_PROGRESS_1)
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Building CXX object deps/swak/test/CMakeFiles/parse-yaml.dir/parse.cpp.o"
	cd /media/fusion10/work/chromatinVariation/src/ase_cpp/build/release/deps/swak/test && /usr/bin/c++   $(CXX_DEFINES) $(CXX_FLAGS) -o CMakeFiles/parse-yaml.dir/parse.cpp.o -c /media/fusion10/work/chromatinVariation/src/ase_cpp/deps/swak/test/parse.cpp

deps/swak/test/CMakeFiles/parse-yaml.dir/parse.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/parse-yaml.dir/parse.cpp.i"
	cd /media/fusion10/work/chromatinVariation/src/ase_cpp/build/release/deps/swak/test && /usr/bin/c++  $(CXX_DEFINES) $(CXX_FLAGS) -E /media/fusion10/work/chromatinVariation/src/ase_cpp/deps/swak/test/parse.cpp > CMakeFiles/parse-yaml.dir/parse.cpp.i

deps/swak/test/CMakeFiles/parse-yaml.dir/parse.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/parse-yaml.dir/parse.cpp.s"
	cd /media/fusion10/work/chromatinVariation/src/ase_cpp/build/release/deps/swak/test && /usr/bin/c++  $(CXX_DEFINES) $(CXX_FLAGS) -S /media/fusion10/work/chromatinVariation/src/ase_cpp/deps/swak/test/parse.cpp -o CMakeFiles/parse-yaml.dir/parse.cpp.s

deps/swak/test/CMakeFiles/parse-yaml.dir/parse.cpp.o.requires:
.PHONY : deps/swak/test/CMakeFiles/parse-yaml.dir/parse.cpp.o.requires

deps/swak/test/CMakeFiles/parse-yaml.dir/parse.cpp.o.provides: deps/swak/test/CMakeFiles/parse-yaml.dir/parse.cpp.o.requires
	$(MAKE) -f deps/swak/test/CMakeFiles/parse-yaml.dir/build.make deps/swak/test/CMakeFiles/parse-yaml.dir/parse.cpp.o.provides.build
.PHONY : deps/swak/test/CMakeFiles/parse-yaml.dir/parse.cpp.o.provides

deps/swak/test/CMakeFiles/parse-yaml.dir/parse.cpp.o.provides.build: deps/swak/test/CMakeFiles/parse-yaml.dir/parse.cpp.o
.PHONY : deps/swak/test/CMakeFiles/parse-yaml.dir/parse.cpp.o.provides.build

# Object files for target parse-yaml
parse__yaml_OBJECTS = \
"CMakeFiles/parse-yaml.dir/parse.cpp.o"

# External object files for target parse-yaml
parse__yaml_EXTERNAL_OBJECTS =

deps/swak/test/parse-yaml: deps/swak/test/CMakeFiles/parse-yaml.dir/parse.cpp.o
deps/swak/test/parse-yaml: deps/swak/deps/yaml-cpp/libyaml-cpp.a
deps/swak/test/parse-yaml: deps/swak/test/CMakeFiles/parse-yaml.dir/build.make
deps/swak/test/parse-yaml: deps/swak/test/CMakeFiles/parse-yaml.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --red --bold "Linking CXX executable parse-yaml"
	cd /media/fusion10/work/chromatinVariation/src/ase_cpp/build/release/deps/swak/test && $(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/parse-yaml.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
deps/swak/test/CMakeFiles/parse-yaml.dir/build: deps/swak/test/parse-yaml
.PHONY : deps/swak/test/CMakeFiles/parse-yaml.dir/build

deps/swak/test/CMakeFiles/parse-yaml.dir/requires: deps/swak/test/CMakeFiles/parse-yaml.dir/parse.cpp.o.requires
.PHONY : deps/swak/test/CMakeFiles/parse-yaml.dir/requires

deps/swak/test/CMakeFiles/parse-yaml.dir/clean:
	cd /media/fusion10/work/chromatinVariation/src/ase_cpp/build/release/deps/swak/test && $(CMAKE_COMMAND) -P CMakeFiles/parse-yaml.dir/cmake_clean.cmake
.PHONY : deps/swak/test/CMakeFiles/parse-yaml.dir/clean

deps/swak/test/CMakeFiles/parse-yaml.dir/depend:
	cd /media/fusion10/work/chromatinVariation/src/ase_cpp/build/release && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /media/fusion10/work/chromatinVariation/src/ase_cpp /media/fusion10/work/chromatinVariation/src/ase_cpp/deps/swak/test /media/fusion10/work/chromatinVariation/src/ase_cpp/build/release /media/fusion10/work/chromatinVariation/src/ase_cpp/build/release/deps/swak/test /media/fusion10/work/chromatinVariation/src/ase_cpp/build/release/deps/swak/test/CMakeFiles/parse-yaml.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : deps/swak/test/CMakeFiles/parse-yaml.dir/depend

