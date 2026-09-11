# Multi-account iPasargad Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a post-login “افزودن اکانت” flow for iPasargad and aggregate Mofid + iPasargad holdings in one portfolio while keeping same-symbol holdings as separate cards per account/provider.

**Architecture:** Keep Mofid as the primary authenticated account and introduce a broker-account registry for additional providers. A multi-account portfolio repository aggregates provider snapshots; every holding is identified by `accountId + instrumentId`, so identical symbols from Mofid and iPasargad never collide in UI or local allocation storage. iPasargad authentication uses the observed captcha/login flow and the returned token as the `otauth-FU` cookie.

**Tech Stack:** Flutter, Dart, Cubit, dartz, get_it/injectable, Dio, SharedPreferences, FlutterSecureStorage.

**Spec:** `docs/superpowers/specs/2026-09-11-portfolio-design.md`

## Global Constraints

- Android Flutter app, Persian RTL UI.
- Domain must not depend on Flutter, Dio, or response models.
- `Future<Either<Failure, T>>` for repository operations.
- Cubit for presentation state.
- Mofid and iPasargad secrets/tokens must not be committed or exported.
- Raw HAR files must not be committed.
- Same instrument in different accounts must render as separate cards.
- iPasargad is the only additional provider in this phase.
- Sharing remains LAN-only HTTP snapshot with fixed Basic Auth credentials in source and no backend.

---

### Task 1: Account identity and allocation keys

**Files:**
- Create: `lib/src/features/accounts/domain/entities/broker_provider.dart`
- Create: `lib/src/features/accounts/domain/entities/investment_account.dart`
- Modify: `lib/src/features/portfolio/domain/entities/portfolio_holding.dart`
- Modify: `lib/src/features/portfolio/domain/entities/holding_allocation.dart`
- Modify: `lib/src/features/portfolio/domain/use_case/save_symbol_allocations.dart`
- Modify: `lib/src/features/portfolio/presentation/manager/portfolio_state.dart`
- Test: `test/features/portfolio/domain/portfolio_holding_test.dart`
- Test: `test/features/portfolio/domain/save_symbol_allocations_test.dart`

**Interfaces:**
- Produces: `PortfolioHolding.holdingKey`, `HoldingAllocation.holdingKey`.
- Invariant: `holdingKey = "$accountId::$symbolIsin"`.

- [ ] Write tests that prove two holdings with the same ISIN but different account IDs have different keys and allocations do not collide.
- [ ] Implement the minimum account/provider fields and holding-key migration fallback.
- [ ] Update allocation lookups to use holding key.

### Task 2: Additional account registry and iPasargad session storage

**Files:**
- Create: `lib/src/features/accounts/domain/repository/broker_account_repository.dart`
- Create: `lib/src/features/accounts/data/repository/preferences_broker_account_repository_impl.dart`
- Create: `lib/src/features/accounts/data/security/ipasargad_session_store.dart`
- Test: `test/features/accounts/data/preferences_broker_account_repository_test.dart`

**Interfaces:**
- Produces: persistent `InvestmentAccount` list and per-account iPasargad session token/expiry.

- [ ] Write persistence tests.
- [ ] Implement JSON storage in SharedPreferences and token storage in FlutterSecureStorage.

### Task 3: iPasargad authentication

**Files:**
- Create: `lib/src/features/accounts/domain/entities/ipasargad_captcha.dart`
- Create: `lib/src/features/accounts/domain/repository/ipasargad_authentication_repository.dart`
- Create: `lib/src/features/accounts/data/repository/ipasargad_authentication_repository_impl.dart`
- Create: `lib/src/features/accounts/presentation/manager/ipasargad_login_cubit.dart`
- Create: `lib/src/features/accounts/presentation/manager/ipasargad_login_state.dart`
- Create: `lib/src/features/accounts/presentation/pages/ipasargad_login_page.dart`
- Test: `test/features/accounts/data/ipasargad_authentication_repository_test.dart`

**Interfaces:**
- `GET https://identity.ipasargad.ir/captcha/getCaptcha`
- `POST https://identity.ipasargad.ir/Account/Login`
- Login request: `{loginName,password,captcha:{hash,salt,value}}`.
- Login token is persisted and later sent as cookie `otauth-FU=<token>`.

- [ ] Write captcha/login mapping tests using fake HTTP responses.
- [ ] Implement repository and Cubit.
- [ ] Implement captcha image + login form.

### Task 4: iPasargad portfolio source and multi-account aggregation

**Files:**
- Create: `lib/src/features/portfolio/data/repository/ipasargad_portfolio_repository_impl.dart`
- Create: `lib/src/features/portfolio/data/repository/multi_account_portfolio_repository_impl.dart`
- Modify: `lib/src/features/portfolio/data/repository/mofid_portfolio_repository_impl.dart`
- Modify: `lib/src/features/portfolio/domain/entities/account_snapshot.dart`
- Test: `test/features/portfolio/data/ipasargad_portfolio_repository_test.dart`
- Test: `test/features/portfolio/data/multi_account_portfolio_repository_test.dart`

**Interfaces:**
- iPasargad composition: `POST /api/requestdailyposition/getcustomerrequestcomposition`.
- iPasargad profit/loss: `POST /api/requestdailyposition/getprofitorloss`.
- iPasargad evidence: `GET /api/request/getcustomerevidences`.
- Multi-account repository continues to implement existing `PortfolioRepository`.

- [ ] Write tests for Riton mapping and rial→toman conversion.
- [ ] Write aggregation test proving Mofid Riton and iPasargad Riton remain two cards.
- [ ] Implement iPasargad source and aggregator with per-account warnings instead of failing the primary Mofid snapshot.

### Task 5: Account management UI and source labels

**Files:**
- Create: `lib/src/features/accounts/presentation/manager/broker_accounts_cubit.dart`
- Create: `lib/src/features/accounts/presentation/manager/broker_accounts_state.dart`
- Create: `lib/src/features/accounts/presentation/pages/accounts_page.dart`
- Create: `lib/src/features/accounts/presentation/pages/add_account_page.dart`
- Modify: `lib/src/app/app.dart`
- Modify: `lib/src/features/settings/presentation/pages/settings_page.dart`
- Modify: `lib/src/features/portfolio/presentation/widgets/holding_card.dart`
- Modify: `lib/src/features/portfolio/presentation/pages/portfolio_page.dart`

**Interfaces:**
- Settings exposes “افزودن اکانت”.
- Phase-one provider selector contains only “آی‌پاسارگاد”.
- Holding card always displays account/provider source.

- [ ] Add account list + remove/relogin actions.
- [ ] Add iPasargad login route.
- [ ] Render provider/account badge on each holding card.
- [ ] Reload portfolio after successful add/remove.

### Task 6: Sharing/export compatibility and spec update

**Files:**
- Modify: `lib/src/features/sharing/data/models/shared_portfolio_bundle_model.dart`
- Modify: `lib/src/features/sharing/domain/entities/shared_portfolio_bundle.dart`
- Modify: `lib/src/features/export/domain/markdown_portfolio_exporter.dart`
- Modify: `docs/superpowers/specs/2026-09-11-portfolio-design.md`
- Modify: `README.md`
- Modify: `VERIFICATION.md`

**Interfaces:**
- Shared snapshot serializes `accountId`, `accountLabel`, provider and `holdingKey`.
- Markdown export shows account source per row.

- [ ] Update serialization and allocation lookup.
- [ ] Add iPasargad HAR-derived API appendix and multi-account behavior to spec.
- [ ] Run available static checks and record that Flutter build/test still require an environment with Flutter SDK.
