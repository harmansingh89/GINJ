namespace GINJ.DTOs
{
    public class LoginResponse
    {
        public string Token { get; set; } = string.Empty;
        public long UserId { get; set; }
        public string Phone { get; set; } = string.Empty;
    }
}
