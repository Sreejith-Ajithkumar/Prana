
using Microsoft.EntityFrameworkCore;
using Prana.Api.Data;

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

// Root endpoint
app.MapGet("/", () => Results.Ok(new
{
    name = "Prana Food API",
    status = "running",
    version = "0.1.0"
}));

// Database health endpoint
app.MapHealthChecks("/health");

app.Run();
