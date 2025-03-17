-- phpMyAdmin SQL Dump
-- version 5.2.1deb3
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Erstellungszeit: 17. Mrz 2025 um 22:06
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
-- Datenbank: `kernelv2`
--

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `blame_lines`
--

CREATE TABLE `blame_lines` (
  `branch_id` int(11) NOT NULL,
  `file_id` int(11) NOT NULL,
  `line_nr` int(11) NOT NULL,
  `commit_hash` varchar(64) NOT NULL,
  `commit_line_nr` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `branches`
--

CREATE TABLE `branches` (
  `branch_id` int(11) NOT NULL,
  `branch_name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `branch_commits`
--

CREATE TABLE `branch_commits` (
  `branch_id` int(11) NOT NULL,
  `commit_hash` varchar(64) NOT NULL,
  `file_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `commits`
--

CREATE TABLE `commits` (
  `commit_hash` varchar(64) NOT NULL,
  `author_id` int(11) DEFAULT NULL,
  `committer_id` int(11) DEFAULT NULL,
  `author_time` datetime NOT NULL,
  `committer_time` datetime NOT NULL,
  `summary` varbinary(32768) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `commit_lines`
--

CREATE TABLE `commit_lines` (
  `commit_hash` varchar(64) NOT NULL,
  `file_id` int(11) NOT NULL,
  `line_nr` int(11) NOT NULL,
  `code` varbinary(32768) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `files`
--

CREATE TABLE `files` (
  `file_id` int(11) NOT NULL,
  `filename` varchar(4096) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `name` varbinary(255) DEFAULT NULL,
  `email` varbinary(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indizes der exportierten Tabellen
--

--
-- Indizes für die Tabelle `blame_lines`
--
ALTER TABLE `blame_lines`
  ADD PRIMARY KEY (`branch_id`,`file_id`,`line_nr`),
  ADD KEY `commit_hash` (`commit_hash`,`file_id`,`commit_line_nr`),
  ADD KEY `idx_blame_file_lines` (`file_id`,`line_nr`);

--
-- Indizes für die Tabelle `branches`
--
ALTER TABLE `branches`
  ADD PRIMARY KEY (`branch_id`);

--
-- Indizes für die Tabelle `branch_commits`
--
ALTER TABLE `branch_commits`
  ADD PRIMARY KEY (`branch_id`,`commit_hash`,`file_id`),
  ADD KEY `idx_commit` (`commit_hash`),
  ADD KEY `idx_file` (`file_id`);

--
-- Indizes für die Tabelle `commits`
--
ALTER TABLE `commits`
  ADD PRIMARY KEY (`commit_hash`),
  ADD KEY `author_id` (`author_id`),
  ADD KEY `committer_id` (`committer_id`),
  ADD KEY `idx_commit_times` (`author_time`,`committer_time`);

--
-- Indizes für die Tabelle `commit_lines`
--
ALTER TABLE `commit_lines`
  ADD PRIMARY KEY (`commit_hash`,`file_id`,`line_nr`),
  ADD KEY `file_id` (`file_id`);

--
-- Indizes für die Tabelle `files`
--
ALTER TABLE `files`
  ADD PRIMARY KEY (`file_id`),
  ADD UNIQUE KEY `unique_filename` (`filename`) USING HASH;

--
-- Indizes für die Tabelle `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `unique_user` (`name`,`email`);

--
-- AUTO_INCREMENT für exportierte Tabellen
--

--
-- AUTO_INCREMENT für Tabelle `files`
--
ALTER TABLE `files`
  MODIFY `file_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT für Tabelle `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints der exportierten Tabellen
--

--
-- Constraints der Tabelle `blame_lines`
--
ALTER TABLE `blame_lines`
  ADD CONSTRAINT `blame_lines_ibfk_1` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`branch_id`),
  ADD CONSTRAINT `blame_lines_ibfk_2` FOREIGN KEY (`file_id`) REFERENCES `files` (`file_id`),
  ADD CONSTRAINT `blame_lines_ibfk_3` FOREIGN KEY (`commit_hash`,`file_id`,`commit_line_nr`) REFERENCES `commit_lines` (`commit_hash`, `file_id`, `line_nr`);

--
-- Constraints der Tabelle `branch_commits`
--
ALTER TABLE `branch_commits`
  ADD CONSTRAINT `branch_commits_ibfk_1` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`branch_id`),
  ADD CONSTRAINT `branch_commits_ibfk_2` FOREIGN KEY (`commit_hash`) REFERENCES `commits` (`commit_hash`),
  ADD CONSTRAINT `branch_commits_ibfk_3` FOREIGN KEY (`file_id`) REFERENCES `files` (`file_id`);

--
-- Constraints der Tabelle `commits`
--
ALTER TABLE `commits`
  ADD CONSTRAINT `commits_ibfk_1` FOREIGN KEY (`author_id`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `commits_ibfk_2` FOREIGN KEY (`committer_id`) REFERENCES `users` (`user_id`);

--
-- Constraints der Tabelle `commit_lines`
--
ALTER TABLE `commit_lines`
  ADD CONSTRAINT `commit_lines_ibfk_1` FOREIGN KEY (`commit_hash`) REFERENCES `commits` (`commit_hash`),
  ADD CONSTRAINT `commit_lines_ibfk_2` FOREIGN KEY (`file_id`) REFERENCES `files` (`file_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
