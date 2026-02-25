# encoding=utf-8
import os
import json
import random
import logging
from byteplussdkarkruntime import Ark
from byteplussdkarkruntime._exceptions import ArkBadRequestError
from dotenv import load_dotenv
import time
from datetime import datetime

load_dotenv()

# Setup logging with timestamp-based filename
os.makedirs('logs', exist_ok=True)
log_filename = f"logs/task_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"

# Configure logging to both file and console
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_filename),
        logging.StreamHandler()  # This will also print to console
    ]
)
log = logging.getLogger(__name__)

# Get configuration from environment
api_key = os.getenv('ARK_API_KEY')
model_endpoint_id = os.getenv('MODEL_ENDPOINT_ID')
target_token_million = float(os.getenv('TARGET_TOKEN_MILLION', 1))
target_variation_percent = float(os.getenv('TARGET_VARIATION_PERCENT', 0))
cache_enabled = os.getenv('CACHE_ENABLED', 'true').lower() == 'true'
cache_prefix = os.getenv('CACHE_PREFIX', 'true').lower() == 'true'
cost_per_million = float(os.getenv('COST_PER_MILLION', 0.015))

# Calculate randomized target
def calculate_random_target():
    base_tokens = target_token_million * 1_000_000
    if target_variation_percent > 0:
        variation_amount = base_tokens * (target_variation_percent / 100)
        min_tokens = base_tokens - variation_amount
        max_tokens = base_tokens + variation_amount
        random_target = random.uniform(min_tokens, max_tokens)
        return int(random_target)
    return int(base_tokens)

client = Ark(
    base_url='https://ark.ap-southeast.bytepluses.com/api/v3',
    api_key=api_key,
)

# Check if caching is enabled
cached_response_id = None

if cache_enabled:
    # Only use caching logic if cache is enabled
    if not os.path.exists('cached_response.json'):
        log.info("cached_response.json not found. Creating initial cached response...")

        # Load content from novel.txt
        try:
            with open('novels/novel1.txt', 'r', encoding='utf-8') as f:
                novel_content = f.read()
        except FileNotFoundError:
            log.error("Error: novel.txt not found. Please ensure novel.txt exists in the current directory.")
            exit(1)

        # Create initial response with novel analysis
        input_text = f'''You are an expert in analyzing novels. Please analyze issues related to the following content: {novel_content}'''

        log.info("Creating initial cached response...")
        initial_response = client.responses.create(
            model=model_endpoint_id,
            input=[
                {
                    "role": "system",
                    "content": input_text,
                }
            ],
            caching={"type": "enabled", "prefix": cache_prefix},
            thinking={"type": "disabled"},
        )

        log.info("Initial response usage:")
        log.info(initial_response.usage.model_dump_json())

        # Save response ID to JSON file for future use
        with open('cached_response.json', 'w') as f:
            json.dump({'response_id': initial_response.id}, f)

        cached_response_id = initial_response.id
        log.info(f"Cached response created and saved. ID: {cached_response_id}")
    else:
        # Load existing cached response ID
        with open('cached_response.json', 'r') as f:
            cached_data = json.load(f)
            cached_response_id = cached_data['response_id']
        log.info(f"Found existing cached response. ID: {cached_response_id}")
        log.info("Starting token processing loop...\n")
else:
    log.info("Caching is disabled. Running without cache...")
    log.info("Note: Without caching, each request will process the full novel content.")

# Token tracking variables
total_cached_tokens = 0
target_tokens = calculate_random_target()

