using GINJ.Data;
using GINJ.DTOs;
using GINJ.Models;
using GINJ.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace GINJ.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]
    public class SubmissionsController : ControllerBase
    {
        private readonly IUserRepository _userRepo;
        private readonly IUserProfileRepository _userProfileRepo;
        private readonly IGurbaniListRepository _gurbaniRepo;
        private readonly IPrizeListRepository _prizeRepo;
        private readonly ISubmissionRepository _submissionRepo;
        private readonly ILogger<SubmissionsController> _logger;

        public SubmissionsController(
            ILogger<SubmissionsController> logger,
            IUserRepository userRepo,
            IUserProfileRepository userProfileRepo,
            IGurbaniListRepository gurbaniRepo,
            IPrizeListRepository prizeRepo,
            ISubmissionRepository submissionRepo)
        {
            _logger = logger;
            _userRepo = userRepo;
            _userProfileRepo = userProfileRepo;
            _gurbaniRepo = gurbaniRepo;
            _prizeRepo = prizeRepo;
            _submissionRepo = submissionRepo;
        }

        [HttpGet("by-user/{userId}")]
        public async Task<IActionResult> GetByUser(long userId)
        {
            try
            {
                var submissions = await _submissionRepo.GetByUserAsync(userId);
                return Ok(submissions);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to retrieve submissions for user {UserId}", userId);
                return StatusCode(500, new { error = "An error occurred while retrieving submissions." });
            }
        }

        [HttpGet("by-user-profile/{userProfileId}")]
        public async Task<IActionResult> GetByUserProfile(long userProfileId)
        {
            try
            {
                var submissions = await _submissionRepo.GetByUserProfileAsync(userProfileId);
                var result = submissions.Select(s => new
                {
                    id = s.Id,
                    userProfileId = s.UserProfileId,
                    gurbaniId = s.GurbaniId,
                    prizeId = s.PrizeId,
                    prizeName = s.Prize?.Name,
                    status = s.Status.ToString(),
                    whatsAppTestStatus = s.WhatsAppTestStatus.ToString(),
                    whatsAppNumber = s.WhatsAppNumber,
                    whatsAppTestDate = s.WhatsAppTestDate,
                    reviewNotes = s.ReviewNotes,
                    createdAt = s.CreatedAt,
                    dispatch = s.Dispatch != null ? new
                    {
                        id = s.Dispatch.Id,
                        deliveryStatus = s.Dispatch.DeliveryStatus.ToString(),
                        docketNumber = s.Dispatch.DocketNumber,
                    } : (object?)null,
                }).ToList();
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to retrieve submissions for user profile {UserProfileId}", userProfileId);
                return StatusCode(500, new { error = "An error occurred while retrieving submissions." });
            }
        }

        [HttpPost("create/{userId}")]
        public async Task<IActionResult> Create(long userId, [FromBody] SubmissionRequest request)
        {
            try
            {
                var user = await _userRepo.GetByIdAsync(userId);
                if (user == null)
                {
                    return NotFound(new { error = "User not found." });
                }

                var userProfile = await _userProfileRepo.GetByIdAsync(request.UserProfileId);
                if (userProfile == null || userProfile.UserId != userId)
                {
                    return BadRequest(new { error = "User profile not found or not owned by user." });
                }

                var gurbani = await _gurbaniRepo.GetByIdAsync(request.GurbaniId);
                if (gurbani == null || !gurbani.IsActive)
                {
                    return BadRequest(new { error = "Gurbani item not found." });
                }

                var prize = await _prizeRepo.GetByIdAsync(request.PrizeId);
                if (prize == null || !prize.IsActive || prize.AvailableStock <= 0)
                {
                    return BadRequest(new { error = "Prize not available." });
                }

                var existingApproved = await _submissionRepo.GetExistingApprovedForUserProfileAsync(request.UserProfileId);

                if (existingApproved.Any(s => s.Dispatch == null || s.Dispatch.DeliveryStatus != DeliveryStatus.Delivered))
                {
                    return BadRequest(new { error = "A previous approved submission is still in delivery." });
                }

                var deliveredRhyme = await _submissionRepo.HasDeliveredGurbaniAsync(request.UserProfileId, request.GurbaniId);

                if (deliveredRhyme)
                {
                    return BadRequest(new { error = "This Gurbani item has already been delivered for this profile and cannot be selected again." });
                }

                var rejectedSubmission = await _submissionRepo.GetLastRejectedSubmissionAsync(request.UserProfileId, request.GurbaniId);

                if (rejectedSubmission != null && rejectedSubmission.RejectedAt.HasValue)
                {
                    var retryAt = rejectedSubmission.RejectedAt.Value.AddDays(7);
                    if (DateTime.UtcNow < retryAt)
                    {
                        return BadRequest(new { error = $"You can resubmit this Gurbani item after {retryAt:yyyy-MM-dd}." });
                    }
                }

                var openPendingSubmission = await _submissionRepo.GetLatestOpenPendingForUserProfileAsync(request.UserProfileId);

                if (openPendingSubmission != null)
                {
                    openPendingSubmission.GurbaniId = request.GurbaniId;
                    openPendingSubmission.PrizeId = request.PrizeId;
                    openPendingSubmission.Address = request.Address;
                    openPendingSubmission.Status = SubmissionStatus.Pending;
                    openPendingSubmission.WhatsAppTestStatus = WhatsAppTestStatus.Pending;
                    openPendingSubmission.WhatsAppNumber = request.WhatsAppNumber;
                    openPendingSubmission.WhatsAppTestDate = request.WhatsAppTestDate;
                    openPendingSubmission.ReviewNotes = null;
                    openPendingSubmission.RejectedAt = null;
                    openPendingSubmission.UpdatedAt = DateTime.UtcNow;

                    if (openPendingSubmission.Dispatch != null)
                    {
                        openPendingSubmission.Dispatch.DeliveryStatus = DeliveryStatus.Pending;
                        openPendingSubmission.Dispatch.DocketNumber = null;
                        openPendingSubmission.Dispatch.DispatchedAt = null;
                        openPendingSubmission.Dispatch.DeliveredAt = null;
                        openPendingSubmission.Dispatch.UpdatedAt = DateTime.UtcNow;
                    }

                    await _submissionRepo.SaveChangesAsync();
                    return Ok(openPendingSubmission);
                }

                var submission = new Submission
                {
                    UserId = userId,
                    UserProfileId = request.UserProfileId,
                    GurbaniId = request.GurbaniId,
                    PrizeId = request.PrizeId,
                    Address = request.Address,
                    WhatsAppNumber = request.WhatsAppNumber,
                    WhatsAppTestDate = request.WhatsAppTestDate,
                    Status = SubmissionStatus.Pending,
                    WhatsAppTestStatus = WhatsAppTestStatus.Pending,
                };

                await _submissionRepo.AddAsync(submission);

                return CreatedAtAction(nameof(GetByUser), new { userId }, submission);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to create submission for user {UserId}", userId);
                return StatusCode(500, new { error = "An error occurred while creating submission." });
            }
        }
    }
}
