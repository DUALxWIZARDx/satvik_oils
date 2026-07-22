# Satvik Oils — Software Architecture

This document is the architectural companion to `PROJECT.md`. It does not introduce
new features or business rules — everything below is a structural translation of
what `PROJECT.md` already specifies, designed to satisfy the stated AI Rules:
UI separated from business logic, components reused, features built one at a time,
and no silent renaming of database fields.

Two assumptions are made where `PROJECT.md` is silent, flagged inline and again in
Section 10 so they can be confirmed before coding starts.

---

## 1. Recommended `lib/` Folder Structure

```
lib/
├── main.dart                          # entry point, orientation lock, DB init
├── app.dart                           # MaterialApp, theme, root shell
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart            # dark theme palette tokens
│   │   ├── app_text_styles.dart
│   │   ├── app_dimens.dart             # spacing/radius/animation-duration tokens
│   │   └── product_catalog.dart        # the 8 fixed products + quantity variants
│   ├── theme/
│   │   └── app_theme.dart
│   ├── utils/
│   │   ├── currency_formatter.dart
│   │   ├── date_time_formatter.dart
│   │   ├── sale_id_generator.dart
│   │   └── validators.dart
│   ├── database/
│   │   ├── db_helper.dart              # sqflite singleton, open + migrate
│   │   ├── db_schema.dart              # table + column name constants
│   │   └── migrations/
│   │       └── v1_initial_schema.dart  # one file per future version bump
│   └── errors/
│       └── app_exceptions.dart
│
├── models/
│   ├── product_model.dart
│   ├── sale_model.dart
│   ├── customer_model.dart
│   ├── payment_mode.dart               # enum: cash / upi / card
│   └── discount_type.dart              # enum: none / 5% / 10% / custom
│
├── repositories/
│   ├── product_repository.dart
│   ├── sale_repository.dart
│   ├── customer_repository.dart
│   └── settings_repository.dart
│
├── services/
│   ├── pricing_service.dart            # autofill + discount + total calculation
│   ├── report_service.dart             # aggregation across sales for Reports
│   ├── sync_service.dart               # manual Firestore push/pull
│   ├── backup_service.dart             # local export/import of the DB
│   └── pin_service.dart                # PIN hashing, storage, verification
│
├── providers/
│   ├── navigation_provider.dart
│   ├── sales_provider.dart
│   ├── sale_history_provider.dart
│   ├── reports_provider.dart
│   ├── customer_provider.dart
│   └── settings_provider.dart
│
├── screens/
│   ├── shell/
│   │   ├── app_shell.dart              # IndexedStack + drawer + top bar
│   │   ├── side_menu.dart
│   │   └── top_bar.dart
│   ├── sales/
│   │   ├── sales_screen.dart
│   │   └── widgets/
│   │       ├── product_card.dart
│   │       ├── expanded_sale_form.dart
│   │       ├── quantity_selector.dart
│   │       ├── discount_selector.dart
│   │       ├── payment_selector.dart
│   │       ├── customer_picker_field.dart
│   │       └── sale_saved_banner.dart
│   ├── sale_history/
│   │   ├── sale_history_screen.dart
│   │   └── widgets/
│   │       ├── sale_list_item.dart
│   │       ├── sale_filter_bar.dart
│   │       ├── edit_sale_dialog.dart
│   │       └── pin_prompt_dialog.dart
│   ├── reports/
│   │   ├── reports_screen.dart
│   │   └── widgets/
│   │       ├── report_summary_tile.dart
│   │       ├── sales_trend_chart.dart   # FL Chart wrapper
│   │       └── report_filter_bar.dart
│   └── settings/
│       ├── settings_screen.dart
│       └── widgets/
│           ├── pin_management_tile.dart
│           ├── product_price_editor.dart
│           ├── customer_manager_panel.dart
│           └── backup_restore_panel.dart
│
└── widgets/                            # generic, feature-agnostic
    ├── buttons/primary_button.dart
    ├── inputs/segmented_selector.dart  # backs quantity/discount/payment pickers
    ├── inputs/amount_input_field.dart
    ├── feedback/success_toast.dart
    ├── feedback/confirm_dialog.dart
    └── cards/expandable_card.dart      # generic expand/collapse shell
```

