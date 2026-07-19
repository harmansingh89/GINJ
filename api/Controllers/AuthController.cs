using GINJ.Data;
using GINJ.DTOs;
using GINJ.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace GINJ.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _dbContext;
        private readonly PasswordHasher<User> _passwordHasher;
        private readonly IConfiguration _configuration;
        private readonly Microsoft.Extensions.Caching.Memory.IMemoryCache _cache;
        private readonly ILogger<AuthController> _logger;

        public AuthController(AppDbContext dbContext, IConfiguration configuration, Microsoft.Extensions.Caching.Memory.IMemoryCache cache, ILogger<AuthController> logger)
        {
            _dbContext = dbContext;
            _passwordHasher = new PasswordHasher<User>();
            _configuration = configuration;
            _cache = cache;
            _logger = logger;
        }

        [HttpPost("signup")]
        public async Task<IActionResult> Signup([FromBody] SignupRequest request)
        {
            if (!request.ConsentAccepted)
            {
                return BadRequest(new { error = "Parental consent is required." });
            }

            if (await _dbContext.Users.AnyAsync(p => p.Phone == request.Phone))
            {
                return Conflict(new { error = "Phone number is already registered." });
            }

            var verifyKey = $"otp-verified:{request.Phone}";
            if (!_cache.TryGetValue(verifyKey, out var verifiedObj) || verifiedObj is not bool verified || !verified)
            {
                return BadRequest(new { error = "Phone number is not verified via OTP." });
            }

            var parent = new User
            {
                Phone = request.Phone,
                ConsentAccepted = request.ConsentAccepted,
                PhoneVerified = true
            };

            parent.PasswordHash = _passwordHasher.HashPassword(parent, request.Password);
            _dbContext.Users.Add(parent);
            await _dbContext.SaveChangesAsync();

            _cache.Remove(verifyKey);

            return CreatedAtAction(nameof(Signup), new { id = parent.Id }, new { parent.Id, parent.Phone });
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var parent = await _dbContext.Users.FirstOrDefaultAsync(p => p.Phone == request.Phone);
            if (parent == null)
            {
                return Unauthorized(new { error = "Phone number does not exist. Please sign up." });
            }

            var result = _passwordHasher.VerifyHashedPassword(parent, parent.PasswordHash, request.Password);
            if (result == PasswordVerificationResult.Failed)
            {
                return Unauthorized(new { error = "Phone number or password does not match. Please try again." });
            }

            if (!parent.PhoneVerified)
            {
                return Unauthorized(new { error = "Phone number is not verified." });
            }

            var jwtSettings = _configuration.GetSection("JwtSettings");
            var secretKey = jwtSettings.GetValue<string>("Secret") ?? string.Empty;
            var issuer = jwtSettings.GetValue<string>("Issuer");
            var audience = jwtSettings.GetValue<string>("Audience");
            var expiryMinutes = jwtSettings.GetValue<int>("ExpiryMinutes");

            var claims = new List<Claim>
            {
                new Claim(JwtRegisteredClaimNames.Sub, parent.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.UniqueName, parent.Phone),
                new Claim("userId", parent.Id.ToString())
            };

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var token = new JwtSecurityToken(
                issuer: issuer,
                audience: audience,
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(expiryMinutes),
                signingCredentials: creds);

            var tokenString = new JwtSecurityTokenHandler().WriteToken(token);

            var response = new LoginResponse
            {
                Token = tokenString,
                UserId = parent.Id,
                Phone = parent.Phone
            };

            return Ok(response);
        }

        [HttpPost("send-otp")]
        public IActionResult SendOtp([FromBody] OtpRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Phone))
            {
                return BadRequest(new { error = "Phone is required." });
            }

            // Use a fixed dummy OTP for development and testing.
            var code = "456456";

            var cacheKey = $"otp:{request.Phone}";
            _cache.Set(cacheKey, code, TimeSpan.FromMinutes(5));

            // Log OTP for development/testing (do NOT do this in production)
            _logger.LogInformation("Generated OTP for {Phone}: {Otp}", request.Phone, code);

            // Return OTP in response for dev convenience
            return Ok(new { otp = code, message = "OTP generated (dev)" });
        }

        [HttpPost("verify-otp")]
        public IActionResult VerifyOtp([FromBody] VerifyOtpRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Phone) || string.IsNullOrWhiteSpace(request.Code))
            {
                return BadRequest(new { error = "Phone and code are required." });
            }

            var cacheKey = $"otp:{request.Phone}";
            if (!_cache.TryGetValue(cacheKey, out var expectedObj) || expectedObj == null)
            {
                return Unauthorized(new { error = "OTP expired or not found." });
            }

            var expected = expectedObj as string ?? string.Empty;

            if (expected != request.Code)
            {
                return Unauthorized(new { error = "Invalid OTP." });
            }

            // OTP verified, mark phone as verified and remove OTP cache
            _cache.Remove(cacheKey);
            _cache.Set($"otp-verified:{request.Phone}", true, TimeSpan.FromMinutes(30));

            return Ok(new { verified = true });
        }

        [HttpPost("refresh-token")]
        public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Token))
            {
                return BadRequest(new { error = "Token is required." });
            }

            try
            {
                var jwtSettings = _configuration.GetSection("JwtSettings");
                var secretKey = jwtSettings.GetValue<string>("Secret") ?? string.Empty;

                var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
                var tokenHandler = new JwtSecurityTokenHandler();

                // Validate the token (ignore expiration for now to extract claims)
                var principal = tokenHandler.ValidateToken(request.Token, new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = key,
                    ValidateIssuer = true,
                    ValidIssuer = jwtSettings.GetValue<string>("Issuer"),
                    ValidateAudience = true,
                    ValidAudience = jwtSettings.GetValue<string>("Audience"),
                    ValidateLifetime = false // Allow expired tokens for refresh
                }, out SecurityToken validatedToken);

                var userIdClaim = principal.FindFirst("userId");
                if (userIdClaim == null || !long.TryParse(userIdClaim.Value, out long userId))
                {
                    return Unauthorized(new { error = "Invalid token." });
                }

                var parent = await _dbContext.Users.FindAsync(userId);
                if (parent == null)
                {
                    return Unauthorized(new { error = "User not found." });
                }

                // Generate new token
                var claims = new List<Claim>
                {
                    new Claim(JwtRegisteredClaimNames.Sub, parent.Id.ToString()),
                    new Claim(JwtRegisteredClaimNames.UniqueName, parent.Phone),
                    new Claim("userId", parent.Id.ToString())
                };

                var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
                var expiryMinutes = jwtSettings.GetValue<int>("ExpiryMinutes");

                var newToken = new JwtSecurityToken(
                    issuer: jwtSettings.GetValue<string>("Issuer"),
                    audience: jwtSettings.GetValue<string>("Audience"),
                    claims: claims,
                    expires: DateTime.UtcNow.AddMinutes(expiryMinutes),
                    signingCredentials: creds);

                var tokenString = tokenHandler.WriteToken(newToken);

                return Ok(new { token = tokenString });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Token refresh failed");
                return Unauthorized(new { error = "Token refresh failed." });
            }
        }

        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Phone))
            {
                return BadRequest(new { error = "Phone is required." });
            }

            var parent = await _dbContext.Users.FirstOrDefaultAsync(p => p.Phone == request.Phone);
            if (parent == null)
            {
                // For security, don't reveal if phone exists
                return Ok(new { message = "If phone exists, OTP will be sent." });
            }

            // Generate dummy OTP for password reset
            var code = "456456";
            var cacheKey = $"reset-otp:{request.Phone}";
            _cache.Set(cacheKey, code, TimeSpan.FromMinutes(10));

            _logger.LogInformation("Generated password reset OTP for {Phone}: {Otp}", request.Phone, code);

            return Ok(new { otp = code, message = "OTP sent (dev)" });
        }

        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Phone) || string.IsNullOrWhiteSpace(request.Code) || string.IsNullOrWhiteSpace(request.NewPassword))
            {
                return BadRequest(new { error = "Phone, code, and new password are required." });
            }

            var cacheKey = $"reset-otp:{request.Phone}";
            if (!_cache.TryGetValue(cacheKey, out var expectedObj) || expectedObj == null)
            {
                return Unauthorized(new { error = "OTP expired or not found." });
            }

            var expected = expectedObj as string ?? string.Empty;
            if (expected != request.Code)
            {
                return Unauthorized(new { error = "Invalid OTP." });
            }

            var parent = await _dbContext.Users.FirstOrDefaultAsync(p => p.Phone == request.Phone);
            if (parent == null)
            {
                return NotFound(new { error = "Phone not found." });
            }

            // Update password
            parent.PasswordHash = _passwordHasher.HashPassword(parent, request.NewPassword);
            _dbContext.Users.Update(parent);
            await _dbContext.SaveChangesAsync();

            _cache.Remove(cacheKey);

            return Ok(new { message = "Password reset successfully." });
        }
    }
}
