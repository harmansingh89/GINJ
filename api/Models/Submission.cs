using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace GINJ.Models
{
    public enum SubmissionStatus
    {
        Pending,
        Approved,
        Rejected
    }

    public enum WhatsAppTestStatus
    {
        Pending,
        Passed,
        Failed,
        Postponed
    }

    public class Submission
    {
        [Key]
        public long Id { get; set; }

        [Required]
        public long UserId { get; set; }
        public User? User { get; set; }

        [Required]
        public long UserProfileId { get; set; }
        public UserProfile? UserProfile { get; set; }

        [Required]
        public long GurbaniId { get; set; }
        public GurbaniList? Gurbani { get; set; }

        [Required]
        public long PrizeId { get; set; }
        public PrizeList? Prize { get; set; }

        [Required]
        public string Address { get; set; } = string.Empty;

        public SubmissionStatus Status { get; set; } = SubmissionStatus.Pending;
        public WhatsAppTestStatus WhatsAppTestStatus { get; set; } = WhatsAppTestStatus.Pending;
        public string? ReviewNotes { get; set; }
        public string? WhatsAppNumber { get; set; }
        public DateTime? WhatsAppTestDate { get; set; }
        public DateTime? RejectedAt { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        public bool IsActive { get; set; } = true;

        public Dispatch? Dispatch { get; set; }
    }
}
