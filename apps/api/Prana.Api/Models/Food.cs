namespace Prana.Api.Models;

public sealed class Food
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public required string Name { get; set; }
    public string? Description { get; set; }
    public Guid? BrandId { get; set; }
    public Brand? Brand { get; set; }
    public required string SourceRecordId { get; set; }
    public Guid DataSourceId { get; set; }
    public DataSource DataSource { get; set; } = null!;
    public string? RegionCode { get; set; }
    public string? LanguageCode { get; set; }
    public bool IsPublished { get; set; } = true;
    public DateTimeOffset CreatedAtUtc { get; set; } = DateTimeOffset.UtcNow;
    public ICollection<FoodServing> Servings { get; set; } = new List<FoodServing>();
    public ICollection<FoodBarcode> Barcodes { get; set; } = new List<FoodBarcode>();
}
