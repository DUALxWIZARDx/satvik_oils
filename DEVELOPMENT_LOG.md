2026-09-20 - Product analysis and pricing expandable modal cards

Summary:
- Replaced inline product-card height expansion with a shared native Flutter Hero modal interaction.
- Added a dimmed and blurred backdrop, circular close action, tap-outside dismissal, reverse Hero transition, delayed content fade/slide, and scrollable expanded content.
- Applied the interaction to Analytics Product Analysis and Products & Pricing without changing providers, models, repositories, calculations, or pricing callbacks.

Files modified:
- lib/widgets/cards/expandable_card_modal.dart - shared expandable-card modal presentation.
- lib/widgets/cards/product_pricing_card.dart - routes pricing cards through the shared modal.
- lib/screens/analytics/analytics_screen.dart - routes product analysis cards through the shared modal.
- lib/screens/products_pricing/products_pricing_screen.dart - removes inline expansion state and uses unique pricing Hero tags.
- DEVELOPMENT_LOG.md - documented this UI-only implementation.

Validation:
- Focused Flutter analysis passed for both target screens, the pricing card, and the shared modal.
- Full flutter analyze passed.
- Existing full widget test remains outdated: it expects the hamburger drawer even though the current app uses floating bottom navigation.

2026-09-05 - Sales History month selection and grouped day layout

Summary:
- Replaced the Sales History title with the selected month and a calendar icon button.
- Added a modal year selector restricted to 2026 and future years, with all 12 months in a responsive grid.
- Grouped month-scoped orders by day and updated each order card to show time, every oil line with quantity, total amount, and payment mode.
- Kept the existing dark premium visual language and search behavior.

Architecture:
- SaleHistoryProvider stores the selected month and reloads when a month is chosen.
- SaleRepository applies the selected month as a SQLite date range before grouping orders.
- No database schema, models, sales calculations, navigation, or existing sale-writing behavior changed.
- The screen remains fully SQLite-backed and does not include demo data.

Files modified:
- lib/repositories/sale_repository.dart - added the selected-month predicate to the existing grouped history query.
- lib/providers/sale_history_provider.dart - added selected-month state and reload behavior.
- lib/screens/sale_history/sale_history_screen.dart - added the month modal, day sections, and updated order cards.
- DEVELOPMENT_LOG.md - documented this implementation.

Validation:
- Focused flutter analyze passed for the Sales History screen, provider, and repository.
- Full flutter analyze run after implementation.

2026-09-04 - Fixed sale timestamp creation flow

Summary:
- Connected SalesProvider to the shared DateTimeService.
- Each new order captures the device's current local DateTime once and passes
  that timestamp unchanged to every SaleRepository-built sale row.
- SQLite continues storing the SaleModel created_at, sale_date, and sale_time
  values through the existing serialization and schema.

Root cause:
- SalesProvider did not pass createdAt when creating sales, so timestamp
  creation was implicit in SaleRepository instead of being connected to the
  centralized service. No current source literal for "12 Aug", sampleDate, or
  demoDate was found.

Files modified for this fix:
- lib/app.dart - injects the shared DateTimeService into SalesProvider.
- lib/providers/sales_provider.dart - captures and forwards the real local
  sale timestamp for saveSale and saveOrder.
- DEVELOPMENT_LOG.md - documented the fix.

Display verification:
- Dashboard Recent Orders displays the SQLite sale_time value.
- Sale History displays the SQLite created_at value.
- Dashboard's date header uses DateTimeService.today.

2026-09-04 - Centralized Date & Time service

Summary:
- Added a shared DateTimeService backed by the Android device's local
  DateTime.now() value.
- Added current date/time accessors, today/yesterday, week and month bounds,
  last 7 days, last 30 days, and reusable date/time format helpers.
- Added automatic midnight notifications so Dashboard data reloads for the
  new local day while the app remains open.

Files created:
- lib/core/utils/date_time_service.dart

Files modified:
- lib/app.dart - registered the shared DateTimeService.
- lib/providers/dashboard_provider.dart - injected the service and refreshed
  Dashboard data after midnight.
- lib/screens/dashboard/dashboard_screen.dart - uses the service for today's
  displayed date.
- lib/screens/sale_history/sale_history_screen.dart - uses shared date/time
  formatting for order timestamps.
- lib/widgets/cards/product_pricing_card.dart - uses shared date formatting
  for price update dates.
- DEVELOPMENT_LOG.md - documented this implementation.

Hardcoded/presentation date replacements:
- Dashboard's direct DateTime.now() and local long-date formatter.
- Sale History's local combined date/time formatter.
- Products & Pricing's local update-date formatter.

Repository timestamps and date serialization were intentionally unchanged to
preserve existing business logic and the requested repository scope.

Usage:
- Read the service with Provider: context.read<DateTimeService>() or
  context.watch<DateTimeService>().
- Use service.today, service.currentDateTime, service.currentTime,
  service.startOfWeek, service.endOfWeek, service.startOfMonth,
  service.endOfMonth, service.last7Days, and service.last30Days.
