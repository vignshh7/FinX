import os
import re
import tempfile
from datetime import datetime
import requests
from PIL import Image


class OCRService:
    """
    Strict OCR service that uses OCR.space only.
    No mock or synthetic fallback data is returned.
    """

    def __init__(self):
        self.api_key = os.getenv("OCR_SPACE_API_KEY", "K85785367588957")
        self.api_url = os.getenv("OCR_SPACE_API_URL", "https://api.ocr.space/parse/image")
        self.timeout_seconds = int(os.getenv("OCR_SPACE_TIMEOUT_SECONDS", "60"))
        self.max_upload_bytes = 1024 * 1024

    @staticmethod
    def _safe_float(value):
        try:
            return float(value)
        except (TypeError, ValueError):
            return 0.0

    @staticmethod
    def _normalize_line(line):
        return re.sub(r"\s+", " ", (line or "").strip().lower())

    @staticmethod
    def _amount_from_match(match_value):
        cleaned = str(match_value).replace(",", "").strip()
        try:
            return float(cleaned)
        except (TypeError, ValueError):
            return 0.0

    def _extract_amount_candidates(self, text):
        lines = [line.strip() for line in text.split("\n") if line.strip()]
        candidates = []
        total_keywords = [
            "grand total",
            "total due",
            "amount due",
            "net payable",
            "total",
            "balance due",
        ]
        subtotal_keywords = ["subtotal", "sub total"]
        tax_keywords = ["tax", "gst", "vat", "service tax", "cgst", "sgst", "igst"]
        payment_keywords = [
            "cash",
            "change",
            "tendered",
            "visa",
            "mastercard",
            "card",
            "auth",
            "tip",
            "paid",
            "payment",
        ]

        for idx, raw_line in enumerate(lines):
            normalized = self._normalize_line(raw_line)
            amounts = re.findall(r"\$?\s*([0-9][0-9,]*\.[0-9]{2})", raw_line)
            for match in amounts:
                value = self._amount_from_match(match)
                if not (0.01 <= value <= 100000):
                    continue

                candidate_type = "generic"
                if any(keyword in normalized for keyword in total_keywords):
                    candidate_type = "total_line"
                elif any(keyword in normalized for keyword in subtotal_keywords):
                    candidate_type = "subtotal_line"
                elif any(keyword in normalized for keyword in tax_keywords):
                    candidate_type = "tax_line"
                elif any(keyword in normalized for keyword in payment_keywords):
                    candidate_type = "payment_line"

                candidates.append(
                    {
                        "value": round(value, 2),
                        "line": raw_line,
                        "line_index": idx,
                        "line_norm": normalized,
                        "candidate_type": candidate_type,
                    }
                )

        return candidates, lines

    def _score_amount_candidate(self, candidate, lines, item_sum, ocr_amount):
        score = 0.25
        line_norm = candidate["line_norm"]
        line_index = candidate["line_index"]
        value = candidate["value"]
        total_lines = max(len(lines), 1)

        if candidate["candidate_type"] == "total_line":
            score += 0.9
        elif candidate["candidate_type"] == "subtotal_line":
            score += 0.35
        elif candidate["candidate_type"] == "tax_line":
            score += 0.2
        elif candidate["candidate_type"] == "payment_line":
            score -= 0.15

        # Totals are usually printed in the lower part of the bill.
        score += 0.25 * (line_index / total_lines)

        if "grand total" in line_norm or "total due" in line_norm or "amount due" in line_norm:
            score += 0.35

        if any(token in line_norm for token in ["change", "tendered", "tip"]):
            score -= 0.3

        if ocr_amount > 0:
            diff_ratio = abs(value - ocr_amount) / max(value, ocr_amount)
            if diff_ratio <= 0.03:
                score += 0.25
            elif diff_ratio <= 0.12:
                score += 0.12

        if item_sum > 0:
            diff_ratio = abs(value - item_sum) / max(value, item_sum)
            if diff_ratio <= 0.03:
                score += 0.4
            elif diff_ratio <= 0.10:
                score += 0.22
            elif diff_ratio <= 0.20:
                score += 0.1

        return round(score, 4)

    def infer_total_amount(self, raw_text, items, ocr_amount):
        """
        Infer a final receipt total using OCR text signals + extracted line items.
        This combines multiple evidence sources instead of relying on a single field.
        """
        candidates, lines = self._extract_amount_candidates(raw_text)
        item_sum = round(
            sum(
                self._safe_float(item.get("price"))
                for item in (items or [])
                if isinstance(item, dict)
            ),
            2,
        )
        ocr_amount = round(self._safe_float(ocr_amount), 2)

        predicted = 0.0
        reason = "No strong amount signals found"
        confidence = "low"

        best_candidate = None
        if candidates:
            for candidate in candidates:
                candidate["score"] = self._score_amount_candidate(candidate, lines, item_sum, ocr_amount)
            best_candidate = max(candidates, key=lambda c: c["score"])
            predicted = round(best_candidate["value"], 2)

            if best_candidate["score"] >= 1.2:
                confidence = "high"
            elif best_candidate["score"] >= 0.7:
                confidence = "medium"
            else:
                confidence = "low"

            reason = f"AI scorer selected '{best_candidate['line']}'"
        elif ocr_amount > 0:
            predicted = ocr_amount
            reason = "Used OCR extracted amount"
            confidence = "medium"

        # If item sum is close to predicted total, blend for stability.
        if predicted > 0 and item_sum > 0:
            diff_ratio = abs(predicted - item_sum) / max(predicted, item_sum)
            if diff_ratio <= 0.25:
                predicted = round((predicted + item_sum) / 2.0, 2)
                reason = "Combined total-line amount with itemized sum"
                confidence = "high"

        # If no usable predicted amount, fall back to itemized sum.
        if predicted <= 0 and item_sum > 0:
            predicted = item_sum
            reason = "Used sum of extracted line items"
            confidence = "low"

        return {
            "predicted_amount": predicted,
            "item_sum": item_sum,
            "ocr_amount": ocr_amount,
            "confidence": confidence,
            "reason": reason,
            "total_candidates_found": len(candidates),
            "generic_candidates_found": len([c for c in candidates if c.get("candidate_type") == "generic"]),
            "selected_amount_line": (best_candidate or {}).get("line", ""),
            "selected_amount_score": (best_candidate or {}).get("score", 0.0),
        }

    def _prepare_image_for_upload(self, image_path):
        """
        OCR.space free tier accepts files up to 1MB.
        Compress and resize oversized images to stay below this hard limit.
        Returns (path_to_upload, temporary_file_to_cleanup_or_none).
        """
        file_size = os.path.getsize(image_path)
        if file_size <= self.max_upload_bytes:
            return image_path, None

        with Image.open(image_path) as source:
            image = source.convert("RGB")
            width, height = image.size

            # Start with moderate quality and gradually reduce dimensions/quality.
            quality = 85
            scale = 1.0
            temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
            temp_file_path = temp_file.name
            temp_file.close()

            for _ in range(10):
                target_width = max(600, int(width * scale))
                target_height = max(600, int(height * scale))
                resized = image.resize((target_width, target_height), Image.Resampling.LANCZOS)
                resized.save(
                    temp_file_path,
                    format="JPEG",
                    quality=quality,
                    optimize=True,
                )

                if os.path.getsize(temp_file_path) <= self.max_upload_bytes:
                    return temp_file_path, temp_file_path

                quality = max(45, quality - 8)
                scale *= 0.88

        if os.path.getsize(temp_file_path) > self.max_upload_bytes:
            raise ValueError("Image is too large for OCR.space even after compression")

        return temp_file_path, temp_file_path

    def extract_text(self, image_path):
        if not os.path.exists(image_path):
            raise FileNotFoundError(f"Image not found: {image_path}")

        upload_path, temp_path = self._prepare_image_for_upload(image_path)
        try:
            with open(upload_path, "rb") as image_file:
                files = {
                    "filename": image_file,
                }
                data = {
                    "apikey": self.api_key,
                    "language": "eng",
                    "isOverlayRequired": "false",
                    "isTable": "true",
                    "OCREngine": "2",
                    "scale": "true",
                }
                response = requests.post(
                    self.api_url,
                    data=data,
                    files=files,
                    timeout=self.timeout_seconds,
                )
        finally:
            if temp_path and os.path.exists(temp_path):
                try:
                    os.remove(temp_path)
                except OSError:
                    pass

        if response.status_code != 200:
            raise ValueError(f"OCR.space request failed with status {response.status_code}")

        payload = response.json()

        if payload.get("IsErroredOnProcessing"):
            messages = payload.get("ErrorMessage") or payload.get("ErrorDetails") or "Unknown OCR API error"
            if isinstance(messages, list):
                messages = "; ".join(str(message) for message in messages)
            raise ValueError(f"OCR.space processing error: {messages}")

        parsed_results = payload.get("ParsedResults") or []
        text = "\n".join(
            (entry.get("ParsedText") or "").strip()
            for entry in parsed_results
            if isinstance(entry, dict)
        ).strip()

        if not text or not text.strip():
            raise ValueError("No text detected from OCR")

        return text

    def extract_structured_data(self, text):
        result = {
            "store": "Unknown Store",
            "items": [],
            "amount": 0.0,
            "date": datetime.now().strftime("%Y-%m-%d"),
            "tax": 0.0,
            "confidence": "medium",
        }

        lines = [line.strip() for line in text.split("\n") if line.strip()]
        if not lines:
            raise ValueError("OCR produced empty parsed lines")

        # Store name is usually near the top of the receipt.
        for line in lines[:5]:
            cleaned = re.sub(r"[^A-Za-z0-9\s&'-]", "", line).strip()
            if len(cleaned) >= 3:
                result["store"] = cleaned.title()
                break

        amount_patterns = [
            r"total[:\s]*\$?([0-9]+\.?[0-9]*)",
            r"amount[:\s]*\$?([0-9]+\.?[0-9]*)",
            r"\$([0-9]+\.[0-9]{2})",
        ]

        amounts_found = []
        for line in lines:
            for pattern in amount_patterns:
                for match in re.findall(pattern, line, flags=re.IGNORECASE):
                    try:
                        value = float(match)
                        if 0.01 <= value <= 100000:
                            amounts_found.append(value)
                    except ValueError:
                        continue

        if amounts_found:
            result["amount"] = max(amounts_found)

        date_patterns = [
            r"(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
            r"(\d{4}[/-]\d{1,2}[/-]\d{1,2})",
        ]
        for line in lines:
            matched_date = None
            for pattern in date_patterns:
                m = re.search(pattern, line)
                if m:
                    matched_date = m.group(1)
                    break
            if not matched_date:
                continue

            for fmt in ["%m/%d/%Y", "%m-%d-%Y", "%m/%d/%y", "%Y-%m-%d", "%Y/%m/%d"]:
                try:
                    result["date"] = datetime.strptime(matched_date, fmt).strftime("%Y-%m-%d")
                    break
                except ValueError:
                    continue
            if result["date"] != datetime.now().strftime("%Y-%m-%d"):
                break

        item_pattern = re.compile(r"^([A-Za-z][A-Za-z0-9\s&'\-]{2,40})\s+\$?([0-9]+\.[0-9]{2})$")
        for line in lines:
            if any(token in line.lower() for token in ["total", "subtotal", "tax", "change", "cash", "visa", "mastercard"]):
                continue
            m = item_pattern.search(line)
            if not m:
                continue
            try:
                result["items"].append(
                    {
                        "name": m.group(1).strip().title(),
                        "price": float(m.group(2)),
                    }
                )
            except ValueError:
                continue

        score = 0
        if result["store"] != "Unknown Store":
            score += 25
        if result["amount"] > 0:
            score += 35
        if result["items"]:
            score += 20
        if result["date"] != datetime.now().strftime("%Y-%m-%d"):
            score += 20

        if score >= 70:
            result["confidence"] = "high"
        elif score >= 40:
            result["confidence"] = "medium"
        else:
            result["confidence"] = "low"

        return result

    def process_receipt(self, image_path):
        raw_text = self.extract_text(image_path)
        structured_data = self.extract_structured_data(raw_text)

        amount_analysis = self.infer_total_amount(
            raw_text=raw_text,
            items=structured_data.get("items", []),
            ocr_amount=structured_data.get("amount", 0.0),
        )

        structured_data["ocr_amount"] = amount_analysis["ocr_amount"]
        structured_data["ai_predicted_amount"] = amount_analysis["predicted_amount"]
        structured_data["amount_confidence"] = amount_analysis["confidence"]
        structured_data["amount_reason"] = amount_analysis["reason"]
        structured_data["selected_amount_line"] = amount_analysis.get("selected_amount_line", "")
        structured_data["selected_amount_score"] = amount_analysis.get("selected_amount_score", 0.0)
        structured_data["amount"] = amount_analysis["predicted_amount"] or structured_data.get("amount", 0.0)

        structured_data["raw_text"] = raw_text
        structured_data["processing_status"] = "success"
        return structured_data
