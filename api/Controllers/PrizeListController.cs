using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using GINJ.Repositories;
using Microsoft.Extensions.Logging;
using System.IO;

namespace GINJ.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/prizelist")]
    public class PrizeListController : ControllerBase
    {
        private readonly IGurbaniListRepository _gurbaniRepo;
        private readonly IUserProfileRepository _userProfileRepo;
        private readonly IPrizeListRepository _prizeRepo;
        private readonly ILogger<PrizeListController> _logger;

        public PrizeListController(ILogger<PrizeListController> logger, IGurbaniListRepository gurbaniRepo, IUserProfileRepository userProfileRepo, IPrizeListRepository prizeRepo)
        {
            _logger = logger;
            _gurbaniRepo = gurbaniRepo;
            _userProfileRepo = userProfileRepo;
            _prizeRepo = prizeRepo;
        }

        [HttpGet("eligible/{userProfileId}/{gurbaniId}")]
        public async Task<IActionResult> GetEligible(long userProfileId, long gurbaniId)
        {
            try
            {
                var gurbani = await _gurbaniRepo.GetByIdAsync(gurbaniId);
                if (gurbani == null || !gurbani.IsActive)
                {
                    return NotFound(new { error = "Gurbani item not found." });
                }

                var userProfile = await _userProfileRepo.GetByIdAsync(userProfileId);
                if (userProfile == null)
                {
                    return NotFound(new { error = "User profile not found." });
                }

                var prizes = await _prizeRepo.GetEligiblePrizesAsync(userProfileId, gurbaniId);

                return Ok(prizes);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get eligible prizes for user profile {UserProfileId} and gurbani {GurbaniId}", userProfileId, gurbaniId);
                return StatusCode(500, new { error = "An error occurred while retrieving eligible prizes." });
            }
        }

        [HttpPost("upload-image")]
        [AllowAnonymous]
        public async Task<IActionResult> UploadImage(IFormFile file)
        {
            try
            {
                if (file == null || file.Length == 0)
                {
                    return BadRequest(new { error = "No file provided." });
                }

                // Validate file size (max 5MB)
                const long maxFileSize = 5 * 1024 * 1024;
                if (file.Length > maxFileSize)
                {
                    return BadRequest(new { error = "File size must not exceed 5MB." });
                }

                // Validate file type (images only)
                var allowedMimes = new[] { "image/jpeg", "image/png", "image/gif", "image/webp" };
                if (!allowedMimes.Contains(file.ContentType))
                {
                    return BadRequest(new { error = "Only JPEG, PNG, GIF, and WebP images are allowed." });
                }

                // Generate unique filename
                var fileName = $"{Guid.NewGuid()}_{Path.GetFileName(file.FileName)}";
                var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images", "gifts");
                
                // Ensure directory exists
                if (!Directory.Exists(uploadsFolder))
                {
                    Directory.CreateDirectory(uploadsFolder);
                }

                var filePath = Path.Combine(uploadsFolder, fileName);

                // Save file
                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                // Return relative URL path
                var imageUrl = $"/images/gifts/{fileName}";
                return Ok(new { imageUrl });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to upload image");
                return StatusCode(500, new { error = "An error occurred while uploading the image." });
            }
        }
    }
}
