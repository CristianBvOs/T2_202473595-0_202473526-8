<?php
require_once 'funciones.php';
requiere_rol([ROL_PACIENTE]);

$titulo = 'Agendar hora';

$id_reprogramar = (int)($_GET['reprogramar'] ?? $_POST['reprogramar'] ?? 0);
$cita = null;

if ($id_reprogramar > 0) {
    $st = $pdo->prepare('SELECT v.*, fn_cita_modificable(v.id_cita) AS modificable
                         FROM   vw_cita_detalle v
                         WHERE  v.id_cita = ? AND v.rut_paciente = ?');
    $st->execute([$id_reprogramar, rut_actual()]);
    $cita = $st->fetch();

    if (!$cita) {
        flash('danger', 'La cita indicada no existe o no le pertenece.');
        ir_a('mis_citas.php');
    }
    if (!$cita['modificable']) {
        flash('warning', 'Solo se pueden reprogramar citas Reservadas o Confirmadas '
                       . 'cuya fecha no haya pasado.');
        ir_a('mis_citas.php');
    }
    $titulo = 'Reprogramar cita';
}

$id_especialidad = (int)($_GET['id_especialidad'] ?? $_POST['id_especialidad'] ?? 0);
$id_centro       = (int)($_GET['id_centro'] ?? $_POST['id_centro'] ?? 0);
$rut_medico      = trim($_GET['rut_medico'] ?? $_POST['rut_medico'] ?? '');
$fecha           = trim($_GET['fecha'] ?? $_POST['fecha'] ?? '');

if ($cita) {

    $id_especialidad = (int)$cita['id_especialidad'];
    $id_centro       = (int)$cita['id_centro'];
    $rut_medico      = $cita['rut_medico'];
    if ($fecha === '') {
        $fecha = $cita['fecha'];
    }
}

if (!$cita && $rut_medico !== '' && $id_especialidad === 0) {
    $st = $pdo->prepare('SELECT id_especialidad FROM medico_especialidad WHERE rut_medico = ? LIMIT 1');
    $st->execute([$rut_medico]);
    $id_especialidad = (int)$st->fetchColumn();
}
if (!$cita && $rut_medico !== '' && $id_centro === 0) {
    $st = $pdo->prepare('SELECT id_centro FROM medico_centro WHERE rut_medico = ? LIMIT 1');
    $st->execute([$rut_medico]);
    $id_centro = (int)$st->fetchColumn();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['hora'])) {
    try {
        if ($id_reprogramar > 0) {
            $st = $pdo->prepare('CALL sp_reprogramar_cita(?, ?, ?)');
            $st->execute([$id_reprogramar, $_POST['fecha'], $_POST['hora']]);
            $st->closeCursor();
            flash('success', 'La cita N° ' . $id_reprogramar . ' fue reprogramada para el '
                           . fecha_cl($_POST['fecha']) . ' a las ' . hora_corta($_POST['hora']) . '.');
        } else {
            $st = $pdo->prepare('CALL sp_agendar_cita(?, ?, ?, ?, ?, ?, @id_cita)');
            $st->execute([
                rut_actual(),
                $_POST['rut_medico'],
                (int)$_POST['id_especialidad'],
                (int)$_POST['id_centro'],
                $_POST['fecha'],
                $_POST['hora'],
            ]);
            $st->closeCursor();
            $id_nueva = (int)$pdo->query('SELECT @id_cita')->fetchColumn();
            flash('success', 'Hora reservada correctamente (cita N° ' . $id_nueva . ').');
        }
        ir_a('mis_citas.php');
    } catch (PDOException $e) {
        flash('danger', mensaje_bd($e));
    }
}

