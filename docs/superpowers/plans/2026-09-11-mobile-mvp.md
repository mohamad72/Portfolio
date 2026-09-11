# Portfolio Mobile MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the bootstrap into a usable Android Flutter MVP that can authenticate against Mofid with the observed OIDC/PKCE contract, read account holdings and market data, persist local sub-portfolios and allocations, manage a local watchlist, compare against Ayar when data exists, and export a safe Markdown snapshot.

**Architecture:** Keep the approved feature-first Clean structure (`data/domain/presentation`) with Cubit, `Future<Either<Failure,T>>`, generic `RemoteDataSource`, and `get_it` + `injectable`. Mofid transport contracts come only from the supplied HAR/design; when the available source is insufficient for a correct claim (execution-level trade history), the app exposes an explicit unavailable-data state instead of fabricating behavior.

**Tech Stack:** Flutter stable, Dart >=3.12, flutter_bloc, dartz, get_it, injectable, Dio, equatable, shared_preferences, flutter_secure_storage, local_auth, dio_cookie_manager, cookie_jar, html, crypto, path_provider.

**Spec:** `docs/superpowers/specs/2026-09-11-portfolio-design.md`

## Global Constraints

- Persian RTL UI.
- Never commit or log captured usernames, passwords, cookies, access tokens, national IDs, phone numbers, or HAR payloads.
- Mofid login uses the observed `easy_pkce` authorization-code + S256 PKCE contract and manual web login; captcha/OTP remain on Mofid's page.
- Read-only account integration only. No order placement or account mutation.
- Mofid price fields are treated as rial and converted to toman exactly once at the data/domain boundary where the supplied contract supports it.
- Local sub-portfolio allocations must never exceed the synced total quantity for a symbol.
- Historical sub-portfolio profit remains unavailable until execution-level transaction ownership is known.
- `coin_blubber` is coin bubble, never gold bubble.
- Sharing uses a backend-free LAN HTTP server on the owner device, fixed Basic Auth credentials `viewer / portfolio123`, and read-only snapshots. Internet-wide access is explicitly out of scope without a relay/backend/VPN/port-forward.

---

### Task 1: Extend network and secure session boundary

**Files:**
- Modify: `lib/src/shared/network/remote_data_source.dart`
- Modify: `lib/src/shared/network/dio_remote_data_source.dart`
- Create: `lib/src/shared/security/secure_session_store.dart`
- Create: `lib/src/features/authentication/domain/entities/mofid_session.dart`
- Create: `lib/src/features/authentication/domain/repository/authentication_repository.dart`
- Create: `lib/src/features/authentication/data/repository/mofid_authentication_repository_impl.dart`
- Create: `test/features/authentication/data/mofid_authentication_repository_test.dart`

**Interfaces:**
- `RemoteDataSource.postJson(...)`, `postForm(...)`.
- `AuthenticationRepository.exchangeAuthorizationCode(code, verifier)` returns `MofidSession` and persists access token in secure storage.

- [ ] Write a fake-transport test verifying exact token form fields and no credential logging.
- [ ] Run the auth repository test and confirm RED before implementation.
- [ ] Implement form POST + secure session storage + token response mapping.
- [ ] Run the auth repository test and full suite.

### Task 2: Implement PKCE web login UX

**Files:**
- Create: `lib/src/features/authentication/domain/use_case/get_login_request.dart`
- Create: `lib/src/features/authentication/domain/use_case/complete_login.dart`
- Create: `lib/src/features/authentication/presentation/manager/authentication_cubit.dart`
- Create: `lib/src/features/authentication/presentation/manager/authentication_state.dart`
- Create: `lib/src/features/authentication/presentation/pages/mofid_login_page.dart`
- Create: `lib/src/features/authentication/data/pkce/pkce_generator.dart`
- Create: `test/features/authentication/data/pkce_generator_test.dart`

**Interfaces:**
- Authorization endpoint `https://login.emofid.com/connect/authorize`.
- Client `easy_pkce`, redirect `https://m.easytrader.ir/auth-callback`, scopes `easy2_api mts_api openid profile login_delegation-api`.

