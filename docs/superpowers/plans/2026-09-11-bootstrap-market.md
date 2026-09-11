# Portfolio Bootstrap + TGJU Market Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create an upload-ready Flutter repository foundation and one working vertical slice that reads the TGJU market snapshot and presents verified values safely.

**Architecture:** Follow the approved feature-first Clean structure with data/domain/presentation boundaries, Cubit state management, `Future<Either<Failure, T>>`, `get_it` + `injectable`, and a generic Dio-based `RemoteDataSource`. The TGJU repository owns the endpoint and response mapping. Portfolio domain primitives are added without pretending Mofid authentication/history is already implemented.

**Tech Stack:** Flutter stable, Dart >=3.12, flutter_bloc, dartz, get_it, injectable, Dio, equatable.

**Spec:** `docs/superpowers/specs/2026-09-11-portfolio-design.md`

## Global Constraints

- Persian RTL UI.
- No credentials, cookies, session tokens, invite codes, or captured private financial data in source control.
- TGJU snapshot endpoint comes from the supplied HAR; `coin_blubber` is coin bubble, not 18k-gold bubble.
- Money shown as toman only after an explicit source-unit mapping.
- Mofid write/order APIs are out of scope for this bootstrap.
- Android platform files may be generated with `flutter create` because Flutter SDK is unavailable in the artifact-generation environment.

---

### Task 1: Market parsing contract

**Files:**
- Test: `test/features/market/data/tgju_market_mapper_test.dart`
- Create: `lib/src/features/market/data/models/tgju_market_item_model.dart`
- Create: `lib/src/features/market/data/mapper/tgju_market_mapper.dart`
- Create: `lib/src/features/market/domain/entities/market_price.dart`

**Interfaces:**
- Consumes: TGJU `current.<slug>` maps from the supplied HAR.
- Produces: `MarketPrice TgjuMarketMapper.map(String code, Map<String, dynamic> json)`.

- [ ] Write tests for comma-number parsing, rial-to-toman conversion, timestamp preservation, and missing values.
- [ ] Implement the smallest mapper/model/entity satisfying those tests.

### Task 2: TGJU repository + network boundary

**Files:**
- Test: `test/features/market/data/tgju_market_repository_test.dart`
- Create: `lib/src/shared/error/failure.dart`
- Create: `lib/src/shared/network/remote_data_source.dart`
- Create: `lib/src/shared/network/dio_remote_data_source.dart`
- Create: `lib/src/features/market/domain/repository/market_repository.dart`
- Create: `lib/src/features/market/domain/use_case/get_market_prices.dart`
- Create: `lib/src/features/market/data/repository/tgju_market_repository_impl.dart`

**Interfaces:**
- Produces: `Future<Either<Failure, List<MarketPrice>>> getPrices()`.
- Endpoint: `GET https://call4.tgju.org/ajax.json?rev=<60 chars>`.

- [ ] Write repository contract tests around a fake `RemoteDataSource`.
- [ ] Implement network abstraction, endpoint request, error mapping, and selected slugs only.

### Task 3: Presentation + dependency injection

**Files:**
- Create: `lib/main.dart`
- Create: `lib/src/app/app.dart`
- Create: `lib/src/shared/di/di_config.dart`
- Create: `lib/src/shared/di/network_module.dart`
- Create: `lib/src/features/market/presentation/manager/market_cubit.dart`
- Create: `lib/src/features/market/presentation/manager/market_state.dart`
- Create: `lib/src/features/market/presentation/pages/market_overview_page.dart`
- Create: `lib/src/features/market/presentation/widgets/market_price_card.dart`

**Interfaces:**
- Consumes: `GetMarketPrices`.
- Produces: RTL Material app with loading/success/error/refresh states.

- [ ] Wire DI and Cubit.
- [ ] Render four requested market cards plus a clearly labeled coin-bubble card.
- [ ] Never label `coin_blubber` as gold bubble.

### Task 4: Portfolio domain seed + repository delivery tooling

**Files:**
- Test: `test/features/portfolio/domain/portfolio_holding_test.dart`
- Create: `lib/src/features/portfolio/domain/entities/portfolio_holding.dart`
- Create: `README.md`
- Create: `tool/bootstrap.sh`
- Create: `.github/workflows/flutter-ci.yml`

**Interfaces:**
- Produces: immutable holding/value primitive and reproducible setup/build workflow.

- [ ] Add a pure holding-value test and implementation.
- [ ] Add bootstrap that generates Android files when absent, gets packages, and runs injectable codegen.
- [ ] Add CI for format/analyze/test/debug APK upload.