$especialidades = $pdo->query('SELECT e.id_especialidad, e.nombre
                               FROM   especialidad e
                               WHERE  EXISTS (SELECT 1 FROM medico_especialidad me
                                              WHERE me.id_especialidad = e.id_especialidad)
                               ORDER BY e.nombre')->fetchAll();

$centros = [];
if ($id_especialidad > 0) {
    $st = $pdo->prepare('SELECT DISTINCT c.id_centro, c.nombre, co.nombre AS comuna
                         FROM   centro_medico c
                         JOIN   comuna        co ON co.id_comuna = c.id_comuna
                         JOIN   medico_centro mc ON mc.id_centro = c.id_centro
                         JOIN   medico_especialidad me ON me.rut_medico = mc.rut_medico
                         WHERE  me.id_especialidad = ?
                         ORDER BY c.nombre');
    $st->execute([$id_especialidad]);
    $centros = $st->fetchAll();
}

$medicos = [];
if ($id_especialidad > 0 && $id_centro > 0) {
    $st = $pdo->prepare('SELECT u.rut, u.nombre
                         FROM   usuario u
                         JOIN   medico_especialidad me ON me.rut_medico = u.rut
                         JOIN   medico_centro       mc ON mc.rut_medico = u.rut
                         WHERE  me.id_especialidad = ? AND mc.id_centro = ?
                         ORDER BY u.nombre');
    $st->execute([$id_especialidad, $id_centro]);
    $medicos = $st->fetchAll();
}

$disponibles = [];
$mensaje_bloques = '';
if ($rut_medico !== '' && $fecha !== '') {
    if (es_fin_de_semana($fecha)) {
        $mensaje_bloques = 'La red SaludUSM atiende de lunes a viernes. Seleccione otro día.';
    } elseif ($fecha < date('Y-m-d')) {
        $mensaje_bloques = 'La fecha seleccionada ya pasó.';
    } else {
        $disponibles = bloques_disponibles($pdo, $rut_medico, $fecha);
        if (empty($disponibles)) {
            $mensaje_bloques = 'El médico no tiene bloques disponibles ese día.';
        }
    }
}

require 'cabecera.php';
?>

<h1 class="h4 mb-3"><?= h($titulo) ?><?= $cita ? ' N° ' . (int)$cita['id_cita'] : '' ?></h1>

<?php if ($cita): ?>
    <div class="card mb-4">
        <div class="card-body">
            <dl class="row mb-0">
                <dt class="col-sm-3">Médico</dt>
                <dd class="col-sm-9"><?= h($cita['medico']) ?> (<?= h($cita['especialidad']) ?>)</dd>
                <dt class="col-sm-3">Centro</dt>
                <dd class="col-sm-9"><?= h($cita['centro']) ?>, <?= h($cita['comuna']) ?></dd>
                <dt class="col-sm-3">Hora actual</dt>
                <dd class="col-sm-9">
                    <?= fecha_cl($cita['fecha']) ?> a las <?= hora_corta($cita['hora_inicio']) ?>
                </dd>
            </dl>
            <p class="text-muted small mb-0 mt-3">
                La reprogramación cambia solo la fecha y la hora. Para cambiar de médico o de
                centro debe cancelar esta cita y agendar una nueva.
            </p>
        </div>
    </div>

    <form class="row g-3 mb-4" method="get" action="agendar_hora.php">
        <input type="hidden" name="reprogramar" value="<?= (int)$cita['id_cita'] ?>">
        <div class="col-md-4">
            <label class="form-label" for="fecha">Nueva fecha</label>
            <input type="date" class="form-control" id="fecha" name="fecha"
                   value="<?= h($fecha) ?>" min="<?= date('Y-m-d') ?>" onchange="this.form.submit()">
        </div>
    </form>
<?php else: ?>
    <div class="card mb-4">
        <div class="card-body">
            <form class="row g-3" method="get" action="agendar_hora.php">
                <div class="col-md-3">
                    <label class="form-label" for="id_especialidad">1. Especialidad</label>
                    <select class="form-select" id="id_especialidad" name="id_especialidad"
                            onchange="this.form.submit()">
                        <option value="0">Seleccione...</option>
                        <?php foreach ($especialidades as $e): ?>
                            <option value="<?= (int)$e['id_especialidad'] ?>"
                                <?= $id_especialidad === (int)$e['id_especialidad'] ? 'selected' : '' ?>>
                                <?= h($e['nombre']) ?>
                            </option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="col-md-3">
                    <label class="form-label" for="id_centro">2. Centro médico</label>
                    <select class="form-select" id="id_centro" name="id_centro"
                            onchange="this.form.submit()" <?= empty($centros) ? 'disabled' : '' ?>>
                        <option value="0">Seleccione...</option>
                        <?php foreach ($centros as $c): ?>
                            <option value="<?= (int)$c['id_centro'] ?>"
                                <?= $id_centro === (int)$c['id_centro'] ? 'selected' : '' ?>>
                                <?= h($c['nombre']) ?> (<?= h($c['comuna']) ?>)
                            </option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="col-md-3">
                    <label class="form-label" for="rut_medico">3. Médico</label>
                    <select class="form-select" id="rut_medico" name="rut_medico"
                            onchange="this.form.submit()" <?= empty($medicos) ? 'disabled' : '' ?>>
                        <option value="">Seleccione...</option>
                        <?php foreach ($medicos as $m): ?>
                            <option value="<?= h($m['rut']) ?>"
                                <?= $rut_medico === $m['rut'] ? 'selected' : '' ?>>
                                <?= h($m['nombre']) ?>
                            </option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="col-md-3">
                    <label class="form-label" for="fecha">4. Fecha</label>
                    <input type="date" class="form-control" id="fecha" name="fecha"
                           value="<?= h($fecha) ?>" min="<?= date('Y-m-d') ?>"
                           onchange="this.form.submit()" <?= $rut_medico === '' ? 'disabled' : '' ?>>
                </div>
            </form>
            <p class="text-muted small mb-0 mt-3">
                Horario de atención: lunes a viernes de 09:00 a 18:00, en bloques de 30 minutos.
            </p>
        </div>
    </div>
<?php endif; ?>

<?php if ($mensaje_bloques !== ''): ?>
    <div class="alert alert-warning"><?= h($mensaje_bloques) ?></div>
<?php endif; ?>

<?php if (!empty($disponibles)): ?>
    <h2 class="h6 mb-3">Bloques disponibles para el <?= fecha_cl($fecha) ?></h2>
    <div class="d-flex flex-wrap gap-2 mb-4">
        <?php foreach ($disponibles as $bloque): ?>
            <form method="post" action="agendar_hora.php"
                  onsubmit="return confirm('¿Confirma la hora de las <?= hora_corta($bloque) ?>?');">
                <input type="hidden" name="reprogramar" value="<?= (int)$id_reprogramar ?>">
                <input type="hidden" name="id_especialidad" value="<?= (int)$id_especialidad ?>">
                <input type="hidden" name="id_centro" value="<?= (int)$id_centro ?>">
                <input type="hidden" name="rut_medico" value="<?= h($rut_medico) ?>">
                <input type="hidden" name="fecha" value="<?= h($fecha) ?>">
                <input type="hidden" name="hora" value="<?= h($bloque) ?>">
                <button type="submit" class="btn btn-outline-success bloque-horario">
                    <?= hora_corta($bloque) ?>
                </button>
            </form>
        <?php endforeach; ?>
    </div>
<?php endif; ?>

<a href="mis_citas.php" class="btn btn-outline-secondary">Volver a mis citas</a>

<?php require 'pie.php'; ?>
