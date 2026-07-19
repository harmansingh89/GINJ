using GINJ.Models;

namespace GINJ.DTOs
{
    public class ReviewUpdateRequest
    {
        public long SubmissionId { get; set; }
        public WhatsAppTestStatus WhatsAppTestStatus { get; set; }
        public SubmissionStatus SubmissionStatus { get; set; }
        public string? ReviewNotes { get; set; }
    }
}
