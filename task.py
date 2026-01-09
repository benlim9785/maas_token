# encoding=utf-8
import os
import json
from byteplussdkarkruntime import Ark
from dotenv import load_dotenv
import time
from datetime import datetime

load_dotenv()

# Get configuration from environment
api_key = os.getenv('ARK_API_KEY')
model_endpoint_id = os.getenv('MODEL_ENDPOINT_ID')
target_token_million = float(os.getenv('TARGET_TOKEN_MILLION', 1))

client = Ark(
    base_url='https://ark.ap-southeast.bytepluses.com/api/v3',
    api_key=api_key,
)

# Check if cached response exists, create if not
cached_response_id = None

if not os.path.exists('cached_response.json'):
    print("cached_response.json not found. Creating initial cached response...")

    # Load content from novel.txt
    try:
        with open('novel.txt', 'r', encoding='utf-8') as f:
            novel_content = f.read()
    except FileNotFoundError:
        print("Error: novel.txt not found. Please ensure novel.txt exists in the current directory.")
        exit(1)

    # Create initial response with novel analysis
    input_text = f'''You are an expert in analyzing novels. Please analyze issues related to the following content: {novel_content}'''

    print("Creating initial cached response...")
    initial_response = client.responses.create(
        model=model_endpoint_id,
        input=[
            {
                "role": "system",
                "content": input_text,
            }
        ],
        caching={"type": "enabled", "prefix": True},
        thinking={"type": "disabled"},
    )

    print("Initial response usage:")
    print(initial_response.usage.model_dump_json())

    # Save response ID to JSON file for future use
    with open('cached_response.json', 'w') as f:
        json.dump({'response_id': initial_response.id}, f)

    cached_response_id = initial_response.id
    print(f"Cached response created and saved. ID: {cached_response_id}")
else:
    # Load existing cached response ID
    with open('cached_response.json', 'r') as f:
        cached_data = json.load(f)
        cached_response_id = cached_data['response_id']
    print(f"Found existing cached response. ID: {cached_response_id}")
    print("Starting token processing loop...\n")

# Token tracking variables
total_cached_tokens = 0
target_tokens = target_token_million * 1_000_000
cost_per_million = 0.015

def loop():
    global total_cached_tokens

    # Continue with second prompt using cached system prompt
    response = client.responses.create(
        model=model_endpoint_id,
        previous_response_id=cached_response_id,
        input=[{"role": "user", "content": "What is the main theme expressed in the above text?"}],
        caching={"type": "enabled"},
        thinking={"type": "disabled"},
        max_output_tokens=1
    )

    cached_tokens = response.usage.input_tokens_details.cached_tokens
    total_cached_tokens += cached_tokens

    print(f"[{datetime.now()}]: looped - cached tokens: {cached_tokens:,} | total: {total_cached_tokens:,} | target: {target_tokens:,}")

    return total_cached_tokens >= target_tokens

def calculate_and_show_bill():
    total_million_tokens = total_cached_tokens / 1_000_000
    total_cost = total_million_tokens * cost_per_million

    print(f"\n{'='*50}")
    print(f"FINAL BILLING SUMMARY")
    print(f"{'='*50}")
    print(f"Target tokens: {target_tokens:,}")
    print(f"Total cached tokens processed: {total_cached_tokens:,}")
    print(f"Total million tokens: {total_million_tokens:.6f}")
    print(f"Cost per million tokens: ${cost_per_million}")
    print(f"Total bill: ${total_cost:.6f}")
    print(f"{'='*50}")

print(f"Target: {target_tokens:,} tokens ({target_token_million} million)")
print(f"Cost rate: ${cost_per_million} per million cached tokens")
print(f"{'='*50}")

while True:
    target_reached = loop()

    if target_reached:
        calculate_and_show_bill()
        break

    time.sleep(20)