using GINJ.Data;
using GINJ.Models;
using Microsoft.EntityFrameworkCore;

namespace GINJ.Repositories
{
    public class UserProfileRepository : IUserProfileRepository
    {
        private readonly AppDbContext _db;

        public UserProfileRepository(AppDbContext db)
        {
            _db = db;
        }

        public async Task<UserProfile?> GetByIdAsync(long id)
        {
            return await _db.UserProfiles.FindAsync(id);
        }
        public async Task<List<UserProfile>> GetByUserAsync(long userId)
        {
            return await _db.UserProfiles.Where(c => c.UserId == userId).ToListAsync();
        }

        public async Task<UserProfile> AddAsync(UserProfile userProfile)
        {
            _db.UserProfiles.Add(userProfile);
            await _db.SaveChangesAsync();
            return userProfile;
        }

        public async Task SaveChangesAsync()
        {
            await _db.SaveChangesAsync();
        }
    }
}
