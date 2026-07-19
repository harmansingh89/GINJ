using GINJ.DTOs;
using GINJ.Models;
using GINJ.Repositories;
using Microsoft.AspNetCore.Mvc;
using System.IO;
using System.Linq;
using Microsoft.EntityFrameworkCore;

namespace GINJ.Controllers
{
    [ApiController]
    [Route("api/admin-catalog")]
    public class AdminCatalogController : ControllerBase
    {
        private readonly IGurbaniListRepository _gurbaniRepo;
        private readonly IPrizeListRepository _prizeRepo;
        private readonly GINJ.Data.AppDbContext _db;

        public AdminCatalogController(IGurbaniListRepository gurbaniRepo, IPrizeListRepository prizeRepo, GINJ.Data.AppDbContext db)
        {
            _gurbaniRepo = gurbaniRepo;
            _prizeRepo = prizeRepo;
            _db = db;
        }

        [HttpGet("gurbani-items")]
        public async Task<IActionResult> GetGurbaniItems()
        {
            var gurbaniItems = await _gurbaniRepo.GetAllAsync();
            return Ok(gurbaniItems);
        }

        [HttpPost("gurbani-items")]
        public async Task<IActionResult> CreateGurbaniItem([FromBody] RhymeRequest request)
        {
            var gurbani = new GurbaniList
            {
                Title = request.Title,
                YoutubeUrl = request.YoutubeUrl,
                IsThisGurbani = request.IsThisGurbani,
                AgeGroup = request.AgeGroup,
                IsActive = request.IsActive,
            };

            await _gurbaniRepo.AddAsync(gurbani);
            await _gurbaniRepo.SaveChangesAsync();
            return CreatedAtAction(nameof(GetGurbaniItems), new { id = gurbani.Id }, gurbani);
        }

        [HttpPut("gurbani-items/{id}")]
        public async Task<IActionResult> UpdateGurbaniItem(long id, [FromBody] RhymeRequest request)
        {
            var gurbani = await _gurbaniRepo.GetByIdAsync(id);
            if (gurbani == null)
            {
                return NotFound();
            }

            gurbani.Title = request.Title;
            gurbani.YoutubeUrl = request.YoutubeUrl;
            gurbani.IsThisGurbani = request.IsThisGurbani;
            gurbani.AgeGroup = request.AgeGroup;
            gurbani.IsActive = request.IsActive;

            await _gurbaniRepo.SaveChangesAsync();
            return Ok(gurbani);
        }

        [HttpDelete("gurbani-items/{id}")]
        public async Task<IActionResult> DeleteGurbaniItem(long id)
        {
            var gurbani = await _gurbaniRepo.GetByIdAsync(id);
            if (gurbani == null)
            {
                return NotFound();
            }

            await _gurbaniRepo.DeleteAsync(gurbani);
            await _gurbaniRepo.SaveChangesAsync();
            return NoContent();
        }

        [HttpGet("prizes")]
        public async Task<IActionResult> GetPrizes()
        {
            var prizes = await _prizeRepo.GetAllAsync();
            return Ok(prizes);
        }

        [HttpGet("users")]
        public async Task<IActionResult> GetUsers()
        {
            var users = await _db.Users
                .Include(p => p.UserProfiles)
                .OrderByDescending(p => p.CreatedAt)
                .Select(p => new
                {
                    p.Id,
                    p.Phone,
                    p.ConsentAccepted,
                    p.PhoneVerified,
                    p.RecipientName,
                    p.HouseOrFlatNo,
                    p.StreetOrLocality,
                    p.City,
                    p.PinCode,
                    p.SavedAddress,
                    p.CreatedAt,
                    UserProfiles = p.UserProfiles.Select(c => new
                    {
                        c.Id,
                        c.Name,
                        c.DateOfBirth,
                        c.Age,
                        c.Sex,
                        c.FatherName,
                        c.CreatedAt,
                    }).ToList(),
                })
                .ToListAsync();
            return Ok(users);
        }

        [HttpGet("addresses")]
        public async Task<IActionResult> GetUserAddresses()
        {
            var addresses = await _db.Users
                .Include(p => p.UserProfiles)
                .OrderByDescending(p => p.CreatedAt)
                .Select(p => new
                {
                    p.Id,
                    p.RecipientName,
                    p.HouseOrFlatNo,
                    p.StreetOrLocality,
                    p.City,
                    p.PinCode,
                    p.Phone,
                    p.SavedAddress,
                    p.CreatedAt,
                    UserProfiles = p.UserProfiles.Select(c => new
                    {
                        c.Id,
                        c.Name,
                        c.DateOfBirth,
                        c.Age,
                        c.Sex,
                        c.FatherName,
                        c.CreatedAt,
                    }).ToList(),
                })
                .ToListAsync();
            return Ok(addresses);
        }

