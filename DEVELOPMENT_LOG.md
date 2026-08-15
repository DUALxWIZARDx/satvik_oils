2026-08-15 — Order Discount feature (Cart)

Summary:
- Added order-level discount functionality to the Sales/Cart flow.

Files modified:
- lib/models/discount_type.dart — added 7%, 12%, 15% enum values.
- lib/providers/sales_provider.dart — track selected order discount, compute subtotal, discountAmount, finalTotal; include order summary fields when saving orders.
- lib/models/sale_model.dart — added optional order-level fields: orderSubtotal, orderDiscountPercent, orderDiscountAmount, orderFinalTotal; serialized/deserialized to/from map.
- lib/core/database/db_schema.dart — added constants for new sale columns: order_subtotal, order_discount_percent, order_discount_amount, order_final_total.
- lib/repositories/sale_repository.dart — buildNewSale accepts and forwards order-level summary fields.
- lib/screens/sales/cart_screen.dart — added discount chips (5,7,10,12,15) and updated cart summary UI to show Subtotal, Discount, Discount Amount, Final Total.

Notes:
- Discount is applied to the entire order; only one percentage may be active at a time.
- Shopping cart recalculates totals automatically when items change or a new discount is selected.
- The selected discount percentage and computed order summary fields are included on saved sale rows to ensure order-level data is preserved for history/reports.
- Database schema constants were added; ensure DB migration is handled before running in production.

Manual checks to perform:
- Run `flutter analyze` (done) and address any warnings as needed.
- Launch app and verify Cart screen: select each discount, add/remove products, change quantities; confirm totals update automatically.
- Save an order and verify saved rows include order-level fields.

Do NOT commit these changes yet.

2026-08-15 — Database migration for order summary fields

Summary:
- Added DB migration to add order-level summary fields to the `sales` table for existing databases, and updated initial schema for fresh installs.

Files modified:
- lib/core/database/db_schema.dart — bumped schema version to 3.
- lib/core/database/migrations/v1_initial_schema.dart — include `order_id`, `order_subtotal` (REAL), `order_discount_percent` (INTEGER), `order_discount_amount` (REAL), `order_final_total` (REAL) in the initial CREATE TABLE and extended the `discount_type` check.
- lib/core/database/migrations/v3_add_order_summary_to_sales.dart — new migration that adds the four order summary columns if missing using `ALTER TABLE` guarded by `PRAGMA table_info`.
- lib/core/database/db_helper.dart — registered migration v3.

Notes:
- Migration uses `PRAGMA table_info` to avoid duplicate-column errors and preserves existing data.
- Fresh installs will have the new columns from the initial CREATE TABLE; upgrades will run v3 to add missing columns.

Manual checks to perform:
- Start app with an existing DB (version 1 or 2) and verify it upgrades without errors and existing sales remain accessible.
- Create and save a new order with a discount and verify saved rows include the new order-level fields.

