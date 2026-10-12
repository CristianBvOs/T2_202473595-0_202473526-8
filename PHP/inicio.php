<?php
require_once 'funciones.php';
requiere_rol();

$titulo = 'Inicio';
$resumen = [];

if (es_paciente()) {
    $st = $pdo->prepare("SELECT
            SUM(fecha >= CURDATE() AND estado IN ('Reservada','Confirmada')) AS proximas,
            SUM(estado = 'Atendida')  AS atendidas,
            COUNT(*)                  AS total
        FROM vw_cita_detalle WHERE rut_paciente = ?");
    $st->execute([rut_actual()]);
    $resumen = $st->fetch();
} elseif (es_medico()) {
    $st = $pdo->prepare("SELECT
            SUM(fecha = CURDATE())    AS hoy,
            SUM(fecha > CURDATE() AND estado IN ('Reservada','Confirmada')) AS proximas,
            COUNT(*)                  AS total
        FROM vw_cita_detalle WHERE rut_medico = ?");
    $st->execute([rut_actual()]);
    $resumen = $st->fetch();
} else {
    $resumen = $pdo->query("SELECT
            (SELECT COUNT(*) FROM centro_medico) AS centros,
            (SELECT COUNT(*) FROM medico)        AS medicos,
            (SELECT COUNT(*) FROM paciente)      AS pacientes,
            (SELECT COUNT(*) FROM cita)          AS citas")->fetch();
}

require 'cabecera.php';
?>

<div class="p-4 mb-4 rounded-3 bloque-portada">
    <h1 class="h3">Hola, <?= h(usuario_actual()['nombre']) ?></h1>
    <p class="mb-4 text-muted">
        Red de salud SaludUSM &middot; perfil <?= h(nombre_rol(rol_actual())) ?>
    </p>
    <form class="row g-2" method="get" action="buscar_medicos.php">
        <div class="col-md-9">
            <input type="text" class="form-control form-control-lg" name="q"
                   placeholder="Buscar médico por nombre o especialidad...">
        </div>
        <div class="col-md-3 d-grid">
            <button class="btn btn-salud btn-lg" type="submit">Buscar</button>
        </div>
    </form>
</div>

<div class="row g-3">
<?php if (es_paciente()): ?>
    <div class="col-md-4">
        <div class="card text-center h-100"><div class="card-body">
            <div class="display-6"><?= (int)$resumen['proximas'] ?></div>
            <div class="text-muted">Citas próximas</div>
            <a href="mis_citas.php" class="btn btn-sm btn-outline-primary mt-3">Ver mis citas</a>
        </div></div>
    </div>
    <div class="col-md-4">
        <div class="card text-center h-100"><div class="card-body">
            <div class="display-6"><?= (int)$resumen['atendidas'] ?></div>
            <div class="text-muted">Atenciones recibidas</div>
            <a href="historial.php" class="btn btn-sm btn-outline-primary mt-3">Ver historial</a>
        </div></div>
    </div>
    <div class="col-md-4">
        <div class="card text-center h-100"><div class="card-body">
            <div class="display-6">+</div>
            <div class="text-muted">Reservar una nueva hora</div>
            <a href="agendar_hora.php" class="btn btn-sm btn-salud mt-3">Agendar hora</a>
        </div></div>
    </div>
<?php elseif (es_medico()): ?>
    <div class="col-md-4">
        <div class="card text-center h-100"><div class="card-body">
            <div class="display-6"><?= (int)$resumen['hoy'] ?></div>
            <div class="text-muted">Citas de hoy</div>
            <a href="agenda_medico.php" class="btn btn-sm btn-salud mt-3">Ver mi agenda</a>
        </div></div>
    </div>
    <div class="col-md-4">
        <div class="card text-center h-100"><div class="card-body">
            <div class="display-6"><?= (int)$resumen['proximas'] ?></div>
            <div class="text-muted">Citas futuras activas</div>
            <a href="busqueda_avanzada.php" class="btn btn-sm btn-outline-primary mt-3">Buscar citas</a>
        </div></div>
    </div>
    <div class="col-md-4">
        <div class="card text-center h-100"><div class="card-body">
            <div class="display-6"><?= (int)$resumen['total'] ?></div>
            <div class="text-muted">Citas históricas</div>
            <a href="historial.php" class="btn btn-sm btn-outline-primary mt-3">Historial clínico</a>
        </div></div>
    </div>
<?php else: ?>
    <div class="col-md-3">
        <div class="card text-center h-100"><div class="card-body">
            <div class="display-6"><?= (int)$resumen['centros'] ?></div>
            <div class="text-muted">Centros médicos</div>
            <a href="admin_centros.php" class="btn btn-sm btn-outline-primary mt-3">Gestionar</a>
        </div></div>
    </div>
    <div class="col-md-3">
        <div class="card text-center h-100"><div class="card-body">
            <div class="display-6"><?= (int)$resumen['medicos'] ?></div>
            <div class="text-muted">Médicos</div>
            <a href="admin_medicos.php" class="btn btn-sm btn-outline-primary mt-3">Gestionar</a>
        </div></div>
    </div>
    <div class="col-md-3">
        <div class="card text-center h-100"><div class="card-body">
            <div class="display-6"><?= (int)$resumen['pacientes'] ?></div>
            <div class="text-muted">Pacientes registrados</div>
        </div></div>
    </div>
    <div class="col-md-3">
        <div class="card text-center h-100"><div class="card-body">
            <div class="display-6"><?= (int)$resumen['citas'] ?></div>
            <div class="text-muted">Citas en el sistema</div>
            <a href="panel_gestion.php" class="btn btn-sm btn-salud mt-3">Panel de gestión</a>
        </div></div>
    </div>
<?php endif; ?>
</div>

<?php require 'pie.php'; ?>