        [HttpGet("audit-logs")]
        public async Task<IActionResult> GetAuditLogs()
        {
            var logs = await _db.AuditLogs
                .OrderByDescending(a => a.CreatedAt)
                .Take(500)
                .Select(a => new
                {
                    a.Id,
                    a.EntityName,
                    a.EntityId,
                    a.Action,
                    a.ActorType,
                    a.ActorId,
                    a.ActorName,
                    a.RequestPath,
                    a.ChangedColumns,
                    a.OldValues,
                    a.NewValues,
                    a.CreatedAt,
                })
                .ToListAsync();

            return Ok(logs);
        }

        [HttpPut("addresses/{userId}")]
        public async Task<IActionResult> UpdateUserAddress(long userId, [FromBody] AddressRequest request)
        {
            var user = await _db.Users.FindAsync(userId);
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
            await _db.SaveChangesAsync();

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

        [HttpPost("users/remove-duplicates")]
        public async Task<IActionResult> RemoveDuplicateUsers()
        {
            // Keep the earliest created user for each phone, delete others
            var duplicates = await _db.Users
                .GroupBy(p => p.Phone)
                .Where(g => g.Count() > 1)
                .ToListAsync();

            var toDelete = new List<GINJ.Models.User>();
            foreach (var group in duplicates)
            {
                var ordered = group.OrderBy(p => p.CreatedAt).ToList();
                // keep first, delete the rest
                toDelete.AddRange(ordered.Skip(1));
            }

            if (toDelete.Any())
            {
                _db.Users.RemoveRange(toDelete);
                await _db.SaveChangesAsync();
            }

            return Ok(new { deleted = toDelete.Count });
        }

        [HttpPost("prizes")]
        public async Task<IActionResult> CreatePrize([FromBody] GiftRequest request)
        {
            var prize = new PrizeList
            {
                Name = request.Name,
                ImageUrl = request.ImageUrl,
                MinimumScore = request.MinimumScore ?? request.Price ?? 0,
                IsActive = request.IsActive,
            };

            await _prizeRepo.AddAsync(prize);
            await _prizeRepo.SaveChangesAsync();
            return CreatedAtAction(nameof(GetPrizes), new { id = prize.Id }, prize);
        }

        [HttpPut("prizes/{id}")]
        public async Task<IActionResult> UpdatePrize(long id, [FromBody] GiftRequest request)
        {
            var prize = await _prizeRepo.GetByIdAsync(id);
            if (prize == null)
            {
                return NotFound();
            }

            prize.Name = request.Name;
            prize.ImageUrl = request.ImageUrl;
            prize.MinimumScore = request.MinimumScore ?? request.Price ?? prize.MinimumScore;
            prize.IsActive = request.IsActive;

            await _prizeRepo.SaveChangesAsync();
            return Ok(prize);
        }

        [HttpDelete("prizes/{id}")]
        public async Task<IActionResult> DeletePrize(long id)
        {
            var prize = await _prizeRepo.GetByIdAsync(id);
            if (prize == null)
            {
                return NotFound();
            }

            await _prizeRepo.DeleteAsync(prize);
            await _prizeRepo.SaveChangesAsync();
            return NoContent();
        }

        [HttpPost("prizes/{id}/remove-image")]
        public async Task<IActionResult> RemovePrizeImage(long id)
        {
            var prize = await _prizeRepo.GetByIdAsync(id);
            if (prize == null)
            {
                return NotFound();
            }

            if (string.IsNullOrWhiteSpace(prize.ImageUrl))
            {
                return BadRequest(new { error = "Prize has no image to remove." });
            }

            if (prize.ImageUrl.StartsWith("/images/gifts/"))
            {
                var relativePath = prize.ImageUrl.TrimStart('/').Replace('/', Path.DirectorySeparatorChar);
                var filePath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", relativePath);
                if (System.IO.File.Exists(filePath))
                {
                    System.IO.File.Delete(filePath);
                }
            }

            prize.ImageUrl = null;
            await _prizeRepo.SaveChangesAsync();
            return Ok(prize);
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
