namespace Prana.Api.Models;

public sealed class DataSource
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public required string Code { get; set; }
    public required string Name { get; set; }
    public string? License { get; set; }
    public string? SourceUrl { get; set; }
    public ICollection<Food> Foods { get; set; } = new List<Food>();
}
