import requests
import json
import time
from PIL import Image
from decouple import config
from fastapi import FastAPI, File, UploadFile

app = FastAPI()

# Set up API endpoint and key
endpoint = "https://tvu.cognitiveservices.azure.com/"
key = config('API_KEY')
url = f"{endpoint}formrecognizer/documentModels/prebuilt-receipt:analyze?api-version=2023-07-31"


image_path = "../images/enson.jpg"

@app.post("/upload-receipt/")
async def upload_receipt(file: UploadFile):
    headers = {
        "Ocp-Apim-Subscription-Key": key,
        "Content-Type": "application/octet-stream"
    }

    image_data = await file.read()

    # Send receipt image to Azure Document Intelligence
    response = requests.post(url, headers=headers, data=image_data)

    # Check if the request was accepted
    if response.status_code == 202:
        operation_url = response.headers.get("Operation-Location")
        print(f"Processing started. Checking results at: {operation_url}")

        # Polling loop: Wait for the result
        while True:
            result_response = requests.get(operation_url, headers=headers)
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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)  


# # Resize image to max allowed dimensions
# with Image.open(image_path) as img:
#     img.thumbnail((4200, 4200))  # Resize while keeping aspect ratio
#     img.save("resized_receipt.jpg", quality=85)  # Compress slightly

# print("Image resized and saved as resized_receipt.jpg")

# with open("resized_receipt.jpg", "rb") as file:
#     headers = {
#         "Ocp-Apim-Subscription-Key": key,
#         "Content-Type": "application/octet-stream",
#     }
#     response = requests.post(url, headers=headers, data=file)