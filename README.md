# eco2shop

Small product catalog in Flutter. Products come from [DummyJSON](https://dummyjson.com) (no API key).

The brief was a catalog: list, pagination, detail, search, and the usual loading / error / empty states. I also added a cart, a mock checkout, and an order history after that. Those extras are not wired to a real payment API. There is no login. That was on purpose, it is not in the assignment.

## Run
flutter pub get
flutter run

Needs a device or simulator and internet (the list calls DummyJSON).

flutter test


## Stack

- Flutter
- Riverpod (`Notifier` / `NotifierProvider`) for screen state
- `http` for the API

## How the code is split

Two layers, plus screens:

- `lib/api/` — HTTP client and error type. This is the only place that talks to DummyJSON.
- `lib/feature/products/providers/` — list, search, pagination, selected category. Screens do not build URLs.
- `lib/feature/*/screens/` — UI. Home, catalog, product detail, cart, checkout, orders.

Product JSON is parsed in `lib/feature/products/models/product_model.dart`.

I kept cart, checkout, and orders in their own `feature/` folders so the catalog does not depend on them. Checkout only calls the order provider after a mock payment succeeds.

## Required catalog behaviour

List: `GET /products?limit=20&skip=0`. Each card shows title, thumbnail, and price.

Pagination: scrolling near the bottom calls the same endpoint with a higher `skip`. `skip` is the number of products already loaded, not the page index. I stop when `products.length` reaches `total`.

Detail: tap a product, `GET /products/{id}`. Shows description, price, rating, and images. Broken images fall back to an icon.

Search: the catalog search box is debounced (500ms) and hits `GET /products/search?q=`. I did not filter the list already on screen. DummyJSON already searches the full catalog, and a client-side filter would miss products that have not been paged in yet. If you type again before the last request finishes, the older response is ignored (`_searchGeneration` in `ProductNotifier`).

States:

- loading — spinner on first load
- error — message and a Retry button (home and catalog)
- empty — “No products found”
- success — the list / grid

Pull-to-refresh is on the home list and the catalog.

## Extra (after the catalog)

Not required. Included so the app is usable past browsing:

- Cart (add, quantity, remove)
- Checkout with mock payment only (card, FPX, e-wallet, cash on delivery). A card number ending in `0002` is declined. Nothing is charged.
- Order history on the bottom nav. A successful checkout clears the cart and saves the order in memory.

Orders and the cart are lost when the app restarts. There is no database.

## Not done

- No login / account screen in this submission
- No saved cart or orders
- No real payment gateway
- Category chips on the home screen are extra filtering via DummyJSON’s category endpoint, not part of the search box

## AI assistance

I used AI mostly to skip typing out boilerplate and to look up syntax, rather than for logic or architecture.

- **Models:** Generated the Dart `Product` classes and `fromJson` boilerplate straight from the DummyJSON payload.
- **Syntax:** Checked the exact syntax for the `Timer` debounce and the baseline Riverpod `Notifier` setup.