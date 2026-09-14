CXX ?= clang++
CXXFLAGS ?= -std=c++20 -Wall -Wextra -Werror -pedantic -O2
INCLUDES = -Isrc
BUILD_DIR = build
TEST_BIN = $(BUILD_DIR)/latticewake_core_tests
CORE_SOURCES = src/scene.cpp src/event_trace.cpp src/terrain_evaluator.cpp src/scene_serialization.cpp src/offline_terrain_voice.cpp
TEST_SOURCES = tests/core_tests.cpp

.PHONY: test clean

test: $(TEST_BIN)
	$(TEST_BIN)

$(TEST_BIN): $(CORE_SOURCES) $(TEST_SOURCES) | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(INCLUDES) $(CORE_SOURCES) $(TEST_SOURCES) -o $(TEST_BIN)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
