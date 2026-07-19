using GINJ.Models;
using Microsoft.EntityFrameworkCore;

namespace GINJ.Data
{
    public static class SeedData
    {
        public static void Initialize(AppDbContext context)
        {
            context.Database.Migrate();

            if (!context.GurbaniLists.Any())
            {
                context.GurbaniLists.AddRange(
                    new GurbaniList { Title = "Twinkle Twinkle Little Star", Description = "A classic rhyme.", YoutubeUrl = "https://www.youtube.com/watch?v=yCjJyiqpAuU", ScoreRequirement = 0 },
                    new GurbaniList { Title = "Baa Baa Black Sheep", Description = "A popular nursery rhyme.", YoutubeUrl = "https://www.youtube.com/watch?v=7iT8kCmQ4i4", ScoreRequirement = 0 },
                    new GurbaniList { Title = "Humpty Dumpty", Description = "A traditional rhyme.", ScoreRequirement = 0 }
                );
            }

            if (!context.PrizeLists.Any())
            {
                context.PrizeLists.AddRange(
                    new PrizeList { Name = "Sticker Pack", Description = "A set of fun stickers.", MinimumScore = 0, AvailableStock = 20, IsActive = true },
                    new PrizeList { Name = "Coloring Book", Description = "A simple coloring book.", MinimumScore = 5, AvailableStock = 15, IsActive = true },
                    new PrizeList { Name = "Toy Puzzle", Description = "A small puzzle toy.", MinimumScore = 10, AvailableStock = 10, IsActive = true },
                    new PrizeList { Name = "Pencil Set", Description = "Colorful pencils for drawing.", MinimumScore = 0, AvailableStock = 25, IsActive = true },
                    new PrizeList { Name = "Toy Car", Description = "A small toy car.", MinimumScore = 8, AvailableStock = 12, IsActive = true },
                    new PrizeList { Name = "Drawing Pad", Description = "A large drawing pad with quality paper.", MinimumScore = 0, AvailableStock = 18, IsActive = true },
                    new PrizeList { Name = "Toy Ball", Description = "A soft foam ball for playing.", MinimumScore = 3, AvailableStock = 14, IsActive = true },
                    new PrizeList { Name = "Story Book", Description = "An illustrated children's story book.", MinimumScore = 5, AvailableStock = 16, IsActive = true }
                );
            }
            else
            {
                // Add missing gifts if they don't exist
                if (!context.PrizeLists.Any(g => g.Name == "Drawing Pad"))
                {
                    context.PrizeLists.Add(new PrizeList { Name = "Drawing Pad", Description = "A large drawing pad with quality paper.", MinimumScore = 0, AvailableStock = 18, IsActive = true });
                }
                if (!context.PrizeLists.Any(g => g.Name == "Toy Ball"))
                {
                    context.PrizeLists.Add(new PrizeList { Name = "Toy Ball", Description = "A soft foam ball for playing.", MinimumScore = 3, AvailableStock = 14, IsActive = true });
                }
                if (!context.PrizeLists.Any(g => g.Name == "Story Book"))
                {
                    context.PrizeLists.Add(new PrizeList { Name = "Story Book", Description = "An illustrated children's story book.", MinimumScore = 5, AvailableStock = 16, IsActive = true });
                }
            }

            context.SaveChanges();
        }
    }
}
