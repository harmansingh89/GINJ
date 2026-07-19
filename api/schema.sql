-- Idempotent schema initialization for database `ginj`
-- Safe to run multiple times. Does not modify existing tables if they already exist.
CREATE DATABASE IF NOT EXISTS `ginj` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `ginj`;

CREATE TABLE IF NOT EXISTS `user` (
  `Id` bigint NOT NULL AUTO_INCREMENT,
  `Phone` varchar(255) CHARACTER SET utf8mb4 NOT NULL,
  `PasswordHash` longtext CHARACTER SET utf8mb4 NOT NULL,
  `ConsentAccepted` tinyint(1) NOT NULL,
  `PhoneVerified` tinyint(1) NOT NULL,
  `RecipientName` longtext CHARACTER SET utf8mb4 NULL,
  `HouseOrFlatNo` longtext CHARACTER SET utf8mb4 NULL,
  `StreetOrLocality` longtext CHARACTER SET utf8mb4 NULL,
  `City` longtext CHARACTER SET utf8mb4 NULL,
  `PinCode` longtext CHARACTER SET utf8mb4 NULL,
  `SavedAddress` longtext CHARACTER SET utf8mb4 NULL,
  `CreatedAt` datetime(6) NOT NULL,
  `UpdatedAt` datetime(6) NOT NULL,
  PRIMARY KEY (`Id`)
) CHARACTER SET=utf8mb4;

CREATE TABLE IF NOT EXISTS `gurbaniList` (
  `Id` bigint NOT NULL AUTO_INCREMENT,
  `Title` longtext CHARACTER SET utf8mb4 NOT NULL,
  `Description` longtext CHARACTER SET utf8mb4 NULL,
  `YoutubeUrl` longtext CHARACTER SET utf8mb4 NULL,
  `IsThisGurbani` tinyint(1) NOT NULL,
  `AgeGroup` longtext CHARACTER SET utf8mb4 NULL,
  `Weightage` int NOT NULL,
  `IsActive` tinyint(1) NOT NULL,
  PRIMARY KEY (`Id`)
) CHARACTER SET=utf8mb4;

CREATE TABLE IF NOT EXISTS `prizeList` (
  `Id` bigint NOT NULL AUTO_INCREMENT,
  `Name` longtext CHARACTER SET utf8mb4 NOT NULL,
  `Description` longtext CHARACTER SET utf8mb4 NULL,
  `ImageUrl` longtext CHARACTER SET utf8mb4 NULL,
  `EligibilityCriteria` longtext CHARACTER SET utf8mb4 NULL,
  `Price` int NOT NULL,
  `AvailableStock` int NOT NULL,
  `IsActive` tinyint(1) NOT NULL,
  PRIMARY KEY (`Id`)
) CHARACTER SET=utf8mb4;

CREATE TABLE IF NOT EXISTS `userProfiles` (
  `Id` bigint NOT NULL AUTO_INCREMENT,
  `UserId` bigint NOT NULL,
  `Name` longtext CHARACTER SET utf8mb4 NOT NULL,
  `DateOfBirth` datetime(6) NOT NULL,
  `Age` int NOT NULL,
  `Sex` longtext CHARACTER SET utf8mb4 NOT NULL,
  `FatherName` longtext CHARACTER SET utf8mb4 NOT NULL,
  `InternalScore` int NOT NULL,
  `CreatedAt` datetime(6) NOT NULL,
  `UpdatedAt` datetime(6) NOT NULL,
  PRIMARY KEY (`Id`)
) CHARACTER SET=utf8mb4;

