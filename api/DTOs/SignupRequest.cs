namespace GINJ.DTOs
{
    public class SignupRequest
    {
        public string Phone { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public bool ConsentAccepted { get; set; }
    }
}