- Use formatDate, formatTime, formatShortDate, and formatMonthYear for UI
  presentation.

2026-09-04 - Dashboard layout update

Summary:
- Removed the Top Selling Oils Today section from the Dashboard UI.
- Kept Recent Orders on the left with its existing table and behavior.
- Moved the four summary cards into an equal-spacing, equal-height grid on the right.
- Added a responsive stacked layout for narrower tablet widths.

Files modified:
- lib/screens/dashboard/dashboard_screen.dart - updated Dashboard presentation only.
- DEVELOPMENT_LOG.md - documented the Dashboard layout update.

Notes:
- No business logic, provider, repository, database, calculations, or data flow changed.
- Run `flutter analyze` after this update.

2026-08-19 - Sale History screen

Summary:
- Replaced the Sale History placeholder with newest-first completed-order cards.
- Grouped sale rows by order_id, with a sale-id fallback for legacy rows without an order_id.
- Added product and payment-mode search filtering.
- Limited each card to two oil lines and a "+N more" indicator for additional products.
- No changes were made to Sales, Cart, Products & Pricing, Dashboard, or the database schema.

Files modified:
- lib/models/sale_history_model.dart - added grouped order and oil-line read models.
- lib/repositories/sale_repository.dart - added the grouped Sale History query.
- lib/providers/sale_history_provider.dart - added loading, refresh, and product/payment search state.
- lib/screens/sale_history/sale_history_screen.dart - added search, order cards, and loading/error/empty states.
- DEVELOPMENT_LOG.md - documented the feature and manual checks.

Repository methods added:
- getSaleHistoryOrders()

Provider methods added:
- setSearchQuery(String value)
- loadOrders({bool forceReload = false})

Manual checks to perform:
- Open Sale History and verify one card appears per completed order, including multi-product orders.
- Verify each card shows up to two oils, "+N more" when needed, total amount, payment mode, date, and time.
- Search by a product name and by Cash, UPI, or Card; clear the search and verify all orders return.
- Verify newest orders appear first and the empty states appear with no orders or no matching results.
- Confirm Sales, Cart, Products & Pricing, Dashboard, and the database schema remain unchanged.
- Run flutter analyze.

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


2026-08-19 - Dashboard feature

Summary:
- Added a simple Dashboard screen backed by Provider -> Repository -> SQLite.
- Dashboard shows today's sales revenue, profit, order count, average order value, top selling oils today, and recent orders.
- Added clean empty states for days with no sales data.
- Wired Dashboard into the existing shell navigation while keeping Sales as the default screen.

Files modified:
- lib/models/dashboard_model.dart - added read models for dashboard summary, top selling oils, and recent orders.
- lib/repositories/sale_repository.dart - added read-only dashboard aggregation methods.
- lib/providers/dashboard_provider.dart - added dashboard loading/error/empty state and SQLite-backed data loading.
- lib/screens/dashboard/dashboard_screen.dart - added simple tablet-friendly dashboard UI.
- lib/app.dart - registered DashboardProvider.
- lib/screens/shell/app_shell.dart - added DashboardScreen to the IndexedStack.
- lib/screens/shell/side_menu.dart - added Dashboard navigation item.

Repository methods added:
- getDashboardSummaryForDate(DateTime date)
- getTopSellingOilsForDate(DateTime date, {int limit = 5})
- getRecentOrdersForDate(DateTime date, {int limit = 5})

Notes:
- No database migration required; dashboard reads existing sales/order columns.
- Order-level dashboard summaries group rows by order_id when present and fall back to sale id for older single-sale rows.
- Profit is computed from sale snapshots and subtracts order-level discount once per order.
- Top selling oils infer quantity sold from total_amount / unit_price_snapshot because the current sales table has no separate quantity column.
- `flutter analyze` was run. It reported three existing info-level issues in untouched Sales/Cart/Pricing UI files:
  - lib/screens/sales/cart_screen.dart: unnecessary_underscores
  - lib/screens/sales/sales_screen.dart: use_build_context_synchronously
  - lib/widgets/feedback/update_price_dialog.dart: deprecated_member_use

Manual checks to perform:
- Open Dashboard before any sale today and verify metric cards and tables show empty states.
- Save a single-product sale and verify Dashboard revenue, profit, orders, average order value, top selling oils, and recent orders refresh when Dashboard is opened.
- Save a multi-item cart order with an order discount and verify Dashboard counts it as one order and uses the final order total.
- Verify Sales, Cart, Products & Pricing, Sale History, Reports, and Settings still open from the side menu.


2026-08-19 - Floating bottom navigation

Summary:
- Replaced the hamburger menu and navigation drawer with a floating bottom navigation bar.
- Added exactly five icon-only navigation buttons: Dashboard, Sales, Products, History, and Settings.
- Kept the existing dark theme and used a simple pill-shaped floating container with a highlighted active icon capsule.
- Updated the shell layout so screens reserve space for the bottom navigation.