def loop():
    global total_cached_tokens, cached_response_id

    if cache_enabled and cached_response_id:
        # Use cached responses when caching is enabled
        try:
            response = client.responses.create(
                model=model_endpoint_id,
                previous_response_id=cached_response_id,
                input=[{"role": "user", "content": "What is the main theme expressed in the above text?"}],
                caching={"type": "enabled"},
                thinking={"type": "disabled"},
                max_output_tokens=1
            )
        except ArkBadRequestError as e:
            error_data = e.args[0] if e.args else {}
            if isinstance(error_data, dict) and error_data.get('code') == 'InvalidParameter.PreviousResponseNotFound':
                log.warning(f"Previous response not found: {error_data.get('message', 'Unknown error')}")
                log.info("Removing cached_response.json and triggering fresh session...")
                if os.path.exists('cached_response.json'):
                    os.remove('cached_response.json')
                    log.info("cached_response.json removed successfully.")
                else:
                    log.info("cached_response.json not found, nothing to remove.")
                # Reset cached_response_id to trigger fresh session creation
                cached_response_id = None
                log.info("Restarting with fresh session...")
                return False  # Return False to continue the loop, which will create a new session
            else:
                # Re-raise if it's a different error
                raise

        cached_tokens = response.usage.input_tokens_details.cached_tokens if response.usage.input_tokens_details else 0
        total_cached_tokens += cached_tokens
        log.info(f"looped - cached tokens: {cached_tokens:,} | total: {total_cached_tokens:,} | target: {target_tokens:,}")

    else:
        # When caching is disabled, make fresh requests with full novel content
        try:
            with open('novels/novel1.txt', 'r', encoding='utf-8') as f:
                novel_content = f.read()
        except FileNotFoundError:
            log.error("Error: novel.txt not found.")
            return True  # Exit the loop

        response = client.responses.create(
            model=model_endpoint_id,
            input=[
                {
                    "role": "system",
                    "content": f"You are an expert in analyzing novels. Please analyze issues related to the following content: {novel_content}"
                },
                {
                    "role": "user",
                    "content": "What is the main theme expressed in the above text?"
                }
            ],
            caching={"type": "disabled"},
            thinking={"type": "disabled"},
            max_output_tokens=1
        )

        # Track input tokens instead of cached tokens when not using cache
        input_tokens = response.usage.input_tokens
        total_cached_tokens += input_tokens
        log.info(f"looped - input tokens: {input_tokens:,} | total: {total_cached_tokens:,} | target: {target_tokens:,}")

    return total_cached_tokens >= target_tokens

def calculate_and_show_bill():
    total_million_tokens = total_cached_tokens / 1_000_000
    total_cost = total_million_tokens * cost_per_million

    log.info(f"\n{'='*50}")
    log.info(f"FINAL BILLING SUMMARY")
    log.info(f"{'='*50}")
    log.info(f"Caching enabled: {cache_enabled}")
    log.info(f"Base target: {target_token_million}M tokens")
    if target_variation_percent > 0:
        min_target = target_token_million * (1 - target_variation_percent/100)
        max_target = target_token_million * (1 + target_variation_percent/100)
        log.info(f"Variation range: {min_target:.2f}M - {max_target:.2f}M tokens (±{target_variation_percent}%)")
        log.info(f"Today's randomized target: {target_tokens:,} tokens ({target_tokens/1_000_000:.3f}M)")
    else:
        log.info(f"Fixed target: {target_tokens:,} tokens")
    if cache_enabled:
        log.info(f"Total cached tokens processed: {total_cached_tokens:,}")
    else:
        log.info(f"Total input tokens processed: {total_cached_tokens:,}")
    log.info(f"Total million tokens: {total_million_tokens:.6f}")
    log.info(f"Cost per million tokens: ${cost_per_million}")
    log.info(f"Total bill: ${total_cost:.6f}")
    log.info(f"{'='*50}")

log.info(f"Base target: {target_token_million} million tokens")
if target_variation_percent > 0:
    min_target = target_token_million * (1 - target_variation_percent/100)
    max_target = target_token_million * (1 + target_variation_percent/100)
    log.info(f"Variation range: {min_target:.2f}M - {max_target:.2f}M tokens (±{target_variation_percent}%)")
    log.info(f"Today's randomized target: {target_tokens:,} tokens ({target_tokens/1_000_000:.3f}M)")
else:
    log.info(f"Fixed target: {target_tokens:,} tokens")

if cache_enabled:
    log.info(f"Cost rate: ${cost_per_million} per million cached tokens")
    log.info(f"Cache enabled with prefix: {cache_prefix}")
else:
    log.info(f"Cost rate: ${cost_per_million} per million input tokens")
    log.info(f"Cache disabled - will process full novel content each request")
log.info(f"{'='*50}")

while True:
    target_reached = loop()

    if target_reached:
        calculate_and_show_bill()
        break

    time.sleep(20)