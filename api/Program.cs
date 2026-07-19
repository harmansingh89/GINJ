using GINJ.Data;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Pomelo.EntityFrameworkCore.MySql.Infrastructure;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Serilog;

Log.Logger = new LoggerConfiguration()
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.File("logs/log-.txt", rollingInterval: RollingInterval.Day)
    .CreateLogger();

var builder = WebApplication.CreateBuilder(args);
builder.Host.UseSerilog();

// Allow command-line or environment overrides for the listening URL.
// If none are provided, the app can still use the default from launchSettings.
var urls = builder.Configuration["urls"];
if (!string.IsNullOrWhiteSpace(urls))
{
    builder.WebHost.UseUrls(urls);
}

builder.Services.AddControllers().AddJsonOptions(options =>
{
    options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
    options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
});
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddMemoryCache();
builder.Services.AddHttpContextAccessor();
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowLocal", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? "server=localhost;port=3306;database=GINJ;user=root;password=Password123!";
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseMySql(connectionString, new MySqlServerVersion(new Version(8, 0, 33))));

// Register repositories
builder.Services.AddScoped<GINJ.Repositories.IGurbaniListRepository, GINJ.Repositories.GurbaniListRepository>();
builder.Services.AddScoped<GINJ.Repositories.IPrizeListRepository, GINJ.Repositories.PrizeListRepository>();
builder.Services.AddScoped<GINJ.Repositories.IUserProfileRepository, GINJ.Repositories.UserProfileRepository>();
builder.Services.AddScoped<GINJ.Repositories.IUserRepository, GINJ.Repositories.UserRepository>();
builder.Services.AddScoped<GINJ.Repositories.ISubmissionRepository, GINJ.Repositories.SubmissionRepository>();

var jwtSettings = builder.Configuration.GetSection("JwtSettings");
var secretKey = jwtSettings.GetValue<string>("Secret") ?? "SuperSecretDummyKey12345!";

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSettings.GetValue<string>("Issuer"),
        ValidAudience = jwtSettings.GetValue<string>("Audience"),
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey))
    };
});

var app = builder.Build();

await InitializeDatabaseAsync(app.Services);

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
app.UseSerilogRequestLogging();
app.UseStaticFiles();
app.UseCors("AllowLocal");

//app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.Run();

static async Task InitializeDatabaseAsync(IServiceProvider services)
{
    for (var attempt = 1; attempt <= 15; attempt++)
    {
        try
        {
            using var scope = services.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            dbContext.Database.Migrate();
            SeedData.Initialize(dbContext);
            return;
        }
        catch (Exception ex)
        {
            if (attempt == 15)
            {
                Log.Fatal(ex, "Database initialization failed after multiple attempts.");
                throw;
            }

            Log.Warning(ex, "Database is not ready yet. Retrying in 5 seconds. Attempt {Attempt}/15", attempt);
            await Task.Delay(5000);
        }
    }
}
