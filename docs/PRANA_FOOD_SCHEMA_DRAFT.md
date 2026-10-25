# Prana Food Database — Sprint 8F.3B.2 (draft)

This document is an additive draft. Compare it with existing `docs/` files before merging into canonical documentation.

## Architecture

Flutter mobile → ASP.NET Core 8 API → SQL Server 2022 (`PranaFood`). Initial deployment is local development with Windows Authentication. SQL Server Developer Edition must not be used for production workloads.

## Tables

| Table | Purpose |
|---|---|
| `DataSources` | Source identification, license, URL; `Code` unique |
| `Brands` | Product manufacturer / brand name |
| `Foods` | Canonical source-specific food records; `DataSourceId + SourceRecordId` unique |
| `FoodServings` | Per-serving calories, macros, units and optional gram weight |
| `FoodBarcodes` | Barcode-to-food mapping; same barcode may appear for competing source records |

Foods from different sources intentionally remain separate records. Source attribution is mandatory. This initial schema stores only the primary four nutrition values and does not assert full USDA nutrient coverage.

## Integrity

- SQL decimal precision `(18,4)` for nutrition and quantities.
- Check constraint prevents negative nutrient values, quantity ≤0, and nonpositive recorded gram weight.
- `Foods.Name` indexed for basic searches. Later search improvements should use verified SQL Server full-text capabilities and ranking.
- Barcode strings preserve leading zeros; validation belongs in import/API layers.
- Missing macro measurements should **not** automatically be interpreted as zero: importer must filter incomplete source data until nullable nutrient columns / quality flags are designed.
- Do not import Open Food Facts datasets into a combined database until ODbL obligations are explicitly addressed.

## Local migration commands

From `apps/api/Prana.Api`:

```powershell
dotnet build
dotnet ef migrations add AddFoodCatalogSchema
dotnet ef migrations script -o "$env:TEMP\PranaFood_AddFoodCatalogSchema.sql"
dotnet ef database update
```

Review generated SQL before applying migrations. Never drop or overwrite an existing database to resolve a failed migration.

## Pending milestones

- USDA data license / schema mapping and repeatable ETL.
- Search API (`/api/v1/foods/search`) with filtering, pagination and rate limiting.
- CI tests for constraints, migrations and real SQL Server connectivity.
- API authentication, ownership, monitoring and production hosting.
- Database backups and restore tests.
