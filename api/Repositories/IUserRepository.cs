using GINJ.Models;

namespace GINJ.Repositories
{
    public interface IUserRepository
    {
        Task<User?> GetByIdAsync(long id);
        Task SaveChangesAsync();
    }
}
