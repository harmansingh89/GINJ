namespace GINJ.DTOs
{
    public class VerifyOtpRequest
    {
        public string Phone { get; set; } = string.Empty;
        public string Code { get; set; } = string.Empty;
    }
}
