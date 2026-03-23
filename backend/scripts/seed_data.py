import json
import os
import sys
import urllib.request
from datetime import date, timedelta

BASE_URL = os.getenv("FINX_API_BASE_URL", "https://finx-i7m6.onrender.com/api").rstrip("/")
EMAIL = os.getenv("FINX_EMAIL")
PASSWORD = os.getenv("FINX_PASSWORD")
NAME = os.getenv("FINX_NAME", "Vignesh")


def _request(path, method="GET", data=None, token=None):
    url = f"{BASE_URL}{path}"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"

    body = None
    if data is not None:
        body = json.dumps(data).encode("utf-8")

    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read().decode("utf-8")
            return resp.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode("utf-8")
        return exc.code, json.loads(raw) if raw else {"error": raw}


def register_or_login():
    if not EMAIL or not PASSWORD:
        raise SystemExit("Set FINX_EMAIL and FINX_PASSWORD env vars.")

    status, _ = _request(
        "/register",
        method="POST",
        data={"name": NAME, "email": EMAIL, "password": PASSWORD},
    )
    if status not in (200, 201, 409):
        raise SystemExit(f"Register failed: {status}")

    status, data = _request(
        "/login",
        method="POST",
        data={"email": EMAIL, "password": PASSWORD},
    )
    if status != 200:
        raise SystemExit(f"Login failed: {status} {data}")
    return data.get("token")


def seed_budget(token):
    _request(
        "/budget",
        method="PUT",
        data={"monthly_limit": 2500, "currency": "USD"},
        token=token,
    )

    _request(
        "/budget/categories",
        method="PUT",
        data={
            "category_budgets": [
                {"category": "Food", "monthly_limit": 600},
                {"category": "Travel", "monthly_limit": 300},
                {"category": "Shopping", "monthly_limit": 400},
                {"category": "Bills", "monthly_limit": 700},
                {"category": "Entertainment", "monthly_limit": 250},
            ]
        },
        token=token,
    )


def seed_expenses(token):
    today = date.today()
    expenses = [
        {
            "store": "Walmart",
            "amount": 58.25,
            "category": "Food",
            "date": str(today - timedelta(days=2)),
            "items": ["Milk", "Bread", "Eggs"],
            "raw_ocr_text": "Sample OCR text",
        },
        {
            "store": "Uber",
            "amount": 22.40,
            "category": "Travel",
            "date": str(today - timedelta(days=5)),
            "items": ["Ride"],
        },
        {
            "store": "Best Buy",
            "amount": 199.99,
            "category": "Shopping",
            "date": str(today - timedelta(days=8)),
            "items": ["Headphones"],
        },
        {
            "store": "Netflix",
            "amount": 15.99,
            "category": "Entertainment",
            "date": str(today - timedelta(days=12)),
            "items": ["Subscription"],
        },
        {
            "store": "Electric Co",
            "amount": 92.10,
            "category": "Bills",
            "date": str(today - timedelta(days=15)),
            "items": ["Electricity"],
        },
    ]

    created = []
    for item in expenses:
        status, data = _request("/expenses", method="POST", data=item, token=token)
        if status == 201:
            created.append(data)

    if created:
        expense_id = created[0].get("id")
        if expense_id:
            _request(
                f"/expenses/{expense_id}/feedback",
                method="POST",
                data={"correct_category": "Food", "confidence": 0.9},
                token=token,
            )


def seed_subscriptions(token):
    subs = [
        {"name": "Spotify", "amount": 9.99, "frequency": "monthly", "renewal_date": "2025-04-15"},
        {"name": "Apple iCloud", "amount": 2.99, "frequency": "monthly", "renewal_date": "2025-04-20"},
    ]
    for item in subs:
        _request("/subscriptions", method="POST", data=item, token=token)


def seed_income(token):
    today = date.today()
    incomes = [
        {
            "source": "Salary",
            "category": "Primary",
            "amount": 4200,
            "date": str(today - timedelta(days=1)),
            "is_recurring": True,
            "notes": "Monthly salary",
        },
        {
            "source": "Freelance",
            "category": "Side",
            "amount": 600,
            "date": str(today - timedelta(days=10)),
            "is_recurring": False,
            "notes": "Design project",
        },
    ]
    for item in incomes:
        _request("/incomes", method="POST", data=item, token=token)


def main():
    token = register_or_login()
    seed_budget(token)
    seed_expenses(token)
    seed_subscriptions(token)
    seed_income(token)

    print("Seed complete.")


if __name__ == "__main__":
    main()
