using GINJ.Models;

namespace GINJ.DTOs
{
    public class RhymeRequest
    {
        public string Title { get; set; } = string.Empty;
        public string? YoutubeUrl { get; set; }
        public bool IsThisGurbani { get; set; }
        public string? AgeGroup { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
