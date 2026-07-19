using GINJ.Models;

namespace GINJ.Repositories
{
    public interface IPrizeListRepository
    {
        Task<List<PrizeList>> GetAllAsync();
        Task<PrizeList?> GetByIdAsync(long id);
        Task<List<PrizeList>> GetEligiblePrizesAsync(long userProfileId, long gurbaniId);
        Task AddAsync(PrizeList prize);
        Task DeleteAsync(PrizeList prize);
        Task SaveChangesAsync();
    }
}
