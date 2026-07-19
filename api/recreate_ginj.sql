-- Destructive clean rebuild for database `ginj`
-- Run after dropping the existing database or with a fresh database context.
CREATE DATABASE IF NOT EXISTS `ginj` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `ginj`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `Dispatches`;
DROP TABLE IF EXISTS `submissions`;
DROP TABLE IF EXISTS `userProfiles`;
DROP TABLE IF EXISTS `AuditLogs`;
DROP TABLE IF EXISTS `user`;
DROP TABLE IF EXISTS `gurbaniList`;
DROP TABLE IF EXISTS `prizeList`;
DROP TABLE IF EXISTS `__EFMigrationsHistory`;
SET FOREIGN_KEY_CHECKS = 1;

START TRANSACTION;
ALTER DATABASE CHARACTER SET utf8mb4;

CREATE TABLE `AuditLogs` (
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
    CONSTRAINT `PK_AuditLogs` PRIMARY KEY (`Id`)
) CHARACTER SET=utf8mb4;

CREATE TABLE `gurbaniList` (
    `Id` bigint NOT NULL AUTO_INCREMENT,
    `Title` longtext CHARACTER SET utf8mb4 NOT NULL,
    `Description` longtext CHARACTER SET utf8mb4 NULL,
    `YoutubeUrl` longtext CHARACTER SET utf8mb4 NULL,
    `IsThisGurbani` tinyint(1) NOT NULL,
    `AgeGroup` longtext CHARACTER SET utf8mb4 NULL,
    `Weightage` int NOT NULL,
    `IsActive` tinyint(1) NOT NULL,
    CONSTRAINT `PK_gurbaniList` PRIMARY KEY (`Id`)
) CHARACTER SET=utf8mb4;

CREATE TABLE `prizeList` (
    `Id` bigint NOT NULL AUTO_INCREMENT,
    `Name` longtext CHARACTER SET utf8mb4 NOT NULL,
    `Description` longtext CHARACTER SET utf8mb4 NULL,
    `ImageUrl` longtext CHARACTER SET utf8mb4 NULL,
    `EligibilityCriteria` longtext CHARACTER SET utf8mb4 NULL,
    `Price` int NOT NULL,
    `AvailableStock` int NOT NULL,
    `IsActive` tinyint(1) NOT NULL,
    CONSTRAINT `PK_prizeList` PRIMARY KEY (`Id`)
) CHARACTER SET=utf8mb4;

CREATE TABLE `user` (
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
    CONSTRAINT `PK_user` PRIMARY KEY (`Id`)
) CHARACTER SET=utf8mb4;

CREATE TABLE `userProfiles` (
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
    CONSTRAINT `PK_userProfiles` PRIMARY KEY (`Id`),
    CONSTRAINT `FK_userProfiles_user_UserId` FOREIGN KEY (`UserId`) REFERENCES `user` (`Id`) ON DELETE CASCADE
) CHARACTER SET=utf8mb4;

CREATE TABLE `submissions` (
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
    CONSTRAINT `PK_submissions` PRIMARY KEY (`Id`),
    CONSTRAINT `FK_submissions_gurbaniList_GurbaniId` FOREIGN KEY (`GurbaniId`) REFERENCES `gurbaniList` (`Id`) ON DELETE CASCADE,
    CONSTRAINT `FK_submissions_prizeList_PrizeId` FOREIGN KEY (`PrizeId`) REFERENCES `prizeList` (`Id`) ON DELETE CASCADE,
    CONSTRAINT `FK_submissions_userProfiles_UserProfileId` FOREIGN KEY (`UserProfileId`) REFERENCES `userProfiles` (`Id`) ON DELETE CASCADE,
    CONSTRAINT `FK_submissions_user_UserId` FOREIGN KEY (`UserId`) REFERENCES `user` (`Id`) ON DELETE CASCADE
) CHARACTER SET=utf8mb4;

CREATE TABLE `Dispatches` (
    `Id` bigint NOT NULL AUTO_INCREMENT,
    `SubmissionId` bigint NOT NULL,
    `DocketNumber` longtext CHARACTER SET utf8mb4 NULL,
    `DispatchedAt` datetime(6) NULL,
    `DeliveryStatus` int NOT NULL,
    `DeliveredAt` datetime(6) NULL,
    `CreatedAt` datetime(6) NOT NULL,
    `UpdatedAt` datetime(6) NOT NULL,
    CONSTRAINT `PK_Dispatches` PRIMARY KEY (`Id`),
    CONSTRAINT `FK_Dispatches_submissions_SubmissionId` FOREIGN KEY (`SubmissionId`) REFERENCES `submissions` (`Id`) ON DELETE CASCADE
) CHARACTER SET=utf8mb4;

CREATE INDEX `IX_AuditLogs_CreatedAt` ON `AuditLogs` (`CreatedAt`);

CREATE INDEX `IX_AuditLogs_EntityName` ON `AuditLogs` (`EntityName`);

CREATE UNIQUE INDEX `IX_Dispatches_SubmissionId` ON `Dispatches` (`SubmissionId`);

CREATE INDEX `IX_submissions_GurbaniId` ON `submissions` (`GurbaniId`);

CREATE INDEX `IX_submissions_PrizeId` ON `submissions` (`PrizeId`);

CREATE INDEX `IX_submissions_UserId` ON `submissions` (`UserId`);

CREATE INDEX `IX_submissions_UserProfileId` ON `submissions` (`UserProfileId`);

CREATE UNIQUE INDEX `IX_user_Phone` ON `user` (`Phone`);

CREATE INDEX `IX_userProfiles_UserId` ON `userProfiles` (`UserId`);
CREATE TABLE IF NOT EXISTS `__EFMigrationsHistory` (
    `MigrationId` varchar(150) CHARACTER SET utf8mb4 NOT NULL,
    `ProductVersion` varchar(32) CHARACTER SET utf8mb4 NOT NULL,
    CONSTRAINT `PK___EFMigrationsHistory` PRIMARY KEY (`MigrationId`)
) CHARACTER SET=utf8mb4;
INSERT INTO `__EFMigrationsHistory` (`MigrationId`, `ProductVersion`)
VALUES ('20260717152510_InitialCreate', '9.0.0');

COMMIT;

