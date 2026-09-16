CXX ?= clang++
CXXFLAGS ?= -std=c++20 -Wall -Wextra -Werror -pedantic -O2
INCLUDES = -Isrc
BUILD_DIR = build
TEST_BIN = $(BUILD_DIR)/latticewake_core_tests
BRIDGE_TEST_BIN = $(BUILD_DIR)/latticewake_bridge_tests
CORE_SOURCES = src/scene.cpp src/scene_v1.cpp src/event_trace.cpp src/terrain_evaluator.cpp src/scene_serialization.cpp src/offline_terrain_voice.cpp src/sample_transport.cpp src/proposals.cpp src/offline_oversampling.cpp src/role_event_generator.cpp src/direct_play.cpp src/terrain_frame.cpp src/mpe_state.cpp src/realtime_kernel.cpp src/render_plan.cpp
TEST_SOURCES = tests/core_tests.cpp
BRIDGE_SOURCES = app/Bridge/LatticewakeBridge.cpp tests/bridge_tests.cpp

.PHONY: test clean sanitizer swift-test scripts-check package bundle-verify verify-release crash-baseline crash-smoke crash-report launch-exact

test: $(TEST_BIN) $(BRIDGE_TEST_BIN) $(BUILD_DIR)/playable_tests
	$(TEST_BIN)
	$(BRIDGE_TEST_BIN)
	$(BUILD_DIR)/playable_tests

sanitizer:
	$(MAKE) BUILD_DIR=/tmp/latticewake-sanitized CXXFLAGS='-std=c++20 -Wall -Wextra -Werror -pedantic -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer' test
	/tmp/latticewake-sanitized/latticewake_core_tests
	/tmp/latticewake-sanitized/latticewake_bridge_tests
	/tmp/latticewake-sanitized/playable_tests

swift-test:
	cd app && swift test

scripts-check:
	zsh -n scripts/triage_macos_crash.sh
	zsh -n scripts/verify_macos_bundle.sh
	zsh -n scripts/launch_exact_macos_app.sh

package:
	bash app/scripts/build_macos_app.sh

$(BUILD_DIR)/playable_tests: $(CORE_SOURCES) tests/playable_tests.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(INCLUDES) $(CORE_SOURCES) tests/playable_tests.cpp -o $@

$(TEST_BIN): $(CORE_SOURCES) $(TEST_SOURCES) | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(INCLUDES) $(CORE_SOURCES) $(TEST_SOURCES) -o $(TEST_BIN)

$(BRIDGE_TEST_BIN): $(BRIDGE_SOURCES) $(CORE_SOURCES) $(wildcard src/*.hpp) app/Bridge/include/LatticewakeBridge.h | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -Iapp/Bridge/include $(BRIDGE_SOURCES) -o $(BRIDGE_TEST_BIN)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)

crash-baseline:
	zsh scripts/triage_macos_crash.sh baseline

crash-smoke:
	zsh scripts/triage_macos_crash.sh smoke

crash-report:
	zsh scripts/triage_macos_crash.sh report

launch-exact:
	zsh scripts/launch_exact_macos_app.sh

bundle-verify:
	zsh scripts/verify_macos_bundle.sh

verify-release: test sanitizer swift-test scripts-check package bundle-verify