Files modified:
- lib/screens/shell/app_shell.dart - removed drawer usage, added bottom navigation overlay, and reserved bottom layout space.
- lib/screens/shell/top_bar.dart - removed the hamburger menu button.
- lib/screens/shell/floating_bottom_nav.dart - added the floating icon-only navigation bar.
- lib/screens/shell/side_menu.dart - removed the old drawer widget.

Notes:
- No Providers, Repositories, SQLite code, database schema, or business logic were changed.
- Reports remains in the codebase but is no longer exposed in the five-button navigation requested for this update.
- `flutter analyze` was run. It reported the same three existing info-level issues in untouched Sales/Cart/Pricing UI files:
  - lib/screens/sales/cart_screen.dart: unnecessary_underscores
  - lib/screens/sales/sales_screen.dart: use_build_context_synchronously
  - lib/widgets/feedback/update_price_dialog.dart: deprecated_member_use

Manual checks to perform:
- Launch the app and verify there is no hamburger icon and no navigation drawer.
- Confirm the bottom navigation shows five icon-only buttons with no visible labels.
- Tap Dashboard, Sales, Products, History, and Settings and confirm each screen opens.
- Confirm the bottom navigation does not cover screen content.

2026-09-04 — Sales screen UI/UX redesign (presentation layer only)

Summary:
- Redesigned sales_screen.dart and cart_screen.dart to feel like a premium
  landscape POS application. Inspired by Shopify POS, Square POS, and Linear.
- No providers, repositories, SQLite, state management, calculations, pricing
  logic, discount logic, payment logic, or cart logic were changed.
- Every existing provider call and database interaction continues to work
  exactly as before.

Files modified:
- lib/screens/sales/sales_screen.dart — full presentation redesign.
- lib/screens/sales/cart_screen.dart — full presentation redesign.
- DEVELOPMENT_LOG.md — this entry.

UI improvements:

sales_screen.dart:
- Replaced centered single-column card with a true two-panel landscape layout
  (55 / 45 flex split) that fills the full tablet canvas.
- Left panel: 4-column product tile grid with AnimatedContainer selection
  feedback, variant chip row, quantity stepper (− / field / +) with
  FilteringTextInputFormatter, unit price / line total readout card, and a
  full-width Add to Cart primary CTA.
- Right panel: persistent inline order summary (no modal push required);
  order header with item badge, cart list with accent dot rows, discount
  chips, payment mode chips, totals block, and Save Order CTA — all always
  visible while the user selects products.
- Removed unused app_dimens.dart and app_text_styles.dart imports.

cart_screen.dart:
- Replaced centered GlassCard column with a two-panel layout (cart list left,
  controls sidebar right at 320 px fixed width).
- Left panel: order header with item badge, scrollable cart item list, and an
  outlined "Add More Products" back button.
- Right panel: scrollable summary sidebar with discount chips, payment mode
  chips, totals block (subtotal / discount / final total), and Save Order CTA.
- Removed unused app_dimens.dart, app_text_styles.dart, and glass_card.dart
  imports; replaced ChoiceChip with consistent _SelectableChip widgets.

UX improvements:
- Products are now tapped directly from a grid instead of a dropdown — zero
  typing, one tap to select a product.
- Variant and discount selection use chip rows — no dropdowns to open.
- Payment mode shows icon + label chips with animated highlight; no dropdown.
- Quantity stepper allows both tap-to-increment and direct numeric entry.
- Unit price and line total are always visible before adding to cart.
- The cart is always visible in the right panel on the Sales screen — the
  operator can see the running order total at all times without navigating away.
- AnimatedContainer (130–140 ms, Curves.easeOut) on all chip and tile
  selections gives immediate, non-distracting feedback.
- Save Order CTA is disabled and visually muted when cart is empty; active
  (full AppColors.primary fill) when items are present.
- Discount rows in the totals block only render when a discount is active,
  keeping the summary clean for full-price orders.

Reused components:
- SalesProvider — all provider calls (selectProduct, selectVariant,
  setQuantity, refreshCurrentPrice, addToCart, removeCartItem,
  setOrderDiscountPercent, setPaymentMode, saveOrder, isSaving, error,
  cart, subtotal, discountAmount, finalTotal, orderDiscountPercent,
  selectedPaymentMode, currentPrice, quantity, selectedProduct,
  selectedVariant) preserved verbatim.
- AppColors — all colour tokens used from existing palette; no new colours.
- SuccessToast.show() — reused for Add to Cart and Save Order feedback.
- PaymentMode enum (dbValue, label) — unchanged.
- CartItem model (productName, variant, quantity, lineTotal) — unchanged.
- ProductCatalog.products and quantityVariants — unchanged.

New reusable widgets introduced (private to each file, not promoted to
lib/widgets/ since they are screen-specific):
- _SelectableChip — animated chip used for variants, discounts.
- _PaymentModeChip — animated chip with icon + label for payment modes.
- _QuantityButton — icon button with opacity fade when disabled.
- _TotalRow — label / value row used across both totals blocks.
- _PanelLabel / _SectionLabel — consistent uppercase muted section headers.
- _PriceReadout — unit price + line total two-column card.
- _ProductTile — animated product grid tile.
- _CartItemRow — accent-dot cart row (shared pattern across both files).
- _EmptyCartState / _EmptyState — empty cart illustrations.