- [ ] Test verifier/challenge/state generation format.
- [ ] Implement direct HTTP Mofid login: PKCE authorize request, anti-forgery extraction, credential POST, callback validation, token exchange, secure credential persistence, and biometric re-entry.
- [ ] Validate state before code exchange; reject missing/mismatched state.
- [ ] Run auth tests.

### Task 3: Read Mofid holdings, cash and market quotes

**Files:**
- Create: `lib/src/features/portfolio/data/models/mofid_performance_item_model.dart`
- Create: `lib/src/features/portfolio/data/models/mofid_market_quote_model.dart`
- Create: `lib/src/features/portfolio/data/repository/mofid_portfolio_repository_impl.dart`
- Create: `lib/src/features/portfolio/domain/entities/account_snapshot.dart`
- Create: `lib/src/features/portfolio/domain/entities/portfolio_quote.dart`
- Create: `lib/src/features/portfolio/domain/repository/portfolio_repository.dart`
- Create: `lib/src/features/portfolio/domain/use_case/get_account_snapshot.dart`
- Create: `test/features/portfolio/data/mofid_portfolio_repository_test.dart`

**Interfaces:**
- `GET /assetmodule/api/performance` -> current quantities via `asset`.
- `GET /easy/api/money` -> cash values.
- `POST /symbols/api/marketdata` GraphQL body -> best buy/last/closing values.

- [ ] Test mapping from supplied response-shaped fixtures to holdings and toman values.
- [ ] Implement repository with Bearer token header loaded from secure session storage.
- [ ] Use `bestBuyPrice` as the explicitly labeled estimated immediate-sale basis when available; fallback is labeled last trade.
- [ ] Run portfolio data tests.

### Task 4: Persist local portfolios and validated allocations

**Files:**
- Create: `lib/src/features/portfolio/domain/entities/local_portfolio.dart`
- Create: `lib/src/features/portfolio/domain/entities/holding_allocation.dart`
- Create: `lib/src/features/portfolio/domain/repository/local_portfolio_repository.dart`
- Create: `lib/src/features/portfolio/data/repository/preferences_local_portfolio_repository_impl.dart`
- Create: `lib/src/features/portfolio/domain/use_case/save_symbol_allocations.dart`
- Create: `lib/src/features/portfolio/domain/use_case/get_local_portfolios.dart`
- Create: `test/features/portfolio/domain/save_symbol_allocations_test.dart`

**Interfaces:**
- `saveAllocations(symbolIsin,totalQuantity,allocations)` rejects negative values and sums above total.
- Unallocated quantity remains visible and belongs to no sub-portfolio.

- [ ] Test allocation invariants including exact total, partial allocation, over-allocation and negative quantities.
- [ ] Implement JSON persistence through SharedPreferences.
- [ ] Run allocation tests.

### Task 5: Build portfolio dashboard and allocation editor

**Files:**
- Create: `lib/src/features/portfolio/presentation/manager/portfolio_cubit.dart`
- Create: `lib/src/features/portfolio/presentation/manager/portfolio_state.dart`
- Create: `lib/src/features/portfolio/presentation/pages/portfolio_page.dart`
- Create: `lib/src/features/portfolio/presentation/widgets/holding_card.dart`
- Create: `lib/src/features/portfolio/presentation/widgets/allocation_sheet.dart`

**Interfaces:**
- Dashboard consumes account snapshot + local portfolios.
- Selector supports total account, each local portfolio and unallocated quantity.

- [ ] Render synced holdings, total value and cash separately.
- [ ] Allow create/rename local portfolio and per-symbol allocation edits.
- [ ] Keep historical profit labels unavailable when source history is insufficient.
- [ ] Add refresh and session-expired path.

### Task 6: Local watchlist backed by Mofid symbols/quotes

**Files:**
- Create: `lib/src/features/watchlist/domain/entities/watch_symbol.dart`
- Create: `lib/src/features/watchlist/domain/repository/watchlist_repository.dart`
- Create: `lib/src/features/watchlist/data/repository/watchlist_repository_impl.dart`
- Create: `lib/src/features/watchlist/presentation/manager/watchlist_cubit.dart`
- Create: `lib/src/features/watchlist/presentation/manager/watchlist_state.dart`
- Create: `lib/src/features/watchlist/presentation/pages/watchlist_page.dart`
- Create: `test/features/watchlist/data/watchlist_repository_test.dart`

