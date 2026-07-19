using GINJ.Data;
using GINJ.Models;
using Microsoft.EntityFrameworkCore;

namespace GINJ.Repositories
{
    public class PrizeListRepository : IPrizeListRepository
    {
        private readonly AppDbContext _db;

        public PrizeListRepository(AppDbContext db)
        {
            _db = db;
        }

        public async Task<List<PrizeList>> GetAllAsync()
        {
            return await _db.PrizeLists.ToListAsync();
        }

        public async Task<PrizeList?> GetByIdAsync(long id)
        {
            return await _db.PrizeLists.FindAsync(id);
        }

        public async Task<List<PrizeList>> GetEligiblePrizesAsync(long userProfileId, long gurbaniId)
        {
            var userProfile = await _db.UserProfiles.FindAsync(userProfileId);
            if (userProfile == null) return new List<PrizeList>();

            var gurbani = await _db.GurbaniLists.FindAsync(gurbaniId);
            if (gurbani == null) return new List<PrizeList>();

            var minPrice = gurbani.ScoreRequirement - 50;
            var maxPrice = gurbani.ScoreRequirement + 50;

            return await _db.PrizeLists
                .Where(g => g.IsActive
                    && g.AvailableStock > 0
                    && g.MinimumScore >= minPrice
                    && g.MinimumScore <= maxPrice
                    && userProfile.InternalScore >= g.MinimumScore)
                .ToListAsync();
        }

        public async Task AddAsync(PrizeList prize)
        {
            await _db.PrizeLists.AddAsync(prize);
        }

        public async Task DeleteAsync(PrizeList prize)
        {
            _db.PrizeLists.Remove(prize);
            await Task.CompletedTask;
        }

        public async Task SaveChangesAsync()
        {
            await _db.SaveChangesAsync();
        }
    }
}