flutter analyze: No issues found (ran in 7.8 s).

Manual checks to perform:
- Launch app on a landscape tablet; confirm two-panel layout fills the screen
  with no overflow, clipping, or scrolling on the Sales screen.
- Tap each of the 8 product tiles; confirm active tile highlights green and
  variant chips update to match the selected product's variants.
- Tap each variant chip; confirm selection animates and price readout updates.
- Use − / + stepper and direct numeric entry; confirm quantity updates and
  line total recalculates.
- Tap Add to Cart; confirm item appears in the right-panel cart list and the
  toast fires.
- Select discount chips (5, 7, 10, 12, 15 %); confirm only one is active at
  a time, toggling the same chip deselects it, and totals block shows/hides
  the discount row accordingly.
- Tap Cash, UPI, Card payment chips; confirm only one is active at a time.
- Tap Save Order with items; confirm order saves, cart clears, toast fires.
- Tap Save Order with empty cart; confirm button is muted and non-interactive.
- Navigate to Cart screen (if pushed from elsewhere); confirm the two-panel
  cart layout renders correctly with all controls functional.
- Confirm Dashboard, Products, Sale History, and Settings are unaffected.
- Run flutter analyze — expect no issues.

2026-09-04 — Products & Pricing UI/UX redesign (presentation layer only)

Summary:
- Redesigned the Products & Pricing screen, product pricing card, and update
  price dialog to match the flat-surface visual language established by the
  Dashboard and Sales screens.
- No providers, repositories, SQLite, state management, calculations, pricing
  logic, cost-price propagation, or navigation were changed.
- Every existing provider call and database interaction continues to work
  exactly as before.

Files modified:
- lib/screens/products_pricing/products_pricing_screen.dart — screen redesign.
- lib/widgets/cards/product_pricing_card.dart — card redesign.
- lib/widgets/feedback/update_price_dialog.dart — dialog redesign.
- DEVELOPMENT_LOG.md — this entry.

UI improvements:

products_pricing_screen.dart:
- Added _ScreenHeader row (title + muted subtitle + Refresh button) matching
  the Dashboard header pattern exactly — same OutlinedButton style, same
  inline loading spinner, same typography.
- Added screen-level _ErrorState (error icon + message + Try Again button)
  matching Dashboard's _DashboardErrorState.
- Replaced Wrap + manual cardWidth arithmetic with GridView.builder using
  SliverGridDelegateWithFixedCrossAxisCount. Column count is still responsive
  (2–4 columns via LayoutBuilder) but card heights are now consistent across
  each row via a fixed mainAxisExtent. No more mismatched card heights.

product_pricing_card.dart:
- Replaced GlassCard (backdrop blur + gradient) with a plain
  Container(AppColors.surface, Border.all(AppColors.border), radius 14)
  matching Dashboard's _KpiCard and _RecentOrdersPanel surfaces.
- Added a 4 px tint-colour accent bar on the left edge of each card — gives
  each product a unique identity without gradients.
- Collapsed face now shows the product name AND a 1L price preview (tint
  colour, w700) + animated chevron — operators can scan prices without
  expanding every card.
- Expanded detail replaced the flat ListView of price rows with a proper
  table layout: SIZE / SELLING / COST / UPDATED column headers (muted, 10 px,
  w700, tracked) + per-row data with clear typographic hierarchy — variant
  as a badge chip, selling price w700/textPrimary, cost price
  w500/textSecondary, date textMuted.
- "Update Price" button changed from low-contrast OutlinedButton
  (white/0.12 border) to FilledButton (AppColors.primary background,
  AppColors.background foreground, radius 12, height 52) — identical style
  to ADD TO CART and SAVE ORDER in the Sales screen.
- AnimatedContainer expand/collapse kept at 220 ms Curves.easeInOutCubic;
  chevron rotates 180° on expand via AnimatedRotation.

update_price_dialog.dart:
- Replaced GlassCard (backdrop blur) with a plain Container
  (AppColors.surface, Border.all(AppColors.border), radius 16, drop shadow)
  matching Dashboard card surfaces.
- DropdownButtonFormField variant selector replaced with a chip-row
  (_VariantChip) using the same AnimatedContainer + InkWell pattern as the
  Sales screen's variant chips — AppColors.primary fill when selected,
  AppColors.border outline when unselected, 130 ms Curves.easeOut.
- All input fields (_PriceField + _NoteField) use consistent
  OutlineInputBorder styling with explicit enabled/focused/error states and
  a ₹ prefix text — read-only fields use AppColors.background fill and
  reduced-opacity border to communicate non-editability.
- Cancel / Save Price buttons are now 52 px tall, radius 12, matching Sales
  CTAs exactly.
- Fixed pre-existing analyzer warning: all withOpacity() calls replaced with
  withValues(alpha:) throughout the file.
- Dialog header updated with an icon container (AppColors.primaryMuted
  background, edit icon in AppColors.primary) + product name · variant
  subtitle line.

