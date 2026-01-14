import os
import argparse
from byteplussdkarkruntime import Ark
from dotenv import load_dotenv

load_dotenv()

def main():
    parser = argparse.ArgumentParser(description='Simple ModelArk query script with token usage tracking')
    parser.add_argument('file_path', help='Path to the novel/text file to analyze')
    parser.add_argument('--model', '-m',
                       default=os.getenv('MODEL_ENDPOINT_ID'),
                       help='Model endpoint ID (default: from MODEL_ENDPOINT_ID env var)')
    parser.add_argument('--query', '-q',
                       default="What is the main theme of this text?",
                       help='Query to send to the model (default: "What is the main theme of this text?")')

    args = parser.parse_args()

    # Validate arguments
    if not args.model:
        print("Error: Model ID is required. Set MODEL_ENDPOINT_ID env var or use --model")
        return 1

    if not os.path.exists(args.file_path):
        print(f"Error: File not found: {args.file_path}")
        return 1

    # Get API key from environment
    api_key = os.getenv('ARK_API_KEY')
    if not api_key:
        print("Error: ARK_API_KEY environment variable is required")
        return 1

    # API key loaded successfully

    # Initialize Ark client
    client = Ark(
        base_url='https://ark.ap-southeast.bytepluses.com/api/v3',
        api_key=api_key,
    )

    # Read the text file
    try:
        with open(args.file_path, 'r', encoding='utf-8') as f:
            text_content = f.read()
    except Exception as e:
        print(f"Error reading file: {e}")
        return 1

    print(f"File: {args.file_path}")
    print(f"File size: {len(text_content):,} characters")
    print(f"Model: {args.model}")
    print(f"Query: {args.query}")
    print(f"{'='*50}")

    # Test model access with a minimal request first
    print("Testing model access...")
    try:
        client.responses.create(
            model=args.model,
            input=[
                {
                    "role": "user",
                    "content": "Hello"
                }
            ],
            max_output_tokens=5
        )
        print("✅ Model access confirmed!")

    except Exception as e:
        print(f"❌ Model access failed: {e}")
        print("\nPossible solutions:")
        print("1. Check if model endpoint ID is correct")
        print("2. Verify API key has access to this model")
        print("3. Try a different model endpoint")
        return 1

    # Create the ModelArk request
    try:
        response = client.responses.create(
            model=args.model,
            input=[
                {
                    "role": "system",
                    "content": f"You are an expert text analyst. Please analyze the following text: {text_content}"
                },
                {
                    "role": "user",
                    "content": args.query
                }
            ],
            thinking={"type": "disabled"},
        )

        # Display the response - BytePlus SDK structure
        print(f"RESPONSE:")

        # Extract content from BytePlus response structure
        try:
            if hasattr(response, 'output') and response.output:
                # BytePlus ModelArk response structure: response.output[0].content[0].text
                response_text = response.output[0].content[0].text
                print(f"{response_text}")
            else:
                print("Could not extract response content")
                print(f"Response object: {response}")
        except (IndexError, AttributeError) as e:
            print(f"Error extracting response content: {e}")
            print(f"Response structure: {type(response)}")

        print(f"\n{'='*50}")

        # Display token usage information
        print(f"TOKEN USAGE:")
        print(f"{'='*50}")
        usage = response.usage

        print(f"Input tokens: {usage.input_tokens:,}")
        print(f"Output tokens: {usage.output_tokens:,}")
        print(f"Total tokens: {usage.total_tokens:,}")

        # Show detailed token breakdown if available
        if hasattr(usage, 'input_tokens_details') and usage.input_tokens_details:
            details = usage.input_tokens_details
            if hasattr(details, 'cached_tokens') and details.cached_tokens:
                print(f"Cached tokens: {details.cached_tokens:,}")

        # Calculate estimated costs (using typical ModelArk pricing)
        cost_per_1k_input = 0.0015  # Example rate - adjust based on actual model pricing
        cost_per_1k_output = 0.002  # Example rate - adjust based on actual model pricing

        input_cost = (usage.input_tokens / 1000) * cost_per_1k_input
        output_cost = (usage.output_tokens / 1000) * cost_per_1k_output
        total_cost = input_cost + output_cost

        print(f"\nESTIMATED COSTS:")
        print(f"Input cost: ${input_cost:.6f}")
        print(f"Output cost: ${output_cost:.6f}")
        print(f"Total cost: ${total_cost:.6f}")

        return 0

    except Exception as e:
        print(f"Error calling ModelArk API: {e}")
        return 1

if __name__ == "__main__":
    exit(main())