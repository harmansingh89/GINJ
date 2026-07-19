using GINJ.Data;
using GINJ.Models;
using Microsoft.EntityFrameworkCore;

namespace GINJ.Repositories
{
    public class SubmissionRepository : ISubmissionRepository
    {
        private readonly AppDbContext _db;

        public SubmissionRepository(AppDbContext db)
        {
            _db = db;
        }

        public async Task<List<Submission>> GetByUserAsync(long userId)
        {
            return await _db.Submissions
            .Include(s => s.Gurbani)
            .Include(s => s.Prize)
                .Include(s => s.Dispatch)
            .Where(s => s.UserId == userId)
                .ToListAsync();
        }

        public async Task<List<Submission>> GetByUserProfileAsync(long userProfileId)
        {
            return await _db.Submissions
            .Include(s => s.Gurbani)
            .Include(s => s.Prize)
                .Include(s => s.Dispatch)
            .Where(s => s.UserProfileId == userProfileId)
                .OrderByDescending(s => s.CreatedAt)
                .ToListAsync();
        }

        public async Task<List<Submission>> GetPendingAsync()
        {
            return await _db.Submissions
                .Include(s => s.User)
                .Include(s => s.UserProfile)
                .Include(s => s.Gurbani)
                .Include(s => s.Prize)
                .Include(s => s.Dispatch)
                .Where(s => s.IsActive && s.Status == SubmissionStatus.Pending)
                .ToListAsync();
        }

        public async Task<Submission?> FindByIdAsync(long id)
        {
            return await _db.Submissions.FindAsync(id);
        }

        public async Task<Submission?> GetLatestOpenPendingForUserProfileAsync(long userProfileId)
        {
            return await _db.Submissions
                .Include(s => s.Dispatch)
            .Where(s => s.UserProfileId == userProfileId && s.IsActive && s.Status == SubmissionStatus.Pending &&
                    (s.Dispatch == null || s.Dispatch.DeliveryStatus != DeliveryStatus.Delivered))
                .OrderByDescending(s => s.CreatedAt)
                .FirstOrDefaultAsync();
        }

        public async Task<List<Submission>> GetExistingApprovedForUserProfileAsync(long userProfileId)
        {
            return await _db.Submissions
            .Where(s => s.UserProfileId == userProfileId && s.Status == SubmissionStatus.Approved)
                .Include(s => s.Dispatch)
                .ToListAsync();
        }

        public async Task<bool> HasDeliveredGurbaniAsync(long userProfileId, long gurbaniId)
        {
            return await _db.Submissions
            .Where(s => s.UserProfileId == userProfileId && s.GurbaniId == gurbaniId)
                .Include(s => s.Dispatch)
                .AnyAsync(s => s.Dispatch != null && s.Dispatch.DeliveryStatus == DeliveryStatus.Delivered);
        }

        public async Task<Submission?> GetLastRejectedSubmissionAsync(long userProfileId, long gurbaniId)
        {
            return await _db.Submissions
            .Where(s => s.UserProfileId == userProfileId && s.GurbaniId == gurbaniId && s.Status == SubmissionStatus.Rejected)
                .OrderByDescending(s => s.RejectedAt)
                .FirstOrDefaultAsync();
        }

        public async Task<Submission> AddAsync(Submission submission)
        {
            _db.Submissions.Add(submission);
            await _db.SaveChangesAsync();
            return submission;
        }

        public async Task<Dispatch?> GetDispatchBySubmissionIdAsync(long submissionId)
        {
            return await _db.Dispatches.FirstOrDefaultAsync(d => d.SubmissionId == submissionId);
        }

        public async Task<Dispatch> CreateDispatchAsync(Dispatch dispatch)
        {
            _db.Dispatches.Add(dispatch);
            await _db.SaveChangesAsync();
            return dispatch;
        }

        public async Task<PrizeList?> GetPrizeByIdAsync(long id)
        {
            return await _db.PrizeLists.FindAsync(id);
        }

        public async Task<List<Submission>> GetLatestPerUserProfileAsync()
        {
            var submissions = await _db.Submissions
                .Include(s => s.User)
                .Include(s => s.UserProfile)
                .Include(s => s.Gurbani)
                .Include(s => s.Prize)
                .Include(s => s.Dispatch)
                .ToListAsync();

            var latestPerUserProfile = submissions
                .GroupBy(s => s.UserProfileId)
                .Select(g => g.OrderByDescending(s => s.CreatedAt).First())
                .OrderByDescending(s => s.CreatedAt)
                .ToList();

            return latestPerUserProfile;
        }

        public async Task SaveChangesAsync()
        {
            await _db.SaveChangesAsync();
        }
    }
}
