# Flutter production build (ODA Black Car)

## Where credentials live

| Credential | Backend `ODA-TRANSPORTATION/.env` | Flutter app |
|------------|-------------------------------------|-------------|
| `SQUARE_ACCESS_TOKEN` | Yes | **Never** |
| `SQUARE_APPLICATION_ID` | Yes | Fallback only (`square_credentials.dart`); runtime from API |
| `SQUARE_LOCATION_ID` | Yes | Fallback only; runtime from API |
| `SQUARE_PRODUCTION_WEBHOOK_SIGNATURE_KEY` | Yes | **Never** |
| `SQUARE_PRODUCTION_WEBHOOK_NOTIFICATION_URL` | Yes | **Never** (server verifies webhooks) |
| API | N/A | `AppConfig.productionApiBaseUrl` |

At runtime the app calls:

`GET https://api.odatransportation.com/api/v1/payments/square/config`

and uses `applicationId` + `locationId` from that response (must match backend `SQUARE_ENV=production`).

## Release build (Play Store / App Store)

```bash
cd oda-black-car-service

flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.odatransportation.com/api/v1 \
  --dart-define=SQUARE_ENV=production

# iOS
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://api.odatransportation.com/api/v1 \
  --dart-define=SQUARE_ENV=production
```

Release builds also default `API_BASE_URL` to production when `API_BASE_URL` is omitted (`kReleaseMode`).

## Debug against production API

```bash
flutter run \
  --dart-define=PRODUCTION_API=true \
  --dart-define=SQUARE_ENV=production
```

## Debug against local backend

```bash
flutter run --dart-define=API_BASE_URL=http://<LAN_IP>:5100/api/v1
# Backend .env: SQUARE_ENV=sandbox
```

## Production server checklist

1. `ODA-TRANSPORTATION/.env` on `api.odatransportation.com` has `SQUARE_ENV=production` and all `SQUARE_PRODUCTION_*` / legacy vars filled.
2. `GET /api/v1/payments/square/config` returns `environment: "production"` and your `sq0idp-...` application id.
3. Square Dashboard → Mobile Payments SDK → production signatures for Android/iOS match your store builds.
4. Webhook subscription URL matches `SQUARE_PRODUCTION_WEBHOOK_NOTIFICATION_URL`.
