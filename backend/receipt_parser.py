import requests
import json
import time
from PIL import Image
from decouple import config

# Set up API endpoint and key
endpoint = "https://tvu.cognitiveservices.azure.com/"
key = config('API_KEY')
url = f"{endpoint}formrecognizer/documentModels/prebuilt-receipt:analyze?api-version=2023-07-31"

headers = {
    "Ocp-Apim-Subscription-Key": key,
    "Content-Type": "application/json"
}

image_path = "../images/enson.jpg"

# Resize image to max allowed dimensions
with Image.open(image_path) as img:
    img.thumbnail((4200, 4200))  # Resize while keeping aspect ratio
    img.save("resized_receipt.jpg", quality=85)  # Compress slightly

print("Image resized and saved as resized_receipt.jpg")

with open("resized_receipt.jpg", "rb") as file:
    headers = {
        "Ocp-Apim-Subscription-Key": key,
        "Content-Type": "application/octet-stream",
    }
    response = requests.post(url, headers=headers, data=file)



# Check if the request was accepted
if response.status_code == 202:
    operation_url = response.headers.get("Operation-Location")
    print(f"Processing started. Checking results at: {operation_url}")

    # Polling loop: Wait for the result
    while True:
        result_response = requests.get(operation_url, headers={"Ocp-Apim-Subscription-Key": key})
        result_json = result_response.json()

        # Check if processing is complete
        status = result_json.get("status")
        if status in ["succeeded", "failed"]:
            break  # Exit loop once processing is done

        print("Processing... Waiting 3 seconds before retrying.")
        time.sleep(3)  # Wait before polling again

    # Print final result
    print(json.dumps(result_json, indent=2))

else:
    print(f"Error {response.status_code}: {response.text}")