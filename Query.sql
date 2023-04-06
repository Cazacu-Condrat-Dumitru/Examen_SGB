/*CREATE TABLE Aeroporturi (
  cod INT PRIMARY KEY,
  oras VARCHAR(255)
);

CREATE TABLE Zbor_cod (
  cod INT PRIMARY KEY,
  Denumire_aviacompanie VARCHAR(255)
);

CREATE TABLE Zboruri (
  punctplecare INT,
  punctdestinatie INT,
  ora_plecare DATETIME,
  ora_sosire DATETIME,
  cod INT PRIMARY KEY,
  FOREIGN KEY (punctplecare) REFERENCES Aeroporturi(cod),
  FOREIGN KEY (punctdestinatie) REFERENCES Aeroporturi(cod),
  FOREIGN KEY (cod) REFERENCES Zbor_cod(cod)
);

CREATE TABLE Zboruri_disponibile (
  zbor INT,
  data DATE,
  numar_locuri_libere INT,
  pret DECIMAL(10,2),
  PRIMARY KEY (zbor, data),
  FOREIGN KEY (zbor) REFERENCES Zboruri(cod)
);

CREATE TABLE Rezervari (
  cod_rezervare INT PRIMARY KEY AUTO_INCREMENT,
  zbor INT,
  data DATE,
  nume_pasager VARCHAR(255),
  pret DECIMAL(10,2),
  FOREIGN KEY (zbor, data) REFERENCES Zboruri_disponibile(zbor, data)
);
*/
/*
INSERT INTO Aeroporturi (cod, oras) VALUES
  (1, 'Bucuresti'),
  (2, 'Paris'),
  (3, 'Londra'),
   (4, 'Tokyo'),
  (5, 'Madrid');

INSERT INTO Zbor_cod (cod, Denumire_aviacompanie) VALUES
  (1, 'Air France'),
  (2, 'British Airways'),
  (3, 'Lufthansa'),
	(4, 'Ryanair'),
	(5, 'Fluffy');

INSERT INTO Zboruri (punctplecare, punctdestinatie, ora_plecare, ora_sosire, cod) VALUES
  (1, 2, '2023-03-20 10:00:00', '2023-03-20 13:00:00', 1),
  (2, 3, '2023-03-21 09:00:00', '2023-03-21 11:30:00', 2),
  (3, 4, '2023-03-22 14:00:00', '2023-03-22 16:00:00', 3),
    (1, 4, '2023-03-23 15:30:00', '2023-03-23 18:00:00', 4),
  (1, 3, '2023-03-23 15:30:00', '2023-03-23 18:00:00', 5);

INSERT INTO Zboruri_disponibile (zbor, data, numar_locuri_libere, pret) VALUES
  (1, '2023-03-20', 150, 200.00),
  (1, '2023-03-21', 120, 180.00),
  (2, '2023-03-21', 100, 250.00),
  (3, '2023-03-22', 80, 300.00),
  (4, '2023-03-23', 200, 100.00);

INSERT INTO Rezervari (zbor, data, nume_pasager, pret) VALUES
  (1, '2023-03-20', 'Popescu Ion', 200.00),
  (1, '2023-03-21', 'Ionescu Maria', 180.00),
  (2, '2023-03-21', 'Georgescu Alexandru', 250.00),
  (3, '2023-03-22', 'Popa Andreea', 300.00),
  (4, '2023-03-23', 'Constantin Mihai', 100.00);
  */
  /*----------------------Nr3--------------------------------*/
  -- 
--  delimiter $$
--  CREATE PROCEDURE proc1(IN data_zbor DATE, IN punctdestinatie SMALLINT)
--  BEGIN
--  SELECT zbor, numar_locuri_libere
--  FROM zboruri_disponibile
-- INNER JOIN zboruri ON zboruri_disponibile.zbor = zboruri.cod
--  INNER JOIN zbor_cod ON zboruri_disponibile.zbor = zbor_cod.cod
--  WHERE data_zbor = data_zbor AND zbor = punctdestinatie;
--  END $$
-- delimiter ;

/*----------------------Nr4--------------------------------*/

-- DELIMITER $$
-- 
-- CREATE FUNCTION check_connection(oras1 VARCHAR(40), oras2 VARCHAR(40))
-- RETURNS VARCHAR(5)
-- DETERMINISTIC
-- BEGIN
--     DECLARE num_zboruri INT;
-- 
--     SELECT COUNT(*) INTO num_zboruri
--     FROM zboruri
--     INNER JOIN aeroporturi AS a1 ON zboruri.punctplecare = a1.cod
--     INNER JOIN aeroporturi AS a2 ON zboruri.punctdestinatie = a2.cod
--     WHERE a1.oras = oras1 AND a2.oras = oras2;
-- 
--     IF num_zboruri > 0 THEN
--         RETURN "TRUE";
--     ELSE
--         RETURN "FALSE";
--     END IF;
-- END$$
-- 
-- DELIMITER ;

