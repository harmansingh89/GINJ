using GINJ.Data;
using GINJ.Models;
using Microsoft.EntityFrameworkCore;

namespace GINJ.Repositories
{
    public class GurbaniListRepository : IGurbaniListRepository
    {
        private readonly AppDbContext _db;

        public GurbaniListRepository(AppDbContext db)
        {
            _db = db;
        }

        public async Task<List<GurbaniList>> GetActiveGurbaniAsync()
        {
            return await _db.GurbaniLists.Where(r => r.IsActive).ToListAsync();
        }

        public async Task<List<GurbaniList>> GetAllAsync()
        {
            return await _db.GurbaniLists.ToListAsync();
        }

        public async Task<GurbaniList?> GetByIdAsync(long id)
        {
            return await _db.GurbaniLists.FindAsync(id);
        }

        public async Task AddAsync(GurbaniList gurbani)
        {
            await _db.GurbaniLists.AddAsync(gurbani);
        }

        public async Task DeleteAsync(GurbaniList gurbani)
        {
            _db.GurbaniLists.Remove(gurbani);
            await Task.CompletedTask;
        }

        public async Task SaveChangesAsync()
        {
            await _db.SaveChangesAsync();
        }
    }
}
