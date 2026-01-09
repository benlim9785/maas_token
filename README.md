# BytePlus ModelArk Token Caching Project

A Python project for testing and measuring cached token usage with BytePlus ModelArk API, featuring automatic billing calculation and token target management.

## Overview

This project demonstrates efficient token caching with BytePlus ModelArk by:
- Creating an initial cached system prompt from novel analysis
- Running continuous API calls that leverage cached tokens
- Tracking total token usage against a configurable target
- Calculating billing costs at $0.015 per million cached tokens

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
TARGET_TOKEN_MILLION=1
```

**Configuration Options:**
- `ARK_API_KEY`: Your BytePlus ModelArk API key
- `MODEL_ENDPOINT_ID`: Your model endpoint ID (e.g., `ep-20251224002331-ntm9r`)
- `TARGET_TOKEN_MILLION`: Target token count in millions (default: 1 million tokens)


## Usage

### Running the Project

```bash
python task.py
```

### First Run Behavior

When you run the project for the first time:

1. **Initial Setup**: Creates cached response from `novel.txt`
2. **Cache Creation**: Generates a cached system prompt
3. **Verification**: Tests the caching mechanism
4. **Token Loop**: Starts the continuous token processing

### Subsequent Runs

On subsequent runs:

1. **Cache Detection**: Loads existing cached response
2. **Token Loop**: Immediately starts token processing
3. **Progress Tracking**: Shows real-time token accumulation

## Understanding the Output

### During Execution
```
Target: 1,000,000 tokens (1.0 million)
Cost rate: $0.015 per million cached tokens
==================================================
[2024-01-09 10:30:15]: looped - cached tokens: 15,234 | total: 847,592 | target: 1,000,000
[2024-01-09 10:30:35]: looped - cached tokens: 15,234 | total: 862,826 | target: 1,000,000
```

### Final Billing Summary
```
==================================================
FINAL BILLING SUMMARY
==================================================
Target tokens: 1,000,000
Total cached tokens processed: 1,003,456
Total million tokens: 1.003456
Cost per million tokens: $0.015
Total bill: $0.015052
==================================================
```

## Configuration Options

### Adjusting Token Target

To change your token target, modify the `.env` file:

```env
# For 5 million tokens
TARGET_TOKEN_MILLION=5

# For 0.5 million tokens
TARGET_TOKEN_MILLION=0.5
```

### Using Different Model Endpoints

Update your model endpoint in `.env`:

```env
MODEL_ENDPOINT_ID="ep-your-new-endpoint-id"
```

## File Structure

```
maas_token/
├── task.py                 # Main execution script
├── main.py                 # Legacy setup script (not needed)
├── .env                    # Environment configuration
├── novel.txt               # Content for system prompt caching
├── cached_response.json    # Generated cache file (auto-created)
└── README.md               # This file
```

## Troubleshooting

### Common Issues

1. **"cached_response.json not found" but setup fails**
   - Check if `novel.txt` exists and has content
   - Verify your API key and model endpoint ID
   - Ensure caching is enabled for your model in ModelArk console

2. **No cached tokens in responses**
   - Verify caching is enabled in ModelArk console for your specific model
   - Check that you're using the correct endpoint ID
   - Ensure the model supports caching features

3. **API authentication errors**
   - Verify your `ARK_API_KEY` in the `.env` file
   - Check API key permissions in BytePlus console
   - Ensure the API key is active and not expired

### Getting Help

- **BytePlus Documentation**: [ModelArk API Docs](https://www.byteplus.com/docs/ark)
- **Console Access**: [BytePlus ModelArk Console](https://console.byteplus.com/ark/)
- **API Key Management**: [API Keys Section](https://console.byteplus.com/ark/region:ark+ap-southeast-1/apikey)

## Cost Information

- **Cached Token Rate**: $0.015 per million cached tokens
- **Real-time Tracking**: Monitor costs as tokens accumulate
- **Target-based**: Automatically stops and calculates final bill when target is reached

---

**Note**: This project is designed for testing and measuring cached token efficiency. Make sure caching is properly configured in your BytePlus ModelArk console before running the project.