# Satvik Oils - Project Blueprint

## Project Overview
Satvik Oils is an offline-first Android tablet (landscape) sales management application for a single-user edible oils shop.

Primary Goal:
Record every sale in under 10 seconds with minimal taps.

---

## Tech Stack

- Flutter
- SQLite
- Provider
- Firebase Firestore (Manual Sync)
- FL Chart

---

## Navigation

☰ Menu

1. Sales (Default)
2. Sale History
3. Reports
4. Settings

---

## Product Philosophy

- Offline First
- Landscape Only
- Premium Dark Theme
- Smooth Animations
- Minimal Taps
- Minimal Typing
- Fast User Experience

---

## Sales Screen

Top Bar

- Hamburger Menu
- Satvik Oils
- Today's Sales
- Today's Orders

Main Area

Display 8 Product Cards

- Groundnut Oil
- Coconut Oil
- White Sesame Oil
- Black Sesame Oil
- Mustard Oil
- Sunflower Oil
- Safflower Oil
- Almond Oil

When a card is tapped it expands.

Expanded Card

Quantity

- 100ml
- 250ml
- 500ml
- 1L
- 5L

Price

- Auto-filled
- Editable

Discount

- None
- 5%
- 10%
- Custom

Payment

- Cash
- UPI
- Card

Optional

- Regular Customer

Button

- Save Sale

After Save

Automatically

- Generate Sale ID
- Save Date
- Save Time
- Save Product
- Save Quantity
- Save Payment Mode
- Save Discount
- Calculate Total
- Collapse Card
- Show "Sale Saved"
- Ready for Next Sale

---

## Sale History

- View Sales
- Search
- Filter by Date
- Filter by Product
- Filter by Customer
- Filter by Payment Mode
- Edit Sale
- Delete Sale (PIN Required)

---

## Reports

- Daily Sales
- Monthly Sales
- Quarterly Sales
- Yearly Sales
- Product-wise Sales
- Top Selling Products
- Profit Report
- Payment Method Analysis
- Customer Purchase History
- Discount Analysis
- Quarterly Graph
- Yearly Graph

---

## Customers

Store

- Name
- Phone
- Address

Customer selection is optional during sales.

---

## Settings

- PIN Management
- Product Prices
- Cost Prices
- Regular Customers
- Backup
- Restore
- Manual Cloud Sync

---

## Business Rules

- Offline First
- Manual Firebase Sync
- Old Sales Never Change After Price Updates
- Inventory Excluded from Version 1
- Official Bills Excluded from Version 1
- Expense Tracking Planned for Future Versions

---

## AI Rules

- Read PROJECT.md before coding.
- Never modify approved modules without approval.
- Never rename database fields without approval.
- Reuse components.
- Keep UI separate from business logic.
- Implement one feature at a time.

---

## Roadmap

Version 1

- Sales
- Sale History
- Reports
- Customers
- Settings

Version 2

- Inventory

Version 3

- Official Bills

Version 4

- Expense Tracking

Version 5

- Multi-device Live Sync
