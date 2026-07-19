namespace GINJ.DTOs
{
    public class SubmissionRequest
    {
        public long UserProfileId { get; set; }
        public long GurbaniId { get; set; }
        public long PrizeId { get; set; }

        public string Address { get; set; } = string.Empty;
        public string? WhatsAppNumber { get; set; }
        public DateTime? WhatsAppTestDate { get; set; }
    }
}