CREATE TABLE IF NOT EXISTS `submissions` (
  `Id` bigint NOT NULL AUTO_INCREMENT,
  `UserId` bigint NOT NULL,
  `UserProfileId` bigint NOT NULL,
  `GurbaniId` bigint NOT NULL,
  `PrizeId` bigint NOT NULL,
  `Address` longtext CHARACTER SET utf8mb4 NOT NULL,
  `Status` int NOT NULL,
  `WhatsAppTestStatus` int NOT NULL,
  `ReviewNotes` longtext CHARACTER SET utf8mb4 NULL,
  `WhatsAppNumber` longtext CHARACTER SET utf8mb4 NULL,
  `WhatsAppTestDate` datetime(6) NULL,
  `RejectedAt` datetime(6) NULL,
  `CreatedAt` datetime(6) NOT NULL,
  `UpdatedAt` datetime(6) NOT NULL,
  `IsActive` tinyint(1) NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`Id`)
) CHARACTER SET=utf8mb4;

CREATE TABLE IF NOT EXISTS `Dispatches` (
  `Id` bigint NOT NULL AUTO_INCREMENT,
  `SubmissionId` bigint NOT NULL,
  `DocketNumber` longtext CHARACTER SET utf8mb4 NULL,
  `DispatchedAt` datetime(6) NULL,
  `DeliveryStatus` int NOT NULL,
  `DeliveredAt` datetime(6) NULL,
  `CreatedAt` datetime(6) NOT NULL,
  `UpdatedAt` datetime(6) NOT NULL,
  PRIMARY KEY (`Id`)
) CHARACTER SET=utf8mb4;

CREATE TABLE IF NOT EXISTS `AuditLogs` (
  `Id` bigint NOT NULL AUTO_INCREMENT,
  `EntityName` varchar(255) CHARACTER SET utf8mb4 NOT NULL,
  `EntityId` longtext CHARACTER SET utf8mb4 NULL,
  `Action` longtext CHARACTER SET utf8mb4 NOT NULL,
  `ActorType` longtext CHARACTER SET utf8mb4 NOT NULL,
  `ActorId` longtext CHARACTER SET utf8mb4 NULL,
  `ActorName` longtext CHARACTER SET utf8mb4 NULL,
  `RequestPath` longtext CHARACTER SET utf8mb4 NULL,
  `ChangedColumns` longtext CHARACTER SET utf8mb4 NULL,
  `OldValues` longtext CHARACTER SET utf8mb4 NULL,
  `NewValues` longtext CHARACTER SET utf8mb4 NULL,
  `CreatedAt` datetime(6) NOT NULL,
  PRIMARY KEY (`Id`)
) CHARACTER SET=utf8mb4;

CREATE TABLE IF NOT EXISTS `__EFMigrationsHistory` (
  `MigrationId` varchar(150) CHARACTER SET utf8mb4 NOT NULL,
  `ProductVersion` varchar(32) CHARACTER SET utf8mb4 NOT NULL,
  PRIMARY KEY (`MigrationId`)
) CHARACTER SET=utf8mb4;

-- Indexes and foreign keys
SELECT COUNT(*) INTO @idxExists FROM information_schema.statistics
 WHERE table_schema='ginj' AND table_name='user' AND index_name='IX_user_Phone';
SET @stmt = IF(@idxExists = 0,
  'ALTER TABLE `user` ADD UNIQUE INDEX `IX_user_Phone` (`Phone`);',
  'SELECT "IX_user_Phone exists";');
PREPARE s1 FROM @stmt; EXECUTE s1; DEALLOCATE PREPARE s1;

SELECT COUNT(*) INTO @idxExists FROM information_schema.statistics
 WHERE table_schema='ginj' AND table_name='userProfiles' AND index_name='IX_userProfiles_UserId';
SET @stmt = IF(@idxExists = 0,
  'ALTER TABLE `userProfiles` ADD INDEX `IX_userProfiles_UserId` (`UserId`);',
  'SELECT "IX_userProfiles_UserId exists";');
PREPARE s2 FROM @stmt; EXECUTE s2; DEALLOCATE PREPARE s2;

SELECT COUNT(*) INTO @idxExists FROM information_schema.statistics
 WHERE table_schema='ginj' AND table_name='submissions' AND index_name='IX_submissions_UserId';
