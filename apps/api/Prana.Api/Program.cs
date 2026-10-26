
using Microsoft.EntityFrameworkCore;
using Prana.Api.Data;
using Prana.Api.Import;

var builder = WebApplication.CreateBuilder(args);

// SQL Server connection
builder.Services.AddDbContext<PranaFoodDbContext>(options =>
{
    var connectionString = builder.Configuration
        .GetConnectionString("PranaFood")
        ?? throw new InvalidOperationException(
            "PranaFood connection string is missing.");

    options.UseSqlServer(connectionString);
});

// Database health checks
builder.Services.AddHealthChecks()
    .AddDbContextCheck<PranaFoodDbContext>();

var app = builder.Build();

// --------------------------------------------------
// USDA Foundation Foods importer
// --------------------------------------------------

if (args.Length > 0 && args[0] == "--import-usda-foundation")
{
    if (args.Length < 2 || string.IsNullOrWhiteSpace(args[1]))
    {
        Console.Error.WriteLine(
            "Usage: --import-usda-foundation <csv-directory> [--dry-run]");

        Environment.ExitCode = 1;
        return;
    }

    var csvDirectory = args[1];
    var dryRun = args.Skip(2).Contains("--dry-run");

    if (args.Skip(2).Any(x => x != "--dry-run"))
    {
        Console.Error.WriteLine("Unknown importer option.");
        Environment.ExitCode = 1;
        return;
    }

    try
    {
        await using var scope = app.Services.CreateAsyncScope();

        var db = scope.ServiceProvider
            .GetRequiredService<PranaFoodDbContext>();

        Environment.ExitCode = await UsdaFoundationImporter.RunAsync(
            db,
            csvDirectory,
            dryRun);
    }
    catch (Exception ex)
    {
        Console.Error.WriteLine($"USDA import failed: {ex.Message}");
        Environment.ExitCode = 1;
    }

    return;
}

// Reject unrecognized import commands
if (args.Any(x => x.StartsWith(
    "--import-", StringComparison.Ordinal)))
{
    Console.Error.WriteLine("Unknown import command.");
    Environment.ExitCode = 1;
    return;
}

// --------------------------------------------------
// Root endpoint
// --------------------------------------------------

app.MapGet("/", () => Results.Ok(new
{
    name = "Prana Food API",
    status = "running",
    version = "0.1.0"
}));

// --------------------------------------------------
// Database health endpoint
// --------------------------------------------------

app.MapHealthChecks("/health");

// --------------------------------------------------
// Search foods
// GET /api/v1/foods/search?q=apple&page=1&pageSize=20
// --------------------------------------------------

app.MapGet("/api/v1/foods/search", async (
    string? q,
    int? page,
    int? pageSize,
    PranaFoodDbContext db,
    CancellationToken ct) =>
{
    var query = q?.Trim();

    if (string.IsNullOrWhiteSpace(query) ||
        query.Length < 2 ||
        query.Length > 100)
    {
        return Results.BadRequest(new
        {
            error = "Search must contain 2 to 100 characters."
        });
    }

    var currentPage = page ?? 1;
    var size = pageSize ?? 20;

    if (currentPage < 1 ||
        size < 1 ||
        size > 50 ||
        ((long)currentPage - 1) * size > int.MaxValue)
    {
        return Results.BadRequest(new
        {
            error = "Invalid pagination parameters."
        });
    }

    var foods =
        from food in db.Foods.AsNoTracking()
        join serving in db.FoodServings.AsNoTracking()
            on food.Id equals serving.FoodId
        join source in db.DataSources.AsNoTracking()
            on food.DataSourceId equals source.Id
        where food.IsPublished
            && serving.IsDefault
            && food.Name.Contains(query!)
        select new
        {
            food.Id,
            food.Name,
            food.SourceRecordId,
            Source = source.Name,
            SourceUrl = source.SourceUrl,
            Serving = serving.Description,
            serving.CaloriesKcal,
            serving.ProteinGrams,
            serving.CarbohydrateGrams,
            serving.FatGrams
        };

    var total = await foods.CountAsync(ct);

    var results = await foods
        .OrderBy(x => x.Name)
        .ThenBy(x => x.Id)
        .Skip((currentPage - 1) * size)
        .Take(size)
        .ToListAsync(ct);

    return Results.Ok(new
    {
        query,
        page = currentPage,
        pageSize = size,
        total,
        results
    });
});

// --------------------------------------------------
// Food details by ID
// GET /api/v1/foods/{id}
// --------------------------------------------------

app.MapGet("/api/v1/foods/{id:guid}", async (
    Guid id,
    PranaFoodDbContext db,
    CancellationToken ct) =>
{
    var food = await db.Foods
        .AsNoTracking()
        .Where(f => f.Id == id && f.IsPublished)
        .Select(f => new
        {
            f.Id,
            f.Name,
            f.Description,
            f.SourceRecordId,
            Source = f.DataSource.Name,
            SourceUrl = f.DataSource.SourceUrl,
            Servings = f.Servings
                .OrderByDescending(s => s.IsDefault)
                .ThenBy(s => s.Description)
                .Select(s => new
                {
                    s.Id,
                    s.Description,
                    s.Quantity,
                    s.Unit,
                    s.GramWeight,
                    s.CaloriesKcal,
                    s.ProteinGrams,
                    s.CarbohydrateGrams,
                    s.FatGrams,
                    s.IsDefault
                })
                .ToList()
        })
        .SingleOrDefaultAsync(ct);

    return food is null
        ? Results.NotFound(new { error = "Food not found." })
        : Results.Ok(food);
});

// --------------------------------------------------
// Start HTTP server
// IMPORTANT: This must remain the final statement.
// --------------------------------------------------

app.Run();
