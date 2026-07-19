using GINJ.Models;

namespace GINJ.DTOs
{
    public class DispatchUpdateRequest
    {
        public string? DocketNumber { get; set; }
        public DeliveryStatus DeliveryStatus { get; set; }
    }
}