**Reasoning:** `core/`, `models/`, `repositories/`, `services/`, `providers/` are
horizontal layers shared by every feature; `screens/` is vertical, one folder per
nav item, each with its own `widgets/` for screen-specific UI. Anything used by
two or more screens graduates to the top-level `widgets/`. This mirrors the "Keep
UI separate from business logic" and "Reuse components" rules directly in the
folder layout, so those rules are hard to violate by accident.

---

## 2. Feature / Module Breakdown

| Module | Screens involved | Depends on | Notes |
|---|---|---|---|
| **Sales** | Sales screen | Product, Customer, Sale repositories; Pricing service | The 10-second core flow — highest priority module |
| **Sale History** | Sale History screen | Sale, Customer repositories; PIN service | Edit is constrained by the immutability rule (Section 10) |
| **Reports** | Reports screen | Sale repository (read-only) + Report service | Never writes to `sales`; purely aggregates |
| **Customers** | Embedded picker in Sales; management panel in Settings | Customer repository | Optional at point of sale, per spec |
| **Settings** | Settings screen | Settings, Product, Customer repositories; PIN, Backup, Sync services | Owns PIN, prices, backup/restore, manual sync |

Reports and Sale History both read the `sales` table but never write to the
snapshot fields described in Section 5 — this is what lets "Old Sales Never
Change After Price Updates" hold structurally, not just by convention.

---

## 3. State Management (Provider)

One `ChangeNotifier` per feature, matching the module table above, registered
once via `MultiProvider` at the root of `app.dart`:

- **`NavigationProvider`** — holds the active drawer index (0–3). Drives the
  shell's `IndexedStack`.
- **`SalesProvider`** — transient, in-memory only: which card is expanded,
  selected quantity/price/discount/payment/customer, today's running totals.
  Nothing here is persisted until "Save Sale" is tapped; the provider then
  delegates to `SaleRepository`, resets the form, and refreshes the totals.
- **`SaleHistoryProvider`** — current filters (date/product/customer/payment),
  loaded sale list, edit/delete state.
- **`ReportsProvider`** — selected report type + date range, and the computed
  result. Computation is cached and only re-run when the user changes the
  filter or explicitly refreshes, not on every rebuild (see Section 10).
- **`CustomerProvider`** — customer list, search, add/edit.
- **`SettingsProvider`** — PIN state, product/cost prices, sync/backup status.

**Reasoning:** the Sales screen's "expand card" animation and per-second usage
pattern means rebuild scope matters. Widgets should use `Selector` (not blanket
`Consumer`) so that, e.g., tapping one product card only rebuilds that card and
the form beneath it, not all eight cards — this is what keeps the "smooth
animations" goal compatible with "minimal taps, minimal typing" on a low-to-mid
tablet CPU. Repositories and services are plain Dart classes injected into
providers via constructor parameters (not themselves `ChangeNotifier`s) — state
belongs to providers, data access does not.

---

## 4. Navigation Architecture

Because this is a fixed, four-item, landscape-only, single-user tablet app with
no deep-linking requirement, a full `Navigator`/named-routes stack is more
machinery than the app needs. Recommended approach:

- **`AppShell`** wraps everything: persistent hamburger `Drawer` + top bar, and
  an `IndexedStack` for the four main screens (Sales / Sale History / Reports /
  Settings), switched by `NavigationProvider.currentIndex`.
- `IndexedStack` (not `Navigator.push`) keeps each screen's state alive when the
  user switches away and back — e.g., a half-filled sale form or a Reports
  filter isn't lost just because the user checked Sale History.
- Modals — Edit Sale, PIN prompt, Delete confirmation, Restore confirmation —
  use `showDialog`/`showModalBottomSheet` rather than route pushes, since they're
  transient overlays, not navigable destinations.
- `main.dart` locks orientation to landscape via
  `SystemChrome.setPreferredOrientations` before `runApp`, matching the
  "Landscape Only" product rule.

If a future version needs deep links or multi-window support, this can be
migrated to named routes without touching the screens themselves, since the
shell is the only place that currently knows about "navigation."

---

## 5. SQLite Architecture

### Tables

**`products`**
`id, name, is_active`
— the 8 fixed products; a row here is metadata only, never a price source for
past sales (see below).

**`product_prices`**
`id, product_id, quantity_variant, selling_price, cost_price, effective_from`
— current and historical price list per product+quantity combination. Used to
*autofill* the Sales form. Never joined into historical sale reporting.

**`customers`**
`id, name, phone, address, created_at`

