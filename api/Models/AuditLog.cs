using System.ComponentModel.DataAnnotations;

namespace GINJ.Models
{
    public class AuditLog
    {
        [Key]
        public long Id { get; set; }

        [Required]
        public string EntityName { get; set; } = string.Empty;

        public string? EntityId { get; set; }

        [Required]
        public string Action { get; set; } = string.Empty;

        [Required]
        public string ActorType { get; set; } = string.Empty;

        public string? ActorId { get; set; }
        public string? ActorName { get; set; }
        public string? RequestPath { get; set; }
        public string? ChangedColumns { get; set; }
        public string? OldValues { get; set; }
        public string? NewValues { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}