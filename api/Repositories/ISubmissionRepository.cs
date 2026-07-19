using GINJ.Models;

namespace GINJ.Repositories
{
    public interface ISubmissionRepository
    {
        Task<List<Submission>> GetByUserAsync(long userId);
        Task<List<Submission>> GetByUserProfileAsync(long userProfileId);
        Task<List<Submission>> GetPendingAsync();
        Task<Submission?> FindByIdAsync(long id);
        Task<Submission?> GetLatestOpenPendingForUserProfileAsync(long userProfileId);
        Task<List<Submission>> GetExistingApprovedForUserProfileAsync(long userProfileId);
        Task<bool> HasDeliveredGurbaniAsync(long userProfileId, long gurbaniId);
        Task<Submission?> GetLastRejectedSubmissionAsync(long userProfileId, long gurbaniId);
        Task<Submission> AddAsync(Submission submission);
        Task<Dispatch?> GetDispatchBySubmissionIdAsync(long submissionId);
        Task<Dispatch> CreateDispatchAsync(Dispatch dispatch);
        Task<PrizeList?> GetPrizeByIdAsync(long id);
        Task<List<Submission>> GetLatestPerUserProfileAsync();
        Task SaveChangesAsync();
    }
}