**`sales`**
`id (Sale ID), created_at, sale_date, sale_time, product_id, product_name_snapshot, quantity_variant, unit_price_snapshot, cost_price_snapshot, discount_type, discount_value, total_amount, payment_mode, customer_id (nullable), synced_at (nullable)`

**`app_settings`**
key–value table: PIN hash, last sync timestamp, backup metadata.

### Why snapshot fields on `sales`

`PROJECT.md` states old sales must never change after a price update. If `sales`
only stored `product_id` and looked prices up live from `product_prices`, then
editing a price in Settings would silently rewrite every past report. Storing
`product_name_snapshot`, `unit_price_snapshot`, and `cost_price_snapshot`
directly on the row at the moment of sale makes each sale immutable by
construction — no repository method should ever update those three columns once
a row exists, regardless of what "Edit Sale" is later allowed to touch (flagged
as an open question in Section 10).

### Indexing

Indexes on `sales.sale_date`, `sales.product_id`, `sales.customer_id`, and
`sales.payment_mode` — these are exactly the four filters listed under Sale
History and the groupings listed under Reports, so query performance stays flat
as sales accumulate over years.

### Migration strategy

`db_helper.dart` tracks a single integer schema version and an ordered list of
migration functions (`onUpgrade`), one per version bump, rather than ad hoc
`ALTER TABLE` calls scattered through the app. Version 2 (Inventory), Version 3
(Bills), and Version 4 (Expenses) on the roadmap will each add tables/columns
through this same mechanism, so V1 should be built expecting at least three more
migrations to follow it.

---

## 6. Model, Service, and Repository Organization

Four layers, one direction of dependency (UI → Provider → Repository/Service →
Database/Firestore), never the reverse:

- **Models** — plain data classes with `fromMap`/`toMap`. No logic beyond
  serialization.
- **Repositories** — one per table. Own all SQL for that table: insert, update,
  delete, and simple filtered `get` queries (by date, product, customer,
  payment mode). A repository never reaches into another repository's table.
- **Services** — logic that spans repositories or talks to something outside
  SQLite:
  - `PricingService` computes autofill price + discount + total for the Sales
    form (pure calculation, no DB access — easy to unit test).
  - `ReportService` calls into `SaleRepository`'s queries and aggregates them
    into the report shapes Reports needs (daily/monthly/quarterly/yearly,
    product-wise, top-selling, profit, payment-method, discount analysis).
  - `SyncService` reads from repositories and pushes to Firestore, and pulls
    remote changes back on manual trigger.
  - `BackupService` serializes the whole local database to a file and restores
    from one.
  - `PinService` hashes, stores, and verifies the PIN — used by Sale History's
    delete action and Settings' PIN management.
- **Providers** — the only layer UI talks to. A provider calls one or more
  repositories/services and exposes plain state + methods to widgets.

This keeps a strict rule that's easy to enforce in review: if a class imports
`sqflite` directly, it must live in `repositories/`; if a widget imports a
repository directly, that's a violation to fix, not a style preference.

---

## 7. Reusable Widget Strategy

Several pieces of UI in `PROJECT.md` are the same interaction pattern wearing
different labels:

- **`SegmentedSelector<T>`** — one generic chip/segment picker backs Quantity
  (100ml…5L), Discount (None/5%/10%/Custom), and Payment (Cash/UPI/Card).
  Written once, themed once, tested once.
- **`ExpandableCard`** — a generic expand/collapse animated container; the 8
  product cards are instances of it, each supplying its own content. This is
  where the "smooth animations" requirement lives, centrally, instead of being
  reimplemented per card.
- **`PrimaryButton`** — reused for Save Sale, Save Customer, Backup, Restore,
  and Confirm actions, so button styling/animation is defined once.
- **`SuccessToast`** — the "Sale Saved" confirmation, reused for "Customer
  Saved," "Backup Complete," "Sync Complete."
- **`ConfirmDialog`** — reused for Delete Sale (with PIN) and Restore
  confirmation, parameterized by message and confirm action.
- **`AmountInputField`** — reused for the editable Price field on the Sales
  form, the Custom discount amount, and Cost Price entry in Settings.

Centralizing the "minimal taps, minimal typing" behaviors — like price autofill
or default-quantity selection — in `PricingService` rather than in each
widget's `onTap` means the fast-entry logic is defined once and every screen
that needs it behaves consistently.

---

## 8. Required Flutter Packages

Only what's necessary to deliver what `PROJECT.md` already specifies:

