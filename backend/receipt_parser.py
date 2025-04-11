import requests
import json
import time
from PIL import Image
from decouple import config
from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

app = FastAPI()

# Allow all origins to make requests (for testing)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods (GET, POST, etc.)
    allow_headers=["*"],  # Allows all headers
)

# Set up API endpoint and key
endpoint = "https://michelle.cognitiveservices.azure.com/"
key = config('API_KEY')
url = f"{endpoint}formrecognizer/documentModels/prebuilt-receipt:analyze?api-version=2023-07-31"

class Item(BaseModel):
    description: str
    price: float

class TaxDetail(BaseModel):
    description: str
    amount: float

class Receipt(BaseModel):
    items: list[Item] = []
    merchant_name: str 
    subtotal: float
    tax_details: list[TaxDetail] = []
    total: float
    total_tax: float
    tip: float

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
        #print(json.dumps(result_json, indent=2))

        # write returned json to a file
        with open("receipt_result.json", "w") as result_file:
            json.dump(result_json, result_file, indent=2)

        receipt = extract_json(result_json=result_json)
        
        return receipt

    else:
        print(f"Error {response.status_code}: {response.text}")

def extract_json(result_json):
    items = []
    tax_details = []
    fields = result_json['analyzeResult']['documents'][0]['fields']
    for item in fields['Items']:
        try:
            quantity = item['Quantity']
            price = item['Price']
        except KeyError:
            quantity = 1
            price = item['TotalPrice']
        
        for i in range(quantity):
            items.append(Item(description=items['Description']['content'], price=price))

    for tax in fields['TaxDetails']:
        tax_details.append(TaxDetail(description=tax['content'], amount=tax['valueObject']['Amount']['content']))

    return Receipt(
        items=items, 
        merchant_name='',
        tax_details=tax_details,
        )


@app.get("/")
async def read_root():
    return {"message": "Hello, world!"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)