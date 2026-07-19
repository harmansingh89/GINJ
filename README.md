# GINJ

## Repository structure
- `api/` — .NET backend API project
- `flutter_app/` — Flutter mobile client
- `admin-ui/` — React admin dashboard

## Overview
A simple C# .NET Web API backend for the Parent-Child Rhyme Gift journey.

## Tech stack
- .NET 9 Web API
- Entity Framework Core
- MySQL
- Flutter mobile app
- React admin dashboard

## Setup
1. Open the backend project folder: `cd api`
2. Execute `api/setup.sql` in MySQL Workbench to create the `GINJ` database and local user.
3. Confirm `api/appsettings.json` uses the `ginj` user connection string.
4. Restore packages: `dotnet restore`
5. Build the project: `dotnet build`
6. Run the project: `dotnet run`

## API Endpoints
- `POST /api/auth/signup`
- `POST /api/auth/login`
- `GET /api/childprofiles/by-parent/{parentId}`
- `POST /api/childprofiles/create/{parentId}`
- `GET /api/rhymes`
- `GET /api/gifts/eligible/{childProfileId}/{rhymeId}`
- `POST /api/submissions/create/{parentId}`

## API Endpoints
- `POST /api/auth/signup`
- `POST /api/auth/login`
- `GET /api/childprofiles/by-parent/{parentId}`
- `POST /api/childprofiles/create/{parentId}`
- `GET /api/rhymes`
- `GET /api/gifts/eligible/{childProfileId}/{rhymeId}`
- `POST /api/submissions/create/{parentId}`
- `GET /api/submissions/by-parent/{parentId}`
- `GET /api/admin/pending-submissions`
- `PUT /api/admin/review`
- `PUT /api/admin/dispatch/{submissionId}`
- `PUT /api/admin/delivery/{submissionId}`

## Notes
- `POST /api/auth/login` returns a JWT token.
- Secure endpoints require the `Authorization: Bearer {token}` header.

## Frontend skeletons
- Flutter app skeleton available in `flutter_app/`
  - Run `flutter pub get` inside `flutter_app/`
  - Build for a real Android phone with:
    `flutter build apk --release --dart-define=API_BASE_URL=http://<your-pc-ip>:5000`
  - The app uses `http://10.0.2.2:5000` for Android emulators by default.
- Admin React dashboard skeleton available in `admin-ui/`
  - Run `npm install` inside `admin-ui/`
  - Start with `npm start`.

## Docker deployment
1. Install Docker and Docker Compose on the Linux server.
2. From the repository root, run `docker-compose up --build`.
3. The backend API is exposed on `http://<server-host>:5000`.
4. The admin dashboard is exposed on `http://<server-host>` (port 80).

### SIT notes
- The React admin UI uses `/api` by default, and the Docker nginx proxy forwards `/api` to the `api` service.
- If you deploy the backend separately, set `REACT_APP_API_BASE_URL` to the backend URL in `admin-ui`.
- The mobile app should point to the production API URL, not `10.0.2.2`.
