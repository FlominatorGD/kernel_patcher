-- phpMyAdmin SQL Dump
-- version 5.2.1deb3
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Erstellungszeit: 16. Feb 2025 um 12:05
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
-- Tabellenstruktur für Tabelle `contributors`
--

CREATE TABLE `contributors` (
  `contributor_name` varbinary(255) NOT NULL,
  `contributor_email` varbinary(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=binary;

--
-- Daten für Tabelle `contributors`
--


--
-- Indizes der exportierten Tabellen
--

--
-- Indizes für die Tabelle `contributors`
--
ALTER TABLE `contributors`
  ADD PRIMARY KEY (`contributor_name`,`contributor_email`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