| Package | Why it's needed |
|---|---|
| `provider` | State management, already in the stack |
| `sqflite` + `path` | Local SQLite storage, already in the stack |
| `path_provider` | Locate the on-device DB/backup file paths |
| `cloud_firestore` + `firebase_core` | Manual Firestore sync, already in the stack |
| `fl_chart` | Quarterly/Yearly graphs, already in the stack |
| `intl` | Date and currency formatting throughout Sales/History/Reports |
| `connectivity_plus` | Detect network state so "Manual Cloud Sync" can be enabled/disabled sensibly |
| `flutter_secure_storage` | Store the PIN hash — this is more sensitive than ordinary settings and shouldn't sit in plain `shared_preferences` |
| `uuid` | Generate collision-safe Sale IDs (see Section 10 on multi-device readiness) |

Nothing for navigation, DI, or animation frameworks is added — `Navigator`,
constructor injection, and Flutter's built-in `Animated*` widgets cover
everything this app needs without extra dependencies.

---

## 9. Development Order

Following the "implement one feature at a time" rule, ordered by actual
dependency rather than the order features are listed in `PROJECT.md`:

1. **Core infrastructure** — `db_helper`, schema/migration scaffolding, dark
   theme, `AppShell` + drawer + `IndexedStack`, base models.
2. **Products & minimal Settings** — seed the 8 fixed products, build just
   enough of Settings to set/edit product and cost prices, and a default PIN.
   *Needed first because the Sales form's autofill has nothing to fill from
   otherwise, and Sale History's delete-with-PIN has nothing to check against.*
3. **Sales screen** — the core sub-10-second flow. This is the module the
   business goal is centered on, and it's now unblocked by steps 1–2.
4. **Sale History** — view/search/filter, edit, and PIN-gated delete. Depends
   on real sales existing from step 3 and PIN existing from step 2.
5. **Customers** — storage plus the optional picker retrofitted into the Sales
   form, and a management panel in Settings.
6. **Reports** — daily/monthly/quarterly/yearly, product-wise, profit,
   payment-method, discount analysis, and the FL Chart graphs. Naturally comes
   after there's real sales history to report on.
7. **Backup / Restore, then Manual Firebase Sync** — local backup first
   (self-contained, no external dependency), sync second since it builds on
   the same data export logic.

Version 2+ (Inventory, Bills, Expenses, multi-device live sync) follow the
roadmap in `PROJECT.md` once V1 is stable.

---

## 10. Architectural Risks and Improvements

- **Edit Sale scope is under-specified.** `PROJECT.md` lists "Edit Sale" under
  Sale History but the immutability rule says old sales must never change
  after a price update. These aren't automatically in conflict, but the exact
  boundary needs a decision before that screen is built: e.g., payment mode or
  linked customer might be editable, while `unit_price_snapshot`,
  `cost_price_snapshot`, and `product_name_snapshot` should not be, regardless
  of what Settings does later. Worth confirming explicitly rather than
  assuming.

- **PIN storage.** Store a salted hash via `flutter_secure_storage`, never the
  PIN itself and never in plain `shared_preferences`.

- **Sale ID format.** A UUID (or a date-prefixed + random suffix scheme) is
  recommended over a simple auto-increment integer. Version 5 on the roadmap is
  multi-device live sync — sequential IDs generated independently on two
  devices will collide, whereas a UUID-based scheme avoids a painful ID-scheme
  migration later. This costs nothing to do now.

- **Sync readiness.** Even though V1 is single-device, adding a `synced_at`
  (already included above) and treating "unsynced" as the natural default costs
  little now and saves a schema migration when Version 5 (multi-device live
  sync) arrives.

- **Report computation cost.** Aggregating years of sales on every keystroke of
  a filter would be wasteful. `ReportsProvider` should compute on an explicit
  trigger (filter applied / refresh tapped), not reactively on every filter
  change, once the sales table is large.

- **"Today's Sales" vs. "Today's Orders" is not defined in `PROJECT.md`.**
  This document assumes "Today's Sales" is the total revenue amount and
  "Today's Orders" is the count of sale transactions for the day — this is an
  assumption, not a stated rule, and is worth a quick confirmation before the
  top bar is built.

- **Whether the 8 products themselves are ever add/removable is unstated.**
  `PROJECT.md` only lists "Product Prices" under Settings, not product
  management. This document assumes the 8 products are fixed for V1 and only
  their prices/cost prices are editable — flagging this since it affects
  whether `products` needs full CRUD or just price-field updates.
