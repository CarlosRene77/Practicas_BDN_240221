CREATE DATABASE  IF NOT EXISTS `db_test` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `db_test`;
-- MySQL dump 10.13  Distrib 8.0.36, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: db_test
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
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tb_logs`
--

LOCK TABLES `tb_logs` WRITE;
/*!40000 ALTER TABLE `tb_logs` DISABLE KEYS */;
INSERT INTO `tb_logs` VALUES (1,'tb_users','Create','root@localhost','Usuario creado. ID=5, email=jonny@utxicotepec.edu.mx, nickname=STD-JonnyNH','2026-09-08 11:15:59',_binary ''),(2,'tb_users','Create','root@localhost','Usuario creado. ID=6, email=saul@utxicotepec.edu.mx, nickname=STD-SAULBM','2026-09-08 11:16:26',_binary ''),(3,'tb_users','Create','root@localhost','Usuario creado. ID=8, email=luis@utxicotepec.edu.mx, nickname=STD-LuisCM','2026-09-08 11:17:22',_binary ''),(4,'tb_users','Create','adrian.rios@DESKTOP-ACMHB9I','Usuario creado. ID=9, email=240221@utxicotepec.edu.mx, nickname=ING-CARLOS','2026-09-08 11:41:00',_binary ''),(5,'tb_users','Create','adrian.rios@DESKTOP-ACMHB9I','Usuario creado. ID=10, email=240638@utxicotepec.edu.mx, nickname=ING-Chema','2026-09-08 11:41:28',_binary ''),(6,'tb_users','Create','adrian.rios@DESKTOP-ACMHB9I','Usuario creado. ID=11, email=240165@utxicotepec.edu.mx, nickname=ING-ADRIAN','2026-09-08 11:41:55',_binary ''),(7,'tb_users','Create','juan.reyes@PC-12','Usuario creado. ID=12, email=saulito.barrios@utxicotepec.edu.mx, nickname=Saul','2026-09-09 18:04:08',_binary ''),(8,'tb_users','Create','juan.reyes@PC-12','Usuario creado. ID=13, email=sophia.cazarez@gmail.com, nickname=Sophi','2026-09-09 18:05:57',_binary ''),(9,'tb_users','Create','juan.reyes@PC-12','Usuario creado. ID=14, email=jonhy.lilys@gmail.com, nickname=Cueritos','2026-09-09 18:07:12',_binary ''),(11,'tb_users','Create','juan.reyes@PC-12','Usuario creado. ID=12, email=saulito.barrios@utxicotepec.edu.mx, nickname=Saul_Barrios','2026-09-09 18:14:31',_binary ''),(12,'tb_users','Create','juan.reyes@PC-12','Usuario creado. ID=14, email=jonhy.lilys@gmail.com, nickname=Cueritos','2026-09-09 18:17:26',_binary ''),(13,'tb_users','Update','juan.reyes@PC-12','Usuario actualizado. ID=12 | Email: saulito.barrios@utxicotepec.edu.mx -> saulito.barrios@utxicotepec.edu.mx | Nickname: Saul_Barrios -> Saul_Barrios','2026-09-09 18:21:58',_binary ''),(14,'tb_users','Delete','juan.reyes@PC-12','Usuario eliminado. ID=13, email=sophia.cazarez@gmail.com, nickname=Sophi','2026-09-09 18:22:55',_binary ''),(15,'tb_users','Create','uriel.valenzuela@DESKTOP-TTGCQ98','Usuario creado. ID=15, email=jeansito@gmail.com, nickname=pato34','2026-09-15 11:24:59',_binary ''),(16,'tb_users','Create','uriel.valenzuela@DESKTOP-TTGCQ98','Usuario creado. ID=16, email=juanito@gmail.com, nickname=pato44','2026-09-15 11:25:19',_binary ''),(17,'tb_products','Create','root@localhost','Producto creado. ID=1, SKU=SKU-001, name=Camisa Casual de Algodón','2026-09-22 11:09:29',_binary ''),(18,'tb_products','Create','root@localhost','Producto creado. ID=2, SKU=SKU-002, name=Pantalón Deportivo Jogger','2026-09-22 11:09:29',_binary ''),(19,'tb_products','Create','pablo.reyes@PC-16','Producto creado. ID=8, SKU=SKU-008, name=Audífonos Inalámbricos ANC','2026-09-22 11:12:45',_binary ''),(20,'tb_products','Create','pablo.reyes@PC-16','Producto creado. ID=9, SKU=SKU-009, name=Monitor Curvo 27\" 144Hz','2026-09-22 11:12:45',_binary ''),(21,'tb_products','Create','pablo.reyes@PC-16','Producto creado. ID=10, SKU=SKU-010, name=Teclado Mecanico 65% Wireless','2026-09-22 11:12:45',_binary ''),(22,'tb_products','Create','pablo.reyes@PC-16','Producto creado. ID=11, SKU=SKU-011, name=Mousepad con Carga Qi','2026-09-22 11:12:45',_binary ''),(23,'tb_products','Create','pablo.reyes@PC-16','Producto creado. ID=12, SKU=SKU-012, name=SSD NVMe 1TB PCIe 4.0','2026-09-22 11:12:45',_binary '');
/*!40000 ALTER TABLE `tb_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tb_products`
--

DROP TABLE IF EXISTS `tb_products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_products` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `SKU` varchar(50) NOT NULL,
  `name` varchar(250) NOT NULL,
  `description` text,
  `current_price` decimal(10,2) NOT NULL DEFAULT '0.00',
  `current_stock` int unsigned NOT NULL DEFAULT '0',
  `status` bit(1) DEFAULT b'1',
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_update` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `SKU` (`SKU`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tb_products`
--

LOCK TABLES `tb_products` WRITE;
/*!40000 ALTER TABLE `tb_products` DISABLE KEYS */;
INSERT INTO `tb_products` VALUES (1,'SKU-001','Camisa Casual de Algodón','Camisa de manga larga para caballero, 100% algodón.',29.99,50,_binary '','2026-09-22 11:02:10','2026-09-22 11:02:10'),(2,'SKU-002','Pantalón Deportivo Jogger','Pantalón cómodo para ejercicio y uso diario.',39.50,30,_binary '','2026-09-22 11:02:10','2026-09-22 11:02:10'),(3,'SKU-003','Chamarra Puffer Impermeable','Chamarra con aislamiento térmico y acabado repelente al agua.',79.99,20,_binary '','2026-09-22 11:04:05','2026-09-22 11:04:05'),(4,'SKU-004','Suter de Lana Merino','Suter ligero de cuello redondo ideal para clima templado.',49.99,25,_binary '','2026-09-22 11:04:05','2026-09-22 11:04:05'),(5,'SKU-005','Shorts de Running','Shorts ligeros con forro interno y bolsa con cierre para celular.',24.50,40,_binary '','2026-09-22 11:04:05','2026-09-22 11:04:05'),(6,'SKU-006','Playera Básica de Cuello V','Playera de algodón peinado corte slim fit en tono neutro.',19.99,60,_binary '','2026-09-22 11:04:05','2026-09-22 11:04:05'),(7,'SKU-007','Blazer Casual Slim','Blazer estructurado en mezcla de lino para ocasiones semiformales.',89.00,15,_binary '','2026-09-22 11:04:05','2026-09-22 11:04:05'),(8,'SKU-008','Audífonos Inalámbricos ANC','Audífonos circumauriculares con cancelación activa de ruido y 30h de batería.',149.99,15,_binary '','2026-09-22 11:12:45','2026-09-22 11:12:45'),(9,'SKU-009','Monitor Curvo 27\" 144Hz','Monitor gaming WQHD con panel VA y tiempo de respuesta de 1ms.',299.50,10,_binary '','2026-09-22 11:12:45','2026-09-22 11:12:45'),(10,'SKU-010','Teclado Mecanico 65% Wireless','Teclado mecánico ultra compacto con triple modo de conexión (Bluetooth, 2.4GHz, USB-C).',89.99,25,_binary '','2026-09-22 11:12:45','2026-09-22 11:12:45'),(11,'SKU-011','Mousepad con Carga Qi','Alfombrilla de escritorio rígida con cargador inalámbrico integrado para smartphone.',45.00,30,_binary '','2026-09-22 11:12:45','2026-09-22 11:12:45'),(12,'SKU-012','SSD NVMe 1TB PCIe 4.0','Unidad de estado sólido de alta velocidad de lectura hasta 7000 MB/s.',79.99,40,_binary '','2026-09-22 11:12:45','2026-09-22 11:12:45');
/*!40000 ALTER TABLE `tb_products` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_products_after_insert` AFTER INSERT ON `tb_products` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        description,
        operation_date,
        operation_status
    )
    VALUES (
        'tb_products',
        'Create',
        USER(),
        CONCAT('Producto creado. ID=', NEW.ID, ', SKU=', NEW.SKU, ', name=', NEW.name),
        NOW(),
        1
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

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

-- Dump completed on 2026-09-22 11:45:21
