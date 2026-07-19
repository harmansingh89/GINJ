namespace GINJ.DTOs
{
    public class ChildProfileRequest
    {
        public string Name { get; set; } = string.Empty;
        public DateTime? DateOfBirth { get; set; }
        public int Age { get; set; }
        public string Sex { get; set; } = string.Empty;
        public string FatherName { get; set; } = string.Empty;
    }
}
