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
    DECLARE v_choque INT DEFAULT 0;

    IF NEW.fecha <> OLD.fecha
       OR NEW.hora_inicio <> OLD.hora_inicio
       OR NEW.rut_medico <> OLD.rut_medico THEN

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
  (1, DATE_ADD(CURDATE(), INTERVAL -67 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '21647072-9', '19000111-3', 1, 1, 3),
  (2, DATE_ADD(CURDATE(), INTERVAL -66 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '20485571-4', '16777888-7', 8, 4, 3),
  (3, DATE_ADD(CURDATE(), INTERVAL -48 DAY), '14:30:00', ADDTIME('14:30:00', '00:30:00'), '14661009-9', '22555666-0', 1, 5, 3),
  (4, DATE_ADD(CURDATE(), INTERVAL -25 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '21847332-6', '15666777-3', 7, 3, 5),
  (5, DATE_ADD(CURDATE(), INTERVAL -15 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '5460868-3', '20111222-2', 5, 4, 3),
  (6, DATE_ADD(CURDATE(), INTERVAL -50 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '27338720-K', '20111222-2', 3, 4, 5),
  (7, DATE_ADD(CURDATE(), INTERVAL -73 DAY), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '6511345-7', '21444555-7', 1, 5, 3),
  (8, DATE_ADD(CURDATE(), INTERVAL -2 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '13847158-6', '14555666-K', 6, 2, 3),
  (9, DATE_ADD(CURDATE(), INTERVAL -27 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '9356233-K', '11222333-9', 2, 1, 4),
  (10, DATE_ADD(CURDATE(), INTERVAL -47 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '21915368-6', '9222333-7', 2, 2, 3),
  (11, DATE_ADD(CURDATE(), INTERVAL -77 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '11429746-1', '11222333-9', 1, 1, 5),
  (12, DATE_ADD(CURDATE(), INTERVAL -90 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '21847332-6', '13444555-6', 4, 2, 3),
  (13, DATE_ADD(CURDATE(), INTERVAL -26 DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '13553248-7', '8333444-4', 6, 4, 3),
  (14, DATE_ADD(CURDATE(), INTERVAL -71 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '7712431-4', '22555666-0', 7, 5, 4),
  (15, DATE_ADD(CURDATE(), INTERVAL -27 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '20485571-4', '13444555-6', 4, 2, 5),
  (16, DATE_ADD(CURDATE(), INTERVAL -26 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '21647072-9', '22555666-0', 10, 3, 3),
  (17, DATE_ADD(CURDATE(), INTERVAL -30 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '9662211-2', '14555666-K', 6, 4, 3),
  (18, DATE_ADD(CURDATE(), INTERVAL -57 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '21647072-9', '14555666-K', 6, 2, 5),
  (19, DATE_ADD(CURDATE(), INTERVAL -82 DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '20485571-4', '18999000-6', 1, 3, 3),
  (20, DATE_ADD(CURDATE(), INTERVAL -47 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '9662211-2', '14555666-K', 6, 4, 3),
  (21, DATE_ADD(CURDATE(), INTERVAL -35 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '7712431-4', '13444555-6', 4, 2, 3),
  (22, DATE_ADD(CURDATE(), INTERVAL -8 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '20485571-4', '18999000-6', 1, 3, 3),
  (23, DATE_ADD(CURDATE(), INTERVAL -84 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '18628001-6', '9222333-7', 2, 3, 3),
  (24, DATE_ADD(CURDATE(), INTERVAL -67 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '14469942-4', '10111222-5', 1, 2, 3),
  (25, DATE_ADD(CURDATE(), INTERVAL -24 DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '13553248-7', '8333444-4', 6, 4, 1),
  (26, DATE_ADD(CURDATE(), INTERVAL -55 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '7712431-4', '13444555-6', 4, 2, 3),
  (27, DATE_ADD(CURDATE(), INTERVAL -7 DAY), '14:30:00', ADDTIME('14:30:00', '00:30:00'), '6663624-0', '14555666-K', 1, 4, 4),
  (28, DATE_ADD(CURDATE(), INTERVAL -47 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '18232133-8', '21444555-7', 1, 2, 4),
  (29, DATE_ADD(CURDATE(), INTERVAL -11 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '21915368-6', '9222333-7', 2, 3, 3),
  (30, DATE_ADD(CURDATE(), INTERVAL -80 DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '5460868-3', '10111222-5', 1, 2, 3),
  (31, DATE_ADD(CURDATE(), INTERVAL -77 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '21915368-6', '11222333-9', 2, 1, 3),
  (32, DATE_ADD(CURDATE(), INTERVAL -77 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '21847332-6', '20111222-2', 5, 4, 3),
  (33, DATE_ADD(CURDATE(), INTERVAL -22 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '13847158-6', '22555666-0', 7, 5, 4),
  (34, DATE_ADD(CURDATE(), INTERVAL -25 DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '27231161-7', '17888999-0', 3, 4, 3),
  (35, DATE_ADD(CURDATE(), INTERVAL -9 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '9662211-2', '8333444-4', 6, 1, 4),
  (36, DATE_ADD(CURDATE(), INTERVAL -13 DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '11429746-1', '22555666-0', 7, 3, 3),
  (37, DATE_ADD(CURDATE(), INTERVAL -94 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '21915368-6', '13444555-6', 4, 2, 3),
  (38, DATE_ADD(CURDATE(), INTERVAL -21 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '21915368-6', '18999000-6', 2, 3, 3),
  (39, DATE_ADD(CURDATE(), INTERVAL -94 DAY), '09:30:00', ADDTIME('09:30:00', '00:30:00'), '18628001-6', '21444555-7', 9, 2, 3),
  (40, DATE_ADD(CURDATE(), INTERVAL -61 DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '24606690-6', '17888999-0', 3, 2, 3),
  (41, DATE_ADD(CURDATE(), INTERVAL -30 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '24914536-K', '10111222-5', 3, 2, 3),
  (42, DATE_ADD(CURDATE(), INTERVAL -7 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '13847158-6', '11222333-9', 2, 1, 3),
  (43, DATE_ADD(CURDATE(), INTERVAL -53 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '20013704-3', '14555666-K', 6, 4, 2),
  (44, DATE_ADD(CURDATE(), INTERVAL -9 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '18232133-8', '19000111-3', 4, 5, 3),
  (45, DATE_ADD(CURDATE(), INTERVAL -42 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '13847158-6', '22555666-0', 10, 3, 4),
  (46, DATE_ADD(CURDATE(), INTERVAL -61 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '15353079-3', '12333444-2', 5, 1, 2),
  (47, DATE_ADD(CURDATE(), INTERVAL -2 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '18628001-6', '19000111-3', 1, 1, 3),
  (48, DATE_ADD(CURDATE(), INTERVAL -11 DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '20485571-4', '21444555-7', 1, 5, 3),
  (49, DATE_ADD(CURDATE(), INTERVAL -18 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '9662211-2', '8333444-4', 6, 4, 3),
  (50, DATE_ADD(CURDATE(), INTERVAL -63 DAY), '09:30:00', ADDTIME('09:30:00', '00:30:00'), '27325630-K', '10111222-5', 3, 2, 3),
  (51, DATE_ADD(CURDATE(), INTERVAL -34 DAY), '14:30:00', ADDTIME('14:30:00', '00:30:00'), '20485571-4', '11222333-9', 1, 1, 3),
  (52, DATE_ADD(CURDATE(), INTERVAL -48 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '21915368-6', '11222333-9', 1, 1, 3),
  (53, DATE_ADD(CURDATE(), INTERVAL -21 DAY), '09:30:00', ADDTIME('09:30:00', '00:30:00'), '13116706-7', '9222333-7', 2, 3, 3),
  (54, DATE_ADD(CURDATE(), INTERVAL -11 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '20013704-3', '15666777-3', 1, 3, 4),
  (55, DATE_ADD(CURDATE(), INTERVAL -84 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '20485571-4', '19000111-3', 1, 5, 5),
  (56, DATE_ADD(CURDATE(), INTERVAL -11 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '13553248-7', '9222333-7', 2, 2, 5),
  (57, DATE_ADD(CURDATE(), INTERVAL -29 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '13847158-6', '21444555-7', 9, 2, 1),
  (58, DATE_ADD(CURDATE(), INTERVAL -36 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '14469942-4', '15666777-3', 1, 3, 3),
  (59, DATE_ADD(CURDATE(), INTERVAL -28 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '9662211-2', '16777888-7', 8, 3, 4),
  (60, DATE_ADD(CURDATE(), INTERVAL -78 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '13116706-7', '10111222-5', 1, 2, 3),
  (61, DATE_ADD(CURDATE(), INTERVAL -45 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '20048937-3', '12333444-2', 5, 1, 4),
  (62, DATE_ADD(CURDATE(), INTERVAL -25 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '18628001-6', '13444555-6', 4, 2, 3),
  (63, DATE_ADD(CURDATE(), INTERVAL -22 DAY), '09:30:00', ADDTIME('09:30:00', '00:30:00'), '11429746-1', '21444555-7', 1, 2, 5),
  (64, DATE_ADD(CURDATE(), INTERVAL -73 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '5460868-3', '14555666-K', 1, 4, 3),
  (65, DATE_ADD(CURDATE(), INTERVAL -37 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '11429746-1', '18999000-6', 5, 1, 1),
  (66, DATE_ADD(CURDATE(), INTERVAL -72 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '6511345-7', '9222333-7', 2, 3, 2),
  (67, DATE_ADD(CURDATE(), INTERVAL -92 DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '6511345-7', '13444555-6', 4, 2, 2),
  (68, DATE_ADD(CURDATE(), INTERVAL -84 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '20485571-4', '18999000-6', 1, 3, 3),
  (69, DATE_ADD(CURDATE(), INTERVAL -77 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '5460868-3', '16777888-7', 8, 3, 4),
  (70, DATE_ADD(CURDATE(), INTERVAL -88 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '21915368-6', '16777888-7', 8, 4, 4),
  (71, DATE_ADD(CURDATE(), INTERVAL -92 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '17728730-K', '13444555-6', 4, 2, 3),
  (72, DATE_ADD(CURDATE(), INTERVAL -11 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '9356233-K', '8333444-4', 6, 1, 3),
  (73, DATE_ADD(CURDATE(), INTERVAL -67 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '21847332-6', '14555666-K', 1, 2, 3),
  (74, DATE_ADD(CURDATE(), INTERVAL -27 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '21647072-9', '20111222-2', 5, 4, 3),
  (75, DATE_ADD(CURDATE(), INTERVAL -5 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '15353079-3', '13444555-6', 4, 2, 1),
  (76, DATE_ADD(CURDATE(), INTERVAL -18 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '20485571-4', '19000111-3', 4, 1, 3),
  (77, DATE_ADD(CURDATE(), INTERVAL -81 DAY), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '21647072-9', '11222333-9', 2, 1, 3),
  (78, DATE_ADD(CURDATE(), INTERVAL -73 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '17728730-K', '15666777-3', 7, 3, 3),
  (79, DATE_ADD(CURDATE(), INTERVAL -92 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '26444633-3', '17888999-0', 3, 2, 2),
  (80, DATE_ADD(CURDATE(), INTERVAL -49 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '13553248-7', '15666777-3', 1, 3, 3),
  (81, DATE_ADD(CURDATE(), INTERVAL -37 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '5460868-3', '13444555-6', 4, 2, 3),
  (82, DATE_ADD(CURDATE(), INTERVAL -82 DAY), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '14661009-9', '14555666-K', 1, 2, 5),
  (83, DATE_ADD(CURDATE(), INTERVAL -47 DAY), '09:30:00', ADDTIME('09:30:00', '00:30:00'), '9659846-7', '12333444-2', 5, 3, 3),
  (84, DATE_ADD(CURDATE(), INTERVAL -85 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '6511345-7', '12333444-2', 5, 3, 3),
  (85, DATE_ADD(CURDATE(), INTERVAL -28 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '21847332-6', '11222333-9', 1, 1, 4),
  (86, DATE_ADD(CURDATE(), INTERVAL -91 DAY), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '13553248-7', '22555666-0', 10, 3, 3),
  (87, DATE_ADD(CURDATE(), INTERVAL -38 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '20013704-3', '12333444-2', 5, 3, 5),
  (88, DATE_ADD(CURDATE(), INTERVAL -34 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '24956132-0', '17888999-0', 3, 2, 5),
  (89, DATE_ADD(CURDATE(), INTERVAL -78 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '21915368-6', '9222333-7', 2, 2, 3),
  (90, DATE_ADD(CURDATE(), INTERVAL -74 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '21847332-6', '11222333-9', 2, 1, 3),
  (91, DATE_ADD(CURDATE(), INTERVAL -86 DAY), '17:00:00', ADDTIME('17:00:00', '00:30:00'), '13847158-6', '10111222-5', 1, 1, 4),
  (92, DATE_ADD(CURDATE(), INTERVAL -56 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '14661009-9', '21444555-7', 1, 2, 4),
  (93, DATE_ADD(CURDATE(), INTERVAL -7 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '24914536-K', '20111222-2', 3, 4, 4),
  (94, DATE_ADD(CURDATE(), INTERVAL -55 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '21647072-9', '16777888-7', 8, 3, 4),
  (95, DATE_ADD(CURDATE(), INTERVAL -19 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '21647072-9', '12333444-2', 5, 3, 3),
  (96, DATE_ADD(CURDATE(), INTERVAL -20 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '6663624-0', '8333444-4', 6, 4, 3),
  (97, DATE_ADD(CURDATE(), INTERVAL -93 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '21847332-6', '16777888-7', 8, 3, 3),
  (98, DATE_ADD(CURDATE(), INTERVAL -28 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '21647072-9', '10111222-5', 1, 1, 4),
  (99, DATE_ADD(CURDATE(), INTERVAL -29 DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '26457849-3', '17888999-0', 3, 4, 4),
  (100, DATE_ADD(CURDATE(), INTERVAL -21 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '6663624-0', '8333444-4', 6, 4, 4),
  (101, DATE_ADD(CURDATE(), INTERVAL -80 DAY), '14:30:00', ADDTIME('14:30:00', '00:30:00'), '24914536-K', '10111222-5', 3, 1, 1),
  (102, DATE_ADD(CURDATE(), INTERVAL -74 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '7712431-4', '12333444-2', 5, 3, 3),
  (103, DATE_ADD(CURDATE(), INTERVAL -42 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '20485571-4', '19000111-3', 4, 1, 3),
  (104, DATE_ADD(CURDATE(), INTERVAL -89 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '21647072-9', '12333444-2', 5, 1, 3),
  (105, DATE_ADD(CURDATE(), INTERVAL -85 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '25514128-7', '10111222-5', 3, 1, 3),
  (106, DATE_ADD(CURDATE(), INTERVAL -5 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '15353079-3', '15666777-3', 1, 3, 3),
  (107, DATE_ADD(CURDATE(), INTERVAL -10 DAY), '09:30:00', ADDTIME('09:30:00', '00:30:00'), '24914536-K', '17888999-0', 3, 4, 3),
  (108, DATE_ADD(CURDATE(), INTERVAL -15 DAY), '09:30:00', ADDTIME('09:30:00', '00:30:00'), '11429746-1', '10111222-5', 1, 1, 3),
  (109, DATE_ADD(CURDATE(), INTERVAL -58 DAY), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '26444633-3', '20111222-2', 3, 4, 3),
  (110, DATE_ADD(CURDATE(), INTERVAL -69 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '24606690-6', '20111222-2', 3, 4, 3),
  (111, DATE_ADD(CURDATE(), INTERVAL -62 DAY), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '9662211-2', '12333444-2', 5, 1, 5),
  (112, DATE_ADD(CURDATE(), INTERVAL -89 DAY), '17:30:00', ADDTIME('17:30:00', '00:30:00'), '6511345-7', '18999000-6', 1, 3, 2),
  (113, DATE_ADD(CURDATE(), INTERVAL -45 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '21847332-6', '16777888-7', 8, 3, 3),
  (114, CURDATE(), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '24606690-6', '10111222-5', 3, 2, 1),
  (115, CURDATE(), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '26613011-2', '10111222-5', 3, 1, 2),
  (116, CURDATE(), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '13847158-6', '10111222-5', 1, 2, 2),
  (117, CURDATE(), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '13847158-6', '11222333-9', 2, 1, 2),
  (118, CURDATE(), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '15627806-8', '11222333-9', 2, 1, 2),
  (119, CURDATE(), '11:00:00', ADDTIME('11:00:00', '00:30:00'), '9662211-2', '11222333-9', 2, 1, 2),
  (120, CURDATE(), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '17737289-7', '12333444-2', 5, 1, 2),
  (121, CURDATE(), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '14469942-4', '12333444-2', 5, 3, 1),
  (122, CURDATE(), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '21647072-9', '12333444-2', 5, 1, 2),
  (123, CURDATE(), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '20048937-3', '13444555-6', 4, 2, 1),
  (124, CURDATE(), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '6663624-0', '13444555-6', 4, 2, 2),
  (125, CURDATE(), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '20048937-3', '13444555-6', 4, 2, 1),
  (126, DATE_ADD(CURDATE(), INTERVAL 33 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '27325630-K', '10111222-5', 3, 1, 2),
  (127, DATE_ADD(CURDATE(), INTERVAL 40 DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '5460868-3', '10111222-5', 1, 1, 5),
  (128, DATE_ADD(CURDATE(), INTERVAL 2 DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '5700968-3', '10111222-5', 1, 1, 2),
  (129, DATE_ADD(CURDATE(), INTERVAL 41 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '7712431-4', '11222333-9', 2, 1, 1),
  (130, DATE_ADD(CURDATE(), INTERVAL 21 DAY), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '6080013-8', '11222333-9', 1, 1, 2),
  (131, DATE_ADD(CURDATE(), INTERVAL 29 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '15627806-8', '11222333-9', 1, 1, 2),
  (132, DATE_ADD(CURDATE(), INTERVAL 19 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '21915368-6', '12333444-2', 5, 1, 2),
  (133, DATE_ADD(CURDATE(), INTERVAL 14 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '21847332-6', '12333444-2', 5, 1, 2),
  (134, DATE_ADD(CURDATE(), INTERVAL 7 DAY), '15:00:00', ADDTIME('15:00:00', '00:30:00'), '13116706-7', '12333444-2', 5, 1, 1),
  (135, DATE_ADD(CURDATE(), INTERVAL 35 DAY), '12:00:00', ADDTIME('12:00:00', '00:30:00'), '5460868-3', '13444555-6', 4, 2, 2),
  (136, DATE_ADD(CURDATE(), INTERVAL 23 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '21847332-6', '13444555-6', 4, 2, 2),
  (137, DATE_ADD(CURDATE(), INTERVAL 40 DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '18628001-6', '13444555-6', 4, 2, 1),
  (138, DATE_ADD(CURDATE(), INTERVAL 38 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '9659846-7', '14555666-K', 1, 4, 1),
  (139, DATE_ADD(CURDATE(), INTERVAL 4 DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '15353079-3', '14555666-K', 1, 2, 5),
  (140, DATE_ADD(CURDATE(), INTERVAL 20 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '7712431-4', '14555666-K', 1, 4, 2),
  (141, DATE_ADD(CURDATE(), INTERVAL 25 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '13553248-7', '15666777-3', 1, 3, 5),
  (142, DATE_ADD(CURDATE(), INTERVAL 28 DAY), '14:30:00', ADDTIME('14:30:00', '00:30:00'), '7712431-4', '15666777-3', 1, 3, 2),
  (143, DATE_ADD(CURDATE(), INTERVAL 2 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '9662211-2', '15666777-3', 7, 3, 1),
  (144, DATE_ADD(CURDATE(), INTERVAL 40 DAY), '16:30:00', ADDTIME('16:30:00', '00:30:00'), '14469942-4', '16777888-7', 8, 3, 2),
  (145, DATE_ADD(CURDATE(), INTERVAL 13 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '21647072-9', '16777888-7', 8, 3, 2),
  (146, DATE_ADD(CURDATE(), INTERVAL 14 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '5700968-3', '16777888-7', 8, 4, 2),
  (147, DATE_ADD(CURDATE(), INTERVAL 34 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '26444633-3', '17888999-0', 3, 2, 1),
  (148, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '24606690-6', '17888999-0', 3, 4, 1),
  (149, DATE_ADD(CURDATE(), INTERVAL 41 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '24914536-K', '17888999-0', 3, 2, 2),
  (150, DATE_ADD(CURDATE(), INTERVAL 32 DAY), '11:30:00', ADDTIME('11:30:00', '00:30:00'), '7712431-4', '18999000-6', 1, 1, 2),
  (151, DATE_ADD(CURDATE(), INTERVAL 16 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '15353079-3', '18999000-6', 1, 3, 1),
  (152, DATE_ADD(CURDATE(), INTERVAL 28 DAY), '10:00:00', ADDTIME('10:00:00', '00:30:00'), '14661009-9', '18999000-6', 5, 1, 1),
  (153, DATE_ADD(CURDATE(), INTERVAL 28 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '6080013-8', '19000111-3', 4, 5, 1),
  (154, DATE_ADD(CURDATE(), INTERVAL 31 DAY), '10:30:00', ADDTIME('10:30:00', '00:30:00'), '11429746-1', '19000111-3', 1, 1, 2),
  (155, DATE_ADD(CURDATE(), INTERVAL 28 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '7712431-4', '19000111-3', 1, 1, 1),
  (156, DATE_ADD(CURDATE(), INTERVAL 23 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '5460868-3', '20111222-2', 5, 4, 1),
  (157, DATE_ADD(CURDATE(), INTERVAL 28 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '26646933-0', '20111222-2', 3, 4, 1),
  (158, DATE_ADD(CURDATE(), INTERVAL 41 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '20013704-3', '20111222-2', 5, 4, 1),
  (159, DATE_ADD(CURDATE(), INTERVAL 38 DAY), '12:30:00', ADDTIME('12:30:00', '00:30:00'), '5460868-3', '9222333-7', 2, 2, 2),
  (160, DATE_ADD(CURDATE(), INTERVAL 3 DAY), '13:00:00', ADDTIME('13:00:00', '00:30:00'), '18929971-0', '9222333-7', 2, 3, 5),
  (161, DATE_ADD(CURDATE(), INTERVAL 17 DAY), '16:00:00', ADDTIME('16:00:00', '00:30:00'), '13553248-7', '9222333-7', 2, 2, 1),
  (162, DATE_ADD(CURDATE(), INTERVAL 20 DAY), '13:30:00', ADDTIME('13:30:00', '00:30:00'), '13847158-6', '8333444-4', 6, 1, 2),
  (163, DATE_ADD(CURDATE(), INTERVAL 13 DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '5700968-3', '8333444-4', 6, 4, 5),
  (164, DATE_ADD(CURDATE(), INTERVAL 22 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '5700968-3', '8333444-4', 6, 4, 2),
  (165, DATE_ADD(CURDATE(), INTERVAL 7 DAY), '15:30:00', ADDTIME('15:30:00', '00:30:00'), '18232133-8', '21444555-7', 1, 5, 2),
  (166, DATE_ADD(CURDATE(), INTERVAL 25 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '7712431-4', '21444555-7', 1, 5, 2),
  (167, DATE_ADD(CURDATE(), INTERVAL 17 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '14661009-9', '21444555-7', 1, 5, 2),
  (168, DATE_ADD(CURDATE(), INTERVAL 3 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '6511345-7', '22555666-0', 1, 5, 5),
  (169, DATE_ADD(CURDATE(), INTERVAL 4 DAY), '14:00:00', ADDTIME('14:00:00', '00:30:00'), '17737289-7', '22555666-0', 7, 5, 1),
  (170, DATE_ADD(CURDATE(), INTERVAL 20 DAY), '09:00:00', ADDTIME('09:00:00', '00:30:00'), '11429746-1', '22555666-0', 10, 3, 2);

INSERT INTO atencion (id_atencion, id_cita, motivo, observaciones) VALUES
  (1, 1, 'Control de morbilidad general', 'Se solicitan exámenes complementarios para el próximo control.'),
  (2, 2, 'Molestias visuales al leer', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (3, 3, 'Control de morbilidad general', 'Se solicitan exámenes complementarios para el próximo control.'),
  (4, 5, 'Prurito y enrojecimiento', 'Se solicitan exámenes complementarios para el próximo control.'),
  (5, 7, 'Control de morbilidad general', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (6, 8, 'Control de método anticonceptivo', 'Evolución favorable respecto al control anterior.'),
  (7, 10, 'Control de presión arterial elevada', 'Evolución favorable respecto al control anterior.'),
  (8, 12, 'Control post esguince', 'Se solicitan exámenes complementarios para el próximo control.'),
  (9, 13, 'Molestias urinarias a repetición', 'Sin signos de alarma al examen físico. Se refuerzan indicaciones.'),
  (10, 16, 'Dificultad para conciliar el sueño', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (11, 17, 'Molestias urinarias a repetición', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (12, 19, 'Chequeo preventivo anual', 'Se ajusta dosis del tratamiento habitual.'),
  (13, 20, 'Control de método anticonceptivo', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (14, 21, 'Dolor lumbar persistente', 'Se ajusta dosis del tratamiento habitual.'),
  (15, 22, 'Control de morbilidad general', 'Se ajusta dosis del tratamiento habitual.'),
  (16, 23, 'Control de presión arterial elevada', 'Se ajusta dosis del tratamiento habitual.'),
  (17, 24, 'Chequeo preventivo anual', 'Se deriva a especialista para evaluación complementaria.'),
  (18, 26, 'Control post esguince', 'Se deriva a especialista para evaluación complementaria.'),
  (19, 29, 'Control de presión arterial elevada', 'Se ajusta dosis del tratamiento habitual.'),
  (20, 30, 'Cuadro respiratorio agudo', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (21, 31, 'Revisión de exámenes de laboratorio', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (22, 32, 'Prurito y enrojecimiento', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (23, 34, 'Tos persistente', 'Se deriva a especialista para evaluación complementaria.'),
  (24, 36, 'Mareos y episodios de inestabilidad', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (25, 37, 'Control post esguince', 'Evolución favorable respecto al control anterior.'),
  (26, 38, 'Revisión de exámenes de laboratorio', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (27, 39, 'Dolor de oído hace dos días', 'Se solicitan exámenes complementarios para el próximo control.'),
  (28, 40, 'Tos persistente', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (29, 41, 'Control de niño sano', 'Se ajusta dosis del tratamiento habitual.'),
  (30, 42, 'Control de presión arterial elevada', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (31, 44, 'Dolor de rodilla al caminar', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (32, 47, 'Chequeo preventivo anual', 'Se deriva a especialista para evaluación complementaria.'),
  (33, 48, 'Control de morbilidad general', 'Se ajusta dosis del tratamiento habitual.'),
  (34, 49, 'Control ginecológico anual', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (35, 50, 'Tos persistente', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (36, 51, 'Chequeo preventivo anual', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (37, 52, 'Chequeo preventivo anual', 'Sin signos de alarma al examen físico. Se refuerzan indicaciones.'),
  (38, 53, 'Palpitaciones al esfuerzo', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (39, 58, 'Control de morbilidad general', 'Se deriva a especialista para evaluación complementaria.'),
  (40, 60, 'Molestias digestivas recurrentes', 'Se ajusta dosis del tratamiento habitual.'),
  (41, 62, 'Control post esguince', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (42, 64, 'Chequeo preventivo anual', 'Se solicitan exámenes complementarios para el próximo control.'),
  (43, 68, 'Cuadro respiratorio agudo', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (44, 71, 'Control post esguince', 'Se deriva a especialista para evaluación complementaria.'),
  (45, 72, 'Molestias urinarias a repetición', 'Evolución favorable respecto al control anterior.'),
  (46, 73, 'Chequeo preventivo anual', 'Se ajusta dosis del tratamiento habitual.'),
  (47, 74, 'Lesión cutánea de reciente aparición', 'Evolución favorable respecto al control anterior.'),
  (48, 76, 'Dolor lumbar persistente', 'Sin signos de alarma al examen físico. Se refuerzan indicaciones.'),
  (49, 77, 'Control de presión arterial elevada', 'Se ajusta dosis del tratamiento habitual.'),
  (50, 78, 'Mareos y episodios de inestabilidad', 'Se deriva a especialista para evaluación complementaria.'),
  (51, 80, 'Cuadro respiratorio agudo', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (52, 81, 'Control post esguince', 'Se ajusta dosis del tratamiento habitual.'),
  (53, 83, 'Lesión cutánea de reciente aparición', 'Sin signos de alarma al examen físico. Se refuerzan indicaciones.'),
  (54, 84, 'Prurito y enrojecimiento', 'Sin signos de alarma al examen físico. Se refuerzan indicaciones.'),
  (55, 86, 'Cuadro ansioso reciente', 'Evolución favorable respecto al control anterior.'),
  (56, 89, 'Control de presión arterial elevada', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (57, 90, 'Control de presión arterial elevada', 'Evolución favorable respecto al control anterior.'),
  (58, 95, 'Control de tratamiento dermatológico', 'Evolución favorable respecto al control anterior.'),
  (59, 96, 'Control ginecológico anual', 'Paciente estable, se indica tratamiento ambulatorio y control en 30 días.'),
  (60, 97, 'Molestias visuales al leer', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (61, 102, 'Lesión cutánea de reciente aparición', 'Se entregan indicaciones de autocuidado y signos de alarma.'),
  (62, 103, 'Control post esguince', 'Sin signos de alarma al examen físico. Se refuerzan indicaciones.'),
  (63, 104, 'Prurito y enrojecimiento', 'Evolución favorable respecto al control anterior.'),
  (64, 105, 'Diarrea y vómitos hace 24 horas', 'Se deriva a especialista para evaluación complementaria.'),
  (65, 106, 'Cuadro respiratorio agudo', 'Se deriva a especialista para evaluación complementaria.'),
  (66, 107, 'Control de niño sano', 'Se solicitan exámenes complementarios para el próximo control.'),
  (67, 108, 'Chequeo preventivo anual', 'Sin signos de alarma al examen físico. Se refuerzan indicaciones.'),
  (68, 109, 'Diarrea y vómitos hace 24 horas', 'Evolución favorable respecto al control anterior.'),
  (69, 110, 'Tos persistente', 'Evolución favorable respecto al control anterior.'),
  (70, 113, 'Molestias visuales al leer', 'Se entregan indicaciones de autocuidado y signos de alarma.');

INSERT INTO atencion_diagnostico (id_atencion, id_diagnostico) VALUES
  (1, 1),
  (2, 7),
  (2, 19),
  (3, 1),
  (3, 16),
  (4, 17),
  (4, 6),
  (5, 16),
  (6, 12),
  (7, 2),
  (7, 16),
  (7, 3),
  (8, 17),
  (8, 10),
  (9, 9),
  (9, 12),
  (10, 19),
  (10, 13),
  (10, 8),
  (11, 9),
  (11, 12),
  (12, 1),
  (13, 12),
  (13, 9),
  (14, 10),
  (14, 4),
  (15, 1),
  (15, 9),
  (15, 2),
  (16, 20),
  (17, 9),
  (18, 4),
  (19, 16),
  (19, 2),
  (20, 2),
  (20, 15),
  (21, 3),
  (22, 18),
  (22, 6),
  (22, 17),
  (23, 1),
  (23, 5),
  (23, 14),
  (24, 13),
  (24, 8),
  (24, 19),
  (25, 4),
  (26, 2),
  (26, 3),
  (27, 15),
  (28, 1),
  (29, 1),
  (30, 2),
  (30, 16),
  (31, 17),
  (31, 4),
  (31, 10),
  (32, 4),
  (33, 19),
  (33, 16),
  (34, 12),
  (34, 9),
  (35, 5),
  (35, 14),
  (36, 4),
  (36, 15),
  (36, 16),
  (37, 19),
  (38, 3),
  (39, 1),
  (39, 16),
  (39, 19),
  (40, 19),
  (41, 4),
  (42, 16),
  (43, 1),
  (43, 19),
  (44, 17),
  (45, 9),
  (45, 12),
  (46, 4),
  (47, 6),
  (48, 17),
  (49, 16),
  (50, 19),
  (51, 15),
  (51, 4),
  (52, 17),
  (53, 18),
  (54, 18),
  (54, 17),
  (55, 13),
  (56, 3),
  (56, 16),
  (56, 20),
  (57, 16),
  (57, 2),
  (58, 6),
  (58, 18),
  (58, 17),
  (59, 9),
  (59, 12),
  (60, 19),
  (60, 7),
  (61, 18),
  (62, 10),
  (62, 4),
  (63, 18),
  (63, 17),
  (64, 5),
  (64, 1),
  (64, 15),
  (65, 16),
  (65, 9),
  (65, 2),
  (66, 14),
  (66, 15),
  (67, 19),
  (67, 1),
  (68, 11),
  (69, 14),
  (70, 7);

INSERT INTO receta (id_receta, id_atencion, medicamento, dosis, dias_tratamiento) VALUES
  (1, 1, 'Amoxicilina 500 mg', '1 comprimido cada 12 horas', 3),
  (2, 1, 'Loratadina 10 mg', '2 inhalaciones cada 6 horas', 7),
  (3, 2, 'Lágrimas artificiales', '1 comprimido cada 12 horas', 60),
  (4, 3, 'Loratadina 10 mg', '1 sobre cada 6 horas', 10),
  (5, 3, 'Omeprazol 20 mg', '1 comprimido cada 8 horas', 60),
  (6, 4, 'Hidrocortisona crema 1%', '1 gota en cada ojo cada 8 horas', 90),
  (7, 4, 'Emoliente dermatológico', '1 sobre cada 6 horas', 7),
  (8, 4, 'Clotrimazol crema 1%', '1 comprimido cada 8 horas', 14),
  (9, 5, 'Omeprazol 20 mg', '1 comprimido al día', 10),
  (10, 5, 'Loratadina 10 mg', 'Aplicar 2 veces al día', 7),
  (11, 6, 'Sulfato ferroso 200 mg', '1 comprimido cada 12 horas', 30),
  (12, 6, 'Fluconazol 150 mg', '1 gota en cada ojo cada 8 horas', 5),
  (13, 7, 'Enalapril 10 mg', '1 comprimido cada 12 horas', 14),
  (14, 7, 'Amlodipino 5 mg', '1 comprimido cada 12 horas', 5),
  (15, 8, 'Diclofenaco gel 1%', '5 ml cada 8 horas', 14),
  (16, 8, 'Ketoprofeno 100 mg', '1 comprimido cada 12 horas', 60),
  (17, 9, 'Fluconazol 150 mg', '1 sobre cada 6 horas', 5),
  (18, 9, 'Sulfato ferroso 200 mg', '1 comprimido al día', 14),
  (19, 10, 'Clonazepam 0,5 mg', '1 comprimido al día', 14),
  (20, 10, 'Sertralina 50 mg', '1 sobre cada 6 horas', 60),
  (21, 10, 'Quetiapina 25 mg', '1 comprimido cada 12 horas', 10),
  (22, 11, 'Nitrofurantoína 100 mg', '1 comprimido al día', 3),
  (23, 11, 'Fluconazol 150 mg', '1 comprimido cada 12 horas', 14),
  (24, 11, 'Sulfato ferroso 200 mg', '1 gota en cada ojo cada 8 horas', 5),
  (25, 12, 'Omeprazol 20 mg', '5 ml cada 8 horas', 3),
  (26, 13, 'Sulfato ferroso 200 mg', '5 ml cada 8 horas', 3),
  (27, 13, 'Nitrofurantoína 100 mg', 'Aplicar 2 veces al día', 90),
  (28, 13, 'Fluconazol 150 mg', '1 sobre cada 6 horas', 60),
  (29, 14, 'Ciclobenzaprina 10 mg', '1 comprimido cada 12 horas', 3),
  (30, 14, 'Diclofenaco gel 1%', '1 gota en cada ojo cada 8 horas', 90),
  (31, 15, 'Loratadina 10 mg', 'Aplicar 2 veces al día', 5),
  (32, 15, 'Paracetamol 500 mg', '2 inhalaciones cada 6 horas', 5),
  (33, 15, 'Omeprazol 20 mg', '5 ml cada 8 horas', 60),
  (34, 16, 'Aspirina 100 mg', '1 comprimido cada 12 horas', 3),
  (35, 16, 'Losartán 50 mg', '1 sobre cada 6 horas', 30),
  (36, 17, 'Ibuprofeno 400 mg', '1 gota en cada ojo cada 8 horas', 14),
  (37, 17, 'Omeprazol 20 mg', '1 gota en cada ojo cada 8 horas', 60),
  (38, 18, 'Paracetamol 1 g', '1 sobre cada 6 horas', 14),
  (39, 18, 'Diclofenaco gel 1%', 'Aplicar 2 veces al día', 10),
  (40, 18, 'Ketoprofeno 100 mg', 'Aplicar 2 veces al día', 5),
  (41, 19, 'Atorvastatina 20 mg', '5 ml cada 8 horas', 14),
  (42, 19, 'Amlodipino 5 mg', '1 gota en cada ojo cada 8 horas', 90),
  (43, 19, 'Enalapril 10 mg', '1 sobre cada 6 horas', 3),
  (44, 20, 'Omeprazol 20 mg', '1 sobre cada 6 horas', 30),
  (45, 21, 'Enalapril 10 mg', '1 comprimido cada 12 horas', 14),
  (46, 21, 'Aspirina 100 mg', '1 comprimido cada 12 horas', 3),
  (47, 21, 'Losartán 50 mg', '1 comprimido al día', 10),
  (48, 22, 'Hidrocortisona crema 1%', '2 inhalaciones cada 6 horas', 7),
  (49, 22, 'Cetirizina 10 mg', '2 inhalaciones cada 6 horas', 90),
  (50, 23, 'Sales de rehidratación oral', '1 comprimido al día', 60),
  (51, 23, 'Paracetamol jarabe 120 mg/5 ml', '1 comprimido cada 12 horas', 30),
  (52, 24, 'Sumatriptán 50 mg', '1 comprimido cada 8 horas', 3),
  (53, 25, 'Paracetamol 1 g', '1 comprimido cada 8 horas', 3),
  (54, 26, 'Aspirina 100 mg', '5 ml cada 8 horas', 3),
  (55, 26, 'Atorvastatina 20 mg', 'Aplicar 2 veces al día', 90),
  (56, 27, 'Mometasona spray nasal', '1 gota en cada ojo cada 8 horas', 5),
  (57, 27, 'Amoxicilina 875 mg', '1 comprimido cada 12 horas', 14),
  (58, 27, 'Ibuprofeno 600 mg', '1 gota en cada ojo cada 8 horas', 10),
  (59, 28, 'Paracetamol jarabe 120 mg/5 ml', '5 ml cada 8 horas', 3),
  (60, 28, 'Amoxicilina suspensión 250 mg', '1 comprimido cada 8 horas', 14),
  (61, 29, 'Salbutamol inhalador', '1 comprimido al día', 60),
  (62, 30, 'Losartán 50 mg', '1 comprimido al día', 10),
  (63, 30, 'Enalapril 10 mg', '1 comprimido cada 8 horas', 5),
  (64, 30, 'Atorvastatina 20 mg', '1 comprimido al día', 60),
  (65, 31, 'Paracetamol 1 g', '1 sobre cada 6 horas', 7),
  (66, 31, 'Ketoprofeno 100 mg', '1 comprimido al día', 10),
  (67, 31, 'Diclofenaco gel 1%', '1 comprimido cada 12 horas', 10),
  (68, 32, 'Paracetamol 500 mg', 'Aplicar 2 veces al día', 5),
  (69, 32, 'Loratadina 10 mg', '1 comprimido al día', 5),
  (70, 32, 'Amoxicilina 500 mg', '2 inhalaciones cada 6 horas', 90),
  (71, 33, 'Omeprazol 20 mg', 'Aplicar 2 veces al día', 3),
  (72, 33, 'Amoxicilina 500 mg', '1 gota en cada ojo cada 8 horas', 60),
  (73, 34, 'Sulfato ferroso 200 mg', 'Aplicar 2 veces al día', 90),
  (74, 34, 'Nitrofurantoína 100 mg', '5 ml cada 8 horas', 14),
  (75, 34, 'Ácido fólico 1 mg', '1 comprimido cada 12 horas', 7),
  (76, 35, 'Amoxicilina suspensión 250 mg', '1 gota en cada ojo cada 8 horas', 7),
  (77, 35, 'Sales de rehidratación oral', '1 comprimido al día', 3),
  (78, 36, 'Ibuprofeno 400 mg', '1 comprimido cada 8 horas', 14),
  (79, 36, 'Amoxicilina 500 mg', '1 comprimido al día', 60),
  (80, 37, 'Amoxicilina 500 mg', 'Aplicar 2 veces al día', 3),
  (81, 38, 'Enalapril 10 mg', '1 comprimido cada 12 horas', 30),
  (82, 39, 'Ibuprofeno 400 mg', 'Aplicar 2 veces al día', 7),
  (83, 39, 'Amoxicilina 500 mg', '1 gota en cada ojo cada 8 horas', 30),
  (84, 40, 'Loratadina 10 mg', '1 comprimido cada 8 horas', 7),
  (85, 40, 'Amoxicilina 500 mg', '1 comprimido cada 12 horas', 60),
  (86, 41, 'Ciclobenzaprina 10 mg', '1 comprimido cada 8 horas', 90),
  (87, 41, 'Diclofenaco gel 1%', '1 comprimido cada 8 horas', 3),
  (88, 42, 'Amoxicilina 500 mg', '2 inhalaciones cada 6 horas', 10),
  (89, 42, 'Omeprazol 20 mg', '1 comprimido al día', 90),
  (90, 42, 'Paracetamol 500 mg', '2 inhalaciones cada 6 horas', 60),
  (91, 43, 'Omeprazol 20 mg', '1 comprimido cada 8 horas', 3),
  (92, 43, 'Paracetamol 500 mg', '1 gota en cada ojo cada 8 horas', 10),
  (93, 44, 'Ketoprofeno 100 mg', '1 comprimido al día', 14),
  (94, 44, 'Ciclobenzaprina 10 mg', '5 ml cada 8 horas', 10),
  (95, 44, 'Paracetamol 1 g', 'Aplicar 2 veces al día', 5),
  (96, 45, 'Ácido fólico 1 mg', '2 inhalaciones cada 6 horas', 10),
  (97, 45, 'Sulfato ferroso 200 mg', '1 comprimido cada 12 horas', 60),
  (98, 45, 'Fluconazol 150 mg', '1 comprimido cada 12 horas', 3),
  (99, 46, 'Omeprazol 20 mg', '1 comprimido al día', 5),
  (100, 46, 'Paracetamol 500 mg', 'Aplicar 2 veces al día', 7),
  (101, 47, 'Clotrimazol crema 1%', '2 inhalaciones cada 6 horas', 5),
  (102, 47, 'Cetirizina 10 mg', '5 ml cada 8 horas', 14),
  (103, 48, 'Diclofenaco gel 1%', '1 gota en cada ojo cada 8 horas', 5),
  (104, 48, 'Ciclobenzaprina 10 mg', '5 ml cada 8 horas', 30),
  (105, 49, 'Atorvastatina 20 mg', '1 gota en cada ojo cada 8 horas', 10),
  (106, 49, 'Amlodipino 5 mg', '1 sobre cada 6 horas', 90),
  (107, 50, 'Amitriptilina 25 mg', '2 inhalaciones cada 6 horas', 7),
  (108, 51, 'Omeprazol 20 mg', '1 sobre cada 6 horas', 60),
  (109, 51, 'Ibuprofeno 400 mg', '2 inhalaciones cada 6 horas', 5),
  (110, 52, 'Ciclobenzaprina 10 mg', '1 gota en cada ojo cada 8 horas', 60),
  (111, 52, 'Diclofenaco gel 1%', '1 comprimido cada 8 horas', 14),
  (112, 52, 'Paracetamol 1 g', '1 sobre cada 6 horas', 5),
  (113, 53, 'Cetirizina 10 mg', 'Aplicar 2 veces al día', 3),
  (114, 54, 'Emoliente dermatológico', '1 comprimido cada 8 horas', 30),
  (115, 55, 'Clonazepam 0,5 mg', '1 comprimido al día', 60),
  (116, 55, 'Quetiapina 25 mg', '1 sobre cada 6 horas', 90),
  (117, 56, 'Aspirina 100 mg', '1 comprimido cada 8 horas', 10),
  (118, 56, 'Enalapril 10 mg', '1 sobre cada 6 horas', 7),
  (119, 57, 'Aspirina 100 mg', 'Aplicar 2 veces al día', 60),
  (120, 57, 'Losartán 50 mg', '1 gota en cada ojo cada 8 horas', 30),
  (121, 57, 'Atorvastatina 20 mg', '1 comprimido cada 12 horas', 60),
  (122, 58, 'Clotrimazol crema 1%', '1 gota en cada ojo cada 8 horas', 7),
  (123, 59, 'Fluconazol 150 mg', '1 sobre cada 6 horas', 5),
  (124, 59, 'Nitrofurantoína 100 mg', '1 comprimido cada 12 horas', 3),
  (125, 60, 'Lágrimas artificiales', '1 comprimido al día', 7),
  (126, 61, 'Hidrocortisona crema 1%', '1 gota en cada ojo cada 8 horas', 7),
  (127, 62, 'Diclofenaco gel 1%', '1 comprimido al día', 14),
  (128, 62, 'Ketoprofeno 100 mg', '2 inhalaciones cada 6 horas', 10),
  (129, 62, 'Paracetamol 1 g', '1 comprimido cada 12 horas', 90),
  (130, 63, 'Clotrimazol crema 1%', '5 ml cada 8 horas', 5),
  (131, 63, 'Cetirizina 10 mg', '1 gota en cada ojo cada 8 horas', 90),
  (132, 64, 'Salbutamol inhalador', '5 ml cada 8 horas', 14),
  (133, 65, 'Ibuprofeno 400 mg', '1 comprimido cada 8 horas', 10),
  (134, 65, 'Paracetamol 500 mg', '5 ml cada 8 horas', 7),
  (135, 66, 'Amoxicilina suspensión 250 mg', '1 comprimido cada 12 horas', 10),
  (136, 66, 'Sales de rehidratación oral', '5 ml cada 8 horas', 5),
  (137, 67, 'Paracetamol 500 mg', 'Aplicar 2 veces al día', 7),
  (138, 67, 'Ibuprofeno 400 mg', '1 comprimido al día', 3),
  (139, 68, 'Salbutamol inhalador', '5 ml cada 8 horas', 90),
  (140, 68, 'Sales de rehidratación oral', '1 comprimido cada 12 horas', 90),
  (141, 68, 'Ibuprofeno jarabe 100 mg/5 ml', '1 gota en cada ojo cada 8 horas', 10),
  (142, 69, 'Sales de rehidratación oral', '2 inhalaciones cada 6 horas', 30),
  (143, 70, 'Tobramicina colirio', '1 gota en cada ojo cada 8 horas', 3),
  (144, 70, 'Timolol colirio 0,5%', '1 gota en cada ojo cada 8 horas', 30);