UX improvements:
- Pricing data is visible at a glance on collapsed cards — no need to expand
  all 8 cards to audit prices.
- Variant selection in the dialog is now a single tap on a chip instead of
  opening a dropdown — consistent with the Sales screen interaction model.
- Read-only cost price fields are visually distinct (darker fill, faded
  border) so operators immediately understand only Selling Price is editable
  for non-1L variants.
- Refresh button and error retry follow the same pattern as Dashboard so
  the interaction is familiar across screens.

Reused components:
- ProductsPricingProvider — all calls (loadCurrentPrices, saveProductPrice,
  currentPricesFor, isLoading, errorMessage) preserved verbatim.
- AppColors — all tokens from existing palette; no new colours introduced.
- AppTextStyles.screenTitle — reused in _ScreenHeader.
- AppDimens.spacingMedium / spacingLarge / spacingSmall — used throughout.
- ProductCatalog.products / quantityVariants — unchanged.
- UpdatePriceDialog.show() static method — signature unchanged; all callers
  (products_pricing_screen.dart) continue to work without modification.

New reusable widgets introduced (private, screen/widget-scoped):
  In product_pricing_card.dart:
  - _CollapsedFace — product name + tint bar + price preview + chevron.
  - _ExpandedDetail — detail panel shell with divider + padding + CTA.
  - _PriceTableHeader — column header row (SIZE/SELLING/COST/UPDATED).
  - _PriceVariantRow — per-variant data row with badge chip.
  - _UpdatePriceButton — FilledButton CTA.
  - _StatusMessage — loading / error / empty state text.

  In update_price_dialog.dart:
  - _DialogHeader — icon container + title + subtitle row.
  - _FieldLabel — uppercase muted section label.
  - _VariantChipRow — chip row container.
  - _VariantChip — animated selectable chip (same pattern as Sales).
  - _PriceField — styled TextFormField with ₹ prefix and read-only support.
  - _NoteField — styled optional note TextField.
  - _DialogActions — Cancel + Save Price button row.

  In products_pricing_screen.dart:
  - _ScreenHeader — title + subtitle + refresh button (Dashboard-pattern).
  - _ErrorState — error icon + message + retry button (Dashboard-pattern).

Confirmation:
- Providers NOT modified.
- Repositories NOT modified.
- SQLite NOT modified.
- Business logic NOT modified.
- ProductCatalog NOT modified.
- Pricing calculations NOT modified.
- Cost-price propagation NOT modified.
- Navigation NOT modified.

flutter analyze: No issues found (ran in 3.7 s).

Manual checks to perform:
- Open Products & Pricing; confirm 4-column grid on a landscape tablet with
  no overflow or clipping.
- Confirm collapsed cards show product name, tint accent bar, 1L price
  preview, and chevron.
- Tap a card; confirm it expands smoothly (220 ms) and shows SIZE/SELLING/
  COST/UPDATED table. Chevron rotates down. Tap again — collapses.
- Tap "UPDATE PRICE"; confirm the dialog opens with chip-row variant
  selector, ₹-prefixed price fields, and Save Price / Cancel buttons.
- Select a non-1L variant in the dialog; confirm Cost Price field becomes
  read-only (darker fill). Select 1L; confirm Cost Price becomes editable.
- Save a price; confirm the card updates and the success flow works as before.
- Tap Refresh in the screen header; confirm prices reload.
- Confirm Dashboard, Sales, Sale History, and Settings remain unaffected.
- Run flutter analyze — expect no issues.

2026-09-04 — Products & Pricing card height fix (presentation only)

Summary:
- Replaced GridView.builder (fixed mainAxisExtent: 544 px) with a Wrap inside
  a SingleChildScrollView. Cards now size themselves to their own animated
  height — collapsed cards sit at 96 px, and only the tapped card expands.
- No business logic, providers, repositories, or SQLite were changed.

Files modified:
- lib/screens/products_pricing/products_pricing_screen.dart — swapped
  GridView for Wrap + SingleChildScrollView; removed _cardExtentFor helper.

flutter analyze: No issues found (ran in 4.3 s).

2026-09-05 — Sale History screen UI/UX redesign (presentation layer only)

Summary:
- Redesigned the Sale History screen to match the flat-surface premium visual
  language established by Dashboard, Sales, and Products & Pricing.
- No providers, repositories, SQLite schema, database queries, models,
  calculations, navigation, month filtering logic, or calendar functionality
  were changed.
- Every existing provider call and database interaction continues to work
  exactly as before.

Files modified:
- lib/screens/sale_history/sale_history_screen.dart — full presentation redesign.
- DEVELOPMENT_LOG.md — this entry.

UI improvements:

Header:
- Replaced plain row (title + bare IconButton) with a premium two-part header
  matching the Dashboard pattern exactly.
- Left side: large month title (28 px, w700, letter-spacing −0.5) +
  muted order-count subtitle ("126 orders") — count updates live with search
  and reflects the currently loaded month.
- Right side: OutlinedButton.icon with calendar icon and "Month" label —
  identical style (background AppColors.surface, border AppColors.border,
  radius 10, padding 16×12) to the Refresh button on Dashboard.
