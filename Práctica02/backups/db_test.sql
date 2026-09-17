CREATE DATABASE  IF NOT EXISTS `db_test` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `db_test`;
-- MySQL dump 10.13  Distrib 8.0.36, for Win64 (x86_64)
--
-- Host: localhost    Database: db_test
-- ------------------------------------------------------
-- Server version	8.0.36

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `tb_logs`
--

DROP TABLE IF EXISTS `tb_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_logs` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `table_name` varchar(100) NOT NULL,
  `operation` enum('Create','Read','Update','Delete') NOT NULL,
  `db_user` varchar(80) NOT NULL,
  `description` text,
  `operation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `operation_status` bit(1) DEFAULT b'1',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tb_logs`
--

LOCK TABLES `tb_logs` WRITE;
/*!40000 ALTER TABLE `tb_logs` DISABLE KEYS */;
INSERT INTO `tb_logs` VALUES (1,'tb_users','Create','root@localhost','Usuario creado. ID=5, email=jonny@utxicotepec.edu.mx, nickname=STD-JonnyNH','2026-09-08 11:15:59',_binary ''),(2,'tb_users','Create','root@localhost','Usuario creado. ID=6, email=saul@utxicotepec.edu.mx, nickname=STD-SAULBM','2026-09-08 11:16:26',_binary ''),(3,'tb_users','Create','root@localhost','Usuario creado. ID=8, email=luis@utxicotepec.edu.mx, nickname=STD-LuisCM','2026-09-08 11:17:22',_binary ''),(4,'tb_users','Create','adrian.rios@DESKTOP-ACMHB9I','Usuario creado. ID=9, email=240221@utxicotepec.edu.mx, nickname=ING-CARLOS','2026-09-08 11:41:00',_binary ''),(5,'tb_users','Create','adrian.rios@DESKTOP-ACMHB9I','Usuario creado. ID=10, email=240638@utxicotepec.edu.mx, nickname=ING-Chema','2026-09-08 11:41:28',_binary ''),(6,'tb_users','Create','adrian.rios@DESKTOP-ACMHB9I','Usuario creado. ID=11, email=240165@utxicotepec.edu.mx, nickname=ING-ADRIAN','2026-09-08 11:41:55',_binary ''),(7,'tb_users','Create','juan.reyes@PC-12','Usuario creado. ID=12, email=saulito.barrios@utxicotepec.edu.mx, nickname=Saul','2026-09-09 18:04:08',_binary ''),(8,'tb_users','Create','juan.reyes@PC-12','Usuario creado. ID=13, email=sophia.cazarez@gmail.com, nickname=Sophi','2026-09-09 18:05:57',_binary ''),(9,'tb_users','Create','juan.reyes@PC-12','Usuario creado. ID=14, email=jonhy.lilys@gmail.com, nickname=Cueritos','2026-09-09 18:07:12',_binary ''),(11,'tb_users','Create','juan.reyes@PC-12','Usuario creado. ID=12, email=saulito.barrios@utxicotepec.edu.mx, nickname=Saul_Barrios','2026-09-09 18:14:31',_binary ''),(12,'tb_users','Create','juan.reyes@PC-12','Usuario creado. ID=14, email=jonhy.lilys@gmail.com, nickname=Cueritos','2026-09-09 18:17:26',_binary ''),(13,'tb_users','Update','juan.reyes@PC-12','Usuario actualizado. ID=12 | Email: saulito.barrios@utxicotepec.edu.mx -> saulito.barrios@utxicotepec.edu.mx | Nickname: Saul_Barrios -> Saul_Barrios','2026-09-09 18:21:58',_binary ''),(14,'tb_users','Delete','juan.reyes@PC-12','Usuario eliminado. ID=13, email=sophia.cazarez@gmail.com, nickname=Sophi','2026-09-09 18:22:55',_binary ''),(15,'tb_users','Create','uriel.valenzuela@DESKTOP-TTGCQ98','Usuario creado. ID=15, email=jeansito@gmail.com, nickname=pato34','2026-09-15 11:24:59',_binary ''),(16,'tb_users','Create','uriel.valenzuela@DESKTOP-TTGCQ98','Usuario creado. ID=16, email=juanito@gmail.com, nickname=pato44','2026-09-15 11:25:19',_binary '');
/*!40000 ALTER TABLE `tb_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tb_users`
--

DROP TABLE IF EXISTS `tb_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_users` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `email` varchar(80) NOT NULL,
  `nickname` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_update` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `last_login` datetime DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `nickname` (`nickname`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tb_users`
--

LOCK TABLES `tb_users` WRITE;
/*!40000 ALTER TABLE `tb_users` DISABLE KEYS */;
INSERT INTO `tb_users` VALUES (5,'jonny@utxicotepec.edu.mx','STD-JonnyNH','52dcb810931e20f7aa2f49b3510d3805','2026-09-08 11:15:59','2026-09-09 17:45:44',NULL),(6,'saul@utxicotepec.edu.mx','STD-SAULBM','52dcb810931e20f7aa2f49b3510d3805','2026-09-08 11:16:26','2026-09-09 17:45:44',NULL),(8,'luis@utxicotepec.edu.mx','STD-LuisCM','52dcb810931e20f7aa2f49b3510d3805','2026-09-08 11:17:22','2026-09-09 17:45:44',NULL),(9,'240221@utxicotepec.edu.mx','ING-CARLOS','52dcb810931e20f7aa2f49b3510d3805','2026-09-08 11:41:00','2026-09-09 17:45:44',NULL),(10,'240638@utxicotepec.edu.mx','ING-Chema','827ccb0eea8a706c4c34a16891f84e7b','2026-09-08 11:41:28','2026-09-09 17:45:44',NULL),(11,'240165@utxicotepec.edu.mx','ING-ADRIAN','81dc9bdb52d04dc20036dbd8313ed055','2026-09-08 11:41:55','2026-09-09 17:45:44',NULL),(12,'saulito.barrios@utxicotepec.edu.mx','Saul_Barrios','f180d9521dd923d5835a93f48639d309','2026-09-09 18:04:08','2026-09-09 18:14:31',NULL),(15,'jeansito@gmail.com','pato34','3c5961c7d1531f2e4a0b5a32e9c63e8d','2026-09-15 11:24:59',NULL,NULL),(16,'juanito@gmail.com','pato44','a849f06ab57bce73b75e84b4ea090737','2026-09-15 11:25:19',NULL,NULL);
/*!40000 ALTER TABLE `tb_users` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_users_after_insert` AFTER INSERT ON `tb_users` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        description,
        operation_date,
        operation_status
    )
    VALUES (
        'tb_users',
        'Create',
        USER(),
        CONCAT(
            'Usuario creado. ID=', NEW.ID,
            ', email=', NEW.email,
            ', nickname=', NEW.nickname
        ),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_users_after_update` AFTER UPDATE ON `tb_users` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        description,
        operation_date,
        operation_status
    )
    VALUES (
        'tb_users',
        'Update', 
        USER(),
        CONCAT(
            'Usuario actualizado. ID=', OLD.ID, 
            ' | Email: ', OLD.email, ' -> ', NEW.email, 
            ' | Nickname: ', OLD.nickname, ' -> ', NEW.nickname
        ),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_users_after_delete` AFTER DELETE ON `tb_users` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        description,
        operation_date,
        operation_status
    )
    VALUES (
        'tb_users',
        'Delete', 
        USER(),
        CONCAT(
            'Usuario eliminado. ID=', OLD.ID, 
            ', email=', OLD.email,
            ', nickname=', OLD.nickname
        ),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-15 11:48:56
