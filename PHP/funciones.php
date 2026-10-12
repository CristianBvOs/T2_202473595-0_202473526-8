<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

require_once 'conexion.php';

define('ROL_PACIENTE', 1);
define('ROL_MEDICO', 2);
define('ROL_ADMIN', 3);

function usuario_actual()
{
    return isset($_SESSION['usuario']) ? $_SESSION['usuario'] : null;
}

function hay_sesion()
{
    return usuario_actual() !== null;
}

function rol_actual()
{
    $u = usuario_actual();
    return $u ? (int)$u['id_rol'] : 0;
}

function rut_actual()
{
    $u = usuario_actual();
    return $u ? $u['rut'] : null;
}

function es_paciente()
{
    return rol_actual() === ROL_PACIENTE;
}

function es_medico()
{
    return rol_actual() === ROL_MEDICO;
}

function es_admin()
{
    return rol_actual() === ROL_ADMIN;
}

function requiere_rol($roles = [])
{
    if (!hay_sesion()) {
        flash('warning', 'Debe iniciar sesion para acceder a esa seccion.');
        ir_a('login.php');
    }
    if (!empty($roles) && !in_array(rol_actual(), $roles, true)) {
        flash('danger', 'No tiene permisos para acceder a esa seccion.');
        ir_a('inicio.php');
    }
}

function nombre_rol($id_rol)
{
    switch ((int)$id_rol) {
        case ROL_PACIENTE: return 'Paciente';
        case ROL_MEDICO:   return 'Médico';
        case ROL_ADMIN:    return 'Administrador';
    }
    return 'Desconocido';
}

function h($texto)
{
    return htmlspecialchars((string)$texto, ENT_QUOTES, 'UTF-8');
}

function validar_rut($rut)
{
    $rut = strtoupper(trim($rut));
    if (!preg_match('/^[0-9]{7,8}-[0-9K]$/', $rut)) {
        return false;
    }
    list($numero, $dv) = explode('-', $rut);
    $suma = 0;
    $multiplo = 2;
    for ($i = strlen($numero) - 1; $i >= 0; $i--) {
        $suma += (int)$numero[$i] * $multiplo;
        $multiplo = ($multiplo == 7) ? 2 : $multiplo + 1;
    }
    $resto = 11 - ($suma % 11);
    if ($resto == 11) {
        $esperado = '0';
    } elseif ($resto == 10) {
        $esperado = 'K';
    } else {
        $esperado = (string)$resto;
    }
    return $dv === $esperado;
}

function validar_password($clave)
{
    return strlen($clave) >= 8
        && preg_match('/[A-Z]/', $clave)
        && preg_match('/[a-z]/', $clave)
        && preg_match('/[0-9]/', $clave);
}

function validar_email($email)
{
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

function mensaje_bd(PDOException $e)
{
    $texto = $e->getMessage();
    if (preg_match('/1644\s+(.+)$/', $texto, $m)) {
        return trim($m[1]);
    }
    if (strpos($texto, '1062') !== false) {
        return 'Ya existe un registro con esos datos (valor duplicado).';
    }
    if (strpos($texto, '1451') !== false) {
        return 'No se puede eliminar: existen registros asociados que dependen de este dato.';
    }
    if (strpos($texto, '1452') !== false) {
        return 'Los datos referenciados no existen o no son validos.';
    }
    if (strpos($texto, '4025') !== false || strpos($texto, '3819') !== false) {
        return 'Alguno de los datos ingresados no cumple el formato exigido.';
    }
    return 'Error de base de datos: ' . $texto;
}

function flash($tipo, $texto)
{
    $_SESSION['flash'][] = ['tipo' => $tipo, 'texto' => $texto];
}

function mostrar_flash()
{
    if (empty($_SESSION['flash'])) {
        return;
    }
    foreach ($_SESSION['flash'] as $m) {
        echo '<div class="alert alert-' . h($m['tipo']) . ' alert-dismissible fade show" role="alert">'
            . h($m['texto'])
            . '<button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>';
    }
    $_SESSION['flash'] = [];
}

function ir_a($url)
{
    header('Location: ' . $url);
    exit;
}

function fecha_cl($fecha)
{
    if (!$fecha) {
        return '';
    }
    return date('d-m-Y', strtotime($fecha));
}

function hora_corta($hora)
{
    return substr((string)$hora, 0, 5);
}

function bloques_horarios()
{
    $bloques = [];
    for ($h = 9; $h < 18; $h++) {
        $bloques[] = sprintf('%02d:00:00', $h);
        $bloques[] = sprintf('%02d:30:00', $h);
    }
    return $bloques;
}

function bloques_disponibles(PDO $pdo, $rut_medico, $fecha)
{
    if ($fecha === '' || es_fin_de_semana($fecha) || $fecha < date('Y-m-d')) {
        return [];
    }
    $st = $pdo->prepare("SELECT c.hora_inicio
                         FROM   cita c
                         JOIN   estado_cita e ON e.id_estado = c.id_estado
                         WHERE  c.rut_medico = ?
                           AND  c.fecha = ?
                           AND  e.nombre IN ('Reservada','Confirmada','Atendida')");
    $st->execute([$rut_medico, $fecha]);
    $tomados = $st->fetchAll(PDO::FETCH_COLUMN);

    $disponibles = [];
    foreach (bloques_horarios() as $bloque) {
        if (in_array($bloque, $tomados, true)) {
            continue;
        }
        if ($fecha === date('Y-m-d') && $bloque <= date('H:i:s')) {
            continue;
        }
        $disponibles[] = $bloque;
    }
    return $disponibles;
}

function es_fin_de_semana($fecha)
{
    $dia = (int)date('N', strtotime($fecha));
    return $dia >= 6;
}

function dia_habil_actual()
{
    $fecha = date('Y-m-d');
    while (es_fin_de_semana($fecha)) {
        $fecha = date('Y-m-d', strtotime($fecha . ' +1 day'));
    }
    return $fecha;
}

function color_estado($estado)
{
    switch ($estado) {
        case 'Reservada':  return 'secondary';
        case 'Confirmada': return 'primary';
        case 'Atendida':   return 'success';
        case 'No Asistió': return 'warning';
        case 'Cancelada':  return 'danger';
    }
    return 'light';
}
