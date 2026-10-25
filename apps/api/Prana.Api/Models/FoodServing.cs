namespace Prana.Api.Models;

public sealed class FoodServing
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid FoodId { get; set; }
    public Food Food { get; set; } = null!;
    public required string Description { get; set; }
    public decimal Quantity { get; set; } = 1m;
    public required string Unit { get; set; }
    public decimal? GramWeight { get; set; }
    public decimal CaloriesKcal { get; set; }
    public decimal ProteinGrams { get; set; }
    public decimal CarbohydrateGrams { get; set; }
    public decimal FatGrams { get; set; }
    public bool IsDefault { get; set; }
}