/*----------------------Nr5--------------------------------*/

DELIMITER $$

CREATE PROCEDURE anulare_rezervare(IN cod_rezervare INT)
BEGIN
    DECLARE data_zbor DATE;

    SELECT 
        Zboruri_disponibile.data 
    INTO 
        data_zbor
    FROM 
        Rezervari 
        JOIN Zboruri_disponibile ON 
            Rezervari.zbor = Zboruri_disponibile.zbor AND 
            Rezervari.data = Zboruri_disponibile.data
    WHERE 
        Rezervari.cod_rezervare = cod_rezervare;

    IF data_zbor < DATE_ADD(CURDATE(), INTERVAL 3 DAY) THEN
        SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Anularea nu este permisă cu mai puțin de 3 zile înainte de zbor.';
    ELSE
        DELETE FROM Rezervari WHERE cod_rezervare = cod_rezervare;
        SELECT CONCAT('Anularea a fost efectuată cu succes pentru rezervarea cu codul: ', cod_rezervare) AS 'Rezultat';
    END IF;
END; $$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE anulare_rezervare(IN cod_rezervare INT, OUT mesaj VARCHAR(255))
BEGIN
    DECLARE data_zbor DATE;
    DECLARE zbor_cod INT;

    -- get flight and date from reservation
    SELECT zbor, data INTO zbor_cod, data_zbor FROM Rezervari WHERE cod_rezervare = cod_rezervare;

    -- check if cancellation is allowed
    IF data_zbor < DATE_ADD(CURDATE(), INTERVAL 3 DAY) THEN
        SET mesaj = 'Anularea nu este permisa cu mai putin de 3 zile inainte de zbor.';
    ELSE
        -- increase available seats
        UPDATE Zboruri disponibile SET numar_locuri_libere = numar_locuri_libere + 1 
        WHERE zbor = zbor_cod AND data = data_zbor;

        -- delete reservation
        DELETE FROM Rezervari WHERE cod_rezervare = cod_rezervare;

        -- increase next passenger price
        UPDATE Zboruri disponibile SET pret = pret + 100 
        WHERE zbor = zbor_cod AND data = data_zbor;

        SET mesaj = 'Anularea a fost efectuata cu succes pentru rezervarea cu codul: ' + cod_rezervare;
    END IF;
END; $$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE anulare_rezervare(IN cod_rezervare INT, OUT mesaj VARCHAR(255))
BEGIN
    DECLARE data_zbor DATE;

    -- get flight date from reservation
    SELECT data INTO data_zbor FROM Rezervari WHERE cod_rezervare = cod_rezervare;

    -- check if cancellation is allowed
    IF data_zbor < DATE_ADD(CURDATE(), INTERVAL 3 DAY) THEN
        SET mesaj = 'Anularea nu este permisa cu mai putin de 3 zile inainte de zbor.';
    ELSE
        -- delete reservation
        DELETE FROM Rezervari WHERE cod_rezervare = cod_rezervare;

        SET mesaj = 'Anularea a fost efectuata cu succes pentru rezervarea cu codul: ' + cod_rezervare;
    END IF;
END; $$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE anulare_rezervare(IN cod_rezervare INT, OUT mesaj VARCHAR(255))
BEGIN
    DECLARE data_zbor DATE;
    DECLARE zbor_cod INT;
    DECLARE pret_vechi INT;
    DECLARE pret_nou INT;
    DECLARE locuri_libere INT;

    -- get flight date and flight code from reservation
    SELECT Zboruri_disponibile.data, Zboruri_disponibile.zbor INTO data_zbor, zbor_cod
    FROM Rezervari
    JOIN Zboruri_disponibile ON Rezervari.zbor = Zboruri_disponibile.zbor AND Rezervari.data = Zboruri_disponibile.data
    WHERE Rezervari.cod_rezervare = cod_rezervare;

    -- check if cancellation is allowed
    IF data_zbor < DATE_ADD(CURDATE(), INTERVAL 3 DAY) THEN
        SET mesaj = 'Anularea nu este permisa cu mai putin de 3 zile inainte de zbor.';
    ELSE
        -- get current number of available seats and price
        SELECT numar_locuri_libere, pret INTO locuri_libere, pret_vechi FROM Zboruri_disponibile WHERE zbor = zbor_cod AND data = data_zbor;

        -- increase available seats and price for next passenger
        UPDATE Zboruri_disponibile SET numar_locuri_libere = locuri_libere + 1, pret = pret_vechi + 100 WHERE zbor = zbor_cod AND data = data_zbor;

        -- delete reservation
        DELETE FROM Rezervari WHERE cod_rezervare = cod_rezervare;

        SET mesaj = 'Anularea a fost efectuata cu succes pentru rezervarea cu codul: ' + cod_rezervare;
    END IF;
END; $$

DELIMITER ;