SET @stmt = IF(@idxExists = 0,
  'ALTER TABLE `submissions` ADD INDEX `IX_submissions_UserId` (`UserId`);',
  'SELECT "IX_submissions_UserId exists";');
PREPARE s3 FROM @stmt; EXECUTE s3; DEALLOCATE PREPARE s3;

SELECT COUNT(*) INTO @idxExists FROM information_schema.statistics
 WHERE table_schema='ginj' AND table_name='submissions' AND index_name='IX_submissions_UserProfileId';
SET @stmt = IF(@idxExists = 0,
  'ALTER TABLE `submissions` ADD INDEX `IX_submissions_UserProfileId` (`UserProfileId`);',
  'SELECT "IX_submissions_UserProfileId exists";');
PREPARE s4 FROM @stmt; EXECUTE s4; DEALLOCATE PREPARE s4;

SELECT COUNT(*) INTO @idxExists FROM information_schema.statistics
 WHERE table_schema='ginj' AND table_name='submissions' AND index_name='IX_submissions_GurbaniId';
SET @stmt = IF(@idxExists = 0,
  'ALTER TABLE `submissions` ADD INDEX `IX_submissions_GurbaniId` (`GurbaniId`);',
  'SELECT "IX_submissions_GurbaniId exists";');
PREPARE s5 FROM @stmt; EXECUTE s5; DEALLOCATE PREPARE s5;

SELECT COUNT(*) INTO @idxExists FROM information_schema.statistics
 WHERE table_schema='ginj' AND table_name='submissions' AND index_name='IX_submissions_PrizeId';
SET @stmt = IF(@idxExists = 0,
  'ALTER TABLE `submissions` ADD INDEX `IX_submissions_PrizeId` (`PrizeId`);',
  'SELECT "IX_submissions_PrizeId exists";');
PREPARE s6 FROM @stmt; EXECUTE s6; DEALLOCATE PREPARE s6;

SELECT COUNT(*) INTO @idxExists FROM information_schema.statistics
 WHERE table_schema='ginj' AND table_name='Dispatches' AND index_name='IX_Dispatches_SubmissionId';
SET @stmt = IF(@idxExists = 0,
  'ALTER TABLE `Dispatches` ADD UNIQUE INDEX `IX_Dispatches_SubmissionId` (`SubmissionId`);',
  'SELECT "IX_Dispatches_SubmissionId exists";');
PREPARE s7 FROM @stmt; EXECUTE s7; DEALLOCATE PREPARE s7;

SELECT COUNT(*) INTO @idxExists FROM information_schema.statistics
 WHERE table_schema='ginj' AND table_name='AuditLogs' AND index_name='IX_AuditLogs_CreatedAt';
SET @stmt = IF(@idxExists = 0,
  'ALTER TABLE `AuditLogs` ADD INDEX `IX_AuditLogs_CreatedAt` (`CreatedAt`);',
  'SELECT "IX_AuditLogs_CreatedAt exists";');
PREPARE s8 FROM @stmt; EXECUTE s8; DEALLOCATE PREPARE s8;

SELECT COUNT(*) INTO @idxExists FROM information_schema.statistics
 WHERE table_schema='ginj' AND table_name='AuditLogs' AND index_name='IX_AuditLogs_EntityName';
SET @stmt = IF(@idxExists = 0,
  'ALTER TABLE `AuditLogs` ADD INDEX `IX_AuditLogs_EntityName` (`EntityName`);',
  'SELECT "IX_AuditLogs_EntityName exists";');
PREPARE s9 FROM @stmt; EXECUTE s9; DEALLOCATE PREPARE s9;

SELECT COUNT(*) INTO @fkExists FROM information_schema.table_constraints
 WHERE table_schema='ginj' AND table_name='userProfiles' AND constraint_name='FK_userProfiles_user_UserId';
