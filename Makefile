NAME = main # Your project's name

# Select language 
LANG = c
# LANG = cpp

# General flags
CXXFLAGS = -O2 -Wall -DNDEBUG -I$(IPATH)
CXX =
ifeq ($(LANG),c)
	CXX = gcc
	CXXFLAGS +=
else 
	ifeq ($(LANG),cpp)
		CXX = g++
		CXXFLAGS += -std=c++11
	endif
endif

# [WARNING] Be careful with space in Makefile 
# Path for object library
OPATH = lib/build
# Path for library source file
SPATH = lib/src
# Path for library header files 
IPATH = lib/inc

# Get all source files in /lib/src and its subdirectories 
SOURCE_LIBS = $(wildcard $(SPATH)/**/*.$(LANG) $(SPATH)/*.$(LANG))

# Get all header files in lib/inc and its subdirectories
HEADER_LIBS = $(wildcard $(IPATH)/**/*.h $(IPATH)/*.h)

# Get all object files by substituting .cpp/.c by .o
# More info: Google "patsubst in Makefile"
OBJ_LIBS = $(patsubst $(SPATH)/%.$(LANG), $(OPATH)/%.o, $(SOURCE_LIBS))

# Necessary files and directories for project
FILES = LICENSE README.md
DIRS = bin lib $(OPATH) $(SPATH) $(IPATH) src

all: $(OBJ_LIBS) $(NAME)

# Compile object files
class: $(OBJ_LIBS)

# Compile object libraries 
$(OBJ_LIBS): CXXFLAGS += -c # flag for compiling object libraries
$(OBJ_LIBS): $(SOURCE_LIBS) $(HEADER_LIBS) 
	@echo Building object libraries...
	@$(CXX) $(CXXFLAGS) $(SOURCE_LIBS)

	@# Move *.o to lib/build 
	@# [EXPLAIN] g++ can not generate multiple files into a specified directory
	@mv *.o -v $(OPATH)
	@echo Finished.

# Compile executive file from src named $(NAME)
$(NAME): $(SOURCE_LIBS) $(HEADER_LIBS) src/main.$(LANG)
	@echo Building executive file...
	@$(CXX) $(CXXFLAGS) src/main.$(LANG) $(OBJ_LIBS) -o $@
	@echo Finished.

# Make necessary directories and file
.PHONY: configure
configure:
	@echo Creating neccessary files and directories...
	@mkdir -p $(DIRS)
	@touch $(FILES)
	@echo Finished.

	@# [TODO] It seems like speeding Catch Unite Testing does not work properly, 
	@# it requires C++11, even though I turn flag -std=c++11 on.

	@# Uncomment these lines for configuring unit testing
	@# Download Makefile for Unit Testing from Github
	@#$(RM) test/Makefile
	@#echo Download necessary files...
	@#wget -P test/ $(MAKEFILE_TEST_LINK)
	@# Make the Makefile in test for unit testing
	@# make -C <dir> <option> is for changing the directory for multiple make
	@#make -C test configure 
	@#echo Finished

# For debugging purpose.
.PHONY: debug
debug: CXXFLAGS += -g # flag for debuging
debug: 
	@echo Create debuging file...
	@# Generate a.out
	@$(CXX) $(CXXFLAGS) src/main.$(LANG) $(OBJ_LIBS) 
	
	@# Move a.out to bin/ 
	@# [EXPLAIN] g++ can not generate miltiple files to a specified directory.
	@mv a.out bin/
	@echo Finished.

	@echo Entering debugging mode.
	@gdb bin/a.out 

.PHONY: clean
clean: EXEC_FILES = $(shell find -type f -executable) # Find executable files
clean:
	@echo Cleaning following files: [$(OBJ_LIBS) $(EXEC_FILES)]...
	@$(RM) $(OBJ_LIBS) $(EXEC_FILES)
	@echo Finished.