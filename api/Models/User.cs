using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace GINJ.Models
{
    public class User
    {
        [Key]
        public long Id { get; set; }

        [Required]
        [Phone]
        public string Phone { get; set; } = string.Empty;

        [Required]
        public string PasswordHash { get; set; } = string.Empty;

        public bool ConsentAccepted { get; set; }
        public bool PhoneVerified { get; set; }

        public string? RecipientName { get; set; }
        public string? HouseOrFlatNo { get; set; }
        public string? StreetOrLocality { get; set; }
        public string? City { get; set; }
        public string? PinCode { get; set; }
        public string? SavedAddress { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        [JsonIgnore]
        public ICollection<UserProfile> UserProfiles { get; set; } = new List<UserProfile>();
        
        [JsonIgnore]
        public ICollection<Submission> Submissions { get; set; } = new List<Submission>();
    }
}
