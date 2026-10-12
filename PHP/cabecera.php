<?php
if (!isset($titulo)) {
    $titulo = 'SaludUSM';
}
$u = usuario_actual();
$seccion = basename($_SERVER['PHP_SELF']);

function activo($archivo)
{
    global $seccion;
    return $seccion === $archivo ? ' active' : '';
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= h($titulo) ?> | SaludUSM</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="../CSS/estilos.css" rel="stylesheet">
</head>
<body>
<nav class="navbar navbar-expand-lg navbar-dark bg-salud">
    <div class="container">
        <a class="navbar-brand fw-bold" href="inicio.php">
            <span class="cruz">+</span> SaludUSM
        </a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#menu">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="menu">
            <ul class="navbar-nav me-auto">
                <li class="nav-item">
                    <a class="nav-link<?= activo('inicio.php') ?>" href="inicio.php">Inicio</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link<?= activo('buscar_medicos.php') ?>" href="buscar_medicos.php">Buscar médicos</a>
                </li>
                <?php if (es_paciente()): ?>
                    <li class="nav-item">
                        <a class="nav-link<?= activo('mis_citas.php') ?>" href="mis_citas.php">Mis citas</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link<?= activo('agendar_hora.php') ?>" href="agendar_hora.php">Agendar hora</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link<?= activo('historial.php') ?>" href="historial.php">Mi historial</a>
                    </li>
                <?php endif; ?>
                <?php if (es_medico()): ?>
                    <li class="nav-item">
                        <a class="nav-link<?= activo('agenda_medico.php') ?>" href="agenda_medico.php">Mi agenda</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link<?= activo('historial.php') ?>" href="historial.php">Historial clínico</a>
                    </li>
                <?php endif; ?>
                <?php if (es_admin()): ?>
                    <li class="nav-item">
                        <a class="nav-link<?= activo('panel_gestion.php') ?>" href="panel_gestion.php">Panel de gestión</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link<?= activo('admin_centros.php') ?>" href="admin_centros.php">Centros</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link<?= activo('admin_medicos.php') ?>" href="admin_medicos.php">Médicos</a>
                    </li>
                <?php endif; ?>
                <li class="nav-item">
                    <a class="nav-link<?= activo('busqueda_avanzada.php') ?>" href="busqueda_avanzada.php">Búsqueda avanzada</a>
                </li>
            </ul>
            <ul class="navbar-nav">
                <li class="nav-item dropdown">
                    <a class="nav-link dropdown-toggle" href="#" data-bs-toggle="dropdown">
                        <?= h($u['nombre']) ?> (<?= h(nombre_rol($u['id_rol'])) ?>)
                    </a>
                    <ul class="dropdown-menu dropdown-menu-end">
                        <li><a class="dropdown-item" href="perfil.php">Mis datos</a></li>
                        <li><hr class="dropdown-divider"></li>
                        <li><a class="dropdown-item" href="logout.php">Cerrar sesión</a></li>
                    </ul>
                </li>
            </ul>
        </div>
    </div>
</nav>
<main class="container my-4">
<?php mostrar_flash(); ?>
