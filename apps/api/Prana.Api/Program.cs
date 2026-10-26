
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

// Health checks
builder.Services.AddHealthChecks()
    .AddDbContextCheck<PranaFoodDbContext>();

var app = builder.Build();

// USDA Foundation Foods importer command
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

    await using var scope = app.Services.CreateAsyncScope();

    var db = scope.ServiceProvider
        .GetRequiredService<PranaFoodDbContext>();

    try
    {
        Environment.ExitCode =
            await UsdaFoundationImporter.RunAsync(
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

// Reject unrecognized importer arguments instead of starting the API.
if (args.Any(x => x.StartsWith("--import-", StringComparison.Ordinal)))
{
    Console.Error.WriteLine("Unknown import command.");
    Environment.ExitCode = 1;
    return;
}

// Root endpoint
app.MapGet("/", () => Results.Ok(new
{
    name = "Prana Food API",
    status = "running",
    version = "0.1.0"
}));

// Database health endpoint
app.MapHealthChecks("/health");

// Start normal HTTP server
app.Run();
