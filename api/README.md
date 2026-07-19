# API Setup

This folder contains the .NET backend API for the GINJ project.

## Local database setup
1. Open `api/setup.sql` in MySQL Workbench.
2. Execute the script to create the `GINJ` database and a local user.
3. Ensure `api/appsettings.json` contains the matching connection string:

```json
"ConnectionStrings": {
  "DefaultConnection": "server=localhost;port=3306;database=GINJ;user=ginj;password=GinjPassword123!"
}
```

## Run the API
```powershell
cd d:\Projects\GINJ\api
dotnet restore
dotnet build
dotnet run
```

## Notes
- The API uses `http://0.0.0.0:5000` by default via `Program.cs`.
- The Flutter Android emulator should use `http://10.0.2.2:5000` to reach the API.
