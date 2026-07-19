using GINJ.Models;

namespace GINJ.Repositories
{
    public interface IGurbaniListRepository
    {
        Task<List<GurbaniList>> GetActiveGurbaniAsync();
        Task<List<GurbaniList>> GetAllAsync();
        Task<GurbaniList?> GetByIdAsync(long id);
        Task AddAsync(GurbaniList gurbani);
        Task DeleteAsync(GurbaniList gurbani);
        Task SaveChangesAsync();
    }
}
