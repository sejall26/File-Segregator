"""
ABL File Segregator - FastAPI Application
==========================================
Reads Progress OpenEdge ABL (.p) files, classifies them using Gemini AI,
copies them into category folders, and generates a JSON report.
"""
import warnings
warnings.filterwarnings("ignore", category=FutureWarning)


import os
import json
import shutil
import time
from pathlib import Path
from typing import Optional

import google.generativeai as genai
#from google import genai
from fastapi import FastAPI, Query, HTTPException
from fastapi.responses import JSONResponse
from dotenv import load_dotenv

# ── Load environment variables ──────────────────────────────────────────────

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
if not GEMINI_API_KEY:
    raise RuntimeError("GEMINI_API_KEY not set. Please add it to your .env file.")

genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel("gemini-2.5-flash")
'''

api_key=os.getenv("G_API_KEY"),
if not G_API_KEY:
    raise RuntimeError("API_KEY not set. Please add it to your .env file.")

OpenAI
    model="grok-3",
'''


# ── FastAPI app ──────────────────────────────────────────────────────────────
app = FastAPI(
    title="ABL File Segregator",
    description="AI-powered pipeline to classify Progress OpenEdge ABL (.p) files using Gemini.",
    version="1.0.0",
)

# ── Helpers ──────────────────────────────────────────────────────────────────

def scan_abl_files(source_folder: str) -> list[Path]:
    """Recursively find all .p files in the source folder."""
    source = Path(source_folder)
    if not source.exists():
        raise FileNotFoundError(f"Source folder not found: {source_folder}")
    return list(source.rglob("*.p"))


def build_prompt(filename: str, code: str) -> str:
    """Build the classification prompt sent to Gemini."""
    return f"""You are an expert software analyst specializing in Progress OpenEdge ABL (Advanced Business Language) code.

Analyze the following ABL source file and return a JSON object with EXACTLY these four keys:
- "category"  : A short, specific business category name (e.g. "Billing", "Inventory", "Reporting",
                 "Customer Management", "Order Processing", "Authentication", "Database Utilities",
                 "Utility", or a NEW category if none of these fit — use your judgment).
- "summary"   : One or two sentences describing what this file does in plain English.
- "keywords"  : A list of 4–6 relevant keywords (as a JSON array of strings).
- "confidence": A number from 0.0 to 1.0 reflecting your confidence in the classification.

Return ONLY the raw JSON object — no markdown, no code fences, no extra explanation.

File name : {filename}

ABL Code:
\"\"\"
{code[:6000]}
\"\"\"
"""


def classify_file(file_path: Path) -> dict:
    """Send file content to Gemini and parse the classification result."""
    code = file_path.read_text(encoding="utf-8", errors="ignore")
    prompt = build_prompt(file_path.name, code)

    # Retry up to 3 times on transient errors
    for attempt in range(1, 4):
        try:
            response = model.generate_content(prompt)
            raw = response.text.strip()

            # Strip accidental markdown fences if present
            if raw.startswith("```"):
                raw = raw.split("```")[1]
                if raw.lower().startswith("json"):
                    raw = raw[4:]
                raw = raw.strip()

            result = json.loads(raw)

            # Normalise keys
            return {
                "filename": file_path.name,
                "filepath": str(file_path),
                "category": str(result.get("category", "Other")).strip(),
                "summary": str(result.get("summary", "")).strip(),
                "keywords": result.get("keywords", []),
                "confidence": float(result.get("confidence", 0.0)),
                "error": None,
            }

        except json.JSONDecodeError as e:
            if attempt == 3:
                return _error_result(file_path, f"JSON parse error after 3 attempts: {e}")
            time.sleep(2)

        except Exception as e:
            if attempt == 3:
                return _error_result(file_path, str(e))
            time.sleep(2)


def _error_result(file_path: Path, error_msg: str) -> dict:
    return {
        "filename": file_path.name,
        "filepath": str(file_path),
        "category": "Unclassified",
        "summary": "",
        "keywords": [],
        "confidence": 0.0,
        "error": error_msg,
    }


