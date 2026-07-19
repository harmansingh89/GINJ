using GINJ.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Http;

namespace GINJ.Data
{
    public class AppDbContext : DbContext
    {
        private readonly IHttpContextAccessor? _httpContextAccessor;
        private bool _isSavingAuditLogs;

        public AppDbContext(DbContextOptions<AppDbContext> options, IHttpContextAccessor? httpContextAccessor)
            : base(options)
        {
            _httpContextAccessor = httpContextAccessor;
        }

        public DbSet<User> Users => Set<User>();
        public DbSet<UserProfile> UserProfiles => Set<UserProfile>();
        public DbSet<GurbaniList> GurbaniLists => Set<GurbaniList>();
        public DbSet<PrizeList> PrizeLists => Set<PrizeList>();
        public DbSet<Submission> Submissions => Set<Submission>();
        public DbSet<Dispatch> Dispatches => Set<Dispatch>();
        public DbSet<AuditLog> AuditLogs => Set<AuditLog>();

        public override int SaveChanges()
        {
            return SaveChangesAsync().GetAwaiter().GetResult();
        }

        public override int SaveChanges(bool acceptAllChangesOnSuccess)
        {
            return SaveChangesAsync(acceptAllChangesOnSuccess).GetAwaiter().GetResult();
        }

        public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            return SaveChangesAsync(true, cancellationToken);
        }

        public override async Task<int> SaveChangesAsync(bool acceptAllChangesOnSuccess, CancellationToken cancellationToken = default)
        {
            if (_isSavingAuditLogs)
            {
                return await base.SaveChangesAsync(acceptAllChangesOnSuccess, cancellationToken);
            }

            var pendingAuditLogs = BuildPendingAuditLogs();
            var result = await base.SaveChangesAsync(acceptAllChangesOnSuccess, cancellationToken);

            if (pendingAuditLogs.Count == 0)
            {
                return result;
            }

            var (actorType, actorId, actorName, requestPath) = GetActorContext();

            try
            {
                _isSavingAuditLogs = true;
                AuditLogs.AddRange(pendingAuditLogs.Select(audit =>
                    audit.ToAuditLog(actorType, actorId, actorName, requestPath)));
                await base.SaveChangesAsync(acceptAllChangesOnSuccess, cancellationToken);
            }
            finally
            {
                _isSavingAuditLogs = false;
            }

            return result;
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<User>()
                .ToTable("user");

            modelBuilder.Entity<UserProfile>()
                .ToTable("userProfiles")
                .Property(c => c.UserId)
                .HasColumnName("UserId");

            modelBuilder.Entity<GurbaniList>()
                .ToTable("gurbaniList")
                .Property(r => r.ScoreRequirement)
                .HasColumnName("Weightage");

            modelBuilder.Entity<PrizeList>()
                .ToTable("prizeList")
                .Property(g => g.MinimumScore)
                .HasColumnName("Price");

            modelBuilder.Entity<Submission>()
                .ToTable("submissions")
                .Property(s => s.UserProfileId)
                .HasColumnName("UserProfileId");

            modelBuilder.Entity<Submission>()
                .Property(s => s.GurbaniId)
                .HasColumnName("GurbaniId");

            modelBuilder.Entity<Submission>()
                .Property(s => s.PrizeId)
                .HasColumnName("PrizeId");

            modelBuilder.Entity<User>()
                .HasIndex(p => p.Phone)
                .IsUnique();

            modelBuilder.Entity<UserProfile>()
                .HasOne(c => c.User)
                .WithMany(p => p.UserProfiles)
                .HasForeignKey(c => c.UserId);

            modelBuilder.Entity<Submission>()
                .HasOne(s => s.User)
                .WithMany(p => p.Submissions)
                .HasForeignKey(s => s.UserId);

            modelBuilder.Entity<Submission>()
                .HasOne(s => s.UserProfile)
                .WithMany(c => c.Submissions)
                .HasForeignKey(s => s.UserProfileId);

            modelBuilder.Entity<Submission>()
                .HasOne(s => s.Gurbani)
                .WithMany()
                .HasForeignKey(s => s.GurbaniId);

            modelBuilder.Entity<Submission>()
                .HasOne(s => s.Prize)
                .WithMany()
                .HasForeignKey(s => s.PrizeId);

            modelBuilder.Entity<Submission>()
                .Property(s => s.IsActive)
                .HasDefaultValue(true);

            modelBuilder.Entity<Dispatch>()
                .HasOne(d => d.Submission)
                .WithOne(s => s.Dispatch)
                .HasForeignKey<Dispatch>(d => d.SubmissionId);

            modelBuilder.Entity<AuditLog>()
                .HasIndex(a => a.EntityName);

            modelBuilder.Entity<AuditLog>()
                .HasIndex(a => a.CreatedAt);
        }

        private List<PendingAuditLog> BuildPendingAuditLogs()
        {
            ChangeTracker.DetectChanges();

            var pendingLogs = new List<PendingAuditLog>();

            foreach (var entry in ChangeTracker.Entries())
            {
                if (entry.Entity is AuditLog ||
                    entry.State == EntityState.Detached ||
                    entry.State == EntityState.Unchanged)
                {
                    continue;
                }

                var pendingLog = new PendingAuditLog
                {
                    Entry = entry,
                    Action = entry.State.ToString(),
                };

                foreach (var property in entry.Properties)
                {
                    var propertyName = property.Metadata.Name;

                    if (property.Metadata.IsPrimaryKey())
                    {
                        continue;
                    }

                    switch (entry.State)
                    {
                        case EntityState.Added:
                            pendingLog.NewValues[propertyName] = property.CurrentValue;
                            pendingLog.ChangedColumns.Add(propertyName);
                            break;
                        case EntityState.Deleted:
                            pendingLog.OldValues[propertyName] = property.OriginalValue;
                            pendingLog.ChangedColumns.Add(propertyName);
                            break;
                        case EntityState.Modified:
                            if (!property.IsModified)
                            {
                                break;
                            }

                            if (Equals(property.OriginalValue, property.CurrentValue))
                            {
                                break;
                            }

                            pendingLog.OldValues[propertyName] = property.OriginalValue;
                            pendingLog.NewValues[propertyName] = property.CurrentValue;
                            pendingLog.ChangedColumns.Add(propertyName);
                            break;
                    }
                }

                if (pendingLog.ChangedColumns.Count > 0)
                {
                    pendingLogs.Add(pendingLog);
                }
            }

            return pendingLogs;
        }

        private (string actorType, string? actorId, string? actorName, string? requestPath) GetActorContext()
        {
            var httpContext = _httpContextAccessor?.HttpContext;
            var requestPath = httpContext?.Request.Path.Value;

            if (httpContext == null)
            {
                return ("System", null, null, requestPath);
            }

            var userId = httpContext.User.FindFirst("userId")?.Value;
            var actorName = httpContext.User.Identity?.Name ?? httpContext.User.FindFirst("unique_name")?.Value;

            if (!string.IsNullOrWhiteSpace(requestPath) && requestPath.StartsWith("/api/admin", StringComparison.OrdinalIgnoreCase))
            {
                return ("Admin", userId, actorName ?? "Admin UI", requestPath);
            }

            if (httpContext.User.Identity?.IsAuthenticated == true)
            {
                return ("User", userId, actorName, requestPath);
            }

            return ("Anonymous", userId, actorName, requestPath);
        }
    }
}
