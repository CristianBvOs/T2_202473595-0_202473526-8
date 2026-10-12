DROP DATABASE IF EXISTS salud_usm;
CREATE DATABASE salud_usm
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE salud_usm;

SET NAMES utf8mb4;

CREATE TABLE rol (
    id_rol      INT          NOT NULL AUTO_INCREMENT,
    nombre      VARCHAR(20)  NOT NULL,
    CONSTRAINT pk_rol PRIMARY KEY (id_rol),
    CONSTRAINT uq_rol_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

CREATE TABLE region (
    id_region   INT          NOT NULL AUTO_INCREMENT,
    nombre      VARCHAR(60)  NOT NULL,
    CONSTRAINT pk_region PRIMARY KEY (id_region),
    CONSTRAINT uq_region_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

CREATE TABLE comuna (
    id_comuna   INT          NOT NULL AUTO_INCREMENT,
    nombre      VARCHAR(60)  NOT NULL,
    id_region   INT          NOT NULL,
    CONSTRAINT pk_comuna PRIMARY KEY (id_comuna),
    CONSTRAINT uq_comuna_nombre UNIQUE (nombre),
    CONSTRAINT fk_comuna_region FOREIGN KEY (id_region)
        REFERENCES region (id_region)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE prevision (
    id_prevision INT         NOT NULL AUTO_INCREMENT,
    nombre       VARCHAR(20) NOT NULL,
    CONSTRAINT pk_prevision PRIMARY KEY (id_prevision),
    CONSTRAINT uq_prevision_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

CREATE TABLE especialidad (
    id_especialidad INT         NOT NULL AUTO_INCREMENT,
    nombre          VARCHAR(40) NOT NULL,
    CONSTRAINT pk_especialidad PRIMARY KEY (id_especialidad),
    CONSTRAINT uq_especialidad_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

CREATE TABLE estado_cita (
    id_estado   INT          NOT NULL AUTO_INCREMENT,
    nombre      VARCHAR(20)  NOT NULL,
    CONSTRAINT pk_estado_cita PRIMARY KEY (id_estado),
    CONSTRAINT uq_estado_cita_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

CREATE TABLE diagnostico (
    id_diagnostico INT          NOT NULL AUTO_INCREMENT,
    codigo_cie10   VARCHAR(10)  NOT NULL,
    descripcion    VARCHAR(120) NOT NULL,
    CONSTRAINT pk_diagnostico PRIMARY KEY (id_diagnostico),
    CONSTRAINT uq_diagnostico_codigo UNIQUE (codigo_cie10)
) ENGINE=InnoDB;

CREATE TABLE usuario (
    rut             VARCHAR(12)  NOT NULL,
    nombre          VARCHAR(80)  NOT NULL,
    email           VARCHAR(100) NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    id_rol          INT          NOT NULL,
    fecha_registro  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_usuario PRIMARY KEY (rut),
    CONSTRAINT uq_usuario_email UNIQUE (email),
    CONSTRAINT ck_usuario_rut CHECK (rut REGEXP '^[0-9]{7,8}-[0-9Kk]$'),
    CONSTRAINT fk_usuario_rol FOREIGN KEY (id_rol)
        REFERENCES rol (id_rol)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE paciente (
    rut              VARCHAR(12) NOT NULL,
    fecha_nacimiento DATE        NOT NULL,
    sexo             CHAR(1)     NOT NULL,
    telefono         VARCHAR(20)     NULL,
    id_comuna        INT         NOT NULL,
    id_prevision     INT         NOT NULL,
    CONSTRAINT pk_paciente PRIMARY KEY (rut),
    CONSTRAINT ck_paciente_sexo CHECK (sexo IN ('M','F','O')),
    CONSTRAINT fk_paciente_usuario FOREIGN KEY (rut)
        REFERENCES usuario (rut)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_paciente_comuna FOREIGN KEY (id_comuna)
        REFERENCES comuna (id_comuna)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_paciente_prevision FOREIGN KEY (id_prevision)
        REFERENCES prevision (id_prevision)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE medico (
    rut            VARCHAR(12) NOT NULL,
    fecha_ingreso  DATE        NOT NULL,
    CONSTRAINT pk_medico PRIMARY KEY (rut),
    CONSTRAINT fk_medico_usuario FOREIGN KEY (rut)
        REFERENCES usuario (rut)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE centro_medico (
    id_centro   INT          NOT NULL AUTO_INCREMENT,
    codigo      VARCHAR(10)  NOT NULL,
    nombre      VARCHAR(80)  NOT NULL,
    id_comuna   INT          NOT NULL,
    CONSTRAINT pk_centro_medico PRIMARY KEY (id_centro),
    CONSTRAINT uq_centro_codigo UNIQUE (codigo),
    CONSTRAINT fk_centro_comuna FOREIGN KEY (id_comuna)
        REFERENCES comuna (id_comuna)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE medico_especialidad (
    rut_medico      VARCHAR(12) NOT NULL,
    id_especialidad INT         NOT NULL,
    CONSTRAINT pk_medico_especialidad PRIMARY KEY (rut_medico, id_especialidad),
    CONSTRAINT fk_medesp_medico FOREIGN KEY (rut_medico)
        REFERENCES medico (rut)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_medesp_especialidad FOREIGN KEY (id_especialidad)
        REFERENCES especialidad (id_especialidad)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE medico_centro (
    rut_medico  VARCHAR(12) NOT NULL,
    id_centro   INT         NOT NULL,
    CONSTRAINT pk_medico_centro PRIMARY KEY (rut_medico, id_centro),
    CONSTRAINT fk_medcen_medico FOREIGN KEY (rut_medico)
        REFERENCES medico (rut)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_medcen_centro FOREIGN KEY (id_centro)
        REFERENCES centro_medico (id_centro)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE cita (
    id_cita         INT         NOT NULL AUTO_INCREMENT,
    fecha           DATE        NOT NULL,
    hora_inicio     TIME        NOT NULL,
    hora_fin        TIME        NOT NULL,
    rut_paciente    VARCHAR(12) NOT NULL,
    rut_medico      VARCHAR(12) NOT NULL,
    id_especialidad INT         NOT NULL,
    id_centro       INT         NOT NULL,
    id_estado       INT         NOT NULL,
    CONSTRAINT pk_cita PRIMARY KEY (id_cita),
    CONSTRAINT ck_cita_horario CHECK (hora_fin > hora_inicio),

    KEY ix_cita_bloque_medico   (rut_medico, fecha, hora_inicio),
    KEY ix_cita_bloque_paciente (rut_paciente, fecha, hora_inicio),

    CONSTRAINT fk_cita_paciente FOREIGN KEY (rut_paciente)
        REFERENCES paciente (rut)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_cita_estado FOREIGN KEY (id_estado)
        REFERENCES estado_cita (id_estado)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_cita_curriculum FOREIGN KEY (rut_medico, id_especialidad)
        REFERENCES medico_especialidad (rut_medico, id_especialidad)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_cita_contrato FOREIGN KEY (rut_medico, id_centro)
        REFERENCES medico_centro (rut_medico, id_centro)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE INDEX ix_cita_fecha  ON cita (fecha);
CREATE INDEX ix_cita_estado ON cita (id_estado);
CREATE INDEX ix_cita_centro ON cita (id_centro);

CREATE TABLE atencion (
    id_atencion    INT          NOT NULL AUTO_INCREMENT,
    id_cita        INT          NOT NULL,
    motivo         VARCHAR(200) NOT NULL,
    observaciones  TEXT             NULL,
    fecha_registro DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_atencion PRIMARY KEY (id_atencion),
    CONSTRAINT uq_atencion_cita UNIQUE (id_cita),
    CONSTRAINT fk_atencion_cita FOREIGN KEY (id_cita)
        REFERENCES cita (id_cita)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE atencion_diagnostico (
    id_atencion    INT NOT NULL,
    id_diagnostico INT NOT NULL,
    CONSTRAINT pk_atencion_diagnostico PRIMARY KEY (id_atencion, id_diagnostico),
    CONSTRAINT fk_atdiag_atencion FOREIGN KEY (id_atencion)
        REFERENCES atencion (id_atencion)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_atdiag_diagnostico FOREIGN KEY (id_diagnostico)
        REFERENCES diagnostico (id_diagnostico)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE receta (
    id_receta        INT          NOT NULL AUTO_INCREMENT,
    id_atencion      INT          NOT NULL,
    medicamento      VARCHAR(80)  NOT NULL,
    dosis            VARCHAR(60)  NOT NULL,
    dias_tratamiento INT          NOT NULL,
    CONSTRAINT pk_receta PRIMARY KEY (id_receta),
    CONSTRAINT ck_receta_dias CHECK (dias_tratamiento > 0),
    CONSTRAINT fk_receta_atencion FOREIGN KEY (id_atencion)
        REFERENCES atencion (id_atencion)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE INDEX ix_receta_atencion ON receta (id_atencion);

CREATE OR REPLACE VIEW vw_cita_detalle AS
SELECT  c.id_cita,
        c.fecha,
        c.hora_inicio,
        c.hora_fin,
        c.rut_paciente,
        up.nombre        AS paciente,
        pa.id_prevision,
        pv.nombre        AS prevision,
        c.rut_medico,
        um.nombre        AS medico,
        c.id_especialidad,
        es.nombre        AS especialidad,
        c.id_centro,
        ce.nombre        AS centro,
        co.id_comuna,
        co.nombre        AS comuna,
        re.id_region,
        re.nombre        AS region,
        c.id_estado,
        st.nombre        AS estado,
        a.id_atencion
FROM        cita          c
JOIN        paciente      pa ON pa.rut = c.rut_paciente
JOIN        usuario       up ON up.rut = pa.rut
JOIN        prevision     pv ON pv.id_prevision = pa.id_prevision
JOIN        usuario       um ON um.rut = c.rut_medico
JOIN        especialidad  es ON es.id_especialidad = c.id_especialidad
JOIN        centro_medico ce ON ce.id_centro = c.id_centro
JOIN        comuna        co ON co.id_comuna = ce.id_comuna
JOIN        region        re ON re.id_region = co.id_region
JOIN        estado_cita   st ON st.id_estado = c.id_estado
LEFT JOIN   atencion      a  ON a.id_cita = c.id_cita;

CREATE OR REPLACE VIEW vw_atencion_detalle AS
SELECT  a.id_atencion,
        a.id_cita,
        a.motivo,
        a.observaciones,
        a.fecha_registro,
        v.fecha,
        v.hora_inicio,
        v.rut_paciente,
        v.paciente,
        v.prevision,
        v.rut_medico,
        v.medico,
        v.especialidad,
        v.centro
FROM    atencion        a
JOIN    vw_cita_detalle v ON v.id_cita = a.id_cita;

DELIMITER $$

CREATE FUNCTION fn_porcentaje_inasistencia(p_id_centro INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
    DECLARE v_total INT DEFAULT 0;
    DECLARE v_no_asistio INT DEFAULT 0;

    SELECT COUNT(*) INTO v_total
    FROM   cita
    WHERE  id_centro = p_id_centro;

    IF v_total = 0 THEN
        RETURN 0.00;
    END IF;

    SELECT COUNT(*) INTO v_no_asistio
    FROM   cita c
    JOIN   estado_cita e ON e.id_estado = c.id_estado
    WHERE  c.id_centro = p_id_centro
      AND  e.nombre = 'No Asistió';

    RETURN ROUND(100 * v_no_asistio / v_total, 2);
END$$

CREATE FUNCTION fn_cita_modificable(p_id_cita INT)
RETURNS TINYINT
READS SQL DATA
BEGIN
    DECLARE v_ok TINYINT DEFAULT 0;

    SELECT COUNT(*) INTO v_ok
    FROM   cita c
    JOIN   estado_cita e ON e.id_estado = c.id_estado
    WHERE  c.id_cita = p_id_cita
      AND  e.nombre IN ('Reservada','Confirmada')
      AND  (c.fecha > CURDATE()
            OR (c.fecha = CURDATE() AND c.hora_inicio > CURTIME()));

    RETURN v_ok;
END$$

CREATE TRIGGER trg_cita_bi
BEFORE INSERT ON cita
FOR EACH ROW
BEGIN
    DECLARE v_choque INT DEFAULT 0;

    SELECT COUNT(*) INTO v_choque
    FROM   cita c
    JOIN   estado_cita e ON e.id_estado = c.id_estado
    WHERE  c.rut_medico  = NEW.rut_medico
      AND  c.fecha       = NEW.fecha
      AND  c.hora_inicio = NEW.hora_inicio
      AND  e.nombre IN ('Reservada','Confirmada','Atendida');

    IF v_choque > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El medico ya tiene una cita activa en ese bloque horario.';
    END IF;

    SELECT COUNT(*) INTO v_choque
    FROM   cita c
    JOIN   estado_cita e ON e.id_estado = c.id_estado
    WHERE  c.rut_paciente = NEW.rut_paciente
      AND  c.fecha        = NEW.fecha
      AND  c.hora_inicio  = NEW.hora_inicio
      AND  e.nombre IN ('Reservada','Confirmada','Atendida');

    IF v_choque > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El paciente ya tiene otra cita a esa misma fecha y hora.';
    END IF;
END$$

CREATE TRIGGER trg_cita_bu
BEFORE UPDATE ON cita
FOR EACH ROW
BEGIN
    DECLARE v_choque       INT DEFAULT 0;
    DECLARE v_activa_nueva INT DEFAULT 0;
    DECLARE v_activa_vieja INT DEFAULT 0;

    SELECT COUNT(*) INTO v_activa_nueva
    FROM   estado_cita
    WHERE  id_estado = NEW.id_estado
      AND  nombre IN ('Reservada','Confirmada','Atendida');

    SELECT COUNT(*) INTO v_activa_vieja
    FROM   estado_cita
    WHERE  id_estado = OLD.id_estado
      AND  nombre IN ('Reservada','Confirmada','Atendida');

    IF v_activa_nueva > 0
       AND (NEW.fecha        <> OLD.fecha
            OR NEW.hora_inicio <> OLD.hora_inicio
            OR NEW.rut_medico  <> OLD.rut_medico
            OR NEW.rut_paciente <> OLD.rut_paciente
            OR v_activa_vieja = 0) THEN

        SELECT COUNT(*) INTO v_choque
        FROM   cita c
        JOIN   estado_cita e ON e.id_estado = c.id_estado
        WHERE  c.id_cita    <> NEW.id_cita
          AND  c.rut_medico  = NEW.rut_medico
          AND  c.fecha       = NEW.fecha
          AND  c.hora_inicio = NEW.hora_inicio
          AND  e.nombre IN ('Reservada','Confirmada','Atendida');

        IF v_choque > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El medico ya tiene una cita activa en ese bloque horario.';
        END IF;

        SELECT COUNT(*) INTO v_choque
        FROM   cita c
        JOIN   estado_cita e ON e.id_estado = c.id_estado
        WHERE  c.id_cita     <> NEW.id_cita
          AND  c.rut_paciente = NEW.rut_paciente
          AND  c.fecha        = NEW.fecha
          AND  c.hora_inicio  = NEW.hora_inicio
          AND  e.nombre IN ('Reservada','Confirmada','Atendida');

        IF v_choque > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El paciente ya tiene otra cita a esa misma fecha y hora.';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_atencion_bi
BEFORE INSERT ON atencion
FOR EACH ROW
BEGIN
    DECLARE v_estado VARCHAR(20);

    SELECT e.nombre INTO v_estado
    FROM   cita c
    JOIN   estado_cita e ON e.id_estado = c.id_estado
    WHERE  c.id_cita = NEW.id_cita;

    IF v_estado IS NULL OR v_estado <> 'Atendida' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Solo se puede registrar la atencion de una cita en estado Atendida.';
    END IF;
END$$

CREATE TRIGGER trg_medesp_max_tres
BEFORE INSERT ON medico_especialidad
FOR EACH ROW
BEGIN
    DECLARE v_total INT DEFAULT 0;

    SELECT COUNT(*) INTO v_total
    FROM   medico_especialidad
    WHERE  rut_medico = NEW.rut_medico;

    IF v_total >= 3 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Un medico no puede tener mas de 3 especialidades.';
    END IF;
END$$

CREATE PROCEDURE sp_agendar_cita(
    IN  p_rut_paciente    VARCHAR(12),
    IN  p_rut_medico      VARCHAR(12),
    IN  p_id_especialidad INT,
    IN  p_id_centro       INT,
    IN  p_fecha           DATE,
    IN  p_hora            TIME,
    OUT p_id_cita         INT
)
BEGIN
    DECLARE v_n INT DEFAULT 0;

    IF p_fecha < CURDATE()
       OR (p_fecha = CURDATE() AND p_hora <= CURTIME()) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede agendar una hora en el pasado.';
    END IF;

    IF DAYOFWEEK(p_fecha) IN (1, 7) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La red SaludUSM atiende solo de lunes a viernes.';
    END IF;

    IF p_hora < '09:00:00' OR p_hora > '17:30:00' OR MINUTE(p_hora) NOT IN (0, 30) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Bloque invalido: la atencion es de 09:00 a 18:00 en bloques de 30 minutos.';
    END IF;

    SELECT COUNT(*) INTO v_n
    FROM   medico_especialidad
    WHERE  rut_medico = p_rut_medico AND id_especialidad = p_id_especialidad;

    IF v_n = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El medico seleccionado no posee la especialidad solicitada.';
    END IF;

    SELECT COUNT(*) INTO v_n
    FROM   medico_centro
    WHERE  rut_medico = p_rut_medico AND id_centro = p_id_centro;

    IF v_n = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El medico seleccionado no atiende en ese centro medico.';
    END IF;

    INSERT INTO cita (fecha, hora_inicio, hora_fin, rut_paciente,
                      rut_medico, id_especialidad, id_centro, id_estado)
    VALUES (p_fecha,
            p_hora,
            ADDTIME(p_hora, '00:30:00'),
            p_rut_paciente,
            p_rut_medico,
            p_id_especialidad,
            p_id_centro,
            (SELECT id_estado FROM estado_cita WHERE nombre = 'Reservada'));

    SET p_id_cita = LAST_INSERT_ID();
END$$

CREATE PROCEDURE sp_reprogramar_cita(
    IN p_id_cita INT,
    IN p_fecha   DATE,
    IN p_hora    TIME
)
BEGIN
    IF fn_cita_modificable(p_id_cita) = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Solo se pueden reprogramar citas Reservadas o Confirmadas cuya fecha no haya pasado.';
    END IF;

    IF p_fecha < CURDATE()
       OR (p_fecha = CURDATE() AND p_hora <= CURTIME()) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede reprogramar una hora al pasado.';
    END IF;

    IF DAYOFWEEK(p_fecha) IN (1, 7) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La red SaludUSM atiende solo de lunes a viernes.';
    END IF;

    IF p_hora < '09:00:00' OR p_hora > '17:30:00' OR MINUTE(p_hora) NOT IN (0, 30) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Bloque invalido: la atencion es de 09:00 a 18:00 en bloques de 30 minutos.';
    END IF;

    UPDATE cita
    SET    fecha       = p_fecha,
           hora_inicio = p_hora,
           hora_fin    = ADDTIME(p_hora, '00:30:00')
    WHERE  id_cita     = p_id_cita;
END$$

CREATE PROCEDURE sp_cancelar_citas_vencidas()
BEGIN
    UPDATE cita
    SET    id_estado = (SELECT id_estado FROM estado_cita WHERE nombre = 'Cancelada')
    WHERE  fecha < CURDATE()
      AND  id_estado IN (SELECT id_estado FROM estado_cita
                         WHERE nombre IN ('Reservada','Confirmada'));
END$$

DELIMITER ;

INSERT INTO rol (id_rol, nombre) VALUES
  (1, 'Paciente'),
  (2, 'Medico'),
  (3, 'Administrador');

INSERT INTO region (id_region, nombre) VALUES
  (1, 'Región de Valparaíso'),
  (2, 'Región Metropolitana'),
  (3, 'Región de Coquimbo');

INSERT INTO comuna (id_comuna, nombre, id_region) VALUES
  (1, 'Valparaíso', 1),
  (2, 'Viña del Mar', 1),
  (3, 'Quilpué', 1),
  (4, 'Villa Alemana', 1),
  (5, 'San Antonio', 1),
  (6, 'Santiago', 2),
  (7, 'Maipú', 2),
  (8, 'Ñuñoa', 2),
  (9, 'Puente Alto', 2),
  (10, 'La Florida', 2),
  (11, 'La Serena', 3),
  (12, 'Coquimbo', 3);

INSERT INTO prevision (id_prevision, nombre) VALUES
  (1, 'Fonasa'),
  (2, 'Isapre'),
  (3, 'Particular');

INSERT INTO estado_cita (id_estado, nombre) VALUES
  (1, 'Reservada'),
  (2, 'Confirmada'),
  (3, 'Atendida'),
  (4, 'No Asistió'),
  (5, 'Cancelada');

INSERT INTO especialidad (id_especialidad, nombre) VALUES
  (1, 'Medicina General'),
  (2, 'Cardiología'),
  (3, 'Pediatría'),
  (4, 'Traumatología'),
  (5, 'Dermatología'),
  (6, 'Ginecología'),
  (7, 'Neurología'),
  (8, 'Oftalmología'),
  (9, 'Otorrinolaringología'),
  (10, 'Psiquiatría');

INSERT INTO diagnostico (id_diagnostico, codigo_cie10, descripcion) VALUES
  (1, 'J00', 'Rinofaringitis aguda (resfrío común)'),
  (2, 'I10', 'Hipertensión esencial (primaria)'),
  (3, 'E11', 'Diabetes mellitus tipo 2'),
  (4, 'M54', 'Dorsalgia'),
  (5, 'J45', 'Asma'),
  (6, 'L20', 'Dermatitis atópica'),
  (7, 'H52', 'Trastornos de la acomodación y de la refracción'),
  (8, 'G43', 'Migraña'),
  (9, 'K21', 'Enfermedad por reflujo gastroesofágico'),
  (10, 'M17', 'Gonartrosis (artrosis de rodilla)'),
  (11, 'A09', 'Gastroenteritis de presunto origen infeccioso'),
  (12, 'N39', 'Infección de vías urinarias de sitio no especificado'),
  (13, 'F41', 'Trastornos de ansiedad'),
  (14, 'H66', 'Otitis media supurativa'),
  (15, 'J02', 'Faringitis aguda'),
  (16, 'E78', 'Trastornos del metabolismo de las lipoproteínas'),
  (17, 'M79', 'Reumatismo no especificado'),
  (18, 'L30', 'Otras dermatitis'),
  (19, 'R51', 'Cefalea'),
  (20, 'I48', 'Fibrilación y aleteo auricular');

INSERT INTO centro_medico (id_centro, codigo, nombre, id_comuna) VALUES
  (1, 'CM-001', 'CESFAM SaludUSM Valparaíso', 1),
  (2, 'CM-002', 'Centro Médico SaludUSM Viña del Mar', 2),
  (3, 'CM-003', 'Centro Médico SaludUSM Santiago Centro', 6),
  (4, 'CM-004', 'CESFAM SaludUSM Maipú', 7),
  (5, 'CM-005', 'Centro Médico SaludUSM La Serena', 11);

INSERT INTO usuario (rut, nombre, email, password_hash, id_rol) VALUES
  ('11111111-1', 'Gonzalo Alarcón Carrasco', 'admin@saludusm.cl', '$2y$10$IWHiabdMTM2/sFchDC1Tmee4EdNxu9dT2ANPgQR858ynU51iDzLxy', 3),
  ('10111222-5', 'Camila Rojas Fuentes', 'camila.rojas@saludusm.cl', '$2y$10$1CUX6CoWRk9I6PQy91cRhu.OWRl6CBIHE8joX5pO2eZAtyStv84/W', 2),
  ('11222333-9', 'Andrés Muñoz Silva', 'andres.munoz@saludusm.cl', '$2y$10$1CUX6CoWRk9I6PQy91cRhu.OWRl6CBIHE8joX5pO2eZAtyStv84/W', 2),
  ('12333444-2', 'Valentina Soto Pérez', 'valentina.soto@saludusm.cl', '$2y$10$1CUX6CoWRk9I6PQy91cRhu.OWRl6CBIHE8joX5pO2eZAtyStv84/W', 2),
  ('13444555-6', 'Matías Herrera Lagos', 'matias.herrera@saludusm.cl', '$2y$10$1CUX6CoWRk9I6PQy91cRhu.OWRl6CBIHE8joX5pO2eZAtyStv84/W', 2),
  ('14555666-K', 'Fernanda Castro Díaz', 'fernanda.castro@saludusm.cl', '$2y$10$1CUX6CoWRk9I6PQy91cRhu.OWRl6CBIHE8joX5pO2eZAtyStv84/W', 2),
  ('15666777-3', 'Sebastián Vera Núñez', 'sebastian.vera@saludusm.cl', '$2y$10$1CUX6CoWRk9I6PQy91cRhu.OWRl6CBIHE8joX5pO2eZAtyStv84/W', 2),
  ('16777888-7', 'Josefa Álvarez Ríos', 'josefa.alvarez@saludusm.cl', '$2y$10$1CUX6CoWRk9I6PQy91cRhu.OWRl6CBIHE8joX5pO2eZAtyStv84/W', 2),
  ('17888999-0', 'Ignacio Fuentes Bravo', 'ignacio.fuentes@saludusm.cl', '$2y$10$1CUX6CoWRk9I6PQy91cRhu.OWRl6CBIHE8joX5pO2eZAtyStv84/W', 2),
  ('18999000-6', 'Antonia Reyes Cortés', 'antonia.reyes@saludusm.cl', '$2y$10$1CUX6CoWRk9I6PQy91cRhu.OWRl6CBIHE8joX5pO2eZAtyStv84/W', 2),
  ('19000111-3', 'Tomás Espinoza Leiva', 'tomas.espinoza@saludusm.cl', '$2y$10$1CUX6CoWRk9I6PQy91cRhu.OWRl6CBIHE8joX5pO2eZAtyStv84/W', 2),
  ('20111222-2', 'Isidora Pinto Salas', 'isidora.pinto@saludusm.cl', '$2y$10$1CUX6CoWRk9I6PQy91cRhu.OWRl6CBIHE8joX5pO2eZAtyStv84/W', 2),
  ('9222333-7', 'Rodrigo Maldonado Ruiz', 'rodrigo.maldonado@saludusm.cl', '$2y$10$1CUX6CoWRk9I6PQy91cRhu.OWRl6CBIHE8joX5pO2eZAtyStv84/W', 2),
  ('8333444-4', 'Paula Contreras Vidal', 'paula.contreras@saludusm.cl', '$2y$10$1CUX6CoWRk9I6PQy91cRhu.OWRl6CBIHE8joX5pO2eZAtyStv84/W', 2),
  ('21444555-7', 'Benjamín Torres Aguirre', 'benjamin.torres@saludusm.cl', '$2y$10$1CUX6CoWRk9I6PQy91cRhu.OWRl6CBIHE8joX5pO2eZAtyStv84/W', 2),
  ('22555666-0', 'Martina Navarro Gómez', 'martina.navarro@saludusm.cl', '$2y$10$1CUX6CoWRk9I6PQy91cRhu.OWRl6CBIHE8joX5pO2eZAtyStv84/W', 2),
  ('27325630-K', 'Agustín Salinas Peña', 'agustin.salinas@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('27231161-7', 'Bárbara Ortiz Mena', 'barbara.ortiz@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('26613011-2', 'Cristóbal Lagos Ruiz', 'cristobal.lagos@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('25514128-7', 'Daniela Ibáñez Soto', 'daniela.ibanez@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('26444633-3', 'Emilio Cárdenas Vera', 'emilio.cardenas@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('24956132-0', 'Francisca Bravo Miranda', 'francisca.bravo@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('26646933-0', 'Gonzalo Tapia Riquelme', 'gonzalo.tapia@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('24606690-6', 'Javiera Molina Sepúlveda', 'javiera.molina@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('24914536-K', 'Lucas Guzmán Farías', 'lucas.guzman@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('24921527-9', 'Manuela Órdenes Vargas', 'manuela.ordenes@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('27338720-K', 'Nicolás Zúñiga Poblete', 'nicolas.zuniga@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('26457849-3', 'Olivia Cáceres Duarte', 'olivia.caceres@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('5460868-3', 'Pablo Sandoval Aravena', 'pablo.sandoval@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('13847158-6', 'Renata Figueroa Lillo', 'renata.figueroa@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('21847332-6', 'Simón Aguilera Toro', 'simon.aguilera@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('11429746-1', 'Trinidad Bustos Cea', 'trinidad.bustos@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('20485571-4', 'Vicente Palma Godoy', 'vicente.palma@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('21915368-6', 'Amanda Riquelme Silva', 'amanda.riquelme@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('7712431-4', 'Benjamín Cortés Maldonado', 'benjamin.cortes@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('21647072-9', 'Catalina Vergara Ampuero', 'catalina.vergara@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('17737289-7', 'Diego Henríquez Rojas', 'diego.henriquez@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('9356233-K', 'Elena Marchant Pizarro', 'elena.marchant@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('18929971-0', 'Felipe Oyarzún Cid', 'felipe.oyarzun@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('17728730-K', 'Gabriela Saavedra Lobos', 'gabriela.saavedra@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('6080013-8', 'Hugo Villalobos Rivas', 'hugo.villalobos@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('14661009-9', 'Isabel Cifuentes Mora', 'isabel.cifuentes@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('15627806-8', 'Joaquín Bahamondes Ruiz', 'joaquin.bahamondes@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('9662211-2', 'Karina Alarcón Vera', 'karina.alarcon@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('14469942-4', 'Lorenzo Pardo Escobar', 'lorenzo.pardo@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('13553248-7', 'Magdalena Ulloa Núñez', 'magdalena.ulloa@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('6511345-7', 'Nicanor Salgado Bello', 'nicanor.salgado@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('15353079-3', 'Paz Carrasco Jara', 'paz.carrasco@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('18232133-8', 'Rafael Donoso Quintana', 'rafael.donoso@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('6663624-0', 'Sofía Merino Andrade', 'sofia.merino@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('20048937-3', 'Tomás Valenzuela Rubio', 'tomas.valenzuela@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('20013704-3', 'Úrsula Garrido Peña', 'ursula.garrido@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('5700968-3', 'Valeria Ampuero Silva', 'valeria.ampuero@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('13116706-7', 'Waldo Jiménez Castro', 'waldo.jimenez@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('18628001-6', 'Ximena Barría Solís', 'ximena.barria@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1),
  ('9659846-7', 'Zacarías Fernández Luna', 'zacarias.fernandez@correo.cl', '$2y$10$Uu.kW9WDJHb79WhAm8DfQ.PxAPCfMBQK6e7jJ2w2mVAlgYQJwJVry', 1);

INSERT INTO medico (rut, fecha_ingreso) VALUES
  ('10111222-5', DATE_SUB(CURDATE(), INTERVAL 14 MONTH)),
  ('11222333-9', DATE_SUB(CURDATE(), INTERVAL 42 MONTH)),
  ('12333444-2', DATE_SUB(CURDATE(), INTERVAL 63 MONTH)),
  ('13444555-6', DATE_SUB(CURDATE(), INTERVAL 63 MONTH)),
  ('14555666-K', DATE_SUB(CURDATE(), INTERVAL 77 MONTH)),
  ('15666777-3', DATE_SUB(CURDATE(), INTERVAL 14 MONTH)),
  ('16777888-7', DATE_SUB(CURDATE(), INTERVAL 28 MONTH)),
  ('17888999-0', DATE_SUB(CURDATE(), INTERVAL 70 MONTH)),
  ('18999000-6', DATE_SUB(CURDATE(), INTERVAL 70 MONTH)),
  ('19000111-3', DATE_SUB(CURDATE(), INTERVAL 63 MONTH)),
  ('20111222-2', DATE_SUB(CURDATE(), INTERVAL 49 MONTH)),
  ('9222333-7', DATE_SUB(CURDATE(), INTERVAL 70 MONTH)),
  ('8333444-4', DATE_SUB(CURDATE(), INTERVAL 63 MONTH)),
  ('21444555-7', DATE_SUB(CURDATE(), INTERVAL 84 MONTH)),
  ('22555666-0', DATE_SUB(CURDATE(), INTERVAL 56 MONTH));

INSERT INTO paciente (rut, fecha_nacimiento, sexo, telefono, id_comuna, id_prevision) VALUES
  ('27325630-K', '2021-04-01', 'M', NULL, 1, 1),
  ('27231161-7', '2021-02-10', 'F', '+56943160265', 2, 2),
  ('26613011-2', '2019-11-16', 'M', '+56972175656', 3, 3),
  ('25514128-7', '2015-05-12', 'F', '+56977866880', 4, 1),
  ('26444633-3', '2018-11-03', 'M', '+56975686986', 5, 2),
  ('24956132-0', '2013-09-10', 'F', '+56968601278', 6, 3),
  ('26646933-0', '2019-11-23', 'M', '+56971473104', 7, 1),
  ('24606690-6', '2012-06-15', 'F', '+56986669073', 8, 2),
  ('24914536-K', '2013-10-18', 'M', '+56996901508', 9, 3),
  ('24921527-9', '2013-09-26', 'F', NULL, 10, 1),
  ('27338720-K', '2021-07-17', 'M', '+56964714533', 11, 2),
  ('26457849-3', '2018-08-17', 'F', '+56999523069', 12, 3),
  ('5460868-3', '1948-04-25', 'M', '+56947313932', 1, 1),
  ('13847158-6', '1976-11-04', 'F', '+56987634371', 2, 2),
  ('21847332-6', '2003-08-08', 'M', '+56946376341', 3, 3),
  ('11429746-1', '1968-11-16', 'M', '+56963689519', 4, 1),
  ('20485571-4', '1998-05-18', 'M', '+56997363825', 5, 2),
  ('21915368-6', '2003-07-07', 'F', '+56969510228', 6, 3),
  ('7712431-4', '1956-01-05', 'M', NULL, 7, 1),
  ('21647072-9', '2002-08-12', 'F', '+56956821744', 8, 2),
  ('17737289-7', '1989-08-17', 'M', '+56996727300', 9, 3),
  ('9356233-K', '1961-11-02', 'F', '+56968932423', 10, 1),
  ('18929971-0', '1993-02-15', 'M', '+56999145394', 11, 2),
  ('17728730-K', '1989-03-14', 'F', '+56994309920', 12, 3),
  ('6080013-8', '1950-05-16', 'M', '+56979677843', 1, 1),
  ('14661009-9', '1979-12-28', 'M', '+56985205206', 2, 2),
  ('15627806-8', '1982-01-03', 'M', '+56930028718', 3, 3),
  ('9662211-2', '1962-09-27', 'F', NULL, 4, 1),
  ('14469942-4', '1978-04-08', 'M', '+56946216039', 5, 2),
  ('13553248-7', '1975-05-22', 'F', '+56977949368', 6, 3),
  ('6511345-7', '1952-06-22', 'M', '+56996033634', 7, 1),
  ('15353079-3', '1981-04-16', 'F', '+56947611550', 8, 2),
  ('18232133-8', '1991-07-22', 'M', '+56951491145', 9, 3),
  ('6663624-0', '1952-05-17', 'F', '+56985302958', 10, 1),
  ('20048937-3', '1997-09-26', 'M', '+56956400239', 11, 2),
  ('20013704-3', '1997-02-13', 'F', '+56939856055', 12, 3),
  ('5700968-3', '1949-11-12', 'F', NULL, 1, 1),
  ('13116706-7', '1974-09-16', 'O', '+56973991209', 2, 2),
  ('18628001-6', '1992-06-04', 'F', '+56996782671', 3, 3),
  ('9659846-7', '1962-10-26', 'M', '+56952915476', 4, 1);

INSERT INTO medico_especialidad (rut_medico, id_especialidad) VALUES
  ('10111222-5', 3),
  ('10111222-5', 1),
  ('11222333-9', 2),
  ('11222333-9', 1),
  ('12333444-2', 5),
  ('13444555-6', 4),
  ('14555666-K', 6),
  ('14555666-K', 1),
  ('15666777-3', 7),
  ('15666777-3', 1),
  ('16777888-7', 8),
  ('17888999-0', 3),
  ('18999000-6', 1),
  ('18999000-6', 2),
  ('18999000-6', 5),
  ('19000111-3', 4),
  ('19000111-3', 1),
  ('20111222-2', 3),
  ('20111222-2', 5),
  ('9222333-7', 2),
  ('8333444-4', 6),
  ('21444555-7', 9),
  ('21444555-7', 1),
  ('22555666-0', 10),
  ('22555666-0', 7),
  ('22555666-0', 1);

INSERT INTO medico_centro (rut_medico, id_centro) VALUES
  ('10111222-5', 1),
  ('10111222-5', 2),
  ('11222333-9', 1),
  ('12333444-2', 1),
  ('12333444-2', 3),
  ('13444555-6', 2),
  ('14555666-K', 2),
  ('14555666-K', 4),
  ('15666777-3', 3),
  ('16777888-7', 3),
  ('16777888-7', 4),
  ('17888999-0', 2),
  ('17888999-0', 4),
  ('18999000-6', 1),
  ('18999000-6', 3),
  ('19000111-3', 1),
  ('19000111-3', 5),
  ('20111222-2', 4),
  ('9222333-7', 2),
  ('9222333-7', 3),
  ('8333444-4', 1),
  ('8333444-4', 4),
  ('21444555-7', 2),
  ('21444555-7', 5),
  ('22555666-0', 3),
  ('22555666-0', 5);

INSERT INTO cita (id_cita, fecha, hora_inicio, hora_fin, rut_paciente,
                  rut_medico, id_especialidad, id_centro, id_estado) VALUES
  (1, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -60 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '21647072-9', '19000111-3', 1, 1, 3),
  (2, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -59 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '20485571-4', '16777888-7', 8, 4, 3),
  (3, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -33 DAY), '14:30:00', ADDTIME('14:30:00', '00:30:00'), '14661009-9', '22555666-0', 1, 5, 3),
  (4, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -14 DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '5700968-3', '15666777-3', 7, 3, 5),
  (5, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -26 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '24956132-0', '20111222-2', 3, 4, 3),
  (6, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -6 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '27231161-7', '20111222-2', 3, 4, 5),
  (7, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -46 DAY), '14:30:00', ADDTIME('14:30:00', '00:30:00'), '7712431-4', '21444555-7', 9, 5, 3),
  (8, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -96 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '18232133-8', '14555666-K', 1, 2, 3),
  (9, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -91 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '14469942-4', '11222333-9', 2, 1, 4),
  (10, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -81 DAY), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '21915368-6', '9222333-7', 2, 2, 3),
  (11, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -53 DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '21847332-6', '11222333-9', 2, 1, 5),
  (12, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -47 DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '5460868-3', '13444555-6', 4, 2, 3),
  (13, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -31 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '13553248-7', '8333444-4', 6, 1, 3),
  (14, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -35 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '13553248-7', '22555666-0', 1, 3, 4),
  (15, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -95 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '21847332-6', '13444555-6', 4, 2, 5),
  (16, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -95 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '20485571-4', '22555666-0', 7, 3, 3),
  (17, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -33 DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '20013704-3', '14555666-K', 6, 2, 3),
  (18, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -55 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '9662211-2', '14555666-K', 1, 2, 5),
  (19, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -81 DAY), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '20013704-3', '18999000-6', 2, 3, 3),
  (20, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -46 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '9662211-2', '14555666-K', 1, 4, 3),
  (21, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -77 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '9659846-7', '13444555-6', 4, 2, 3),
  (22, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -18 DAY), '14:30:00', ADDTIME('14:30:00', '00:30:00'), '21915368-6', '18999000-6', 1, 1, 3),
  (23, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -11 DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '21847332-6', '9222333-7', 2, 3, 3),
  (24, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -41 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '18628001-6', '10111222-5', 1, 2, 3),
  (25, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -11 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '9356233-K', '8333444-4', 6, 4, 1),
  (26, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -17 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '18929971-0', '13444555-6', 4, 2, 3),
  (27, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -32 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '18232133-8', '14555666-K', 1, 2, 4),
  (28, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -76 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '21647072-9', '21444555-7', 1, 5, 4),
  (29, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -42 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '13847158-6', '9222333-7', 2, 3, 3),
  (30, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -3 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '13847158-6', '10111222-5', 1, 1, 3),
  (31, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -77 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '5700968-3', '11222333-9', 1, 1, 3),
  (32, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -27 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '9659846-7', '20111222-2', 5, 4, 3),
  (33, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -26 DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '9662211-2', '22555666-0', 1, 3, 4),
  (34, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -3 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '24956132-0', '17888999-0', 3, 2, 3),
  (35, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -40 DAY), '09:30:00', ADDTIME('09:30:00', '00:30:00'), '13847158-6', '8333444-4', 6, 4, 4),
  (36, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -52 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '21915368-6', '22555666-0', 10, 5, 3),
  (37, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -25 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '5460868-3', '13444555-6', 4, 2, 3),
  (38, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -94 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '13847158-6', '18999000-6', 5, 1, 3),
  (39, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -41 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '14469942-4', '21444555-7', 1, 2, 3),
  (40, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -49 DAY), '14:30:00', ADDTIME('14:30:00', '00:30:00'), '24914536-K', '17888999-0', 3, 2, 3),
  (41, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -97 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '7712431-4', '10111222-5', 1, 1, 3),
  (42, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -17 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '21915368-6', '11222333-9', 1, 1, 3),
  (43, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -25 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '13847158-6', '14555666-K', 6, 2, 2),
  (44, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -52 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '15353079-3', '19000111-3', 4, 1, 3),
  (45, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -7 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '18628001-6', '22555666-0', 1, 5, 4),
  (46, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -39 DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '20048937-3', '12333444-2', 5, 3, 2),
  (47, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -13 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '5460868-3', '19000111-3', 1, 5, 3),
  (48, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -94 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '15627806-8', '21444555-7', 9, 2, 3),
  (49, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -34 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '9662211-2', '8333444-4', 6, 4, 3),
  (50, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -49 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '21915368-6', '10111222-5', 1, 2, 3),
  (51, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -90 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '15627806-8', '11222333-9', 1, 1, 3),
  (52, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -83 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '20485571-4', '11222333-9', 1, 1, 3),
  (53, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -39 DAY), '14:30:00', ADDTIME('14:30:00', '00:30:00'), '15353079-3', '9222333-7', 2, 2, 3),
  (54, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -68 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '20048937-3', '15666777-3', 7, 3, 4),
  (55, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -61 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '21915368-6', '19000111-3', 4, 5, 5),
  (56, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -24 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '13847158-6', '9222333-7', 2, 2, 5),
  (57, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -12 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '13116706-7', '21444555-7', 1, 5, 1),
  (58, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -28 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '20048937-3', '15666777-3', 7, 3, 3),
  (59, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -73 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '18628001-6', '16777888-7', 8, 3, 4),
  (60, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -94 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '26613011-2', '10111222-5', 3, 2, 3),
  (61, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -52 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '14661009-9', '12333444-2', 5, 3, 4),
  (62, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -69 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '9659846-7', '13444555-6', 4, 2, 3),
  (63, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -73 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '11429746-1', '21444555-7', 9, 5, 5),
  (64, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -60 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '15353079-3', '14555666-K', 6, 4, 3),
  (65, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -26 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '14469942-4', '18999000-6', 1, 3, 1),
  (66, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -91 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '7712431-4', '9222333-7', 2, 2, 2),
  (67, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -35 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '21847332-6', '13444555-6', 4, 2, 2),
  (68, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -10 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '18628001-6', '18999000-6', 2, 1, 3),
  (69, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -21 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '7712431-4', '16777888-7', 8, 3, 4),
  (70, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -11 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '6511345-7', '16777888-7', 8, 4, 4),
  (71, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -24 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '21915368-6', '13444555-6', 4, 2, 3),
  (72, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -45 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '9356233-K', '8333444-4', 6, 4, 3),
  (73, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -63 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '9659846-7', '14555666-K', 1, 2, 3),
  (74, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -70 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '27338720-K', '20111222-2', 3, 4, 3),
  (75, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -21 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '15353079-3', '13444555-6', 4, 2, 1),
  (76, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -74 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '9356233-K', '19000111-3', 1, 5, 3),
  (77, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -97 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '7712431-4', '11222333-9', 1, 1, 3),
  (78, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -12 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '15353079-3', '15666777-3', 7, 3, 3),
  (79, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -60 DAY), '14:30:00', ADDTIME('14:30:00', '00:30:00'), '24921527-9', '17888999-0', 3, 4, 2),
  (80, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -90 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '9659846-7', '15666777-3', 1, 3, 3),
  (81, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -84 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '6511345-7', '13444555-6', 4, 2, 3),
  (82, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -5 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '21847332-6', '14555666-K', 1, 2, 5),
  (83, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -94 DAY), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '13553248-7', '12333444-2', 5, 1, 3),
  (84, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -19 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '20013704-3', '12333444-2', 5, 3, 3),
  (85, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -13 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '20485571-4', '11222333-9', 2, 1, 4),
  (86, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -75 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '21915368-6', '22555666-0', 7, 3, 3),
  (87, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -69 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '21847332-6', '12333444-2', 5, 3, 5),
  (88, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -87 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '26457849-3', '17888999-0', 3, 2, 5),
  (89, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -73 DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '20485571-4', '9222333-7', 2, 3, 3),
  (90, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -17 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '14469942-4', '11222333-9', 2, 1, 3),
  (91, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -42 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '21647072-9', '10111222-5', 1, 1, 4),
  (92, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -67 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '6663624-0', '21444555-7', 9, 2, 4),
  (93, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -14 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '24606690-6', '20111222-2', 3, 4, 4),
  (94, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -61 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '5460868-3', '16777888-7', 8, 3, 4),
  (95, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -47 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '17728730-K', '12333444-2', 5, 3, 3),
  (96, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -95 DAY), '14:30:00', ADDTIME('14:30:00', '00:30:00'), '20013704-3', '8333444-4', 6, 1, 3),
  (97, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -33 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '14661009-9', '16777888-7', 8, 3, 3),
  (98, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -27 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '9356233-K', '10111222-5', 1, 1, 4),
  (99, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -98 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '26444633-3', '17888999-0', 3, 2, 4),
  (100, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -69 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '21915368-6', '8333444-4', 6, 4, 4),
  (101, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -54 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '26457849-3', '10111222-5', 3, 1, 1),
  (102, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -80 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '14661009-9', '12333444-2', 5, 1, 3),
  (103, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -7 DAY), '09:30:00', ADDTIME('09:30:00', '00:30:00'), '11429746-1', '19000111-3', 1, 1, 3),
  (104, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -47 DAY), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '13847158-6', '12333444-2', 5, 1, 3),
  (105, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -62 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '24606690-6', '10111222-5', 3, 2, 3),
  (106, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -53 DAY), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '9662211-2', '15666777-3', 7, 3, 3),
  (107, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -90 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '24914536-K', '17888999-0', 3, 4, 3),
  (108, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -28 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '27325630-K', '10111222-5', 3, 1, 3),
  (109, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -97 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '24606690-6', '20111222-2', 3, 4, 3),
  (110, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -68 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '24914536-K', '20111222-2', 3, 4, 3),
  (111, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -63 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '13847158-6', '12333444-2', 5, 3, 5),
  (112, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -69 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '7712431-4', '18999000-6', 1, 1, 2),
  (113, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL -87 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '13847158-6', '16777888-7', 8, 3, 3),
  (114, DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '15353079-3', '10111222-5', 1, 1, IF(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY) < CURDATE(), 3, 1)),
  (115, DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '26646933-0', '10111222-5', 3, 1, IF(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY) < CURDATE(), 3, 2)),
  (116, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '18628001-6', '10111222-5', 1, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY) < CURDATE(), 3, 1)),
  (117, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '26457849-3', '10111222-5', 3, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY) < CURDATE(), 3, 2)),
  (118, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '27231161-7', '10111222-5', 3, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY) < CURDATE(), 3, 1)),
  (119, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '20048937-3', '10111222-5', 1, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY) < CURDATE(), 3, 2)),
  (120, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '27325630-K', '10111222-5', 3, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY) < CURDATE(), 3, 1)),
  (121, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '6663624-0', '10111222-5', 1, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY) < CURDATE(), 3, 2)),
  (122, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '21847332-6', '10111222-5', 1, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY) < CURDATE(), 3, 1)),
  (123, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '27231161-7', '10111222-5', 3, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY) < CURDATE(), 3, 2)),
  (124, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '13847158-6', '10111222-5', 1, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY) < CURDATE(), 3, 1)),
  (125, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '24606690-6', '10111222-5', 3, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY) < CURDATE(), 3, 2)),
  (126, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '5700968-3', '10111222-5', 1, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY) < CURDATE(), 3, 1)),
  (127, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '27231161-7', '10111222-5', 3, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY) < CURDATE(), 3, 2)),
  (128, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '20485571-4', '10111222-5', 1, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY) < CURDATE(), 3, 1)),
  (129, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '6080013-8', '10111222-5', 1, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY) < CURDATE(), 3, 2)),
  (130, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '20013704-3', '10111222-5', 1, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY) < CURDATE(), 3, 1)),
  (131, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '20485571-4', '10111222-5', 1, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY) < CURDATE(), 3, 2)),
  (132, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '25514128-7', '10111222-5', 3, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY) < CURDATE(), 3, 1)),
  (133, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '7712431-4', '10111222-5', 1, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY) < CURDATE(), 3, 2)),
  (134, DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '7712431-4', '11222333-9', 2, 1, IF(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY) < CURDATE(), 3, 1)),
  (135, DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '13116706-7', '11222333-9', 1, 1, IF(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY) < CURDATE(), 3, 2)),
  (136, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '20013704-3', '11222333-9', 2, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY) < CURDATE(), 3, 1)),
  (137, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '21647072-9', '11222333-9', 1, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY) < CURDATE(), 3, 2)),
  (138, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '20013704-3', '11222333-9', 2, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY) < CURDATE(), 3, 1)),
  (139, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '17728730-K', '11222333-9', 2, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY) < CURDATE(), 3, 2)),
  (140, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '5700968-3', '11222333-9', 1, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY) < CURDATE(), 3, 1)),
  (141, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '21847332-6', '11222333-9', 1, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY) < CURDATE(), 3, 2)),
  (142, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '18929971-0', '11222333-9', 1, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY) < CURDATE(), 3, 1)),
  (143, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '7712431-4', '11222333-9', 1, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY) < CURDATE(), 3, 2)),
  (144, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '18929971-0', '11222333-9', 2, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY) < CURDATE(), 3, 1)),
  (145, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '20013704-3', '11222333-9', 1, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY) < CURDATE(), 3, 2)),
  (146, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY), '14:30:00', ADDTIME('14:30:00', '00:30:00'), '7712431-4', '11222333-9', 1, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY) < CURDATE(), 3, 1)),
  (147, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '21915368-6', '11222333-9', 2, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY) < CURDATE(), 3, 2)),
  (148, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '15627806-8', '11222333-9', 1, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY) < CURDATE(), 3, 1)),
  (149, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY), '14:30:00', ADDTIME('14:30:00', '00:30:00'), '7712431-4', '11222333-9', 2, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY) < CURDATE(), 3, 2)),
  (150, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '21647072-9', '11222333-9', 1, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY) < CURDATE(), 3, 1)),
  (151, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '18929971-0', '11222333-9', 2, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY) < CURDATE(), 3, 2)),
  (152, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '5460868-3', '11222333-9', 1, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY) < CURDATE(), 3, 1)),
  (153, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '18628001-6', '11222333-9', 1, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY) < CURDATE(), 3, 2)),
  (154, DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '7712431-4', '12333444-2', 5, 3, IF(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY) < CURDATE(), 3, 1)),
  (155, DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '21915368-6', '12333444-2', 5, 1, IF(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY) < CURDATE(), 3, 2)),
  (156, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '7712431-4', '12333444-2', 5, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY) < CURDATE(), 3, 1)),
  (157, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '14661009-9', '12333444-2', 5, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY) < CURDATE(), 3, 2)),
  (158, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '21915368-6', '12333444-2', 5, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY) < CURDATE(), 3, 1)),
  (159, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '20485571-4', '12333444-2', 5, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY) < CURDATE(), 3, 2)),
  (160, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '6080013-8', '12333444-2', 5, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY) < CURDATE(), 3, 1)),
  (161, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '11429746-1', '12333444-2', 5, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY) < CURDATE(), 3, 2)),
  (162, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '5700968-3', '12333444-2', 5, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY) < CURDATE(), 3, 1)),
  (163, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '17728730-K', '12333444-2', 5, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY) < CURDATE(), 3, 2)),
  (164, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '5460868-3', '12333444-2', 5, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY) < CURDATE(), 3, 1)),
  (165, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '17728730-K', '12333444-2', 5, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY) < CURDATE(), 3, 2)),
  (166, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '20485571-4', '12333444-2', 5, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY) < CURDATE(), 3, 1)),
  (167, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '20485571-4', '12333444-2', 5, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY) < CURDATE(), 3, 2)),
  (168, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '20048937-3', '12333444-2', 5, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY) < CURDATE(), 3, 1)),
  (169, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '5460868-3', '12333444-2', 5, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY) < CURDATE(), 3, 2)),
  (170, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY), '09:30:00', ADDTIME('09:30:00', '00:30:00'), '21847332-6', '12333444-2', 5, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY) < CURDATE(), 3, 1)),
  (171, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '6663624-0', '12333444-2', 5, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY) < CURDATE(), 3, 2)),
  (172, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '13553248-7', '12333444-2', 5, 1, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY) < CURDATE(), 3, 1)),
  (173, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '21647072-9', '12333444-2', 5, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY) < CURDATE(), 3, 2)),
  (174, DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '20048937-3', '13444555-6', 4, 2, IF(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY) < CURDATE(), 3, 1)),
  (175, DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '18628001-6', '13444555-6', 4, 2, IF(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY) < CURDATE(), 3, 2)),
  (176, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '20013704-3', '13444555-6', 4, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY) < CURDATE(), 3, 1)),
  (177, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '21647072-9', '13444555-6', 4, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY) < CURDATE(), 3, 2)),
  (178, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '18232133-8', '13444555-6', 4, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY) < CURDATE(), 3, 1)),
  (179, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '7712431-4', '13444555-6', 4, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY) < CURDATE(), 3, 2)),
  (180, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '15627806-8', '13444555-6', 4, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY) < CURDATE(), 3, 1)),
  (181, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '14661009-9', '13444555-6', 4, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY) < CURDATE(), 3, 2)),
  (182, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY), '09:30:00', ADDTIME('09:30:00', '00:30:00'), '6511345-7', '13444555-6', 4, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY) < CURDATE(), 3, 1)),
  (183, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '21915368-6', '13444555-6', 4, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY) < CURDATE(), 3, 2)),
  (184, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '11429746-1', '13444555-6', 4, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY) < CURDATE(), 3, 1)),
  (185, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '21915368-6', '13444555-6', 4, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY) < CURDATE(), 3, 2)),
  (186, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY), '09:30:00', ADDTIME('09:30:00', '00:30:00'), '11429746-1', '13444555-6', 4, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY) < CURDATE(), 3, 1)),
  (187, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '5460868-3', '13444555-6', 4, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY) < CURDATE(), 3, 2)),
  (188, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '21647072-9', '13444555-6', 4, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY) < CURDATE(), 3, 1)),
  (189, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '6663624-0', '13444555-6', 4, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY) < CURDATE(), 3, 2)),
  (190, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '6080013-8', '13444555-6', 4, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY) < CURDATE(), 3, 1)),
  (191, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '18929971-0', '13444555-6', 4, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY) < CURDATE(), 3, 2)),
  (192, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY), '14:30:00', ADDTIME('14:30:00', '00:30:00'), '11429746-1', '13444555-6', 4, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY) < CURDATE(), 3, 1)),
  (193, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '13847158-6', '13444555-6', 4, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY) < CURDATE(), 3, 2)),
  (194, DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '11429746-1', '14555666-K', 1, 2, IF(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY) < CURDATE(), 3, 1)),
  (195, DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '15627806-8', '14555666-K', 1, 4, IF(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY) < CURDATE(), 3, 2)),
  (196, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '17728730-K', '14555666-K', 6, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY) < CURDATE(), 3, 1)),
  (197, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '20485571-4', '14555666-K', 1, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY) < CURDATE(), 3, 2)),
  (198, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '9356233-K', '14555666-K', 6, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY) < CURDATE(), 3, 1)),
  (199, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '13847158-6', '14555666-K', 1, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY) < CURDATE(), 3, 2)),
  (200, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '17737289-7', '14555666-K', 1, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY) < CURDATE(), 3, 1)),
  (201, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '20485571-4', '14555666-K', 1, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY) < CURDATE(), 3, 2)),
  (202, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '17728730-K', '14555666-K', 6, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY) < CURDATE(), 3, 1)),
  (203, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '9662211-2', '14555666-K', 6, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY) < CURDATE(), 3, 2)),
  (204, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '6511345-7', '14555666-K', 1, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY) < CURDATE(), 3, 1)),
  (205, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '18628001-6', '14555666-K', 6, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY) < CURDATE(), 3, 2)),
  (206, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '5460868-3', '14555666-K', 1, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY) < CURDATE(), 3, 1)),
  (207, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '6663624-0', '14555666-K', 6, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY) < CURDATE(), 3, 2)),
  (208, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '5460868-3', '14555666-K', 1, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY) < CURDATE(), 3, 1)),
  (209, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '9356233-K', '14555666-K', 6, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY) < CURDATE(), 3, 2)),
  (210, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '20485571-4', '14555666-K', 1, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY) < CURDATE(), 3, 1)),
  (211, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '6663624-0', '14555666-K', 6, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY) < CURDATE(), 3, 2)),
  (212, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY), '14:30:00', ADDTIME('14:30:00', '00:30:00'), '15627806-8', '14555666-K', 1, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY) < CURDATE(), 3, 1)),
  (213, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY), '09:30:00', ADDTIME('09:30:00', '00:30:00'), '17728730-K', '14555666-K', 6, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY) < CURDATE(), 3, 2)),
  (214, DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '21915368-6', '15666777-3', 7, 3, IF(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY) < CURDATE(), 3, 1)),
  (215, DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '9659846-7', '15666777-3', 1, 3, IF(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY) < CURDATE(), 3, 2)),
  (216, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '20485571-4', '15666777-3', 1, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY) < CURDATE(), 3, 1)),
  (217, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '11429746-1', '15666777-3', 7, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY) < CURDATE(), 3, 2)),
  (218, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '21915368-6', '15666777-3', 1, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY) < CURDATE(), 3, 1)),
  (219, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '13847158-6', '15666777-3', 7, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY) < CURDATE(), 3, 2)),
  (220, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '5700968-3', '15666777-3', 7, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY) < CURDATE(), 3, 1)),
  (221, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '6511345-7', '15666777-3', 1, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY) < CURDATE(), 3, 2)),
  (222, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '9659846-7', '15666777-3', 1, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY) < CURDATE(), 3, 1)),
  (223, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '11429746-1', '15666777-3', 1, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY) < CURDATE(), 3, 2)),
  (224, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '6511345-7', '15666777-3', 7, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY) < CURDATE(), 3, 1)),
  (225, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '14661009-9', '15666777-3', 1, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY) < CURDATE(), 3, 2)),
  (226, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY), '09:30:00', ADDTIME('09:30:00', '00:30:00'), '13847158-6', '15666777-3', 1, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY) < CURDATE(), 3, 1)),
  (227, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '13116706-7', '15666777-3', 7, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY) < CURDATE(), 3, 2)),
  (228, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY), '14:30:00', ADDTIME('14:30:00', '00:30:00'), '21647072-9', '15666777-3', 1, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY) < CURDATE(), 3, 1)),
  (229, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '13116706-7', '15666777-3', 7, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY) < CURDATE(), 3, 2)),
  (230, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '14661009-9', '15666777-3', 7, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY) < CURDATE(), 3, 1)),
  (231, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '13553248-7', '15666777-3', 7, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY) < CURDATE(), 3, 2)),
  (232, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '9356233-K', '15666777-3', 7, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY) < CURDATE(), 3, 1)),
  (233, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '11429746-1', '15666777-3', 1, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY) < CURDATE(), 3, 2)),
  (234, DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '17728730-K', '16777888-7', 8, 4, IF(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY) < CURDATE(), 3, 1)),
  (235, DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '21915368-6', '16777888-7', 8, 4, IF(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY) < CURDATE(), 3, 2)),
  (236, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '21915368-6', '16777888-7', 8, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY) < CURDATE(), 3, 1)),
  (237, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '20485571-4', '16777888-7', 8, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY) < CURDATE(), 3, 2)),
  (238, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '20485571-4', '16777888-7', 8, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY) < CURDATE(), 3, 1)),
  (239, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '14661009-9', '16777888-7', 8, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY) < CURDATE(), 3, 2)),
  (240, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '11429746-1', '16777888-7', 8, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY) < CURDATE(), 3, 1)),
  (241, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '21847332-6', '16777888-7', 8, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY) < CURDATE(), 3, 2)),
  (242, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '5700968-3', '16777888-7', 8, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY) < CURDATE(), 3, 1)),
  (243, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY), '09:30:00', ADDTIME('09:30:00', '00:30:00'), '21915368-6', '16777888-7', 8, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY) < CURDATE(), 3, 2)),
  (244, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '20485571-4', '16777888-7', 8, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY) < CURDATE(), 3, 1)),
  (245, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '9659846-7', '16777888-7', 8, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY) < CURDATE(), 3, 2)),
  (246, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '13553248-7', '16777888-7', 8, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY) < CURDATE(), 3, 1)),
  (247, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '18232133-8', '16777888-7', 8, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY) < CURDATE(), 3, 2)),
  (248, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '20013704-3', '16777888-7', 8, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY) < CURDATE(), 3, 1)),
  (249, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '21847332-6', '16777888-7', 8, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY) < CURDATE(), 3, 2)),
  (250, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '14661009-9', '16777888-7', 8, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY) < CURDATE(), 3, 1)),
  (251, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '13847158-6', '16777888-7', 8, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY) < CURDATE(), 3, 2)),
  (252, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '11429746-1', '16777888-7', 8, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY) < CURDATE(), 3, 1)),
  (253, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '9356233-K', '16777888-7', 8, 3, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY) < CURDATE(), 3, 2)),
  (254, DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '27231161-7', '17888999-0', 3, 2, IF(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY) < CURDATE(), 3, 1)),
  (255, DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), '09:30:00', ADDTIME('09:30:00', '00:30:00'), '27338720-K', '17888999-0', 3, 2, IF(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY) < CURDATE(), 3, 2)),
  (256, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '27325630-K', '17888999-0', 3, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY) < CURDATE(), 3, 1)),
  (257, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '24921527-9', '17888999-0', 3, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 DAY) < CURDATE(), 3, 2)),
  (258, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '25514128-7', '17888999-0', 3, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY) < CURDATE(), 3, 1)),
  (259, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '25514128-7', '17888999-0', 3, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 2 DAY) < CURDATE(), 3, 2)),
  (260, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY), '09:30:00', ADDTIME('09:30:00', '00:30:00'), '27325630-K', '17888999-0', 3, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY) < CURDATE(), 3, 1)),
  (261, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '24914536-K', '17888999-0', 3, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 3 DAY) < CURDATE(), 3, 2)),
  (262, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '26457849-3', '17888999-0', 3, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY) < CURDATE(), 3, 1)),
  (263, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '26444633-3', '17888999-0', 3, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 4 DAY) < CURDATE(), 3, 2)),
  (264, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '27231161-7', '17888999-0', 3, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY) < CURDATE(), 3, 1)),
  (265, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '27325630-K', '17888999-0', 3, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY) < CURDATE(), 3, 2)),
  (266, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '27325630-K', '17888999-0', 3, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY) < CURDATE(), 3, 1)),
  (267, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '27325630-K', '17888999-0', 3, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 8 DAY) < CURDATE(), 3, 2)),
  (268, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '26646933-0', '17888999-0', 3, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY) < CURDATE(), 3, 1)),
  (269, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '26646933-0', '17888999-0', 3, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 9 DAY) < CURDATE(), 3, 2)),
  (270, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '24956132-0', '17888999-0', 3, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY) < CURDATE(), 3, 1)),
  (271, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '27231161-7', '17888999-0', 3, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 10 DAY) < CURDATE(), 3, 2)),
  (272, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '27325630-K', '17888999-0', 3, 4, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY) < CURDATE(), 3, 1)),
  (273, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '24921527-9', '17888999-0', 3, 2, IF(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 11 DAY) < CURDATE(), 3, 2)),
  (274, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 52 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '20048937-3', '10111222-5', 1, 2, 2),
  (275, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 29 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '26457849-3', '10111222-5', 3, 1, 5),
  (276, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 30 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '24606690-6', '10111222-5', 3, 1, 1),
  (277, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 22 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '15353079-3', '11222333-9', 1, 1, 5),
  (278, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 23 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '13847158-6', '11222333-9', 1, 1, 1),
  (279, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 49 DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '6511345-7', '11222333-9', 1, 1, 2),
  (280, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 42 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '21915368-6', '12333444-2', 5, 3, 1),
  (281, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 22 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '20485571-4', '12333444-2', 5, 3, 2),
  (282, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 53 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '13847158-6', '12333444-2', 5, 1, 1),
  (283, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 23 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '7712431-4', '13444555-6', 4, 2, 2),
  (284, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 50 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '18628001-6', '13444555-6', 4, 2, 2),
  (285, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 29 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '13847158-6', '13444555-6', 4, 2, 1),
  (286, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 25 DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '21847332-6', '14555666-K', 1, 2, 1),
  (287, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 59 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '21847332-6', '14555666-K', 1, 2, 1),
  (288, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 46 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '17728730-K', '14555666-K', 6, 4, 1),
  (289, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 23 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '7712431-4', '15666777-3', 7, 3, 2),
  (290, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 32 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '17737289-7', '15666777-3', 7, 3, 1),
  (291, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 45 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '14661009-9', '15666777-3', 7, 3, 2),
  (292, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 49 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '6663624-0', '16777888-7', 8, 3, 1),
  (293, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 49 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '13553248-7', '16777888-7', 8, 3, 1),
  (294, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 44 DAY), '09:30:00', ADDTIME('09:30:00', '00:30:00'), '13847158-6', '16777888-7', 8, 4, 2),
  (295, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 28 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '24921527-9', '17888999-0', 3, 4, 1),
  (296, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 43 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '24606690-6', '17888999-0', 3, 2, 1),
  (297, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 38 DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '27231161-7', '17888999-0', 3, 4, 2),
  (298, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 30 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '11429746-1', '18999000-6', 5, 1, 2),
  (299, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 51 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '15627806-8', '18999000-6', 5, 1, 1),
  (300, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 18 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '21647072-9', '18999000-6', 1, 3, 1),
  (301, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 45 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '21847332-6', '19000111-3', 1, 5, 1),
  (302, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 50 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '5460868-3', '19000111-3', 1, 1, 5),
  (303, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 31 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '20485571-4', '19000111-3', 4, 1, 1),
  (304, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 15 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '26613011-2', '20111222-2', 3, 4, 1),
  (305, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 22 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '21647072-9', '20111222-2', 5, 4, 2),
  (306, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 21 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '21647072-9', '20111222-2', 5, 4, 2),
  (307, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 58 DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '13553248-7', '9222333-7', 2, 2, 1),
  (308, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 24 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '7712431-4', '9222333-7', 2, 3, 1),
  (309, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 45 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '11429746-1', '9222333-7', 2, 2, 1),
  (310, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 31 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '6663624-0', '8333444-4', 6, 1, 5),
  (311, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 53 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '18628001-6', '8333444-4', 6, 1, 2),
  (312, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 14 DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '13553248-7', '8333444-4', 6, 1, 2),
  (313, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 59 DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '5460868-3', '21444555-7', 1, 2, 2),
  (314, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 52 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '20013704-3', '21444555-7', 9, 2, 2),
  (315, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 57 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '9356233-K', '21444555-7', 1, 5, 2),
  (316, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 16 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '20013704-3', '22555666-0', 10, 3, 2),
  (317, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 32 DAY), '09:30:00', ADDTIME('09:30:00', '00:30:00'), '13847158-6', '22555666-0', 7, 5, 2),
  (318, DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 38 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '5460868-3', '22555666-0', 7, 5, 5);

