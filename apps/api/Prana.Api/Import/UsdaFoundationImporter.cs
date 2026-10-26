using System.Globalization;
using Microsoft.EntityFrameworkCore;
using Microsoft.VisualBasic.FileIO;
using Prana.Api.Data;
using Prana.Api.Models;

namespace Prana.Api.Import;

/// <summary>Imports USDA Foundation Foods only. Never writes during --dry-run.</summary>
public static class UsdaFoundationImporter
{
    private const string SourceCode = "usda-fdc-foundation";
    private const string SourceUrl = "https://fdc.nal.usda.gov/";
    private static readonly string[] NeededNutrients = ["1003", "1004", "1005", "2047", "2048"];

    public static async Task<int> RunAsync(
        PranaFoodDbContext db, string directory, bool dryRun, CancellationToken ct = default)
    {
        foreach (var name in new[] { "food.csv", "food_nutrient.csv", "nutrient.csv" })
        {
            if (!File.Exists(Path.Combine(directory, name)))
                throw new FileNotFoundException($"Missing required USDA file: {name}");
        }

        // Guard against schema changes and mistakenly imported nutrient IDs.
        var nutrients = CsvRows(Path.Combine(directory, "nutrient.csv"))
            .Where(x => NeededNutrients.Contains(x.GetValueOrDefault("id")))
            .ToDictionary(x => x["id"], x => x, StringComparer.Ordinal);
        foreach (var id in NeededNutrients)
        {
            if (!nutrients.ContainsKey(id))
                throw new InvalidDataException($"Missing USDA nutrient ID {id}.");
        }
        foreach (var id in new[] { "2047", "2048" })
        {
            if (!string.Equals(nutrients[id].GetValueOrDefault("unit_name"), "KCAL", StringComparison.OrdinalIgnoreCase))
                throw new InvalidDataException($"Unexpected USDA energy unit for {id}.");
        }
        foreach (var id in new[] { "1003", "1004", "1005" })
        {
            if (!string.Equals(nutrients[id].GetValueOrDefault("unit_name"), "G", StringComparison.OrdinalIgnoreCase))
                throw new InvalidDataException($"Unexpected USDA macro unit for {id}.");
        }

        var foundation = CsvRows(Path.Combine(directory, "food.csv"))
            .Where(row => row.GetValueOrDefault("data_type") == "foundation_food")
            .Select(row => (Id: row["fdc_id"].Trim(), Name: row["description"].Trim()))
            .Where(x => x.Id.Length > 0 && x.Name.Length is > 0 and <= 350)
            .DistinctBy(x => x.Id)
            .OrderBy(x => x.Id, StringComparer.Ordinal)
            .ToList();
        var ids = foundation.Select(x => x.Id).ToHashSet(StringComparer.Ordinal);
        var values = new Dictionary<string, Dictionary<string, decimal>>(StringComparer.Ordinal);
        var badAmounts = 0;
        foreach (var row in CsvRows(Path.Combine(directory, "food_nutrient.csv")))
        {
            var id = row.GetValueOrDefault("fdc_id", "");
            var nutrient = row.GetValueOrDefault("nutrient_id", "");
            if (!ids.Contains(id) || !NeededNutrients.Contains(nutrient)) continue;
            var amountText = row.GetValueOrDefault("amount", "");
            if (!decimal.TryParse(amountText, NumberStyles.Float, CultureInfo.InvariantCulture, out var amount)
                || amount < 0 || amount > 100000m)
            {
                badAmounts++;
                continue;
            }
            if (!values.TryGetValue(id, out var data))
                values[id] = data = new Dictionary<string, decimal>(StringComparer.Ordinal);
            // Fail closed on conflicting duplicate measurements; do not choose an arbitrary row.
            if (data.TryGetValue(nutrient, out var old) && old != amount)
                throw new InvalidDataException($"Conflicting USDA nutrient {nutrient} for FDC {id}.");
            data[nutrient] = amount;
        }

        var ready = new List<(string Id, string Name, decimal Kcal, decimal Protein, decimal Fat, decimal Carbs)>();
        foreach (var food in foundation)
        {
            if (!values.TryGetValue(food.Id, out var n)
                || !n.TryGetValue("1003", out var protein)
                || !n.TryGetValue("1004", out var fat)
                || !n.TryGetValue("1005", out var carbs)) continue;
            if (!n.TryGetValue("2048", out var kcal) && !n.TryGetValue("2047", out kcal)) continue;
            if (new[] { kcal, protein, fat, carbs }.Any(x => x > 10000m)) continue;
            ready.Add((food.Id, food.Name, kcal, protein, fat, carbs));
        }

        Console.WriteLine($"Foundation foods: {foundation.Count}; usable four-field foods: {ready.Count}; invalid nutrient rows: {badAmounts}; dry run: {dryRun}");
        if (dryRun) return 0;

        // Database writes begin only after CSV parsing/validation is complete.
        await using var tx = await db.Database.BeginTransactionAsync(ct);
        var source = await db.DataSources.SingleOrDefaultAsync(x => x.Code == SourceCode, ct);
        if (source is null)
        {
            source = new DataSource
            {
                Code = SourceCode,
                Name = "USDA FoodData Central — Foundation Foods",
                License = "CC0 1.0 (USDA public-domain data)",
                SourceUrl = SourceUrl
            };
            db.DataSources.Add(source);
            await db.SaveChangesAsync(ct);
        }

        var existing = (await db.Foods.AsNoTracking()
                .Where(x => x.DataSourceId == source.Id)
                .Select(x => x.SourceRecordId).ToListAsync(ct))
            .ToHashSet(StringComparer.Ordinal);
        var created = 0;
        foreach (var batch in ready.Where(x => !existing.Contains(x.Id)).Chunk(50))
        {
            foreach (var food in batch)
            {
                var entry = new Food
                {
                    Name = food.Name,
                    SourceRecordId = food.Id,
                    DataSourceId = source.Id,
                    LanguageCode = "en",
                    RegionCode = "US",
                    IsPublished = true
                };
                entry.Servings.Add(new FoodServing
                {
                    Description = "100 g",
                    Quantity = 100m,
                    Unit = "g",
                    GramWeight = 100m,
                    CaloriesKcal = food.Kcal,
                    ProteinGrams = food.Protein,
                    FatGrams = food.Fat,
                    CarbohydrateGrams = food.Carbs,
                    IsDefault = true
                });
                db.Foods.Add(entry);
            }
            await db.SaveChangesAsync(ct);
            created += batch.Length;
            db.ChangeTracker.Clear();
        }
        await tx.CommitAsync(ct);
        Console.WriteLine($"Imported {created}; skipped {ready.Count - created} previously imported foods.");
        return 0;
    }

    private static IEnumerable<Dictionary<string, string>> CsvRows(string path)
    {
        using var parser = new TextFieldParser(path);
        parser.TextFieldType = FieldType.Delimited;
        parser.SetDelimiters(",");
        parser.HasFieldsEnclosedInQuotes = true;
        if (parser.EndOfData) throw new InvalidDataException($"Empty CSV file: {path}");
        var headers = parser.ReadFields() ?? throw new InvalidDataException($"Missing header: {path}");
        if (headers.Length != headers.Distinct(StringComparer.Ordinal).Count())
            throw new InvalidDataException($"Duplicate CSV headers: {path}");
        while (!parser.EndOfData)
        {
            var fields = parser.ReadFields();
            if (fields is null) continue;
            if (fields.Length != headers.Length)
                throw new InvalidDataException($"Incorrect CSV field count in {path}, line {parser.LineNumber}.");
            var row = new Dictionary<string, string>(StringComparer.Ordinal);
            for (var i = 0; i < headers.Length; i++) row[headers[i].TrimStart('\uFEFF')] = fields[i];
            yield return row;
        }
    }
}