**Interfaces:**
- Local selected ISINs persist in SharedPreferences.
- Symbol catalog uses `POST /symbols/api/symbols/all` only when authenticated.
- Quotes use the same market-data endpoint as portfolio.

- [ ] Test local add/remove/dedup behavior.
- [ ] Implement authenticated symbol search and quote refresh.
- [ ] Label values as price change, not investment profit.

### Task 7: Ayar benchmark and safe Markdown export

**Files:**
- Create: `lib/src/features/benchmark/domain/relative_return_calculator.dart`
- Create: `lib/src/features/export/domain/markdown_portfolio_exporter.dart`
- Create: `lib/src/features/export/data/markdown_file_writer.dart`
- Create: `test/features/benchmark/domain/relative_return_calculator_test.dart`
- Create: `test/features/export/domain/markdown_portfolio_exporter_test.dart`

**Interfaces:**
- Relative return formula: `(1 + portfolioReturn) / (1 + ayarReturn) - 1`.
- Export contains no authentication/session fields.

- [ ] Test relative return including zero denominator guard.
- [ ] Test Markdown content and secret-field absence.
- [ ] Implement file creation in app documents directory and copy-to-clipboard path in UI.

### Task 8: App shell, dependency injection and CI hardening

**Files:**
- Modify: `lib/src/app/app.dart`
- Create: `lib/src/app/app_shell.dart`
- Modify: `lib/src/shared/di/network_module.dart`
- Modify: `pubspec.yaml`
- Modify: `.github/workflows/flutter-ci.yml`
- Modify: `README.md`
- Modify: `VERIFICATION.md`
- Create: `lib/src/features/sharing/**`
- Create: `test/features/sharing/**`

**Interfaces:**
- Bottom navigation: پرتفوی، بازار، دیده‌بان، تنظیمات.
- Unauthenticated portfolio/watchlist routes open Mofid login.

- [ ] Wire all Cubits/use cases/repositories through injectable.
- [ ] Add generated Android bootstrap permissions for internet and cleartext=true because the LAN share endpoint is HTTP.
- [ ] Ensure CI runs codegen, formatting, analyze, tests and debug APK build.
- [ ] Record that device login/biometric and GitHub CI build are not locally verified in this environment.

## Explicitly Unsupported by Current Sources

- Execution-level historical trade allocation and exact sub-portfolio historical P&L: the supplied order report is cumulative order state, not execution records.
- Internet-wide sharing: the implemented mode is direct LAN HTTP only; remote access outside the LAN still needs a relay/backend/VPN/port-forward.
- Cryptographically biometric-gated credential decryption: no native keystore implementation is included; only session token secure storage is used.


### Task 9: Backend-free LAN portfolio sharing

**Files:**
- Create: `lib/src/features/sharing/data/share_credentials.dart`
- Create: `lib/src/features/sharing/data/share_basic_auth.dart`
- Create: `lib/src/features/sharing/data/repository/lan_portfolio_sharing_repository_impl.dart`
- Create: `lib/src/features/sharing/data/models/shared_portfolio_bundle_model.dart`
- Create: `lib/src/features/sharing/domain/entities/share_server_info.dart`
- Create: `lib/src/features/sharing/domain/entities/shared_portfolio_bundle.dart`
- Create: `lib/src/features/sharing/domain/repository/portfolio_sharing_repository.dart`
- Create: `lib/src/features/sharing/presentation/manager/sharing_cubit.dart`
- Create: `lib/src/features/sharing/presentation/pages/sharing_page.dart`
- Create: `lib/src/features/sharing/presentation/pages/shared_portfolio_page.dart`
- Test: `test/features/sharing/**`

**Interfaces:**
- Owner serves `GET /portfolio` on port `8787`.
- Basic Auth credentials are intentionally source-visible: `viewer / portfolio123`.
- Client connects with owner LAN address and renders a read-only snapshot.

- [ ] Test Basic Auth acceptance/rejection and snapshot JSON round-trip.
- [ ] Start the local HTTP server only after a valid Mofid snapshot can be published.
- [ ] Serve only read-only portfolio data and never expose Mofid token/password.
- [ ] Add viewer connection UI and read-only shared portfolio page.
- [ ] Verify on two Android devices on the same Wi-Fi.
