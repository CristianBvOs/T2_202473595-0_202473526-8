<?php
define('BD_SERVIDOR', 'localhost');
define('BD_NOMBRE',   'salud_usm');
define('BD_USUARIO',  'root');
define('BD_CLAVE',    '');

date_default_timezone_set('America/Santiago');

try {
    $pdo = new PDO(
        'mysql:host=' . BD_SERVIDOR . ';dbname=' . BD_NOMBRE . ';charset=utf8mb4',
        BD_USUARIO,
        BD_CLAVE,
        [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]
    );

    $desfase = (new DateTime())->format('P');
    $pdo->exec("SET time_zone = '" . $desfase . "'");
} catch (PDOException $e) {
    die('No fue posible conectar con la base de datos: ' . $e->getMessage());
}
