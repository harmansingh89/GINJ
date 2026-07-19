using GINJ.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using GINJ.Repositories;
using Microsoft.Extensions.Logging;

namespace GINJ.Controllers
{
    //[Authorize]
    [ApiController]    
    [Route("api/gurbanilist")]
    public class GurbaniListController : ControllerBase
    {
        private readonly IGurbaniListRepository _gurbaniRepo;
        private readonly ILogger<GurbaniListController> _logger;

        public GurbaniListController(ILogger<GurbaniListController> logger, IGurbaniListRepository gurbaniRepo)
        {
            _logger = logger;
            _gurbaniRepo = gurbaniRepo;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            try
            {
                var gurbaniItems = await _gurbaniRepo.GetActiveGurbaniAsync();
                return Ok(gurbaniItems);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get active gurbani items");
                return StatusCode(500, new { error = "An error occurred while retrieving gurbani items." });
            }
        }
    }
}
