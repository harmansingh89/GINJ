namespace GINJ.DTOs
{
    public class AddressRequest
    {
        public string? RecipientName { get; set; }
        public string? HouseOrFlatNo { get; set; }
        public string? StreetOrLocality { get; set; }
        public string? City { get; set; }
        public string? PinCode { get; set; }
        public string? Phone { get; set; }
        public string? Address { get; set; }
    }
}
