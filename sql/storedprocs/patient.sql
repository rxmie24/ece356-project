--Patient table related procedures
--6.2
DROP PROCEDURE IF EXISTS CreatePatient;
DELIMITER @@
CREATE PROCEDURE CreatePatient
 (IN alias VARCHAR(20),
  IN province VARCHAR(30),
  IN city VARCHAR(50),
  IN first_name VARCHAR(100),
  IN last_name VARCHAR(100),
  IN email VARCHAR(256))
BEGIN

  IF (SELECT EXIST (SELECT address_id 
    FROM patient_address p
    WHERE p.province = province AND p.city = city) = 0) THEN
  INSERT INTO patient_address(
    province
    city
    )
  VALUES (
    province
    city);
  END IF;

  SET @address_id = SELECT address_id 
  FROM patient_address p
  WHERE p.province = province AND p.city = city;

  INSERT INTO patient(
    alias,
    first_name,
    last_name,
    address_id
    email) 
  VALUES (
    alias,
    first_name,
    last_name,
    @address_id
    email);

END @@
DELIMITER ;

--6.3
DROP PROCEDURE IF EXISTS PatientSearch
DELIMITER @@
CREATE PROCEDURE PatientSearch
 (IN alias VARCHAR(20),
  IN province VARCHAR(30),
  IN city VARCHAR(50))
BEGIN

	SELECT
		alias,
		province,
		city,
		count(Review.serial_number) AS num_reviews,
		max(Review.date_time) AS latest_review
	FROM patient
	LEFT JOIN reviews ON patient.alias = reviews.patient_alias
	WHERE
		(alias IS NULL OR patient.alias = alias) AND
		(province IS NULL OR patient.province = province) AND
		(city IS NULL OR patient.city = city)
	GROUP BY patient.alias;

END @@
DELIMITER ;

--6.4
DROP PROCEDURE IF EXISTS AddFriend;
DELIMITER @@
CREATE PROCEDURE AddFriend
  (IN requestor_alias VARCHAR(20),
   IN requestee_alias VARCHAR(20))
BEGIN

  IF SELECT EXISTS(
    SELECT status 
    FROM patient_friends 
    WHERE alias_from = requestee_alias 
    AND alias_to = requestor_alias) = 1 THEN
  UPDATE patient_friends 
  SET status = 1 
  WHERE alias_from = requestee_alias 
    AND alias_to = requestor_alias;

ELSE INSERT INTO patient_friends (
  alias_from, 
  alias_to, 
  status) 
VALUES (
  requestor_alias, 
  requestee_alias, 
  0);
END IF;

END @@
DELIMITER ;

--6.5
DROP PROCEDURE IF EXISTS ViewFriendRequests;
DELIMITER @@
CREATE PROCEDURE ViewFriendRequests
  (IN alias VARCHAR(20))
BEGIN
  /* search for patients who have requested friendship with the given alias but are not yet
  friends with the given alias */
  /* return matching patients as a relation with the attributes alias and email */
  SELECT pf.alias_from, p.email
    FROM patient p
    LEFT JOIN patient_friends pf
      ON pf.requestor_alias = p.alias
    WHERE
      pf.alias_to = alias AND
      pf.status = 0;

END @@
DELIMITER ;

--6.6
DROP PROCEDURE IF EXISTS ViewFriends;
DELIMITER @@
CREATE PROCEDURE ViewFriends
  (IN alias VARCHAR(20))
BEGIN
  /* search for patients who are friends of the given alias */
  /* return matching patients as a relation with the attributes alias and email */
  SELECT p.alias, p.email
    FROM patient p
      WHERE p.alias in (
        SELECT pf.alias_from AS alias
          FROM patient_friends pf
            WHERE pf.alias_to = alias AND
                  pf.status = 1
        UNION
        SELECT pf.alias_to AS alias
          FROM patient_friends pf
            WHERE pf.alias_from = alias AND
                  pf.status = 1
      );
END @@
DELIMITER ;

--6.7
DROP PROCEDURE IF EXISTS AreFriends;
DELIMITER @@
CREATE PROCEDURE AreFriends
  (IN alias1 VARCHAR(20),
   IN alias2 VARCHAR(20),
   OUT are_friends BOOLEAN)
BEGIN
  /* returns true in are_friends if alias1 and alias2 are friends, and false otherwise */
  IF (SELECT status FROM patient_friends pf
        WHERE
        (pf.alias_from = alias2 AND pf.alias_to = alias1)
        OR
        (pf.alias_from = alias1 AND pf.alias_to = alias2)) =  1 THEN
    SELECT TRUE INTO are_friends;
  ELSE
    SELECT FALSE INTO are_friends;
  END IF
END @@
DELIMITER ;
