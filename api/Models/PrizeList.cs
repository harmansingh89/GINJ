using System.ComponentModel.DataAnnotations;

namespace GINJ.Models
{
    public class PrizeList
    {
        [Key]
        public long Id { get; set; }

        [Required]
        public string Name { get; set; } = string.Empty;

        public string? Description { get; set; }
        public string? ImageUrl { get; set; }
        public string? EligibilityCriteria { get; set; }
        public int MinimumScore { get; set; }
        public int AvailableStock { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
