<?php
require_once 'funciones.php';
requiere_rol([ROL_MEDICO]);

$titulo = 'Mi agenda';
$dia = trim($_GET['dia'] ?? $_POST['dia'] ?? date('Y-m-d'));

if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['accion'] ?? '') === 'estado') {
    $id_cita   = (int)($_POST['id_cita'] ?? 0);
    $id_estado = (int)($_POST['id_estado'] ?? 0);

    $st = $pdo->prepare('SELECT v.id_cita, v.estado, v.id_atencion
                         FROM   vw_cita_detalle v
                         WHERE  v.id_cita = ? AND v.rut_medico = ?');
    $st->execute([$id_cita, rut_actual()]);
    $cita = $st->fetch();

    $st = $pdo->prepare('SELECT nombre FROM estado_cita WHERE id_estado = ?');
    $st->execute([$id_estado]);
    $nuevo = $st->fetchColumn();

    if (!$cita) {
        flash('danger', 'La cita indicada no existe o no corresponde a su agenda.');
    } elseif (!in_array($nuevo, ['Confirmada', 'Atendida', 'No Asistió'], true)) {
        flash('danger', 'El médico solo puede dejar la cita en Confirmada, Atendida o No Asistió.');
    } elseif ($cita['id_atencion'] && $nuevo !== 'Atendida') {

        flash('warning', 'La cita ya tiene una atención registrada: elimine primero la atención '
                       . 'si necesita cambiarle el estado.');
    } else {
        try {
            $st = $pdo->prepare('UPDATE cita SET id_estado = ? WHERE id_cita = ?');
            $st->execute([$id_estado, $id_cita]);
            flash('success', 'La cita N° ' . $id_cita . ' quedó en estado ' . $nuevo . '.');
        } catch (PDOException $e) {
            flash('danger', mensaje_bd($e));
        }
    }
    ir_a('agenda_medico.php?dia=' . urlencode($dia));
}

$st = $pdo->prepare('SELECT * FROM vw_cita_detalle
                     WHERE  rut_medico = ? AND fecha = ?
                     ORDER BY hora_inicio');
$st->execute([rut_actual(), $dia]);
$citas = $st->fetchAll();

$estados = $pdo->query("SELECT id_estado, nombre FROM estado_cita
                        WHERE nombre IN ('Confirmada','Atendida','No Asistió')
                        ORDER BY id_estado")->fetchAll();

require 'cabecera.php';
?>

<h1 class="h4 mb-3">Mi agenda</h1>

<form class="row g-2 align-items-end mb-4" method="get" action="agenda_medico.php">
    <div class="col-md-3">
        <label class="form-label" for="dia">Día</label>
        <input type="date" class="form-control" id="dia" name="dia" value="<?= h($dia) ?>"
               onchange="this.form.submit()">
    </div>
    <div class="col-md-6">
        <a class="btn btn-outline-secondary"
           href="agenda_medico.php?dia=<?= date('Y-m-d', strtotime($dia . ' -1 day')) ?>">&laquo; Día anterior</a>
        <a class="btn btn-outline-secondary" href="agenda_medico.php">Hoy</a>
        <a class="btn btn-outline-secondary"
           href="agenda_medico.php?dia=<?= date('Y-m-d', strtotime($dia . ' +1 day')) ?>">Día siguiente &raquo;</a>
    </div>
</form>

<p class="text-muted"><?= count($citas) ?> cita(s) para el <?= fecha_cl($dia) ?>.</p>

<div class="table-responsive">
    <table class="table table-hover align-middle bg-white">
        <thead class="table-light">
            <tr>
                <th>Hora</th>
                <th>Paciente</th>
                <th>Previsión</th>
                <th>Especialidad</th>
                <th>Centro</th>
                <th>Estado</th>
                <th class="text-end">Acciones</th>
            </tr>
        </thead>
        <tbody>
        <?php if (empty($citas)): ?>
            <tr><td colspan="7" class="text-center text-muted py-4">No tiene citas agendadas ese día.</td></tr>
        <?php endif; ?>
        <?php foreach ($citas as $c): ?>
            <tr>
                <td class="fw-semibold"><?= hora_corta($c['hora_inicio']) ?></td>
                <td><?= h($c['paciente']) ?><br>
                    <span class="text-muted small"><?= h($c['rut_paciente']) ?></span></td>
                <td><?= h($c['prevision']) ?></td>
                <td><?= h($c['especialidad']) ?></td>
                <td><?= h($c['centro']) ?></td>
                <td><span class="badge bg-<?= color_estado($c['estado']) ?>"><?= h($c['estado']) ?></span></td>
                <td class="text-end">
                    <form method="post" action="agenda_medico.php" class="d-inline-flex gap-1">
                        <input type="hidden" name="accion" value="estado">
                        <input type="hidden" name="id_cita" value="<?= (int)$c['id_cita'] ?>">
                        <input type="hidden" name="dia" value="<?= h($dia) ?>">
                        <select name="id_estado" class="form-select form-select-sm w-auto">
                            <?php foreach ($estados as $e): ?>
                                <option value="<?= (int)$e['id_estado'] ?>"
                                    <?= $c['id_estado'] == $e['id_estado'] ? 'selected' : '' ?>>
                                    <?= h($e['nombre']) ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                        <button class="btn btn-sm btn-outline-primary" type="submit">Actualizar</button>
                    </form>
                    <?php if ($c['estado'] === 'Atendida'): ?>
                        <a class="btn btn-sm btn-salud" href="atencion.php?id_cita=<?= (int)$c['id_cita'] ?>">
                            <?= $c['id_atencion'] ? 'Editar atención' : 'Registrar atención' ?>
                        </a>
                    <?php endif; ?>
                    <a class="btn btn-sm btn-outline-secondary"
                       href="historial.php?rut_paciente=<?= urlencode($c['rut_paciente']) ?>">Historial</a>
                </td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>

<?php require 'pie.php'; ?>
