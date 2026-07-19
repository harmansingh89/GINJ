using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace GINJ.Models
{
    public class UserProfile
    {
        [Key]
        public long Id { get; set; }

        [Required]
        public long UserId { get; set; }
        
        [JsonIgnore]
        public User? User { get; set; }

        [Required]
        public string Name { get; set; } = string.Empty;

        [Required]
        public DateTime DateOfBirth { get; set; }

        [Required]
        public int Age { get; set; }

        [Required]
        public string Sex { get; set; } = string.Empty;

        [Required]
        public string FatherName { get; set; } = string.Empty;

        public int InternalScore { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        [JsonIgnore]
        public ICollection<Submission> Submissions { get; set; } = new List<Submission>();
    }
}
