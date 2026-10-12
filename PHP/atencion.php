<?php
require_once 'funciones.php';
requiere_rol([ROL_MEDICO]);

$titulo  = 'Ficha de atención';
$id_cita = (int)($_GET['id_cita'] ?? $_POST['id_cita'] ?? 0);

$st = $pdo->prepare('SELECT * FROM vw_cita_detalle WHERE id_cita = ? AND rut_medico = ?');
$st->execute([$id_cita, rut_actual()]);
$cita = $st->fetch();

if (!$cita) {
    flash('danger', 'La cita indicada no existe o no corresponde a su agenda.');
    ir_a('agenda_medico.php');
}
if ($cita['estado'] !== 'Atendida') {
    flash('warning', 'Solo puede registrar la atención de una cita en estado Atendida. '
                   . 'Cambie primero el estado desde su agenda.');
    ir_a('agenda_medico.php?dia=' . urlencode($cita['fecha']));
}

$id_atencion = (int)$cita['id_atencion'];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $accion = $_POST['accion'] ?? '';

    try {

        if ($accion === 'guardar_atencion') {
            $motivo = trim($_POST['motivo'] ?? '');
            $obs    = trim($_POST['observaciones'] ?? '');

            if ($motivo === '') {
                flash('danger', 'El motivo de consulta es obligatorio.');
            } elseif ($id_atencion > 0) {
                $st = $pdo->prepare('UPDATE atencion SET motivo = ?, observaciones = ?
                                     WHERE id_atencion = ?');
                $st->execute([$motivo, $obs, $id_atencion]);
                flash('success', 'Atención actualizada.');
            } else {
                $st = $pdo->prepare('INSERT INTO atencion (id_cita, motivo, observaciones)
                                     VALUES (?, ?, ?)');
                $st->execute([$id_cita, $motivo, $obs]);
                flash('success', 'Atención registrada. Ahora puede agregar diagnósticos y recetas.');
            }

        } elseif ($accion === 'eliminar_atencion') {
            $st = $pdo->prepare('DELETE FROM atencion WHERE id_atencion = ?');
            $st->execute([$id_atencion]);
            flash('success', 'La atención fue eliminada junto con sus diagnósticos y recetas.');
            ir_a('agenda_medico.php?dia=' . urlencode($cita['fecha']));

        } elseif ($accion === 'agregar_diagnostico') {
            $st = $pdo->prepare('INSERT INTO atencion_diagnostico (id_atencion, id_diagnostico)
                                 VALUES (?, ?)');
            $st->execute([$id_atencion, (int)$_POST['id_diagnostico']]);
            flash('success', 'Diagnóstico agregado a la atención.');

        } elseif ($accion === 'crear_diagnostico') {

            $codigo = strtoupper(trim($_POST['codigo_cie10'] ?? ''));
            $descripcion = trim($_POST['descripcion'] ?? '');

            if ($codigo === '' || $descripcion === '') {
                flash('danger', 'Para crear un diagnóstico debe indicar el código CIE-10 y la descripción.');
            } else {
                $st = $pdo->prepare('SELECT id_diagnostico FROM diagnostico WHERE codigo_cie10 = ?');
                $st->execute([$codigo]);
                $existente = $st->fetchColumn();

                if ($existente) {
                    flash('warning', 'El código ' . $codigo . ' ya existe en el catálogo; '
                                   . 'se asoció ese diagnóstico a la atención.');
                    $st = $pdo->prepare('INSERT INTO atencion_diagnostico (id_atencion, id_diagnostico)
                                         VALUES (?, ?)');
                    $st->execute([$id_atencion, $existente]);
                } else {
                    $pdo->beginTransaction();
                    $st = $pdo->prepare('INSERT INTO diagnostico (codigo_cie10, descripcion)
                                         VALUES (?, ?)');
                    $st->execute([$codigo, $descripcion]);
                    $nuevo = (int)$pdo->lastInsertId();

                    $st = $pdo->prepare('INSERT INTO atencion_diagnostico (id_atencion, id_diagnostico)
                                         VALUES (?, ?)');
                    $st->execute([$id_atencion, $nuevo]);
                    $pdo->commit();
                    flash('success', 'Diagnóstico ' . $codigo . ' creado y agregado a la atención.');
                }
            }

        } elseif ($accion === 'editar_diagnostico') {

            $st = $pdo->prepare('UPDATE atencion_diagnostico
                                 SET    id_diagnostico = ?
                                 WHERE  id_atencion = ? AND id_diagnostico = ?');
            $st->execute([(int)$_POST['id_nuevo'], $id_atencion, (int)$_POST['id_actual']]);
            flash('success', 'Diagnóstico actualizado.');

        } elseif ($accion === 'quitar_diagnostico') {
            $st = $pdo->prepare('DELETE FROM atencion_diagnostico
                                 WHERE id_atencion = ? AND id_diagnostico = ?');
            $st->execute([$id_atencion, (int)$_POST['id_diagnostico']]);
            flash('success', 'Diagnóstico quitado de la atención.');

        } elseif ($accion === 'agregar_receta' || $accion === 'editar_receta') {
            $medicamento = trim($_POST['medicamento'] ?? '');
            $dosis       = trim($_POST['dosis'] ?? '');
            $dias        = (int)($_POST['dias_tratamiento'] ?? 0);

            if ($medicamento === '' || $dosis === '' || $dias <= 0) {
                flash('danger', 'Medicamento, dosis y días de tratamiento son obligatorios '
                              . '(los días deben ser mayores que cero).');
            } elseif ($accion === 'agregar_receta') {
                $st = $pdo->prepare('INSERT INTO receta (id_atencion, medicamento, dosis, dias_tratamiento)
                                     VALUES (?, ?, ?, ?)');
                $st->execute([$id_atencion, $medicamento, $dosis, $dias]);
                flash('success', 'Medicamento agregado a la receta.');
            } else {
                $st = $pdo->prepare('UPDATE receta
                                     SET    medicamento = ?, dosis = ?, dias_tratamiento = ?
                                     WHERE  id_receta = ? AND id_atencion = ?');
                $st->execute([$medicamento, $dosis, $dias, (int)$_POST['id_receta'], $id_atencion]);
                flash('success', 'Línea de receta actualizada.');
            }

        } elseif ($accion === 'eliminar_receta') {
            $st = $pdo->prepare('DELETE FROM receta WHERE id_receta = ? AND id_atencion = ?');
            $st->execute([(int)$_POST['id_receta'], $id_atencion]);
            flash('success', 'Medicamento eliminado de la receta.');
        }
    } catch (PDOException $e) {
        flash('danger', mensaje_bd($e));
    }

    ir_a('atencion.php?id_cita=' . $id_cita);
}

$st = $pdo->prepare('SELECT * FROM atencion WHERE id_cita = ?');
$st->execute([$id_cita]);
$atencion = $st->fetch();

$asignados = [];
$lineas    = [];
if ($atencion) {
    $id_atencion = (int)$atencion['id_atencion'];

    $st = $pdo->prepare('SELECT d.id_diagnostico, d.codigo_cie10, d.descripcion
                         FROM   atencion_diagnostico ad
                         JOIN   diagnostico d ON d.id_diagnostico = ad.id_diagnostico
                         WHERE  ad.id_atencion = ?
                         ORDER BY d.codigo_cie10');
    $st->execute([$id_atencion]);
    $asignados = $st->fetchAll();

    $st = $pdo->prepare('SELECT * FROM receta WHERE id_atencion = ? ORDER BY id_receta');
    $st->execute([$id_atencion]);
    $lineas = $st->fetchAll();
}

$catalogo = $pdo->query('SELECT id_diagnostico, codigo_cie10, descripcion
                         FROM diagnostico ORDER BY codigo_cie10')->fetchAll();

require 'cabecera.php';
?>

<h1 class="h4 mb-1">Ficha de atención</h1>
<p class="text-muted">
    Cita N° <?= (int)$cita['id_cita'] ?> &middot; <?= fecha_cl($cita['fecha']) ?>
    a las <?= hora_corta($cita['hora_inicio']) ?> &middot; <?= h($cita['centro']) ?>
</p>

<div class="card mb-4">
    <div class="card-body">
        <dl class="row mb-0">
            <dt class="col-sm-3">Paciente</dt>
            <dd class="col-sm-9"><?= h($cita['paciente']) ?> (<?= h($cita['rut_paciente']) ?>)</dd>
            <dt class="col-sm-3">Previsión</dt>
            <dd class="col-sm-9"><?= h($cita['prevision']) ?></dd>
            <dt class="col-sm-3">Especialidad</dt>
            <dd class="col-sm-9"><?= h($cita['especialidad']) ?></dd>
        </dl>
    </div>
</div>
<form method="post" action="atencion.php" class="card mb-4">
    <div class="card-body">
        <input type="hidden" name="id_cita" value="<?= (int)$id_cita ?>">
        <input type="hidden" name="accion" value="guardar_atencion">
        <div class="mb-3">
            <label class="form-label" for="motivo">Motivo de consulta</label>
            <input type="text" class="form-control" id="motivo" name="motivo" maxlength="200"
                   value="<?= h($atencion['motivo'] ?? '') ?>" required>
        </div>
        <div class="mb-3">
            <label class="form-label" for="observaciones">Observaciones clínicas</label>
            <textarea class="form-control" id="observaciones" name="observaciones"
                      rows="4"><?= h($atencion['observaciones'] ?? '') ?></textarea>
        </div>
        <div class="d-flex justify-content-between">
            <a href="agenda_medico.php?dia=<?= h($cita['fecha']) ?>" class="btn btn-outline-secondary">
                Volver a la agenda
            </a>
            <div class="d-flex gap-2">
                <?php if ($atencion): ?>
                    <button class="btn btn-outline-danger" type="submit" form="form-eliminar-atencion"
                            onclick="return confirm('Se eliminará la atención junto con sus diagnósticos y recetas. ¿Continuar?');">
                        Eliminar atención
                    </button>
                <?php endif; ?>
                <button class="btn btn-salud" type="submit">
                    <?= $atencion ? 'Guardar cambios' : 'Registrar atención' ?>
                </button>
            </div>
        </div>
    </div>
</form>

<?php if ($atencion): ?>

    <form method="post" action="atencion.php" id="form-eliminar-atencion" class="d-none">
        <input type="hidden" name="id_cita" value="<?= (int)$id_cita ?>">
        <input type="hidden" name="accion" value="eliminar_atencion">
    </form>
    <div class="card mb-4">
        <div class="card-header">Diagnósticos</div>
        <div class="card-body">
            <form method="post" action="atencion.php" class="row g-2 mb-3">
                <input type="hidden" name="id_cita" value="<?= (int)$id_cita ?>">
                <input type="hidden" name="accion" value="agregar_diagnostico">
                <div class="col-md-9">
                    <select class="form-select" name="id_diagnostico" required>
                        <option value="">Seleccione un diagnóstico del catálogo CIE-10...</option>
                        <?php foreach ($catalogo as $d): ?>
                            <option value="<?= (int)$d['id_diagnostico'] ?>">
                                <?= h($d['codigo_cie10']) ?> - <?= h($d['descripcion']) ?>
                            </option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="col-md-3 d-grid">
                    <button class="btn btn-salud" type="submit">Agregar diagnóstico</button>
                </div>
            </form>
            <form method="post" action="atencion.php" class="row g-2 mb-3">
                <input type="hidden" name="id_cita" value="<?= (int)$id_cita ?>">
                <input type="hidden" name="accion" value="crear_diagnostico">
                <div class="col-md-3">
                    <input type="text" class="form-control" name="codigo_cie10"
                           placeholder="Código CIE-10 (ej: R50)" maxlength="10" required>
                </div>
                <div class="col-md-6">
                    <input type="text" class="form-control" name="descripcion"
                           placeholder="Descripción del diagnóstico" maxlength="120" required>
                </div>
                <div class="col-md-3 d-grid">
                    <button class="btn btn-outline-primary" type="submit">Crear y agregar</button>
                </div>
                <div class="col-12">
                    <span class="form-text">
                        Use este formulario solo si el diagnóstico no aparece en el catálogo.
                    </span>
                </div>
            </form>

            <div class="table-responsive">
                <table class="table table-sm table-hover align-middle mb-0">
                    <thead class="table-light">
                        <tr>
                            <th style="width:120px">Código</th>
                            <th>Descripción</th>
                            <th style="width:400px">Cambiar por</th>
                            <th class="text-end" style="width:90px"></th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php if (empty($asignados)): ?>
                        <tr><td colspan="4" class="text-center text-muted py-3">
                            La atención todavía no tiene diagnósticos.
                        </td></tr>
                    <?php endif; ?>
                    <?php foreach ($asignados as $d): ?>
                        <tr>
                            <td><span class="badge bg-secondary"><?= h($d['codigo_cie10']) ?></span></td>
                            <td><?= h($d['descripcion']) ?></td>
                            <td>
                                <form method="post" action="atencion.php" class="d-flex gap-2">
                                    <input type="hidden" name="id_cita" value="<?= (int)$id_cita ?>">
                                    <input type="hidden" name="accion" value="editar_diagnostico">
                                    <input type="hidden" name="id_actual" value="<?= (int)$d['id_diagnostico'] ?>">
                                    <select class="form-select form-select-sm" name="id_nuevo" required>
                                        <?php foreach ($catalogo as $c): ?>
                                            <option value="<?= (int)$c['id_diagnostico'] ?>"
                                                <?= $c['id_diagnostico'] == $d['id_diagnostico'] ? 'selected' : '' ?>>
                                                <?= h($c['codigo_cie10']) ?> - <?= h($c['descripcion']) ?>
                                            </option>
                                        <?php endforeach; ?>
                                    </select>
                                    <button class="btn btn-sm btn-outline-primary" type="submit">Guardar</button>
                                </form>
                            </td>
                            <td class="text-end">
                                <form method="post" action="atencion.php"
                                      onsubmit="return confirm('¿Quitar este diagnóstico de la atención?');">
                                    <input type="hidden" name="id_cita" value="<?= (int)$id_cita ?>">
                                    <input type="hidden" name="accion" value="quitar_diagnostico">
                                    <input type="hidden" name="id_diagnostico" value="<?= (int)$d['id_diagnostico'] ?>">
                                    <button class="btn btn-sm btn-outline-danger" type="submit">Quitar</button>
                                </form>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    <div class="card mb-4">
        <div class="card-header">Receta</div>
        <div class="card-body">
            <form method="post" action="atencion.php" class="row g-2 mb-3">
                <input type="hidden" name="id_cita" value="<?= (int)$id_cita ?>">
                <input type="hidden" name="accion" value="agregar_receta">
                <div class="col-md-5">
                    <input type="text" class="form-control" name="medicamento"
                           placeholder="Medicamento" maxlength="80" required>
                </div>
                <div class="col-md-4">
                    <input type="text" class="form-control" name="dosis"
                           placeholder="Dosis (ej: 1 comprimido cada 8 horas)" maxlength="60" required>
                </div>
                <div class="col-md-2">
                    <input type="number" class="form-control" name="dias_tratamiento"
                           placeholder="Días" min="1" required>
                </div>
                <div class="col-md-1 d-grid">
                    <button class="btn btn-salud" type="submit">+</button>
                </div>
            </form>

            <div class="table-responsive">
                <table class="table table-sm table-hover align-middle mb-0">
                    <thead class="table-light">
                        <tr>
                            <th>Medicamento</th>
                            <th>Dosis</th>
                            <th style="width:100px">Días</th>
                            <th class="text-end" style="width:180px"></th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php if (empty($lineas)): ?>
                        <tr><td colspan="4" class="text-center text-muted py-3">La receta está vacía.</td></tr>
                    <?php endif; ?>
                    <?php foreach ($lineas as $r): $fid = 'receta-' . (int)$r['id_receta']; ?>
                        <tr>
                            <td>
                                <form method="post" action="atencion.php" id="<?= $fid ?>">
                                    <input type="hidden" name="id_cita" value="<?= (int)$id_cita ?>">
                                    <input type="hidden" name="id_receta" value="<?= (int)$r['id_receta'] ?>">
                                </form>
                                <input type="text" class="form-control form-control-sm" name="medicamento"
                                       form="<?= $fid ?>" value="<?= h($r['medicamento']) ?>"
                                       maxlength="80" required>
                            </td>
                            <td><input type="text" class="form-control form-control-sm" name="dosis"
                                       form="<?= $fid ?>" value="<?= h($r['dosis']) ?>"
                                       maxlength="60" required></td>
                            <td><input type="number" class="form-control form-control-sm" name="dias_tratamiento"
                                       form="<?= $fid ?>" value="<?= (int)$r['dias_tratamiento'] ?>"
                                       min="1" required></td>
                            <td class="text-end">
                                <button class="btn btn-sm btn-outline-primary" type="submit" form="<?= $fid ?>"
                                        name="accion" value="editar_receta">Guardar</button>
                                <button class="btn btn-sm btn-outline-danger" type="submit" form="<?= $fid ?>"
                                        name="accion" value="eliminar_receta"
                                        onclick="return confirm('¿Eliminar este medicamento de la receta?');">
                                    Eliminar
                                </button>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
<?php endif; ?>

<?php require 'pie.php'; ?>
