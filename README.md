# Satvik Oils

An offline-first Android tablet sales management and business intelligence application built for a retail cold-pressed and edible oils business.

Satvik Oils is designed specifically for landscape tablet point-of-sale environments, focusing on recording sales in under 10 seconds with minimal taps, lightning-fast transaction logging, and real-time offline analytics without requiring constant internet access.

---

## Key Features

- **Rapid Point of Sale (POS)**: Optimized product catalog grid (Groundnut, Coconut, Sesame, Mustard, Sunflower, Safflower, Almond) with rapid quantity variants (100ml, 250ml, 500ml, 1L, 2L, 5L), cart management, customer selection, multiple payment modes (Cash, UPI, Card), and instant order confirmation.
- **Offline-First SQLite Architecture**: Instant local persistence using SQLite (`sqflite`). Operates seamlessly in environments with intermittent or zero internet connectivity.
- **Product Pricing & Variant Management**: Configurable selling and cost prices per product and quantity variant, backed by versioned SQLite database migrations.
- **Comprehensive Sales History**: Filter, inspect, and track past orders by date and month with detailed itemized breakdown and payment mode indicators.
- **Real-Time Analytics & Dashboard**:
  - Live revenue, order count, and payment breakdown metrics.
  - Product-level profitability analysis, margins, and sales volume tracking.
  - Customer purchase history, loyalty/membership status, and repeat order tracking.
- **Custom Hardware & UX Optimization**:
  - Dedicated landscape orientation tailored for tablet checkout counters.
  - Premium dark theme interface reducing eye strain in continuous retail use.
  - Floating bottom navigation and smooth transitions between core screens.

---

## Technology Stack

- **Framework**: [Flutter](https://flutter.dev/) (SDK `^3.12.2`)
- **Language**: [Dart](https://dart.dev/)
- **Local Database**: [SQLite](https://www.sqlite.org/) via [`sqflite`](https://pub.dev/packages/sqflite)
- **State Management**: [Provider](https://pub.dev/packages/provider) (`ChangeNotifierProvider`, `ChangeNotifierProxyProvider`)
- **Formatting & Utilities**: [`intl`](https://pub.dev/packages/intl), [`uuid`](https://pub.dev/packages/uuid), [`path`](https://pub.dev/packages/path)
- **Design System**: Material 3 with a custom dark palette, responsive tablet layout, and glassmorphic surface tokens.

---

## Architecture

The project follows a clean separation of concerns and unidirectional data flow:

```
UI (Screens & Widgets)
       │
       ▼
State Management (Providers)
       │
       ▼
Data Layer (Repositories & Services)
       │
       ▼
Local SQLite Database (DbHelper & Schema Migrations)
```

- **`lib/core/`**: Theme tokens (`AppColors`, `AppDimens`, `AppTheme`), static catalog definitions (`ProductCatalog`), date/time abstraction services (`DateTimeService`), and database helpers.
- **`lib/core/database/`**: Single SQLite gateway (`DbHelper`), schema definitions (`DbSchema`), and sequential migration scripts (`v1` through `v5`).
- **`lib/models/`**: Strongly-typed immutable models for products, cart items, sales, customers, analytics reports, and payment modes.
- **`lib/repositories/`**: Encapsulates raw SQL queries, transactions, and transformations for sales, products, customers, and settings.
- **`lib/providers/`**: Application state machines handling active cart calculations, date-filtered metrics, history reloads, and customer membership updates.
- **`lib/screens/`**: Tablet-tailored screens (Sales POS, Dashboard, Products & Pricing, Sale History, Analytics, Settings) hosted in an overarching `AppShell`.
- **`lib/widgets/`**: Reusable interactive UI components (expandable modal cards, segmented selectors, primary buttons, animated currency text, feedback banners).

---

## SQLite & Database Approach

- **Local Storage**: Stored locally in private application sandbox storage as `satvik_oils.db`.
- **Foreign Keys & Referential Integrity**: SQLite foreign keys enabled by default (`PRAGMA foreign_keys = ON`).
- **Transactional Migrations**: Upgrades are executed via deterministic, sequential migration handlers (`V1InitialSchema` → `V2AddOrderIdToSales` → `V3AddOrderSummaryToSales` → `V4AddMembership` → `V5AddCatalogVariants`).
- **Price Freezing**: Historic sales snapshot product name, variant, and exact unit price at transaction time, ensuring future catalog price modifications never alter historical financial audits.

---

## Analytics

The analytics engine processes sales data directly from SQLite:
- Aggregates daily, monthly, and overall revenue.
- Computes gross profit and gross margin based on cost vs. selling prices.
- Payment mode split analysis (Cash vs. UPI vs. Card).
- Customer segmentation (membership, total orders, lifetime spend).

---

## Screenshots

<!-- Add representative screenshots of the tablet UI here -->
*(Screenshots showing Landscape POS, Live Dashboard, Sales History, and Analytics screens will be placed here)*

---

## Project Structure

```
satvik_oils/
├── android/            # Android platform integration and build configuration
├── assets/             # Project assets (icons and resources)
├── docs/               # Technical reviews and architectural records
├── lib/
│   ├── app.dart        # Root app widget and global provider tree
│   ├── main.dart       # App entrypoint and orientation lock
│   ├── core/           # Constants, theme, database helpers, migrations
│   ├── models/         # Domain models and enums
│   ├── providers/      # Feature state providers
│   ├── repositories/   # SQLite data access objects
│   ├── screens/        # Screen implementations for each module
│   ├── services/       # Pricing and utility calculation services
│   └── widgets/        # Shared components and visual feedback
├── test/               # Unit and calculation test suite
├── ARCHITECTURE.md     # In-depth architectural blueprint
├── DEVELOPMENT_LOG.md  # Detailed feature implementation log
├── PROJECT.md          # Core specifications and business rules
└── pubspec.yaml        # Flutter dependency declarations
```

---

## Getting Started & Setup

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.12.2` or later compatible Flutter 3.x)
- Android SDK & Build Tools (API Level 34 / Java 17+ recommended)
- Physical Android tablet or landscape emulator configured for `1280x800` or higher

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/<your-username>/satvik_oils.git
   cd satvik_oils
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify analyzer diagnostics**:
   ```bash
   flutter analyze
   ```

4. **Run the application** (in landscape on a connected device/emulator):
   ```bash
   flutter run
   ```

5. **Build debug APK**:
   ```bash
   flutter build apk --debug
   ```

---

## Version & Release Information

- **Current Version**: `1.0.0+1`
- **Platform Support**: Android Tablet (Landscape-first, target SDK 34)

---

## Future Improvements

As outlined in the project roadmap:
- **Inventory Tracking**: Stock level tracking and low-stock threshold alerts.
- **Thermal Receipt Printing & Billing**: Support for ESC/POS thermal receipt printers and GST invoice generation.
- **Expense Management**: Direct logging of operational overheads and raw seed batch procurement costs.
- **Multi-Device Cloud Sync**: Optional manual or background Firestore cloud sync for multi-counter or back-office access.