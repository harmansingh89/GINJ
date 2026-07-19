namespace GINJ.DTOs
{
    public class GiftRequest
    {
        public string Name { get; set; } = string.Empty;
        public string? ImageUrl { get; set; }
        public int? MinimumScore { get; set; }
        public int? Price { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
