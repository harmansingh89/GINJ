namespace GINJ.DTOs
{
    public class ResetPasswordRequest
    {
        public string Phone { get; set; } = string.Empty;
        public string Code { get; set; } = string.Empty;
        public string NewPassword { get; set; } = string.Empty;
    }
}
