<?php
require_once 'funciones.php';
requiere_rol();

$titulo = 'Búsqueda avanzada';

$f = [
    'desde'           => trim($_GET['desde'] ?? ''),
    'hasta'           => trim($_GET['hasta'] ?? ''),
    'id_centro'       => (int)($_GET['id_centro'] ?? 0),
    'id_region'       => (int)($_GET['id_region'] ?? 0),
    'id_especialidad' => (int)($_GET['id_especialidad'] ?? 0),
    'rut_medico'      => trim($_GET['rut_medico'] ?? ''),
    'id_estado'       => (int)($_GET['id_estado'] ?? 0),
    'id_prevision'    => (int)($_GET['id_prevision'] ?? 0),
];

$where = [];
$par   = [];

if (es_paciente()) {
    $where[] = 'v.rut_paciente = ?';
    $par[]   = rut_actual();
} elseif (es_medico()) {
    $where[] = 'v.rut_medico = ?';
    $par[]   = rut_actual();
}

if ($f['desde'] !== '')          { $where[] = 'v.fecha >= ?';           $par[] = $f['desde']; }
if ($f['hasta'] !== '')          { $where[] = 'v.fecha <= ?';           $par[] = $f['hasta']; }
if ($f['id_centro'] > 0)         { $where[] = 'v.id_centro = ?';        $par[] = $f['id_centro']; }
if ($f['id_region'] > 0)         { $where[] = 'v.id_region = ?';        $par[] = $f['id_region']; }
if ($f['id_especialidad'] > 0)   { $where[] = 'v.id_especialidad = ?';  $par[] = $f['id_especialidad']; }
if ($f['rut_medico'] !== '')     { $where[] = 'v.rut_medico = ?';       $par[] = $f['rut_medico']; }
if ($f['id_estado'] > 0)         { $where[] = 'v.id_estado = ?';        $par[] = $f['id_estado']; }
if ($f['id_prevision'] > 0)      { $where[] = 'v.id_prevision = ?';     $par[] = $f['id_prevision']; }

$sql = 'SELECT v.* FROM vw_cita_detalle v';
if (!empty($where)) {
    $sql .= ' WHERE ' . implode(' AND ', $where);
}
$sql .= ' ORDER BY v.fecha DESC, v.hora_inicio DESC LIMIT 300';

$st = $pdo->prepare($sql);
$st->execute($par);
$resultados = $st->fetchAll();

