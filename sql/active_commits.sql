-- phpMyAdmin SQL Dump
-- version 5.2.1deb3
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Erstellungszeit: 16. Feb 2025 um 12:02
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
-- Tabellenstruktur für Tabelle `active_commits`
--

CREATE TABLE `active_commits` (
  `active_commit_id` int(11) NOT NULL,
  `commit_hash` varbinary(255) NOT NULL,
  `line_number` int(11) NOT NULL,
  `branch_id` int(11) NOT NULL,
  `filename` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `active_commits`
--


--
-- Indizes der exportierten Tabellen
--

--
-- Indizes für die Tabelle `active_commits`
--
ALTER TABLE `active_commits`
  ADD PRIMARY KEY (`active_commit_id`),
  ADD KEY `branch_id` (`branch_id`),
  ADD KEY `filename` (`filename`);

--
-- AUTO_INCREMENT für exportierte Tabellen
--

--
-- AUTO_INCREMENT für Tabelle `active_commits`
--
ALTER TABLE `active_commits`
  MODIFY `active_commit_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7255089;

--
-- Constraints der exportierten Tabellen
--

--
-- Constraints der Tabelle `active_commits`
--
ALTER TABLE `active_commits`
  ADD CONSTRAINT `active_commits_ibfk_1` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`branch_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `active_commits_ibfk_2` FOREIGN KEY (`filename`) REFERENCES `files` (`filename`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
