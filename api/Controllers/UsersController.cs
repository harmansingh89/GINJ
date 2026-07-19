using GINJ.Data;
using GINJ.DTOs;
using GINJ.Models;
using GINJ.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GINJ.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/users")]
    public class UsersController : ControllerBase
    {
        private readonly IUserRepository _userRepo;
        private readonly ILogger<UsersController> _logger;

        public UsersController(IUserRepository userRepo, ILogger<UsersController> logger)
        {
            _userRepo = userRepo;
            _logger = logger;
        }

        [HttpGet("{userId}")]
        public async Task<IActionResult> GetUser(long userId)
        {
            try
            {
                var user = await _userRepo.GetByIdAsync(userId);
                if (user == null)
                {
                    return NotFound(new { error = "User not found." });
                }

                return Ok(new
                {
                    user.Id,
                    user.Phone,
                    user.ConsentAccepted,
                    user.RecipientName,
                    user.HouseOrFlatNo,
                    user.StreetOrLocality,
                    user.City,
                    user.PinCode,
                    user.SavedAddress
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to retrieve user {UserId}", userId);
                return StatusCode(500, new { error = "An error occurred while retrieving user." });
            }
        }

        [HttpPut("address/{userId}")]
        public async Task<IActionResult> UpdateAddress(long userId, [FromBody] AddressRequest request)
        {
            try
            {
                var user = await _userRepo.GetByIdAsync(userId);
                if (user == null)
                {
                    return NotFound(new { error = "User not found." });
                }

                if (request.Phone != null)
                {
                    user.Phone = request.Phone;
                }

                if (request.RecipientName != null)
                {
                    user.RecipientName = request.RecipientName;
                }

                if (request.HouseOrFlatNo != null)
                {
                    user.HouseOrFlatNo = request.HouseOrFlatNo;
                }

                if (request.StreetOrLocality != null)
                {
                    user.StreetOrLocality = request.StreetOrLocality;
                }

                if (request.City != null)
                {
                    user.City = request.City;
                }

                if (request.PinCode != null)
                {
                    user.PinCode = request.PinCode;
                }

                user.SavedAddress = BuildSavedAddress(user);
                user.UpdatedAt = DateTime.UtcNow;
                await _userRepo.SaveChangesAsync();

                return Ok(new
                {
                    user.Id,
                    user.Phone,
                    user.RecipientName,
                    user.HouseOrFlatNo,
                    user.StreetOrLocality,
                    user.City,
                    user.PinCode,
                    user.SavedAddress
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to update address for user {UserId}", userId);
                return StatusCode(500, new { error = "An error occurred while updating user address." });
            }
        }

        private static string BuildSavedAddress(User user)
        {
            var parts = new[]
            {
                user.RecipientName,
                user.HouseOrFlatNo,
                user.StreetOrLocality,
                user.City,
                string.IsNullOrWhiteSpace(user.PinCode) ? null : $"PIN: {user.PinCode}"
            }
            .Where(part => !string.IsNullOrWhiteSpace(part))
            .ToArray();

            return string.Join(", ", parts);
        }
    }
}
