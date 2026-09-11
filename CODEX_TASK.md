# Codex handoff — Portfolio Android MVP

Repository را روی branch جدا از `main` باز کن و ابتدا `docs/superpowers/specs/2026-09-11-portfolio-design.md` ، `docs/superpowers/plans/2026-09-11-mobile-mvp.md` و `docs/superpowers/plans/2026-09-11-multi-account-ipasargad.md` را بخوان.

هدف این handoff فقط verification و اصلاح compile/runtime پروژهٔ موجود است؛ قراردادهای API را با endpoint حدسی جایگزین نکن و هیچ secret یا HAR خامی commit نکن.

مراحل مورد انتظار:

1. `./tool/bootstrap.sh`
2. `dart format lib test`
3. `flutter analyze --no-fatal-infos`
4. `flutter test`
5. `flutter build apk --debug`
6. هر خطای compile/test را با کمترین تغییر و بدون شکستن معماری `data/domain/presentation` اصلاح کن.
7. در پایان، diff را برای secretها (`Bearer`, token واقعی، password، cookie، HAR) بررسی کن.
8. نتیجهٔ واقعی پنج فرمان بالا و مسیر APK را در PR بنویس. ورود مفید باید بدون browser UI باشد: `GET authorize -> Login HTML/anti-forgery -> POST /Login -> authorize callback -> POST /connect/token`. اگر ورود واقعی مفید روی محیط cloud قابل آزمون نیست، آن را صریحاً unverified نگه دار.
9. بررسی کن `local_auth` روی Android با `FlutterFragmentActivity`، `USE_BIOMETRIC` و minSdk 24 bootstrap می‌شود و startup gate در صورت credential ذخیره‌شده اثر انگشت می‌خواهد.

محدودیت‌های محصول را دور نزن: execution-level trade history هنوز قرارداد کافی ندارد، بنابراین سود تاریخی واقعی را جعل نکن. اشتراک‌گذاری این نسخه عمداً backend ندارد و با HTTP server محلی روی پورت 8787 و Basic Auth ثابت `viewer / portfolio123` پیاده شده است؛ فقط روی شبکهٔ محلی verification شود و آن را به‌عنوان اشتراک اینترنتی معرفی نکن.


## Multi-account checks

- مسیر افزودن حساب آی‌پاسارگاد را compile/test کن؛ fixtureهای تست فقط دادهٔ ساختگی دارند.
- مطمئن شو `MofidPortfolioSource` و `IPasargadPortfolioSource` فقط از طریق `MultiAccountPortfolioRepositoryImpl` به `PortfolioRepository` متصل می‌شوند.
- اگر دو holding با ISIN یکسان ولی accountId متفاوت باشند، UI و allocation آن‌ها را merge نکن.
- آی‌پاسارگاد: کپچا از `identity.ipasargad.ir/captcha/getCaptcha`، Login از `/Account/Login` و APIهای پرتفوی از `clientapi.ipasargad.ir` هستند. token واقعی هرگز log/commit نشود.
- واحد iPasargad را روی دستگاه با UI رسمی تطبیق بده؛ adapter فعلی بر اساس شواهد HAR یک بار ریال→تومان تبدیل می‌کند.

- در تست واقعی آی‌پاسارگاد بررسی کن آیا cookie مرورگری `cookiesession1` برای Login مستقیم لازم است؛ HAR منبع ایجاد آن را ثبت نکرده و نباید مقدار ساختگی hardcode شود.
