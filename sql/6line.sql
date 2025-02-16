-- phpMyAdmin SQL Dump
-- version 5.2.1deb3
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Erstellungszeit: 16. Feb 2025 um 12:12
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
-- Tabellenstruktur für Tabelle `line`
--

CREATE TABLE `line` (
  `line` int(8) NOT NULL,
  `branch_id` int(11) NOT NULL,
  `filename` varchar(255) NOT NULL,
  `file_data` varbinary(32767) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `line`
--

--
-- Indizes der exportierten Tabellen
--

--
-- Indizes für die Tabelle `line`
--
ALTER TABLE `line`
  ADD PRIMARY KEY (`line`,`branch_id`,`filename`),
  ADD KEY `branch_id` (`branch_id`);

--
-- Constraints der exportierten Tabellen
--

--
-- Constraints der Tabelle `line`
--
ALTER TABLE `line`
  ADD CONSTRAINT `line_ibfk_1` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`branch_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
