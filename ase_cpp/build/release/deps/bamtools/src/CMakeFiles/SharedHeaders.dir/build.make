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

# Utility rule file for SharedHeaders.

deps/bamtools/src/CMakeFiles/SharedHeaders:
	$(CMAKE_COMMAND) -E cmake_progress_report /media/fusion10/work/chromatinVariation/src/ase_cpp/build/release/CMakeFiles $(CMAKE_PROGRESS_1)
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold "Exporting SharedHeaders"

SharedHeaders: deps/bamtools/src/CMakeFiles/SharedHeaders
SharedHeaders: deps/bamtools/src/CMakeFiles/SharedHeaders.dir/build.make
	cd /media/fusion10/work/chromatinVariation/src/ase_cpp/build/release/deps/bamtools/src && /usr/bin/cmake -E copy_if_different /media/fusion10/work/chromatinVariation/src/ase_cpp/deps/bamtools/src/shared/bamtools_global.h /media/fusion10/work/chromatinVariation/src/ase_cpp/include/shared/bamtools_global.h
.PHONY : SharedHeaders

# Rule to build all files generated by this target.
deps/bamtools/src/CMakeFiles/SharedHeaders.dir/build: SharedHeaders
.PHONY : deps/bamtools/src/CMakeFiles/SharedHeaders.dir/build

deps/bamtools/src/CMakeFiles/SharedHeaders.dir/clean:
	cd /media/fusion10/work/chromatinVariation/src/ase_cpp/build/release/deps/bamtools/src && $(CMAKE_COMMAND) -P CMakeFiles/SharedHeaders.dir/cmake_clean.cmake
.PHONY : deps/bamtools/src/CMakeFiles/SharedHeaders.dir/clean

deps/bamtools/src/CMakeFiles/SharedHeaders.dir/depend:
	cd /media/fusion10/work/chromatinVariation/src/ase_cpp/build/release && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /media/fusion10/work/chromatinVariation/src/ase_cpp /media/fusion10/work/chromatinVariation/src/ase_cpp/deps/bamtools/src /media/fusion10/work/chromatinVariation/src/ase_cpp/build/release /media/fusion10/work/chromatinVariation/src/ase_cpp/build/release/deps/bamtools/src /media/fusion10/work/chromatinVariation/src/ase_cpp/build/release/deps/bamtools/src/CMakeFiles/SharedHeaders.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : deps/bamtools/src/CMakeFiles/SharedHeaders.dir/depend

