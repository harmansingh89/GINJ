using System.Text.Json;
using GINJ.Models;
using Microsoft.EntityFrameworkCore.ChangeTracking;

namespace GINJ.Data
{
    internal class PendingAuditLog
    {
        public required EntityEntry Entry { get; init; }
        public required string Action { get; init; }
        public Dictionary<string, object?> OldValues { get; } = new();
        public Dictionary<string, object?> NewValues { get; } = new();
        public List<string> ChangedColumns { get; } = new();

        public AuditLog ToAuditLog(string actorType, string? actorId, string? actorName, string? requestPath)
        {
            var entityName = Entry.Metadata.ClrType.Name;
            var primaryKey = Entry.Properties.FirstOrDefault(p => p.Metadata.IsPrimaryKey());

            return new AuditLog
            {
                EntityName = entityName,
                EntityId = primaryKey?.CurrentValue?.ToString(),
                Action = Action,
                ActorType = actorType,
                ActorId = actorId,
                ActorName = actorName,
                RequestPath = requestPath,
                ChangedColumns = ChangedColumns.Count == 0 ? null : string.Join(",", ChangedColumns),
                OldValues = OldValues.Count == 0 ? null : JsonSerializer.Serialize(OldValues),
                NewValues = NewValues.Count == 0 ? null : JsonSerializer.Serialize(NewValues),
                CreatedAt = DateTime.UtcNow,
            };
        }
    }
}