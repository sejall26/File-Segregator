# ABL File Segregator 🤖

An AI-powered FastAPI pipeline that reads Progress OpenEdge ABL (`.p`) files,
classifies them by business functionality using **Gemini 2.5 Flash**, copies them
into category folders, and produces a JSON report — all with a single API call.

---

## 📁 Project Structure

```
File Segregate/
├── main.py                        # FastAPI app (the whole pipeline)
├── requirements.txt               # Python dependencies
├── .env.example                   # Template for your API key
├── .env                           # Your actual API key (create this)
└── sample_abl_files/              # Demo .p files to test with
    ├── billing_invoice.p
    ├── inventory_check.p
    ├── user_auth.p
    ├── sales_order.p
    ├── monthly_report.p
    ├── customer_mgmt.p
    ├── db_utils.p
    └── string_utils.p
```

---

## ⚙️ Setup (one-time)

### 1. Create a virtual environment
```bash
python -m venv venv
venv\Scripts\activate        # Windows
```

### 2. Install dependencies
```bash
pip install -r requirements.txt
```

### 3. Add your Gemini API key
Copy `.env.example` → `.env` and paste your key:
```
GEMINI_API_KEY=AIza...your_key_here
```
Get a free key at → https://aistudio.google.com/app/apikey

---

## 🚀 Run the server

```bash
uvicorn main:app --reload
```

The API will be available at **http://127.0.0.1:8000**

---

## 🔌 API Endpoints

### `GET /`
Health check — confirms the server is running.

---

### `POST /segregate`
The main pipeline. Scans a folder, classifies every `.p` file, copies them into
category subfolders, and returns a full JSON report.

**Query Parameters:**

| Parameter | Required | Default | Description |
|---|---|---|---|
| `source_folder` | ✅ Yes | — | Full path to the folder containing `.p` files |
| `output_folder` | ❌ No | `<source_folder>/segregated_output` | Where to create category folders |
| `delay_seconds` | ❌ No | `1.5` | Pause between Gemini calls (avoids rate limits) |

**Example (Swagger UI):**
Open http://127.0.0.1:8000/docs and click **POST /segregate**, then enter:
```
source_folder = C:\File Segregate\sample_abl_files
```

**Example (curl):**
```bash
curl -X POST "http://127.0.0.1:8000/segregate?source_folder=C:\File Segregate\sample_abl_files"
```

**Example Response:**
```json
{
  "status": "success",
  "total_files_processed": 8,
  "categories_found": ["Authentication", "Billing", "Customer Management", "Database Utilities", "Inventory", "Order Processing", "Reporting", "Utility"],
  "report_path": "C:\\File Segregate\\sample_abl_files\\segregated_output\\classification_report.json",
  "results": [
    {
      "filename": "billing_invoice.p",
      "category": "Billing",
      "summary": "Handles invoice generation, line-item calculation, tax application, and late fee computation for customer billing.",
      "keywords": ["invoice", "billing", "tax", "late fee", "payment"],
      "confidence": 0.97,
      "copied_to": "C:\\...\\segregated_output\\Billing\\billing_invoice.p"
    }
  ]
}
```

---

### `GET /report`
Read the last saved `classification_report.json` from a previous run.

**Query Parameters:**

| Parameter | Required | Description |
|---|---|---|
| `output_folder` | ✅ Yes | The output folder path used in the `/segregate` call |

---

## 📂 Output Folder Structure (after running)

```
segregated_output/
├── classification_report.json     # Full JSON report
├── Billing/
│   └── billing_invoice.p
├── Inventory/
│   └── inventory_check.p
├── Authentication/
│   └── user_auth.p
├── Order_Processing/
│   └── sales_order.p
├── Reporting/
│   └── monthly_report.p
├── Customer_Management/
│   └── customer_mgmt.p
├── Database_Utilities/
│   └── db_utils.p
└── Utility/
    └── string_utils.p
```

---

## 📊 JSON Report Format

```json
{
  "total_files": 8,
  "categories_found": ["Billing", "Inventory", ...],
  "files": [
    {
      "filename": "billing_invoice.p",
      "filepath": "C:\\...\\billing_invoice.p",
      "category": "Billing",
      "summary": "Handles invoice generation...",
      "keywords": ["invoice", "billing", "tax"],
      "confidence": 0.97,
      "copied_to": "C:\\...\\segregated_output\\Billing\\billing_invoice.p",
      "error": null
    }
  ]
}
```

---

## 💡 Tips

- **Rate limits**: If you have many files, increase `delay_seconds` (e.g. `3.0`) to stay within Gemini's free-tier limits.
- **Large files**: The pipeline sends the first 6,000 characters of each file to Gemini. Adjust the `[:6000]` slice in `build_prompt()` if needed.
- **Custom output folder**: Pass `output_folder` to separate the classified files from the originals.
- **Interactive docs**: Visit http://127.0.0.1:8000/docs for the full Swagger UI.
