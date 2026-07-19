# GINJ Deployment to Remote Server

## Remote Server Info
- **IP**: 88.151.32.132
- **Portainer URL**: https://portman.goodcontent.stream/
- **SSH User**: normhigh
- **SSH Password**: ff3rt_23sd823
- **Docker Folder**: /home/normhigh/docker/ginj/
- **DB Password**: ginjD0wNR0aD@1232

---

## Step 1: Build Docker Image Locally

Open PowerShell in the project root (`d:\Projects\GINJ`):

```powershell
cd d:\Projects\GINJ
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

Verify the build succeeded:
```powershell
docker images | grep ginj
```

Test locally:
- API: `http://localhost:5000/swagger/index.html`
- Admin UI: `http://localhost/`

---

## Step 2: Export Docker Image as .tar

```powershell
docker save -o ginj.tar ginj-api:latest
```

This creates `ginj.tar` in the current directory (`d:\Projects\GINJ`).

---

## Step 3: Transfer Files to Remote Server

```bash
scp ginj.tar docker-compose.yml normhigh@88.151.32.132:/home/normhigh/docker/ginj/
```

When prompted, enter password: `3234fg4t`

---

## Step 4: Connect to Remote Server via Putty

- **Host**: 88.151.32.132
- **User**: normhigh
- **Password**: ff3rt_23sd823

---

## Step 5: Prepare Remote Environment

In Putty terminal, navigate to the Docker folder:

```bash
cd /home/normhigh/docker/ginj/
```

### Clean up old containers (via Portainer)

1. Open https://portman.goodcontent.stream/
2. Go to **Containers** tab
3. Stop and remove:
   - `ginj-api`
   - `ginjdb`
4. Go to **Images** tab
5. Remove `eldusermanagement:latest` image

---

## Step 6: Load and Run Image on Remote Server

In Putty, load the image:

```bash
docker load -i /home/normhigh/docker/ginj/ginj.tar
```

Run the containers:

```bash
docker-compose up -d
```

Verify containers are running:

```bash
docker ps
```

---

## Step 7: Connect Containers to Network via Portainer

1. Open https://portman.goodcontent.stream/
2. Go to **Containers** tab
3. Click `ginj-api` container
4. Under **Connected networks**, click **Join a network**
5. Select `my-main-net`
6. Click **JOIN**
7. Repeat for `ginjdb` container

---

## Step 8: Connect MySQL Database (if needed)

To make the database publicly accessible temporarily:

1. In Portainer, open `ginjdb` container
2. Add `my-main-net` network and join
3. Connect via local MySQL client:
   - **Host**: 88.151.32.132
   - **Port**: 3306
   - **Username**: ginj
   - **Password**: ginjD0wNR0aD@1232

**Important**: Remove the `my-main-net` connection from `ginjdb` after you're done to disable public access.

---

## Step 9: Test the Deployment

Test API endpoint:

```
http://88.151.32.132:18160/swagger/index.html
```

---

## Notes

- The Docker image was built with **Alpine Linux 9.0** for smaller size and faster deployment
- Environment variables (MySQL password, connection strings) are set in `docker-compose.yml`
- All containers should be in the `my-main-net` network for proper communication on the remote server
- API port: **18160**
- Admin UI port: **18161** (if configured in Portainer)
- MySQL port: **3306** (internal), exposed only via network
