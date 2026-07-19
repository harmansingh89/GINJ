using GINJ.Models;

namespace GINJ.Repositories
{
    public interface IUserProfileRepository
    {
        Task<UserProfile?> GetByIdAsync(long id);
        Task<List<UserProfile>> GetByUserAsync(long userId);
        Task<UserProfile> AddAsync(UserProfile userProfile);
        Task SaveChangesAsync();
    }
}