- Loading state shows "Loading…" in the subtitle instead of a stale count.

Search bar:
- Replaced bare TextField with a fully styled input field — AppColors.surface
  fill, AppColors.border enabled border, AppColors.primary focused border
  (1.5 px), radius 10, muted hint text, rounded search icon prefix.
  Matches the input language used in the update_price_dialog fields.

Order list — day grouping:
- Replaced nested Column-inside-ListView with a flat ListView.builder fed a
  pre-built list of _DayHeaderItem and _OrderCardItem objects — no nested
  scroll conflicts, no layout jank, smooth BouncingScrollPhysics on tablets.
- Day headings: bold secondary text (13 px, w700) + full-width Divider to
  the right — clean visual separation without heavy separators.
- "Today" and "Yesterday" labels prepended automatically when applicable
  (e.g. "Today · 5 September").
- Groups respect the newest-first ordering already returned by the repository.
- AnimatedSwitcher (200 ms) transitions between loading / error / empty /
  list body states without layout jumps.

Order cards:
- Replaced DecoratedBox + flat Padding with a Container matching Dashboard's
  _RecentOrdersPanel card surface: AppColors.surface fill, AppColors.border
  border, radius 14, subtle drop shadow (black 12 % / blur 6 / offset 0,2).
- Top row: time (muted, 12 px, w500) + payment mode badge side-by-side.
- Middle: oil lines each prefixed with a 5 px AppColors.primary accent dot —
  same dot pattern used in the Sales screen cart item rows.
- Right column: total amount (20 px, w700, letter-spacing −0.3) aligned to
  the vertical centre — immediately readable as the most important value.
- No order IDs, database identifiers, or internal fields are displayed.

Payment mode badges:
- Exact replica of Dashboard's _PaymentMethodBadge: colour-coded bg/border/
  text per mode (Cash = green, UPI = blue, Card = amber/purple), radius 6,
  uppercase label, 10 px w700, letter-spacing 0.5.

Empty state:
- Replaced plain centred Text with a two-state empty panel:
  - No sales: receipt icon (48 px, muted 50 %) + "No sales found" (17 px,
    w600) + "Select another month using the calendar." subtitle.
  - Search miss: same icon + "No matching orders" + "Try a different product
    name or payment mode." subtitle.
  - Matches Dashboard's _EmptyOrdersState typographic pattern.

Error state:
- Added a proper error panel matching Products & Pricing _ErrorState:
  danger-border container + error icon + message + "Try Again"
  OutlinedButton.icon that calls provider.loadOrders(forceReload: true).

Month picker dialog:
- Replaced Dialog(backgroundColor: AppColors.surface) with a transparent
  Dialog wrapping a plain Container — same shadow + border treatment as the
  update_price_dialog (radius 16, border AppColors.border, black 35 % shadow).
- Header updated with icon container (AppColors.primaryMuted bg, calendar
  icon in AppColors.primary) + title row — same pattern as the update price
  dialog header.
- Year dropdown wrapped in a styled Container (AppColors.surfaceElevated,
  radius 8, border) instead of a bare DropdownButtonHideUnderline.
- Month chips updated from AnimatedContainer + plain InkWell to the exact
  animated chip pattern used across Sales, Products & Pricing, and the update
  price dialog: AnimatedContainer (130 ms, Curves.easeOut), AppColors.primary
  fill when selected, AppColors.border outline when unselected, Material +
  InkWell for splash, AppColors.background foreground when selected.

Responsiveness:
- Single-column list on all tablet widths — no grid, no overflow risk.
- Month picker grid: 4 columns ≥ 400 px, 3 columns below — same breakpoint
  as the original implementation.
- All spacing uses AppDimens tokens; no hardcoded magic numbers.

Reused components:
- SaleHistoryProvider — all calls (loadOrders, orders, searchQuery,
  setSearchQuery, selectMonth, selectedMonth, isLoading, hasLoaded,
  errorMessage) preserved verbatim.
- DateTimeService — formatMonthYear, formatTime used exactly as before.
- NavigationProvider.currentIndex — tab-active detection unchanged.
- AppColors — all tokens from existing palette; no new colours.
- AppDimens — spacingLarge, spacingMedium, spacingSmall throughout.
- PaymentMode.label — unchanged.
- SaleHistoryOrder / SaleHistoryItem models — unchanged.

New private widgets (screen-scoped, not promoted to lib/widgets/):
- _HistoryHeader — month title + order count + calendar button.
- _SearchBar — styled search TextField.
- _OrderListView — flat-list day-grouped renderer.
- _DayHeading — date label + trailing divider.
- _OrderCard — premium transaction card.
- _PaymentBadge — colour-coded payment mode badge (mirrors Dashboard).
- _EmptyState — two-variant empty panel.
- _ErrorState — error panel with retry (mirrors Products & Pricing).
- _MonthPickerDialog — restyled month/year picker (logic unchanged).
- _MonthChip — animated chip (same pattern as Sales/Products chips).
- _DayHeaderItem / _OrderCardItem — flat list item descriptors.

