$base = 'http://localhost:5000'
$phone = '999' + (Get-Random -Minimum 1000000 -Maximum 9999999)
Write-Output "-> send-otp for $phone"
$sendOtp = Invoke-RestMethod -Uri "$base/api/auth/send-otp" -Method Post -ContentType 'application/json' -Body (ConvertTo-Json @{ phone = $phone })
$sendOtp | ConvertTo-Json -Depth 5 | Write-Output

Write-Output "-> verify-otp"
$verify = Invoke-RestMethod -Uri "$base/api/auth/verify-otp" -Method Post -ContentType 'application/json' -Body (ConvertTo-Json @{ phone = $phone; code = '456456' })
$verify | ConvertTo-Json -Depth 5 | Write-Output

Write-Output "-> signup"
$signup = Invoke-RestMethod -Uri "$base/api/auth/signup" -Method Post -ContentType 'application/json' -Body (ConvertTo-Json @{ phone = $phone; password = 'TestPass123!'; consentAccepted = $true })
$signup | ConvertTo-Json -Depth 5 | Write-Output

Write-Output "-> login"
$login = Invoke-RestMethod -Uri "$base/api/auth/login" -Method Post -ContentType 'application/json' -Body (ConvertTo-Json @{ phone = $phone; password = 'TestPass123!' })
$token = $login.Token
if (-not $token) { $token = $login.token }
$userId = $login.UserId
if (-not $userId) { $userId = $login.userId }
Write-Output "Token: $token"
Write-Output "UserId: $userId"

Write-Output "-> create user profile"
$profile = Invoke-RestMethod -Uri "$base/api/userprofiles/create/$userId" -Method Post -ContentType 'application/json' -Headers @{ Authorization = "Bearer $token" } -Body (ConvertTo-Json @{ name = 'Test Child'; dateOfBirth = '2018-01-01T00:00:00Z'; age = 8; sex = 'M'; fatherName = 'Test Father' })
$profile | ConvertTo-Json -Depth 5 | Write-Output
$profileId = $profile.Id
if (-not $profileId) { $profileId = $profile.id }
Write-Output "ProfileId: $profileId"

Write-Output "-> create submission"
try {
	$submission = Invoke-RestMethod -Uri "$base/api/submissions/create/$userId" -Method Post -ContentType 'application/json' -Headers @{ Authorization = "Bearer $token" } -Body (ConvertTo-Json @{ userProfileId = $profileId; gurbaniId = 1; prizeId = 1; address = '123 Test St' }) -ErrorAction Stop
	$submission | ConvertTo-Json -Depth 5 | Write-Output
} catch {
	Write-Output "Submission call failed:"
	if ($_.Exception -and $_.Exception.Response) {
		$respStream = $_.Exception.Response.GetResponseStream()
		$reader = New-Object System.IO.StreamReader($respStream)
		$errContent = $reader.ReadToEnd()
		Write-Output $errContent
	} else {
		Write-Output $_ | ConvertTo-Json -Depth 5
	}
}

Write-Output "Smoke test completed"
