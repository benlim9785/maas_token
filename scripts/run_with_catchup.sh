#!/bin/bash

# Enhanced Daily Task Runner with Catch-up Mechanism
# This script checks for missed executions and runs catch-up if needed
#
# Usage:
#   ./run_with_catchup.sh                    # Normal execution with catch-up logic
#   ./run_with_catchup.sh --force-now        # Force immediate execution
#   ./run_with_catchup.sh --immediate        # Force immediate execution (alias)
#   ./run_with_catchup.sh --help             # Show help

SCRIPT_DIR="/Users/bytedance/Desktop/maas_token"
LOG_DIR="$SCRIPT_DIR/logs"
LAST_RUN_FILE="$SCRIPT_DIR/.last_successful_run"
DATE=$(date '+%Y-%m-%d_%H-%M-%S')
TODAY=$(date '+%Y-%m-%d')

# Parse command line arguments
FORCE_NOW=false

case "$1" in
    --force-now|--immediate)
        FORCE_NOW=true
        ;;
    --help|-h)
        echo "Enhanced Daily Task Runner with Catch-up Mechanism"
        echo ""
        echo "Usage:"
        echo "  $0                    # Normal execution with catch-up logic"
        echo "  $0 --force-now        # Force immediate execution"
        echo "  $0 --immediate        # Force immediate execution (alias)"
        echo "  $0 --help             # Show this help"
        echo ""
        echo "Normal behavior:"
        echo "  - Checks if task already ran today"
        echo "  - Detects and handles missed executions"
        echo "  - Skips if already completed today"
        echo ""
        echo "Force mode (--force-now):"
        echo "  - Runs immediately regardless of previous executions"
        echo "  - Useful for testing and initial setup"
        echo "  - Will update last run date"
        exit 0
        ;;
    "")
        # No arguments - normal behavior
        ;;
    *)
        echo "Error: Unknown argument '$1'"
        echo "Use --help for usage information"
        exit 1
        ;;
esac

# Create logs directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to log messages with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to load environment variables from .env file
load_env_file() {
    local env_file=""

    # Check for .env file in common locations
    if [ -n "$ENV_FILE" ] && [ -f "$ENV_FILE" ]; then
        env_file="$ENV_FILE"
        log_message "Using custom .env file: $env_file"
    elif [ -f "$SCRIPT_DIR/.env" ]; then
        env_file="$SCRIPT_DIR/.env"
        log_message "Found .env file: $env_file"
    elif [ -f "$SCRIPT_DIR/env" ]; then
        env_file="$SCRIPT_DIR/env"
        log_message "Found env file: $env_file"
    elif [ -f "$(dirname "$SCRIPT_DIR")/.env" ]; then
        env_file="$(dirname "$SCRIPT_DIR")/.env"
        log_message "Found parent .env file: $env_file"
    else
        log_message "⚠️  No .env file found. Using existing environment variables."
        return 1
    fi

    # Load .env file
    if [ -f "$env_file" ]; then
        log_message "Loading environment variables from: $env_file"

        # Read .env file and export variables
        while IFS= read -r line || [ -n "$line" ]; do
            # Skip empty lines and comments
            if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
                continue
            fi

            # Handle lines with = (key=value format)
            if [[ "$line" =~ ^[^=]+=[^=]*$ ]]; then
                # Extract key and value
                key=$(echo "$line" | cut -d '=' -f 1)
                value=$(echo "$line" | cut -d '=' -f 2- | sed 's/^"//;s/"$//')  # Remove surrounding quotes

                # Export the variable
                export "$key"="$value"

                # Log variable loading (mask sensitive values)
                if [[ "$key" =~ (API_KEY|SECRET|PASSWORD|TOKEN) ]] && [[ ! "$key" =~ (TARGET_TOKEN) ]]; then
                    log_message "   Loaded $key=***hidden***"
                else
                    log_message "   Loaded $key=$value"
                fi
            fi
        done < "$env_file"

        return 0
    else
        log_message "❌ Environment file not found: $env_file"
        return 1
    fi
}

# Load environment variables at startup
log_message "🔧 Loading environment configuration..."
load_env_file

# Cross-platform timeout function
run_with_timeout() {
    local timeout_seconds="$1"
    shift
    local command="$@"

    # Try different timeout commands in order of preference
    if command -v timeout >/dev/null 2>&1; then
        # Linux/GNU timeout
        timeout "$timeout_seconds" $command
    elif command -v gtimeout >/dev/null 2>&1; then
        # macOS with coreutils (brew install coreutils)
        gtimeout "$timeout_seconds" $command
    else
        # No timeout available - run without timeout but log warning
        log_message "⚠️  Warning: No timeout command available. Running without timeout protection."
        log_message "   To install timeout on macOS: brew install coreutils"
        $command
    fi
}