Confirmation:
- Providers NOT modified.
- Repositories NOT modified.
- SQLite NOT modified.
- Business logic NOT modified.
- Models NOT modified.
- Navigation NOT modified.
- Month filtering logic NOT modified.
- Calendar functionality NOT modified.

flutter analyze: No issues found (ran in 4.5 s).

Manual checks to perform:
- Open Sale History; confirm header shows current month name + order count.
- Confirm calendar button matches Dashboard Refresh button style.
- Tap calendar; confirm month picker opens with styled chips and year
  dropdown. Select a different month; confirm list reloads.
- Search by a product name; confirm matching orders appear, count updates,
  "No matching orders" empty state shows when nothing matches.
- Clear search; confirm all orders return.
- Confirm day headings appear with inline dividers and "Today" / "Yesterday"
  labels where applicable.
- Confirm each order card shows time, payment badge, oil lines with accent
  dots, and total amount — no order IDs visible.
- Confirm Cash = green badge, UPI = blue badge, Card = amber badge.
- On an empty month, confirm "No sales found" empty state with subtitle.
- Trigger a load error (disable DB); confirm error panel with Try Again.
- Confirm Dashboard, Sales, Products & Pricing, and Settings are unaffected.
- Run flutter analyze — expect no issues.

2026-09-05 — Delete Sale feature

Summary:
- Implemented end-to-end order deletion: SQLite → Repository → Provider → UI.
- Follows the existing Provider → Repository → SQLite architecture exactly.
- No database schema, migrations, business logic, pricing, cart, reports
  calculations, or navigation were modified.

Files modified:
- lib/models/sale_history_model.dart
- lib/repositories/sale_repository.dart
- lib/providers/sale_history_provider.dart
- lib/screens/sale_history/sale_history_screen.dart
- DEVELOPMENT_LOG.md

────────────────────────────────────────────────────────────────────────────
lib/models/sale_history_model.dart
────────────────────────────────────────────────────────────────────────────
- Added required field `final String orderKey` to `SaleHistoryOrder`.
- `orderKey` is the `COALESCE(order_id, id)` value that the repository
  already computed as `order_key` in `getSaleHistoryOrders`. It mirrors the
  grouping key used by every read query and is now the canonical identifier
  for delete operations.

────────────────────────────────────────────────────────────────────────────
lib/repositories/sale_repository.dart
────────────────────────────────────────────────────────────────────────────
Changes:
  1. `getSaleHistoryOrders` — both `SaleHistoryOrder(...)` constructor calls
     (new order and merged order) now pass `orderKey: orderKey` from
     `row['order_key']`. No SQL changed.

  2. Added `deleteOrderByKey(String orderKey)`:
     ```dart
     Future<void> deleteOrderByKey(String orderKey) async {
       final db = await _dbHelper.database;
       await db.delete(
         SaleTable.tableName,
         where: '${SaleTable.orderId} = ? '
             'OR (${SaleTable.orderId} IS NULL AND ${SaleTable.id} = ?)',
         whereArgs: [orderKey, orderKey],
       );
     }
     ```
     This mirrors the `COALESCE(order_id, id)` pattern used throughout the
     repository:
     - Multi-item orders share a non-null `order_id` — all their rows are
       deleted in one statement.
     - Single-item orders have `order_id IS NULL` — only the row whose `id`
       matches is deleted.
     The existing `deleteSale(String id)` method (single-row PK delete) is
     left untouched; it remains available for any other caller.

────────────────────────────────────────────────────────────────────────────
lib/providers/sale_history_provider.dart
────────────────────────────────────────────────────────────────────────────
- Added `Future<void> deleteOrder(String orderKey)`:
  - Finds the order in `_allOrders` by `orderKey`.
  - Removes it **optimistically** — the card disappears immediately without
    waiting for SQLite — then calls `_saleRepository.deleteOrderByKey`.
  - On repository failure: restores the removed order at its original index
    and sets `_errorMessage` so the screen can surface the problem. This
    keeps `_allOrders` consistent with SQLite in all cases.
  - Uses `List<SaleHistoryOrder>.from(...)` copies throughout to avoid
    mutating the const-initialized empty list.

────────────────────────────────────────────────────────────────────────────
lib/screens/sale_history/sale_history_screen.dart
────────────────────────────────────────────────────────────────────────────
Presentation changes only. All existing provider calls, routing, and
business logic are unchanged.

Imports:
- Added `../../providers/dashboard_provider.dart` to enable post-delete
  dashboard refresh.

`_SaleHistoryScreenState`:
- Added `_handleDelete(String orderKey)`:
    1. Calls `context.read<SaleHistoryProvider>().deleteOrder(orderKey)`.
    2. Calls `context.read<DashboardProvider>().loadToday(forceReload: true)`
       so the Dashboard revenue / order-count metrics stay accurate after
       deletion without requiring a manual refresh.

`_buildBody`:
- Passes `onDelete: _handleDelete` to `_OrderListView`.

