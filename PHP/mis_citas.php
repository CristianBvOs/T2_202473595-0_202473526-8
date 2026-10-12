<?php
require_once 'funciones.php';
requiere_rol([ROL_PACIENTE]);

$titulo = 'Mis citas';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['accion'] ?? '') === 'cancelar') {
    $id_cita = (int)($_POST['id_cita'] ?? 0);

    $st = $pdo->prepare('SELECT fn_cita_modificable(c.id_cita) AS modificable
                         FROM   cita c
                         WHERE  c.id_cita = ? AND c.rut_paciente = ?');
    $st->execute([$id_cita, rut_actual()]);
    $fila = $st->fetch();

    if (!$fila) {
        flash('danger', 'La cita indicada no existe o no le pertenece.');
    } elseif (!$fila['modificable']) {
        flash('warning', 'Solo se pueden cancelar citas Reservadas o Confirmadas cuya fecha no haya pasado.');
    } else {
        try {
            $st = $pdo->prepare("UPDATE cita
                                 SET    id_estado = (SELECT id_estado FROM estado_cita
                                                     WHERE nombre = 'Cancelada')
                                 WHERE  id_cita = ?");
            $st->execute([$id_cita]);
            flash('success', 'La cita N° ' . $id_cita . ' fue cancelada. '
                           . 'El bloque queda disponible nuevamente.');
        } catch (PDOException $e) {
            flash('danger', mensaje_bd($e));
        }
    }
    ir_a('mis_citas.php');
}

$sql = 'SELECT v.*, fn_cita_modificable(v.id_cita) AS modificable
        FROM   vw_cita_detalle v
        WHERE  v.rut_paciente = ?
          AND  %s
        ORDER BY v.fecha %s, v.hora_inicio %s';

$st = $pdo->prepare(sprintf($sql, 'v.fecha >= CURDATE()', 'ASC', 'ASC'));
$st->execute([rut_actual()]);
$proximas = $st->fetchAll();

$st = $pdo->prepare(sprintf($sql, 'v.fecha < CURDATE()', 'DESC', 'DESC'));
$st->execute([rut_actual()]);
$historicas = $st->fetchAll();

require 'cabecera.php';
?>

<div class="d-flex justify-content-between align-items-center mb-3">
    <h1 class="h4 mb-0">Mis citas</h1>
    <a href="agendar_hora.php" class="btn btn-salud">Agendar nueva hora</a>
</div>

<ul class="nav nav-tabs mb-3" role="tablist">
    <li class="nav-item">
        <button class="nav-link active" data-bs-toggle="tab" data-bs-target="#tab-proximas" type="button">
            Próximas <span class="badge bg-secondary"><?= count($proximas) ?></span>
        </button>
    </li>
    <li class="nav-item">
        <button class="nav-link" data-bs-toggle="tab" data-bs-target="#tab-historicas" type="button">
            Históricas <span class="badge bg-secondary"><?= count($historicas) ?></span>
        </button>
    </li>
</ul>

<div class="tab-content">
<?php
$bloques = ['tab-proximas' => $proximas, 'tab-historicas' => $historicas];
$primero = true;
foreach ($bloques as $id => $lista):
?>
    <div class="tab-pane fade <?= $primero ? 'show active' : '' ?>" id="<?= $id ?>">
        <div class="table-responsive">
            <table class="table table-hover align-middle bg-white">
                <thead class="table-light">
                    <tr>
                        <th>Fecha y hora</th>
                        <th>Médico</th>
                        <th>Especialidad</th>
                        <th>Centro</th>
                        <th>Estado</th>
                        <th class="text-end">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                <?php if (empty($lista)): ?>
                    <tr><td colspan="6" class="text-center text-muted py-4">No hay citas en esta sección.</td></tr>
                <?php endif; ?>
                <?php foreach ($lista as $c): ?>
                    <tr>
                        <td>
                            <?= fecha_cl($c['fecha']) ?><br>
                            <span class="text-muted small">
                                <?= hora_corta($c['hora_inicio']) ?> a <?= hora_corta($c['hora_fin']) ?>
                            </span>
                        </td>
                        <td><?= h($c['medico']) ?></td>
                        <td><?= h($c['especialidad']) ?></td>
                        <td><?= h($c['centro']) ?><br>
                            <span class="text-muted small"><?= h($c['comuna']) ?></span></td>
                        <td><span class="badge bg-<?= color_estado($c['estado']) ?>"><?= h($c['estado']) ?></span></td>
                        <td class="text-end">
                            <?php if ($c['modificable']): ?>
                                <a class="btn btn-sm btn-outline-primary"
                                   href="agendar_hora.php?reprogramar=<?= (int)$c['id_cita'] ?>">Reprogramar</a>
                                <form method="post" action="mis_citas.php" class="d-inline"
                                      onsubmit="return confirm('¿Confirma que desea cancelar esta cita?');">
                                    <input type="hidden" name="accion" value="cancelar">
                                    <input type="hidden" name="id_cita" value="<?= (int)$c['id_cita'] ?>">
                                    <button class="btn btn-sm btn-outline-danger" type="submit">Cancelar</button>
                                </form>
                            <?php elseif ($c['id_atencion']): ?>
                                <a class="btn btn-sm btn-outline-secondary" href="historial.php">Ver atención</a>
                            <?php else: ?>
                                <span class="text-muted small">Sin acciones</span>
                            <?php endif; ?>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>
<?php $primero = false; endforeach; ?>
</div>

<?php require 'pie.php'; ?>
