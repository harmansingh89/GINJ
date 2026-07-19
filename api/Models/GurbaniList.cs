using System.ComponentModel.DataAnnotations;

namespace GINJ.Models
{
    public class GurbaniList
    {
        [Key]
        public long Id { get; set; }

        [Required]
        public string Title { get; set; } = string.Empty;

        public string? Description { get; set; }
        public string? YoutubeUrl { get; set; }
        public bool IsThisGurbani { get; set; }
        public string? AgeGroup { get; set; }
        public int ScoreRequirement { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
