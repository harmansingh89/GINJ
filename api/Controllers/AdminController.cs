using GINJ.DTOs;
using GINJ.Models;
using GINJ.Repositories;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace GINJ.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AdminController : ControllerBase
    {
        private readonly ISubmissionRepository _submissionRepo;
        private readonly IPrizeListRepository _giftRepo;
        private readonly ILogger<AdminController> _logger;

        public AdminController(ISubmissionRepository submissionRepo, IPrizeListRepository giftRepo, ILogger<AdminController> logger)
        {
            _submissionRepo = submissionRepo;
            _giftRepo = giftRepo;
            _logger = logger;
        }

        [HttpGet("pending-submissions")]
        public async Task<IActionResult> GetPendingSubmissions()
        {
            try
            {
                var latestPerUserProfile = await _submissionRepo.GetLatestPerUserProfileAsync();
                return Ok(latestPerUserProfile);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to retrieve pending submissions");
                return StatusCode(500, new { error = "An error occurred while retrieving pending submissions." });
            }
        }

        [HttpPut("review")]
        public async Task<IActionResult> Review([FromBody] ReviewUpdateRequest request)
        {
            try
            {
                var submission = await _submissionRepo.FindByIdAsync(request.SubmissionId);
                if (submission == null)
                {
                    return NotFound(new { error = "Submission not found." });
                }

                submission.WhatsAppTestStatus = request.WhatsAppTestStatus;
                submission.Status = request.SubmissionStatus;
                submission.ReviewNotes = request.ReviewNotes;
                submission.UpdatedAt = DateTime.UtcNow;

                if (request.SubmissionStatus == SubmissionStatus.Rejected)
                {
                    submission.RejectedAt = DateTime.UtcNow;
                    submission.IsActive = false;
                }

                await _submissionRepo.SaveChangesAsync();
                return Ok(submission);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = "An error occurred while reviewing submission.", details = ex.Message });
            }
        }

        [HttpPut("dispatch/{submissionId}")]
        public async Task<IActionResult> Dispatch(long submissionId, [FromBody] DispatchUpdateRequest request)
        {
            var submission = await _submissionRepo.FindByIdAsync(submissionId);
            if (submission == null)
            {
                return NotFound(new { error = "Submission not found." });
            }
            var dispatch = await _submissionRepo.GetDispatchBySubmissionIdAsync(submissionId);
            if (dispatch == null)
            {
                dispatch = new Dispatch
                {
                    SubmissionId = submissionId,
                    DocketNumber = request.DocketNumber,
                    DispatchedAt = request.DeliveryStatus == DeliveryStatus.Dispatched ? DateTime.UtcNow : (DateTime?)null,
                    DeliveredAt = request.DeliveryStatus == DeliveryStatus.Delivered ? DateTime.UtcNow : (DateTime?)null,
                    DeliveryStatus = request.DeliveryStatus,
                };

                if (request.DeliveryStatus == DeliveryStatus.Delivered)
                {
                    submission.Status = SubmissionStatus.Approved;
                    submission.IsActive = false;
                    submission.UpdatedAt = DateTime.UtcNow;
                }

                await _submissionRepo.CreateDispatchAsync(dispatch);
            }
            else
            {
                dispatch.DocketNumber = request.DocketNumber;
                if (request.DeliveryStatus == DeliveryStatus.Dispatched)
                {
                    dispatch.DispatchedAt = DateTime.UtcNow;
                }
                if (request.DeliveryStatus == DeliveryStatus.Delivered)
                {
                    dispatch.DeliveredAt = DateTime.UtcNow;
                }
                if (request.DeliveryStatus == DeliveryStatus.Returned)
                {
                    dispatch.DeliveredAt = null;
                }
                dispatch.DeliveryStatus = request.DeliveryStatus;
                dispatch.UpdatedAt = DateTime.UtcNow;

                if (request.DeliveryStatus == DeliveryStatus.Delivered)
                {
                    submission.Status = SubmissionStatus.Approved;
                    submission.IsActive = false;
                    submission.UpdatedAt = DateTime.UtcNow;
                }
                else if (request.DeliveryStatus == DeliveryStatus.Returned)
                {
                    submission.Status = SubmissionStatus.Pending;
                    submission.IsActive = true;
                    submission.UpdatedAt = DateTime.UtcNow;
                }

                await _submissionRepo.SaveChangesAsync();
            }

            return Ok(dispatch);
        }

        [HttpGet("submission-history/{userProfileId}")]
        public async Task<IActionResult> GetSubmissionHistory(long userProfileId)
        {
            try
            {
            var submissions = await _submissionRepo.GetByUserProfileAsync(userProfileId);
                var latestOpenSubmissionId = submissions
                    .Where(s => s.Status != SubmissionStatus.Rejected &&
                        (s.Dispatch == null || s.Dispatch.DeliveryStatus != DeliveryStatus.Delivered))
                    .OrderByDescending(s => s.CreatedAt)
                    .Select(s => (long?)s.Id)
                    .FirstOrDefault();

                var visibleSubmissions = submissions
                    .Where(s =>
                        s.Id == latestOpenSubmissionId ||
                        s.Status == SubmissionStatus.Rejected ||
                        (s.Dispatch != null && s.Dispatch.DeliveryStatus == DeliveryStatus.Delivered))
                    .OrderByDescending(s => s.CreatedAt)
                    .ToList();

                var history = visibleSubmissions.Select(s => new
                {
                    id = s.Id,
                    gurbani = s.Gurbani?.Title,
                    prize = s.Prize?.Name,
                    address = s.Address,
                    status = s.Status.ToString(),
                    dispatchStatus = s.Dispatch?.DeliveryStatus.ToString() ?? "None",
                    docket = s.Dispatch?.DocketNumber,
                    createdAt = s.CreatedAt,
                }).OrderByDescending(s => s.createdAt).ToList();
                return Ok(history);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to retrieve submission history for user profile {UserProfileId}", userProfileId);
                return StatusCode(500, new { error = "An error occurred while retrieving submission history." });
            }
        }
    }
}
