# USDA Foundation Foods — Sprint 8F.3B.3

Local input: April 30, 2026 FoodData Central Foundation Foods CSV. Downloaded CSV is excluded from Git at `/data/imports/`.

## Pre-import validation

Reported from local CSV inspection:
- 88,990 records in `food.csv` across all data types
- 469 records where `data_type=foundation_food`
- 346 of the 469 have a present energy ID 2047/2048 plus IDs 1003/1004/1005
- Energy 2047 = Atwater General Factors (KCAL), 2048 = Atwater Specific Factors (KCAL)
- 1003 protein (G), 1004 total lipid/fat (G), 1005 carbohydrate by difference (G)

Presence does not guarantee a valid import: numeric validation and duplicate-value checks run separately.

## Data model

One `DataSources` row with code `usda-fdc-foundation`; `Foods.SourceRecordId` contains the string FDC ID, with unique `(DataSourceId, SourceRecordId)`. `FoodServings` contains a standard `100 g` default serving with macros and calories. Source URL and CC0 designation retained. No wholesale schema changes.

## Operation / safety

Stop the API before building. Run dry-run before writes; back up local database; use `dotnet run -- --import-usda-foundation <CSV-directory> [--dry-run]`. After import, verify count and source code in SSMS. Rerunning skips existing foods rather than duplicating them. Do not expose Developer Edition SQL Server publicly.

## Outstanding

- Add automated unit and database integration tests with synthetic CSV fixtures.
- Add a migration that can store complete nutrients/metadata and import-version tracking.
- Implement USDA record updates on subsequent release ingestion.
- Build read-only API food search and pagination; include attribution in app UI.
- Review and update existing `docs/DATABASE.md`, `docs/API.md`, and `docs/architecture/ARCHITECTURE.md` without clobbering existing content.


## Verified import results — October 25, 2026

Dataset: USDA FoodData Central Foundation Foods, April 30, 2026 CSV release.

- Foundation Food records: 469
- Records with required nutrient fields present: 346
- Records accepted by importer validation: 336
- Invalid nutrient rows encountered: 10
- Foods imported into SQL Server: 336
- Standard 100 g servings created: 336
- Duplicate source records: 0
- Foods without servings: 0
- Invalid servings: 0
- Second import: 0 new foods, 336 existing foods skipped

The 10 invalid nutrient rows do not necessarily represent 10 rejected foods.

### Verified PowerShell commands

```powershell
cd "D:\Development\Projects\Prana\apps\api\Prana.Api"

$env:ASPNETCORE_ENVIRONMENT = "Development"
$env:DOTNET_ENVIRONMENT = "Development"

$csv = "D:\Development\Projects\Prana\data\imports\usda\foundation\FoodData_Central_foundation_food_csv_2026-04-30"

dotnet run --no-launch-profile -- --import-usda-foundation "$csv" --dry-run
```

After validating the dry-run and backing up the database:

```powershell
dotnet run --no-launch-profile -- --import-usda-foundation "$csv"
```

### Testing status

Manual import validation and repeat-import verification passed.

Automated importer-specific unit and integration tests remain outstanding. The initial xUnit project currently contains only its template test.

## Automated importer tests

The USDA Foundation Foods importer has five automated xUnit tests using synthetic CSV fixtures and an isolated in-memory SQLite database.

Test coverage includes:

- Dry-run validation without database writes.
- Correct calorie and macronutrient mapping.
- Rejection of incomplete and negative nutrient values.
- Repeat-import duplicate prevention.
- Conflicting nutrient measurement rejection.

Run from the repository root:

```powershell
dotnet test tests/Prana.Api.Tests/Prana.Api.Tests.csproj
```

**Verified baseline:** 5 importer tests passing, 0 failures.

The tests do not connect to the development `PranaFood` SQL Server database. The existing 336 imported foods remain unchanged.
