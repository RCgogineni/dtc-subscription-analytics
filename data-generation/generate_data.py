import random
import numpy as np
import pandas as pd
from datetime import date, timedelta
from dateutil.relativedelta import relativedelta

random.seed(42)
np.random.seed(42)

# ---- Config ----
OBS_START = date(2024, 1, 1)       # first possible signup month
OBS_END_SIGNUP = date(2025, 6, 1)  # last possible signup month
AS_OF_DATE = date(2025, 9, 1)      # "today" for the dataset - data is truncated here
N_CUSTOMERS = 4200

CHANNELS = {
    "Paid Social": {"share": 0.34, "churn_mult": 1.25},
    "Organic Search": {"share": 0.22, "churn_mult": 1.00},
    "Influencer": {"share": 0.16, "churn_mult": 1.15},
    "Referral": {"share": 0.14, "churn_mult": 0.65},
    "Email": {"share": 0.14, "churn_mult": 0.90},
}

PLANS = {
    "Monthly": {"share": 0.55, "monthly_price": 35, "billing_interval_months": 1, "churn_mult": 1.4},
    "Quarterly": {"share": 0.30, "monthly_price": 30, "billing_interval_months": 3, "churn_mult": 0.9},
    "Annual": {"share": 0.15, "monthly_price": 25, "billing_interval_months": 12, "churn_mult": 0.45},
}

SEGMENTS = {
    "Acne": 0.55,
    "Anti-Aging": 0.30,
    "Hyperpigmentation": 0.15,
}

COUNTRY_SHARE = {"United States": 0.88, "Canada": 0.07, "United Kingdom": 0.05}

def weighted_choice(d):
    keys = list(d.keys())
    weights = [d[k]["share"] if isinstance(d[k], dict) else d[k] for k in keys]
    return random.choices(keys, weights=weights, k=1)[0]

def months_between(d1, d2):
    return (d2.year - d1.year) * 12 + (d2.month - d1.month)

def add_months(d, n):
    return d + relativedelta(months=n)

# growth curve for signups: more signups in later months (business growing)
signup_months = pd.date_range(OBS_START, OBS_END_SIGNUP, freq="MS").date
n_months = len(signup_months)
growth_weights = np.linspace(1.0, 3.2, n_months)  # ramps up over time
growth_weights = growth_weights / growth_weights.sum()

customers = []
billing_events = []

customer_counter = 1
txn_counter = 1

for i, month in enumerate(signup_months):
    n_this_month = int(round(growth_weights[i] * N_CUSTOMERS))
    for _ in range(n_this_month):
        cust_id = f"CUST_{customer_counter:05d}"
        customer_counter += 1

        signup_day = random.randint(1, 28)
        signup_date = date(month.year, month.month, signup_day)

        channel = weighted_choice(CHANNELS)
        plan = weighted_choice(PLANS)
        segment = weighted_choice(SEGMENTS)
        country = weighted_choice(COUNTRY_SHARE)
        age = int(np.clip(np.random.normal(31, 8), 18, 65))
        gender = random.choices(["Female", "Male", "Other"], weights=[0.78, 0.20, 0.02])[0]

        plan_info = PLANS[plan]
        monthly_price = plan_info["monthly_price"]
        interval = plan_info["billing_interval_months"]
        base_churn_mult = plan_info["churn_mult"] * CHANNELS[channel]["churn_mult"]

        customers.append({
            "customer_id": cust_id,
            "signup_date": signup_date.isoformat(),
            "acquisition_channel": channel,
            "plan_type": plan,
            "skin_segment": segment,
            "country": country,
            "age": age,
            "gender": gender,
            "monthly_price": monthly_price,
        })

        # ---- simulate billing cycle history ----
        cycle_start = signup_date
        tenure_month_marker = 0
        churned = False
        cancellation_date = None

        while True:
            months_elapsed = months_between(signup_date, cycle_start)
            if cycle_start > AS_OF_DATE:
                break

            # charge event for this billing cycle
            charge_amount = monthly_price * interval
            billing_events.append({
                "transaction_id": f"TXN_{txn_counter:07d}",
                "customer_id": cust_id,
                "billing_date": cycle_start.isoformat(),
                "transaction_type": "charge",
                "plan_type_at_transaction": plan,
                "amount": charge_amount,
            })
            txn_counter += 1

            # hazard: base monthly hazard, higher in first 3 months (classic early churn),
            # applied at each renewal point (so annual plans only face it once/year)
            tenure_after_this_cycle = months_elapsed + interval
            if tenure_after_this_cycle <= 3:
                base_monthly_hazard = 0.09
            elif tenure_after_this_cycle <= 6:
                base_monthly_hazard = 0.05
            else:
                base_monthly_hazard = 0.025

            # probability of churn at this renewal = 1 - (1-hazard)^interval, scaled by plan/channel mult
            hazard_this_cycle = 1 - (1 - base_monthly_hazard) ** interval
            hazard_this_cycle = min(0.9, hazard_this_cycle * base_churn_mult)

            next_cycle_start = add_months(cycle_start, interval)

            if next_cycle_start > AS_OF_DATE:
                break

            if random.random() < hazard_this_cycle:
                cancellation_date = next_cycle_start
                billing_events.append({
                    "transaction_id": f"TXN_{txn_counter:07d}",
                    "customer_id": cust_id,
                    "billing_date": cancellation_date.isoformat(),
                    "transaction_type": "cancellation",
                    "plan_type_at_transaction": plan,
                    "amount": 0,
                })
                txn_counter += 1
                churned = True
                break

            cycle_start = next_cycle_start

        customers[-1]["is_churned"] = churned
        customers[-1]["cancellation_date"] = cancellation_date.isoformat() if cancellation_date else None

customers_df = pd.DataFrame(customers)
billing_df = pd.DataFrame(billing_events)

customers_df.to_csv("/home/claude/dtc-project/synthetic/customers.csv", index=False)
billing_df.to_csv("/home/claude/dtc-project/synthetic/billing_transactions.csv", index=False)

print("Customers:", customers_df.shape)
print("Billing events:", billing_df.shape)
print()
print(customers_df.head(8).to_string())
print()
print(billing_df.head(10).to_string())
print()
print("Overall churn rate:", customers_df["is_churned"].mean().round(3))
print()
print("Churn rate by plan:")
print(customers_df.groupby("plan_type")["is_churned"].mean().round(3))
print()
print("Churn rate by channel:")
print(customers_df.groupby("acquisition_channel")["is_churned"].mean().round(3))
