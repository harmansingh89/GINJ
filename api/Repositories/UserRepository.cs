using GINJ.Data;
using GINJ.Models;

namespace GINJ.Repositories
{
    public class UserRepository : IUserRepository
    {
        private readonly AppDbContext _db;

        public UserRepository(AppDbContext db)
        {
            _db = db;
        }

        public async Task<User?> GetByIdAsync(long id)
        {
            return await _db.Users.FindAsync(id);
        }

        public async Task SaveChangesAsync()
        {
            await _db.SaveChangesAsync();
        }
    }
}
