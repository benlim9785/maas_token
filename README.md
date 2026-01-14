# BytePlus ModelArk Token Caching Project

A Python project for processing tokens with BytePlus ModelArk API, featuring configurable caching, automatic billing calculation, randomized token targets, and automated daily scheduling.

## Overview

This project processes tokens with BytePlus ModelArk by:
- Configurable caching system (enabled/disabled via .env)
- Processing novel content with randomized token targets (±5% variation)
- Running continuous API calls with real-time progress tracking
- Professional logging with timestamped files
- Automated daily scheduling via cronjob setup
- Calculating billing costs at configurable rates (default: $0.0875 per million input tokens)

## Prerequisites

### 1. Enable Caching for Model seed1.6 Flash in ModelArk

Before using this project, you must enable caching for your model in the BytePlus ModelArk console:

1. **Access BytePlus ModelArk Console**
   - Navigate to [BytePlus ModelArk Console](https://console.byteplus.com/ark/)
   - Select your region (e.g., `ark+ap-southeast-1`)

2. **Enable Model Caching**
   - Go to **Models** section
   - Find your **seed1.6 flash** model endpoint
   - Click on **Settings** or **Configuration**
   - Enable **Caching** option for the model
   - Save the configuration

   > ⚠️ **Important**: Without enabling caching, the project will not work as expected and you won't see cached token benefits.

### 2. Setup BytePlus ModelArk Endpoint

1. **Create Model Endpoint**
   - In the ModelArk console, go to **Endpoints**
   - Create a new endpoint or use existing one
   - Select **seed1.6 flash** model
   - Note down the **Endpoint ID** (format: `ep-xxxxxxxxxx-xxxxx`)

2. **Get API Key**
   - Navigate to [API Keys section](https://console.byteplus.com/ark/region:ark+ap-southeast-1/apikey)
   - Create a new API key or use existing one
   - Copy the API key securely

## Project Setup

### 1. Install Dependencies

```bash
# Install required Python packages
pip install -r requirements.txt
```

### 2. Environment Configuration

Create a `.env` file in the project root:

```env
ARK_API_KEY="your-api-key-here"
MODEL_ENDPOINT_ID="your-endpoint-id-here"
TARGET_TOKEN_MILLION=10
CACHE_ENABLED=False
CACHE_PREFIX=False
COST_PER_MILLION=0.0875
TARGET_VARIATION_PERCENT=5
```

**Configuration Options:**
- `ARK_API_KEY`: Your BytePlus ModelArk API key
- `MODEL_ENDPOINT_ID`: Your model endpoint ID (e.g., `ep-20251224002331-ntm9r`)
- `TARGET_TOKEN_MILLION`: Base target token count in millions (default: 10 million tokens)
- `CACHE_ENABLED`: Enable/disable API response caching (true/false, default: false)
- `CACHE_PREFIX`: Use cache prefix when caching is enabled (true/false, default: false)
- `COST_PER_MILLION`: Cost rate per million tokens (default: $0.0875 for input tokens)
- `TARGET_VARIATION_PERCENT`: Daily randomization percentage for token targets (default: ±5%)


## Usage

### Manual Execution

```bash
python task.py
```

The script will create timestamped log files in the `logs/` directory and display progress both in console and log file.

### Automated Daily Execution (Recommended)

#### Setup Cronjob

Use the automated setup script to install a daily cronjob:

```bash
# Setup cronjob to run daily at 9:00 AM (includes immediate run)
./scripts/setup_cronjob.sh

# Setup cronjob without running immediately
./scripts/setup_cronjob.sh --no-run
```

**What the setup script does:**
- ✅ Installs cronjob for daily 9 AM execution
- ✅ Creates logs directory
- ✅ Runs immediately for today (unless --no-run specified)
- ✅ Provides monitoring commands

#### Remove Cronjob

To completely remove the cronjob and stop any running processes:

```bash
# Remove cronjob and kill any running task.py processes
./scripts/remove_cronjob.sh
```

**What the removal script does:**
- ✅ Removes the scheduled cronjob from crontab
- ✅ Finds and kills any running task.py processes
- ✅ Uses graceful termination (SIGTERM) first, then force kill (SIGKILL) if needed
- ✅ Provides verification commands

#### Monitor Execution

```bash
# List log files to find latest run
ls -la logs/

# Watch live progress (replace with actual timestamp)
tail -f logs/task_YYYYMMDD_HHMMSS.log

# Check if task.py is currently running
ps aux | grep "python.*task.py"
```

**Benefits of Automated Scheduling**:
- 🕘 **Daily consistency**: Runs automatically every day at 9 AM
- 📊 **Individual log files**: Each run gets its own timestamped log
- 🛡️ **Process management**: Safe setup and removal with process cleanup
- ⚡ **Immediate testing**: Setup script can run immediately for validation
- 🔄 **Rate limit protection**: Prevents multiple simultaneous runs

### How It Works

**With Caching Enabled (`CACHE_ENABLED=true`):**
1. **Initial Setup**: Creates cached response from novel content in `novels/novel1.txt`
2. **Cache Creation**: Generates a cached system prompt for reuse
3. **Token Loop**: Leverages cached tokens for efficient processing

**With Caching Disabled (`CACHE_ENABLED=false`, default):**
1. **Direct Processing**: Processes full novel content on each API call
2. **Token Loop**: Tracks input tokens instead of cached tokens
3. **Higher Token Usage**: Each request processes complete novel content

**Daily Randomization:**
- Base target (e.g., 10M tokens) varies by ±5% each day
- Prevents predictable usage patterns
- Example: 10M ±5% = random target between 9.5M - 10.5M tokens

## Understanding the Output

### During Execution

**Console and Log Output:**
```
2026-01-14 14:08:53,641 - INFO - Base target: 10.0 million tokens
2026-01-14 14:08:53,642 - INFO - Variation range: 9.50M - 10.50M tokens (±5.0%)
2026-01-14 14:08:53,642 - INFO - Today's randomized target: 10,238,894 tokens (10.239M)
2026-01-14 14:08:53,642 - INFO - Cost rate: $0.0875 per million input tokens
2026-01-14 14:08:53,642 - INFO - Cache disabled - will process full novel content each request
2026-01-14 14:08:53,642 - INFO - ==================================================
2026-01-14 14:08:53,643 - INFO - looped - input tokens: 221,478 | total: 221,478 | target: 10,238,894
2026-01-14 14:09:15,822 - INFO - looped - input tokens: 221,478 | total: 442,956 | target: 10,238,894
```

### Final Billing Summary
```
2026-01-14 15:05:49,030 - INFO -
==================================================
2026-01-14 15:05:49,030 - INFO - FINAL BILLING SUMMARY
2026-01-14 15:05:49,030 - INFO - ==================================================
2026-01-14 15:05:49,030 - INFO - Caching enabled: False
2026-01-14 15:05:49,030 - INFO - Base target: 10.0M tokens
2026-01-14 15:05:49,030 - INFO - Variation range: 9.50M - 10.50M tokens (±5.0%)
2026-01-14 15:05:49,030 - INFO - Today's randomized target: 10,238,894 tokens (10.239M)
2026-01-14 15:05:49,030 - INFO - Total input tokens processed: 10,372,286
2026-01-14 15:05:49,030 - INFO - Total million tokens: 10.372286
2026-01-14 15:05:49,030 - INFO - Cost per million tokens: $0.0875
2026-01-14 15:05:49,030 - INFO - Total bill: $0.907575
2026-01-14 15:05:49,030 - INFO - ==================================================
```

## Configuration Options

### Adjusting Token Targets

To change your token processing configuration, modify the `.env` file:

```env
# For 5 million tokens base target with ±10% variation
TARGET_TOKEN_MILLION=5
TARGET_VARIATION_PERCENT=10

# For fixed 2 million tokens (no randomization)
TARGET_TOKEN_MILLION=2
TARGET_VARIATION_PERCENT=0
```

### Enabling/Disabling Caching

Control caching behavior in `.env`:

```env
# Enable caching for more efficient token reuse
CACHE_ENABLED=true
CACHE_PREFIX=true

# Disable caching for processing full content each request (default)
CACHE_ENABLED=false
CACHE_PREFIX=false
```

### Adjusting Cost Rates

Update billing calculations for different models:

```env
# For different cost models
COST_PER_MILLION=0.0875    # Current default for input tokens
COST_PER_MILLION=0.015     # Example for cached tokens
```

## File Structure

```
maas_token/
├── task.py                          # Main execution script with logging
├── main.py                          # Simple ModelArk query script
├── .env                             # Environment configuration
├── novels/                          # Novel content directory
│   └── novel1.txt                   # Content for system prompt processing
├── cached_response.json             # Generated cache file (auto-created when caching enabled)
├── scripts/                         # Automation scripts directory
│   ├── setup_cronjob.sh            # Cronjob installation and setup script
│   └── remove_cronjob.sh           # Cronjob removal and cleanup script
├── logs/                            # Execution logs directory (auto-created)
│   ├── task_YYYYMMDD_HHMMSS.log    # Timestamped log files for each run
│   └── README.md                    # Log directory documentation
├── README.md                        # Main project documentation
└── AUTOMATION_GUIDE.md              # Additional automation documentation (if exists)
```

### Key Files Explained

**Core Scripts:**
- `task.py`: Main script with professional logging and token processing
- `main.py`: Simplified script for testing single ModelArk queries

**Configuration:**
- `.env`: All configuration variables (API keys, targets, caching, costs)
- `novels/novel1.txt`: Source content for token processing

**Automation:**
- `scripts/setup_cronjob.sh`: One-command cronjob installation
- `scripts/remove_cronjob.sh`: Complete cronjob and process cleanup

**Logging:**
- `logs/`: All execution logs with timestamps
- Each run creates its own log file for easy tracking

## Troubleshooting

### Common Issues

1. **"novel.txt not found" error**
   - Ensure `novels/novel1.txt` exists and has content
   - Check the correct path: `novels/novel1.txt` (not root directory)
   - Verify file has proper UTF-8 encoding

2. **Rate limit errors (TPM limit exceeded)**
   - Wait 1-2 hours between manual runs to avoid API rate limits
   - Use `./scripts/remove_cronjob.sh` to stop duplicate processes
   - Check for multiple running instances: `ps aux | grep task.py`

3. **API authentication errors**
   - Verify your `ARK_API_KEY` in the `.env` file
   - Check API key permissions in BytePlus console
   - Ensure the API key is active and not expired

4. **Cronjob setup issues**
   - Ensure virtual environment exists: `ls venv/`
   - Check cronjob installation: `crontab -l`
   - Use `--no-run` flag to test setup without running task

5. **No log files appearing**
   - Check if `logs/` directory exists (auto-created by script)
   - Verify script has write permissions to the directory
   - Look for error messages in console output

### Getting Help

- **BytePlus Documentation**: [ModelArk API Docs](https://www.byteplus.com/docs/ark)
- **Console Access**: [BytePlus ModelArk Console](https://console.byteplus.com/ark/)
- **API Key Management**: [API Keys Section](https://console.byteplus.com/ark/region:ark+ap-southeast-1/apikey)

## Cost Information

### Current Pricing (Configurable via .env)

- **Default Input Token Rate**: $0.0875 per million input tokens
- **Cached Token Rate**: $0.015 per million cached tokens (when caching enabled)
- **Configurable**: Adjust `COST_PER_MILLION` in `.env` for different models

### Cost Examples

**With Caching Disabled (Default):**
- 10M tokens × $0.0875 = ~$0.88 per run
- Higher token usage but simpler setup

**With Caching Enabled:**
- 10M cached tokens × $0.015 = ~$0.15 per run
- Lower costs but requires ModelArk caching setup

### Features

- **Real-time Tracking**: Monitor costs as tokens accumulate
- **Target-based**: Automatically stops and calculates final bill when target is reached
- **Daily Variation**: ±5% randomization prevents predictable usage patterns
- **Detailed Billing**: Comprehensive summary with token counts and costs

---

**Note**: This project supports both cached and non-cached token processing. Caching provides cost efficiency but requires proper ModelArk console configuration. The default configuration (caching disabled) works immediately without additional setup.