$centros        = $pdo->query('SELECT id_centro, nombre FROM centro_medico ORDER BY nombre')->fetchAll();
$regiones       = $pdo->query('SELECT id_region, nombre FROM region ORDER BY nombre')->fetchAll();
$especialidades = $pdo->query('SELECT id_especialidad, nombre FROM especialidad ORDER BY nombre')->fetchAll();
$estados        = $pdo->query('SELECT id_estado, nombre FROM estado_cita ORDER BY id_estado')->fetchAll();
$previsiones    = $pdo->query('SELECT id_prevision, nombre FROM prevision ORDER BY nombre')->fetchAll();
$medicos        = $pdo->query('SELECT u.rut, u.nombre FROM medico m
                               JOIN usuario u ON u.rut = m.rut ORDER BY u.nombre')->fetchAll();

require 'cabecera.php';
?>

<h1 class="h4 mb-3">Búsqueda avanzada de citas</h1>

<div class="card mb-4">
    <div class="card-body">
        <form class="row g-3" method="get" action="busqueda_avanzada.php">
            <div class="col-md-3">
                <label class="form-label" for="desde">Desde</label>
                <input type="date" class="form-control" id="desde" name="desde" value="<?= h($f['desde']) ?>">
            </div>
            <div class="col-md-3">
                <label class="form-label" for="hasta">Hasta</label>
                <input type="date" class="form-control" id="hasta" name="hasta" value="<?= h($f['hasta']) ?>">
            </div>
            <div class="col-md-3">
                <label class="form-label" for="id_region">Región</label>
                <select class="form-select" id="id_region" name="id_region">
                    <option value="0">Todas</option>
                    <?php foreach ($regiones as $r): ?>
                        <option value="<?= (int)$r['id_region'] ?>"
                            <?= $f['id_region'] === (int)$r['id_region'] ? 'selected' : '' ?>>
                            <?= h($r['nombre']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-md-3">
                <label class="form-label" for="id_centro">Centro médico</label>
                <select class="form-select" id="id_centro" name="id_centro">
                    <option value="0">Todos</option>
                    <?php foreach ($centros as $c): ?>
                        <option value="<?= (int)$c['id_centro'] ?>"
                            <?= $f['id_centro'] === (int)$c['id_centro'] ? 'selected' : '' ?>>
                            <?= h($c['nombre']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-md-3">
                <label class="form-label" for="id_especialidad">Especialidad</label>
                <select class="form-select" id="id_especialidad" name="id_especialidad">
                    <option value="0">Todas</option>
                    <?php foreach ($especialidades as $e): ?>
                        <option value="<?= (int)$e['id_especialidad'] ?>"
                            <?= $f['id_especialidad'] === (int)$e['id_especialidad'] ? 'selected' : '' ?>>
                            <?= h($e['nombre']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <?php if (!es_medico()): ?>
            <div class="col-md-3">
                <label class="form-label" for="rut_medico">Médico</label>
                <select class="form-select" id="rut_medico" name="rut_medico">
                    <option value="">Todos</option>
                    <?php foreach ($medicos as $m): ?>
                        <option value="<?= h($m['rut']) ?>"
                            <?= $f['rut_medico'] === $m['rut'] ? 'selected' : '' ?>>
                            <?= h($m['nombre']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <?php endif; ?>
            <div class="col-md-3">
                <label class="form-label" for="id_estado">Estado de la cita</label>
                <select class="form-select" id="id_estado" name="id_estado">
                    <option value="0">Todos</option>
                    <?php foreach ($estados as $e): ?>
                        <option value="<?= (int)$e['id_estado'] ?>"
                            <?= $f['id_estado'] === (int)$e['id_estado'] ? 'selected' : '' ?>>
                            <?= h($e['nombre']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-md-3">
                <label class="form-label" for="id_prevision">Previsión del paciente</label>
                <select class="form-select" id="id_prevision" name="id_prevision">
                    <option value="0">Todas</option>
                    <?php foreach ($previsiones as $p): ?>
                        <option value="<?= (int)$p['id_prevision'] ?>"
                            <?= $f['id_prevision'] === (int)$p['id_prevision'] ? 'selected' : '' ?>>
                            <?= h($p['nombre']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-12 d-flex gap-2">
                <button class="btn btn-salud" type="submit">Filtrar</button>
                <a class="btn btn-outline-secondary" href="busqueda_avanzada.php">Limpiar filtros</a>
            </div>
        </form>
    </div>
</div>

<p class="text-muted"><?= count($resultados) ?> cita(s) encontradas.</p>

<div class="table-responsive">
    <table class="table table-sm table-hover align-middle bg-white">
        <thead class="table-light">
            <tr>
                <th>Fecha y hora</th>
                <th>Paciente</th>
                <th>Previsión</th>
                <th>Médico</th>
                <th>Especialidad</th>
                <th>Centro</th>
                <th>Estado</th>
            </tr>
        </thead>
        <tbody>
        <?php if (empty($resultados)): ?>
            <tr><td colspan="7" class="text-center text-muted py-4">
                Ninguna cita coincide con los filtros aplicados.
            </td></tr>
        <?php endif; ?>
        <?php foreach ($resultados as $c): ?>
            <tr>
                <td><?= fecha_cl($c['fecha']) ?> <?= hora_corta($c['hora_inicio']) ?></td>
                <td><?= h($c['paciente']) ?></td>
                <td><?= h($c['prevision']) ?></td>
                <td><?= h($c['medico']) ?></td>
                <td><?= h($c['especialidad']) ?></td>
                <td><?= h($c['centro']) ?> <span class="text-muted small">(<?= h($c['region']) ?>)</span></td>
                <td><span class="badge bg-<?= color_estado($c['estado']) ?>"><?= h($c['estado']) ?></span></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>

<?php require 'pie.php'; ?>
