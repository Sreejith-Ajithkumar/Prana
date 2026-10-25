namespace Prana.Api.Models;

public sealed class Brand
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public required string Name { get; set; }
    public ICollection<Food> Foods { get; set; } = new List<Food>();
}
