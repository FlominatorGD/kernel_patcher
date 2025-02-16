-- phpMyAdmin SQL Dump
-- version 5.2.1deb3
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Erstellungszeit: 16. Feb 2025 um 12:04
-- Server-Version: 10.11.8-MariaDB-0ubuntu0.24.04.1
-- PHP-Version: 8.3.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Datenbank: `exynos7870_v2`
--

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `commits`
--

CREATE TABLE `commits` (
  `commit_hash` varbinary(255) NOT NULL,
  `branch_id` int(11) NOT NULL,
  `author_name` varbinary(255) DEFAULT NULL,
  `author_email` varbinary(255) DEFAULT NULL,
  `author_time` timestamp NOT NULL,
  `committer_name` varbinary(255) DEFAULT NULL,
  `committer_email` varbinary(255) DEFAULT NULL,
  `committer_time` timestamp NOT NULL,
  `summary` varbinary(8192) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=binary;

--
-- Daten für Tabelle `commits`
--

--
-- Indizes der exportierten Tabellen
--

--
-- Indizes für die Tabelle `commits`
--
ALTER TABLE `commits`
  ADD PRIMARY KEY (`commit_hash`,`branch_id`),
  ADD KEY `fk_branch` (`branch_id`),
  ADD KEY `author_time` (`author_time`),
  ADD KEY `committer_time` (`committer_time`),
  ADD KEY `fk_author` (`author_name`,`author_email`),
  ADD KEY `fk_committer` (`committer_name`,`committer_email`),
  ADD KEY `summary` (`summary`(3072));

--
-- Constraints der exportierten Tabellen
--

--
-- Constraints der Tabelle `commits`
--
ALTER TABLE `commits`
  ADD CONSTRAINT `fk_author` FOREIGN KEY (`author_name`,`author_email`) REFERENCES `contributors` (`contributor_name`, `contributor_email`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`branch_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_committer` FOREIGN KEY (`committer_name`,`committer_email`) REFERENCES `contributors` (`contributor_name`, `contributor_email`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
