# UBeer Wholesale POS

Android POS for wholesale distribution. Product quantities represent packs; every product stores units per pack and volume per unit. Prices are per pack in USD. Products support sales tax percentages and soda sugar tax rates in dollars per US fluid ounce. Sugar tax uses ounces per unit times units per pack times pack quantity; sales tax is calculated on the product price before sugar tax. Existing invoices retain their original tax snapshots.

## Use

1. Open Products and add a product, its barcode, pack size, unit volume, and price. Enter sales tax (%), and enable soda sugar tax with a dollar rate per US fluid ounce and ounces per unit when applicable.
2. In Point of sale, scan or type a barcode. A unique exact barcode/name adds automatically after input settles; Enter submits immediately. Similar names offer choices. Unknown barcodes can be saved as new products.
3. Add customer details, change quantities, remove items, or use the pencil Price button for an invoice-specific price.
4. Record full or partial payments already received. Balance updates immediately. Card payments require an external terminal; this app records payment details and does not charge cards.
5. Finalize. Invoice history lets you reopen, add items, remove items, change prices, record further payments, print, or delete an invoice. Removing paid items can create customer credit/refund due; the app displays this and does not issue a refund automatically.
6. Settings configures business details, custom receipt footer, additional receipt text, and receipt options. All invoices contain pack sizes, volume, individual unit and pack totals, customer details, payments, and balance; no Tax ID field is printed.
7. Sales reports support invoice-date filtering and show sales, recorded payments, outstanding balances, sugar tax, top products, and unit/pack counts.

## Devices

Use a USB or Bluetooth scanner supporting keyboard/HID mode. Configure its suffix to Enter and focus the scan field. Settings opens Android Bluetooth pairing. Product barcode fields also accept scanner input. Tap the camera icon beside the scan field to request Android camera permission and open the barcode scanner. Known barcodes add to the cart; unknown barcodes open a new product form. The product editor also has a camera scan button. Permission is requested only when you tap the button; previously granted access is reused. Denied access leaves typed and hardware scanner input available. Proprietary scanner SDKs are not included.

Settings opens Android printer setup. Printing uses Android's print framework and a separate invoice document, so application controls are excluded. A printer must have a compatible installed Android print service; PDF output is also available. Direct ESC/POS Bluetooth thermal printing is not included.

## Storage

Data is saved locally in Android private SharedPreferences after changes (browser preview uses localStorage). Existing invoice lines retain product details and tax when catalog products are edited/deleted. Settings includes JSON copy/restore backups. Keep an external backup before uninstalling or clearing app data. This is a single-device application with no multi-user sync or payment processor connection.

## Build and checks

With the Android SDK configured in local.properties and a JDK installed:

```powershell
$env:JAVA_HOME='C:/Program Files/Android/Android Studio/jbr'
./gradlew.bat :app:assembleDebug :app:testDebugUnitTest --no-configuration-cache
node --test tests/pos.test.cjs
```

Debug APK: app/build/outputs/apk/debug/app-debug.apk

The Node workflow tests exercise saved barcode matching, ambiguous names, duplicate barcodes, partial payments, finalizing and editing invoices, customer credit, print content, product snapshots, deletion, and invalid quantities/payments. Physical scanner and printer verification requires compatible connected hardware.


## Phone and tablet layouts

Products and the cart now share a single sales workspace on every screen size. Tablets show them side by side inside one panel. Phones show products above the cart on the same page, with a bounded product grid so large catalogs do not push the cart far down. Phone forms remain full-screen; tablet forms are centered and scrollable.

This repository produces an Android APK. An iPad-sized layout does not make that APK installable on iOS; an actual iPad application would need an iOS build and camera/printing integration.


## Saved customers

Customers has a searchable local directory (name, phone, email, and address), reusable invoice customer information, editing, invoice history, and outstanding balance totals. Save customer information on an invoice to add it to the directory, or use Customers > Add customer. Choose Find previous customer in the invoice customer form to select an existing record. Existing invoice customers are imported automatically. Directory edits do not modify historical invoice snapshots. Customer Tax ID is saved and reusable but remains omitted from receipts. The directory is included in JSON backups.


## Firebase cloud backup

Settings includes manual private Firebase backup and restore, with email/password authentication, complete snapshot checksums, and a local pre-restore recovery copy. It does not synchronize live orders between devices. Cloud activation still requires the Beer project configuration file, Firestore database, Authentication provider, and owner-only backup rules. See FIREBASE_SETUP.md for setup and verification status. Existing local POS operation is available without Firebase configuration.


## Sales reports

Reports provide Sales summary, Item sales, and Payment methods views; Today, Last 7 days, This month, and custom date ranges; sales trends; order count; average sale; taxes; balances; and packs/units sold. Sales are calculated from finalized invoice creation dates and current invoice lines. Collections are calculated independently from payment dates, including later partial payments on older invoices. Product pack sizes remain separate in item sales. Edits and deletions update report totals. Refund processing and discounts are not separately recorded by this app and are not shown as invented report values.
