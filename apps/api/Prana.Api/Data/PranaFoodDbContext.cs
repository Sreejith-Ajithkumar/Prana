using Microsoft.EntityFrameworkCore;
using Prana.Api.Models;

namespace Prana.Api.Data;

public sealed class PranaFoodDbContext : DbContext
{
    public PranaFoodDbContext(DbContextOptions<PranaFoodDbContext> options)
        : base(options) { }

    public DbSet<Food> Foods => Set<Food>();
    public DbSet<FoodServing> FoodServings => Set<FoodServing>();
    public DbSet<FoodBarcode> FoodBarcodes => Set<FoodBarcode>();
    public DbSet<Brand> Brands => Set<Brand>();
    public DbSet<DataSource> DataSources => Set<DataSource>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<DataSource>(e =>
        {
            e.ToTable("DataSources");
            e.HasKey(x => x.Id);
            e.Property(x => x.Code).HasMaxLength(64).IsRequired();
            e.Property(x => x.Name).HasMaxLength(200).IsRequired();
            e.Property(x => x.License).HasMaxLength(200);
            e.Property(x => x.SourceUrl).HasMaxLength(1000);
            e.HasIndex(x => x.Code).IsUnique();
        });

        modelBuilder.Entity<Brand>(e =>
        {
            e.ToTable("Brands");
            e.HasKey(x => x.Id);
            e.Property(x => x.Name).HasMaxLength(250).IsRequired();
            e.HasIndex(x => x.Name);
        });

        modelBuilder.Entity<Food>(e =>
        {
            e.ToTable("Foods");
            e.HasKey(x => x.Id);
            e.Property(x => x.Name).HasMaxLength(350).IsRequired();
            e.Property(x => x.Description).HasMaxLength(2000);
            e.Property(x => x.SourceRecordId).HasMaxLength(160).IsRequired();
            e.Property(x => x.RegionCode).HasMaxLength(16);
            e.Property(x => x.LanguageCode).HasMaxLength(16);
            e.HasIndex(x => x.Name);
            e.HasIndex(x => new { x.DataSourceId, x.SourceRecordId }).IsUnique();
            e.HasOne(x => x.DataSource).WithMany(x => x.Foods)
                .HasForeignKey(x => x.DataSourceId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.Brand).WithMany(x => x.Foods)
                .HasForeignKey(x => x.BrandId).OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<FoodServing>(e =>
        {
            e.ToTable("FoodServings");
            e.HasKey(x => x.Id);
            e.Property(x => x.Description).HasMaxLength(200).IsRequired();
            e.Property(x => x.Unit).HasMaxLength(40).IsRequired();
            e.Property(x => x.Quantity).HasPrecision(18, 4);
            e.Property(x => x.GramWeight).HasPrecision(18, 4);
            e.Property(x => x.CaloriesKcal).HasPrecision(18, 4);
            e.Property(x => x.ProteinGrams).HasPrecision(18, 4);
            e.Property(x => x.CarbohydrateGrams).HasPrecision(18, 4);
            e.Property(x => x.FatGrams).HasPrecision(18, 4);
            e.HasIndex(x => x.FoodId);
            e.HasOne(x => x.Food).WithMany(x => x.Servings)
                .HasForeignKey(x => x.FoodId).OnDelete(DeleteBehavior.Cascade);
            e.ToTable(t => t.HasCheckConstraint("CK_FoodServings_NonNegative",
                "[Quantity] > 0 AND ([GramWeight] IS NULL OR [GramWeight] > 0) AND [CaloriesKcal] >= 0 AND [ProteinGrams] >= 0 AND [CarbohydrateGrams] >= 0 AND [FatGrams] >= 0"));
        });

        modelBuilder.Entity<FoodBarcode>(e =>
        {
            e.ToTable("FoodBarcodes");
            e.HasKey(x => x.Id);
            e.Property(x => x.Value).HasMaxLength(32).IsRequired();
            e.Property(x => x.Format).HasMaxLength(16).IsRequired();
            e.HasIndex(x => x.Value);
            e.HasIndex(x => new { x.FoodId, x.Value }).IsUnique();
            e.HasOne(x => x.Food).WithMany(x => x.Barcodes)
                .HasForeignKey(x => x.FoodId).OnDelete(DeleteBehavior.Cascade);
        });
    }
}
