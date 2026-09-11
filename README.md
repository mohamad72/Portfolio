# portfolio

اپ Flutter برای مشاهدهٔ پرتفوی سرمایه‌گذاری، تفکیک سبدهای محلی، داده‌های مفید و قیمت‌های بازار TGJU.

## وضعیت فعلی

این بسته «شروع پروژه» است، نه نسخهٔ کامل محصول. در این مرحله:

- معماری feature-first با `data / domain / presentation` ایجاد شده است.
- مدیریت state با Cubit انجام می‌شود.
- قرارداد Repository از `Future<Either<Failure, T>>` استفاده می‌کند.
- DI با `get_it + injectable` آماده است.
- یک vertical slice واقعی برای snapshot قیمت TGJU وجود دارد.
- مدل اولیهٔ `PortfolioHolding` اضافه شده است.
- اتصال ورود/نشست/موجودی مفید هنوز پیاده‌سازی نشده است.
- هیچ رمز، توکن، cookie یا دادهٔ مالی ضبط‌شده داخل repository قرار نگرفته است.

## TGJU

منبع قرارداد، HAR ارائه‌شده در پروژه است. endpoint مشاهده‌شده:

```text
GET https://call4.tgju.org/ajax.json?rev=<60 random chars>
```

کلیدهای انتخاب‌شده:

```text
price_dollar_rl  دلار آزاد
price_eur         یورو آزاد
sekee            سکه امامی
geram18          طلای ۱۸ عیار
coin_blubber     حباب سکه امامی
```

> نکته: در سورس HAR، ریالی بودن دلار و طلای ۱۸ عیار صریحاً تأیید شده است. برای یورو، سکه امامی و حباب سکه، کد فعلی مقدار خام منبع را نشان می‌دهد و تا زمان تأیید قرارداد واحد، آن را به تومان تبدیل نمی‌کند. همچنین `coin_blubber` حباب سکه است و هرگز به‌عنوان حباب طلای ۱۸ عیار نمایش داده نمی‌شود.

## راه‌اندازی محلی

اگر repository هنوز پوشهٔ `android/` ندارد:

```bash
./tool/bootstrap.sh
flutter run
```

اسکریپت bootstrap پوشهٔ Android را با Flutter رسمی می‌سازد، packageها را می‌گیرد و code generation مربوط به injectable را اجرا می‌کند.

## تست و Build

```bash
./tool/bootstrap.sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

GitHub Actions همین مراحل را روی هر push به `main` اجرا می‌کند و APK دیباگ را به‌عنوان artifact نگه می‌دارد.

## ساختار اصلی

```text
lib/src/
  app/
  shared/
    di/
    error/
    network/
  features/
    market/
      data/
      domain/
      presentation/
    portfolio/
      domain/
```

طراحی کامل پروژه در `docs/superpowers/specs/2026-09-11-portfolio-design.md` قرار دارد.