`_OrderListView`:
- Added `required this.onDelete` parameter.
- Passes `onDelete` into each `_OrderCardItem`.
- Wrapped each card render path in `AnimatedSize` (220 ms,
  `Curves.easeInOutCubic`) — the card collapses smoothly to zero height
  when the provider removes it from `_allOrders`, rather than disappearing
  abruptly.

`_OrderCardItem`:
- Added `required this.onDelete` field, threaded down to `_OrderCard`.

`_OrderCard`:
- Added `required this.onDelete` parameter.
- Restructured from a single `Row` to a `Column` so:
    • Top: the existing time + badge + oil lines row (unchanged).
    • Bottom: a right-aligned row containing the new `_DeleteButton`.
  Total amount stays top-right, visually unchanged.
- `_confirmDelete(BuildContext)` — uses `showGeneralDialog` with a
  `FadeTransition` + `ScaleTransition` (begin 0.92 → 1.0, 220 ms,
  `Curves.easeOutCubic`). Returns `bool?`; calls `onDelete` only when
  `true`.

New widgets added (private, screen-scoped):

`_DeleteButton`:
- 34 × 34 px circular button.
- Background `Color(0xFF3D1A1A)`, border `Color(0xFF6B2828)`, icon
  `AppColors.danger` — red family consistent with `_DeleteConfirmDialog`.
- Soft red glow shadow (`AppColors.danger` at 18 % opacity).
- `Material` + `InkWell` with `CircleBorder` for proper ripple clipping.
- `Icons.delete_outline_rounded`, size 16.

`_DeleteConfirmDialog`:
- Constrained to max-width 420 px, centred on screen.
- `AppColors.surface` container, `Color(0xFF6B2828)` border (red family),
  radius 16, heavy drop shadow — matches the update_price_dialog surface
  treatment.
- Header: danger icon container (38 × 38, `Color(0xFF3D1A1A)` bg) +
  "Delete Sale?" title — same icon-container header pattern as other dialogs.
- Body: secondary message + "This action cannot be undone." in
  `AppColors.danger`.
- Actions row (48 px height, radius 10):
    • Cancel — `OutlinedButton`, `AppColors.border` side, neutral foreground.
    • Confirm Delete — `FilledButton`, `AppColors.danger` background, white
      foreground, w700. Pops `true`; Cancel pops `false`.

Architecture confirmation:
- Database schema NOT modified.
- Migrations NOT modified.
- Business logic NOT modified.
- Reports calculations NOT modified.
- Product pricing NOT modified.
- Sales / Cart flow NOT modified.
- Dashboard layout NOT modified.
- Navigation NOT modified.

flutter analyze: No issues found (ran in 4.5 s).

Manual checks to perform:
- Open Sale History; confirm each order card shows a small circular red
  delete button at the bottom-right.
- Tap the delete button; confirm the dialog appears with a smooth
  fade + scale animation.
- Tap Cancel; confirm the dialog dismisses and the order card is unchanged.
- Tap the delete button again, then Confirm Delete; confirm:
    • The card animates away smoothly (AnimatedSize collapse).
    • The order count in the header decrements.
    • Switching to Dashboard confirms the revenue and order count have
      updated without a manual refresh.
- Delete the last order in a day group; confirm the day heading disappears
  with the card (no orphaned heading).
- Delete the last order in the month; confirm the "No sales found" empty
  state appears.
- Simulate a delete failure (e.g., close DB); confirm the card reappears
  and an error message is shown.
- Verify multi-item orders (multiple oil lines) are deleted in full —
  no orphaned line items remain in Sale History or Dashboard.
- Verify single-item orders (no order_id) are also deleted correctly.
- Confirm Sales, Products & Pricing, and Settings are unaffected.
- Run flutter analyze — expect no issues.

2026-09-05 — Top bar metrics removal (UI-only)

Summary:
- Removed "Today's Sales", the sales amount, "Today's Orders", the orders
  count, the vertical spacing between them, and the Spacer that pushed them
  to the right side of the top bar.
- Removed the now-unused SalesProvider import and the private _Metric widget
  from top_bar.dart.
- "Satvik Oils" title remains, styled with the existing AppTextStyles.brand
  token (24 px, w700, AppColors.textPrimary) — no style change applied.
- Header height (AppDimens.topBarHeight = 72) and padding unchanged.
- Updated widget_test.dart to remove the two assertions that checked for
  the deleted strings, keeping the test valid.

Files modified:
- lib/screens/shell/top_bar.dart — removed metrics section.
- test/widget_test.dart — removed stale Today's Sales / Today's Orders assertions.

Affected screens:
- All screens rendered inside AppShell (Dashboard, Sales, Products & Pricing,
  Sale History, Settings) share the single TopBar component. All now show the
  clean header automatically.

Confirmation:
- No business logic changed.
- No providers changed.
- No repositories or SQLite touched.
- No navigation changed.
- SalesProvider.todaysSalesRevenue and SalesProvider.todaysOrdersCount still
  exist in the provider — they are simply no longer read by the top bar.

flutter analyze: No issues found (ran in 40.8 s).
