import json
import os
from typing import Any, Dict, List, Optional

import requests


class GroqExpenseCategorizer:
    """
    Categorize expenses from OCR output using Groq chat completions API.
    Falls back to unavailable mode when GROQ_API_KEY is not configured.
    """

    ALLOWED_CATEGORIES = [
        "Food",
        "Transport",
        "Shopping",
        "Bills",
        "Healthcare",
        "Entertainment",
        "Other",
    ]

    def __init__(self):
        self.api_key = os.getenv("GROQ_API_KEY")
        self.model = os.getenv("GROQ_MODEL", "llama-3.1-8b-instant")
        self.endpoint = "https://api.groq.com/openai/v1/chat/completions"
        self.available = bool(self.api_key)

    def categorize_expense(
        self,
        store_name: str,
        items: Optional[List[str]] = None,
        amount: Optional[float] = None,
        raw_text: str = "",
    ) -> Dict[str, Any]:
        """
        Returns dict with category and confidence in [0, 1].
        """
        if not self.available:
            raise RuntimeError("GROQ_API_KEY not configured")

        payload = self._build_payload(
            store_name=store_name or "",
            items=items or [],
            amount=amount,
            raw_text=raw_text or "",
        )

        response = requests.post(
            self.endpoint,
            headers={
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
            },
            json=payload,
            timeout=20,
        )
        response.raise_for_status()

        data = response.json()
        content = data.get("choices", [{}])[0].get("message", {}).get("content", "")
        parsed = self._safe_parse_json(content)

        category = parsed.get("category", "Other")
        if category not in self.ALLOWED_CATEGORIES:
            category = "Other"

        confidence = parsed.get("confidence", 0.6)
        try:
            confidence = float(confidence)
        except (TypeError, ValueError):
            confidence = 0.6
        confidence = max(0.0, min(1.0, confidence))

        reasoning = str(parsed.get("reasoning", "")).strip()

        return {
            "category": category,
            "confidence": confidence,
            "reasoning": reasoning,
            "method": "groq-llm",
        }

    def _build_payload(
        self, store_name: str, items: List[str], amount: Optional[float], raw_text: str
    ) -> Dict[str, Any]:
        # Keep prompt concise and deterministic.
        short_text = raw_text[:800]
        items_preview = items[:20]

        return {
            "model": self.model,
            "temperature": 0.1,
            "max_tokens": 120,
            "response_format": {"type": "json_object"},
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "You categorize receipt expenses. "
                        "Return ONLY JSON with keys: category, confidence, reasoning. "
                        f"category must be one of: {', '.join(self.ALLOWED_CATEGORIES)}. "
                        "confidence must be a number from 0 to 1."
                    ),
                },
                {
                    "role": "user",
                    "content": (
                        f"Store: {store_name}\n"
                        f"Amount: {amount}\n"
                        f"Items: {items_preview}\n"
                        f"OCR text: {short_text}"
                    ),
                },
            ],
        }

    @staticmethod
    def _safe_parse_json(content: str) -> Dict[str, Any]:
        if not content:
            return {}
        try:
            return json.loads(content)
        except json.JSONDecodeError:
            # Try light recovery for fenced output.
            cleaned = content.strip().strip("`")
            try:
                return json.loads(cleaned)
            except json.JSONDecodeError:
                return {}
