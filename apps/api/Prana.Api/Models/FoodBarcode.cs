namespace Prana.Api.Models;

public sealed class FoodBarcode
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid FoodId { get; set; }
    public Food Food { get; set; } = null!;
    public required string Value { get; set; }
    public required string Format { get; set; }
}
