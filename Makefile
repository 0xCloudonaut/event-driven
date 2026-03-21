.PHONY: help clean package package-place-order package-process-order package-analytics

PYTHON ?= python3
PIP ?= $(PYTHON) -m pip
BUILD_DIR := build

PLACE_ORDER_SRC := Scripts/place_order.py
PROCESS_ORDER_SRC := Scripts/process_order.py
ANALYTICS_SRC := Scripts/analytics.py

PLACE_ORDER_BUILD := $(BUILD_DIR)/place_order
PROCESS_ORDER_BUILD := $(BUILD_DIR)/process_order
ANALYTICS_BUILD := $(BUILD_DIR)/analytics

PLACE_ORDER_ZIP := place_order.zip
PROCESS_ORDER_ZIP := process_order.zip
ANALYTICS_ZIP := analytics.zip

help:
	@printf "Available targets:\n"
	@printf "  make package               Build all Lambda zip artifacts\n"
	@printf "  make package-place-order   Build $(PLACE_ORDER_ZIP)\n"
	@printf "  make package-process-order Build $(PROCESS_ORDER_ZIP)\n"
	@printf "  make package-analytics     Build $(ANALYTICS_ZIP)\n"
	@printf "  make clean                 Remove build artifacts\n"

package: package-place-order package-process-order package-analytics

package-place-order: $(PLACE_ORDER_ZIP)

package-process-order: $(PROCESS_ORDER_ZIP)

package-analytics: $(ANALYTICS_ZIP)

$(PLACE_ORDER_ZIP): $(PLACE_ORDER_SRC) requirements.txt
	rm -rf $(PLACE_ORDER_BUILD)
	mkdir -p $(PLACE_ORDER_BUILD)
	$(PIP) install -r requirements.txt -t $(PLACE_ORDER_BUILD)
	cp $(PLACE_ORDER_SRC) $(PLACE_ORDER_BUILD)/place_order.py
	cd $(PLACE_ORDER_BUILD) && zip -rq ../../$(PLACE_ORDER_ZIP) .

$(PROCESS_ORDER_ZIP): $(PROCESS_ORDER_SRC) requirements.txt
	rm -rf $(PROCESS_ORDER_BUILD)
	mkdir -p $(PROCESS_ORDER_BUILD)
	$(PIP) install -r requirements.txt -t $(PROCESS_ORDER_BUILD)
	cp $(PROCESS_ORDER_SRC) $(PROCESS_ORDER_BUILD)/process_order.py
	cd $(PROCESS_ORDER_BUILD) && zip -rq ../../$(PROCESS_ORDER_ZIP) .

$(ANALYTICS_ZIP): $(ANALYTICS_SRC) requirements.txt
	rm -rf $(ANALYTICS_BUILD)
	mkdir -p $(ANALYTICS_BUILD)
	$(PIP) install -r requirements.txt -t $(ANALYTICS_BUILD)
	cp $(ANALYTICS_SRC) $(ANALYTICS_BUILD)/analytics.py
	cd $(ANALYTICS_BUILD) && zip -rq ../../$(ANALYTICS_ZIP) .

clean:
	rm -rf $(BUILD_DIR) $(PLACE_ORDER_ZIP) $(PROCESS_ORDER_ZIP) $(ANALYTICS_ZIP)