SET @stmt = IF(@fkExists = 0,
  'ALTER TABLE `userProfiles` ADD CONSTRAINT `FK_userProfiles_user_UserId` FOREIGN KEY (`UserId`) REFERENCES `user`(`Id`) ON DELETE CASCADE;',
  'SELECT "FK_userProfiles_user_UserId exists";');
PREPARE s10 FROM @stmt; EXECUTE s10; DEALLOCATE PREPARE s10;

SELECT COUNT(*) INTO @fkExists FROM information_schema.table_constraints
 WHERE table_schema='ginj' AND table_name='submissions' AND constraint_name='FK_submissions_user_UserId';
SET @stmt = IF(@fkExists = 0,
  'ALTER TABLE `submissions` ADD CONSTRAINT `FK_submissions_user_UserId` FOREIGN KEY (`UserId`) REFERENCES `user`(`Id`) ON DELETE CASCADE;',
  'SELECT "FK_submissions_user_UserId exists";');
PREPARE s11 FROM @stmt; EXECUTE s11; DEALLOCATE PREPARE s11;

SELECT COUNT(*) INTO @fkExists FROM information_schema.table_constraints
 WHERE table_schema='ginj' AND table_name='submissions' AND constraint_name='FK_submissions_userProfiles_UserProfileId';
SET @stmt = IF(@fkExists = 0,
  'ALTER TABLE `submissions` ADD CONSTRAINT `FK_submissions_userProfiles_UserProfileId` FOREIGN KEY (`UserProfileId`) REFERENCES `userProfiles`(`Id`) ON DELETE CASCADE;',
  'SELECT "FK_submissions_userProfiles_UserProfileId exists";');
PREPARE s12 FROM @stmt; EXECUTE s12; DEALLOCATE PREPARE s12;

SELECT COUNT(*) INTO @fkExists FROM information_schema.table_constraints
 WHERE table_schema='ginj' AND table_name='submissions' AND constraint_name='FK_submissions_gurbaniList_GurbaniId';
SET @stmt = IF(@fkExists = 0,
  'ALTER TABLE `submissions` ADD CONSTRAINT `FK_submissions_gurbaniList_GurbaniId` FOREIGN KEY (`GurbaniId`) REFERENCES `gurbaniList`(`Id`) ON DELETE CASCADE;',
  'SELECT "FK_submissions_gurbaniList_GurbaniId exists";');
PREPARE s13 FROM @stmt; EXECUTE s13; DEALLOCATE PREPARE s13;

SELECT COUNT(*) INTO @fkExists FROM information_schema.table_constraints
 WHERE table_schema='ginj' AND table_name='submissions' AND constraint_name='FK_submissions_prizeList_PrizeId';
SET @stmt = IF(@fkExists = 0,
  'ALTER TABLE `submissions` ADD CONSTRAINT `FK_submissions_prizeList_PrizeId` FOREIGN KEY (`PrizeId`) REFERENCES `prizeList`(`Id`) ON DELETE CASCADE;',
  'SELECT "FK_submissions_prizeList_PrizeId exists";');
PREPARE s14 FROM @stmt; EXECUTE s14; DEALLOCATE PREPARE s14;

SELECT COUNT(*) INTO @fkExists FROM information_schema.table_constraints
 WHERE table_schema='ginj' AND table_name='Dispatches' AND constraint_name='FK_Dispatches_submissions_SubmissionId';
SET @stmt = IF(@fkExists = 0,
  'ALTER TABLE `Dispatches` ADD CONSTRAINT `FK_Dispatches_submissions_SubmissionId` FOREIGN KEY (`SubmissionId`) REFERENCES `submissions`(`Id`) ON DELETE CASCADE;',
  'SELECT "FK_Dispatches_submissions_SubmissionId exists";');
PREPARE s15 FROM @stmt; EXECUTE s15; DEALLOCATE PREPARE s15;
