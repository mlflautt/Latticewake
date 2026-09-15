CXX ?= clang++
CXXFLAGS ?= -std=c++20 -Wall -Wextra -Werror -pedantic -O2
INCLUDES = -Isrc
BUILD_DIR = build
TEST_BIN = $(BUILD_DIR)/latticewake_core_tests
BRIDGE_TEST_BIN = $(BUILD_DIR)/latticewake_bridge_tests
CORE_SOURCES = src/scene.cpp src/event_trace.cpp src/terrain_evaluator.cpp src/scene_serialization.cpp src/offline_terrain_voice.cpp src/sample_transport.cpp src/proposals.cpp src/offline_oversampling.cpp src/role_event_generator.cpp src/direct_play.cpp src/terrain_frame.cpp src/mpe_state.cpp src/realtime_kernel.cpp
TEST_SOURCES = tests/core_tests.cpp
BRIDGE_SOURCES = app/Bridge/LatticewakeBridge.cpp tests/bridge_tests.cpp

.PHONY: test clean

test: $(TEST_BIN) $(BRIDGE_TEST_BIN)
	$(TEST_BIN)
	$(BRIDGE_TEST_BIN)

$(TEST_BIN): $(CORE_SOURCES) $(TEST_SOURCES) | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(INCLUDES) $(CORE_SOURCES) $(TEST_SOURCES) -o $(TEST_BIN)

$(BRIDGE_TEST_BIN): $(BRIDGE_SOURCES) src/realtime_event_queue.hpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -Iapp/Bridge/include $(BRIDGE_SOURCES) -o $(BRIDGE_TEST_BIN)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