INSERT INTO atencion (id_atencion, id_cita, motivo, observaciones) VALUES
  (1, 1, 'Molestias digestivas recurrentes', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (2, 2, 'Control de agudeza visual', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (3, 3, 'Molestias digestivas recurrentes', 'Se solicitan exámenes complementarios para el próximo control.'),
  (4, 5, 'Diarrea y vómitos hace 24 horas', 'Evolución favorable respecto al control anterior.'),
  (5, 7, 'Congestión nasal crónica', 'Se deriva a especialista para evaluación complementaria.'),
  (6, 8, 'Cuadro respiratorio agudo', 'Se solicitan exámenes complementarios para el próximo control.'),
  (7, 10, 'Revisión de exámenes de laboratorio', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (8, 12, 'Control post esguince', 'Se solicitan exámenes complementarios para el próximo control.'),
  (9, 13, 'Molestias urinarias a repetición', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (10, 16, 'Mareos y episodios de inestabilidad', 'Se ajusta dosis del tratamiento habitual.'),
  (11, 17, 'Molestias urinarias a repetición', 'Se deriva a especialista para evaluación complementaria.'),
  (12, 19, 'Control de presión arterial elevada', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (13, 20, 'Control de morbilidad general', 'Se solicitan exámenes complementarios para el próximo control.'),
  (14, 21, 'Control post esguince', 'Se ajusta dosis del tratamiento habitual.'),
  (15, 22, 'Cuadro respiratorio agudo', 'Se deriva a especialista para evaluación complementaria.'),
  (16, 23, 'Palpitaciones al esfuerzo', 'Se solicitan exámenes complementarios para el próximo control.'),
  (17, 24, 'Control de morbilidad general', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (18, 26, 'Dolor lumbar persistente', 'Evolución favorable respecto al control anterior.'),
  (19, 29, 'Revisión de exámenes de laboratorio', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (20, 30, 'Control de morbilidad general', 'Sin signos de alarma al examen físico. Se refuerzan indicaciones.'),
  (21, 31, 'Cuadro respiratorio agudo', 'Se ajusta dosis del tratamiento habitual.'),
  (22, 32, 'Prurito y enrojecimiento', 'Sin signos de alarma al examen físico. Se refuerzan indicaciones.'),
  (23, 34, 'Control de niño sano', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (24, 36, 'Cuadro ansioso reciente', 'Se solicitan exámenes complementarios para el próximo control.'),
  (25, 37, 'Dolor de rodilla al caminar', 'Evolución favorable respecto al control anterior.'),
  (26, 38, 'Control de tratamiento dermatológico', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (27, 39, 'Cuadro respiratorio agudo', 'Se deriva a especialista para evaluación complementaria.'),
  (28, 40, 'Fiebre y decaimiento hace tres días', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (29, 41, 'Molestias digestivas recurrentes', 'Se deriva a especialista para evaluación complementaria.'),
  (30, 42, 'Cuadro respiratorio agudo', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (31, 44, 'Dolor lumbar persistente', 'Evolución favorable respecto al control anterior.'),
  (32, 47, 'Cuadro respiratorio agudo', 'Se deriva a especialista para evaluación complementaria.'),
  (33, 48, 'Dolor de oído hace dos días', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (34, 49, 'Control de método anticonceptivo', 'Evolución favorable respecto al control anterior.'),
  (35, 50, 'Cuadro respiratorio agudo', 'Se deriva a especialista para evaluación complementaria.'),
  (36, 51, 'Chequeo preventivo anual', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (37, 52, 'Control de morbilidad general', 'Se deriva a especialista para evaluación complementaria.'),
  (38, 53, 'Control de presión arterial elevada', 'Sin signos de alarma al examen físico. Se refuerzan indicaciones.'),
  (39, 58, 'Cefalea intensa recurrente', 'Evolución favorable respecto al control anterior.'),
  (40, 60, 'Fiebre y decaimiento hace tres días', 'Sin signos de alarma al examen físico. Se refuerzan indicaciones.'),
  (41, 62, 'Dolor lumbar persistente', 'Se ajusta dosis del tratamiento habitual.'),
  (42, 64, 'Molestias urinarias a repetición', 'Se ajusta dosis del tratamiento habitual.'),
  (43, 68, 'Control de presión arterial elevada', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (44, 71, 'Control post esguince', 'Se deriva a especialista para evaluación complementaria.'),
  (45, 72, 'Molestias urinarias a repetición', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (46, 73, 'Cuadro respiratorio agudo', 'Se ajusta dosis del tratamiento habitual.'),
  (47, 74, 'Diarrea y vómitos hace 24 horas', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (48, 76, 'Control de morbilidad general', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (49, 77, 'Control de morbilidad general', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (50, 78, 'Cefalea intensa recurrente', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (51, 80, 'Cuadro respiratorio agudo', 'Evolución favorable respecto al control anterior.'),
  (52, 81, 'Dolor de rodilla al caminar', 'Se ajusta dosis del tratamiento habitual.'),
  (53, 83, 'Control de tratamiento dermatológico', 'Se ajusta dosis del tratamiento habitual.'),
  (54, 84, 'Prurito y enrojecimiento', 'Sin signos de alarma al examen físico. Se refuerzan indicaciones.'),
  (55, 86, 'Adormecimiento de extremidades', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (56, 89, 'Revisión de exámenes de laboratorio', 'Se solicitan exámenes complementarios para el próximo control.'),
  (57, 90, 'Palpitaciones al esfuerzo', 'Sin signos de alarma al examen físico. Se refuerzan indicaciones.'),
  (58, 95, 'Prurito y enrojecimiento', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (59, 96, 'Control ginecológico anual', 'Se ajusta dosis del tratamiento habitual.'),
  (60, 97, 'Control de agudeza visual', 'Se deriva a especialista para evaluación complementaria.'),
  (61, 102, 'Prurito y enrojecimiento', 'Se solicitan exámenes complementarios para el próximo control.'),
  (62, 103, 'Chequeo preventivo anual', 'Se solicitan exámenes complementarios para el próximo control.'),
  (63, 104, 'Control de tratamiento dermatológico', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (64, 105, 'Diarrea y vómitos hace 24 horas', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (65, 106, 'Mareos y episodios de inestabilidad', 'Evolución favorable respecto al control anterior.'),
  (66, 107, 'Control de niño sano', 'Se solicitan exámenes complementarios para el próximo control.'),
  (67, 108, 'Tos persistente', 'Evolución favorable respecto al control anterior.'),
  (68, 109, 'Diarrea y vómitos hace 24 horas', 'Evolución favorable respecto al control anterior.'),
  (69, 110, 'Fiebre y decaimiento hace tres días', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (70, 113, 'Ojo rojo e irritación', 'Se ajusta dosis del tratamiento habitual.');

INSERT INTO atencion_diagnostico (id_atencion, id_diagnostico) VALUES
  (1, 16),
  (1, 4),
  (2, 19),
  (3, 15),
  (4, 14),
  (5, 14),
  (6, 19),
  (6, 1),
  (6, 16),
  (7, 16),
  (8, 17),
  (8, 10),
  (8, 4),
  (9, 12),
  (9, 9),
  (10, 19),
  (10, 13),
  (11, 9),
  (11, 12),
  (12, 3),
  (13, 11),
  (13, 15),
  (13, 9),
  (14, 10),
  (14, 4),
  (14, 17),
  (15, 19),
  (15, 11),
  (16, 2),
  (16, 20),
  (17, 16),
  (17, 4),
  (17, 15),
  (18, 4),
  (18, 17),
  (18, 10),
  (19, 16),
  (19, 3),
  (19, 2),
  (20, 11),
  (20, 4),
  (21, 4),
  (22, 17),
  (23, 5),
  (23, 15),
  (24, 19),
  (24, 8),
  (25, 10),
  (25, 17),
  (25, 4),
  (26, 17),
  (26, 6),
  (27, 1),
  (27, 9),
  (28, 15),
  (28, 1),
  (29, 16),
  (30, 16),
  (30, 19),
  (30, 1),
  (31, 17),
  (32, 2),
  (32, 9),
  (33, 1),
  (34, 9),
  (34, 12),
  (35, 16),
  (35, 9),
  (36, 19),
  (36, 1),
  (37, 11),
  (37, 19),
  (38, 3),
  (39, 8),
  (39, 19),
  (39, 13),
  (40, 15),
  (41, 4),
  (41, 10),
  (42, 9),
  (42, 12),
  (43, 20),
  (44, 10),
  (44, 4),
  (45, 12),
  (46, 15),
  (46, 16),
  (46, 9),
  (47, 11),
  (48, 4),
  (48, 9),
  (49, 4),
  (49, 11),
  (50, 19),
  (51, 4),
  (51, 15),
  (52, 10),
  (52, 4),
  (53, 17),
  (54, 18),
  (55, 13),
  (55, 8),
  (56, 3),
  (56, 2),
  (56, 20),
  (57, 2),
  (57, 16),
  (58, 18),
  (59, 12),
  (59, 9),
  (60, 7),
  (61, 6),
  (62, 2),
  (62, 4),
  (63, 17),
  (63, 6),
  (64, 1),
  (64, 5),
  (64, 15),
  (65, 19),
  (65, 13),
  (66, 5),
  (66, 15),
  (67, 11),
  (67, 1),
  (68, 14),
  (69, 15),
  (69, 5),
  (70, 7),
  (70, 19);

INSERT INTO receta (id_receta, id_atencion, medicamento, dosis, dias_tratamiento) VALUES
  (1, 1, 'Ibuprofeno 400 mg', '1 sobre cada 6 horas', 7),
  (2, 1, 'Amoxicilina 500 mg', '1 gota en cada ojo cada 8 horas', 90),
  (3, 2, 'Tobramicina colirio', '1 gota en cada ojo cada 8 horas', 14),
  (4, 2, 'Timolol colirio 0,5%', '1 comprimido cada 8 horas', 10),
  (5, 3, 'Amoxicilina 500 mg', '1 gota en cada ojo cada 8 horas', 60),
  (6, 3, 'Ibuprofeno 400 mg', '1 comprimido cada 8 horas', 90),
  (7, 3, 'Paracetamol 500 mg', 'Aplicar 2 veces al día', 60),
  (8, 4, 'Ibuprofeno jarabe 100 mg/5 ml', '1 sobre cada 6 horas', 7),
  (9, 4, 'Paracetamol jarabe 120 mg/5 ml', '1 comprimido cada 8 horas', 10),
  (10, 5, 'Ibuprofeno 600 mg', '1 sobre cada 6 horas', 60),
  (11, 6, 'Paracetamol 500 mg', '1 sobre cada 6 horas', 60),
  (12, 7, 'Atorvastatina 20 mg', '1 sobre cada 6 horas', 3),
  (13, 7, 'Losartán 50 mg', '1 comprimido cada 12 horas', 60),
  (14, 8, 'Paracetamol 1 g', '1 comprimido al día', 3),
  (15, 8, 'Ciclobenzaprina 10 mg', '1 gota en cada ojo cada 8 horas', 7),
  (16, 9, 'Sulfato ferroso 200 mg', '1 gota en cada ojo cada 8 horas', 14),
  (17, 9, 'Fluconazol 150 mg', '5 ml cada 8 horas', 7),
  (18, 9, 'Nitrofurantoína 100 mg', '5 ml cada 8 horas', 5),
  (19, 10, 'Sumatriptán 50 mg', '1 comprimido cada 12 horas', 30),
  (20, 10, 'Ácido valproico 500 mg', '5 ml cada 8 horas', 14),
  (21, 11, 'Nitrofurantoína 100 mg', '1 comprimido cada 12 horas', 3),
  (22, 11, 'Ácido fólico 1 mg', '5 ml cada 8 horas', 10),
  (23, 12, 'Amlodipino 5 mg', '1 comprimido al día', 7),
  (24, 12, 'Aspirina 100 mg', '1 sobre cada 6 horas', 5),
  (25, 12, 'Enalapril 10 mg', '5 ml cada 8 horas', 10),
  (26, 13, 'Omeprazol 20 mg', '1 comprimido cada 8 horas', 7),
  (27, 14, 'Paracetamol 1 g', '2 inhalaciones cada 6 horas', 7),
  (28, 15, 'Loratadina 10 mg', '1 sobre cada 6 horas', 60),
  (29, 15, 'Paracetamol 500 mg', '5 ml cada 8 horas', 14),
  (30, 16, 'Enalapril 10 mg', '1 comprimido cada 12 horas', 5),
  (31, 16, 'Amlodipino 5 mg', '2 inhalaciones cada 6 horas', 30),
  (32, 16, 'Losartán 50 mg', '2 inhalaciones cada 6 horas', 60),
  (33, 17, 'Omeprazol 20 mg', '1 comprimido cada 8 horas', 90),
  (34, 17, 'Paracetamol 500 mg', '2 inhalaciones cada 6 horas', 30),
  (35, 18, 'Diclofenaco gel 1%', 'Aplicar 2 veces al día', 60),
  (36, 18, 'Ketoprofeno 100 mg', '1 comprimido cada 8 horas', 14),
  (37, 19, 'Amlodipino 5 mg', '1 comprimido cada 12 horas', 3),
  (38, 19, 'Aspirina 100 mg', '1 comprimido cada 12 horas', 3),
  (39, 20, 'Loratadina 10 mg', 'Aplicar 2 veces al día', 5),
  (40, 20, 'Paracetamol 500 mg', 'Aplicar 2 veces al día', 90),
  (41, 21, 'Paracetamol 500 mg', '1 comprimido al día', 30),
  (42, 22, 'Hidrocortisona crema 1%', '1 comprimido cada 8 horas', 14),
  (43, 22, 'Cetirizina 10 mg', 'Aplicar 2 veces al día', 10),
  (44, 23, 'Amoxicilina suspensión 250 mg', '1 gota en cada ojo cada 8 horas', 90),
  (45, 23, 'Ibuprofeno jarabe 100 mg/5 ml', 'Aplicar 2 veces al día', 5),
  (46, 23, 'Salbutamol inhalador', '1 gota en cada ojo cada 8 horas', 30),
  (47, 24, 'Clonazepam 0,5 mg', 'Aplicar 2 veces al día', 14),
  (48, 24, 'Sertralina 50 mg', '1 comprimido cada 8 horas', 60),
  (49, 25, 'Diclofenaco gel 1%', '2 inhalaciones cada 6 horas', 30),
  (50, 25, 'Ciclobenzaprina 10 mg', '1 gota en cada ojo cada 8 horas', 5),
  (51, 26, 'Hidrocortisona crema 1%', 'Aplicar 2 veces al día', 60),
  (52, 26, 'Cetirizina 10 mg', '1 comprimido cada 12 horas', 10),
  (53, 27, 'Ibuprofeno 400 mg', '1 gota en cada ojo cada 8 horas', 5),
  (54, 27, 'Loratadina 10 mg', '2 inhalaciones cada 6 horas', 10),
  (55, 28, 'Amoxicilina suspensión 250 mg', '1 sobre cada 6 horas', 14),
  (56, 28, 'Paracetamol jarabe 120 mg/5 ml', '1 sobre cada 6 horas', 90),
  (57, 29, 'Amoxicilina 500 mg', '1 comprimido cada 8 horas', 14),
  (58, 30, 'Omeprazol 20 mg', '1 gota en cada ojo cada 8 horas', 30),
  (59, 30, 'Paracetamol 500 mg', '1 gota en cada ojo cada 8 horas', 10),
  (60, 31, 'Ciclobenzaprina 10 mg', '1 gota en cada ojo cada 8 horas', 5),
  (61, 31, 'Paracetamol 1 g', '1 comprimido cada 8 horas', 90),
  (62, 32, 'Omeprazol 20 mg', '1 gota en cada ojo cada 8 horas', 14),
  (63, 32, 'Loratadina 10 mg', '1 comprimido cada 12 horas', 7),
  (64, 33, 'Ibuprofeno 600 mg', '1 comprimido al día', 30),
  (65, 33, 'Mometasona spray nasal', '1 comprimido cada 8 horas', 7),
  (66, 34, 'Sulfato ferroso 200 mg', '2 inhalaciones cada 6 horas', 60),
  (67, 34, 'Nitrofurantoína 100 mg', '1 comprimido cada 12 horas', 90),
  (68, 34, 'Fluconazol 150 mg', '1 sobre cada 6 horas', 30),
  (69, 35, 'Omeprazol 20 mg', 'Aplicar 2 veces al día', 14),
  (70, 36, 'Amoxicilina 500 mg', '1 comprimido cada 12 horas', 60),
  (71, 36, 'Omeprazol 20 mg', '1 comprimido al día', 14),
  (72, 36, 'Paracetamol 500 mg', '2 inhalaciones cada 6 horas', 90),
  (73, 37, 'Loratadina 10 mg', '1 comprimido cada 8 horas', 10),
  (74, 37, 'Omeprazol 20 mg', '1 comprimido al día', 3),
  (75, 38, 'Atorvastatina 20 mg', '5 ml cada 8 horas', 30),
  (76, 38, 'Losartán 50 mg', '1 sobre cada 6 horas', 30),
  (77, 39, 'Amitriptilina 25 mg', 'Aplicar 2 veces al día', 90),
  (78, 39, 'Pregabalina 75 mg', '1 comprimido cada 12 horas', 3),
  (79, 39, 'Ácido valproico 500 mg', '1 comprimido cada 12 horas', 60),
  (80, 40, 'Amoxicilina suspensión 250 mg', '1 comprimido cada 12 horas', 90),
  (81, 40, 'Sales de rehidratación oral', '2 inhalaciones cada 6 horas', 30),
  (82, 41, 'Ketoprofeno 100 mg', 'Aplicar 2 veces al día', 10),
  (83, 42, 'Sulfato ferroso 200 mg', '1 sobre cada 6 horas', 5),
  (84, 42, 'Fluconazol 150 mg', '2 inhalaciones cada 6 horas', 90),
  (85, 42, 'Nitrofurantoína 100 mg', '5 ml cada 8 horas', 7),
  (86, 43, 'Atorvastatina 20 mg', '1 sobre cada 6 horas', 5),
  (87, 43, 'Aspirina 100 mg', '5 ml cada 8 horas', 7),
  (88, 44, 'Diclofenaco gel 1%', '1 gota en cada ojo cada 8 horas', 14),
  (89, 44, 'Ketoprofeno 100 mg', '1 comprimido al día', 7),
  (90, 45, 'Fluconazol 150 mg', 'Aplicar 2 veces al día', 5),
  (91, 45, 'Ácido fólico 1 mg', '5 ml cada 8 horas', 5),
  (92, 46, 'Omeprazol 20 mg', 'Aplicar 2 veces al día', 60),
  (93, 46, 'Paracetamol 500 mg', '1 gota en cada ojo cada 8 horas', 7),
  (94, 47, 'Paracetamol jarabe 120 mg/5 ml', '1 comprimido al día', 60),
  (95, 47, 'Salbutamol inhalador', 'Aplicar 2 veces al día', 5),
  (96, 48, 'Amoxicilina 500 mg', 'Aplicar 2 veces al día', 3),
  (97, 48, 'Ibuprofeno 400 mg', '1 comprimido al día', 90),
  (98, 49, 'Omeprazol 20 mg', '1 comprimido cada 8 horas', 30),
  (99, 49, 'Amoxicilina 500 mg', 'Aplicar 2 veces al día', 5),
  (100, 49, 'Ibuprofeno 400 mg', '5 ml cada 8 horas', 3),
  (101, 50, 'Amitriptilina 25 mg', '1 gota en cada ojo cada 8 horas', 30),
  (102, 51, 'Ibuprofeno 400 mg', '5 ml cada 8 horas', 3),
  (103, 51, 'Omeprazol 20 mg', '1 comprimido al día', 7),
  (104, 52, 'Diclofenaco gel 1%', '2 inhalaciones cada 6 horas', 10),
  (105, 52, 'Ketoprofeno 100 mg', '1 comprimido cada 8 horas', 30),
  (106, 53, 'Hidrocortisona crema 1%', '1 comprimido al día', 90),
  (107, 53, 'Cetirizina 10 mg', 'Aplicar 2 veces al día', 30),
  (108, 53, 'Emoliente dermatológico', '5 ml cada 8 horas', 30),
  (109, 54, 'Emoliente dermatológico', '2 inhalaciones cada 6 horas', 30),
  (110, 54, 'Clotrimazol crema 1%', '1 comprimido cada 12 horas', 30),
  (111, 55, 'Sumatriptán 50 mg', '1 comprimido cada 8 horas', 10),
  (112, 55, 'Ácido valproico 500 mg', '1 gota en cada ojo cada 8 horas', 5),
  (113, 56, 'Aspirina 100 mg', '1 comprimido al día', 60),
  (114, 56, 'Enalapril 10 mg', '1 comprimido cada 8 horas', 30),
  (115, 57, 'Amlodipino 5 mg', '5 ml cada 8 horas', 90),
  (116, 58, 'Clotrimazol crema 1%', '1 sobre cada 6 horas', 30),
  (117, 58, 'Emoliente dermatológico', '5 ml cada 8 horas', 90),
  (118, 59, 'Ácido fólico 1 mg', '1 gota en cada ojo cada 8 horas', 7),
  (119, 60, 'Tobramicina colirio', '1 comprimido al día', 90),
  (120, 60, 'Timolol colirio 0,5%', '2 inhalaciones cada 6 horas', 10),
  (121, 60, 'Lágrimas artificiales', '1 gota en cada ojo cada 8 horas', 3),
  (122, 61, 'Hidrocortisona crema 1%', '1 comprimido al día', 60),
  (123, 61, 'Clotrimazol crema 1%', '1 comprimido cada 12 horas', 14),
  (124, 62, 'Paracetamol 500 mg', 'Aplicar 2 veces al día', 90),
  (125, 62, 'Loratadina 10 mg', '1 gota en cada ojo cada 8 horas', 90),
  (126, 63, 'Hidrocortisona crema 1%', 'Aplicar 2 veces al día', 10),
  (127, 63, 'Clotrimazol crema 1%', '5 ml cada 8 horas', 7),
  (128, 63, 'Emoliente dermatológico', '1 comprimido cada 8 horas', 90),
  (129, 64, 'Salbutamol inhalador', '1 gota en cada ojo cada 8 horas', 3),
  (130, 64, 'Sales de rehidratación oral', '1 comprimido cada 12 horas', 60),
  (131, 64, 'Paracetamol jarabe 120 mg/5 ml', '1 gota en cada ojo cada 8 horas', 90),
  (132, 65, 'Pregabalina 75 mg', '1 comprimido cada 12 horas', 90),
  (133, 65, 'Ácido valproico 500 mg', '1 sobre cada 6 horas', 60),
  (134, 66, 'Salbutamol inhalador', '1 gota en cada ojo cada 8 horas', 3),
  (135, 66, 'Sales de rehidratación oral', '1 comprimido al día', 60),
  (136, 66, 'Ibuprofeno jarabe 100 mg/5 ml', '5 ml cada 8 horas', 90),
  (137, 67, 'Salbutamol inhalador', '1 sobre cada 6 horas', 10),
  (138, 67, 'Sales de rehidratación oral', '5 ml cada 8 horas', 10),
  (139, 68, 'Amoxicilina suspensión 250 mg', '2 inhalaciones cada 6 horas', 60),
  (140, 68, 'Paracetamol jarabe 120 mg/5 ml', '1 comprimido cada 12 horas', 5),
  (141, 68, 'Ibuprofeno jarabe 100 mg/5 ml', '1 comprimido cada 12 horas', 10),
  (142, 69, 'Salbutamol inhalador', '2 inhalaciones cada 6 horas', 3),
  (143, 70, 'Lágrimas artificiales', '1 gota en cada ojo cada 8 horas', 90),
  (144, 70, 'Timolol colirio 0,5%', '1 comprimido cada 8 horas', 90);
