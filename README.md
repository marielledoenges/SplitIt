# SplitIt
Receipt JSON Schema: https://github.com/Azure-Samples/document-intelligence-code-samples/blob/main/schema/2024-11-30-ga/receipt.md

Within "analyzeResult", we are only interested in "documents". Depending on the "docType" ("receipt", "receipt.retailMeal", "receipt.creditCard", "receipt.gas", "receipt.hotel"), there will be different schemas.

We want to extract the following fields:
#### receipt.retailMeal
| Field | Type | Description | Example |
|:------|:-----|:------------|:--------|
|`Items`|`array`|||
|`Items.*`|`object`|Extracted line item|1<br>Surface Pro 6<br>$999.00<br>$999.00|
|`Items.*.TotalPrice`|`currency`|Total price of line item|$999.00|
|`Items.*.Description.content`|`string`|Item description|Surface Pro 6|
|`Items.*.Quantity`|`number`|Quantity of each item|1|
|`Items.*.Price`|`currency`|Individual price of each item unit|$999.00|
|`MerchantName.content`|`string`|Name of the merchant issuing the receipt|Contoso|
|`Subtotal.valueNumber`|`number`|Subtotal of receipt, often before taxes are applied|$12.34|
|`TaxDetails`|`array`|List of tax details||
|`TaxDetails.*`|`object`|A single tax detail|Sales Tax(10%) $10.00 $1.00 $11.00|
|`TaxDetails.*.Amount.valueCurrency`|`currency`|The amount of the tax detail|$1.00|
|`TaxDetails.*.Description.content`|`string`|The description of the tax detail|Sales Tax|
|`Total.valueNumber`|`number`|Full transaction total of receipt|$14.34|
|`TotalTax.valueNumber`|`number`|Tax on receipt, often sales tax or equivalent|$2.00|
|`Tip.valueNumber`|`number`|Tip included by buyer|$1.00|


If a Quantity exists for an Item, extract the Quantity n and create n Item elements with individual Price of each item unit.