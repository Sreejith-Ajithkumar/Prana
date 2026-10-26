using System.Text;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Prana.Api.Data;
using Prana.Api.Import;
using Xunit;

namespace Prana.Api.Tests;

public sealed class UsdaFoundationImporterTests
{
    [Fact]
    public async Task DryRun_ValidatesCsv_WithoutCreatingDatabaseRows()
    {
        using var fixture = new Fixture();
        fixture.WriteFood("101", "Test apple");
        fixture.WriteNutrients("101", specificEnergy: "52", generalEnergy: "55", protein: "0.3", fat: "0.2", carbs: "14");

        Assert.Equal(0, await UsdaFoundationImporter.RunAsync(fixture.Db, fixture.Directory, dryRun: true));
        Assert.Empty(await fixture.Db.DataSources.ToListAsync());
        Assert.Empty(await fixture.Db.Foods.ToListAsync());
        Assert.Empty(await fixture.Db.FoodServings.ToListAsync());
    }

    [Fact]
    public async Task Import_UsesSpecificAtwaterEnergyAndCorrectMacrosPer100Grams()
    {
        using var fixture = new Fixture();
        fixture.WriteFood("101", "Test apple");
        fixture.WriteNutrients("101", specificEnergy: "52", generalEnergy: "55", protein: "0.3", fat: "0.2", carbs: "14");

        Assert.Equal(0, await UsdaFoundationImporter.RunAsync(fixture.Db, fixture.Directory, dryRun: false));

        var food = await fixture.Db.Foods.SingleAsync();
        var serving = await fixture.Db.FoodServings.SingleAsync();
        Assert.Equal("101", food.SourceRecordId);
        Assert.Equal("Test apple", food.Name);
        Assert.Equal("100 g", serving.Description);
        Assert.Equal(100m, serving.Quantity);
        Assert.Equal(100m, serving.GramWeight);
        Assert.Equal(52m, serving.CaloriesKcal);
        Assert.Equal(0.3m, serving.ProteinGrams);
        Assert.Equal(0.2m, serving.FatGrams);
        Assert.Equal(14m, serving.CarbohydrateGrams);
    }

    [Fact]
    public async Task Import_SkipsIncompleteOrNegativeNutrientRecords()
    {
        using var fixture = new Fixture();
        fixture.WriteFoods(("101", "Complete food"), ("102", "No fat"), ("103", "Negative protein"));
        fixture.WriteNutrientRows(
            ("101", "2047", "90"), ("101", "1003", "2"), ("101", "1004", "3"), ("101", "1005", "12"),
            ("102", "2047", "90"), ("102", "1003", "2"), ("102", "1005", "12"),
            ("103", "2047", "90"), ("103", "1003", "-2"), ("103", "1004", "3"), ("103", "1005", "12"));

        Assert.Equal(0, await UsdaFoundationImporter.RunAsync(fixture.Db, fixture.Directory, dryRun: false));
        var food = await fixture.Db.Foods.SingleAsync();
        Assert.Equal("101", food.SourceRecordId);
        Assert.Equal(90m, (await fixture.Db.FoodServings.SingleAsync()).CaloriesKcal);
    }

    [Fact]
    public async Task RepeatedImport_DoesNotDuplicateFoodsOrServings()
    {
        using var fixture = new Fixture();
        fixture.WriteFood("101", "Test apple");
        fixture.WriteNutrients("101", "52", "55", "0.3", "0.2", "14");

        Assert.Equal(0, await UsdaFoundationImporter.RunAsync(fixture.Db, fixture.Directory, dryRun: false));
        Assert.Equal(0, await UsdaFoundationImporter.RunAsync(fixture.Db, fixture.Directory, dryRun: false));

        Assert.Equal(1, await fixture.Db.DataSources.CountAsync());
        Assert.Equal(1, await fixture.Db.Foods.CountAsync());
        Assert.Equal(1, await fixture.Db.FoodServings.CountAsync());
    }

    [Fact]
    public async Task ConflictingNutrientMeasurements_FailBeforeWriting()
    {
        using var fixture = new Fixture();
        fixture.WriteFood("101", "Test apple");
        fixture.WriteNutrientRows(
            ("101", "2048", "52"), ("101", "2048", "60"),
            ("101", "1003", "0.3"), ("101", "1004", "0.2"), ("101", "1005", "14"));

        await Assert.ThrowsAsync<InvalidDataException>(() =>
            UsdaFoundationImporter.RunAsync(fixture.Db, fixture.Directory, dryRun: false));
        Assert.Empty(await fixture.Db.DataSources.ToListAsync());
        Assert.Empty(await fixture.Db.Foods.ToListAsync());
    }

    private sealed class Fixture : IDisposable
    {
        private readonly SqliteConnection _connection;
        public string Directory { get; } = Path.Combine(Path.GetTempPath(), "prana-usda-tests-" + Guid.NewGuid().ToString("N"));
        public PranaFoodDbContext Db { get; }

        public Fixture()
        {
            System.IO.Directory.CreateDirectory(Directory);
            _connection = new SqliteConnection("Data Source=:memory:");
            _connection.Open();
            var options = new DbContextOptionsBuilder<PranaFoodDbContext>()
                .UseSqlite(_connection)
                .Options;
            Db = new PranaFoodDbContext(options);
            Db.Database.EnsureCreated();
            WriteCsv("food.csv", "fdc_id,data_type,description,food_category_id,publication_date");
            WriteCsv("food_nutrient.csv", "id,fdc_id,nutrient_id,amount,data_points,derivation_id,min,max,median,footnote,min_year_acquired");
            WriteCsv("nutrient.csv", "id,name,unit_name,nutrient_nbr,rank",
                "1003,Protein,G,203,1", "1004,Total lipid (fat),G,204,2", "1005,Carbohydrate by difference,G,205,3",
                "2047,Energy Atwater general,KCAL,957,4", "2048,Energy Atwater specific,KCAL,958,5");
        }

        public void WriteFood(string id, string description) => WriteFoods((id, description));

        public void WriteFoods(params (string Id, string Description)[] foods) =>
            WriteCsv("food.csv", "fdc_id,data_type,description,food_category_id,publication_date",
                foods.Select(x => $"{x.Id},foundation_food,{Quote(x.Description)},,2026-04-30").ToArray());

        public void WriteNutrients(string id, string specificEnergy, string generalEnergy, string protein, string fat, string carbs) =>
            WriteNutrientRows((id, "2048", specificEnergy), (id, "2047", generalEnergy),
                (id, "1003", protein), (id, "1004", fat), (id, "1005", carbs));

        public void WriteNutrientRows(params (string Id, string NutrientId, string Amount)[] rows) =>
            WriteCsv("food_nutrient.csv", "id,fdc_id,nutrient_id,amount,data_points,derivation_id,min,max,median,footnote,min_year_acquired",
                rows.Select((x, i) => $"{i + 1},{x.Id},{x.NutrientId},{x.Amount},,,,,,,").ToArray());

        private void WriteCsv(string filename, string header, params string[] rows) =>
            File.WriteAllText(Path.Combine(Directory, filename),
                string.Join("\n", new[] { header }.Concat(rows)) + "\n", new UTF8Encoding(false));

        private static string Quote(string s) => "\"" + s.Replace("\"", "\"\"") + "\"";

        public void Dispose()
        {
            Db.Dispose();
            _connection.Dispose();
            System.IO.Directory.Delete(Directory, recursive: true);
        }
    }
}
