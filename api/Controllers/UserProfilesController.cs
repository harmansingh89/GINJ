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
    [Route("api/userprofiles")]
    public class UserProfilesController : ControllerBase
    {
        private readonly IUserProfileRepository _userProfileRepo;
        private readonly IUserRepository _userRepo;
        private readonly ILogger<UserProfilesController> _logger;

        public UserProfilesController(IUserProfileRepository userProfileRepo, IUserRepository userRepo, ILogger<UserProfilesController> logger)
        {
            _userProfileRepo = userProfileRepo;
            _userRepo = userRepo;
            _logger = logger;
        }

        [HttpGet("by-user/{userId}")]
        public async Task<IActionResult> GetByUser(long userId)
        {
            try
            {
                var profiles = await _userProfileRepo.GetByUserAsync(userId);
                return Ok(profiles);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to retrieve user profiles for user {UserId}", userId);
                return StatusCode(500, new { error = "An error occurred while retrieving user profiles." });
            }
        }

        [HttpPost("create/{userId}")]
        public async Task<IActionResult> Create(long userId, [FromBody] ChildProfileRequest request)
        {
            try
            {
                var user = await _userRepo.GetByIdAsync(userId);
                if (user == null)
                {
                    return NotFound(new { error = "User not found." });
                }

                // Enforce one profile per user at API level
                var existing = await _userProfileRepo.GetByUserAsync(userId);
                if (existing != null && existing.Count > 0)
                {
                    return Conflict(new { error = "User profile already exists for this user." });
                }

                if (string.IsNullOrWhiteSpace(request.Name) || string.IsNullOrWhiteSpace(request.Sex))
                {
                    return BadRequest(new { error = "Name and sex are required." });
                }

                if (request.DateOfBirth == null && request.Age <= 0)
                {
                    return BadRequest(new { error = "Date of birth or age is required." });
                }

                var dateOfBirth = request.DateOfBirth;
                if (dateOfBirth == null)
                {
                    var today = DateTime.UtcNow.Date;
                    dateOfBirth = today.AddYears(-request.Age);
                }

                var age = request.Age > 0
                    ? request.Age
                    : CalculateAge(dateOfBirth.Value);

                var userProfile = new UserProfile
                {
                    UserId = userId,
                    Name = request.Name,
                    DateOfBirth = dateOfBirth.Value,
                    Age = age,
                    Sex = request.Sex,
                    FatherName = request.FatherName,
                };

                await _userProfileRepo.AddAsync(userProfile);

                var result = new
                {
                    id = userProfile.Id,
                    userId = userProfile.UserId,
                    name = userProfile.Name,
                    dateOfBirth = userProfile.DateOfBirth,
                    age = userProfile.Age,
                    sex = userProfile.Sex,
                    fatherName = userProfile.FatherName,
                    internalScore = userProfile.InternalScore,
                    createdAt = userProfile.CreatedAt,
                    updatedAt = userProfile.UpdatedAt
                };

                return CreatedAtAction(nameof(GetByUser), new { userId }, result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to create user profile for user {UserId}", userId);
                return StatusCode(500, new { error = "An error occurred while creating user profile." });
            }
        }

        [HttpPut("update/{userId}")]
        public async Task<IActionResult> Update(long userId, [FromBody] ChildProfileRequest request)
        {
            try
            {
                var user = await _userRepo.GetByIdAsync(userId);
                if (user == null)
                {
                    return NotFound(new { error = "User not found." });
                }

                var list = await _userProfileRepo.GetByUserAsync(userId);
                if (list == null || list.Count == 0)
                {
                    return NotFound(new { error = "User profile not found." });
                }

                var userProfile = list[0];

                if (string.IsNullOrWhiteSpace(request.Name) || string.IsNullOrWhiteSpace(request.Sex))
                {
                    return BadRequest(new { error = "Name and sex are required." });
                }

                if (request.DateOfBirth == null && request.Age <= 0)
                {
                    return BadRequest(new { error = "Date of birth or age is required." });
                }

                var dateOfBirth = request.DateOfBirth;
                if (dateOfBirth == null)
                {
                    var today = DateTime.UtcNow.Date;
                    dateOfBirth = today.AddYears(-request.Age);
                }

                var age = request.Age > 0
                    ? request.Age
                    : CalculateAge(dateOfBirth.Value);

                userProfile.Name = request.Name;
                userProfile.DateOfBirth = dateOfBirth.Value;
                userProfile.Age = age;
                userProfile.Sex = request.Sex;
                userProfile.FatherName = request.FatherName;
                userProfile.UpdatedAt = DateTime.UtcNow;

                await _userProfileRepo.SaveChangesAsync();

                var result = new
                {
                    id = userProfile.Id,
                    userId = userProfile.UserId,
                    name = userProfile.Name,
                    dateOfBirth = userProfile.DateOfBirth,
                    age = userProfile.Age,
                    sex = userProfile.Sex,
                    fatherName = userProfile.FatherName,
                    internalScore = userProfile.InternalScore,
                    createdAt = userProfile.CreatedAt,
                    updatedAt = userProfile.UpdatedAt
                };

                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to update user profile for user {UserId}", userId);
                return StatusCode(500, new { error = "An error occurred while updating user profile." });
            }
        }

        

        private static int CalculateAge(DateTime dateOfBirth)
        {
            var today = DateTime.UtcNow.Date;
            var age = today.Year - dateOfBirth.Year;
            if (dateOfBirth.Date > today.AddYears(-age))
            {
                age--;
            }

            return age;
        }
    }
}
