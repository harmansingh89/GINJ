using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace GINJ.Models
{
    public enum DeliveryStatus
    {
        Pending,
        Dispatched,
        Delivered,
        Returned
    }

    public class Dispatch
    {
        [Key]
        public long Id { get; set; }

        [Required]
        public long SubmissionId { get; set; }
        
        [JsonIgnore]
        public Submission? Submission { get; set; }

        public string? DocketNumber { get; set; }
        public DateTime? DispatchedAt { get; set; }
        public DeliveryStatus DeliveryStatus { get; set; } = DeliveryStatus.Pending;
        public DateTime? DeliveredAt { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}