def copy_file_to_category(file_path: Path, category: str, output_root: str) -> str:
    """Create a category subfolder and copy the file into it. Returns destination path."""
    # Sanitise category name for use as folder name
    safe_cat = "".join(c if c.isalnum() or c in (" ", "_", "-") else "_" for c in category)
    safe_cat = safe_cat.strip().replace(" ", "_")

    dest_folder = Path(output_root) / safe_cat
    dest_folder.mkdir(parents=True, exist_ok=True)

    dest_file = dest_folder / file_path.name
    shutil.copy2(file_path, dest_file)
    return str(dest_file)


def save_report(results: list[dict], output_root: str) -> str:
    """Save the classification report as JSON and return its path."""
    report_path = Path(output_root) / "classification_report.json"
    report = {
        "total_files": len(results),
        "categories_found": sorted({r["category"] for r in results}),
        "files": results,
    }
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    return str(report_path)


# ── API Endpoints ────────────────────────────────────────────────────────────

@app.get("/", summary="Health check")
def root():
    return {"status": "ok", "message": "ABL File Segregator is running. Use POST /segregate to start."}


@app.post("/segregate", summary="Scan, classify, and copy ABL files")
def segregate(
    source_folder: str = Query(..., description="Full path to the folder containing .p files"),
    output_folder: Optional[str] = Query(
        None,
        description="Full path to the output folder. Defaults to <source_folder>/segregated_output",
    ),
    delay_seconds: float = Query(
        5,
        description="Seconds to wait between Gemini API calls (avoids rate-limits). Default: 5",
    ),
):
    """
    Main pipeline endpoint:
    1. Recursively scans `source_folder` for all *.p files.
    2. Sends each file's content to Gemini for classification.
    3. Copies each file into a category subfolder inside `output_folder`.
    4. Returns a JSON report with all classification details.
    """

    # ── Resolve output folder ─────────────────────────────────────────────
    if not output_folder:
        output_folder = str(Path(source_folder) / "segregated_output")
    Path(output_folder).mkdir(parents=True, exist_ok=True)

    # ── Scan files ────────────────────────────────────────────────────────
    try:
        abl_files = scan_abl_files(source_folder)
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))

    if not abl_files:
        raise HTTPException(
            status_code=404,
            detail=f"No .p files found in '{source_folder}'. Check the path and try again.",
        )

    # ── Classify and copy ─────────────────────────────────────────────────
    results = []
    for idx, file_path in enumerate(abl_files, start=1):
        print(f"[{idx}/{len(abl_files)}] Classifying: {file_path.name} ...", flush=True)

        classification = classify_file(file_path)
        dest = copy_file_to_category(file_path, classification["category"], output_folder)
        classification["copied_to"] = dest
        results.append(classification)

        # Rate-limit guard between API calls
        if idx < len(abl_files):
            time.sleep(delay_seconds)

    # ── Save report ───────────────────────────────────────────────────────
    report_path = save_report(results, output_folder)
    print(f"\nDone! Report saved to: {report_path}", flush=True)

    return JSONResponse(
        content={
            "status": "success",
            "source_folder": source_folder,
            "output_folder": output_folder,
            "total_files_processed": len(results),
            "categories_found": sorted({r["category"] for r in results}),
            "report_path": report_path,
            "results": results,
        }
    )


@app.get("/report", summary="Read the last saved classification report")
def get_report(
    output_folder: str = Query(..., description="The output folder where the report was saved"),
):
    """Returns the classification_report.json from a previous run."""
    report_path = Path(output_folder) / "classification_report.json"
    if not report_path.exists():
        raise HTTPException(
            status_code=404,
            detail=f"No report found at '{report_path}'. Run /segregate first.",
        )
    return JSONResponse(content=json.loads(report_path.read_text(encoding="utf-8")))
