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