# Function to run the main task
run_main_task() {
    local run_type="$1"
    local log_file="$LOG_DIR/task_${run_type}_${DATE}.log"

    log_message "Starting $run_type execution" | tee -a "$log_file"
    log_message "Log file: $log_file" | tee -a "$log_file"

    # Change to script directory
    cd "$SCRIPT_DIR" || {
        log_message "ERROR: Failed to change to script directory" | tee -a "$log_file"
        return 1
    }

    # Detect the correct Python interpreter (prefer activated virtual environment)
    local python_cmd="python3"

    # Check for activated virtual environment
    if [ -n "$VIRTUAL_ENV" ] && [ -x "$VIRTUAL_ENV/bin/python" ]; then
        python_cmd="$VIRTUAL_ENV/bin/python"
        log_message "Using virtual environment Python: $python_cmd" | tee -a "$log_file"
    # Check for Conda environment
    elif [ -n "$CONDA_PREFIX" ] && [ -x "$CONDA_PREFIX/bin/python" ]; then
        python_cmd="$CONDA_PREFIX/bin/python"
        log_message "Using Conda environment Python: $python_cmd" | tee -a "$log_file"
    # Auto-detect common virtual environment locations
    elif [ -x "$SCRIPT_DIR/env/bin/python" ]; then
        python_cmd="$SCRIPT_DIR/env/bin/python"
        log_message "Found local virtual environment: $python_cmd" | tee -a "$log_file"
    elif [ -x "$SCRIPT_DIR/venv/bin/python" ]; then
        python_cmd="$SCRIPT_DIR/venv/bin/python"
        log_message "Found local virtual environment: $python_cmd" | tee -a "$log_file"
    elif [ -x "$SCRIPT_DIR/.venv/bin/python" ]; then
        python_cmd="$SCRIPT_DIR/.venv/bin/python"
        log_message "Found local virtual environment: $python_cmd" | tee -a "$log_file"
    # Fall back to system Python
    elif command -v python3 >/dev/null 2>&1; then
        python_cmd="python3"
        log_message "Using system Python3: $(which python3)" | tee -a "$log_file"
        log_message "⚠️  Warning: Using system Python. Consider using a virtual environment." | tee -a "$log_file"
    elif command -v python >/dev/null 2>&1; then
        python_cmd="python"
        log_message "Using system Python: $(which python)" | tee -a "$log_file"
        log_message "⚠️  Warning: Using system Python. Consider using a virtual environment." | tee -a "$log_file"
    else
        log_message "ERROR: No Python interpreter found" | tee -a "$log_file"
        return 1
    fi

    # Run the task with cross-platform timeout (2 hours)
    log_message "Executing: $python_cmd task.py" | tee -a "$log_file"
    run_with_timeout 7200 "$python_cmd" task.py >> "$log_file" 2>&1
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        log_message "$run_type execution completed successfully" | tee -a "$log_file"
        echo "$TODAY" > "$LAST_RUN_FILE"
        ln -sf "$log_file" "$LOG_DIR/latest.log"
        return 0
    else
        log_message "ERROR: $run_type execution failed with exit code $exit_code" | tee -a "$log_file"
        return $exit_code
    fi
}

# Check if forced execution is requested
if [ "$FORCE_NOW" = true ]; then
    if [ -f "$LAST_RUN_FILE" ]; then
        LAST_RUN_DATE=$(cat "$LAST_RUN_FILE")
        log_message "🚀 FORCE MODE: Ignoring last run date ($LAST_RUN_DATE)"
    else
        log_message "🚀 FORCE MODE: No previous run history"
    fi
    log_message "🔄 Running forced execution..."
    run_main_task "forced"
else
    # Normal execution logic with catch-up mechanism
    if [ -f "$LAST_RUN_FILE" ]; then
        LAST_RUN_DATE=$(cat "$LAST_RUN_FILE")
        log_message "Last successful run: $LAST_RUN_DATE"

        if [ "$LAST_RUN_DATE" = "$TODAY" ]; then
            log_message "✅ Task already completed today. Skipping execution."
            log_message "💡 Use --force-now to run anyway"
            exit 0
        elif [ "$LAST_RUN_DATE" != "$TODAY" ]; then
            # Calculate days missed
            LAST_TIMESTAMP=$(date -j -f "%Y-%m-%d" "$LAST_RUN_DATE" "+%s" 2>/dev/null)
            TODAY_TIMESTAMP=$(date -j -f "%Y-%m-%d" "$TODAY" "+%s")

            if [ -n "$LAST_TIMESTAMP" ] && [ -n "$TODAY_TIMESTAMP" ]; then
                DAYS_MISSED=$(( (TODAY_TIMESTAMP - LAST_TIMESTAMP) / 86400 - 1 ))

                if [ $DAYS_MISSED -gt 0 ]; then
                    log_message "⚠️  Detected $DAYS_MISSED missed day(s) since $LAST_RUN_DATE"
                    log_message "🔄 Running catch-up execution..."
                    run_main_task "catchup"
                else
                    log_message "🔄 Running scheduled execution..."
                    run_main_task "scheduled"
                fi
            else
                log_message "🔄 Running execution (date calculation failed)..."
                run_main_task "scheduled"
            fi
        fi
    else
        log_message "🆕 First time setup - no previous run detected"
        log_message "🔄 Running initial execution..."
        run_main_task "initial"
    fi
fi