using MySqlConnector;
using System;
using System.Threading.Tasks;

var cs = "server=localhost;port=3306;database=GINJ;user=ginj;password=ginj123";
await using var conn = new MySqlConnection(cs);
await conn.OpenAsync();

await using (var cmd = conn.CreateCommand())
{
    Console.WriteLine("ChildProfiles for ParentId=1:");
    cmd.CommandText = "SELECT Id, Name, DateOfBirth, Sex, ParentId FROM ChildProfiles WHERE ParentId = 1";
    await using var childReader = await cmd.ExecuteReaderAsync();
    var childRows = 0;
    while (await childReader.ReadAsync())
    {
        childRows++;
        Console.WriteLine($"Child {childRows}: Id={childReader.GetInt32("Id")}, Name={childReader.GetString("Name")}, DOB={childReader.GetDateTime("DateOfBirth")}, Sex={childReader.GetString("Sex")}, ParentId={childReader.GetInt32("ParentId")}");
    }
    if (childRows == 0)
    {
        Console.WriteLine("No child profiles found for ParentId=1.");
    }
    await childReader.CloseAsync();

    cmd.CommandText = @"SELECT s.Id, s.ChildProfileId, s.ParentId, s.RhymeId, s.GiftId, s.Address, s.Status, s.WhatsAppTestStatus, s.WhatsAppNumber, s.WhatsAppTestDate, s.ReviewNotes, s.CreatedAt, d.Id AS DispatchId, d.DeliveryStatus, d.DocketNumber, d.DispatchedAt, d.DeliveredAt
FROM Submissions s
LEFT JOIN Dispatches d ON s.Id = d.SubmissionId
WHERE s.ParentId = 1
ORDER BY s.CreatedAt DESC";
    await using var reader = await cmd.ExecuteReaderAsync();
    var rows = 0;
    while (await reader.ReadAsync())
    {
        rows++;
        var id = reader.GetInt32(reader.GetOrdinal("Id"));
        var childProfileId = reader.GetInt32(reader.GetOrdinal("ChildProfileId"));
        var parentId = reader.GetInt32(reader.GetOrdinal("ParentId"));
        var rhymeId = reader.GetInt32(reader.GetOrdinal("RhymeId"));
        var giftId = reader.GetInt32(reader.GetOrdinal("GiftId"));
        var address = reader.IsDBNull(reader.GetOrdinal("Address")) ? "null" : reader.GetString(reader.GetOrdinal("Address"));
        var status = reader.GetInt32(reader.GetOrdinal("Status"));
        var whatsAppTestStatus = reader.GetInt32(reader.GetOrdinal("WhatsAppTestStatus"));
        var whatsAppNumber = reader.IsDBNull(reader.GetOrdinal("WhatsAppNumber")) ? "null" : reader.GetString(reader.GetOrdinal("WhatsAppNumber"));
        var createdAt = reader.GetDateTime(reader.GetOrdinal("CreatedAt"));
        var dispatchId = reader.IsDBNull(reader.GetOrdinal("DispatchId")) ? "null" : reader.GetInt32(reader.GetOrdinal("DispatchId")).ToString();
        var deliveryStatus = reader.IsDBNull(reader.GetOrdinal("DeliveryStatus")) ? "null" : reader.GetInt32(reader.GetOrdinal("DeliveryStatus")).ToString();
        var docketNumber = reader.IsDBNull(reader.GetOrdinal("DocketNumber")) ? "null" : reader.GetString(reader.GetOrdinal("DocketNumber"));
        var deliveredAt = reader.IsDBNull(reader.GetOrdinal("DeliveredAt")) ? "null" : reader.GetDateTime(reader.GetOrdinal("DeliveredAt")).ToString();
        Console.WriteLine($"Row {rows}: Id={id}, ChildProfileId={childProfileId}, ParentId={parentId}, RhymeId={rhymeId}, GiftId={giftId}, Status={status}, WhatsAppTestStatus={whatsAppTestStatus}, DispatchId={dispatchId}, DeliveryStatus={deliveryStatus}, DocketNumber={docketNumber}, CreatedAt={createdAt}, DeliveredAt={deliveredAt}, Address={address}, WhatsAppNumber={whatsAppNumber}");
    }
    if (rows == 0)
    {
        Console.WriteLine("No submissions found for ParentId=1.");
    }
}
